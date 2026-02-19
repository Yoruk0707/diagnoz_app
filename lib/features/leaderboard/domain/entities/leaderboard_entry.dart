// lib/features/leaderboard/domain/entities/leaderboard_entry.dart
//
// NEDEN: database_schema.md § leaderboard_weekly ve leaderboard_monthly
// şemalarını temsil eden domain entity.
// Weekly ve monthly aynı yapıda — period enum ile ayrışır.
//
// Referans: game_session.dart Equatable pattern'ı
//           database_schema.md § Leaderboard Schema
//           vcguide.md § Leaderboard Race Condition (FieldValue.increment)

import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════

/// Liderlik tablosu periyodu.
///
/// NEDEN: Weekly ve monthly aynı entity yapısını paylaşır.
/// Firestore'da ayrı collection'lar ama domain'de tek tip.
enum LeaderboardPeriod { weekly, monthly }

// ═══════════════════════════════════════════════════════════════
// MAIN ENTITY
// ═══════════════════════════════════════════════════════════════

/// Liderlik tablosu girişi — database_schema.md § leaderboard_weekly/monthly.
///
/// NEDEN: Denormalize yapı — displayName ve university burada tutulur.
/// Her leaderboard query'de users collection'a join gerekmez.
/// database_schema.md § Denormalization Strategy.
class LeaderboardEntry extends Equatable {
  /// Kullanıcı ID (Firebase Auth UID).
  final String userId;

  /// Görünen ad — denormalize (users collection'dan kopyalanır).
  final String displayName;

  /// Üniversite — denormalize (opsiyonel, profilde set edilmemişse null).
  final String? university;

  /// Toplam skor — FieldValue.increment ile atomik güncellenir.
  ///
  /// NEDEN: vcguide.md § Edge Case 4 — race condition önleme.
  /// Read-then-write değil, increment ile güncelleme.
  final double score;

  /// Toplam oynanan vaka sayısı.
  final int casesPlayed;

  /// Toplam oynanan oyun sayısı.
  final int gamesPlayed;

  /// Hafta numarası (ISO 8601, 1-53) — sadece weekly için.
  /// Monthly'de null.
  final int? weekNumber;

  /// Ay (1-12) — sadece monthly için.
  /// Weekly'de null.
  final int? month;

  /// Yıl — weekly ve monthly'de ortak.
  final int year;

  /// Son güncelleme zamanı — Firestore serverTimestamp.
  final DateTime? lastUpdated;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.university,
    required this.score,
    this.casesPlayed = 0,
    this.gamesPlayed = 0,
    this.weekNumber,
    this.month,
    required this.year,
    this.lastUpdated,
  });

  /// Hangi periyot olduğunu belirle.
  ///
  /// NEDEN: UI'da "Bu Hafta" / "Bu Ay" başlığını göstermek için.
  LeaderboardPeriod get period =>
      weekNumber != null ? LeaderboardPeriod.weekly : LeaderboardPeriod.monthly;

  /// Kullanıcı baş harfleri — avatar widget'ında kullanılır.
  ///
  /// NEDEN: displayName boş/kısa olabilir (profil eksik, silinen hesap vb.)
  /// Boş → '?', 1 karakter → o karakter, 2+ kelime → ilk iki kelimenin baş harfi,
  /// tek kelime → ilk 2 karakter.
  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '?';
    if (trimmed.length == 1) return trimmed.toUpperCase();

    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, 2).toUpperCase();
  }

  @override
  List<Object?> get props => [
        userId,
        score,
        weekNumber,
        month,
        year,
      ];
}
