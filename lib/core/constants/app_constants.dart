// ═══════════════════════════════════════════════════════════════
// DiagnozApp - app_constants.dart
// ═══════════════════════════════════════════════════════════════
//
// Uygulama genelinde kullanılan sabit değerler.
//
// NEDEN: Magic number'lar kod içinde dağılmasın,
// tek merkezden yönetilsin.
//
// Referans: masterplan.md § Game Mechanics, vcsecurity.md § 3
// ═══════════════════════════════════════════════════════════════

/// Oyun sabitleri, rate limit'ler ve uygulama yapılandırması.
///
/// NEDEN: abstract class → instance oluşturulamaz,
/// sadece static erişim (AppConstants.gameDurationSeconds).
abstract class AppConstants {
  // ═══════════════════════════════════════════════════════════════
  // GAME MECHANICS (masterplan.md § Game Mechanics)
  // ═══════════════════════════════════════════════════════════════

  /// Vaka başına süre (saniye).
  /// NEDEN: 120s oyun tasarımı dengesi — masterplan.md § Rush Mode.
  static const int gameDurationSeconds = 120;

  /// Test isteme maliyeti (saniye).
  /// NEDEN: Her test -10s, stratejik karar mekanizması.
  static const int testTimeCostSeconds = 10;

  /// Oyun başına pas hakkı.
  /// NEDEN: 2 pas — yanlış tanıda hayat kurtarır, 3. yanlış = eleme.
  static const int passesPerGame = 2;

  /// Oyun başına vaka sayısı.
  static const int casesPerGame = 5;

  // ═══════════════════════════════════════════════════════════════
  // SCORE BOUNDS (vcguide.md § Edge Case 2)
  // ═══════════════════════════════════════════════════════════════

  /// Vaka başına maksimum puan: (120/100) * 10 = 12.0
  static const double maxScorePerCase = 12.0;

  /// Vaka başına minimum puan.
  static const double minScorePerCase = 0.0;

  /// Oyun başına maksimum toplam puan: 5 * 12.0 = 60.0
  static const double maxTotalScore = casesPerGame * maxScorePerCase;

  // ═══════════════════════════════════════════════════════════════
  // RATE LIMITING (vcsecurity.md § 3)
  // ═══════════════════════════════════════════════════════════════

  /// Saat başına maksimum SMS sayısı.
  /// NEDEN: SMS spam = ₺₺₺ maliyet. Cloud Function'da da enforce edilecek.
  static const int smsMaxPerHour = 3;

  /// Saat başına maksimum oyun başlatma.
  /// NEDEN: Firestore write spam önleme.
  static const int gameStartMaxPerHour = 20;

  /// Leaderboard cache süresi (dakika).
  /// NEDEN: 1000 kullanıcı × her açılışta okuma = 50K read/gün.
  /// 5 dk cache ile bu ~200 read/gün'e düşer.
  static const int leaderboardCacheMinutes = 5;

  // ═══════════════════════════════════════════════════════════════
  // AUTH (vcsecurity.md § 1)
  // ═══════════════════════════════════════════════════════════════

  /// SMS doğrulama kodu geçerlilik süresi (dakika).
  static const int smsCodeExpiryMinutes = 5;

  /// SMS kodu maksimum deneme hakkı.
  static const int smsMaxAttempts = 3;

  // ═══════════════════════════════════════════════════════════════
  // UI CONSTRAINTS
  // ═══════════════════════════════════════════════════════════════

  /// Görüntü adı minimum uzunluk.
  static const int displayNameMinLength = 3;

  /// Görüntü adı maksimum uzunluk.
  static const int displayNameMaxLength = 20;

  /// Leaderboard'da gösterilecek maksimum oyuncu.
  static const int leaderboardMaxDisplay = 100;

  /// Oyun geçmişinde gösterilecek maksimum oyun.
  static const int gameHistoryMaxDisplay = 10;
}