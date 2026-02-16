/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - game_repository.dart (Interface)
/// ═══════════════════════════════════════════════════════════════
/// 
/// PURPOSE: Game repository interface for domain layer
/// 
/// ⚠️  CRITICAL NOTES (vcguide.md):
/// 
/// 1. SERVER-SIDE VALIDATION
///    - startGame() stores serverTimestamp in Firestore
///    - submitDiagnosis() validates time on server
///    - Client timer is UI only
/// 
/// 2. ATOMIC OPERATIONS
///    - Score updates use FieldValue.increment()
///    - Batch writes for game completion
/// 
/// 3. IDEMPOTENCY
///    - Test requests check if already requested
///    - Diagnosis submit checks if already submitted
/// 
/// METHODS:
/// 
/// 1. startGame(mode)
///    - Creates game document with serverTimestamp
///    - Loads 5 random cases
///    - Returns GameState
/// 
/// 2. submitDiagnosis(gameId, caseId, diagnosis, clientTimeSpent)
///    - Validates on server (time check)
///    - Returns CaseResult
/// 
/// 3. requestTest(gameId, caseId, testType)
///    - Idempotent (same test = same result)
///    - Returns TestResult
/// 
/// 4. endGame(gameId)
///    - Calculates final score
///    - Updates leaderboards (atomic)
/// 
/// EXAMPLE:
/// ```dart
/// abstract class GameRepository {
///   /// Start new game
///   /// WHY: Stores startTime on server (vcguide.md § Timer)
///   Future<Either<Failure, GameState>> startGame({
///     required String userId,
///     required GameMode mode,
///   });
///   
///   /// Get cases for game
///   Future<Either<Failure, List<Case>>> getCasesForGame({
///     required String gameId,
///   });
///   
///   /// Submit diagnosis for current case
///   /// WHY: Server validates time (vcguide.md § Timer)
///   Future<Either<Failure, DiagnosisResult>> submitDiagnosis({
///     required String gameId,
///     required String caseId,
///     required String diagnosis,
///     required int clientTimeSpent,
///   });
///   
///   /// Request test result
///   /// WHY: Idempotent - same test returns cached result
///   /// (vcguide.md § Edge Case 3)
///   Future<Either<Failure, TestResult>> requestTest({
///     required String gameId,
///     required String caseId,
///     required String testType,
///   });
///   
///   /// Use a pass after wrong answer
///   Future<Either<Failure, int>> usePass({
///     required String gameId,
///   });
///   
///   /// End game and update leaderboards
///   /// WHY: Atomic operation (vcguide.md § Leaderboard)
///   Future<Either<Failure, GameSummary>> endGame({
///     required String gameId,
///   });
///   
///   /// Get user's game history
///   Future<Either<Failure, List<GameSummary>>> getGameHistory({
///     required String userId,
///     int limit = 10,
///   });
/// }
/// 
/// enum GameMode { rush, zen, pvp, branch }
/// 
/// class DiagnosisResult {
///   final bool isCorrect;
///   final String correctDiagnosis;
///   final double score;
///   final int serverTimeSpent;
/// }
/// 
/// class TestResult {
///   final String testType;
///   final String type; // text, image, both
///   final String? value;
///   final String? imageUrl;
///   final bool isAbnormal;
/// }
/// 
/// class GameSummary {
///   final String gameId;
///   final double totalScore;
///   final int casesCompleted;
///   final int correctAnswers;
///   final DateTime completedAt;
///   final List<CaseResult> caseResults;
/// }
/// ```

// TODO: Implement GameRepository interface
