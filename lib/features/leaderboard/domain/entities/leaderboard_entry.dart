/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - leaderboard_entry.dart (Entity)
/// ═══════════════════════════════════════════════════════════════
/// 
/// PURPOSE: Leaderboard entry entity for domain layer
/// 
/// SCHEMA (database_schema.md § leaderboard_weekly/monthly):
/// - userId: Reference to user
/// - displayName: Denormalized from user (WHY: reduce reads)
/// - university: Denormalized from user
/// - score: Total points for period
/// - casesPlayed: Number of cases completed
/// - gamesPlayed: Number of games completed
/// - weekNumber/month: Period identifier
/// - year: Year identifier
/// 
/// DENORMALIZATION NOTE (database_schema.md § Denormalization):
/// displayName is denormalized to avoid JOIN reads.
/// Trade-off: 2 extra writes on name change vs 50% read reduction.
/// 
/// EXAMPLE:
/// ```dart
/// class LeaderboardEntry extends Equatable {
///   final String odocumentId;
///   final String userId;
///   final String displayName;
///   final String? university;
///   final double score;
///   final int casesPlayed;
///   final int gamesPlayed;
///   final int rank; // Computed client-side from list position
///   final DateTime lastUpdated;
///   
///   const LeaderboardEntry({
///     required this.documentId,
///     required this.userId,
///     required this.displayName,
///     this.university,
///     required this.score,
///     required this.casesPlayed,
///     required this.gamesPlayed,
///     required this.rank,
///     required this.lastUpdated,
///   });
///   
///   /// Display formatted score (e.g., "245.6")
///   String get formattedScore => score.toStringAsFixed(1);
///   
///   /// Display initials for avatar
///   String get initials {
///     final parts = displayName.split(' ');
///     if (parts.length >= 2) {
///       return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
///     }
///     return displayName.substring(0, 2).toUpperCase();
///   }
///   
///   /// Average score per game
///   double get averageScore => 
///     gamesPlayed > 0 ? score / gamesPlayed : 0.0;
///   
///   @override
///   List<Object?> get props => [userId, score, rank];
/// }
/// ```

// TODO: Implement LeaderboardEntry entity
