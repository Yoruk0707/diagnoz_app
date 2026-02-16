/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - leaderboard_provider.dart
/// ═══════════════════════════════════════════════════════════════
/// 
/// PURPOSE: Leaderboard state management with caching
/// 
/// CACHING STRATEGY (vcguide.md § State Management):
/// - Use ref.keepAlive() to prevent disposal
/// - Auto-invalidate after 5 minutes
/// - Manual refresh via pull-to-refresh
/// 
/// FIREBASE COST REDUCTION:
/// Without cache: 1000 users × 50 reads = 50,000 reads/day
/// With cache: ~150 reads/day (99% reduction!)
/// 
/// EXAMPLE:
/// ```dart
/// @riverpod
/// Future<List<LeaderboardEntry>> weeklyLeaderboard(
///   WeeklyLeaderboardRef ref,
/// ) async {
///   // WHY: Keep alive to maintain cache between navigations
///   ref.keepAlive();
///   
///   // WHY: Auto-invalidate after 5 minutes
///   final timer = Timer(const Duration(minutes: 5), () {
///     ref.invalidateSelf();
///   });
///   
///   // WHY: Cancel timer when provider is disposed
///   ref.onDispose(() => timer.cancel());
///   
///   final result = await ref.read(leaderboardRepositoryProvider)
///       .getWeeklyLeaderboard(limit: 50);
///   
///   return result.fold(
///     (failure) => throw failure,
///     (entries) => entries,
///   );
/// }
/// 
/// @riverpod
/// Future<List<LeaderboardEntry>> monthlyLeaderboard(
///   MonthlyLeaderboardRef ref,
/// ) async {
///   ref.keepAlive();
///   
///   final timer = Timer(const Duration(minutes: 5), () {
///     ref.invalidateSelf();
///   });
///   ref.onDispose(() => timer.cancel());
///   
///   final result = await ref.read(leaderboardRepositoryProvider)
///       .getMonthlyLeaderboard(limit: 50);
///   
///   return result.fold(
///     (failure) => throw failure,
///     (entries) => entries,
///   );
/// }
/// 
/// @riverpod
/// Future<UserRankInfo?> currentUserRank(
///   CurrentUserRankRef ref,
///   LeaderboardPeriod period,
/// ) async {
///   final user = ref.watch(currentUserProvider);
///   if (user == null) return null;
///   
///   final result = await ref.read(leaderboardRepositoryProvider)
///       .getUserRank(userId: user.id, period: period);
///   
///   return result.fold(
///     (failure) => null,
///     (rankInfo) => rankInfo,
///   );
/// }
/// ```
/// 
/// USAGE IN WIDGET:
/// ```dart
/// class LeaderboardScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final weeklyAsync = ref.watch(weeklyLeaderboardProvider);
///     final userRank = ref.watch(
///       currentUserRankProvider(LeaderboardPeriod.weekly),
///     );
///     
///     return RefreshIndicator(
///       // Manual refresh
///       onRefresh: () async {
///         ref.invalidate(weeklyLeaderboardProvider);
///         await ref.read(weeklyLeaderboardProvider.future);
///       },
///       child: weeklyAsync.when(
///         data: (entries) => LeaderboardList(entries: entries),
///         loading: () => const LeaderboardSkeleton(),
///         error: (e, _) => ErrorWidget(e.toString()),
///       ),
///     );
///   }
/// }
/// ```

// TODO: Implement Leaderboard providers with Riverpod
