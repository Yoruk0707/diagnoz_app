import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/send_verification_code.dart';
import '../../domain/usecases/verify_sms_code.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

/// Auth Providers — Riverpod dependency injection.
///
/// NEDEN: Tüm auth bağımlılıkları tek dosyada.
/// Provider → Use Case → Repository → Firebase zinciri burada kurulur.
/// Test'te bu provider'ları override ederek mock inject edebilirsin.
///
/// Referans: vcguide.md § State Management (Riverpod)

// ─────────────────────────────────────────────────────────────
// DATA LAYER
// ─────────────────────────────────────────────────────────────

/// Firebase Auth instance provider.
///
/// NEDEN: Test'te MockFirebaseAuth inject etmek için.
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

/// Auth repository implementasyonu.
///
/// NEDEN: AuthRepository interface'i üzerinden erişim → Dependency Inversion.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(
    auth: ref.read(firebaseAuthProvider),
  ),
);

// ─────────────────────────────────────────────────────────────
// DOMAIN LAYER (Use Cases)
// ─────────────────────────────────────────────────────────────

/// SMS gönderme use case provider.
final sendVerificationCodeProvider = Provider<SendVerificationCode>(
  (ref) => SendVerificationCode(ref.read(authRepositoryProvider)),
);

/// SMS doğrulama use case provider.
final verifySmsCodeProvider = Provider<VerifySmsCode>(
  (ref) => VerifySmsCode(ref.read(authRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────
// PRESENTATION LAYER (State Management)
// ─────────────────────────────────────────────────────────────

/// Ana auth state notifier.
///
/// NEDEN: Tüm auth akışı bu notifier üzerinden yönetilir.
/// UI bu provider'ı watch eder, state'e göre ekran gösterir.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    sendVerificationCode: ref.read(sendVerificationCodeProvider),
    verifySmsCode: ref.read(verifySmsCodeProvider),
    repository: ref.read(authRepositoryProvider),
  ),
);

/// Auth state changes stream — router guard için.
///
/// NEDEN: GoRouter redirect bu stream'i dinler.
/// Login/logout değişimlerinde otomatik yönlendirme.
final authStateChangesProvider = StreamProvider<bool>(
  (ref) => ref.read(authRepositoryProvider).authStateChanges.map(
        (user) => user != null,
      ),
);
