// lib/features/game/data/repositories/local_game_repository.dart
//
// NEDEN: Sprint 3 — GameRepository'nin mock data implementasyonu.
// Firestore yok, tüm veriler MockCases'dan gelir.
// Sprint 4'te FirebaseGameRepository ile değiştirilecek.
//
// Referans: auth → firebase_auth_repository.dart pattern'ı
//           game_repository.dart interface

import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/medical_case.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/mock_cases.dart';

/// Local game repository — mock data ile çalışır.
///
/// NEDEN: Sprint 3 MVP. Firestore bağımlılığı olmadan
/// core game loop test edilebilir.
class LocalGameRepository implements GameRepository {
  @override
  Future<Either<Failure, GameSession>> startGame({
    required GameMode mode,
    Specialty? specialty,
  }) async {
    try {
      // NEDEN: Vakaları getir ve karıştır.
      final casesResult = await getCases(
        count: AppConstants.casesPerGame,
        specialty: specialty,
      );

      return casesResult.fold(
        (failure) => Left(failure),
        (cases) {
          // NEDEN: Unique ID — Sprint 4'te Firestore doc ID olacak.
          final sessionId = 'game_${DateTime.now().millisecondsSinceEpoch}';

          final session = GameSession(
            id: sessionId,
            mode: mode,
            startTime: DateTime.now(),
            cases: cases,
            passesLeft: AppConstants.passesPerGame,
          );

          return Right(session);
        },
      );
    } catch (e) {
      // NEDEN: Beklenmeyen hata — crash önleme.
      return Left(GameFailure.timeExceeded()); // Generic game failure
    }
  }

  @override
  Future<Either<Failure, TestResult>> getTestResult({
    required String caseId,
    required String testId,
  }) async {
    try {
      // NEDEN: Mock data'dan vakayı bul.
      final targetCase = MockCases.allCases.firstWhere(
        (c) => c.id == caseId,
        orElse: () => throw Exception('Case not found: $caseId'),
      );

      // NEDEN: İstenen testi bul.
      final test = targetCase.availableTests.firstWhere(
        (t) => t.testId == testId,
        orElse: () => throw Exception('Test not found: $testId'),
      );

      return Right(test);
    } catch (e) {
      return Left(GameFailure.noPasses()); // NEDEN: Test bulunamadı
    }
  }

  @override
  Future<Either<Failure, List<MedicalCase>>> getCases({
    required int count,
    Specialty? specialty,
  }) async {
    try {
      var pool = List<MedicalCase>.from(MockCases.allCases);

      // NEDEN: Branch mode'da specialty filtresi.
      if (specialty != null) {
        pool = pool.where((c) => c.specialty == specialty).toList();
      }

      // NEDEN: Yeterli vaka yoksa hata dön.
      if (pool.length < count) {
        return Left(GameFailure.noPasses()); // NEDEN: Yeterli vaka yok
      }

      // NEDEN: Rastgele sıralama — her oyun farklı olsun.
      pool.shuffle();

      return Right(pool.take(count).toList());
    } catch (e) {
      return Left(GameFailure.noPasses());
    }
  }
}
