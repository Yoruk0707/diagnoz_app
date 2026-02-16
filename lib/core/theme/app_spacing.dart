import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - app_spacing.dart
/// ═══════════════════════════════════════════════════════════════
///
/// Spacing, border radius, and elevation system for DiagnozApp.
/// Design Philosophy: "Clinical Precision" - Consistent, predictable spacing.
///
/// Reference: ui_ux_design_clean.md § 2.3, 2.4, 2.5
///
/// USAGE:
/// ```dart
/// Padding(padding: AppSpacing.screenPadding)
/// SizedBox(height: AppSpacing.md)
/// Container(decoration: BoxDecoration(borderRadius: AppRadius.card))
/// ```
///
/// ⚠️ SECURITY NOTE - OTP/Auth Screens:
/// All interactive elements (buttons, input fields) MUST have a minimum
/// hit area of 48dp regardless of visual size. Use `smallTouchTarget` or
/// `buttonHeightSmall` only for visual sizing; wrap with GestureDetector
/// or InkWell with `minHeight: 48` for touch safety.
/// ═══════════════════════════════════════════════════════════════

/// Spacing system based on 4-point grid.
///
/// All values are derived from [base] (4dp) for consistency.
/// NEDEN: 4dp grid Material Design standardı. Tek yerden değişiklik yapılabilir.
abstract class AppSpacing {
  // ═══════════════════════════════════════════════════════════════
  // BASE UNIT
  // ═══════════════════════════════════════════════════════════════

  /// Base spacing unit - 4dp
  /// All other spacing values are multiples of this.
  static const double base = 4.0;

  // ═══════════════════════════════════════════════════════════════
  // SPACING SCALE (Derived from base)
  // ═══════════════════════════════════════════════════════════════

  /// Extra Small - 4dp (1x base) - inline spacing
  static const double xs = base * 1; // 4dp

  /// Small - 8dp (2x base) - related elements
  static const double sm = base * 2; // 8dp

  /// Medium - 16dp (4x base) - section spacing
  static const double md = base * 4; // 16dp

  /// Large - 24dp (6x base) - card padding
  static const double lg = base * 6; // 24dp

  /// Extra Large - 32dp (8x base) - screen padding
  static const double xl = base * 8; // 32dp

  /// Extra Extra Large - 48dp (12x base) - major section breaks
  static const double xxl = base * 12; // 48dp

  // ═══════════════════════════════════════════════════════════════
  // SEMANTIC ALIASES
  // ═══════════════════════════════════════════════════════════════

  /// Screen horizontal padding - 32dp
  static const double screenPaddingHorizontal = xl;

  /// Screen vertical padding - 24dp
  static const double screenPaddingVertical = lg;

  /// Card internal padding - 24dp
  static const double cardPadding = lg;

  /// List item spacing - 8dp
  static const double listItemSpacing = sm;

  /// Section spacing - 16dp
  static const double sectionSpacing = md;

  /// Inline icon spacing - 4dp
  static const double inlineSpacing = xs;

  // ═══════════════════════════════════════════════════════════════
  // EDGE INSETS (Semantic only)
  // ═══════════════════════════════════════════════════════════════

  /// No padding
  static const EdgeInsets zero = EdgeInsets.zero;

  /// Screen content padding (32dp horizontal, 24dp vertical)
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingHorizontal,
    vertical: screenPaddingVertical,
  );

  /// Card content padding (24dp all sides)
  static const EdgeInsets cardContentPadding = EdgeInsets.all(cardPadding);

  /// Button internal padding (16dp horizontal, 12dp vertical)
  /// Reference: ui_ux_design_clean.md § 3.1
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: base * 3, // 12dp
  );

  /// List tile padding (16dp horizontal, 8dp vertical)
  static const EdgeInsets listTilePadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  // ═══════════════════════════════════════════════════════════════
  // GAP WIDGETS (Most common only)
  // ═══════════════════════════════════════════════════════════════
  //
  // For uncommon sizes, use: SizedBox(height: AppSpacing.xs)

  /// Vertical gap SM (8dp)
  static const SizedBox gapSM = SizedBox(height: sm);

  /// Vertical gap MD (16dp)
  static const SizedBox gapMD = SizedBox(height: md);

  /// Vertical gap LG (24dp)
  static const SizedBox gapLG = SizedBox(height: lg);

  /// Horizontal gap SM (8dp)
  static const SizedBox gapHorizontalSM = SizedBox(width: sm);

  /// Horizontal gap MD (16dp)
  static const SizedBox gapHorizontalMD = SizedBox(width: md);

  // Explicit vertical aliases for clarity
  /// Alias for [gapSM] - vertical 8dp
  static const SizedBox gapVerticalSM = gapSM;

  /// Alias for [gapMD] - vertical 16dp
  static const SizedBox gapVerticalMD = gapMD;

  /// Alias for [gapLG] - vertical 24dp
  static const SizedBox gapVerticalLG = gapLG;
}

/// Border radius constants.
///
/// Reference: ui_ux_design_clean.md § 2.4
abstract class AppRadius {
  // ═══════════════════════════════════════════════════════════════
  // RAW VALUES
  // ═══════════════════════════════════════════════════════════════

  /// None - 0dp (progress bars)
  static const double none = 0.0;

  /// Small - 4dp (chips, small buttons)
  static const double small = 4.0;

  /// Medium - 8dp (cards, inputs)
  static const double medium = 8.0;

  /// Large - 12dp (bottom sheets, dialogs)
  static const double large = 12.0;

  // ═══════════════════════════════════════════════════════════════
  // BORDER RADIUS PRESETS
  // ═══════════════════════════════════════════════════════════════

  /// No radius
  static const BorderRadius zero = BorderRadius.zero;

  /// Small - 4dp all corners
  static const BorderRadius smallAll = BorderRadius.all(Radius.circular(small));

  /// Medium - 8dp all corners
  static const BorderRadius mediumAll =
      BorderRadius.all(Radius.circular(medium));

  /// Large - 12dp all corners
  static const BorderRadius largeAll = BorderRadius.all(Radius.circular(large));

  /// Top large - 12dp top corners only (bottom sheets)
  static const BorderRadius topLarge = BorderRadius.only(
    topLeft: Radius.circular(large),
    topRight: Radius.circular(large),
  );

  // ═══════════════════════════════════════════════════════════════
  // SEMANTIC ALIASES
  // ═══════════════════════════════════════════════════════════════

  /// Button border radius - 8dp
  static const BorderRadius button = mediumAll;

  /// Card border radius - 8dp
  static const BorderRadius card = mediumAll;

  /// Input field border radius - 8dp
  static const BorderRadius input = mediumAll;

  /// Chip border radius - 4dp
  static const BorderRadius chip = smallAll;

  /// Dialog border radius - 12dp
  static const BorderRadius dialog = largeAll;

  /// Bottom sheet border radius - 12dp top only
  static const BorderRadius bottomSheet = topLarge;
}

/// Elevation constants.
///
/// Reference: ui_ux_design_clean.md § 2.5
/// NEDEN: Dark theme'de shadow yerine subtle border kullanılır.
abstract class AppElevation {
  /// Level 0 - 0dp (flat surfaces)
  static const double level0 = 0.0;

  /// Level 1 - 1dp (cards)
  static const double level1 = 1.0;

  /// Level 2 - 2dp (bottom navigation)
  static const double level2 = 2.0;

  /// Level 3 - 4dp (app bar, FAB)
  static const double level3 = 4.0;

  /// Level 4 - 8dp (dialogs, bottom sheets)
  static const double level4 = 8.0;

  // Semantic aliases
  static const double card = level1;
  static const double bottomNav = level2;
  static const double appBar = level3;
  static const double fab = level3;
  static const double dialog = level4;
  static const double bottomSheet = level4;
}

/// Component dimensions.
///
/// Reference: ui_ux_design_clean.md § 3.1, 3.7
///
/// ⚠️ TOUCH TARGET SAFETY:
/// [minTouchTarget] (48dp) is the minimum for accessibility compliance.
/// Values below 48dp ([smallTouchTarget], [buttonHeightSmall]) are for
/// VISUAL sizing only. Always ensure the actual hit area is >= 48dp.
///
/// Example for small visual button with safe hit area:
/// ```dart
/// SizedBox(
///   height: AppDimensions.minTouchTarget, // 48dp hit area
///   child: Center(
///     child: Container(
///       height: AppDimensions.buttonHeightSmall, // 36dp visual
///       // button content...
///     ),
///   ),
/// )
/// ```
abstract class AppDimensions {
  // ═══════════════════════════════════════════════════════════════
  // TOUCH TARGETS
  // ═══════════════════════════════════════════════════════════════

  /// Minimum touch target - 48dp (Material Design requirement)
  /// CRITICAL: All interactive elements must meet this minimum.
  static const double minTouchTarget = 48.0;

  /// Small touch target - 40dp (VISUAL ONLY)
  /// ⚠️ Below minimum. Use for visual sizing only; ensure hit area >= 48dp.
  /// Avoid in OTP/auth screens where mis-taps are security risks.
  static const double smallTouchTarget = 40.0;

  // ═══════════════════════════════════════════════════════════════
  // BUTTONS
  // ═══════════════════════════════════════════════════════════════

  /// Primary button height - 48dp
  /// Reference: ui_ux_design_clean.md § 3.1
  static const double buttonHeight = 48.0;

  /// Small button height - 36dp (VISUAL ONLY)
  /// ⚠️ Below minTouchTarget. Wrap in 48dp hit area for accessibility.
  /// NOT recommended for OTP/auth screens.
  static const double buttonHeightSmall = 36.0;

  /// Large button height - 56dp
  static const double buttonHeightLarge = 56.0;

  // ═══════════════════════════════════════════════════════════════
  // ICONS
  // ═══════════════════════════════════════════════════════════════

  /// Small icon - 16dp
  static const double iconSmall = 16.0;

  /// Default icon - 24dp (Material Design standard)
  static const double iconDefault = 24.0;

  /// Large icon - 32dp
  static const double iconLarge = 32.0;

  // ═══════════════════════════════════════════════════════════════
  // AVATARS (ui_ux_design_clean.md § 3.7)
  // ═══════════════════════════════════════════════════════════════

  /// Small avatar - 32dp
  static const double avatarSmall = 32.0;

  /// Default avatar - 40dp (list items)
  static const double avatarDefault = 40.0;

  /// Large avatar - 64dp (profile screen)
  static const double avatarLarge = 64.0;

  // ═══════════════════════════════════════════════════════════════
  // BORDERS & NAVIGATION
  // ═══════════════════════════════════════════════════════════════

  /// Thin border - 1dp
  static const double borderThin = 1.0;

  /// Focus border - 2dp
  static const double borderFocus = 2.0;

  /// App bar height - 56dp
  static const double appBarHeight = 56.0;

  /// Bottom navigation height - 56dp
  static const double bottomNavHeight = 56.0;
}