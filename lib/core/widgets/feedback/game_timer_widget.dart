/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - game_timer_widget.dart
/// ═══════════════════════════════════════════════════════════════
/// 
/// PURPOSE: Timer countdown display (ui_ux_design.md § 3.2)
/// 
/// ⚠️  CRITICAL COMPONENT - Memory Leak Prevention Required
/// 
/// SPECIFICATIONS:
/// - Font: Monospace (JetBrains Mono) - fixed width digits
/// - Size: 28sp Bold
/// - Progress bar shows remaining time
/// 
/// COLOR BEHAVIOR (ui_ux_design.md):
/// - 120s - 60s: #4CAF50 (Green/Safe)
/// - 59s - 15s:  #FFC107 (Yellow/Caution)
/// - 14s - 0s:   #F44336 (Red/Critical) + Pulse animation
/// 
/// ⚠️  MEMORY LEAK WARNING (vcguide.md § Edge Case 1):
/// ```dart
/// // WRONG - No cleanup!
/// class TimerNotifier extends StateNotifier<int> {
///   TimerNotifier() : super(120) {
///     Timer.periodic(Duration(seconds: 1), (timer) {
///       state--;  // LEAK: Timer runs forever!
///     });
///   }
/// }
/// 
/// // CORRECT - With cleanup
/// class TimerNotifier extends StateNotifier<int> {
///   Timer? _timer;
///   
///   @override
///   void dispose() {
///     _timer?.cancel();  // WHY: Prevent memory leak
///     super.dispose();
///   }
/// }
/// ```
/// 
/// ARCHITECTURE NOTES:
/// - Timer logic in provider (timer_provider.dart)
/// - This widget is DISPLAY ONLY
/// - Uses ref.watch(timerProvider) to get current time
/// 
/// PULSE ANIMATION (Last 10 seconds):
/// - Scale: 1.0 -> 1.05 -> 1.0
/// - Duration: 500ms
/// - Glow effect with BoxShadow
/// 
/// EXAMPLE:
/// ```dart
/// class GameTimerWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final timeLeft = ref.watch(timerProvider);
///     
///     return Column(
///       children: [
///         // Progress bar
///         LinearProgressIndicator(
///           value: timeLeft / 120,
///           backgroundColor: AppColors.backgroundTertiary,
///           valueColor: AlwaysStoppedAnimation(_timerColor(timeLeft)),
///         ),
///         const SizedBox(height: AppSpacing.sm),
///         // Time display
///         Text(
///           '$timeLeft',
///           style: AppTypography.timerStyle.copyWith(
///             color: _timerColor(timeLeft),
///           ),
///         ),
///         Text(
///           'saniye',
///           style: AppTypography.bodySmall.copyWith(
///             color: AppColors.textSecondary,
///           ),
///         ),
///       ],
///     );
///   }
///   
///   Color _timerColor(int seconds) {
///     if (seconds > 60) return AppColors.timerSafe;
///     if (seconds > 15) return AppColors.timerCaution;
///     return AppColors.timerCritical;
///   }
/// }
/// ```

// TODO: Implement GameTimerWidget
