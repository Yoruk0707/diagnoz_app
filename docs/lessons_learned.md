# DiagnozApp: Lessons Learned & Prevention Guide
**Version:** 1.4
**Created:** February 6, 2026
**Last Updated:** February 19, 2026
**Purpose:** Document critical mistakes, edge cases, and preventive measures
**For:** Claude AI Assistant - READ THIS BEFORE IMPLEMENTING ANY FEATURE

> **âš ï¸ THIS FILE IS YOUR MEMORY**  
> Every mistake here was made during actual development.  
> Reading this FIRST prevents wasting hours on solved problems.

---

## Table of Contents

1. [Firebase Dependency Management](#1-firebase-dependency-management)
2. [Version Number Typo Risks](#2-version-number-typo-risks)
3. [Security: debugPrint() Stack Trace Leaks](#3-security-debugprint-stack-trace-leaks)
4. [Global Crash Handling](#4-global-crash-handling)
5. [Three-AI Validation Workflow](#5-three-ai-validation-workflow)
6. [Over-Engineering Score Interpretation](#6-over-engineering-score-interpretation)
7. [ADHD-Friendly Development Workflow](#7-adhd-friendly-development-workflow)
8. [Firebase Initialization Edge Cases](#8-firebase-initialization-edge-cases)
9. [String Management for Localization](#9-string-management-for-localization)
10. [Crashlytics Initialization Order](#10-crashlytics-initialization-order)
11. [Crashlytics Web Platform Incompatibility](#11-crashlytics-web-platform-incompatibility)
12. [Zone Mismatch: ensureInitialized Placement](#12-zone-mismatch-ensureinitialized-placement)
13. [Material 3 Type Name Changes](#13-material-3-type-name-changes)
14. [Missing Factory Constructor â€” Compile Error at Runtime](#14-missing-factory-constructor--compile-error-at-runtime)
15. [Interface Return Type Mismatch â€” void vs String](#15-interface-return-type-mismatch--void-vs-string)
16. [AI Review Workflow â€” When to Skip GLM](#16-ai-review-workflow--when-to-skip-glm)
17. [AI Design Tools (Stitch) â€” Flutter Projeleri Icin Uygun Degil](#17-ai-design-tools-stitch--flutter-projeleri-icin-uygun-degil)
18. [Prevention Checklists Summary](#18-prevention-checklists-summary)
19. [Old Skeleton Files â€” Session Start Audit Required](#19-old-skeleton-files--session-start-audit-required)
20. [GitHub Raw Links â€” Claude File Access Pattern](#20-github-raw-links--claude-file-access-pattern)
21. [TextEditingController in Riverpod Timer â€” ConsumerStatefulWidget Required](#21-texteditingcontroller-in-riverpod-timer--consumerstatefulwidget-required)
22. [Codex Prompt Format â€” Terminal vs Chat Distinction](#22-codex-prompt-format--terminal-vs-chat-distinction)
23. [Mock Data Const Propagation â€” static const vs static final](#23-mock-data-const-propagation--static-const-vs-static-final)
24. [Sprint 4 Firestore Batch Write â€” Lessons & Known Issues](#24-sprint-4-firestore-batch-write--lessons--known-issues)

---

## 1. Firebase Dependency Management

### Problem Encountered

```
DEPENDENCY CONFLICT:
- firebase_performance >=0.11.1+1 depends on firebase_core_platform_interface ^6.0.2
- firebase_analytics >=11.5.1 depends on firebase_core_platform_interface ^5.4.1
- INCOMPATIBLE
```

### Root Cause

Mixing Firebase packages from **different BoM (Bill of Materials) releases**. FlutterFire publishes coordinated releases where all packages share compatible platform_interface versions. Using packages from different releases causes conflicts.

### Failed Attempts (DO NOT USE)

```yaml
# FAILED SET 1 - Old packages with Flutter 3.38.7
firebase_core: 2.27.1        # 22 months old, JS interop broken
firebase_auth: 4.17.9
cloud_firestore: 4.15.9
# Error: Type 'PromiseJsImpl' not found

# FAILED SET 2 - Mixed major versions
firebase_core: 4.3.0
firebase_analytics: 11.5.1   # Requires platform_interface ^5.4.1
firebase_performance: 0.11.1+3  # Requires platform_interface ^6.0.2
# Error: Dependency conflict

# FAILED SET 3 - Performance version mismatch
firebase_performance: 0.10.1+1  # Requires firebase_core ^3.10.1
firebase_core: 4.3.0
# Error: Version solving failed
```

### Working Configuration (BoM 4.7.0 - December 2025)

```yaml
# WORKING SET - All packages from same BoM release
dependencies:
  firebase_core: 4.3.0
  firebase_auth: 6.1.3
  cloud_firestore: 6.1.1
  cloud_functions: 6.0.5
  firebase_crashlytics: 5.0.6
  firebase_analytics: 12.1.0
  firebase_performance: 0.11.1+3
# All use firebase_core_platform_interface: ^6.0.2
```

### Prevention Checklist

```
- Check pub.dev for BoM compatibility matrix before adding packages
- Use EXACT versions (4.3.0) not ranges (^4.3.0 or >=4.3.0)
- All firebase_* packages must share same platform_interface version
- Run flutter pub get after EACH dependency change
- If conflict: Find BoM release that coordinates ALL packages
- Check FlutterFire GitHub VERSIONS.md for coordinated releases
- When upgrading ONE firebase package: upgrade ALL to same BoM
```

### Quick Reference: BoM 4.7.0 Versions

| Package | Version | Platform Interface |
|---------|---------|-------------------|
| firebase_core | 4.3.0 | ^6.0.2 |
| firebase_auth | 6.1.3 | ^6.0.2 |
| cloud_firestore | 6.1.1 | ^6.0.2 |
| cloud_functions | 6.0.5 | ^6.0.2 |
| firebase_crashlytics | 5.0.6 | ^6.0.2 |
| firebase_analytics | 12.1.0 | ^6.0.2 |
| firebase_performance | 0.11.1+3 | ^6.0.2 |

---

## 2. Version Number Typo Risks

### Problem Encountered

```yaml
# Typo: Extra digit inserted
firebase_analytics: 112.1.0  # Should be 12.1.0
# Error: Version 112.1.0 doesn't exist
# Debugging time wasted: 15+ minutes
```

### Impact

- flutter pub get fails with cryptic "version not found" error
- User may think it's a compatibility issue (not typo)
- Debugging spirals into wrong direction

### Prevention Checklist

```
- COPY-PASTE versions from verified sources (pub.dev, VERSIONS.md)
- Use find-replace CAREFULLY (avoid accidental digit insertion)
- Verify major.minor.patch format (max 3 segments + optional build)
- Valid: 12.1.0, 0.11.1+3
- Invalid: 112.1.0, 1.2.3.4, 12..1.0
- Double-check pubspec.yaml after ANY edit
- Read error message carefully: "version X doesn't exist" = likely typo
```

---

## 3. Security: debugPrint() Stack Trace Leaks

### Problem Encountered

```dart
// INSECURE - Leaks internal details in production
try {
  await Firebase.initializeApp();
} catch (e) {
  debugPrint('Firebase error: $e');  // Exposes stack trace in Logcat
}
```

### Impact

- Logcat/Console exposes: file paths, class names, line numbers
- Crash reports expose: backend endpoints, config structure
- Security Risk: Attackers can reconstruct architecture

### Solution: Structured Error Logging

```dart
// SECURE - Release-safe error logging
void _logError(String code, Object error, StackTrace stack) {
  if (kDebugMode) {
    debugPrint('[$code] $error\n$stack');
    return;
  }
  debugPrint('[$code] Hata olustu. Detaylar Crashlytics\'e gonderildi.');
  try {
    FirebaseCrashlytics.instance.recordError(error, stack, reason: code);
  } catch (_) {}
}
```

### Prevention Checklist

```
- NEVER use debugPrint('$e') or debugPrint('$error') in catch blocks
- ALWAYS use error code wrapper (_logError pattern)
- Check kDebugMode before exposing internal details
- Send structured logs to Crashlytics in production
- NEVER log: tokens, passwords, user data, API keys, internal paths
```

---

## 4. Global Crash Handling

### Problem Encountered

```dart
// INCOMPLETE - Async errors disappear silently
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
// If Future throws after this point: no crash report
```

### Solution: Complete Crash Capture

```dart
void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await _initializeApp();
    },
    (error, stack) {
      _logError('unhandled_async_error', error, stack);
    },
  );
}
```

### Prevention Checklist

```
- ALWAYS wrap main() content with runZonedGuarded
- ensureInitialized() INSIDE runZonedGuarded (bkz. S12)
- Set FlutterError.onError AFTER Firebase/Crashlytics init
- Crashlytics calls guarded with kIsWeb check (bkz. S11)
- Test crash reporting in RELEASE mode before production
```

---

## 5. Three-AI Validation Workflow

### Purpose

Systematic security + quality review for critical code paths.

### Workflow Sequence

```
1. Opus (Generate)     - Initial implementation
2. Seneca (Security)   - Security audit (score X/10)
3. GLM-4 (Quality)     - Over-engineering check (score X/10)
4. Opus (Revise)       - Apply feedback, create v2.0
5. GLM-4 (Validate)    - Final approval or additional feedback
```

### Results from main.dart Session

| Metric | v1.0 | v2.0 |
|--------|------|------|
| Security Score (Seneca) | 7.0/10 | 9.5/10 |
| Over-Engineering (GLM-4) | 2/10 | 2/10 |
| Critical Issues | 2 | 0 |
| Warnings | 2 | 0 |

### When to Use

```
USE THREE-AI VALIDATION FOR:
- Entry points (main.dart, router, theme)
- Security-critical screens (auth, OTP, payment, profile)
- Backend validation logic (score calculation, leaderboard, timer)
- Data persistence (Firestore writes, local storage encryption)
- API communication (token handling, request/response)

NOT NEEDED FOR:
- Simple UI widgets (buttons, cards, layouts)
- Styling changes (colors, spacing, fonts)
- Static content screens (about, help, FAQ)
- Internal utilities with no user data
```

### Time Cost

- Extra 20-30 minutes per critical feature
- ROI: Catches security holes BEFORE production

---

## 6. Over-Engineering Score Interpretation

### Common Misconception

```
WRONG: "2/10 over-engineering = bad quality code"
CORRECT: "2/10 over-engineering = minimal bloat, excellent for MVP"
```

### Scale Explanation

```
10/10 = Asiri karmasik - Enterprise patterns for a simple app
 8/10 = Repository pattern for static config
 6/10 = Extra layers "for future flexibility"
 4/10 = Some premature optimization
 2/10 = Lean, only what's needed - EXCELLENT
 1/10 = Bare minimum (potentially too minimal)
```

### Prevention Checklist

```
- Understand: LOWER score = BETTER for MVP
- Don't add "nice to have" abstractions
- YAGNI principle: You Ain't Gonna Need It
- Target score: 2-4/10 for MVP phase
```

---

## 7. ADHD-Friendly Development Workflow

### User Preference

- Step-by-step, clear outcomes
- No overwhelming complexity
- One command at a time
- Visual confirmation (screenshots)

### Effective Patterns

```
GOOD:
"Run this command:
flutter clean
Expected: Build cache cleared, 'Cleaning build...' message."

GOOD:
"Step 1 of 3: Create the file
Step 2 of 3: Add the content
Step 3 of 3: Run and verify"

BAD:
"You need to modify several files. First update pubspec.yaml with these 
15 dependencies, then create 4 new files, configure the router..."
```

### Prevention Checklist

```
- Break tasks into numbered steps
- One command per step
- Expected outcome after each step
- Screenshot confirmation when visual change expected
- If >3 files needed: batch into groups with verification points
```

---

## 8. Firebase Initialization Edge Cases

### Problem Encountered

```dart
// NO RETRY - User stuck on error screen forever
class _FirebaseErrorApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Firebase baslatilamadi')),  // Dead end!
      ),
    );
  }
}
```

### Solution: Retry-Enabled Error Screen

```dart
// WITH RETRY - User can recover
ElevatedButton(
  onPressed: () => _initializeApp(),
  child: const Text(AppStrings.retry),
),
```

### Prevention Checklist

```
- ALWAYS provide retry mechanism on critical init failures
- Test offline mode: Airplane mode -> Launch app -> Should show retry
- Use consistent theming even on error screens (AppTheme.dark)
```

---

## 9. String Management for Localization

### Problem Encountered

Strings scattered across multiple files, duplicated, hard to find and change.

### Solution: Centralized String Constants

```dart
// lib/core/constants/app_strings.dart
abstract class AppStrings {
  static const appTitle = 'DiagnozApp';
  static const home = 'Ana Sayfa';
  static const networkError = 'Baglanti hatasi. Internet baglantinizi kontrol edin.';
}
```

### Prevention Checklist

```
- Create AppStrings class in lib/core/constants/
- Extract ALL user-facing strings
- Keep code/variable names in ENGLISH
- Keep UI strings in TURKISH (target language)
- Future: Replace with l10n/intl when multi-language needed
```

---

## 10. Crashlytics Initialization Order

### Problem Encountered

```dart
// WRONG ORDER - NPE risk
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
// Crashlytics not initialized yet!
await Firebase.initializeApp();
```

### Solution: Correct Initialization Order

```dart
// STEP 1: Firebase FIRST
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// STEP 2: Crashlytics AFTER Firebase, with web guard
if (!kIsWeb) {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
}
```

### Prevention Checklist

```
- Firebase.initializeApp() must come FIRST
- FlutterError.onError set AFTER Firebase init succeeds
- Crashlytics calls wrapped in if (!kIsWeb) guard (bkz. S11)
```

---

## 11. Crashlytics Web Platform Incompatibility

> Added: February 10, 2026 - Sprint 1 Session

### Problem Encountered

```
[firebase_init_failed] Assertion failed:
firebase_crashlytics_platform_interface: 
pluginConstants['isCrashlyticsCollectionEnabled'] != null is not true
```

### Root Cause

Firebase Crashlytics only supports Android and iOS. Calling ANY Crashlytics method on web throws an assertion error.

### Solution: kIsWeb Guard

```dart
if (!kIsWeb) {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
}
```

### Prevention Checklist

```
- EVERY Crashlytics call must be wrapped in if (!kIsWeb)
- _logError helper must also check kIsWeb before Crashlytics calls
- When adding new Firebase services: check platform support matrix first
- Test on web AFTER adding any Firebase service
```

### Firebase Platform Support Quick Reference

| Service | Android | iOS | Web |
|---------|---------|-----|-----|
| Core | Yes | Yes | Yes |
| Auth | Yes | Yes | Yes |
| Firestore | Yes | Yes | Yes |
| Crashlytics | Yes | Yes | NO |
| Analytics | Yes | Yes | Yes |
| Performance | Yes | Yes | Yes |
| Cloud Functions | Yes | Yes | Yes |

---

## 12. Zone Mismatch: ensureInitialized Placement

> Added: February 10, 2026 - Sprint 1 Session

### Problem Encountered

```dart
// WRONG - Zone mismatch
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Zone A
  runZonedGuarded(() async {
    await Firebase.initializeApp();           // Zone B
    runApp(MyApp());                          // Zone B
  }, errorHandler);
}
// ensureInitialized in Zone A, but app runs in Zone B = mismatch
```

### Solution

```dart
void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized(); // Same zone as app
      await _initializeApp();
      runApp(const ProviderScope(child: DiagnozApp()));
    },
    (error, stack) {
      _logError('unhandled_async_error', error, stack);
    },
  );
}
```

### Prevention Checklist

```
- ensureInitialized() MUST be INSIDE runZonedGuarded
- Everything that runs the app must be in the same zone
- Test: Add intentional throw after runApp to verify zone catches it
```

---

## 13. Material 3 Type Name Changes

> Added: February 10, 2026 - Sprint 1 Session

### Problem Encountered

```dart
// OLD (deprecated in Flutter 3.27+)
CardTheme(...)       // Warning: Use CardThemeData instead
TabBarTheme(...)     // Warning: Use TabBarThemeData instead
DialogTheme(...)     // Warning: Use DialogThemeData instead
```

### Solution

```dart
// NEW (Flutter 3.27+)
CardThemeData(...)
TabBarThemeData(...)
DialogThemeData(...)
```

### Prevention Checklist

```
- When using theme components: check Flutter API docs for current name
- Pattern: ComponentTheme -> ComponentThemeData (for most components)
- Run flutter analyze to catch deprecation warnings
- Keep Flutter SDK updated and check migration guides
```

---

## 14. Missing Factory Constructor â€” Compile Error at Runtime

> Added: February 12, 2026 - Sprint 2 Session

### Problem Encountered

```dart
// failures.dart - AuthFailure class'ta EKSIK:
// factory AuthFailure.unknown(String message) YOK!

// firebase_auth_repository.dart - KULLANIYOR:
return Left(AuthFailure.unknown(message));  // COMPILE ERROR!
```

firebase_auth_repository.dart ve verify_sms_code.dart dosyalari AuthFailure.unknown() kullaniyor, ama failures.dart'ta bu factory tanimli degildi.

### Root Cause

Data layer ve use case'ler Codex tarafindan yazilirken AuthFailure.unknown(message) factory'si kullanildi. Ancak domain layer'daki failures.dart baska bir oturumda yazilmisti ve unknown factory eklenmemisti. **flutter analyze bunu yakalamadi** cunku dosyalar ayri ayri analiz ediliyor - cross-file type resolution sadece flutter run veya flutter build sirasinda yapiliyor.

### Solution

```dart
// failures.dart - AuthFailure class'ina eklendi:
factory AuthFailure.unknown(String message) => AuthFailure(
      message,
      code: 'unknown',
    );
```

### Prevention Checklist

```
- Yeni bir Failure subclass factory kullanirken: failures.dart'ta tanimli mi kontrol et
- flutter analyze YETERLI DEGIL cross-file type check icin
- Batch'lar arasi bagimlilik varsa: flutter run ile dogrula (sadece analyze yetmez)
- Data layer yazarken: domain layer'daki interface ve Failure class'larini ONCE kontrol et
- Codex'e dosya yazdirirken: kullandigi tum type'larin import edilebilir oldugunu belirt
```

---

## 15. Interface Return Type Mismatch - void vs String

> Added: February 12, 2026 - Sprint 2 Session

### Problem Encountered

```dart
// auth_repository.dart (interface) - Batch 1'de yazildi:
Future<Either<Failure, void>> sendVerificationCode(String phoneNumber);

// firebase_auth_repository.dart (implementation) - Batch 2'de yazildi:
Future<Either<Failure, String>> sendVerificationCode(String phoneNumber) {
  // String = verificationId (OTP dogrulama icin gerekli)
}
```

Interface void donerken implementation String (verificationId) donuyordu.

### Root Cause

Domain layer (Batch 1) yazilirken auth akisinin tamami dusunulmemisti. sendVerificationCode'un verificationId dondurmesi gerektigi ancak data layer (Batch 2) yazilirken fark edildi.

### Solution

```dart
// Interface guncellendi:
Future<Either<Failure, String>> sendVerificationCode(String phoneNumber);
```

### Prevention Checklist

```
- Domain layer interface yazarken: tum akisi (data + presentation) dusun
- Return type'lar: "Bu veriyi sonraki adim kullanacak mi?" sorusunu sor
- Auth akisi: verificationId MUTLAKA geri donmeli (OTP dogrulama icin)
- Interface ve implementation her zaman ayni return type'a sahip olmali
- Batch 1 (domain) yazarken: Batch 2-3-4'un neye ihtiyac duyacagini planla
- Clean Architecture'da interface degisikligi: tum katmanlari etkiler
```

---

## 16. AI Review Workflow - When to Skip GLM

> Added: February 12, 2026 - Sprint 2 Session

### Lesson Learned

Sprint 2 Batch 2 fix'leri sonrasinda GLM (architecture review) yapilip yapilmayacagi sorgulandi. Karar: Gereksiz.

### When Three-AI Review is Needed

```
- Yeni feature: mimari kararlar iceriyor
- Data layer: Firebase cagrilari, guvenlik
- Router/navigation: uygulama akisini etkiliyor
- Yeni Failure/Entity/UseCase: domain model degisikligi
```

### When to Skip Extra Review

```
- Targeted fix'ler (typo, missing factory, type correction)
- State management (guvenlik karari almiyor)
- UI ekranlari (presentation layer, guvenlik yok)
- Router guncelleme (mevcut yapiya ekleme)
```

### Practical Review Matrix

| Batch Type | Codex | Senaca | GLM | flutter analyze |
|------------|-------|--------|-----|-----------------|
| Domain layer (yeni) | Yes | No | No | Yes |
| Data layer (Firebase) | Yes | Yes | No | Yes |
| Data layer fix'leri | No | No | No | Yes |
| State management | No | No | No | Yes |
| UI ekranlari | No | No | No | Yes |
| Router degisikligi | No | No | No | Yes |
| Sprint sonu toplu | No | Yes | Yes | Yes |

### Prevention Checklist

```
- Her dosya icin review: OVERKILL, zaman kaybi
- Guvenlik-kritik dosyalar: Senaca MUTLAKA
- Mimari kararlar: GLM gerekebilir
- Fix'ler: sadece flutter analyze yeterli
- Sprint sonu: toplu review daha verimli
```

---

## 17. AI Design Tools (Stitch) - Flutter Projeleri Icin Uygun Degil

> Added: February 12, 2026 - Sprint 2 Session

### Lesson Learned

Google Stitch (AI UI design tool) DiagnozApp icin degerlendirildi. Karar: Kullanma.

### Reasons

```
1. OUTPUT FORMAT UYUMSUZ:
   Stitch: HTML/CSS cikti verir
   DiagnozApp: Flutter/Dart gerektirir
   Donusum adimi = ekstra is, hata riski

2. ZAMANLAMA YANLIS:
   Stitch: proje basinda design ideation icin
   Sprint 2: ekranlar zaten ui_ux_design_clean.md'de tanimli
   Basit ekranlar (phone input, OTP): direkt Flutter yazmak daha hizli

3. SINIRLILIKLAR:
   2-3 ekrandan fazlasi tutarsiz
   Brand guidelines otomatik uygulanmiyor
   Animasyon/interaction destegi yok
```

### When It COULD Be Useful

```
- Sprint 3-4'te karmasik ekranlar tasarlarken (game screen, leaderboard)
- Sadece MOCKUP/REFERANS GORSEL olarak
- Kodu DEGIL, sadece visual'i alirsin
- Figma export: referans olarak kullan
```

### Prevention Checklist

```
- Flutter projesinde AI design tool: sadece gorsel referans icin
- Kod ciktisini direkt kullanma (HTML != Flutter)
- Mevcut design doc varsa (ui_ux_design_clean.md): direkt implement et
- Basit ekranlar icin AI design tool gereksiz overhead
```

---

## 18. Prevention Checklists Summary

### Before ANY Feature Implementation

**1. Read Documentation First:**
```
- Read lessons_learned.md (this file) - check for relevant mistakes
- Read vcguide.md - check for edge cases
- Read vcsecurity.md - check for security requirements
- Check if feature touches: timer, score, leaderboard, auth (extra caution)
```

**2. Dependency Changes:**
```
- Using coordinated BoM release?
- All firebase_* packages share same platform_interface version?
- Version numbers correct format (no typos)?
- Run flutter pub get immediately after change?
```

**3. Error Handling:**
```
- Using _logError wrapper (not raw debugPrint)?
- runZonedGuarded present in main()?
- ensureInitialized INSIDE runZonedGuarded? (bkz. S12)
- FlutterError.onError set after Crashlytics init?
- Crashlytics calls guarded with kIsWeb? (bkz. S11)
- Retry mechanism on network failures?
```

**4. Security:**
```
- Backend validation for critical data?
- No stack traces in production logs?
- Rate limiting on expensive operations?
- Input validation present?
```

**5. Code Quality:**
```
- Over-engineering score acceptable (2-4/10)?
- YAGNI principle followed?
- Strings extracted to constants?
- NEDEN comments for non-obvious logic?
```

**6. User Experience:**
```
- Loading states shown?
- Error messages user-friendly (Turkish)?
- Retry mechanism on failures?
- Consistent theming (AppTheme.dark)?
```

**7. Platform Compatibility:**
```
- Does the Firebase service support web? (bkz. S11)
- Theme types using current names? (bkz. S13)
- Zone placement correct? (bkz. S12)
```

**8. Critical Features (Three-AI Validation):**
```
- Is this security-critical? (auth, payment, user data)
- Is this an entry point? (main.dart, router)
- If yes: Use three-ai workflow before finalizing
```

**9. Cross-File Consistency (Sprint 2):**
```
- Domain interface return types match implementation? (bkz. S15)
- All Failure factories used in code exist in failures.dart? (bkz. S14)
- flutter run ile dogrula - flutter analyze cross-file hatalari yakalamaz
- Batch'lar arasi bagimliliklari kontrol et
```

**10. Game State Management (Sprint 3):**
```
- Timer + TextInput ayni ekranda? ConsumerStatefulWidget kullan (bkz. S21)
- TextEditingController state'de mi? dispose() var mi?
- Mock data const propagation dogru mu? (bkz. S23)
- Eski iskelet dosyalar temizlendi mi? (bkz. S19)
```

---

## 19. Old Skeleton Files - Session Start Audit Required

> Added: February 16, 2026 - Sprint 3 Session

### Lesson Learned

Sprint 3 basinda flutter analyze 640 warning verdi â€” eski projeden kalan bos iskelet dosyalar (case.dart, game_state.dart, game_repository.dart, game_state_provider.dart, timer_provider.dart). Sadece doc comment iceriyordu, gercek kod yoktu. project_status.md bunlardan bahsetmiyordu.

### Root Cause

```
- Proje yeniden olusturuldugunda eski dosyalar temizlenmemis
- project_status.md dosya listesi guncel degildi
- Claude'un lib/ dizinine dogrudan erisimi yok
```

### Prevention Checklist

```
- Her sprint basinda: find lib -name "*.dart" | sort
- project_status.md dosya yapisini guncel tut
- Yeni sprint oncesi: flutter analyze tam proje
- Eski iskelet dosyalari hemen sil, "sonra yaparim" deme
```

---

## 20. GitHub Raw Links - Claude File Access Pattern

> Added: February 16, 2026 - Sprint 3 Session

### Lesson Learned

Claude'un lib/ dizinine dogrudan erisimi yok (sadece ai_workspace/ erisilebilir). GitHub raw linkleri ile dosya okuma calisiyor.

### Working Pattern

```
# Dosya okuma (kullanici yapistirir, Claude web_fetch eder):
https://raw.githubusercontent.com/Yoruk0707/diagnoz_app/main/lib/path/to/file.dart

# Dizin listesi (GitHub API):
https://api.github.com/repos/Yoruk0707/diagnoz_app/contents/lib/features/game/

# ONEMLI: Her link kullanici tarafindan yapistirilmali
# Claude kendi basina URL construct edip fetch edemez (guvenlik kisitlamasi)
```

### What Does NOT Work

```
- Claude'un API response'undaki URL'leri takip etmesi -> PERMISSIONS_ERROR
- Claude'un kendisi URL olusturup fetch etmesi -> PERMISSIONS_ERROR
- Cok yeni push'lar -> API cache, birkac dakika bekle
```

### Alternative (Always Works)

```bash
# Terminalde:
cat lib/path/to/file.dart
find lib -name "*.dart" | sort
```

---

## 21. TextEditingController in Riverpod Timer â€” ConsumerStatefulWidget Required

> Added: February 16, 2026 - Sprint 3 Session

### Lesson Learned

ConsumerWidget icinde TextEditingController olusturulursa, her state rebuild'de (timer her saniye tetikler) controller sifirlanir. Kullanici yazi yazamaz â€” her karakter silinir.

### Wrong

```dart
class GameScreen extends ConsumerWidget {
  Widget _buildDiagnosisInput() {
    final controller = TextEditingController(); // HER REBUILD'DE SIFIRLANIR!
    return TextField(controller: controller);
  }
}
```

### Correct

```dart
class GameScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final _controller = TextEditingController(); // STATE'DE KALICI

  @override
  void dispose() {
    _controller.dispose(); // MEMORY LEAK ONLEME
    super.dispose();
  }
}
```

### Prevention Checklist

```
- Timer + TextInput ayni ekranda -> MUTLAKA ConsumerStatefulWidget
- TextEditingController her zaman state'de tanimla
- dispose() icinde controller.dispose() unutma
- ConsumerWidget: sadece input olmayan ekranlar icin
```

---

## 22. Codex Prompt Format â€” Terminal vs Chat Distinction

> Added: February 16, 2026 - Sprint 3 Session

### Lesson Learned

Claude'un verdigi Codex prompt'u terminale yapistirildi â€” zsh hata verdi cunku dogal dil komutlari terminal komutu degil.

### Prevention Checklist

```
- Codex prompt'u verirken acikca belirt: "Bu Codex'e ver" 
- Terminal komutu verirken acikca belirt: "Bu terminale yaz"
- Prompt icinde terminal komutu varsa ayri blokta goster
- Kullaniciya "nereye yapistir" her zaman soyle
```

---

## 23. Mock Data Const Propagation â€” static const vs static final

> Added: February 16, 2026 - Sprint 3 Session

### Lesson Learned

`static final _case = const MedicalCase(...)` yazildiginda, icerideki her nested const keyword'u "unnecessary_const" uyarisi verir. Cunku const ust seviyeden propagate eder.

### Correct Pattern

```dart
// const ust seviyede -> iceride const gereksiz
static const _case1 = MedicalCase(
  patientProfile: PatientProfile(...),  // const yazma
  vitals: Vitals(...),                   // const yazma
  availableTests: [                      // const yazma
    TestResult(...),                     // const yazma
  ],
);
```

### Wrong Pattern

```dart
// final + const -> ic ice const uyarilari
static final _case1 = const MedicalCase(
  patientProfile: const PatientProfile(...),  // UNNECESSARY_CONST!
  vitals: const Vitals(...),                   // UNNECESSARY_CONST!
);
```

---

## 24. Sprint 4 Firestore Batch Write - Lessons & Known Issues

> Added: February 19, 2026 - Sprint 4 Session

### Lessons Learned

Sprint 4'te submitGame batch write (4 koleksiyon: games, users, leaderboard_weekly, leaderboard_monthly) calismasi icin 6 ayri bug fix gerekti. Her biri farkli katmanda sessizce basarisiz oluyordu.

### Bug 1: batch.update() on Non-Existent User Doc

```dart
// WRONG - User doc yoksa NOT_FOUND, tum batch fail olur
batch.update(userRef, {'stats.totalGamesPlayed': FieldValue.increment(1)});

// CORRECT - Doc yoksa olusturur, varsa merge eder
batch.set(userRef, {'stats': {...}}, SetOptions(merge: true));
```

### Bug 2: set() Dot Notation != Nested Path

```dart
// WRONG - set() dot'u literal alan adi olarak yazar, rules fail eder
batch.set(userRef, {'stats.totalGamesPlayed': FieldValue.increment(1)}, SetOptions(merge: true));
// request.resource.data.keys() = ['stats.totalGamesPlayed'] -> allowlist'te YOK

// CORRECT - Nested map + merge:true = deep merge
batch.set(userRef, {'stats': {'totalGamesPlayed': FieldValue.increment(1)}}, SetOptions(merge: true));
// request.resource.data.keys() = ['stats'] -> allowlist'te VAR
```

**KRITIK FARK:** `update()` dot notation'i nested path olarak yorumlar. `set()` literal alan adi olarak yazar.

### Bug 3: mergeFields + FieldPath + FieldValue.increment = Web SDK Uyumsuzlugu

```dart
// WRONG - Web SDK'da sessizce hang eder
SetOptions(mergeFields: [FieldPath(const ['stats', 'totalGamesPlayed'])])

// CORRECT - merge:true her platformda calisir
SetOptions(merge: true)
```

### Bug 4: ISO 8601 Week Number - Write/Read Mismatch

```dart
// WRONG - Farkli algoritma, farkli sonuc (7 vs 8)
// Datasource (write): ((dayOfYear - weekday + 10) / 7).floor()
// Repository (read): Thursday-based ISO 8601

// CORRECT - Shared utility, tek kaynak
// lib/core/utils/date_utils.dart
int getIsoWeekNumber(DateTime date) {
  final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
  final jan1 = DateTime(thursday.year, 1, 1);
  return (thursday.difference(jan1).inDays / 7).floor() + 1;
}
```

### Bug 5: Firestore Security Rules - Field Allowlist Mismatch

Batch write'daki field'lar rules'taki `hasOnly()` listesiyle birebir eslesmeli. Ozellikle:
- `isValidUserFields()` icinde `stats` olmali (nested stats objesi icin)
- `isValidGameFields()` icinde `casesCompleted`, `totalCases`, `cases`, `passesLeft` olmali
- Leaderboard create VE update izni olmali (ilk oyun create, sonrakiler update)

### Known Issue: Leaderboard Tab Refresh

**Durum:** Siralama tab'ina tiklaninca veri gelmiyor, sayfa yenilenince geliyor.
**Muhtemel sebep:** `weeklyLeaderboardProvider` ve `monthlyLeaderboardProvider` `FutureProvider.autoDispose` kullanir. Tab degisiminde provider invalidate edilmiyor — `ref.invalidate()` veya `ref.refresh()` eksik.
**Oncelik:** Sprint 4 sonrasi duzeltilecek (Sprint 5 backlog).

### Prevention Checklist

```
- Firestore batch write: HER ZAMAN try-catch ile sar, success/error logla
- batch.update() KULLANMA — batch.set() + merge:true kullan (doc olmayabilir)
- set() icinde dot notation KULLANMA — nested map kullan
- mergeFields KULLANMA web'de — merge:true kullan
- Ayni hesaplama birden fazla yerde varsa: shared utility'ye tasi (DRY)
- Security rules field allowlist: batch write'daki tum field'lari icermeli
- Leaderboard write: hem create hem update izni olmali
- Debug sirasinda: her katmana (notifier, usecase, repo, datasource) debugPrint ekle
```

---

## Usage Instructions for Claude

### BEFORE Implementing ANYTHING:

1. Read this file completely
2. Check relevant prevention checklists
3. Verify you're not repeating past mistakes
4. Reference specific section if proposing risky pattern

### Example Workflow:

```
User: "Add timer countdown widget"

Claude's Internal Process:
1. [Read lessons_learned.md]
   - Check S21: TextEditingController + timer = ConsumerStatefulWidget
   - Check S11: does timer use any web-incompatible services?
   - Check S12: zone placement correct?
   - Check S14: any missing factories needed?
   
2. [Read vcguide.md Timer System]
   - Client timer = UI only
   - Server validates actual time
   - Must cleanup in dispose()
   
3. [Check security patterns]
   - Timer manipulation = cheating risk
   - Need server-side validation
   
4. [Propose solution]
   - Include dispose() cleanup
   - Include server validation note
   - Add NEDEN comments
   
5. [After implementation]
   - Update lessons_learned.md with timer-specific learnings
```

### When to Update This File:

```
- After discovering a new edge case
- After a bug that took >30 minutes to diagnose
- After receiving security/quality feedback
- After a "gotcha" moment worth documenting
- After any production incident
```

---

## Document Metadata

| Field | Value |
|-------|-------|
| File Path | Project Knowledge |
| Version | 1.4 |
| Created | February 6, 2026 |
| Last Updated | February 19, 2026 |
| Sessions | Firebase config, main.dart security, Sprint 1, Sprint 2 auth, Sprint 3 game loop, Sprint 4 Firebase integration |
| New in v1.4 | S24 Firestore batch write lessons (6 bugs), leaderboard tab refresh known issue |

---

END OF DOCUMENT

"The best time to document a mistake is right after making it.
The second best time is before repeating it."
