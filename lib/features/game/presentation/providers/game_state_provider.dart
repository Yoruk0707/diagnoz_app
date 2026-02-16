/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - game_state_provider.dart
/// ═══════════════════════════════════════════════════════════════
/// 
/// PURPOSE: Game state management with Riverpod
/// 
/// RESPONSIBILITIES:
/// - Track current game state
/// - Handle case transitions
/// - Manage passes
/// - Coordinate with timer
/// - Submit to backend
/// 
/// CRITICAL RULES (vcguide.md):
/// 
/// 1. Test Request (Edge Case 3):
///    - Check time >= 10 before deducting
///    - Prevent duplicate test requests
///    - Optimistic update + rollback on error
/// 
/// 2. Form Submission (Edge Case 5):
///    - Disable submit during loading
///    - Backend idempotency check
/// 
/// 3. Score Calculation (Edge Case 2):
///    - Client-side for display only
///    - Server recalculates on submit
/// 
/// EXAMPLE:
/// ```dart
/// @riverpod
/// class GameState extends _$GameState {
///   @override
///   GameStateEntity build() {
///     return const GameStateEntity.initial();
///   }
///   
///   /// Start new game
///   Future<void> startGame(GameMode mode) async {
///     state = state.copyWith(status: GameStatus.loading);
///     
///     final result = await ref.read(gameRepositoryProvider)
///         .startGame(userId: userId, mode: mode);
///     
///     result.fold(
///       (failure) => state = state.copyWith(
///         status: GameStatus.initial,
///         lastError: failure.message,
///       ),
///       (gameState) {
///         state = gameState.copyWith(status: GameStatus.playing);
///         ref.read(timerProvider.notifier).start();
///       },
///     );
///   }
///   
///   /// Request a test
///   /// WHY: vcguide.md § Edge Case 3
///   Future<void> requestTest(String testType) async {
///     // 1. Check sufficient time
///     if (state.timeLeft < 10) {
///       _showError('Yetersiz süre!');
///       return;
///     }
///     
///     // 2. Check duplicate
///     if (state.requestedTests.contains(testType)) {
///       _showError('Test zaten istendi!');
///       return;
///     }
///     
///     // 3. Optimistic update
///     final previousState = state;
///     state = state.copyWith(
///       requestedTests: [...state.requestedTests, testType],
///     );
///     
///     // 4. Deduct time
///     ref.read(timerProvider.notifier).deductTime(10);
///     
///     // 5. Backend request
///     final result = await ref.read(gameRepositoryProvider)
///         .requestTest(
///           gameId: state.gameId,
///           caseId: state.currentCase!.id,
///           testType: testType,
///         );
///     
///     result.fold(
///       (failure) {
///         // 6. Rollback on error
///         state = previousState;
///         ref.read(timerProvider.notifier).deductTime(-10);
///         _showError(failure.message);
///       },
///       (testResult) {
///         state = state.copyWith(
///           testResults: {
///             ...state.testResults,
///             testType: testResult,
///           },
///         );
///       },
///     );
///   }
///   
///   /// Submit diagnosis
///   /// WHY: vcguide.md § Edge Case 5 - prevent double submit
///   Future<void> submitDiagnosis(String diagnosis) async {
///     if (state.status == GameStatus.submitting) {
///       return; // Prevent double submit
///     }
///     
///     state = state.copyWith(status: GameStatus.submitting);
///     
///     final result = await ref.read(gameRepositoryProvider)
///         .submitDiagnosis(
///           gameId: state.gameId,
///           caseId: state.currentCase!.id,
///           diagnosis: diagnosis,
///           clientTimeSpent: 120 - state.timeLeft,
///         );
///     
///     result.fold(
///       (failure) {
///         state = state.copyWith(
///           status: GameStatus.playing,
///           lastError: failure.message,
///         );
///       },
///       (diagnosisResult) {
///         _handleDiagnosisResult(diagnosisResult);
///       },
///     );
///   }
///   
///   /// Handle timeout
///   void handleTimeout() {
///     state = state.copyWith(status: GameStatus.gameOver);
///   }
///   
///   /// Move to next case
///   void nextCase() {
///     if (state.currentCaseIndex + 1 >= state.totalCases) {
///       _endGame();
///       return;
///     }
///     
///     state = state.copyWith(
///       currentCaseIndex: state.currentCaseIndex + 1,
///       status: GameStatus.playing,
///       requestedTests: [],
///       testResults: {},
///     );
///     
///     ref.read(timerProvider.notifier).reset();
///     ref.read(timerProvider.notifier).start();
///   }
/// }
/// ```

// TODO: Implement GameState provider with Riverpod
