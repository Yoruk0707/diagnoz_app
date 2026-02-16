import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/validators/input_validator.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// SMS doğrulama kodu ile giriş yapma use case.
///
/// NEDEN: Use case → iş kurallarını repository'den ayırır.
/// Client-side validation burada, Firebase çağrısı repository'de.
///
/// Güvenlik: vcsecurity.md § 2 (input validation — client + backend)
class VerifySmsCode {
  final AuthRepository _repository;

  const VerifySmsCode(this._repository);

  /// [verificationId] Firebase'den dönen ID (sendVerificationCode sonrası).
  /// [smsCode] Kullanıcının girdiği 6 haneli kod.
  ///
  /// 1. verificationId boş mu kontrol et
  /// 2. SMS kodu formatını doğrula (6 haneli rakam)
  /// 3. Repository'ye gönder
  ///
  /// Başarılı → Right(AppUser)
  Future<Either<Failure, AppUser>> call({
    required String verificationId,
    required String smsCode,
  }) async {
    // NEDEN: Boş verificationId = flow bozulmuş demek.
    // Normalde olmamalı ama defensive programming.
    if (verificationId.trim().isEmpty) {
      return Left(AuthFailure.unknown(
        'Doğrulama oturumu bulunamadı. Lütfen yeni kod isteyin.',
      ));
    }

    // NEDEN: Kullanıcı kopyala-yapıştır ile boşluk ekleyebilir.
    // trim() ile temizleyip validate ediyoruz (Senaca security review).
    final trimmedCode = smsCode.trim();
    // NEDEN: 6 haneli rakam kontrolü — geçersiz kodu backend'e göndermeden yakala.
    if (!InputValidator.isValidSmsCode(trimmedCode)) {
      return Left(AuthFailure.invalidCode());
    }

    return _repository.verifySmsCode(
      verificationId: verificationId,
      smsCode: trimmedCode,
    );
  }
}
