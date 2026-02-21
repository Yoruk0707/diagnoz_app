// lib/features/profile/presentation/pages/profile_page.dart
//
// NEDEN: Kullanıcı profili — istatistikler ve bilgiler.
// Firestore users/{userId} doc'undan okunur.
// PII koruması: sadece kendi profilini görür (firestore.rules: isOwner).
//
// Referans: leaderboard_page.dart pattern (ConsumerWidget + AsyncValue)
//           database_schema.md § users/{userId}
//           CLAUDE.md § State Management — Riverpod ONLY

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user.dart';
import '../providers/profile_providers.dart';

/// Profil sayfası — kullanıcı bilgileri ve oyun istatistikleri.
///
/// NEDEN: ConsumerWidget yeterli — timer veya controller yok.
/// Pull-to-refresh ile manuel cache invalidation.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
      ),
      body: profileAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(context, ref),
        data: (user) {
          if (user == null) return _buildNotLoggedIn(context);
          return _buildProfileContent(context, ref, user);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PROFILE CONTENT
  // ═══════════════════════════════════════════════════════════

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) {
    // NEDEN: Pull-to-refresh — provider invalidate edilir → yeniden fetch.
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentUserProfileProvider);
      },
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Avatar + İsim ───
          _buildHeader(context, user),
          const SizedBox(height: 24),

          // ─── Genel İstatistikler ───
          _buildSectionTitle(context, 'Oyun İstatistikleri'),
          const SizedBox(height: 12),
          _buildStatsGrid(context, user.stats),
          const SizedBox(height: 24),

          // ─── Skor İstatistikleri ───
          _buildSectionTitle(context, 'Skor Detayları'),
          const SizedBox(height: 12),
          _buildScoreCards(context, user.stats),
        ],
      ),
    );
  }

  /// Avatar, displayName, university, title.
  Widget _buildHeader(BuildContext context, AppUser user) {
    return Column(
      children: [
        // NEDEN: Baş harfler avatar — profil fotoğrafı MVP'de yok.
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primaryContainer,
          child: Text(
            user.initials,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.displayName ?? 'Anonim Kullanıcı',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        if (user.title != null) ...[
          const SizedBox(height: 4),
          Text(
            user.title!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryLight,
                ),
          ),
        ],
        if (user.university != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                user.university!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 2×2 grid — toplam oyun, çözülen vaka, seri, ortalama puan.
  Widget _buildStatsGrid(BuildContext context, UserStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(
          context,
          icon: Icons.sports_esports_rounded,
          label: AppStrings.totalGamesPlayed,
          value: '${stats.totalGamesPlayed}',
        ),
        _buildStatCard(
          context,
          icon: Icons.check_circle_outline_rounded,
          label: 'Çözülen Vaka',
          value: '${stats.totalCasesSolved}',
        ),
        _buildStatCard(
          context,
          icon: Icons.local_fire_department_rounded,
          label: 'Mevcut Seri',
          value: '${stats.currentStreak}',
          valueColor: stats.currentStreak > 0
              ? AppColors.warning
              : AppColors.textPrimary,
        ),
        _buildStatCard(
          context,
          icon: Icons.trending_up_rounded,
          label: AppStrings.averageScore,
          value: stats.averageScore.toStringAsFixed(1),
        ),
      ],
    );
  }

  /// Haftalık, aylık, en yüksek skor kartları.
  Widget _buildScoreCards(BuildContext context, UserStats stats) {
    return Column(
      children: [
        _buildScoreRow(
          context,
          icon: Icons.calendar_view_week_rounded,
          label: 'Haftalık Skor',
          value: stats.weeklyScore.toStringAsFixed(1),
        ),
        const SizedBox(height: 8),
        _buildScoreRow(
          context,
          icon: Icons.calendar_month_rounded,
          label: 'Aylık Skor',
          value: stats.monthlyScore.toStringAsFixed(1),
        ),
        const SizedBox(height: 8),
        _buildScoreRow(
          context,
          icon: Icons.emoji_events_rounded,
          label: AppStrings.bestScore,
          value: stats.bestScore.toStringAsFixed(1),
          valueColor: AppColors.warning,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // REUSABLE WIDGETS
  // ═══════════════════════════════════════════════════════════

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryLight),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryLight),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LOADING / ERROR / NOT LOGGED IN
  // ═══════════════════════════════════════════════════════════

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Profil yüklenemedi.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ref.invalidate(currentUserProfileProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_off_rounded,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Profili görüntülemek için giriş yapın.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
