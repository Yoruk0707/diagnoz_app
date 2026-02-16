import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/validators/input_validator.dart';
import '../repositories/auth_repository.dart';

/// SMS doğrulama kodu gönderme use case.
///
/// NEDEN: Use case → iş kurallarını repository'den ayırır.
/// Validation burada, Firebase çağrısı repository'de.
///
/// Güvenlik: vcsecurity.md § 2 (input validation)
///           vcsecurity.md § 3 (rate limiting — backend'de)
class SendVerificationCode {
  final AuthRepository _repository;

  const SendVerificationCode(this._repository);

  /// [phoneNumber] ham kullanıcı girişi (0555 123 4567, +90555... vb.)
  ///
  /// 1. Format doğrula
  /// 2. E.164'e normalize et
  /// 3. Repository'ye gönder
  ///
  /// Başarılı → Right(verificationId) — OTP ekranında kullanılır.
  Future<Either<Failure, String>> call(String phoneNumber) async {
    // NEDEN: Geçersiz numarayı backend'e göndermeden yakala (UX + maliyet).
    final normalized = InputValidator.normalizePhone(phoneNumber);

    if (normalized == null) {
      return Left(AuthFailure.invalidPhone());
    }

    return _repository.sendVerificationCode(normalized);
  }
}