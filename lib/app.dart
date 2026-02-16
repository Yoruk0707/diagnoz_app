import 'package:flutter/material.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - app.dart
/// ═══════════════════════════════════════════════════════════════
///
/// Uygulamanın kök widget'ı.
///
/// NEDEN: MaterialApp.router → GoRouter entegrasyonu.
/// Theme, navigation, localization hepsi burada bağlanır.
/// ═══════════════════════════════════════════════════════════════

class DiagnozApp extends StatelessWidget {
  const DiagnozApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // NEDEN: App title → OS task switcher'da görünür.
      title: AppStrings.appTitle,

      // NEDEN: Debug banner kaldır → screenshot'larda temiz görünsün.
      debugShowCheckedModeBanner: false,

      // NEDEN: Merkezi tema → tüm widget'lar tutarlı görünüm.
      theme: AppTheme.dark,

      // NEDEN: GoRouter bağlantısı → navigator yerine router kullan.
      routerConfig: appRouter,
    );
  }
}