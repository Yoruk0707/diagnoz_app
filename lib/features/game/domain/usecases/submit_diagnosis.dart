// lib/features/game/domain/usecases/submit_diagnosis.dart
//
// NEDEN: Tanı gönderme iş kuralları burada.
// Doğru/yanlış kontrolü, skor hesaplama, pas hakkı yönetimi.
//
// Referans: masterplan.md § Core Game Loop, § Scoring
//           vcguide.md § Edge Case 2 (Score Bounds)
//           app_constants.dart (passesPerGame, testTimeCostSeconds)

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/game_session.dart';

/// Tanı sonucu — use case'in döndüğü değer.
///
/// NEDEN: UI'ın ihtiyaç duyduğu tüm bilgiyi tek objede topla.
class DiagnosisResult {
  final bool isCorrect;
  final double score;
  final String correctDiagnosis;
  final CaseResult caseResult;
  final GameSession updatedSession;

  const DiagnosisResult({
    required this.isCorrect,
    required this.score,
    required this.correctDiagnosis,
    required this.caseResult,
    required this.updatedSession,
  });
}

/// Tanı gönderme use case.
///
/// NEDEN: İş kuralları:
/// 1. Tanıyı correctDiagnosis ile karşılaştır
/// 2. Doğru → skor hesapla, sonraki vakaya geç
/// 3. Yanlış → pas hakkı düşür, pas=0 ise oyun biter (eleme)
/// 4. Sprint 4'te: server-side validation (timeLeft, score)
class SubmitDiagnosis {
  const SubmitDiagnosis();

  /// [session] mevcut oyun oturumu.
  /// [diagnosis] kullanıcının girdiği tanı.
  /// [timeLeft] kalan süre (saniye).
  /// [testsRequested] istenen testlerin ID listesi.
  ///
  /// Başarılı → Right(DiagnosisResult)
  /// Hata → Left(GameFailure)
  Future<Either<Failure, DiagnosisResult>> call({
    required GameSession session,
    required String diagnosis,
    required int timeLeft,
    List<String> testsRequested = const [],
  }) async {
    // NEDEN: Oyun devam etmiyorsa tanı kabul edilmez.
    if (session.isGameOver) {
      return Left(GameFailure.alreadySubmitted());
    }

    final currentCase = session.currentCase;
    if (currentCase == null) {
      return Left(GameFailure.noPasses()); // NEDEN: Vaka kalmadı
    }

    // NEDEN: Tanı karşılaştırma — case insensitive, trim.
    // Sprint 5: correctDiagnosis artık cases_private koleksiyonundan geliyor.
    // getCases() → _enrichCasesWithPrivateData() zinciri ile entity'ye dolduruluyor.
    // DevTools'ta cases incelendiğinde doğru cevap görünmez.
    final isCorrect = _matchDiagnosis(
      userDiagnosis: diagnosis,
      correctDiagnosis: currentCase.correctDiagnosis,
      alternatives: currentCase.alternativeDiagnoses,
    );

    // NEDEN: Skor hesaplama — CaseResult.calculateScore kullanır.
    // Zorluk çarpanı: easy=1.0×, medium=1.25×, hard=1.5×.
    // vcguide.md § Edge Case 2: negatif/overflow koruması içeride.
    final score = isCorrect
        ? CaseResult.calculateScore(timeLeft, currentCase.difficulty)
        : 0.0;

    final caseResult = CaseResult(
      caseId: currentCase.id,
      testsRequested: testsRequested,
      diagnosis: diagnosis,
      isCorrect: isCorrect,
      timeSpent: session.mode == GameMode.rush
          ? (120 - timeLeft) // NEDEN: Rush'ta 120s başlangıç
          : 0,
      timeLeft: timeLeft,
      score: score,
    );

    // NEDEN: Session güncelleme — immutable copyWith pattern.
    final updatedResults = [...session.caseResults, caseResult];
    final newTotalScore = session.totalScore + score;
    final newPassesLeft = isCorrect
        ? session.passesLeft
        : session.passesLeft - 1; // NEDEN: Yanlış → pas hakkı düşer

    // NEDEN: Oyun bitiş koşulları:
    // 1. Pas hakkı bitti (eleme) — masterplan.md § Rush Mode
    // 2. Tüm vakalar tamamlandı (victory)
    final isEliminated = !isCorrect && newPassesLeft < 0;
    final allCasesDone = session.currentCaseIndex + 1 >= session.totalCases;

    final newStatus = isEliminated || allCasesDone
        ? GameStatus.completed
        : GameStatus.inProgress;

    final updatedSession = session.copyWith(
      status: newStatus,
      currentCaseIndex: session.currentCaseIndex + 1,
      caseResults: updatedResults,
      passesLeft: newPassesLeft < 0 ? 0 : newPassesLeft,
      totalScore: newTotalScore,
      endTime: newStatus == GameStatus.completed ? DateTime.now() : null,
    );

    return Right(DiagnosisResult(
      isCorrect: isCorrect,
      score: score,
      correctDiagnosis: currentCase.correctDiagnosis,
      caseResult: caseResult,
      updatedSession: updatedSession,
    ));
  }

  /// Tanı eşleştirme — case insensitive, trim, alternatifler dahil.
  ///
  /// NEDEN: Kullanıcı "miyokard enfarktüsü" yazabilir,
  /// doğru cevap "Miyokard Enfarktüsü" olabilir.
  /// Alternatifler: "Kalp krizi", "MI", "STEMI" vs.
  bool _matchDiagnosis({
    required String userDiagnosis,
    required String correctDiagnosis,
    required List<String> alternatives,
  }) {
    final userNorm = userDiagnosis.trim().toLowerCase();
    if (userNorm.isEmpty) return false;

    // NEDEN: Ana tanı kontrolü
    if (userNorm == correctDiagnosis.trim().toLowerCase()) return true;

    // NEDEN: Alternatif tanılar kontrolü
    for (final alt in alternatives) {
      if (userNorm == alt.trim().toLowerCase()) return true;
    }

    return false;
  }
}
