// lib/features/game/presentation/providers/game_notifier.dart
//
// NEDEN: Auth notifier pattern'ı — StateNotifier<GameState>.
// Tüm oyun akışı burada yönetilir: başlatma, timer, test isteme,
// tanı gönderme, sonraki vaka, oyun bitişi.
//
// Sprint 4 güncellemesi: Oyun bitince Firestore'a atomic batch write.
// SubmitGameUsecase ile skor kaydedilir (game + user stats + leaderboard).
//
// Referans: auth_notifier.dart pattern'ı
//           vcguide.md § Timer System (dispose cleanup)
//           vcguide.md § Edge Case 3 (test time cost)
//           vcguide.md § Edge Case 5 (duplicate submit — isSubmitting flag)
//           database_schema.md § Submit Game (Atomic Update)
//           app_constants.dart (gameDurationSeconds, testTimeCostSeconds)

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/medical_case.dart';
import '../../domain/usecases/start_game.dart';
import '../../domain/usecases/submit_diagnosis.dart';
import '../../domain/usecases/submit_game_usecase.dart';
import 'game_state.dart';

/// Game state notifier — tüm oyun akışı.
///
/// NEDEN: StateNotifier pattern — immutable state, tek yönlü veri akışı.
/// Timer burada yönetilir, dispose'da cleanup yapılır (memory leak önleme).
///
/// Sprint 4: Oyun bitince SubmitGameUsecase çağrılarak Firestore'a
/// atomic batch write yapılır (game + user stats + leaderboard).
class GameNotifier extends StateNotifier<GameState> {
  final StartGame _startGame;
  final SubmitDiagnosis _submitDiagnosis;
  final SubmitGameUsecase _submitGameUsecase;

  Timer? _timer;

  // NEDEN: Duplicate submit koruması — vcguide.md § Edge Case 5.
  // Firestore'a yazma işlemi sırasında tekrar submit engellensin.
  bool _isSubmittingToFirestore = false;

  // NEDEN: Duplicate diagnosis submit koruması.
  // Ağ gecikmesinde kullanıcı butona tekrar basarsa ikinci submit engellensin.
  bool _isSubmittingDiagnosis = false;

  GameNotifier({
    required StartGame startGame,
    required SubmitDiagnosis submitDiagnosis,
    required SubmitGameUsecase submitGameUsecase,
  })  : _startGame = startGame,
        _submitDiagnosis = submitDiagnosis,
        _submitGameUsecase = submitGameUsecase,
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
      state = GameOver(session: updatedSession, isSubmitting: true);
      // NEDEN: Oyun bitti — Firestore'a kaydet.
      _submitGameToFirestore(updatedSession);
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

    // NEDEN: Ağ gecikmesinde buton spam'ini engelle.
    // _isSubmittingToFirestore pattern'ı ile aynı mantık.
    if (_isSubmittingDiagnosis) return;
    _isSubmittingDiagnosis = true;

    _stopTimer();

    try {
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
            state = GameOver(
              session: diagnosisResult.updatedSession,
              isSubmitting: true,
            );
            // NEDEN: Oyun bitti — Firestore'a kaydet.
            _submitGameToFirestore(diagnosisResult.updatedSession);
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
    } finally {
      // NEDEN: Başarı veya hata — flag'i sıfırla (CLAUDE.md § Form Submission).
      _isSubmittingDiagnosis = false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FIRESTORE SUBMIT
  // ═══════════════════════════════════════════════════════════

  /// Oyunu Firestore'a kaydet — atomic batch write.
  ///
  /// NEDEN: database_schema.md § Submit Game (Atomic Update).
  /// Game + user stats + weekly leaderboard + monthly leaderboard
  /// tek batch'te yazılır. FieldValue.increment ile race condition yok.
  ///
  /// vcguide.md § Edge Case 5: _isSubmittingToFirestore flag ile
  /// duplicate submit önlenir (ağ gecikmesinde buton spam'i).
  ///
  /// CLAUDE.md § Error Handling: "Wrap ALL async operations in try-catch"
  Future<void> _submitGameToFirestore(GameSession session) async {
    debugPrint('[GAME-NOTIFIER] _submitGameToFirestore called — '
        'gameId=${session.id} status=${session.status} '
        'totalScore=${session.totalScore} '
        'casesCompleted=${session.casesCompleted}');

    // NEDEN: Duplicate submit koruması — flag kontrolü.
    // Bu method _handleTimeOut ve submitDiagnosis'ten çağrılabilir.
    if (_isSubmittingToFirestore) return;
    _isSubmittingToFirestore = true;

    try {
      final result = await _submitGameUsecase(session);

      // NEDEN: StateNotifier dispose edilmişse state güncelleme yapma.
      // autoDispose provider ile ekrandan çıkınca dispose olur.
      if (!mounted) return;

      result.fold(
        (failure) {
          if (kDebugMode) {
            print('[GAME] Submit to Firestore failed: ${failure.message}');
          }
          final currentState = state;
          if (currentState is GameOver) {
            state = currentState.copyWith(
              isSubmitting: false,
              submitError: failure.message,
            );
          }
        },
        (_) {
          final currentState = state;
          if (currentState is GameOver) {
            state = currentState.copyWith(
              isSubmitting: false,
              isSubmitted: true,
            );
          }
        },
      );
    } catch (e) {
      // NEDEN: Beklenmeyen hata — UI'da hata mesajı göster ama crash olmasın.
      if (kDebugMode) {
        print('[GAME] Unexpected error submitting to Firestore: $e');
      }
      if (!mounted) return;
      final currentState = state;
      if (currentState is GameOver) {
        state = currentState.copyWith(
          isSubmitting: false,
          submitError: 'Skor kaydedilirken hata oluştu.',
        );
      }
    } finally {
      _isSubmittingToFirestore = false;
    }
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
      state = GameOver(session: session, isSubmitting: true);
      // NEDEN: Son vaka sonucu ekranından geçiş — oyun bitmişse kaydet.
      _submitGameToFirestore(session);
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
