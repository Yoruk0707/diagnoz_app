// lib/features/game/presentation/widgets/timer_widget.dart
//
// NEDEN: Timer UI — AppColors.getTimerColor() ile renk değişimi.
// Sadece UI, timer logic game_notifier'da.
// vcguide.md § Timer System: client timer = UX only.
//
// Referans: app_colors.dart § Timer Colors
//           ui_ux_design_clean.md § Timer Display

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Geri sayım timer widget'ı.
///
/// NEDEN: Renk geçişleri + pulse animasyonu ile urgency hissi.
/// 120-60s: yeşil, 59-15s: sarı, 14-0s: kırmızı + pulse.
class TimerWidget extends StatelessWidget {
  final int timeLeft;

  const TimerWidget({super.key, required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getTimerColor(timeLeft);
    final shouldPulse = AppColors.shouldTimerPulse(timeLeft);
    final progress = timeLeft / AppConstants.gameDurationSeconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // NEDEN: Circular progress — kalan süreyi görsel göster.
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: AppColors.backgroundTertiary,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            // NEDEN: Pulse efekti — son 10s'de dikkat çek.
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: shouldPulse ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              child: Text(_formatTime(timeLeft)),
            ),
          ],
        ),
      ],
    );
  }

  /// NEDEN: 90 → "1:30", 5 → "0:05" formatı.
  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
