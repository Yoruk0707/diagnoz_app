import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - app_theme.dart
/// ═══════════════════════════════════════════════════════════════
///
/// Central theme configuration bringing together colors, typography,
/// and spacing into Material 3 ThemeData.
///
/// Design Philosophy: "Clinical Precision" - Professional, dark, fast.
///
/// Reference: ui_ux_design_clean.md § 2 (Design System)
///
/// USAGE:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.dark,
///   // ...
/// )
/// ```
///
/// ⚠️ PERFORMANCE NOTE:
/// Theme is built ONCE via static final. Component themes are cached.
/// Do NOT access AppTheme.dark in hot paths (build methods) - pass via context.
///
/// ⚠️ SECURITY NOTE - OTP/Auth Screens:
/// Text color handling varies by component type:
/// - TextTheme styles: explicit colors via _buildColorizedTextTheme()
/// - Buttons: text color via foregroundColor property (not textStyle)
/// - Input fields: explicit colors on hintStyle/labelStyle/errorStyle
/// - Dialogs, Chips, ListTiles, etc.: explicit colors on text style properties
/// Verify readability after any color palette changes.
/// ═══════════════════════════════════════════════════════════════

/// Main theme class.
///
/// NEDEN: Abstract class prevents instantiation.
/// All access is via static final field (built once).
abstract class AppTheme {
  // ═══════════════════════════════════════════════════════════════
  // MAIN THEME (Built once, cached)
  // ═══════════════════════════════════════════════════════════════

  /// Dark theme - MVP default
  /// NEDEN: ui_ux_design_clean.md § 2.1 - "Dark mode is MVP default"
  /// NEDEN: static final ensures single construction at app startup.
  static final ThemeData dark = _buildDarkTheme();

  /// Builds the dark theme.
  /// NEDEN: Separated into method for clarity and potential future light theme.
  static ThemeData _buildDarkTheme() {
    // NEDEN: Pre-compute colorized text theme once for reuse in component themes.
    final colorizedTextTheme = _buildColorizedTextTheme();

    return ThemeData(
      // ─────────────────────────────────────────────────────────
      // CORE SETTINGS
      // ─────────────────────────────────────────────────────────

      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,

      // ─────────────────────────────────────────────────────────
      // COLOR SCHEME
      // ─────────────────────────────────────────────────────────

      colorScheme: _darkColorScheme,

      // ─────────────────────────────────────────────────────────
      // TYPOGRAPHY (with colors applied)
      // ─────────────────────────────────────────────────────────

      textTheme: colorizedTextTheme,

      // ─────────────────────────────────────────────────────────
      // COMPONENT THEMES
      // ─────────────────────────────────────────────────────────
      // NOTE: Color handling varies by component:
      // - Buttons: foregroundColor defines text/icon color
      // - Text-heavy components: explicit color in textStyle

      appBarTheme: _buildAppBarTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      cardTheme: _cardTheme,
      chipTheme: _buildChipTheme(),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(),
      dialogTheme: _buildDialogTheme(),
      bottomSheetTheme: _bottomSheetTheme,
      dividerTheme: _dividerTheme,
      iconTheme: _iconTheme,
      progressIndicatorTheme: _progressIndicatorTheme,
      snackBarTheme: _buildSnackBarTheme(),
      tabBarTheme: _buildTabBarTheme(),
      listTileTheme: _buildListTileTheme(),

      // ─────────────────────────────────────────────────────────
      // VISUAL FEEDBACK
      // ─────────────────────────────────────────────────────────

      // NEDEN: Subtle splash effect for dark theme - not too bright
      splashColor: AppColors.primary.withValues(alpha: 0.1),
      highlightColor: AppColors.primary.withValues(alpha: 0.05),

      // NEDEN: Text selection colors (TextField text selection)
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.3),
        selectionHandleColor: AppColors.primary,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // COLOR SCHEME (const for performance)
  // ═══════════════════════════════════════════════════════════════

  /// Dark color scheme
  /// NEDEN: Material 3 color system - semantic color mapping
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,

    // Primary colors - ui_ux_design_clean.md § 2.1
    primary: AppColors.primary,
    onPrimary: AppColors.textPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.primaryLight,

    // Secondary = Primary for DiagnozApp (monochromatic design)
    // NEDEN: Minimalist design, single accent color
    secondary: AppColors.primary,
    onSecondary: AppColors.textPrimary,
    secondaryContainer: AppColors.primaryContainer,
    onSecondaryContainer: AppColors.primaryLight,

    // Tertiary (accent - minimal usage)
    tertiary: AppColors.primaryLight,
    onTertiary: AppColors.backgroundPrimary,

    // Error colors - ui_ux_design_clean.md § 2.1
    error: AppColors.error,
    onError: AppColors.textPrimary,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.error,

    // Surface colors - ui_ux_design_clean.md § 2.1
    surface: AppColors.backgroundSecondary,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,

    // Outline colors
    outline: AppColors.backgroundTertiary,
    outlineVariant: AppColors.textDisabled,

    // Inverse colors (snackbars, tooltips)
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.backgroundPrimary,
    inversePrimary: AppColors.primaryDark,

    // Shadow - minimal in dark theme
    shadow: Colors.black,

    // NEDEN: Dark theme uses borders instead of elevation tint.
    // Setting surfaceTint transparent disables Material 3's automatic tint.
    // Reference: ui_ux_design_clean.md § 2.5
    surfaceTint: Colors.transparent,
  );

  // ═══════════════════════════════════════════════════════════════
  // TEXT THEME WITH COLORS (built once, cached)
  // ═══════════════════════════════════════════════════════════════

  /// Build colorized text theme from base AppTypography.
  /// NEDEN: AppTypography styles are colorless for reusability.
  /// Colors are applied here based on semantic hierarchy.
  static TextTheme _buildColorizedTextTheme() {
    const base = AppTypography.textTheme;
    return TextTheme(
      // Display - high emphasis (white)
      displayLarge: base.displayLarge?.copyWith(color: AppColors.textPrimary),
      displayMedium: base.displayMedium?.copyWith(color: AppColors.textPrimary),
      displaySmall: base.displaySmall?.copyWith(color: AppColors.textPrimary),

      // Headline - high emphasis (white)
      headlineLarge: base.headlineLarge?.copyWith(color: AppColors.textPrimary),
      headlineMedium: base.headlineMedium?.copyWith(color: AppColors.textPrimary),
      headlineSmall: base.headlineSmall?.copyWith(color: AppColors.textPrimary),

      // Title - high emphasis (white)
      titleLarge: base.titleLarge?.copyWith(color: AppColors.textPrimary),
      titleMedium: base.titleMedium?.copyWith(color: AppColors.textPrimary),
      titleSmall: base.titleSmall?.copyWith(color: AppColors.textPrimary),

      // Body - medium emphasis (secondary gray)
      bodyLarge: base.bodyLarge?.copyWith(color: AppColors.textSecondary),
      bodyMedium: base.bodyMedium?.copyWith(color: AppColors.textSecondary),
      bodySmall: base.bodySmall?.copyWith(color: AppColors.textTertiary),

      // Label - medium emphasis (secondary gray)
      labelLarge: base.labelLarge?.copyWith(color: AppColors.textSecondary),
      labelMedium: base.labelMedium?.copyWith(color: AppColors.textSecondary),
      labelSmall: base.labelSmall?.copyWith(color: AppColors.textTertiary),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CACHED TEXT STYLES (for component themes)
  // ═══════════════════════════════════════════════════════════════
  // NEDEN: These are used by multiple component themes.
  // Caching avoids repeated copyWith calls.

  /// Title text style with primary (white) color.
  /// Used in: AppBar, Dialog title
  static final TextStyle _titleLargePrimary =
      AppTypography.titleLarge.copyWith(color: AppColors.textPrimary);

  /// Body medium with secondary color.
  /// Used in: Dialog content, SnackBar
  static final TextStyle _bodyMediumSecondary =
      AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary);

  /// Body large with primary (white) color - HIGH EMPHASIS.
  /// Used in: ListTile title
  /// NEDEN: Titles should be high-emphasis (white) for readability in dark theme.
  static final TextStyle _bodyLargePrimary =
      AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary);

  /// Body small with tertiary color.
  /// Used in: ListTile subtitle
  static final TextStyle _bodySmallTertiary =
      AppTypography.bodySmall.copyWith(color: AppColors.textTertiary);

  /// Label large (no color) - color comes from TabBar's labelColor property.
  /// Used in: TabBar labels
  /// NEDEN: TabBar uses labelColor/unselectedLabelColor for color; textStyle for font only.
  static const TextStyle _labelLargeBase = AppTypography.labelLarge;

  /// Label medium with primaryLight color for chip text.
  /// Used in: Chip label (on primaryContainer background)
  /// NEDEN: #64B5F6 on #1E3A5F = good contrast ratio (~4.5:1)
  static final TextStyle _labelMediumChip =
      AppTypography.labelMedium.copyWith(color: AppColors.primaryLight);

  /// Label small (no color) - color comes from BottomNav's itemColor property.
  /// Used in: BottomNavigationBar labels
  /// NEDEN: BottomNav uses selectedItemColor/unselectedItemColor; textStyle for font only.
  static const TextStyle _labelSmallBase = AppTypography.labelSmall;

  // ═══════════════════════════════════════════════════════════════
  // APP BAR THEME
  // ═══════════════════════════════════════════════════════════════

  static AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      // NEDEN: Dark theme uses flat app bar - color difference instead of elevation
      // Reference: ui_ux_design_clean.md § 2.5 - Level 0 for flat surfaces
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.backgroundPrimary,
      foregroundColor: AppColors.textPrimary,
      centerTitle: true,

      // NEDEN: Explicit color ensures visibility on dark background
      titleTextStyle: _titleLargePrimary,

      // NEDEN: Status bar styling - light icons on dark background
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppDimensions.iconDefault,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ELEVATED BUTTON THEME (Primary CTA)
  // ═══════════════════════════════════════════════════════════════

  /// Primary button (CTA)
  /// Reference: ui_ux_design_clean.md § 3.1
  ///
  /// NOTE: Text color comes from foregroundColor, not textStyle.
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        // NEDEN: ui_ux_design_clean.md § 3.1 - Height: 48dp
        minimumSize: const Size(0, AppDimensions.buttonHeight),

        // NEDEN: ui_ux_design_clean.md § 3.1 - Padding: 16dp horizontal
        padding: AppSpacing.buttonPadding,

        // NEDEN: ui_ux_design_clean.md § 3.1 - Border Radius: 8dp
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),

        // Colors - foregroundColor handles BOTH text and icon color
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        disabledBackgroundColor: AppColors.backgroundTertiary,
        disabledForegroundColor: AppColors.textDisabled,

        // NEDEN: Dark theme uses minimal elevation - shadow unnecessary
        elevation: 0,
        shadowColor: Colors.transparent,

        // Typography (font only - color from foregroundColor)
        textStyle: AppTypography.labelLarge,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // OUTLINED BUTTON THEME (Secondary)
  // ═══════════════════════════════════════════════════════════════

  /// Secondary button
  /// Reference: ui_ux_design_clean.md § 3.1
  ///
  /// NOTE: Text color comes from foregroundColor, not textStyle.
  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppDimensions.buttonHeight),
        padding: AppSpacing.buttonPadding,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),

        // NEDEN: ui_ux_design_clean.md § 3.1 - Border: 1dp #2196F3
        side: const BorderSide(
          color: AppColors.primary,
          width: AppDimensions.borderThin,
        ),

        // Colors - foregroundColor handles BOTH text and icon color
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.textDisabled,

        // Typography (font only - color from foregroundColor)
        textStyle: AppTypography.labelLarge,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TEXT BUTTON THEME
  // ═══════════════════════════════════════════════════════════════

  /// NOTE: Text color comes from foregroundColor, not textStyle.
  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, AppDimensions.buttonHeight),
        padding: AppSpacing.buttonPadding,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.textDisabled,
        // Typography (font only - color from foregroundColor)
        textStyle: AppTypography.labelLarge,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // INPUT DECORATION THEME
  // ═══════════════════════════════════════════════════════════════

  /// Text field styling
  /// Reference: ui_ux_design_clean.md § 2.4, 3.1
  ///
  /// ⚠️ SECURITY NOTE: Input fields are used in OTP/auth screens.
  /// Ensure hint/label contrast is sufficient for readability.
  static InputDecorationTheme _buildInputDecorationTheme() {
    // NEDEN: Cache border radius to avoid repeated object creation
    const inputBorderRadius = AppRadius.input;

    return InputDecorationTheme(
      // NEDEN: ui_ux_design_clean.md § 2.1 - Background Tertiary: #2C2C2C
      filled: true,
      fillColor: AppColors.backgroundTertiary,

      // NEDEN: ui_ux_design_clean.md § 2.4 - Medium: 8dp
      border: const OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide(
          color: AppColors.primary,
          width: AppDimensions.borderFocus,
        ),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide(
          color: AppColors.error,
          width: AppDimensions.borderThin,
        ),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide(
          color: AppColors.error,
          width: AppDimensions.borderFocus,
        ),
      ),
      disabledBorder: const OutlineInputBorder(
        borderRadius: inputBorderRadius,
        borderSide: BorderSide.none,
      ),

      // Content padding
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),

      // Text styles with explicit colors
      // NEDEN: Ensure readability on #2C2C2C background
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
      labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
      errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),

      // Floating label
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      floatingLabelStyle: AppTypography.bodySmall.copyWith(color: AppColors.primary),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CARD THEME (const)
  // ═══════════════════════════════════════════════════════════════

  static const CardThemeData _cardTheme = CardThemeData(
    // NEDEN: ui_ux_design_clean.md § 2.1 - Background Secondary: #1E1E1E
    color: AppColors.backgroundSecondary,

    // NEDEN: ui_ux_design_clean.md § 2.5 - Level 1: 1dp
    elevation: AppElevation.card,
    shadowColor: Colors.transparent,

    // NEDEN: ui_ux_design_clean.md § 2.4 - Medium: 8dp
    shape: RoundedRectangleBorder(borderRadius: AppRadius.card),

    margin: EdgeInsets.zero,
  );

  // ═══════════════════════════════════════════════════════════════
  // CHIP THEME
  // ═══════════════════════════════════════════════════════════════

  /// Chip styling (Test request chips)
  /// Reference: ui_ux_design_clean.md § 3.3
  static ChipThemeData _buildChipTheme() {
    return ChipThemeData(
      // NEDEN: ui_ux_design_clean.md § 3.3 - Available: #1E3A5F background
      backgroundColor: AppColors.primaryContainer,

      // NEDEN: ui_ux_design_clean.md § 3.3 - Requested: #2196F3 background
      selectedColor: AppColors.primary,

      // NEDEN: ui_ux_design_clean.md § 3.3 - Disabled: #2C2C2C background
      disabledColor: AppColors.backgroundTertiary,

      // NEDEN: Explicit color for contrast on #1E3A5F background
      // #64B5F6 (primaryLight) on #1E3A5F = ~4.5:1 contrast ratio
      labelStyle: _labelMediumChip,

      // NEDEN: ui_ux_design_clean.md § 2.4 - Small: 4dp
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.chip),

      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION BAR THEME
  // ═══════════════════════════════════════════════════════════════

  /// Bottom navigation bar styling
  ///
  /// NEDEN: Single source of truth for colors:
  /// - selectedItemColor / unselectedItemColor control BOTH icon and label colors
  /// - labelStyle only defines font (no color) to avoid conflicts
  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme() {
    return const BottomNavigationBarThemeData(
      // NEDEN: ui_ux_design_clean.md § 2.5 - Level 2: 2dp
      elevation: AppElevation.bottomNav,

      backgroundColor: AppColors.backgroundSecondary,

      // NEDEN: Single source of truth for label AND icon colors
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,

      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,

      // NEDEN: Font only - color comes from itemColor properties above
      selectedLabelStyle: _labelSmallBase,
      unselectedLabelStyle: _labelSmallBase,

      selectedIconTheme: IconThemeData(
        size: AppDimensions.iconDefault,
        // NEDEN: Color inherited from selectedItemColor
      ),
      unselectedIconTheme: IconThemeData(
        size: AppDimensions.iconDefault,
        // NEDEN: Color inherited from unselectedItemColor
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOG THEME
  // ═══════════════════════════════════════════════════════════════

  /// Dialog styling
  /// ⚠️ SECURITY NOTE: Dialogs may be used for OTP verification confirmations.
  /// Title and content must have sufficient contrast on #252525 surface.
  static DialogThemeData _buildDialogTheme() {
    return DialogThemeData(
      // NEDEN: ui_ux_design_clean.md § 2.1 - Surface: #252525
      backgroundColor: AppColors.surface,

      // NEDEN: ui_ux_design_clean.md § 2.5 - Level 4: 8dp
      elevation: AppElevation.dialog,

      // NEDEN: ui_ux_design_clean.md § 2.4 - Large: 12dp
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialog),

      // NEDEN: Explicit colors ensure readability on #252525
      // Title: White (#FFFFFF) = high contrast
      // Content: Secondary gray (#B0B0B0) = readable
      titleTextStyle: _titleLargePrimary,
      contentTextStyle: _bodyMediumSecondary,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BOTTOM SHEET THEME (const)
  // ═══════════════════════════════════════════════════════════════

  static const BottomSheetThemeData _bottomSheetTheme = BottomSheetThemeData(
    // NEDEN: ui_ux_design_clean.md § 2.1 - Surface: #252525
    backgroundColor: AppColors.surface,

    // NEDEN: ui_ux_design_clean.md § 2.5 - Level 4: 8dp
    elevation: AppElevation.bottomSheet,

    // NEDEN: ui_ux_design_clean.md § 2.4 - Large: 12dp (top only)
    shape: RoundedRectangleBorder(borderRadius: AppRadius.bottomSheet),

    // Modal backdrop
    modalBackgroundColor: AppColors.surface,
    modalElevation: AppElevation.bottomSheet,
  );

  // ═══════════════════════════════════════════════════════════════
  // DIVIDER THEME (const)
  // ═══════════════════════════════════════════════════════════════

  static const DividerThemeData _dividerTheme = DividerThemeData(
    color: AppColors.backgroundTertiary,
    thickness: AppDimensions.borderThin,
    space: 0,
  );

  // ═══════════════════════════════════════════════════════════════
  // ICON THEME (const)
  // ═══════════════════════════════════════════════════════════════

  static const IconThemeData _iconTheme = IconThemeData(
    size: AppDimensions.iconDefault,
    color: AppColors.textSecondary,
  );

  // ═══════════════════════════════════════════════════════════════
  // PROGRESS INDICATOR THEME (const)
  // ═══════════════════════════════════════════════════════════════

  static const ProgressIndicatorThemeData _progressIndicatorTheme =
      ProgressIndicatorThemeData(
    color: AppColors.primary,
    linearTrackColor: AppColors.backgroundTertiary,
    circularTrackColor: AppColors.backgroundTertiary,
  );

  // ═══════════════════════════════════════════════════════════════
  // SNACK BAR THEME
  // ═══════════════════════════════════════════════════════════════

  /// SnackBar styling
  /// NOTE: Not specified in ui_ux_design_clean.md - sensible defaults
  static SnackBarThemeData _buildSnackBarTheme() {
    return SnackBarThemeData(
      backgroundColor: AppColors.surface,
      // NEDEN: Explicit color for readability on #252525
      contentTextStyle: _bodyMediumSecondary,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mediumAll),
      behavior: SnackBarBehavior.floating,
      actionTextColor: AppColors.primary,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB BAR THEME
  // ═══════════════════════════════════════════════════════════════

  /// TabBar styling (Game screen tabs: Hasta Bilgisi / Tetkikler)
  /// NOTE: Not detailed in ui_ux_design_clean.md - sensible defaults
  ///
  /// NEDEN: Single source of truth for colors:
  /// - labelColor / unselectedLabelColor control text colors
  /// - labelStyle only defines font (no color) to avoid conflicts
  static TabBarThemeData _buildTabBarTheme() {
    return const TabBarThemeData(
      // NEDEN: Single source of truth for label colors
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textTertiary,

      // NEDEN: Font only - color comes from labelColor properties above
      labelStyle: _labelLargeBase,
      unselectedLabelStyle: _labelLargeBase,

      indicatorColor: AppColors.primary,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LIST TILE THEME
  // ═══════════════════════════════════════════════════════════════

  /// ListTile styling
  /// ⚠️ SECURITY NOTE: ListTiles may be used in settings/auth screens.
  /// Titles should be high-emphasis (white) for readability.
  static ListTileThemeData _buildListTileTheme() {
    return ListTileThemeData(
      contentPadding: AppSpacing.listTilePadding,
      minLeadingWidth: AppDimensions.iconDefault,
      iconColor: AppColors.textSecondary,
      textColor: AppColors.textPrimary,

      // NEDEN: Title = HIGH EMPHASIS (white) for readability in dark theme
      // User must clearly see what they're tapping in settings/auth screens
      titleTextStyle: _bodyLargePrimary,

      // NEDEN: Subtitle = lower emphasis (tertiary) for visual hierarchy
      subtitleTextStyle: _bodySmallTertiary,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SEMANTIC COLORS - REMOVED
// ═══════════════════════════════════════════════════════════════
//
// NEDEN (Removal Justification):
// 1. SemanticColors ThemeExtension was defined but NOT integrated into
//    ThemeData.extensions, creating a CRASH RISK if any code used
//    Theme.of(context).extension<SemanticColors>()!
//
// 2. AppColors already provides all semantic colors as static constants:
//    - AppColors.success, AppColors.successContainer
//    - AppColors.warning, AppColors.warningContainer
//    - AppColors.timerSafe, AppColors.timerCaution, AppColors.timerCritical
//
// 3. No theme switching is planned (MVP is dark-only), so ThemeExtension
//    provides no benefit over direct AppColors access.
//
// 4. Duplicated functionality increases maintenance burden and confusion.
//
// MIGRATION: Replace any SemanticColors usage with direct AppColors access:
//   BEFORE: Theme.of(context).extension<SemanticColors>()!.success
//   AFTER:  AppColors.success
// ═══════════════════════════════════════════════════════════════