// ═══════════════════════════════════════════════════════════════
// DiagnozApp - app_strings.dart
// ═══════════════════════════════════════════════════════════════
//
// Tüm kullanıcıya görünen metinler tek merkezde.
//
// NEDEN: Hardcoded string'ler yerine tek dosya yönetimi.
// İleride l10n/intl entegrasyonu için hazır altyapı.
//
// KURAL: Kod/değişkenler İNGİLİZCE, UI metinleri TÜRKÇE.
//
// Referans: lessons_learned.md § 9 String Management
// ═══════════════════════════════════════════════════════════════

/// Kullanıcıya görünen tüm metinler.
///
/// NEDEN: abstract class → instance oluşturulamaz.
abstract class AppStrings {
  // ═══════════════════════════════════════════════════════════════
  // APP IDENTITY
  // ═══════════════════════════════════════════════════════════════

  static const appTitle = 'DiagnozApp';

  // ═══════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════

  static const home = 'Ana Sayfa';
  static const game = 'Oyun';
  static const leaderboard = 'Liderlik Tablosu';
  static const profile = 'Profil';

  // ═══════════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════════

  static const phoneNumberLabel = 'Telefon Numaranız';
  static const phoneNumberHint = '+90 5XX XXX XX XX';
  static const sendCodeButton = 'Kod Gönder';
  static const verifyCodeButton = 'Doğrula';
  static const otpLabel = 'Doğrulama Kodu';
  static const otpHint = '6 haneli kodu girin';

  // ═══════════════════════════════════════════════════════════════
  // GAME - RUSH MODE
  // ═══════════════════════════════════════════════════════════════

  static const play = 'Oyna';
  static const rushMode = 'Rush Modu';
  static const zenMode = 'Zen Modu';
  static const diagnose = 'Tanı Koy';
  static const requestTest = 'Test İste';
  static const pass = 'Pas';
  static const timeUp = 'Süre doldu!';
  static const gameOver = 'Oyun Bitti';
  static const correctDiagnosis = 'Doğru Tanı!';
  static const wrongDiagnosis = 'Yanlış Tanı';
  static const passesRemaining = 'Kalan hak';
  static const caseOf = 'Vaka'; // "Vaka 1/5" şeklinde kullanılacak

  // ═══════════════════════════════════════════════════════════════
  // GAME - CASE PRESENTATION
  // ═══════════════════════════════════════════════════════════════

  static const patientInfo = 'Hasta Bilgisi';
  static const chiefComplaint = 'Şikayet';
  static const vitals = 'Vitaller';
  static const testResults = 'Tetkikler';
  static const labTests = 'Laboratuvar';
  static const imaging = 'Görüntüleme';
  static const ecg = 'EKG';
  static const specialTests = 'Özel';

  // ═══════════════════════════════════════════════════════════════
  // GAME - RESULTS
  // ═══════════════════════════════════════════════════════════════

  static const totalScore = 'Toplam Puan';
  static const yourScore = 'Puanınız';
  static const playAgain = 'Tekrar Oyna';
  static const viewLeaderboard = 'Sıralamayı Gör';
  static const newHighScore = 'Yeni Rekor!';

  // ═══════════════════════════════════════════════════════════════
  // LEADERBOARD
  // ═══════════════════════════════════════════════════════════════

  static const weeklyLeaderboard = 'Haftalık Sıralama';
  static const monthlyLeaderboard = 'Aylık Sıralama';
  static const rank = 'Sıra';
  static const player = 'Oyuncu';
  static const score = 'Puan';
  static const yourRank = 'Sıralamanız';
  static const noGamesYet = 'Henüz oyun oynanmadı';

  // ═══════════════════════════════════════════════════════════════
  // PROFILE
  // ═══════════════════════════════════════════════════════════════

  static const editProfile = 'Profili Düzenle';
  static const displayNameLabel = 'Görüntü Adı';
  static const displayNameHint = '3-20 karakter';
  static const university = 'Üniversite';
  static const gameHistory = 'Oyun Geçmişi';
  static const totalGamesPlayed = 'Toplam Oyun';
  static const averageScore = 'Ortalama Puan';
  static const bestScore = 'En Yüksek Puan';
  static const save = 'Kaydet';

  // ═══════════════════════════════════════════════════════════════
  // ERRORS
  // ═══════════════════════════════════════════════════════════════

  static const networkError =
      'Bağlantı hatası. İnternet bağlantınızı kontrol edin.';
  static const initError =
      'Uygulama başlatılamadı.\n'
      'Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';
  static const timeoutError = 'İstek zaman aşımına uğradı.';
  static const unknownError = 'Beklenmeyen bir hata oluştu.';
  static const invalidPhoneError = 'Geçerli bir telefon numarası girin.';
  static const invalidCodeError = 'Geçersiz doğrulama kodu.';
  static const rateLimitError = 'Çok fazla deneme. Lütfen bekleyin.';
  static const noPassesError = 'Pas hakkınız kalmadı!';

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS (Butonlar)
  // ═══════════════════════════════════════════════════════════════

  static const retry = 'Tekrar Dene';
  static const cancel = 'İptal';
  static const confirm = 'Onayla';
  static const close = 'Kapat';
  static const logout = 'Çıkış Yap';

  // ═══════════════════════════════════════════════════════════════
  // EMPTY STATES
  // ═══════════════════════════════════════════════════════════════

  static const noGamesThisWeek = 'Bu hafta henüz oynamadın';
  static const emptyLeaderboard = 'Henüz kimse oynamamış';
  static const noGameHistory = 'Oyun geçmişin boş';
}