/// Custom exception sınıfları.
///
/// NEDEN: Data layer Firebase/API hatalarını exception olarak fırlatır.
/// Repository bu exception'ları yakalayıp Failure'a çevirir.
/// Böylece domain layer framework-agnostic kalır.
///
/// Akış: Firebase Error → AuthException → Repository catch → AuthFailure
library;

/// Sunucu/API kaynaklı hatalar.
class ServerException implements Exception {
  final String message;
  final String? code;

  const ServerException(this.message, {this.code});

  @override
  String toString() => 'ServerException: $message (code: $code)';
}

/// Ağ bağlantısı hataları.
class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'İnternet bağlantısı bulunamadı']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Kimlik doğrulama hataları.
///
/// NEDEN: Firebase Auth hata kodları → Türkçe kullanıcı mesajları.
/// Her Firebase error code için anlamlı bir mesaj döner.
///
/// Referans: vcsecurity.md § 1 (session management)
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  /// Firebase Auth hata kodlarını Türkçe mesajlara çevir.
  ///
  /// NEDEN: Firebase hata mesajları İngilizce ve teknik.
  /// Kullanıcıya Türkçe, anlaşılır mesaj göstermeliyiz.
  factory AuthException.fromFirebaseCode(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return const AuthException(
          'Geçersiz telefon numarası. Lütfen kontrol edin.',
          code: 'invalid-phone-number',
        );
      case 'too-many-requests':
        // NEDEN: Rate limiting mesajı — kullanıcıyı bilgilendirip spam'i azalt.
        return const AuthException(
          'Çok fazla deneme yaptınız. Lütfen bir süre bekleyin.',
          code: 'too-many-requests',
        );
      case 'invalid-verification-code':
        return const AuthException(
          'Doğrulama kodu hatalı. Lütfen tekrar deneyin.',
          code: 'invalid-verification-code',
        );
      case 'session-expired':
        return const AuthException(
          'Doğrulama süresi doldu. Lütfen yeni kod isteyin.',
          code: 'session-expired',
        );
      case 'quota-exceeded':
        // NEDEN: Firebase SMS kotası dolmuş — ciddi durum, genel mesaj ver.
        return const AuthException(
          'Sistem geçici olarak kullanılamıyor. Lütfen daha sonra tekrar deneyin.',
          code: 'quota-exceeded',
        );
      case 'user-disabled':
        return const AuthException(
          'Bu hesap devre dışı bırakılmış. Destek ile iletişime geçin.',
          code: 'user-disabled',
        );
      case 'network-request-failed':
        return const AuthException(
          'İnternet bağlantınızı kontrol edin.',
          code: 'network-request-failed',
        );
      case 'web-context-cancelled':
        // NEDEN: Kullanıcı reCAPTCHA'yı kapattı — bilgilendirici mesaj.
        return const AuthException(
          'Doğrulama iptal edildi. Lütfen tekrar deneyin.',
          code: 'web-context-cancelled',
        );
      case 'captcha-check-failed':
        return const AuthException(
          'Güvenlik doğrulaması başarısız. Lütfen tekrar deneyin.',
          code: 'captcha-check-failed',
        );
      case 'missing-phone-number':
        return const AuthException(
          'Telefon numarası girilmedi.',
          code: 'missing-phone-number',
        );
      case 'invalid-verification-id':
        return const AuthException(
          'Doğrulama oturumu geçersiz. Lütfen tekrar kod isteyin.',
          code: 'invalid-verification-id',
        );
      case 'operation-not-allowed':
        return const AuthException(
          'Telefon doğrulama şu anda devre dışı.',
          code: 'operation-not-allowed',
        );
      default:
        // NEDEN: Bilinmeyen hata kodları için genel mesaj.
        // Detayları logluyoruz ama kullanıcıya göstermiyoruz.
        return AuthException(
          'Kimlik doğrulama hatası. Lütfen tekrar deneyin.',
          code: code,
        );
    }
  }

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// Yerel önbellek (cache) hataları.
class CacheException implements Exception {
  final String message;

  const CacheException([this.message = 'Önbellek hatası oluştu']);

  @override
  String toString() => 'CacheException: $message';
}
