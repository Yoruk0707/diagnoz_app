// lib/features/game/data/repositories/firebase_game_repository.dart
//
// NEDEN: GameRepository'nin Firestore implementasyonu.
// Sprint 4 — LocalGameRepository yerine kullanılacak.
// FirestoreCaseDatasource'dan vakalar, FirestoreGameDatasource'dan oyun CRUD.
//
// Referans: game_repository.dart interface
//           firebase_auth_repository.dart pattern (Either<Failure, T>)
//           vcguide.md § Edge Cases (timer, score, duplicate submit)
//           CLAUDE.md § Error Handling ("Wrap ALL async operations in try-catch")

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/medical_case.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/firestore_case_datasource.dart';
import '../datasources/firestore_game_datasource.dart';

/// Firebase game repository — Firestore ile çalışır.
///
/// NEDEN: Domain layer Firestore'u bilmez — bu class köprü görevi görür.
/// GameRepository interface'ini implement eder.
/// LocalGameRepository'nin Sprint 4 Firestore versiyonu.
///
/// Güvenlik referansları:
///   vcguide.md § Edge Case 1 (timer — server timestamp)
///   vcguide.md § Edge Case 4 (race condition — FieldValue.increment)
///   vcguide.md § Edge Case 5 (duplicate submit — batch write)
///   CLAUDE.md § Error Handling, § Firestore Cost Optimization
class FirebaseGameRepository implements GameRepository {
  final FirestoreCaseDatasource _caseDatasource;
  final FirestoreGameDatasource _gameDatasource;
  final FirebaseAuth _auth;

  // NEDEN: DI ile test edilebilirlik. Mock datasource'lar inject edilebilir.
  FirebaseGameRepository({
    FirestoreCaseDatasource? caseDatasource,
    FirestoreGameDatasource? gameDatasource,
    FirebaseAuth? auth,
  })  : _caseDatasource = caseDatasource ?? FirestoreCaseDatasource(),
        _gameDatasource = gameDatasource ?? FirestoreGameDatasource(),
        _auth = auth ?? FirebaseAuth.instance;

  // ─────────────────────────────────────────────
  // START GAME
  // ─────────────────────────────────────────────

  @override
  Future<Either<Failure, GameSession>> startGame({
    required GameMode mode,
    Specialty? specialty,
  }) async {
    try {
      final userId = _requireAuthUserId();

      // NEDEN: Firestore'dan rastgele vakalar çek.
      // FirestoreCaseDatasource client-side shuffle yapar.
      final casesResult = await getCases(
        count: AppConstants.casesPerGame,
        specialty: specialty,
      );

      return casesResult.fold(
        (failure) => Left(failure),
        (cases) async {
          // NEDEN: Firestore'da game document oluştur (server timestamp ile).
          // vcguide.md § Timer System: startTime server-side olmalı.
          final gameId = await _gameDatasource.createGame(
            userId: userId,
            mode: mode,
            totalCases: cases.length,
          );

          final session = GameSession(
            id: gameId,
            mode: mode,
            startTime: DateTime.now(),
            cases: cases,
            passesLeft: AppConstants.passesPerGame,
          );

          return Right(session);
        },
      );
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('[GAME] Firebase error in startGame: ${e.code}');
      }
      return Left(ServerFailure(
        'Oyun başlatılamadı. Lütfen tekrar deneyin.',
        code: e.code,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('[GAME] Unexpected error in startGame: $e');
      }
      return const Left(ServerFailure(
        'Oyun başlatılırken beklenmeyen bir hata oluştu.',
      ));
    }
  }

  // ─────────────────────────────────────────────
  // GET TEST RESULT
  // ─────────────────────────────────────────────

  @override
  Future<Either<Failure, TestResult>> getTestResult({
    required String caseId,
    required String testId,
  }) async {
    try {
      // NEDEN: Firestore'dan vakayı çek ve ilgili testi bul.
      // Test sonuçları case document'ının içinde (availableTests).
      // Ayrı bir query gerekmiyor — vaka zaten client'ta yüklü.
      final medicalCase = await _caseDatasource.getCaseById(caseId);

      final test = medicalCase.availableTests.firstWhere(
        (t) => t.testId == testId,
        orElse: () => throw Exception('Test not found: $testId'),
      );

      return Right(test);
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('[GAME] Firebase error in getTestResult: ${e.code}');
      }
      return Left(ServerFailure(
        'Test sonucu alınamadı.',
        code: e.code,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('[GAME] Error in getTestResult: $e');
      }
      return const Left(ServerFailure('Test sonucu alınamadı.'));
    }
  }

  // ─────────────────────────────────────────────
  // GET CASES
  // ─────────────────────────────────────────────

  @override
  Future<Either<Failure, List<MedicalCase>>> getCases({
    required int count,
    Specialty? specialty,
  }) async {
    try {
      // NEDEN: FirestoreCaseDatasource.getRandomCases client-side shuffle yapar.
      // MVP'de 50 vaka — tüm aktif vakalar çekilip karıştırılır.
      final cases = await _caseDatasource.getRandomCases(
        count: count,
        specialty: specialty,
      );

      return Right(cases);
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('[GAME] Firebase error in getCases: ${e.code}');
      }
      return Left(ServerFailure(
        'Vakalar yüklenemedi. İnternet bağlantınızı kontrol edin.',
        code: e.code,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('[GAME] Error in getCases: $e');
      }
      // NEDEN: "Yeterli vaka yok" exception'ı da buraya düşer.
      return const Left(GameFailure(
        'Yeterli vaka bulunamadı.',
        code: 'insufficient-cases',
      ));
    }
  }

  // ─────────────────────────────────────────────
  // SUBMIT GAME
  // ─────────────────────────────────────────────

  /// Tamamlanmış oyunu kaydet — atomic batch write.
  ///
  /// NEDEN: database_schema.md § Submit Game (Atomic Update).
  /// Game + user stats + leaderboard tek batch'te güncellenir.
  /// vcguide.md § Edge Case 4: race condition önleme.
  /// vcguide.md § Edge Case 5: duplicate submit koruması.
  ///
  /// Bu method GameRepository interface'inde yok — Sprint 4'te
  /// interface genişletilecek. Şimdilik concrete class'tan erişilebilir.
  Future<Either<Failure, void>> submitGame(GameSession session) async {
    try {
      final userId = _requireAuthUserId();
      debugPrint('[GAME-REPO] submitGame called — '
          'gameId=${session.id} userId=$userId '
          'status=${session.status} totalScore=${session.totalScore}');

      // NEDEN: Duplicate submit koruması — vcguide.md § Edge Case 5.
      // Zaten completed olan oyun tekrar submit edilemez.
      if (session.status != GameStatus.completed &&
          session.status != GameStatus.timeout) {
        return Left(GameFailure.alreadySubmitted());
      }

      // NEDEN: User profil bilgisi leaderboard'da denormalize edilir.
      // database_schema.md § Denormalization Strategy.
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      String? displayName;
      String? university;
      if (userDoc.exists) {
        final userData = userDoc.data();
        displayName = userData?['displayName'] as String?;
        university = userData?['university'] as String?;
      }

      // NEDEN: Atomic batch write — game + user stats + leaderboard.
      // Biri başarısız olursa hiçbiri yazılmaz (consistency).
      await _gameDatasource.submitGame(
        session: session,
        userId: userId,
        displayName: displayName,
        university: university,
      );

      return const Right(null);
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('[GAME] Firebase error in submitGame: ${e.code}');
      }
      return Left(ServerFailure(
        'Oyun kaydedilemedi. Lütfen tekrar deneyin.',
        code: e.code,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('[GAME] Error in submitGame: $e');
      }
      return const Left(ServerFailure(
        'Oyun kaydedilirken beklenmeyen bir hata oluştu.',
      ));
    }
  }

  // ─────────────────────────────────────────────
  // GAME HISTORY
  // ─────────────────────────────────────────────

  /// Kullanıcının oyun geçmişini getir.
  ///
  /// NEDEN: Profil sayfasında son oyunları gösterme.
  /// CLAUDE.md § Firestore Cost Optimization: max 10 oyun.
  Future<Either<Failure, List<GameSession>>> getGameHistory({
    int limit = 10,
  }) async {
    try {
      final userId = _requireAuthUserId();

      final games = await _gameDatasource.getUserGameHistory(
        userId: userId,
        limit: limit,
      );

      return Right(games);
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('[GAME] Firebase error in getGameHistory: ${e.code}');
      }
      return Left(ServerFailure(
        'Oyun geçmişi yüklenemedi.',
        code: e.code,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('[GAME] Error in getGameHistory: $e');
      }
      return const Left(ServerFailure('Oyun geçmişi yüklenemedi.'));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// FirebaseFirestore instance — submitGame'de user profili okumak için.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Mevcut auth user ID'yi al.
  ///
  /// NEDEN: Firestore security rules userId kontrolü yapar.
  /// Auth olmadan game CRUD mümkün değil.
  String _requireAuthUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ServerFailure(
        'Oturum açmanız gerekiyor.',
        code: 'not-authenticated',
      );
    }
    return user.uid;
  }
}
