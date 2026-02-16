import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - app_typography.dart
/// ═══════════════════════════════════════════════════════════════
///
/// Typography system for DiagnozApp.
/// Design Philosophy: "Clinical Precision" - Professional, readable, fast.
///
/// Reference: ui_ux_design_clean.md § 2.2 Typography
///
/// USAGE:
/// ```dart
/// Text('87', style: AppTypography.timerDisplay.copyWith(color: AppColors.timerSafe))
/// ```
///
/// FONT SETUP: See README.md § Font Configuration
/// - Production: Use local font assets (recommended)
/// - Development: google_fonts package (with runtime fetching disabled)
/// ═══════════════════════════════════════════════════════════════

/// Font family constants.
///
/// WARNING: If fonts are not bundled as assets, system fallback fonts will be
/// used. This breaks the fixed-width guarantee for timer/OTP displays.
/// Always verify fonts load correctly in production builds.
abstract class FontFamily {
  /// Primary font - Inter
  /// Neutral, highly readable, excellent for medical/professional apps.
  /// Fallback: iOS → SF Pro, Android → Roboto
  static const String primary = 'Inter';

  /// Monospace font - JetBrains Mono
  /// CRITICAL: Fixed-width prevents layout shift and character confusion.
  /// Essential for: Timer countdown, OTP input, lab values
  static const String monospace = 'JetBrains Mono';
}

/// Main typography class.
abstract class AppTypography {
  // ═══════════════════════════════════════════════════════════════
  // FONT WEIGHTS (Private)
  // ═══════════════════════════════════════════════════════════════

  static const FontWeight _bold = FontWeight.w700;
  static const FontWeight _semiBold = FontWeight.w600;
  static const FontWeight _medium = FontWeight.w500;
  static const FontWeight _regular = FontWeight.w400;

  // ═══════════════════════════════════════════════════════════════
  // DISPLAY STYLES
  // ═══════════════════════════════════════════════════════════════

  /// Game Over score - 32sp / Bold
  static const TextStyle displayLarge = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 32,
    fontWeight: _bold,
    height: 1.25,
    letterSpacing: -0.5,
  );

  /// Timer base style - 28sp / Bold
  static const TextStyle displayMedium = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 28,
    fontWeight: _bold,
    height: 1.29,
    letterSpacing: -0.25,
  );

  /// Smaller display - 24sp / Bold
  static const TextStyle displaySmall = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 24,
    fontWeight: _bold,
    height: 1.33,
    letterSpacing: 0,
  );

  // ═══════════════════════════════════════════════════════════════
  // HEADLINE STYLES
  // ═══════════════════════════════════════════════════════════════

  /// Screen titles - 24sp / SemiBold
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 24,
    fontWeight: _semiBold,
    height: 1.33,
    letterSpacing: 0,
  );

  /// Secondary headlines - 20sp / SemiBold
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 20,
    fontWeight: _semiBold,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Small headlines - 18sp / SemiBold
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 18,
    fontWeight: _semiBold,
    height: 1.44,
    letterSpacing: 0,
  );

  // ═══════════════════════════════════════════════════════════════
  // TITLE STYLES
  // ═══════════════════════════════════════════════════════════════

  /// Card headers - 20sp / SemiBold
  static const TextStyle titleLarge = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 20,
    fontWeight: _semiBold,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Section headers - 16sp / SemiBold
  static const TextStyle titleMedium = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 16,
    fontWeight: _semiBold,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Small title - 14sp / SemiBold
  static const TextStyle titleSmall = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 14,
    fontWeight: _semiBold,
    height: 1.43,
    letterSpacing: 0.1,
  );

  // ═══════════════════════════════════════════════════════════════
  // BODY STYLES
  // ═══════════════════════════════════════════════════════════════

  /// Primary content - 16sp / Regular
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 16,
    fontWeight: _regular,
    height: 1.5,
    letterSpacing: 0.5,
  );

  /// Secondary content - 14sp / Regular
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 14,
    fontWeight: _regular,
    height: 1.43,
    letterSpacing: 0.25,
  );

  /// Captions, hints - 12sp / Regular
  static const TextStyle bodySmall = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 12,
    fontWeight: _regular,
    height: 1.33,
    letterSpacing: 0.4,
  );

  // ═══════════════════════════════════════════════════════════════
  // LABEL STYLES
  // ═══════════════════════════════════════════════════════════════

  /// Large button text - 14sp / Medium
  static const TextStyle labelLarge = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 14,
    fontWeight: _medium,
    height: 1.43,
    letterSpacing: 0.1,
  );

  /// Button/chip text - 12sp / Medium
  static const TextStyle labelMedium = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 12,
    fontWeight: _medium,
    height: 1.33,
    letterSpacing: 0.5,
  );

  /// Small label - 11sp / Medium
  static const TextStyle labelSmall = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 11,
    fontWeight: _medium,
    height: 1.45,
    letterSpacing: 0.5,
  );

  // ═══════════════════════════════════════════════════════════════
  // ALIASES (Backward Compatibility)
  // ═══════════════════════════════════════════════════════════════

  /// Alias for headlineLarge
  static const TextStyle headline = headlineLarge;

  /// Alias for labelMedium
  static const TextStyle label = labelMedium;

  // ═══════════════════════════════════════════════════════════════
  // MONOSPACE STYLES (Timer, Scores, Lab Values)
  // ═══════════════════════════════════════════════════════════════

  /// Timer countdown - 28sp / Bold / Monospace
  /// Fixed-width ensures no layout shift during countdown.
  static const TextStyle timerDisplay = TextStyle(
    fontFamily: FontFamily.monospace,
    fontSize: 28,
    fontWeight: _bold,
    height: 1.29,
    letterSpacing: 0,
  );

  /// Timer label ("saniye") - 12sp / Regular
  static const TextStyle timerLabel = TextStyle(
    fontFamily: FontFamily.primary,
    fontSize: 12,
    fontWeight: _regular,
    height: 1.33,
    letterSpacing: 0.4,
  );

  /// Score display (5.2 puan) - 20sp / SemiBold / Monospace
  static const TextStyle scoreDisplay = TextStyle(
    fontFamily: FontFamily.monospace,
    fontSize: 20,
    fontWeight: _semiBold,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Large score (Game over - 27.0) - 32sp / Bold / Monospace
  static const TextStyle scoreLarge = TextStyle(
    fontFamily: FontFamily.monospace,
    fontSize: 32,
    fontWeight: _bold,
    height: 1.25,
    letterSpacing: 0,
  );

  /// Lab values (WBC: 12.000) - 14sp / Medium / Monospace
  static const TextStyle labValue = TextStyle(
    fontFamily: FontFamily.monospace,
    fontSize: 14,
    fontWeight: _medium,
    height: 1.43,
    letterSpacing: 0,
  );

  // ═══════════════════════════════════════════════════════════════
  // THEME INTEGRATION
  // ═══════════════════════════════════════════════════════════════

  /// Material 3 TextTheme with all slots populated for design consistency.
  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}

// ═══════════════════════════════════════════════════════════════
// AUTH/OTP EKRANLARI İÇİN ACCESSIBILITY KILAVUZU
// ═══════════════════════════════════════════════════════════════
//
// ÖNCE: Layout'u text scaling ile uyumlu tasarla
// -----------------------------------------------
// - OTP kutuları için Flexible/Expanded kullan, sabit genişlik verme
// - Butonlarda minHeight: 48 (Material guideline)
// - overflow: TextOverflow.ellipsis veya FittedBox kullan
// - maxLines belirle
//
// SON ÇARE: Text scaling'i sınırla (yalnızca dar alanlar için)
// -------------------------------------------------------------
// Eğer layout düzeltmeleri yetmezse ve UI taşması kritik hatalara
// yol açıyorsa, SADECE ilgili widget'ı sınırla:
//
// MediaQuery(
//   data: MediaQuery.of(context).copyWith(
//     textScaler: TextScaler.linear(
//       MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.4),
//     ),
//   ),
//   child: OtpInputRow(), // Sadece bu widget etkilenir
// )
//
// ⚠️ DİKKAT: Bu yaklaşım erişilebilirliği azaltır. Accessibility
// trade-off'u dokümante et ve QA'de görme engelli kullanıcılarla test et.
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// FONT KURULUMU (Özet - Detaylar README.md'de)
// ═══════════════════════════════════════════════════════════════
//
// PRODUCTION (Önerilen): Local Assets
// ------------------------------------
// flutter:
//   fonts:
//     - family: Inter
//       fonts:
//         - asset: assets/fonts/Inter-Regular.ttf
//           weight: 400
//         - asset: assets/fonts/Inter-Medium.ttf
//           weight: 500
//         - asset: assets/fonts/Inter-SemiBold.ttf
//           weight: 600
//         - asset: assets/fonts/Inter-Bold.ttf
//           weight: 700
//     - family: JetBrains Mono
//       fonts:
//         - asset: assets/fonts/JetBrainsMono-Regular.ttf
//         - asset: assets/fonts/JetBrainsMono-Bold.ttf
//           weight: 700
//
// DEVELOPMENT: google_fonts (Dikkatli kullan)
// -------------------------------------------
// dependencies:
//   google_fonts: ^6.1.0  # Versiyonu sabitle!
//
// // main.dart - Runtime network bağımlılığını kapat:
// void main() {
//   GoogleFonts.config.allowRuntimeFetching = false;
//   runApp(MyApp());
// }
//
// // pubspec.lock'u commit et (supply-chain güvenliği)
// ═══════════════════════════════════════════════════════════════