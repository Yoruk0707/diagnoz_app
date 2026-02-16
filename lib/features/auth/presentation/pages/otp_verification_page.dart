import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';

/// OTP Verification Page — SMS kodu doğrulama.
///
/// Referans: ui_ux_design_clean.md § 4.2 Auth Screen (After Code Sent)
///           vcguide.md § Form Submit Edge Case
class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final _codeController = TextEditingController();

  // NEDEN: 45 saniye resend cooldown (ui_ux_design § 4.2).
  Timer? _resendTimer;
  int _resendCountdown = 45;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _codeController.dispose();
    // NEDEN: Timer cleanup → memory leak önleme (vcguide.md § Timer).
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 45;
    _canResend = false;
    _resendTimer?.cancel();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    // NEDEN: Maskelenmiş numara göster (privacy).
    final phoneDisplay = _getMaskedPhone(authState);

    // NEDEN: Giriş başarılı → home'a yönlendir.
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!mounted) return;

      if (next is AuthAuthenticated) {
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isLoading
              ? null
              : () {
                  ref.read(authNotifierProvider.notifier).goBackToPhone();
                  context.go(AppRoutes.authPhone);
                },
        ),
        title: const Text(AppStrings.otpLabel),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Bilgi mesajı
              Text(
                '$phoneDisplay\nnumarasına kod gönderildi.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Kod girişi
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                autofocus: true,
                enabled: !isLoading,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      letterSpacing: 12,
                    ),
                decoration: const InputDecoration(
                  hintText: AppStrings.otpHint,
                ),
                // NEDEN: 6 hane girilince otomatik doğrula.
                onChanged: (value) {
                  if (value.length == 6) {
                    _verifyCode();
                  }
                },
                onFieldSubmitted: (_) => _verifyCode(),
              ),
              const SizedBox(height: 24),

              // Hata mesajı
              if (authState is AuthError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    authState.failure.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Doğrula butonu
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: isLoading ? null : _verifyCode,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.verifyCodeButton),
                ),
              ),
              const SizedBox(height: 16),

              // Tekrar gönder
              TextButton(
                onPressed: _canResend && !isLoading
                    ? () {
                        ref.read(authNotifierProvider.notifier).resendCode();
                        _startResendTimer();
                        _codeController.clear();
                      }
                    : null,
                child: Text(
                  _canResend
                      ? 'Kodu Tekrar Gönder'
                      : 'Tekrar gönder (${_resendCountdown}s)',
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyCode() {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    ref.read(authNotifierProvider.notifier).clearError();
    ref.read(authNotifierProvider.notifier).verifyCode(code);
  }

  /// Telefon numarasını maskele: +90 555 *** **67
  String _getMaskedPhone(AuthState state) {
    String phone = '';

    if (state is AuthCodeSent) {
      phone = state.phoneNumber;
    } else if (state is AuthError && state.previousState is AuthCodeSent) {
      phone = (state.previousState as AuthCodeSent).phoneNumber;
    }

    if (phone.length < 4) return phone;

    // NEDEN: Son 2 hane hariç maskele (privacy).
    final visible = phone.substring(phone.length - 2);
    final masked = phone.substring(0, phone.length - 2).replaceAll(
          RegExp(r'\d'),
          '*',
        );
    return '$masked$visible';
  }
}
