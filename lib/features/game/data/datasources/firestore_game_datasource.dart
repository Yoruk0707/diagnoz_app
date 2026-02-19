// lib/features/game/data/datasources/firestore_game_datasource.dart
//
// NEDEN: Firestore'a oyun kaydetme ve oyun geçmişi çekme datasource'u.
// Sprint 4 — FirebaseGameRepository bu datasource'u kullanacak.
//
// Referans: database_schema.md § games/{gameId}
//           database_schema.md § Submit Game (Atomic Update)
//           vcguide.md § Edge Case 4 (Race Condition — FieldValue.increment)
//           vcguide.md § Edge Case 5 (Duplicate Submit)
//           CLAUDE.md § Leaderboard Race Condition Prevention

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_utils.dart' as app_date;
import '../../domain/entities/game_session.dart';
import '../models/game_model.dart';

/// Firestore game datasource — games collection CRUD + atomic batch writes.
///
/// NEDEN: Data source layer doğrudan Firestore SDK ile konuşur.
/// Repository bu class'ı sarmalayıp Either<Failure, T> döndürür.
class FirestoreGameDatasource {
  final FirebaseFirestore _firestore;

  // NEDEN: DI ile test edilebilirlik. Mock Firestore inject edilebilir.
  FirestoreGameDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore games collection referansı.
  CollectionReference<Map<String, dynamic>> get _gamesRef =>
      _firestore.collection('games');

  // ─────────────────────────────────────────────
  // CREATE — Yeni oyun document'ı oluştur
  // ─────────────────────────────────────────────

  /// Yeni oyun document'ı oluştur ve doc ID döndür.
  ///
  /// NEDEN: Oyun başlarken in_progress status ile boş bir game document
  /// oluşturulur. Firestore auto-generated ID kullanılır.
  /// vcguide.md § Timer System: startTime server timestamp olmalı.
  Future<String> createGame({
    required String userId,
    required GameMode mode,
    required int totalCases,
  }) async {
    final docRef = _gamesRef.doc();

    await docRef.set({
      'userId': userId,
      'mode': mode.name,
      'status': 'in_progress',
      // NEDEN: Server timestamp — client timestamp manipüle edilebilir.
      // vcguide.md § Edge Case 1: client timer = UI only.
      'startTime': FieldValue.serverTimestamp(),
      'totalScore': 0.0,
      'passesLeft': AppConstants.passesPerGame,
      'casesCompleted': 0,
      'totalCases': totalCases,
      'cases': <Map<String, dynamic>>[],
    });

    return docRef.id;
  }

  // ─────────────────────────────────────────────
  // READ — Oyun bilgisi ve geçmiş
  // ─────────────────────────────────────────────

  /// Belirli bir oyunu ID ile getir.
  ///
  /// NEDEN: Oyun detay sayfası ve sonuç ekranı için.
  /// Maliyet: 1 read.
  Future<GameSession> getGameById(String gameId) async {
    final doc = await _gamesRef.doc(gameId).get();

    if (!doc.exists) {
      throw Exception('Game not found: $gameId');
    }

    return GameModel.fromFirestore(doc);
  }

  /// Kullanıcının oyun geçmişini getir (son N oyun).
  ///
  /// NEDEN: Profil sayfasında oyun geçmişi gösterimi.
  /// database_schema.md § Query Patterns: userId + startTime DESC.
  /// Composite index gerekli.
  ///
  /// Maliyet: [limit] read. Default 10 — AppConstants.gameHistoryMaxDisplay.
  /// CLAUDE.md § Firestore Cost Optimization: "Pagination: Load 20 items max"
  Future<List<GameSession>> getUserGameHistory({
    required String userId,
    int limit = 10,
  }) async {
    final snapshot = await _gamesRef
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => GameModel.fromFirestore(doc)).toList();
  }

  // ─────────────────────────────────────────────
  // SUBMIT — Oyun tamamlama (Atomic Batch Write)
  // ─────────────────────────────────────────────

  /// Tamamlanmış oyunu kaydet + user stats + leaderboard güncelle.
  ///
  /// NEDEN: database_schema.md § Submit Game (Atomic Update).
  /// 3 collection aynı anda güncellenmeli — biri başarısız olursa
  /// hiçbiri yazılmamalı (consistency).
  ///
  /// vcguide.md § Edge Case 4: ASLA read-then-write yapma!
  /// FieldValue.increment() ile atomic update.
  ///
  /// CLAUDE.md § "NEVER read-then-write scores (race condition!)"
  /// CLAUDE.md § "ALWAYS use FieldValue.increment() for atomic updates"
  /// CLAUDE.md § "Use batch writes for multi-document updates"
  Future<void> submitGame({
    required GameSession session,
    required String userId,
    required String? displayName,
    required String? university,
  }) async {
    debugPrint('[GAME-DS] submitGame batch write start — '
        'gameId=${session.id} userId=$userId '
        'totalScore=${session.totalScore} cases=${session.casesCompleted}');

    try {
      final batch = _firestore.batch();

      // ─── 1. Game document'ı yaz ───
      // NEDEN: Immutable history — bir kez yazılır, update/delete yasak.
      // database_schema.md § Security: "allow update, delete: if false"
      final gameRef = _gamesRef.doc(session.id);
      batch.set(gameRef, GameModel.toFirestore(session, userId: userId));
      debugPrint('[GAME-DS] batch op 1/4: game doc set');

      // ─── 2. User stats güncelle (atomic + merge) ───
      // NEDEN: FieldValue.increment() race condition önler.
      // vcguide.md § Edge Case 4: concurrent score update'ler kaybolmaz.
      // set+merge kullanılır çünkü user doc henüz olmayabilir.
      //
      // NEDEN: merge:true nested map ile deep merge yapar — sadece belirtilen
      // sub-field'lar güncellenir, stats içindeki diğer alanlar korunur.
      // mergeFields + FieldPath + FieldValue.increment web SDK'da uyumsuz
      // olabiliyor, bu yüzden merge:true tercih edilir.
      final userRef = _firestore.collection('users').doc(userId);
      batch.set(
        userRef,
        {
          'stats': {
            'totalGamesPlayed': FieldValue.increment(1),
            'totalCasesSolved': FieldValue.increment(session.casesCompleted),
            'weeklyScore': FieldValue.increment(session.totalScore),
            'monthlyScore': FieldValue.increment(session.totalScore),
          },
        },
        SetOptions(merge: true),
      );
      debugPrint('[GAME-DS] batch op 2/4: user stats set+merge');

      // ─── 3. Weekly leaderboard güncelle (atomic + merge) ───
      // NEDEN: Denormalized leaderboard — read maliyetini %50 düşürür.
      // database_schema.md § Denormalization Strategy.
      final now = DateTime.now();
      final weekNumber = app_date.getIsoWeekNumber(now);
      final year = now.year;
      final weekDocId = '${userId}_w${weekNumber}_$year';
      final weekRef =
          _firestore.collection('leaderboard_weekly').doc(weekDocId);

      // NEDEN: SetOptions(merge: true) — document yoksa oluşturur, varsa günceller.
      // İlk oyunda create, sonraki oyunlarda increment.
      batch.set(
        weekRef,
        {
          'userId': userId,
          'displayName': displayName ?? '',
          'university': university ?? '',
          'score': FieldValue.increment(session.totalScore),
          'casesPlayed': FieldValue.increment(session.casesCompleted),
          'gamesPlayed': FieldValue.increment(1),
          'weekNumber': weekNumber,
          'year': year,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('[GAME-DS] batch op 3/4: weekly leaderboard set+merge');

      // ─── 4. Monthly leaderboard güncelle (atomic + merge) ───
      final month = now.month;
      final monthDocId = '${userId}_m${month}_$year';
      final monthRef =
          _firestore.collection('leaderboard_monthly').doc(monthDocId);

      batch.set(
        monthRef,
        {
          'userId': userId,
          'displayName': displayName ?? '',
          'university': university ?? '',
          'score': FieldValue.increment(session.totalScore),
          'casesPlayed': FieldValue.increment(session.casesCompleted),
          'gamesPlayed': FieldValue.increment(1),
          'month': month,
          'year': year,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('[GAME-DS] batch op 4/4: monthly leaderboard set+merge');

      // NEDEN: Batch commit — 4 yazma işlemi tek atomik transaction.
      // Biri başarısız olursa hiçbiri yazılmaz.
      debugPrint('[GAME-DS] calling batch.commit()...');
      await batch.commit();
      debugPrint('[GAME-DS] batch write COMPLETE');
    } catch (e, stackTrace) {
      debugPrint('[GAME-DS] batch write ERROR: $e');
      debugPrint('[GAME-DS] stack trace: $stackTrace');
      // NEDEN: Hatayı yukarıya fırlat — repository catch'leyip Left döndürsün.
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  // NEDEN: _getIsoWeekNumber kaldırıldı — core/utils/date_utils.dart'a taşındı.
  // Write ve read tarafı aynı fonksiyonu kullanmalı (DRY).
}
