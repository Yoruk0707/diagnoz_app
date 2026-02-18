// lib/features/game/presentation/pages/game_screen.dart
//
// NEDEN: Ana oyun ekranı — timer, vaka kartı, test butonu, tanı girişi.
// GameNotifier state'ine göre farklı ekranlar gösterir.
//
// Referans: auth ekranları pattern'ı (ConsumerWidget + state switch)
//           ui_ux_design_clean.md § Game Screen Layout

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/game_session.dart';
import '../providers/game_providers.dart';
import '../providers/game_state.dart';
import '../widgets/case_card_widget.dart';
import '../widgets/timer_widget.dart';

/// Ana oyun ekranı — tüm game state'leri handle eder.
///
/// NEDEN: Tek ekran, state'e göre farklı UI.
/// GameInitial → "Oyna" butonu
/// GameLoading → spinner
/// GamePlaying → vaka + timer + test + tanı
/// GameCaseResult → doğru/yanlış feedback
/// GameOver → final skor
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: _buildContent(context, gameState),
      ),
    );
  }

  Widget _buildContent(BuildContext context, GameState state) {
    // NEDEN: State pattern — her state kendi UI'ını render eder.
    if (state is GameInitial) return _buildInitialScreen();
    if (state is GameLoading) return _buildLoadingScreen();
    if (state is GamePlaying) return _buildPlayingScreen(context, state);
    if (state is GameCaseResult) return _buildCaseResultScreen(state);
    if (state is GameOver) return _buildGameOverScreen(state);
    if (state is GameError) return _buildErrorScreen(state);

    return const SizedBox.shrink();
  }

  // ═══════════════════════════════════════════════════════════
  // INITIAL — "Oyna" butonu
  // ═══════════════════════════════════════════════════════════

  Widget _buildInitialScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.medical_services_outlined,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'DiagnozApp',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tıbbi tanı simülasyonu',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),
          // NEDEN: Büyük, belirgin "Oyna" butonu.
          SizedBox(
            width: 200,
            height: 56,
            child: ElevatedButton(
              onPressed: () => ref
                  .read(gameNotifierProvider.notifier)
                  .startNewGame(mode: GameMode.rush),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Oyna',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LOADING
  // ═══════════════════════════════════════════════════════════

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Vakalar yükleniyor...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PLAYING — Ana oyun ekranı
  // ═══════════════════════════════════════════════════════════

  Widget _buildPlayingScreen(
    BuildContext context,
    GamePlaying state,
  ) {
    final currentCase = state.currentCase;
    if (currentCase == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // NEDEN: Üst bar — timer + skor + pas hakkı.
          _buildTopBar(state),
          const SizedBox(height: 12),

          // NEDEN: Scrollable content — vaka kartı + testler.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // NEDEN: Vaka kartı — hasta bilgisi + vitaller.
                  CaseCardWidget(
                    medicalCase: currentCase,
                    caseNumber: state.caseNumber,
                    totalCases: state.totalCases,
                  ),
                  const SizedBox(height: 12),

                  // NEDEN: Test isteme butonu.
                  _buildTestSection(state),
                  const SizedBox(height: 12),

                  // NEDEN: Açılmış test sonuçları.
                  if (state.revealedTests.isNotEmpty)
                    _buildRevealedTests(state),
                ],
              ),
            ),
          ),

          // NEDEN: Alt kısım — tanı girişi, sabit kalır.
          _buildDiagnosisInput(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTopBar(GamePlaying state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // NEDEN: Pas hakkı göstergesi.
        Row(
          children: [
            const Icon(Icons.favorite, color: AppColors.error, size: 18),
            const SizedBox(width: 4),
            Text(
              '${state.passesLeft}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        // NEDEN: Timer — ortada, en önemli bilgi.
        TimerWidget(timeLeft: state.timeLeft),

        // NEDEN: Toplam skor.
        Row(
          children: [
            const Icon(Icons.star, color: AppColors.warning, size: 18),
            const SizedBox(width: 4),
            Text(
              state.totalScore.toStringAsFixed(1),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTestSection(GamePlaying state) {
    final currentCase = state.currentCase;
    if (currentCase == null) return const SizedBox.shrink();

    // NEDEN: Henüz istenmemiş testleri filtrele.
    final availableTests = currentCase.availableTests
        .where((t) => !state.requestedTests.contains(t.testId))
        .toList();

    if (availableTests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Tüm testler istendi',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Card(
      color: AppColors.backgroundSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text(
                  'Test İste (-10sn)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTests.map((test) {
                return ActionChip(
                  label: Text(
                    test.displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: AppColors.backgroundTertiary,
                  side: const BorderSide(color: AppColors.primary, width: 0.5),
                  onPressed: () => ref
                      .read(gameNotifierProvider.notifier)
                      .requestTest(test.testId),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealedTests(GamePlaying state) {
    return Card(
      color: AppColors.backgroundSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Sonuçları',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...state.revealedTests.values.map((test) {
              final color = test.isAbnormal ? AppColors.error : AppColors.success;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (test.isAbnormal
                            ? AppColors.errorContainer
                            : AppColors.successContainer)
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.displayName,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (test.value != null)
                        Text(
                          test.value!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      if (test.findings != null)
                        Text(
                          test.findings!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      if (test.interpretation != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          test.interpretation!,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tanınızı yazın...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.backgroundTertiary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              // NEDEN: Enter ile gönder — hızlı gameplay.
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  ref
                      .read(gameNotifierProvider.notifier)
                      .submitDiagnosis(value.trim());
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // NEDEN: Gönder butonu — büyük, kolay tıklanır.
          SizedBox(
            height: 48,
            width: 48,
            child: ElevatedButton(
              onPressed: () {
                final text = _controller.text.trim();
                if (text.isNotEmpty) {
                  ref
                      .read(gameNotifierProvider.notifier)
                      .submitDiagnosis(text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.send, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CASE RESULT — Doğru/Yanlış feedback
  // ═══════════════════════════════════════════════════════════

  Widget _buildCaseResultScreen(GameCaseResult state) {
    final color = state.isCorrect ? AppColors.success : AppColors.error;
    final icon = state.isCorrect ? Icons.check_circle : Icons.cancel;
    final text = state.isCorrect ? 'Doğru Tanı!' : 'Yanlış Tanı';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 80),
            const SizedBox(height: 16),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (!state.isCorrect) ...[
              const Text(
                'Doğru cevap:',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                state.correctDiagnosis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (state.isCorrect) ...[
              const SizedBox(height: 8),
              Text(
                '+${state.score.toStringAsFixed(1)} puan',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () =>
                    ref.read(gameNotifierProvider.notifier).nextCase(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sonraki Vaka',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GAME OVER — Final skor
  // ═══════════════════════════════════════════════════════════

  Widget _buildGameOverScreen(GameOver state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isVictory ? Icons.emoji_events : Icons.sports_score,
              color: state.isVictory ? AppColors.warning : AppColors.textSecondary,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              state.isVictory ? 'Tebrikler!' : 'Oyun Bitti',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // NEDEN: Skor özeti kartı.
            Card(
              color: AppColors.backgroundSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Toplam Puan',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.totalScore.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${state.casesCompleted} / ${state.totalCases} vaka tamamlandı',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () =>
                    ref.read(gameNotifierProvider.notifier).resetGame(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tekrar Oyna',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ERROR
  // ═══════════════════════════════════════════════════════════

  Widget _buildErrorScreen(GameError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 64),
            const SizedBox(height: 16),
            Text(
              state.failure.message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  ref.read(gameNotifierProvider.notifier).resetGame(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('Ana Ekrana Dön'),
            ),
          ],
        ),
      ),
    );
  }
}
