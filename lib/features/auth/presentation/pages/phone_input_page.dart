import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/validators/input_validator.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';

/// Phone Input Page — telefon numarası girişi.
///
/// Referans: ui_ux_design_clean.md § 4.2 Auth Screen
///           vcsecurity.md § 2 (input validation)
class PhoneInputPage extends ConsumerStatefulWidget {
  const PhoneInputPage({super.key});

  @override
  ConsumerState<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends ConsumerState<PhoneInputPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    // NEDEN: Kod gönderildiğinde OTP sayfasına geç.
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!mounted) return;

      if (next is AuthCodeSent) {
        context.go(AppRoutes.authOtp);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // Başlık
                Text(
                  AppStrings.phoneNumberLabel,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Telefon input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  enabled: !isLoading,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-()]')),
                    LengthLimitingTextInputFormatter(17),
                  ],
                  decoration: const InputDecoration(
                    hintText: AppStrings.phoneNumberHint,
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (!InputValidator.isValidPhone(value)) {
                      return AppStrings.invalidPhoneError;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _sendCode(),
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

                // Kod gönder butonu
                // NEDEN: isLoading → buton disable + spinner.
                // Duplicate submit koruması (vcguide.md § Form Submit).
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: isLoading ? null : _sendCode,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(AppStrings.sendCodeButton),
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendCode() {
    // NEDEN: clearError → önceki hata mesajını temizle.
    ref.read(authNotifierProvider.notifier).clearError();

    if (!_formKey.currentState!.validate()) return;

    ref
        .read(authNotifierProvider.notifier)
        .sendCode(_phoneController.text.trim());
  }
}
