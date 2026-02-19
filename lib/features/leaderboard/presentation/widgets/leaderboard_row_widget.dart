// lib/features/leaderboard/presentation/widgets/leaderboard_row_widget.dart
//
// NEDEN: ui_ux_design_clean.md § 3.6 Leaderboard Row.
// Tek bir leaderboard satırı — sıra, avatar, isim, skor.
// Mevcut kullanıcı highlight, top 3 altın/gümüş/bronz.
//
// Referans: ui_ux_design_clean.md § 3.6 Leaderboard Row
//           ui_ux_design_clean.md § 3.7 Avatar Component
//           ui_ux_design_clean.md § 2.1 Color Palette (dark theme)

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/leaderboard_entry.dart';

/// Leaderboard satırı — sıra numarası, avatar, isim, skor.
///
/// NEDEN: Ayrı widget — ListView.builder'da her satır için yeniden
/// oluşturulur. Const constructor ile gereksiz rebuild önlenir.
class LeaderboardRowWidget extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isCurrentUser;

  const LeaderboardRowWidget({
    super.key,
    required this.entry,
    required this.rank,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // NEDEN: Mevcut kullanıcı satırı primaryContainer ile highlight.
      // ui_ux_design_clean.md § 3.6: "Background: #1E3A5F (highlighted)"
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primaryContainer
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: AppColors.backgroundTertiary.withValues(alpha: 0.5),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // ─── Sıra numarası ───
          _buildRankBadge(context),
          const SizedBox(width: 12),

          // ─── Avatar (initials) ───
          _buildAvatar(),
          const SizedBox(width: 12),

          // ─── İsim + Üniversite ───
          Expanded(child: _buildNameSection(context)),

          // ─── Skor ───
          _buildScore(context),
        ],
      ),
    );
  }

  /// Sıra numarası badge — top 3 altın/gümüş/bronz.
  ///
  /// NEDEN: ui_ux_design_clean.md § 3.6 — [1st], [2nd], [3rd].
  /// Top 3 görsel olarak öne çıkarılır (motivasyon).
  Widget _buildRankBadge(BuildContext context) {
    final color = _getRankColor();
    final isTopThree = rank <= 3;

    return SizedBox(
      width: 32,
      child: isTopThree
          ? Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            )
          : Text(
              '$rank',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
    );
  }

  /// Avatar — initials ile.
  ///
  /// NEDEN: ui_ux_design_clean.md § 3.7 — 40dp, circle, initials.
  /// MVP'de sadece baş harfler, v2.0'da fotoğraf desteği.
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: _getAvatarColor(),
      child: Text(
        entry.initials,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  /// İsim + Üniversite bölümü.
  Widget _buildNameSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.displayName,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isCurrentUser
                    ? AppColors.textPrimary
                    : AppColors.textPrimary,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (entry.university != null && entry.university!.isNotEmpty)
          Text(
            entry.university!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  /// Skor gösterimi — sağda.
  ///
  /// NEDEN: ui_ux_design_clean.md § 3.6 — "245.6 puan" formatı.
  Widget _buildScore(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.score.toStringAsFixed(1),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isCurrentUser ? AppColors.primaryLight : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          '${entry.gamesPlayed} oyun',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Top 3 renkleri — altın, gümüş, bronz.
  Color _getRankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Altın
      case 2:
        return const Color(0xFFC0C0C0); // Gümüş
      case 3:
        return const Color(0xFFCD7F32); // Bronz
      default:
        return AppColors.textSecondary;
    }
  }

  /// Avatar arka plan rengi — userId hash'inden deterministik renk.
  ///
  /// NEDEN: ui_ux_design_clean.md § 3.7 — "Generated from name hash".
  /// Aynı kullanıcı her zaman aynı rengi görür.
  Color _getAvatarColor() {
    final hash = entry.userId.hashCode;
    final colors = [
      AppColors.primary,
      AppColors.primaryDark,
      AppColors.success,
      const Color(0xFF7E57C2), // Purple
      const Color(0xFFFF7043), // Deep Orange
      const Color(0xFF26A69A), // Teal
      const Color(0xFFAB47BC), // Purple accent
      const Color(0xFF42A5F5), // Blue
    ];
    return colors[hash.abs() % colors.length];
  }
}
