// lib/features/game/domain/usecases/submit_game_usecase.dart
//
// NEDEN: Oyun bitince Firestore'a kaydetme use case'i.
// Input validation burada, data yazma repository'de.
// SubmitDiagnosis'ten farklı: bu use case tüm oyunu kaydeder,
// o sadece tek vaka tanısını değerlendirir.
//
// Referans: vcguide.md § Edge Case 2 (Score Calculation — validation)
//           vcguide.md § Edge Case 5 (Duplicate Submit)
//           database_schema.md § Submit Game (Atomic Update)
//           CLAUDE.md § Form Submission — Duplicate Prevention

import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../entities/game_session.dart';
import '../../data/repositories/firebase_game_repository.dart';

/// Tamamlanmış oyunu Firestore'a kaydetme use case.
///
/// NEDEN: İş kuralları (validation) repository'den ayrılır.
/// 1. Score range kontrolü (0-12 per case, 0-60 total)
/// 2. TimeLeft kontrolü (0-120)
/// 3. PassesLeft kontrolü (0-2)
/// 4. Oyun durumu kontrolü (completed/timeout olmalı)
/// 5. Repository'ye delege et (atomic batch write)
class SubmitGameUsecase {
  final FirebaseGameRepository _repository;

  const SubmitGameUsecase(this._repository);

  /// Oyunu Firestore'a kaydet.
  ///
  /// [session] tamamlanmış oyun oturumu.
  ///
  /// Başarılı → Right(void)
  /// Hata → Left(Failure)
  ///
  /// NEDEN: Use case seviyesinde validation yapılır.
  /// Client-side manipulation tespiti (score/time tampering).
  /// vcguide.md § Edge Case 2: "timeLeft can be 999 (manipulation)"
  Future<Either<Failure, void>> call(GameSession session) async {
    // ─── 1. Oyun durumu kontrolü ───
    // NEDEN: Sadece tamamlanmış veya timeout olmuş oyunlar kaydedilir.
    // inProgress veya abandoned oyunlar henüz bitmemiş — submit edilemez.
    if (session.status != GameStatus.completed &&
        session.status != GameStatus.timeout) {
      return Left(GameFailure.alreadySubmitted());
    }

    // ─── 2. NaN/Infinity kontrolü ───
    // NEDEN: double.nan ve double.infinity range check'leri bypass eder
    // (NaN < 0 == false, NaN > 60 == false → validation geçer).
    // Önce isFinite kontrolü, sonra range check yapılmalı.
    if (!session.totalScore.isFinite) {
      return Left(GameFailure.timerTampering());
    }
    for (final result in session.caseResults) {
      if (!result.score.isFinite) {
        return Left(GameFailure.timerTampering());
      }
    }

    // ─── 3. Score validation ───
    // NEDEN: vcguide.md § Edge Case 2 — manipülasyon koruması.
    // Her vaka skoru 0-12 aralığında olmalı.
    for (final result in session.caseResults) {
      if (result.score < AppConstants.minScorePerCase ||
          result.score > AppConstants.maxScorePerCase) {
        return Left(GameFailure.timerTampering());
      }

      // NEDEN: timeLeft 0-120 aralığında olmalı.
      // 120'den büyük = client timer manipülasyonu.
      if (result.timeLeft < 0 ||
          result.timeLeft > AppConstants.gameDurationSeconds) {
        return Left(GameFailure.timerTampering());
      }

      // NEDEN: timeSpent negatif olamaz ve 120'den büyük olamaz.
      if (result.timeSpent < 0 ||
          result.timeSpent > AppConstants.gameDurationSeconds) {
        return Left(GameFailure.timerTampering());
      }
    }

    // NEDEN: Total score kontrolü — max 60.0 (5 * 12.0).
    if (session.totalScore < 0 ||
        session.totalScore > AppConstants.maxTotalScore) {
      return Left(GameFailure.timerTampering());
    }

    // ─── 3. PassesLeft kontrolü ───
    // NEDEN: 0-2 aralığında olmalı, negatif = bug veya manipulation.
    if (session.passesLeft < 0 ||
        session.passesLeft > AppConstants.passesPerGame) {
      return Left(GameFailure.timerTampering());
    }

    // ─── 4. CaseResults length kontrolü ───
    // NEDEN: 0 vaka = boş oyun, casesPerGame'den fazla = manipulation.
    // En az 1, en fazla 5 vaka sonucu olmalı.
    if (session.caseResults.isEmpty ||
        session.caseResults.length > AppConstants.casesPerGame) {
      return Left(GameFailure.timerTampering());
    }

    // ─── 5. TotalScore tutarlılık kontrolü ───
    // NEDEN: session.totalScore, individual case score'ların toplamıyla
    // eşleşmeli. Eşleşmezse client-side score manipulation var.
    final calculatedTotal = session.caseResults
        .map((r) => r.score)
        .fold(0.0, (a, b) => a + b);
    if ((session.totalScore - calculatedTotal).abs() > 0.01) {
      return Left(GameFailure.timerTampering());
    }

    // ─── 6. TimeLeft + TimeSpent tutarlılık kontrolü ───
    // NEDEN: Her vaka için timeLeft + timeSpent ≈ gameDurationSeconds olmalı.
    // 2 saniyelik tolerans: timer tick ve async delay kaynaklı.
    // Büyük sapma = timer manipulation.
    for (final result in session.caseResults) {
      final timeSum = result.timeLeft + result.timeSpent;
      if ((timeSum - AppConstants.gameDurationSeconds).abs() > 2) {
        return Left(GameFailure.timerTampering());
      }
    }

    // ─── 7. CaseId duplicate kontrolü ───
    // NEDEN: Aynı vaka 2 kez gönderilmişse = replay attack veya bug.
    final caseIds = session.caseResults.map((r) => r.caseId).toSet();
    if (caseIds.length != session.caseResults.length) {
      return Left(GameFailure.timerTampering());
    }

    // ─── 8. Diagnosis string validation ───
    // NEDEN: Boş veya aşırı uzun diagnosis = manipulation veya XSS denemesi.
    // maxLength 200, trim sonrası boş string kontrolü.
    // Timeout vakaları null/boş diagnosis olabilir — sadece doğru cevaplarda kontrol.
    for (final result in session.caseResults) {
      final trimmed = result.diagnosis?.trim() ?? '';
      if (result.isCorrect && trimmed.isEmpty) {
        return Left(GameFailure.timerTampering());
      }
      if (trimmed.length > 200) {
        return Left(GameFailure.timerTampering());
      }
    }

    // ─── 9. Skor recompute validation ───
    // NEDEN: Client gönderdiği score'u bağımsızca doğrula.
    // Doğru cevap: (timeLeft / 100) * 10, clamp(0, 12).
    // Yanlış cevap veya timeout (diagnosis null): expectedScore = 0.
    // 0.01 tolerans: floating point aritmetik farkları.
    for (final result in session.caseResults) {
      final double expectedScore;
      if (result.isCorrect) {
        expectedScore =
            ((result.timeLeft / 100) * 10).clamp(0.0, 12.0);
      } else {
        expectedScore = 0.0;
      }
      if ((result.score - expectedScore).abs() > 0.01) {
        return Left(GameFailure.timerTampering());
      }
    }

    // ─── 10. PassesLeft tutarlılık kontrolü ───
    // NEDEN: passesLeft, yanlış cevap sayısıyla tutarlı olmalı.
    // passesUsed = yanlış cevaplı vaka sayısı (timeout hariç — diagnosis null).
    // Timeout vakaları da pas düşürür ama diagnosis null olur.
    // Yanlış cevap = !isCorrect && diagnosis != null (aktif yanlış tahmin).
    final passesUsed = session.caseResults
        .where((r) => !r.isCorrect && r.diagnosis != null)
        .length;
    final expectedPassesLeft = AppConstants.passesPerGame - passesUsed;
    if (session.passesLeft != expectedPassesLeft) {
      return Left(GameFailure.timerTampering());
    }

    // ─── 11. Repository'ye delege et ───
    // NEDEN: Validation geçti, Firestore'a atomic batch write.
    // game + user stats + leaderboard tek işlemde.
    return _repository.submitGame(session);
  }
}
