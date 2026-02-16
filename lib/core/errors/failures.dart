import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - failures.dart
/// ═══════════════════════════════════════════════════════════════
///
/// Clean Architecture hata yönetimi.
///
/// NEDEN: Exception yerine Failure kullanıyoruz çünkü:
/// - Exception = beklenmeyen hatalar (crash)
/// - Failure = beklenen hata durumları (yanlış kod, süre doldu)
/// - Either<Failure, T> ile fonksiyonel error handling
///
/// Referans: vcsecurity.md § 2 (input validation)
///           vcguide.md § edge cases
/// ═══════════════════════════════════════════════════════════════

/// Tüm failure türlerinin base class'ı.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Firebase/API hataları (5xx, timeout vb.)
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// İnternet bağlantısı yok veya timeout.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});

  /// Standart bağlantı hatası mesajı.
  factory NetworkFailure.noConnection() => const NetworkFailure(
        'Bağlantı hatası. İnternet bağlantınızı kontrol edin.',
        code: 'no-connection',
      );
}

/// Auth işlem hataları (SMS, login, token).
///
/// Referans: vcsecurity.md § 1 (session management)
///           vcsecurity.md § 3 (rate limiting)
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});

  factory AuthFailure.invalidPhone() => const AuthFailure(
        'Geçersiz telefon numarası.',
        code: 'invalid-phone',
      );

  factory AuthFailure.rateLimited() => const AuthFailure(
        'Çok fazla deneme. Lütfen birkaç dakika bekleyin.',
        code: 'rate-limited',
      );

  factory AuthFailure.invalidCode() => const AuthFailure(
        'Geçersiz doğrulama kodu.',
        code: 'invalid-code',
      );

  factory AuthFailure.codeExpired() => const AuthFailure(
        'Doğrulama kodunun süresi doldu. Yeni kod isteyin.',
        code: 'code-expired',
      );

  factory AuthFailure.sessionExpired() => const AuthFailure(
        'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
        code: 'session-expired',
      );

  factory AuthFailure.unknown(String message) => AuthFailure(
        message,
        code: 'unknown',
      );
}

/// Input validation hataları.
///
/// Referans: vcsecurity.md § 2
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Oyun mantığı hataları (timer, pass, duplicate submit).
///
/// Referans: vcguide.md § Timer System, § Form Submit Edge Case
class GameFailure extends Failure {
  const GameFailure(super.message, {super.code});

  factory GameFailure.timeExceeded() => const GameFailure(
        'Süre doldu!',
        code: 'time-exceeded',
      );

  factory GameFailure.noPasses() => const GameFailure(
        'Pas hakkınız kalmadı.',
        code: 'no-passes',
      );

  factory GameFailure.alreadySubmitted() => const GameFailure(
        'Bu vaka zaten gönderildi.',
        code: 'already-submitted',
      );

  /// NEDEN: Client timer manipülasyonu tespit edildi (vcguide.md § Timer).
  factory GameFailure.timerTampering() => const GameFailure(
        'Zamanlayıcı hatası tespit edildi.',
        code: 'timer-tampering',
      );
}

/// Hive cache okuma/yazma hataları.
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}
