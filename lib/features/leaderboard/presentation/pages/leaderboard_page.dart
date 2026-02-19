// lib/features/leaderboard/presentation/pages/leaderboard_page.dart
//
// NEDEN: ui_ux_design_clean.md § 4.8 Leaderboard Screen.
// Haftalık/Aylık toggle, Top 50 liste, kullanıcı sırası sticky footer.
// Pull-to-refresh, Loading/Error/Empty states.
//
// Referans: ui_ux_design_clean.md § 4.8 Leaderboard Screen
//           ui_ux_design_clean.md § 3.6 Leaderboard Row
//           vcguide.md § Performance Optimization (ListView.builder)
//           CLAUDE.md § State Management — Riverpod ONLY

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../providers/leaderboard_providers.dart';
import '../widgets/leaderboard_row_widget.dart';

/// Liderlik tablosu — haftalık/aylık sıralama.
///
/// NEDEN: ui_ux_design_clean.md § 4.8.
/// ConsumerWidget yeterli — timer veya controller yok.
/// Pull-to-refresh ile manuel cache invalidation.
class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    // NEDEN: Seçili periyoda göre doğru provider'ı watch et.
    final leaderboardAsync = selectedPeriod == LeaderboardPeriod.weekly
        ? ref.watch(weeklyLeaderboardProvider)
        : ref.watch(monthlyLeaderboardProvider);

    final userRankAsync = ref.watch(currentUserRankProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.leaderboard),
      ),
      body: Column(
        children: [
          // ─── Haftalık/Aylık Toggle ───
          _buildPeriodToggle(context, ref, selectedPeriod),

          // ─── Liste ───
          Expanded(
            child: leaderboardAsync.when(
              loading: () => _buildLoadingState(),
              error: (error, _) => _buildErrorState(context, ref),
              data: (entries) => entries.isEmpty
                  ? _buildEmptyState(context)
                  : _buildLeaderboardList(context, ref, entries),
            ),
          ),

          // ─── Sticky Footer — Kullanıcının kendi sırası ───
          _buildStickyFooter(context, leaderboardAsync, userRankAsync),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PERIOD TOGGLE
  // ═══════════════════════════════════════════════════════════

  /// Haftalık/Aylık toggle — SegmentedButton.
  ///
  /// NEDEN: ui_ux_design_clean.md § 4.8 — "[Haftalik] [Aylik]".
  /// Material 3 SegmentedButton — native look and feel.
  Widget _buildPeriodToggle(
    BuildContext context,
    WidgetRef ref,
    LeaderboardPeriod selected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SegmentedButton<LeaderboardPeriod>(
        segments: const [
          ButtonSegment(
            value: LeaderboardPeriod.weekly,
            label: Text('Haftalık'),
            icon: Icon(Icons.calendar_view_week_rounded),
          ),
          ButtonSegment(
            value: LeaderboardPeriod.monthly,
            label: Text('Aylık'),
            icon: Icon(Icons.calendar_month_rounded),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (newSelection) {
          ref.read(selectedPeriodProvider.notifier).state =
              newSelection.first;
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryContainer;
            }
            return Colors.transparent;
          }),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LEADERBOARD LIST
  // ═══════════════════════════════════════════════════════════

  /// Top 50 liste — ListView.builder (lazy loading).
  ///
  /// NEDEN: ui_ux_design_clean.md § 10.3 — "Must use ListView.builder".
  /// vcguide.md § Performance — <16ms/frame render hedefi.
  Widget _buildLeaderboardList(
    BuildContext context,
    WidgetRef ref,
    List<LeaderboardEntry> entries,
  ) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // NEDEN: Pull-to-refresh — cache invalidation.
    // Kullanıcı aşağı çekince provider invalidate edilir → yeniden fetch.
    return RefreshIndicator(
      onRefresh: () async {
        final period = ref.read(selectedPeriodProvider);
        if (period == LeaderboardPeriod.weekly) {
          ref.invalidate(weeklyLeaderboardProvider);
        } else {
          ref.invalidate(monthlyLeaderboardProvider);
        }
        ref.invalidate(currentUserRankProvider);
      },
      color: AppColors.primary,
      child: ListView.builder(
        itemCount: entries.length,
        // NEDEN: Fixed extent hint — ListView performans optimizasyonu.
        // Her satır yaklaşık aynı yükseklikte.
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isCurrentUser = entry.userId == currentUserId;

          return LeaderboardRowWidget(
            entry: entry,
            rank: index + 1,
            isCurrentUser: isCurrentUser,
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STICKY FOOTER — Kullanıcının sırası
  // ═══════════════════════════════════════════════════════════

  /// Sticky footer — kullanıcının kendi sırası her zaman görünür.
  ///
  /// NEDEN: ui_ux_design_clean.md § 4.8 — "Sticky Footer, Always visible".
  /// Kullanıcı top 50'de olmasa bile kendi sırasını görür.
  Widget _buildStickyFooter(
    BuildContext context,
    AsyncValue<List<LeaderboardEntry>> leaderboardAsync,
    AsyncValue<int> userRankAsync,
  ) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          top: BorderSide(color: AppColors.backgroundTertiary),
        ),
      ),
      child: leaderboardAsync.when(
        loading: () => _buildFooterSkeleton(),
        error: (_, __) => _buildFooterError(context),
        data: (entries) {
          // NEDEN: Kullanıcı listede varsa, entry'sini kullan.
          // Yoksa rank provider'dan sıra al, minimum bilgi göster.
          final userEntry = entries
              .cast<LeaderboardEntry?>()
              .firstWhere(
                (e) => e!.userId == currentUserId,
                orElse: () => null,
              );

          if (userEntry != null) {
            final rank = entries.indexOf(userEntry) + 1;
            return LeaderboardRowWidget(
              entry: userEntry,
              rank: rank,
              isCurrentUser: true,
            );
          }

          // NEDEN: Kullanıcı top 50'de değil — sıra numarasını göster.
          return userRankAsync.when(
            loading: () => _buildFooterSkeleton(),
            error: (_, __) => _buildFooterError(context),
            data: (rank) {
              if (rank == 0) {
                return _buildFooterNotRanked(context);
              }
              return _buildFooterOutOfList(context, rank);
            },
          );
        },
      ),
    );
  }

  /// Footer — kullanıcı henüz sıralamada yok.
  Widget _buildFooterNotRanked(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Icon(
            Icons.person_outline_rounded,
            color: AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Henüz sıralaman yok — bir oyun oyna!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  /// Footer — kullanıcı listede ama top 50'de değil.
  Widget _buildFooterOutOfList(BuildContext context, int rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: AppColors.primaryContainer,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.person_rounded,
            color: AppColors.primaryLight,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Sen',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  /// Footer skeleton — loading state.
  Widget _buildFooterSkeleton() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(width: 12),
          Text('Sıralaman yükleniyor...'),
        ],
      ),
    );
  }

  /// Footer error state.
  Widget _buildFooterError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        'Sıralama bilgisi alınamadı.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LOADING / ERROR / EMPTY STATES
  // ═══════════════════════════════════════════════════════════

  /// Loading state — skeleton rows.
  ///
  /// NEDEN: ui_ux_design_clean.md § 4.8 States — "Skeleton rows (10)".
  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => _buildSkeletonRow(),
    );
  }

  /// Skeleton row — loading placeholder.
  Widget _buildSkeletonRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Sıra
          Container(
            width: 32,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.backgroundTertiary,
          ),
          const SizedBox(width: 12),
          // İsim
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Skor
          Container(
            height: 14,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.backgroundTertiary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Error state — hata mesajı + tekrar dene.
  ///
  /// NEDEN: ui_ux_design_clean.md § 4.8 States — "Yuklenemedi + Retry".
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
            'Liderlik tablosu yüklenemedi.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              final period = ref.read(selectedPeriodProvider);
              if (period == LeaderboardPeriod.weekly) {
                ref.invalidate(weeklyLeaderboardProvider);
              } else {
                ref.invalidate(monthlyLeaderboardProvider);
              }
              ref.invalidate(currentUserRankProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }

  /// Empty state — henüz kimse oynamamış.
  ///
  /// NEDEN: ui_ux_design_clean.md § 4.8 States — "Henuz kimse oynamadi".
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.emptyLeaderboard,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk sırayı almak için bir oyun başlat!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ],
      ),
    );
  }
}
