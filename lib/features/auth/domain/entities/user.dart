import 'package:equatable/equatable.dart';

/// Kullanıcı domain entity.
///
/// NEDEN: Domain layer Firebase'den bağımsız.
/// Data layer'daki UserModel bu entity'ye dönüşür.
///
/// Referans: database_schema.md § users/{userId}
class AppUser extends Equatable {
  final String id;
  final String phoneNumber;
  // NEDEN: Yeni kullanıcıların displayName'i yok (profil tamamlama sonrası set edilir).
  // Firebase Auth User.displayName nullable döner.
  final String? displayName;
  final String? title;
  final String? university;
  final String? profilePhotoUrl;
  final UserStats stats;
  final UserPrivacy privacy;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.phoneNumber,
    this.displayName,
    this.title,
    this.university,
    this.profilePhotoUrl,
    required this.stats,
    required this.privacy,
    required this.createdAt,
  });

  /// Avatar için baş harfler (leaderboard, profil).
  String get initials {
    final name = displayName;
    if (name == null || name.trim().isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    // NEDEN: Tek kelimelik isimde ilk 2 harf al.
    // 1 karakterli isim olmamalı (validator 3+ zorunlu) ama defensive.
    if (name.length < 2) return name.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  /// Kullanıcı profil tamamlamış mı?
  // NEDEN: Sadece null değil, boş string de profil tamamlanmamış sayılmalı (Codex review).
  bool get hasCompletedProfile =>
      displayName != null && displayName!.trim().isNotEmpty;

  @override
  List<Object?> get props => [id, phoneNumber];
}

/// Kullanıcı istatistikleri.
///
/// NEDEN: Ayrı class → leaderboard'da sadece stats gerektiğinde
/// lightweight kullanım.
class UserStats extends Equatable {
  final int totalGamesPlayed;
  final int totalCasesSolved;
  final double averageScore;
  final double weeklyScore;
  final double monthlyScore;
  final double bestScore;
  final int currentStreak;

  const UserStats({
    this.totalGamesPlayed = 0,
    this.totalCasesSolved = 0,
    this.averageScore = 0.0,
    this.weeklyScore = 0.0,
    this.monthlyScore = 0.0,
    this.bestScore = 0.0,
    this.currentStreak = 0,
  });

  static const empty = UserStats();

  @override
  List<Object?> get props => [
        totalGamesPlayed,
        totalCasesSolved,
        averageScore,
        weeklyScore,
        monthlyScore,
        bestScore,
        currentStreak,
      ];
}

/// Kullanıcı gizlilik ayarları.
class UserPrivacy extends Equatable {
  final bool showUniversity;
  final bool showGameHistory;

  const UserPrivacy({
    this.showUniversity = true,
    this.showGameHistory = true,
  });

  static const defaultSettings = UserPrivacy();

  @override
  List<Object?> get props => [showUniversity, showGameHistory];
}
