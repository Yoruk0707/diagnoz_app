/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - timer_provider.dart
/// ═══════════════════════════════════════════════════════════════
/// 
/// PURPOSE: Timer state management with Riverpod
/// 
/// ⚠️  CRITICAL FILE - Memory Leak Prevention
/// 
/// REFERENCE: vcguide.md § Edge Case 1: Timer System
/// 
/// WRONG IMPLEMENTATION (Memory Leak):
/// ```dart
/// class TimerNotifier extends StateNotifier<int> {
///   TimerNotifier() : super(120) {
///     Timer.periodic(Duration(seconds: 1), (timer) {
///       state--;  // LEAK: Timer never stops!
///     });
///   }
/// }
/// // 10 mount/unmount cycles = 10 timers running!
/// ```
/// 
/// CORRECT IMPLEMENTATION:
/// ```dart
/// // WHY: autoDispose ensures cleanup when provider is no longer watched
/// @riverpod
/// class Timer extends _$Timer {
///   Timer? _timer;
///   
///   @override
///   int build() {
///     // WHY: Register cleanup when provider is disposed
///     ref.onDispose(() {
///       _timer?.cancel();
///     });
///     
///     return 120; // Initial time
///   }
///   
///   void start() {
///     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
///       if (state > 0) {
///         state--;
///       } else {
///         _timer?.cancel();
///         _handleTimeout();
///       }
///     });
///   }
///   
///   void pause() {
///     _timer?.cancel();
///   }
///   
///   void reset() {
///     _timer?.cancel();
///     state = 120;
///   }
///   
///   /// Deduct time for test request
///   /// WHY: vcguide.md § Edge Case 3 - prevent negative time
///   void deductTime(int seconds) {
///     state = (state - seconds).clamp(0, 120);
///   }
///   
///   void _handleTimeout() {
///     // Notify game state about timeout
///     ref.read(gameStateProvider.notifier).handleTimeout();
///   }
/// }
/// ```
/// 
/// KEY POINTS:
/// 1. Use autoDispose modifier
/// 2. Store Timer reference in variable
/// 3. Cancel in dispose/onDispose
/// 4. Validate time bounds (0-120)
/// 5. This timer is UI ONLY - server validates actual time
/// 
/// USAGE IN WIDGET:
/// ```dart
/// class GameScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final timeLeft = ref.watch(timerProvider);
///     
///     return Text('$timeLeft saniye');
///   }
/// }
/// ```
/// 
/// TESTING (vcguide.md § Testing):
/// ```dart
/// testWidgets('Timer is disposed when widget unmounts', (tester) async {
///   await tester.pumpWidget(GameScreen());
///   await tester.pumpWidget(Container()); // Unmount
///   expect(tester.binding.timers.length, 0); // No leaks!
/// });
/// ```

// TODO: Implement Timer provider with Riverpod
