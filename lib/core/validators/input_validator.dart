// ═══════════════════════════════════════════════════════════════
// DiagnozApp - input_validator.dart
// ═══════════════════════════════════════════════════════════════
//
// GÜVENLİK KRİTİK DOSYA
//
// "AI kodunun %90'ında input validation eksik."
// — vcsecurity.md § 2
//
// Her kullanıcı girişi buradan geçmeli.
// Backend validation'ı REPLACEMAZ, sadece UX iyileştirir
// ve gereksiz network call'ları engeller.
//
// Referans: vcsecurity.md § 2 (input validation)
//           masterplan.md § scoring formula
// ═══════════════════════════════════════════════════════════════

abstract class InputValidator {
  // ─────────────────────────────────────────────────────────────
  // PHONE VALIDATION
  // ─────────────────────────────────────────────────────────────

  /// Telefon numarasını E.164 formatına normalize eder.
  ///
  /// Geçersizse null döner.
  /// "0555 123 4567" → "+905551234567"
  /// "+905551234567" → "+905551234567"
  ///
  /// NEDEN: Farklı formatlar Firestore'da duplicate user oluşturur.
  /// Referans: vcsecurity.md § 1 (Phone Number Normalization)
  static String? normalizePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;

    // NEDEN: Boşluk, tire, parantez gibi formatlamayı temizle.
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d+]'), '');

    String normalized = digitsOnly;

    // NEDEN: Türkiye hedef pazar, +90 yoksa ekle.
    // FIX: "90555..." girişi "+9090555..." üretiyordu (Senaca review).
    if (normalized.startsWith('+')) {
      // Zaten uluslararası format, dokunma
    } else if (normalized.startsWith('90') && normalized.length >= 12) {
      // NEDEN: "905551234567" → "+905551234567"
      normalized = '+$normalized';
    } else if (normalized.startsWith('0')) {
      normalized = '+90${normalized.substring(1)}';
    } else {
      // NEDEN: "5551234567" → "+905551234567"
      normalized = '+90$normalized';
    }

    // NEDEN: E.164 pattern → + ardından 10-15 rakam.
    if (!RegExp(r'^\+\d{10,15}$').hasMatch(normalized)) {
      return null;
    }

    return normalized;
  }

  /// Telefon numarası geçerli mi? (boolean versiyon, UI için)
  static bool isValidPhone(String? phone) => normalizePhone(phone) != null;

  // ─────────────────────────────────────────────────────────────
  // SMS CODE VALIDATION
  // ─────────────────────────────────────────────────────────────

  /// 6 haneli SMS kodu doğrulama.
  // NEDEN: Kullanıcı kodu boşlukla yapıştırabilir (" 123456 ").
  static bool isValidSmsCode(String? code) {
    if (code == null) return false;
    return RegExp(r'^\d{6}$').hasMatch(code.trim());
  }

  // ─────────────────────────────────────────────────────────────
  // DISPLAY NAME VALIDATION
  // ─────────────────────────────────────────────────────────────

  /// Display name: 3-20 karakter, harf + boşluk + Türkçe karakterler.
  ///
  /// NEDEN: Leaderboard'da görünecek, XSS koruması gerekli.
  static bool isValidDisplayName(String? name) {
    if (name == null || name.trim().isEmpty) return false;
    final trimmed = name.trim();
    if (trimmed.length < 3 || trimmed.length > 20) return false;

    // NEDEN: Türkçe karakterler (ıİöÖüÜçÇşŞğĞ) + harf + boşluk.
    return RegExp(r'^[a-zA-ZıİöÖüÜçÇşŞğĞ\s]+$').hasMatch(trimmed);
  }

  // ─────────────────────────────────────────────────────────────
  // GAME VALUES
  // ─────────────────────────────────────────────────────────────

  /// Kalan süre doğrulama (0-120 arası int).
  ///
  /// NEDEN: Negatif veya >120 → manipülasyon (vcguide.md § Timer).
  /// Bu client-side check. Backend AYRICA doğrular.
  static int? validateTimeLeft(dynamic value) {
    if (value is! int) return null;
    if (value < 0 || value > 120) return null;
    return value;
  }

  /// Skor hesapla ve doğrula.
  ///
  /// Formül: (timeLeft / 100) * 10
  /// Max: 12.0 (120s kaldığında)
  /// Referans: masterplan.md § Scoring
  static double calculateScore(int timeLeft) {
    final validTime = validateTimeLeft(timeLeft);
    if (validTime == null) return 0.0;

    final rawScore = (validTime / 100) * 10;

    // NEDEN: Defensive clamping — formula dışı değer imkansız ama güvenlik katmanı.
    return rawScore.clamp(0.0, 12.0);
  }

  // ─────────────────────────────────────────────────────────────
  // DIAGNOSIS STRING
  // ─────────────────────────────────────────────────────────────

  /// Tanı stringi: max 100 karakter, alfanümerik + Türkçe + boşluk + tire.
  ///
  /// NEDEN: XSS ve injection koruması (vcsecurity.md § 2).
  static bool isValidDiagnosis(String? diagnosis) {
    if (diagnosis == null || diagnosis.trim().isEmpty) return false;
    final trimmed = diagnosis.trim();
    if (trimmed.length > 100) return false;
    return RegExp(r'^[a-zA-Z0-9ıİöÖüÜçÇşŞğĞ\s\-]+$').hasMatch(trimmed);
  }
}
