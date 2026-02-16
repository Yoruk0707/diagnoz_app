/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - primary_button.dart
/// ═══════════════════════════════════════════════════════════════
/// 
/// PURPOSE: Primary CTA button (ui_ux_design.md § 3.1)
/// 
/// SPECIFICATIONS:
/// - Height: 48dp (accessibility minimum)
/// - Padding: 16dp horizontal
/// - Border Radius: 8dp
/// - Background: #2196F3 (primary)
/// - Text: White, 14sp Medium
/// 
/// STATES:
/// - Default: #2196F3 background
/// - Pressed: #1976D2 background
/// - Disabled: #2C2C2C background, #4A4A4A text
/// - Loading: #2196F3 background + CircularProgressIndicator
/// 
/// ⚠️  CRITICAL (vcguide.md § Edge Case 5):
/// - MUST support disabled state during loading
/// - MUST prevent double-tap
/// - Use: onPressed: isLoading ? null : () => ...
/// 
/// EXAMPLE:
/// ```dart
/// class PrimaryButton extends StatelessWidget {
///   final String text;
///   final VoidCallback? onPressed;
///   final bool isLoading;
///   
///   const PrimaryButton({
///     required this.text,
///     required this.onPressed,
///     this.isLoading = false,
///   });
///   
///   @override
///   Widget build(BuildContext context) {
///     return ElevatedButton(
///       // WHY: Disable during loading to prevent double-tap
///       // (vcguide.md § Edge Case 5)
///       onPressed: isLoading ? null : onPressed,
///       style: ElevatedButton.styleFrom(
///         minimumSize: const Size(double.infinity, 48),
///         backgroundColor: AppColors.primary,
///         disabledBackgroundColor: AppColors.backgroundTertiary,
///         shape: RoundedRectangleBorder(
///           borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
///         ),
///       ),
///       child: isLoading
///           ? const SizedBox(
///               height: 20,
///               width: 20,
///               child: CircularProgressIndicator(
///                 strokeWidth: 2,
///                 color: Colors.white,
///               ),
///             )
///           : Text(text),
///     );
///   }
/// }
/// ```

// TODO: Implement PrimaryButton
