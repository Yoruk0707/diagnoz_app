// lib/features/game/domain/repositories/game_repository.dart
//
// NEDEN: Domain layer Firebase/local data source'u bilmez.
// Sprint 3: LocalGameRepository (mock data) implement edecek.
// Sprint 4: FirebaseGameRepository implement edecek.
//
// Referans: auth_repository.dart pattern'ı (dartz Either + Failure)

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/game_session.dart';
import '../entities/medical_case.dart';

/// Game repository interface — domain layer.
///
/// NEDEN: Dependency Inversion. Data layer bu interface'i implement eder.
/// Sprint 3: LocalGameRepository (hardcoded mock cases)
/// Sprint 4: FirebaseGameRepository (Firestore + Cloud Functions)
abstract class GameRepository {
  /// Yeni oyun başlat — rastgele [casesPerGame] vaka seç.
  ///
  /// [mode] oyun modu (Rush, Zen vs.)
  /// [specialty] opsiyonel — Branch mode'da filtre.
  ///
  /// Başarılı → Right(GameSession) — vakaları içerir.
  ///
  /// Olası hatalar:
  /// - [GameFailure] → yeterli vaka yok
  /// - [NetworkFailure] → Firestore'a ulaşılamadı (Sprint 4)
  Future<Either<Failure, GameSession>> startGame({
    required GameMode mode,
    Specialty? specialty,
  });

  /// Belirli bir vakanın test sonucunu getir.
  ///
  /// [caseId] hangi vaka.
  /// [testId] hangi test (lab_cbc, imaging_xray vs.)
  ///
  /// NEDEN: Test sonucu client'ta zaten var (mock data),
  /// ama interface Sprint 4'te Firestore'dan çekilecek şekilde hazır.
  ///
  /// Başarılı → Right(TestResult)
  Future<Either<Failure, TestResult>> getTestResult({
    required String caseId,
    required String testId,
  });

  /// Mevcut vakalar havuzundan vakaları getir.
  ///
  /// [count] kaç vaka istendiği.
  /// [specialty] opsiyonel filtre.
  ///
  /// NEDEN: startGame içinden çağrılır, ayrı method çünkü
  /// Sprint 4'te pagination/caching gerekebilir.
  Future<Either<Failure, List<MedicalCase>>> getCases({
    required int count,
    Specialty? specialty,
  });
}
