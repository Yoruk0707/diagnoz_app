/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - score_calculator.dart
/// ═══════════════════════════════════════════════════════════════
/// 
/// PURPOSE: Score calculation logic (vcguide.md § Edge Case 2)
/// 
/// ⚠️  CRITICAL: This formula is from masterplan.md
/// 
/// FORMULA: score = (timeLeft / 100) * 10
/// 
/// SCORE RANGES:
/// - Per case: 0.0 - 12.0 points
/// - Per game (5 cases): 0.0 - 60.0 points
/// 
/// EXAMPLES:
/// - 120s = 12.0 points (perfect, no tests)
/// - 100s = 10.0 points
/// - 80s = 8.0 points
/// - 52s = 5.2 points
/// - 0s = 0.0 points (timeout)
/// 
/// VALIDATION REQUIRED (vcguide.md):
/// 1. timeLeft < 0 → return 0.0 (timer bug)
/// 2. timeLeft > 120 → return 0.0 (manipulation)
/// 3. Clamp result to [0.0, 12.0]
/// 
/// BACKEND NOTE:
/// - Client-side calculation = UI only
/// - Server MUST recalculate on submit
/// - Never trust client score
/// 
/// EXAMPLE:
/// ```dart
/// abstract class ScoreCalculator {
///   /// Calculate score for a single case
///   /// WHY: Formula from masterplan.md § Game Mechanics
///   static double calculateCaseScore(int timeLeft) {
///     // WHY: Input validation (vcguide.md § Edge Case 2)
///     if (timeLeft < 0) return 0.0;
///     if (timeLeft > 120) return 0.0; // Manipulation attempt
///     
///     // WHY: Formula: (timeLeft / 100) * 10
///     final rawScore = (timeLeft / 100) * 10;
///     
///     // WHY: Defensive clamping
///     return rawScore.clamp(0.0, 12.0);
///   }
///   
///   /// Calculate total game score
///   static double calculateGameScore(List<int> timeLeftPerCase) {
///     return timeLeftPerCase
///         .map((t) => calculateCaseScore(t))
///         .fold(0.0, (sum, score) => sum + score);
///   }
/// }
/// ```
/// 
/// TEST CASES (vcguide.md):
/// ```dart
/// assert(calculateCaseScore(-10) == 0.0);   // Negative
/// assert(calculateCaseScore(0) == 0.0);     // Timeout
/// assert(calculateCaseScore(52) == 5.2);    // Normal
/// assert(calculateCaseScore(80) == 8.0);    // Normal
/// assert(calculateCaseScore(120) == 12.0);  // Perfect
/// assert(calculateCaseScore(999) == 0.0);   // Manipulation
/// ```

// TODO: Implement ScoreCalculator
