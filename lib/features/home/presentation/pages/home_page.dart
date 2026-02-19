// lib/features/home/presentation/pages/home_page.dart
//
// NEDEN: ui_ux_design_clean.md § 4.3 Home Screen.
// Oyun başlatma CTA, haftalık top 3 önizleme, leaderboard linki.
//
// Referans: ui_ux_design_clean.md § 4.3 Home Screen
//           CLAUDE.md § State Management — Riverpod ONLY

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../game/data/datasources/firestore_case_datasource.dart';
import '../../../leaderboard/presentation/providers/leaderboard_providers.dart';

/// Ana sayfa — oyun başlatma ve hızlı erişim.
///
/// NEDEN: ConsumerWidget — leaderboard provider'ını watch eder.
/// Timer/controller yok, StatefulWidget gerekmez.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // ─── Rush Mode Card ───
            _buildRushModeCard(context),
            const SizedBox(height: 16),

            // ─── Zen Mode Card (yakında) ───
            _buildZenModeCard(context),
            const SizedBox(height: 32),

            // ─── Haftalık Top 3 Önizleme ───
            _buildLeaderboardPreview(context, ref),

            // ─── Debug: Seed Data Butonu ───
            if (kDebugMode) ...[
              const SizedBox(height: 32),
              _buildSeedButton(context),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // RUSH MODE CARD
  // ═══════════════════════════════════════════════════════════

  /// Rush Mode CTA kartı.
  ///
  /// NEDEN: ui_ux_design_clean.md § 4.3 — ana CTA.
  /// "120s | 5 Vaka | Rekabet" bilgisi ile.
  Widget _buildRushModeCard(BuildContext context) {
    return Card(
      color: AppColors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.primaryContainer),
      ),
      child: InkWell(
        onTap: () => context.go(AppRoutes.game),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.flash_on_rounded,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.rushMode,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '120s | 5 Vaka | Rekabet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.game),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(AppStrings.play),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ZEN MODE CARD (Yakında)
  // ═══════════════════════════════════════════════════════════

  /// Zen Mode kartı — henüz aktif değil.
  ///
  /// NEDEN: ui_ux_design_clean.md § 4.3 — "[YAKINDA]" tag'i ile.
  Widget _buildZenModeCard(BuildContext context) {
    return Card(
      color: AppColors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.backgroundTertiary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.self_improvement_rounded,
              size: 36,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.zenMode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Süresiz | Öğren | Pratik',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'YAKINDA',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LEADERBOARD PREVIEW
  // ═══════════════════════════════════════════════════════════

  /// Haftalık Top 3 önizleme + "Tümünü Gör" linki.
  ///
  /// NEDEN: ui_ux_design_clean.md § 4.3 — "[Liderlik Tablosu ->]".
  /// Home'da hızlı bakış, detay için leaderboard sayfasına git.
  Widget _buildLeaderboardPreview(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyLeaderboardProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Başlık + "Tümünü Gör" ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.weeklyLeaderboard,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.leaderboard),
              child: const Text('Tümünü Gör'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ─── Top 3 Liste ───
        Card(
          color: AppColors.backgroundSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: weeklyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sıralama yüklenemedi.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                ),
              ),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppStrings.emptyLeaderboard,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              // NEDEN: Sadece top 3 göster — home'da yer tasarrufu.
              final top3 = entries.take(3).toList();

              return Column(
                children: [
                  for (int i = 0; i < top3.length; i++)
                    _buildTop3Row(context, top3[i], i + 1),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DEBUG: SEED DATA BUTTON
  // ═══════════════════════════════════════════════════════════

  /// Debug-only seed butonu — MockCases'ı Firestore'a yükler.
  ///
  /// NEDEN: Sprint 4 geçişi — Firestore'a ilk veri yükleme.
  /// Sadece kDebugMode'da görünür (production'da gizli).
  Widget _buildSeedButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        try {
          final datasource = FirestoreCaseDatasource();
          final count = await datasource.seedCases();

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                count > 0
                    ? '$count vaka Firestore\'a eklendi!'
                    : 'Tüm vakalar zaten mevcut.',
              ),
              backgroundColor: count > 0 ? AppColors.success : AppColors.textSecondary,
            ),
          );
        } catch (e) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Seed hatası: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      icon: const Icon(Icons.storage_rounded),
      label: const Text('[DEBUG] Seed Cases to Firestore'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textTertiary,
        side: const BorderSide(color: AppColors.backgroundTertiary),
      ),
    );
  }

  /// Top 3 satırı — altın/gümüş/bronz ile.
  Widget _buildTop3Row(BuildContext context, dynamic entry, int rank) {
    final colors = [
      const Color(0xFFFFD700), // Altın
      const Color(0xFFC0C0C0), // Gümüş
      const Color(0xFFCD7F32), // Bronz
    ];
    final color = rank <= 3 ? colors[rank - 1] : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Sıra badge
          Container(
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
          ),
          const SizedBox(width: 12),
          // İsim
          Expanded(
            child: Text(
              entry.displayName as String,
              style: Theme.of(context).textTheme.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Skor
          Text(
            '${(entry.score as double).toStringAsFixed(1)} p',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
