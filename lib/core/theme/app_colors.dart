import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - app_colors.dart
/// ═══════════════════════════════════════════════════════════════
///
/// Dark theme color palette for DiagnozApp.
/// Design Philosophy: "Clinical Precision" - Professional hospital software feel.
///
/// Reference: ui_ux_design_clean.md § 2.1 Color Palette
/// ═══════════════════════════════════════════════════════════════

abstract class AppColors {
  // ═══════════════════════════════════════════════════════════════
  // CACHED LUMINANCE VALUES (Performance optimization)
  // ═══════════════════════════════════════════════════════════════

  /// NEDEN: computeLuminance() CPU-intensive. Sabit renkler için bir kere hesapla.
  static final double _lightLuminance = textPrimary.computeLuminance();
  static final double _darkLuminance = backgroundPrimary.computeLuminance();

  // ═══════════════════════════════════════════════════════════════
  // BACKGROUND COLORS
  // ═══════════════════════════════════════════════════════════════

  /// NEDEN: #121212 Material Design dark theme standardı.
  /// Saf siyah yerine kullanılır - OLED'de göz yorgunluğu azaltır.
  static const Color backgroundPrimary = Color(0xFF121212);

  /// NEDEN: Kartlar ve elevated surfaces için. Shadow yerine renk farkı ile elevation.
  static const Color backgroundSecondary = Color(0xFF1E1E1E);

  /// NEDEN: Input fields ve disabled areas için.
  static const Color backgroundTertiary = Color(0xFF2C2C2C);

  /// NEDEN: Dialogs ve bottom sheets için.
  static const Color surface = Color(0xFF252525);

  // ═══════════════════════════════════════════════════════════════
  // PRIMARY COLORS
  // ═══════════════════════════════════════════════════════════════

  /// NEDEN: #2196F3 tıp dünyasında güven ve profesyonellik simgesi.
  static const Color primary = Color(0xFF2196F3);

  /// NEDEN: Hover/focus states için daha açık ton.
  static const Color primaryLight = Color(0xFF64B5F6);

  /// NEDEN: Pressed states için daha koyu ton - "tıkladın" feedback'i.
  static const Color primaryDark = Color(0xFF1976D2);

  /// NEDEN: Chip ve tag arka planları için düşük opacity primary.
  static const Color primaryContainer = Color(0xFF1E3A5F);

  // ═══════════════════════════════════════════════════════════════
  // SEMANTIC COLORS (Single Source of Truth)
  // ═══════════════════════════════════════════════════════════════

  /// NEDEN: Evrensel "başarı" rengi - doğru tanı, onay durumları.
  static const Color success = Color(0xFF4CAF50);
  static const Color successContainer = Color(0xFF1B3D1F);

  /// NEDEN: Evrensel "hata/tehlike" rengi - yanlış tanı, kritik uyarılar.
  static const Color error = Color(0xFFF44336);
  static const Color errorContainer = Color(0xFF3D1B1B);

  /// NEDEN: Dikkat çekici amber - uyarılar, dikkat gerektiren durumlar.
  static const Color warning = Color(0xFFFFC107);
  static const Color warningContainer = Color(0xFF3D3517);

  /// NEDEN: Semantic olarak primary ile aynı, farklı bağlamda kullanım için ayrı tutulur.
  static const Color info = primary;

  // ═══════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════

  /// NEDEN: En yüksek kontrast - başlıklar, CTA buton text'leri.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// NEDEN: Daha az önemli text - açıklamalar, body text.
  static const Color textSecondary = Color(0xFFB0B0B0);

  /// NEDEN: En düşük öncelik - placeholder, hint text.
  static const Color textTertiary = Color(0xFF757575);

  /// NEDEN: Devre dışı elementler - "bu şu an aktif değil" mesajı.
  static const Color textDisabled = Color(0xFF4A4A4A);

  // ═══════════════════════════════════════════════════════════════
  // TIMER COLORS (DRY - References to Semantic Colors)
  // ═══════════════════════════════════════════════════════════════

  /// NEDEN: 120s-60s arası "Rahat ol, zamanın var" hissi.
  /// DRY: success ile aynı renk, tek yerden değiştirilebilir.
  static const Color timerSafe = success;

  /// NEDEN: 59s-15s arası "Dikkat, zaman azalıyor" uyarısı.
  static const Color timerCaution = warning;

  /// NEDEN: 14s-0s arası "Acele et!" urgency hissi.
  static const Color timerCritical = error;

  /// NEDEN: Son 10s pulse efekti için daha parlak kırmızı.
  /// Bu özel renk, error'dan farklı olmalı (animasyonda fark yaratır).
  static const Color timerPulseGlow = Color(0xFFFF5252);

  // ═══════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Timer widget'ı için renk seçimi.
  /// NEDEN: Renk mantığı merkezi bir yerde tutulur.
  static Color getTimerColor(int secondsRemaining) {
    if (secondsRemaining > 60) return timerSafe;
    if (secondsRemaining > 15) return timerCaution;
    return timerCritical;
  }

  /// Son 10 saniyede pulse animasyonu aktif mi?
  /// NEDEN: 0'da oyun bitti, pulse gereksiz.
  static bool shouldTimerPulse(int secondsRemaining) {
    return secondsRemaining <= 10 && secondsRemaining > 0;
  }

  /// WCAG 2.1 kontrast oranına göre text rengi seçimi.
  /// NEDEN: Auth/OTP ekranlarında okunabilirlik kritik - güvenlik riski.
  ///
  /// Formül: contrast = (L1 + 0.05) / (L2 + 0.05)
  /// Beyaz vs koyu text arasında yüksek kontrastlı olanı döner.
  static Color getContrastTextColor(Color backgroundColor) {
    final bgLuminance = backgroundColor.computeLuminance();

    // NEDEN: WCAG kontrast oranı formülü
    double calculateContrast(double lum1, double lum2) {
      final higher = math.max(lum1, lum2);
      final lower = math.min(lum1, lum2);
      return (higher + 0.05) / (lower + 0.05);
    }

    // NEDEN: Cache'lenmiş luminance değerleri kullanılır (performans)
    final contrastWithLight = calculateContrast(bgLuminance, _lightLuminance);
    final contrastWithDark = calculateContrast(bgLuminance, _darkLuminance);

    return contrastWithLight >= contrastWithDark ? textPrimary : backgroundPrimary;
  }
}