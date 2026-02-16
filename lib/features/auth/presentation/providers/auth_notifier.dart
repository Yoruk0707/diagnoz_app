import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/send_verification_code.dart';
import '../../domain/usecases/verify_sms_code.dart';
import 'auth_state.dart';

/// Auth akışını yöneten StateNotifier.
///
/// NEDEN: İş mantığı widget'ta değil burada.
/// Widget sadece state'i okur ve UI gösterir.
/// Referans: vcguide.md § State Management (Riverpod)
class AuthNotifier extends StateNotifier<AuthState> {
  final SendVerificationCode _sendVerificationCode;
  final VerifySmsCode _verifySmsCode;
  final AuthRepository _repository;

  AuthNotifier({
    required SendVerificationCode sendVerificationCode,
    required VerifySmsCode verifySmsCode,
    required AuthRepository repository,
  })  : _sendVerificationCode = sendVerificationCode,
        _verifySmsCode = verifySmsCode,
        _repository = repository,
        super(const AuthInitial());

  /// Uygulama açılışında auth durumunu kontrol et.
  ///
  /// NEDEN: Splash ekranında çağrılır.
  /// Kullanıcı daha önce giriş yapmışsa direkt home'a yönlendir.
  Future<void> checkAuthState() async {
    state = const AuthLoading();

    final result = await _repository.getCurrentUser();

    state = result.fold(
      (failure) => const AuthUnauthenticated(),
      (user) => user != null
          ? AuthAuthenticated(user)
          : const AuthUnauthenticated(),
    );
  }

  /// SMS doğrulama kodu gönder.
  ///
  /// [phoneNumber] Ham kullanıcı girişi (0555..., +90555...).
  /// Use case içinde normalize + validate edilir.
  Future<void> sendCode(String phoneNumber) async {
    state = const AuthLoading();

    final result = await _sendVerificationCode.call(phoneNumber);

    state = result.fold(
      (failure) => AuthError(
        failure: failure,
        previousState: const AuthUnauthenticated(),
      ),
      (verificationId) => AuthCodeSent(
        verificationId: verificationId,
        phoneNumber: phoneNumber,
      ),
    );
  }

  /// OTP kodunu doğrula ve giriş yap.
  ///
  /// NEDEN: verificationId önceki state'ten (AuthCodeSent) alınır.
  /// Eğer state AuthCodeSent değilse → güvenlik hatası, işlem yapma.
  Future<void> verifyCode(String smsCode) async {
    // NEDEN: Defensive check — sadece CodeSent state'inden doğrulama yapılabilir.
    final currentState = state;
    if (currentState is! AuthCodeSent) {
      debugPrint('[auth_notifier] verifyCode called in wrong state: $state');
      return;
    }

    state = const AuthLoading();

    final result = await _verifySmsCode.call(
      verificationId: currentState.verificationId,
      smsCode: smsCode,
    );

    state = result.fold(
      (failure) => AuthError(
        failure: failure,
        // NEDEN: Hata sonrası OTP ekranında kal — kullanıcı tekrar deneyebilsin.
        previousState: currentState,
      ),
      (user) => AuthAuthenticated(user),
    );
  }

  /// Kodu tekrar gönder (resend).
  ///
  /// NEDEN: Sadece AuthCodeSent veya AuthError state'inde çağrılabilir.
  Future<void> resendCode() async {
    final currentState = state;
    String? phoneNumber;

    if (currentState is AuthCodeSent) {
      phoneNumber = currentState.phoneNumber;
    } else if (currentState is AuthError &&
        currentState.previousState is AuthCodeSent) {
      phoneNumber =
          (currentState.previousState as AuthCodeSent).phoneNumber;
    }

    if (phoneNumber == null) return;

    await sendCode(phoneNumber);
  }

  /// Çıkış yap.
  Future<void> signOut() async {
    state = const AuthLoading();

    final result = await _repository.signOut();

    state = result.fold(
      (failure) => AuthError(
        failure: failure,
        previousState: state,
      ),
      (_) => const AuthUnauthenticated(),
    );
  }

  /// Hata state'ini temizle, önceki state'e dön.
  ///
  /// NEDEN: Kullanıcı hata mesajını gördükten sonra
  /// dismiss edince önceki ekrana dönmeli.
  void clearError() {
    if (state is AuthError) {
      state = (state as AuthError).previousState;
    }
  }

  /// Phone ekranına geri dön (OTP'den).
  void goBackToPhone() {
    state = const AuthUnauthenticated();
  }
}
