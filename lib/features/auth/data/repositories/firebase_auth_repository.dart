import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/validators/input_validator.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase Auth repository implementasyonu.
///
/// NEDEN: Domain layer Firebase'i bilmez — bu class köprü görevi görür.
/// AuthRepository interface'ini implement eder, Firebase SDK ile konuşur.
///
/// Güvenlik referansları:
///   vcsecurity.md § 1 (phone normalization — E.164)
///   vcsecurity.md § 2 (input validation — backend'de de yapılır)
///   vcsecurity.md § 3 (rate limiting — Cloud Functions'da)
///   lessons_learned.md § 3 (no stack traces in production)
///   lessons_learned.md § 11 (Crashlytics web incompatibility)
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;

  // NEDEN: DI ile test edilebilirlik. Mock FirebaseAuth inject edilebilir.
  FirebaseAuthRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  // ─────────────────────────────────────────────
  // SMS Gönderme
  // ─────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> sendVerificationCode(
    String phoneNumber,
  ) async {
    try {
      // NEDEN: Defense-in-depth — use case'de validate edilmiş olsa bile
      // repository girişinde de normalize et (Senaca security review).
      final normalizedPhone = InputValidator.normalizePhone(phoneNumber);
      if (normalizedPhone == null) {
        return Left(AuthFailure.invalidPhone());
      }

      // NEDEN: Completer kullanıyoruz çünkü Firebase verifyPhoneNumber
      // callback-based, ama interface Future-based dönüş bekliyor.
      final completer = Completer<Either<Failure, String>>();

      // NEDEN: Completer hiçbir callback çağrılmazsa sonsuza kadar bekler.
      // 90s failsafe ile hang'i önlüyoruz (Senaca security review).
      final timeoutTimer = Timer(const Duration(seconds: 90), () {
        if (!completer.isCompleted) {
          completer.complete(const Left(ServerFailure(
            'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.',
            code: 'verification-timeout',
          )));
        }
      });

      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,

        // NEDEN: Web'de reCAPTCHA otomatik gösterilir.
        // timeout süresi içinde kod gelmezse codeAutoRetrievalTimeout tetiklenir.
        timeout: const Duration(seconds: 60),

        // ── Android auto-verification ──
        // NEDEN: Android SMS'i otomatik okuyabilir. MVP web-first olduğu için
        // şimdilik sadece logluyoruz. Mobile fazda implement edilecek.
        verificationCompleted: (PhoneAuthCredential credential) {
          if (kDebugMode) {
            print('[AUTH] Auto-verification completed (Android only)');
          }
        },

        // ── Hata ──
        verificationFailed: (FirebaseAuthException e) {
          if (kDebugMode) {
            print('[AUTH] Verification failed: ${e.code}');
          }
          if (!completer.isCompleted) {
            completer.complete(Left(_mapFirebaseError(e.code)));
          }
        },

        // ── Kod gönderildi ──
        codeSent: (String verificationId, int? resendToken) {
          if (kDebugMode) {
            print('[AUTH] Code sent. VerificationId length: ${verificationId.length}');
          }
          // NEDEN: verificationId'yi döndürüyoruz → OTP ekranında kullanılacak.
          if (!completer.isCompleted) {
            completer.complete(Right(verificationId));
          }
        },

        // ── Otomatik kod okuma süresi doldu ──
        // NEDEN: Bu callback Android auto-retrieval için. Web'de önemsiz ama
        // Firebase SDK yine de çağırabilir. Completer zaten tamamlanmış olmalı.
        codeAutoRetrievalTimeout: (String verificationId) {
          if (kDebugMode) {
            print('[AUTH] Auto-retrieval timeout');
          }
        },
      );

      final result = await completer.future;
      timeoutTimer.cancel();
      return result;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('[AUTH] FirebaseAuthException: ${e.code}');
      }
      return Left(_mapFirebaseError(e.code));
    } catch (e) {
      // NEDEN: Beklenmeyen hatalar için genel catch.
      // lessons_learned.md § 3: Production'da stack trace loglanmaz.
      if (kDebugMode) {
        print('[AUTH] Unexpected error in sendVerificationCode: $e');
      }
      return Left(AuthFailure.unknown(
        'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
      ));
    }
  }

  // ─────────────────────────────────────────────
  // SMS Kod Doğrulama
  // ─────────────────────────────────────────────

  @override
  Future<Either<Failure, AppUser>> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return Left(AuthFailure.unknown(
          'Giriş başarısız. Lütfen tekrar deneyin.',
        ));
      }

      return Right(_mapFirebaseUser(firebaseUser));
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('[AUTH] Verify SMS failed: ${e.code}');
      }
      return Left(_mapFirebaseError(e.code));
    } catch (e) {
      if (kDebugMode) {
        print('[AUTH] Unexpected error in verifySmsCode: $e');
      }
      return Left(AuthFailure.unknown(
        'Doğrulama sırasında beklenmeyen bir hata oluştu.',
      ));
    }
  }

  // ─────────────────────────────────────────────
  // Mevcut Kullanıcı
  // ─────────────────────────────────────────────

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;

      if (firebaseUser == null) {
        return const Right(null);
      }

      return Right(_mapFirebaseUser(firebaseUser));
    } catch (e) {
      if (kDebugMode) {
        print('[AUTH] Error getting current user: $e');
      }
      return Left(AuthFailure.unknown(
        'Kullanıcı bilgileri alınamadı.',
      ));
    }
  }

  // ─────────────────────────────────────────────
  // Çıkış
  // ─────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _auth.signOut();
      return const Right(null);
    } catch (e) {
      if (kDebugMode) {
        print('[AUTH] Error signing out: $e');
      }
      return Left(AuthFailure.unknown(
        'Çıkış yapılırken hata oluştu.',
      ));
    }
  }

  // ─────────────────────────────────────────────
  // Auth State Stream
  // ─────────────────────────────────────────────

  @override
  Stream<AppUser?> get authStateChanges {
    // NEDEN: Router guard ve UI bu stream'i dinler.
    // Firebase authStateChanges() her login/logout'ta event fırlatır.
    return _auth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _mapFirebaseUser(firebaseUser);
    });
  }

  @override
  bool get isAuthenticated => _auth.currentUser != null;

  // ─────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────

  /// Maps Firebase error codes to specific AuthFailure factories.
  ///
  /// NEDEN: Genel "bilinmeyen hata" yerine spesifik failure döndürmek
  /// UI'da doğru mesaj gösterilmesini sağlar (Senaca security review).
  AuthFailure _mapFirebaseError(String firebaseCode) {
    switch (firebaseCode) {
      case 'invalid-phone-number':
      case 'missing-phone-number':
        return AuthFailure.invalidPhone();
      case 'too-many-requests':
        return AuthFailure.rateLimited();
      case 'session-expired':
      case 'invalid-verification-id':
        return AuthFailure.sessionExpired();
      case 'invalid-verification-code':
        return AuthFailure.invalidCode();
      case 'code-expired':
        return AuthFailure.codeExpired();
      case 'operation-not-allowed':
        return const AuthFailure(
          'SMS doğrulama şu anda kullanılamıyor.',
          code: 'operation-not-allowed',
        );
      default:
        // NEDEN: AuthException.fromFirebaseCode'dan Türkçe mesaj al.
        final exception = AuthException.fromFirebaseCode(firebaseCode);
        return AuthFailure(
          exception.message,
          code: exception.code,
        );
    }
  }

  /// Firebase User → AppUser entity dönüşümü.
  ///
  /// NEDEN: Domain layer Firebase User bilmez.
  /// Sadece ihtiyacımız olan alanları map'liyoruz.
  /// Yeni kullanıcılarda displayName null olacak (profil tamamlama sonrası set edilir).
  AppUser _mapFirebaseUser(User firebaseUser) {
    return AppUser(
      id: firebaseUser.uid,
      phoneNumber: firebaseUser.phoneNumber ?? '',
      // NEDEN: Yeni kullanıcıda null — hasCompletedProfile false döner.
      displayName: firebaseUser.displayName,
      stats: const UserStats(),
      privacy: const UserPrivacy(),
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }
}
