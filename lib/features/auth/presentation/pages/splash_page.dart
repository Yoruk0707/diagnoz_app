import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';

/// Splash Page — uygulama açılışında auth kontrolü.
///
/// NEDEN: Firebase Auth token'ı varsa direkt home'a,
/// yoksa login ekranına yönlendir.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // NEDEN: Widget build olduktan sonra çalışsın diye addPostFrameCallback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).checkAuthState();
    });
  }

  @override
  Widget build(BuildContext context) {
    // NEDEN: State değişince otomatik navigate et.
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!mounted) return;

      if (next is AuthAuthenticated) {
        context.go(AppRoutes.home);
      } else if (next is AuthUnauthenticated) {
        context.go(AppRoutes.authPhone);
      } else if (next is AuthError) {
        context.go(AppRoutes.authPhone);
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.appTitle,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
