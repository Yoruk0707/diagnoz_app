import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Auth repository interface — domain layer Firebase'i bilmez.
///
/// NEDEN: Dependency Inversion. Data layer bu interface'i implement eder.
/// Test'te mock'lanır, domain layer saf kalır.
///
/// Referans: vcsecurity.md § 1 (session management)
///           vcsecurity.md § 3 (rate limiting)
abstract class AuthRepository {
  /// SMS doğrulama kodu gönder.
  ///
  /// [phoneNumber] E.164 formatında olmalı (+905551234567).
  /// Rate limit: 3 SMS/saat (vcsecurity.md § 3).
  ///
  /// Başarılı → Right(verificationId) — OTP doğrulamada kullanılır.
  ///
  /// Olası hatalar:
  /// - [AuthFailure] → geçersiz numara, rate limit aşıldı
  /// - [NetworkFailure] → internet yok
  Future<Either<Failure, String>> sendVerificationCode(String phoneNumber);

  /// SMS kodunu doğrula ve giriş yap.
  ///
  /// [verificationId] Firebase'den dönen ID (sendVerificationCode sonrası).
  /// [smsCode] Kullanıcının girdiği 6 haneli kod.
  ///
  /// Başarılı → Right(AppUser)
  /// Yeni kullanıcı ise Firestore'da profil henüz yok olabilir.
  ///
  /// Olası hatalar:
  /// - [AuthFailure] → yanlış kod, süre dolmuş
  Future<Either<Failure, AppUser>> verifySmsCode({
    required String verificationId,
    required String smsCode,
  });

  /// Mevcut oturumdaki kullanıcıyı getir.
  /// Giriş yapılmamışsa → Right(null)
  Future<Either<Failure, AppUser?>> getCurrentUser();

  /// Çıkış yap, token'ları temizle.
  Future<Either<Failure, void>> signOut();

  /// Auth durumu stream'i (login/logout değişimleri).
  ///
  /// NEDEN: Router guard ve UI bu stream'i dinler.
  /// null = giriş yapılmamış, AppUser = aktif oturum.
  Stream<AppUser?> get authStateChanges;

  /// Senkron auth kontrolü (splash screen, guard).
  bool get isAuthenticated;
}