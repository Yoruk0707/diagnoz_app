/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - game_state.dart (Entity)
/// ═══════════════════════════════════════════════════════════════
/// 
/// PURPOSE: Game state entity for domain layer
/// 
/// GAME RULES (masterplan.md § Game Mechanics):
/// - 5 cases per game
/// - 120 seconds per case
/// - 2 passes total per game
/// - Test request = -10 seconds
/// 
/// STATES:
/// - initial: Before game starts
/// - loading: Loading cases
/// - playing: Active gameplay
/// - submitting: Diagnosis being validated
/// - caseComplete: Case finished, showing result
/// - gameOver: All cases done or eliminated
/// 
/// EXAMPLE:
/// ```dart
/// enum GameStatus {
///   initial,
///   loading,
///   playing,
///   submitting,
///   caseComplete,
///   gameOver,
/// }
/// 
/// class GameState extends Equatable {
///   final String gameId;
///   final GameStatus status;
///   final int currentCaseIndex;
///   final int totalCases;
///   final int timeLeft;
///   final int passesRemaining;
///   final List<CaseResult> completedCases;
///   final Case? currentCase;
///   final List<String> requestedTests;
///   final Map<String, TestResult> testResults;
///   final double totalScore;
///   final String? lastError;
///   
///   const GameState({
///     required this.gameId,
///     this.status = GameStatus.initial,
///     this.currentCaseIndex = 0,
///     this.totalCases = 5,
///     this.timeLeft = 120,
///     this.passesRemaining = 2,
///     this.completedCases = const [],
///     this.currentCase,
///     this.requestedTests = const [],
///     this.testResults = const {},
///     this.totalScore = 0.0,
///     this.lastError,
///   });
///   
///   /// Check if can request test (has enough time)
///   /// WHY: vcguide.md § Edge Case 3
///   bool get canRequestTest => timeLeft >= 10;
///   
///   /// Check if can continue after wrong answer
///   bool get canContinue => passesRemaining > 0;
///   
///   /// Check if game is complete
///   bool get isComplete => 
///     status == GameStatus.gameOver ||
///     currentCaseIndex >= totalCases;
///   
///   /// Create copy with updated fields
///   GameState copyWith({
///     String? gameId,
///     GameStatus? status,
///     int? currentCaseIndex,
///     int? timeLeft,
///     int? passesRemaining,
///     List<CaseResult>? completedCases,
///     Case? currentCase,
///     List<String>? requestedTests,
///     Map<String, TestResult>? testResults,
///     double? totalScore,
///     String? lastError,
///   }) {
///     return GameState(
///       gameId: gameId ?? this.gameId,
///       status: status ?? this.status,
///       currentCaseIndex: currentCaseIndex ?? this.currentCaseIndex,
///       totalCases: totalCases,
///       timeLeft: timeLeft ?? this.timeLeft,
///       passesRemaining: passesRemaining ?? this.passesRemaining,
///       completedCases: completedCases ?? this.completedCases,
///       currentCase: currentCase ?? this.currentCase,
///       requestedTests: requestedTests ?? this.requestedTests,
///       testResults: testResults ?? this.testResults,
///       totalScore: totalScore ?? this.totalScore,
///       lastError: lastError,
///     );
///   }
///   
///   @override
///   List<Object?> get props => [
///     gameId, status, currentCaseIndex, timeLeft, 
///     passesRemaining, totalScore,
///   ];
/// }
/// 
/// class CaseResult extends Equatable {
///   final String caseId;
///   final String diagnosis;
///   final bool isCorrect;
///   final int timeSpent;
///   final int timeLeft;
///   final double score;
///   final List<String> testsRequested;
///   
///   const CaseResult({
///     required this.caseId,
///     required this.diagnosis,
///     required this.isCorrect,
///     required this.timeSpent,
///     required this.timeLeft,
///     required this.score,
///     required this.testsRequested,
///   });
///   
///   @override
///   List<Object?> get props => [caseId, isCorrect, score];
/// }
/// ```

// TODO: Implement GameState entity
