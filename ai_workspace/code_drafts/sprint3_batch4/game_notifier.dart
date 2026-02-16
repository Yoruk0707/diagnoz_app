// lib/features/game/presentation/providers/game_notifier.dart
//
// NEDEN: Auth notifier pattern'ı — StateNotifier<GameState>.
// Tüm oyun akışı burada yönetilir: başlatma, timer, test isteme,
// tanı gönderme, sonraki vaka, oyun bitişi.
//
// Referans: auth_notifier.dart pattern'ı
//           vcguide.md § Timer System (dispose cleanup)
//           vcguide.md § Edge Case 3 (test time cost)
//           app_constants.dart (gameDurationSeconds, testTimeCostSeconds)

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/medical_case.dart';
import '../../domain/usecases/start_game.dart';
import '../../domain/usecases/submit_diagnosis.dart';
import 'game_state.dart';

/// Game state notifier — tüm oyun akışı.
///
/// NEDEN: StateNotifier pattern — immutable state, tek yönlü veri akışı.
/// Timer burada yönetilir, dispose'da cleanup yapılır (memory leak önleme).
class GameNotifier extends StateNotifier<GameState> {
  final StartGame _startGame;
  final SubmitDiagnosis _submitDiagnosis;

  Timer? _timer;

  // NEDEN: Timer cleanup için referans tutuyoruz.
  // vcguide.md § Timer System: dispose()'da iptal edilmeli.

  GameNotifier({
    required StartGame startGame,
    required SubmitDiagnosis submitDiagnosis,
  })  : _startGame = startGame,
        _submitDiagnosis = submitDiagnosis,
        super(const GameInitial());

  // ═══════════════════════════════════════════════════════════
  // GAME LIFECYCLE
  // ═══════════════════════════════════════════════════════════

  /// Yeni oyun başlat.
  ///
  /// NEDEN: Loading state → repository'den vakalar al → timer başlat.
  Future<void> startNewGame({GameMode mode = GameMode.rush}) async {
    state = const GameLoading();

    final result = await _startGame(mode: mode);

    result.fold(
      (failure) => state = GameError(
        failure: failure,
        previousState: const GameInitial(),
      ),
      (session) {
        state = GamePlaying(
          session: session,
          timeLeft: AppConstants.gameDurationSeconds,
        );
        // NEDEN: Rush mode'da timer başlat.
        if (mode == GameMode.rush) {
          _startTimer();
        }
      },
    );
  }

  /// Ana ekrana dön — oyunu sıfırla.
  void resetGame() {
    _stopTimer();
    state = const GameInitial();
  }

  // ═══════════════════════════════════════════════════════════
  // TIMER
  // ═══════════════════════════════════════════════════════════

  /// Timer başlat — her saniye state güncelle.
  ///
  /// NEDEN: vcguide.md § Timer System.
  /// Client timer sadece UI için — server validation Sprint 4'te.
  void _startTimer() {
    _stopTimer(); // NEDEN: Önceki timer varsa temizle (double timer bug önleme).

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentState = state;
      if (currentState is GamePlaying) {
        final newTime = currentState.timeLeft - 1;

        if (newTime <= 0) {
          // NEDEN: Süre doldu — vakayı yanlış say, pas hakkı düşür.
          _handleTimeOut(currentState);
        } else {
          state = GamePlaying(
            session: currentState.session,
            timeLeft: newTime,
            requestedTests: currentState.requestedTests,
            revealedTests: currentState.revealedTests,
          );
        }
      }
    });
  }

  /// Timer durdur.
  ///
  /// NEDEN: Memory leak önleme — vcguide.md § Timer System.
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Süre doldu — vakayı timeout olarak işaretle.
  void _handleTimeOut(GamePlaying currentState) {
    _stopTimer();

    final session = currentState.session;
    final newPassesLeft = session.passesLeft - 1;

    // NEDEN: Timeout = yanlış cevap gibi, pas hakkı düşer.
    final caseResult = CaseResult(
      caseId: session.currentCase?.id ?? '',
      isCorrect: false,
      timeSpent: AppConstants.gameDurationSeconds,
      timeLeft: 0,
      score: 0.0,
      testsRequested: currentState.requestedTests,
      diagnosis: '',
    );

    final updatedResults = [...session.caseResults, caseResult];
    final isEliminated = newPassesLeft < 0;
    final allCasesDone = session.currentCaseIndex + 1 >= session.totalCases;

    final updatedSession = session.copyWith(
      status: isEliminated || allCasesDone
          ? GameStatus.completed
          : GameStatus.inProgress,
      currentCaseIndex: session.currentCaseIndex + 1,
      caseResults: updatedResults,
      passesLeft: newPassesLeft < 0 ? 0 : newPassesLeft,
      endTime: isEliminated || allCasesDone ? DateTime.now() : null,
    );

    if (isEliminated || allCasesDone) {
      state = GameOver(session: updatedSession);
    } else {
      // NEDEN: Timeout sonucu göster, sonra sonraki vakaya geç.
      state = GameCaseResult(
        session: updatedSession,
        isCorrect: false,
        score: 0.0,
        correctDiagnosis: session.currentCase?.correctDiagnosis ?? '',
        userDiagnosis: '',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // TEST REQUEST
  // ═══════════════════════════════════════════════════════════

  /// Test iste — süre -10s, sonuç göster.
  ///
  /// NEDEN: masterplan.md § Test Request System.
  /// vcguide.md § Edge Case 3: test maliyeti kontrol.
  /// Aynı test tekrar istenirse maliyet yok (idempotency).
  void requestTest(String testId) {
    final currentState = state;
    if (currentState is! GamePlaying) return;

    final currentCase = currentState.currentCase;
    if (currentCase == null) return;

    // NEDEN: Aynı test zaten istenmişse, tekrar maliyet alma.
    if (currentState.requestedTests.contains(testId)) return;

    // NEDEN: Yeterli süre var mı? (-10s)
    final newTime = currentState.timeLeft - AppConstants.testTimeCostSeconds;
    if (newTime <= 0) {
      // NEDEN: Süre yetmiyor — timeout tetikle.
      _handleTimeOut(currentState);
      return;
    }

    // NEDEN: Test sonucunu bul.
    final testResult = currentCase.availableTests.firstWhere(
      (t) => t.testId == testId,
      orElse: () => const TestResult(
        testId: '',
        category: TestCategory.lab,
        displayName: 'Bilinmeyen Test',
      ),
    );

    if (testResult.testId.isEmpty) return;

    // NEDEN: State güncelle — yeni test ekle, süre düşür.
    final updatedTests = [...currentState.requestedTests, testId];
    final updatedRevealed = Map<String, TestResult>.from(currentState.revealedTests)
      ..[testId] = testResult;

    state = GamePlaying(
      session: currentState.session,
      timeLeft: newTime,
      requestedTests: updatedTests,
      revealedTests: updatedRevealed,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DIAGNOSIS SUBMISSION
  // ═══════════════════════════════════════════════════════════

  /// Tanı gönder.
  ///
  /// NEDEN: submit_diagnosis use case çağrılır.
  /// Doğru → skor, yanlış → pas hakkı düşer.
  /// vcguide.md § Form Submit Edge Case: duplicate submit koruması
  /// state kontrolüyle sağlanır (GamePlaying değilse işlem yapılmaz).
  Future<void> submitDiagnosis(String diagnosis) async {
    final currentState = state;
    if (currentState is! GamePlaying) return; // NEDEN: Duplicate submit koruması

    _stopTimer();

    final result = await _submitDiagnosis(
      session: currentState.session,
      diagnosis: diagnosis,
      timeLeft: currentState.timeLeft,
      testsRequested: currentState.requestedTests,
    );

    result.fold(
      (failure) {
        state = GameError(
          failure: failure,
          previousState: currentState,
        );
      },
      (diagnosisResult) {
        if (diagnosisResult.updatedSession.isGameOver) {
          state = GameOver(session: diagnosisResult.updatedSession);
        } else {
          state = GameCaseResult(
            session: diagnosisResult.updatedSession,
            isCorrect: diagnosisResult.isCorrect,
            score: diagnosisResult.score,
            correctDiagnosis: diagnosisResult.correctDiagnosis,
            userDiagnosis: diagnosis,
          );
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════

  /// Sonraki vakaya geç — case result ekranından çağrılır.
  ///
  /// NEDEN: Timer'ı yeniden başlat, test listesini sıfırla.
  void nextCase() {
    final currentState = state;
    if (currentState is! GameCaseResult) return;

    final session = currentState.session;

    if (session.isGameOver) {
      state = GameOver(session: session);
      return;
    }

    state = GamePlaying(
      session: session,
      timeLeft: AppConstants.gameDurationSeconds,
    );

    // NEDEN: Yeni vaka, yeni timer.
    _startTimer();
  }

  // ═══════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════

  /// NEDEN: vcguide.md § Timer System — memory leak önleme.
  /// StateNotifier dispose olunca timer iptal edilmeli.
  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
