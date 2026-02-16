/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - date_time_utils.dart
/// ═══════════════════════════════════════════════════════════════
/// 
/// PURPOSE: Date/time utilities for leaderboard periods
/// 
/// USAGE:
/// - Calculate week number for leaderboard_weekly
/// - Calculate month boundaries for leaderboard_monthly
/// - Format timestamps for display
/// 
/// TIMEZONE NOTE:
/// - All timestamps stored in UTC
/// - Display in Turkey timezone (UTC+3)
/// - Leaderboard resets: Monday 00:00 UTC+3
/// 
/// EXAMPLE:
/// ```dart
/// abstract class DateTimeUtils {
///   /// Get week number (1-52)
///   /// WHY: Used for leaderboard_weekly document IDs
///   /// Format: {userId}_w{weekNumber}_{year}
///   static int getWeekNumber(DateTime date) {
///     final firstDayOfYear = DateTime(date.year, 1, 1);
///     final dayOfYear = date.difference(firstDayOfYear).inDays;
///     return ((dayOfYear - date.weekday + 10) / 7).floor();
///   }
///   
///   /// Check if date is in current week
///   static bool isCurrentWeek(DateTime date) {
///     final now = DateTime.now();
///     return getWeekNumber(date) == getWeekNumber(now) &&
///            date.year == now.year;
///   }
///   
///   /// Get start of current week (Monday 00:00)
///   static DateTime getWeekStart(DateTime date) {
///     final daysToSubtract = date.weekday - 1;
///     return DateTime(
///       date.year, 
///       date.month, 
///       date.day - daysToSubtract,
///     );
///   }
///   
///   /// Format relative time (e.g., "2 saat önce")
///   static String formatRelative(DateTime date) {
///     final now = DateTime.now();
///     final diff = now.difference(date);
///     
///     if (diff.inMinutes < 1) return 'Az önce';
///     if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
///     if (diff.inHours < 24) return '${diff.inHours} saat önce';
///     if (diff.inDays < 7) return '${diff.inDays} gün önce';
///     
///     return '${date.day}.${date.month}.${date.year}';
///   }
/// }
/// ```

// TODO: Implement DateTimeUtils
