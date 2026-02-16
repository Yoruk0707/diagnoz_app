import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // NEDEN: ensureInitialized runZonedGuarded içinde olmalı.
  // Aksi halde Zone mismatch hatası oluşur (binding farklı zone'da init olur).
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await _initializeApp();
    },
    (error, stack) {
      // NEDEN: Release'de internal detay sızdırmıyoruz.
      _logError('unhandled_async_error', error, stack);
    },
  );
}

/// Firebase ve Crashlytics başlatma, ardından uygulamayı çalıştırma.
Future<void> _initializeApp() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // NEDEN: Crashlytics sadece Android ve iOS'ta destekleniyor.
    // Web'de çağrılırsa assertion hatası fırlatır ve uygulama çöker.
    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // NEDEN: Debug modda crash raporlama gereksiz ve yanıltıcı.
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
    }
  } catch (e, stack) {
    _logError('firebase_init_failed', e, stack);
    // NEDEN: Firebase olmadan uygulama çalışamaz, retry ekranı göster.
    runApp(const _FirebaseErrorApp());
    return;
  }

  // NEDEN: ProviderScope Riverpod'un kök widget'ı - tüm provider'ları barındırır.
  runApp(
    const ProviderScope(
      child: DiagnozApp(),
    ),
  );
}

/// Release-safe hata loglama.
void _logError(String code, Object error, StackTrace stack) {
  if (kDebugMode) {
    debugPrint('[$code] $error\n$stack');
    return;
  }

  debugPrint('[$code] Hata oluştu. Detaylar Crashlytics\'e gönderildi.');

  // NEDEN: Web'de Crashlytics yok, sadece log bas.
  if (kIsWeb) return;

  try {
    FirebaseCrashlytics.instance.recordError(error, stack, reason: code);
  } catch (_) {
    // NEDEN: Crashlytics henüz init olmamış olabilir.
  }
}

/// Firebase başlatma hatası ekranı - retry destekli.
class _FirebaseErrorApp extends StatelessWidget {
  const _FirebaseErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppStrings.initError,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _initializeApp(),
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}