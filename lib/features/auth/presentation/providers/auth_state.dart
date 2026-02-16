import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';

/// Auth akışının base state'i.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Uygulama ilk açıldığında — auth durumu henüz kontrol edilmedi.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Async işlem devam ediyor (SMS gönderiliyor, kod doğrulanıyor).
///
/// NEDEN: UI'da loading spinner göstermek ve
/// butonu disable etmek için (duplicate submit koruması).
/// Referans: vcguide.md § Form Submit Edge Case
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// SMS kodu gönderildi, OTP girişi bekleniyor.
///
/// [verificationId] Firebase'den dönen ID — OTP doğrulamada lazım.
/// [phoneNumber] Kullanıcıya "X numarasına gönderildi" mesajı için.
class AuthCodeSent extends AuthState {
  final String verificationId;
  final String phoneNumber;

  const AuthCodeSent({
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [verificationId, phoneNumber];
}

/// Kullanıcı giriş yapmış durumda.
class AuthAuthenticated extends AuthState {
  final AppUser user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Kullanıcı giriş yapmamış (logout olmuş veya ilk kontrol sonucu).
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Auth işlemi sırasında hata oluştu.
///
/// [failure] Hatanın detayı (Türkçe mesaj içerir).
/// [previousState] Hata öncesi state — geri dönmek için.
///
/// NEDEN: Hata sonrası kullanıcı phone veya OTP ekranında kalabilir.
/// previousState ile doğru ekranı göstermeye devam ediyoruz.
class AuthError extends AuthState {
  final Failure failure;
  final AuthState previousState;

  const AuthError({
    required this.failure,
    required this.previousState,
  });

  @override
  List<Object?> get props => [failure, previousState];
}
