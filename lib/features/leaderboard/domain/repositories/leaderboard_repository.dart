/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - leaderboard_repository.dart (Interface)
/// ═══════════════════════════════════════════════════════════════
/// 
/// PURPOSE: Leaderboard repository interface
/// 
/// ⚠️  CRITICAL RULES (vcguide.md § Edge Case 4):
/// 
/// 1. RACE CONDITION PREVENTION
///    - Score updates MUST use FieldValue.increment()
///    - NEVER read-then-write
/// 
/// 2. CACHING (vcguide.md § Firebase Best Practices)
///    - Cache leaderboard for 5 minutes
///    - Reduces 50,000 reads → ~150 reads/day
/// 
/// 3. ATOMIC UPDATES
///    - Use batch writes for multi-document updates
///    - User stats + weekly + monthly in one transaction
/// 
/// METHODS:
/// 
/// 1. getWeeklyLeaderboard(limit)
///    - Returns top N entries for current week
///    - Cached for 5 minutes
/// 
/// 2. getMonthlyLeaderboard(limit)
///    - Returns top N entries for current month
///    - Cached for 5 minutes
/// 
/// 3. getUserRank(userId, period)
///    - Returns user's current rank
///    - May need additional query if not in top N
/// 
/// 4. updateScore(userId, score) - INTERNAL
///    - Called by game completion
///    - Uses atomic increment
/// 
/// EXAMPLE:
/// ```dart
/// abstract class LeaderboardRepository {
///   /// Get weekly leaderboard
///   /// WHY: Cached for 5 minutes (vcguide.md § Firebase Best Practices)
///   Future<Either<Failure, List<LeaderboardEntry>>> getWeeklyLeaderboard({
///     int limit = 50,
///     bool forceRefresh = false,
///   });
///   
///   /// Get monthly leaderboard
///   Future<Either<Failure, List<LeaderboardEntry>>> getMonthlyLeaderboard({
///     int limit = 50,
///     bool forceRefresh = false,
///   });
///   
///   /// Get user's rank in a period
///   Future<Either<Failure, UserRankInfo>> getUserRank({
///     required String userId,
///     required LeaderboardPeriod period,
///   });
///   
///   /// Update score atomically (called by game completion)
///   /// WHY: Must use FieldValue.increment (vcguide.md § Edge Case 4)
///   Future<Either<Failure, void>> updateScore({
///     required String userId,
///     required double scoreToAdd,
///     required int casesToAdd,
///     required int gamesToAdd,
///   });
/// }
/// 
/// enum LeaderboardPeriod { weekly, monthly }
/// 
/// class UserRankInfo {
///   final int rank;
///   final double score;
///   final int totalPlayers;
///   final int? rankChange; // null if first entry
/// }
/// ```
/// 
/// IMPLEMENTATION NOTE:
/// ```dart
/// class LeaderboardRepositoryImpl implements LeaderboardRepository {
///   final FirebaseFirestore _firestore;
///   
///   // WHY: In-memory cache (vcguide.md § Firebase Best Practices)
///   List<LeaderboardEntry>? _cachedWeekly;
///   DateTime? _weeklyCacheTime;
///   static const _cacheDuration = Duration(minutes: 5);
///   
///   @override
///   Future<Either<Failure, List<LeaderboardEntry>>> getWeeklyLeaderboard({
///     int limit = 50,
///     bool forceRefresh = false,
///   }) async {
///     // Check cache
///     if (!forceRefresh && 
///         _cachedWeekly != null && 
///         _weeklyCacheTime != null &&
///         DateTime.now().difference(_weeklyCacheTime!) < _cacheDuration) {
///       return Right(_cachedWeekly!);
///     }
///     
///     // Fetch from Firestore
///     try {
///       final snapshot = await _firestore
///           .collection('leaderboard_weekly')
///           .where('weekNumber', isEqualTo: DateTimeUtils.getWeekNumber(DateTime.now()))
///           .where('year', isEqualTo: DateTime.now().year)
///           .orderBy('score', descending: true)
///           .limit(limit)
///           .get();
///       
///       _cachedWeekly = snapshot.docs
///           .asMap()
///           .entries
///           .map((e) => LeaderboardEntry.fromFirestore(e.value, e.key + 1))
///           .toList();
///       _weeklyCacheTime = DateTime.now();
///       
///       return Right(_cachedWeekly!);
///     } on FirebaseException catch (e) {
///       return Left(ServerFailure(message: e.message ?? 'Firestore error'));
///     }
///   }
/// }
/// ```

// TODO: Implement LeaderboardRepository interface
