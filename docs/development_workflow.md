# DiagnozApp: Development Workflow
**Version:** 1.1  
**Last Updated:** January 30, 2026  
**For:** Development team, DevOps, QA  
**Purpose:** Testing, deployment, and monitoring standards

> **This document defines HOW we develop, test, and deploy DiagnozApp.**  
> **For code standards:** See `vcguide.md`  
> **For security:** See `vcsecurity.md`

---

## Table of Contents

1. [Testing Strategy](#1-testing-strategy)
2. [Code Quality Standards](#2-code-quality-standards)
3. [CI/CD Pipeline](#3-cicd-pipeline)
4. [Platform Support](#4-platform-support)
5. [Monitoring & Analytics](#5-monitoring--analytics)
6. [Deployment Process](#6-deployment-process)
7. [Version Management](#7-version-management)

---

## 1. Testing Strategy

### Test Coverage Requirements

**Mandatory minimum coverage: 80%**

```dart
// Run coverage check
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

// Minimum thresholds:
// - Overall: 80%
// - Critical paths (timer, score, auth): 95%
// - UI widgets: 60%
```

---

### 1.1 Unit Tests

**What to test:**
- Business logic (usecases, repositories)
- State management (Riverpod providers)
- Utility functions (score calculation, time validation)
- Data models (toJson, fromJson)

**Example structure:**
```dart
test/
  core/
    utils/
      score_calculator_test.dart
      time_validator_test.dart
  features/
    game/
      domain/
        usecases/
          calculate_score_usecase_test.dart
          submit_diagnosis_usecase_test.dart
      data/
        repositories/
          game_repository_test.dart
```

**Mandatory tests (from vcguide.md):**

```dart
// Timer edge cases
test('Timer cannot go negative', () {
  final calculator = ScoreCalculator();
  expect(calculator.calculate(-10), 0.0);
});

test('Timer validates max value', () {
  final calculator = ScoreCalculator();
  expect(calculator.calculate(999), 0.0);
});

// Race condition tests
test('Concurrent score updates preserve data', () async {
  await Future.wait([
    updateScore(userId, 50.0),
    updateScore(userId, 80.0),
  ]);
  
  final score = await getScore(userId);
  expect(score, 130.0);  // Not lost!
});

// Duplicate submission
test('Form prevents duplicate submit', () async {
  await submitDiagnosis(gameId, 'MI');
  
  expect(
    () => submitDiagnosis(gameId, 'MI'),
    throwsA(isA<AlreadySubmittedException>()),
  );
});
```

**Run command:**
```bash
flutter test test/
```

---

### 1.2 Widget Tests

**What to test:**
- User interactions (button taps, form inputs)
- State changes (timer countdown, score display)
- Navigation flows (screen transitions)
- Error states (no internet, validation errors)

**Critical widgets requiring tests:**
- Timer widget (memory leak check)
- Diagnosis submit button (double-tap prevention)
- Leaderboard list (scroll performance)
- Auth form (validation feedback)

**Example:**
```dart
testWidgets('Timer disposes properly on unmount', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: GameScreen()),
  );
  
  // Verify timer starts
  expect(find.text('120'), findsOneWidget);
  
  // Unmount
  await tester.pumpWidget(Container());
  
  // Verify no memory leak
  expect(tester.binding.timers.length, 0);
});

testWidgets('Submit button disables after tap', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: DiagnosisForm()),
  );
  
  final button = find.byType(ElevatedButton);
  
  // Tap once
  await tester.tap(button);
  await tester.pump();
  
  // Verify disabled
  expect(
    tester.widget<ElevatedButton>(button).onPressed,
    isNull,
  );
});
```

**Run command:**
```bash
flutter test test/ --tags widget
```

---

### 1.3 Integration Tests (E2E)

**Critical flows to test:**
1. **Complete Rush Mode Game:**
   - Auth Ã¢â€ â€™ Game start Ã¢â€ â€™ 5 cases Ã¢â€ â€™ Score Ã¢â€ â€™ Leaderboard

2. **SMS Authentication:**
   - Phone input Ã¢â€ â€™ Code send Ã¢â€ â€™ Verification Ã¢â€ â€™ Home screen

3. **Offline Mode:**
   - Disconnect internet Ã¢â€ â€™ Load cached cases Ã¢â€ â€™ Play game Ã¢â€ â€™ Reconnect Ã¢â€ â€™ Sync score

**Example:**
```dart
// integration_test/rush_mode_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Complete Rush Mode flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Auth
    await tester.enterText(find.byType(TextField), '+905551234567');
    await tester.tap(find.text('Send Code'));
    await tester.pumpAndSettle();
    
    // Verify code (use test number)
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    
    // Start game
    await tester.tap(find.text('Play Rush Mode'));
    await tester.pumpAndSettle();
    
    // Complete 5 cases
    for (int i = 0; i < 5; i++) {
      // Select diagnosis
      await tester.tap(find.text('Myocardial Infarction'));
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
    }
    
    // Verify score submission
    expect(find.text('Game Complete'), findsOneWidget);
    expect(find.byType(LeaderboardScreen), findsOneWidget);
  });
}
```

**Run command:**
```bash
flutter test integration_test/
```

---

## 2. Code Quality Standards

### 2.1 Linter Rules

**Configuration:** `analysis_options.yaml`

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    missing_required_param: error
    missing_return: error
    todo: ignore
    
linter:
  rules:
    # Style
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - unnecessary_const
    
    # Errors
    - avoid_print
    - avoid_returning_null_for_void
    - cancel_subscriptions
    - close_sinks
    
    # Performance
    - prefer_final_fields
    - prefer_final_locals
```

**Run command:**
```bash
flutter analyze --fatal-infos
```

**Pre-commit requirement:** Zero warnings/errors

---

### 2.2 Code Formatter

**Standard:** `dart format`

**Configuration:** `.editorconfig` (optional)
```
[*.dart]
indent_size = 2
max_line_length = 80
```

**Run command:**
```bash
# Check formatting
dart format --set-exit-if-changed .

# Auto-format
dart format .
```

**IDE setup:**
- Format on save (enabled)
- Line length: 80 characters
- Trailing commas: Enabled

---

### 2.3 Git Hooks

**Pre-commit hook:** `.git/hooks/pre-commit`

```bash
#!/bin/bash

echo "Running pre-commit checks..."

# Format check
dart format --set-exit-if-changed .
if [ $? -ne 0 ]; then
  echo "Ã¢ÂÅ’ Code not formatted. Run: dart format ."
  exit 1
fi

# Lint
flutter analyze --fatal-infos
if [ $? -ne 0 ]; then
  echo "Ã¢ÂÅ’ Linter errors found"
  exit 1
fi

# Unit tests
flutter test
if [ $? -ne 0 ]; then
  echo "Ã¢ÂÅ’ Tests failed"
  exit 1
fi

echo "Ã¢Å“â€¦ All checks passed!"
```

**Install:**
```bash
chmod +x .git/hooks/pre-commit
```

---

## 3. CI/CD Pipeline

### 3.1 GitHub Actions Workflow

**File:** `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        channel: 'stable'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run analyzer
      run: flutter analyze --fatal-infos
    
    - name: Check formatting
      run: dart format --set-exit-if-changed .
    
    - name: Run tests
      run: flutter test --coverage
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: coverage/lcov.info
```

---

### 3.2 Automated Deployment

**File:** `.github/workflows/deploy.yml`

```yaml
name: Deploy

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  deploy-ios:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
    
    - name: Build iOS
      run: flutter build ios --release --no-codesign
    
    - name: Deploy to TestFlight
      uses: apple-actions/upload-testflight-build@v1
      with:
        app-path: 'build/ios/ipa/*.ipa'
        issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
        api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
        api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
  
  deploy-android:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
    
    - name: Build Android
      run: flutter build appbundle --release
    
    - name: Deploy to Play Console
      uses: r0adkll/upload-google-play@v1
      with:
        serviceAccountJsonPlainText: ${{ secrets.SERVICE_ACCOUNT_JSON }}
        packageName: com.diagnozapp.app
        releaseFiles: build/app/outputs/bundle/release/*.aab
        track: beta
```

---

## 4. Platform Support

### 4.1 iOS

**Minimum version:** iOS 14.0  
**Target version:** iOS 17.0  
**Test devices:**
- iPhone SE (2nd gen) - minimum
- iPhone 13 Pro - target
- iPad Air (4th gen) - tablet support

**Required capabilities:**
- Dark mode support
- Dynamic Type (accessibility)
- Landscape orientation (game screen)
- Background fetch (score sync)

**Info.plist requirements:**
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Upload profile photo</string>

<key>UIUserInterfaceStyle</key>
<string>Automatic</string>
```

---

### 4.2 Android

**Minimum SDK:** 26 (Android 8.0)  
**Target SDK:** 34 (Android 14)  
**Test devices:**
- Pixel 4a - minimum
- Pixel 7 - target
- Samsung Galaxy Tab S8 - tablet support

**Required permissions:**
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECEIVE_SMS" />
```

**Gradle configuration:**
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 26
        targetSdkVersion 34
    }
}
```

---

### 4.3 Dark Mode

**Implementation:**
```dart
MaterialApp(
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  themeMode: ThemeMode.system,  // Follow system preference
);
```

**Colors must have dark variants:**
```dart
// colors.dart
class AppColors {
  static const primary = Color(0xFF0066CC);
  static const primaryDark = Color(0xFF0055BB);
  
  static const background = Color(0xFFFFFFFF);
  static const backgroundDark = Color(0xFF121212);
}
```

---

## 5. Monitoring & Analytics

### 5.1 Firebase Analytics

**Setup:** Initialize in `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Enable analytics
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  
  runApp(DiagnozApp());
}
```

**Event tracking:**

```dart
// Screen views (automatic)
FirebaseAnalytics.instance.setCurrentScreen(
  screenName: 'game_screen',
);

// Custom events
FirebaseAnalytics.instance.logEvent(
  name: 'game_started',
  parameters: {
    'mode': 'rush',
    'user_level': 'beginner',
  },
);

FirebaseAnalytics.instance.logEvent(
  name: 'case_completed',
  parameters: {
    'case_id': 'case_001',
    'is_correct': true,
    'time_spent': 68,
  },
);

FirebaseAnalytics.instance.logEvent(
  name: 'diagnosis_submitted',
  parameters: {
    'diagnosis': 'Myocardial Infarction',
    'is_correct': true,
    'score': 5.2,
  },
);
```

**Standard events:**
- `game_started` - User starts game
- `game_completed` - User finishes game
- `case_completed` - User completes single case
- `diagnosis_submitted` - User submits diagnosis
- `test_requested` - User requests test
- `pass_used` - User uses pass
- `leaderboard_viewed` - User opens leaderboard

---

### 5.2 Firebase Crashlytics

**Setup:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Enable crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runZonedGuarded(() {
    runApp(DiagnozApp());
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
  });
}
```

**Custom logs:**

```dart
// Log non-fatal errors
try {
  await submitDiagnosis();
} catch (e, stack) {
  FirebaseCrashlytics.instance.recordError(
    e,
    stack,
    reason: 'Diagnosis submission failed',
    fatal: false,
  );
}

// Add custom keys for debugging
FirebaseCrashlytics.instance.setCustomKey('user_id', userId);
FirebaseCrashlytics.instance.setCustomKey('game_mode', 'rush');
```

---

### 5.3 Performance Monitoring

**Track critical operations:**

```dart
// Game load time
final trace = FirebasePerformance.instance.newTrace('game_load');
await trace.start();

await loadGameCases();

trace.setMetric('case_count', 5);
await trace.stop();

// Network requests (automatic with http package)
// Custom metrics
trace.putAttribute('cache_hit', 'true');
```

---

## 6. Deployment Process

### 6.1 Pre-Deployment Checklist

**Before submitting to App Store / Play Store:**

- [ ] Version number incremented (pubspec.yaml)
- [ ] Changelog updated (CHANGELOG.md)
- [ ] All tests passing (`flutter test`)
- [ ] Lint errors fixed (`flutter analyze`)
- [ ] Code formatted (`dart format .`)
- [ ] Build successful (iOS & Android)
- [ ] App icons updated (all sizes)
- [ ] Screenshots prepared (required sizes)
- [ ] Privacy policy link added
- [ ] Firebase production keys configured
- [ ] API endpoints set to production
- [ ] Deep links tested
- [ ] Push notifications tested

---

### 6.2 Build Commands

**iOS (TestFlight):**
```bash
# Clean build
flutter clean
flutter pub get

# Build
flutter build ios --release

# Or build IPA
flutter build ipa --release

# Upload to TestFlight
# (Via Xcode Organizer or Transporter app)
```

**Android (Play Console):**
```bash
# Clean build
flutter clean
flutter pub get

# Build app bundle (recommended)
flutter build appbundle --release

# Or build APK
flutter build apk --release

# Upload to Play Console
# (Via web interface or Google Play Console API)
```

---

### 6.3 Version Numbering

**Format:** `MAJOR.MINOR.PATCH+BUILD`

**Example:** `1.2.3+45`
- Major: Breaking changes (1.x.x)
- Minor: New features (x.2.x)
- Patch: Bug fixes (x.x.3)
- Build: Sequential number (+45)

**pubspec.yaml:**
```yaml
version: 1.2.3+45
```

**Increment rules:**
- Major: Manual (API changes, major redesign)
- Minor: Each feature release
- Patch: Each bug fix release
- Build: Auto-increment on every release

---

## 7. Version Management

### 7.1 Git Branching Strategy

**Branches:**
- `main` - Production-ready code
- `develop` - Integration branch
- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `hotfix/*` - Emergency fixes

**Flow:**
```
feature/timer-widget Ã¢â€ â€™ develop Ã¢â€ â€™ main Ã¢â€ â€™ v1.2.0 tag
```

**Branch protection rules:**
- `main`: Require PR, passing tests, 1 approval
- `develop`: Require PR, passing tests

---

### 7.2 Commit Convention

**Format:** `type(scope): description`

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructuring
- `test`: Adding tests
- `docs`: Documentation
- `chore`: Maintenance

**Examples:**
```
feat(timer): add countdown widget with cleanup
fix(auth): prevent duplicate SMS requests
refactor(game): extract score calculation to usecase
test(leaderboard): add race condition tests
docs(readme): update installation instructions
chore(deps): update firebase packages
```

---

### 7.3 Release Process

**Steps:**

1. **Prepare release:**
   ```bash
   git checkout develop
   git pull
   git checkout -b release/1.2.0
   ```

2. **Update version:**
   ```yaml
   # pubspec.yaml
   version: 1.2.0+46
   ```

3. **Update changelog:**
   ```markdown
   # CHANGELOG.md
   
   ## [1.2.0] - 2026-01-29
   
   ### Added
   - Timer widget with memory leak prevention
   - Score calculation with validation
   
   ### Fixed
   - Race condition in leaderboard updates
   - Duplicate form submission
   ```

4. **Test thoroughly:**
   ```bash
   flutter test
   flutter build ios --release
   flutter build appbundle --release
   ```

5. **Merge to main:**
   ```bash
   git checkout main
   git merge release/1.2.0
   git tag -a v1.2.0 -m "Release version 1.2.0"
   git push origin main --tags
   ```

6. **Deploy:**
   - GitHub Actions auto-triggers on tag push
   - Or manual upload to stores

7. **Merge back to develop:**
   ```bash
   git checkout develop
   git merge main
   git push origin develop
   ```

---

## Quick Reference Commands

```bash
# Development
flutter pub get              # Install dependencies
flutter run                  # Run app (debug)
flutter run --release        # Run app (release)

# Testing
flutter test                 # All tests
flutter test --coverage      # With coverage
flutter test integration_test/  # E2E tests

# Code Quality
flutter analyze --fatal-infos  # Lint
dart format .                  # Format
dart fix --apply              # Auto-fix issues

# Build
flutter build ios --release
flutter build appbundle --release
flutter build apk --release

# Clean
flutter clean
flutter pub get
```

---

## For Claude (AI Assistant)

**When implementing features:**

1. Write tests FIRST (TDD approach)
2. Ensure 80%+ coverage for critical code
3. Run analyzer before committing
4. Follow conventional commits
5. Add Firebase analytics events for user actions
6. Include crashlytics error handling

**Testing priorities:**
1. Unit tests for business logic
2. Widget tests for user interactions
3. Integration tests for critical flows

**Before marking feature complete:**
- [ ] Tests written and passing
- [ ] No analyzer warnings
- [ ] Code formatted
- [ ] Documentation updated

---

**End of Development Workflow v1.1**

**For design specs:** See `ui_ux_design.md` (to be created)  
**For edge cases:** See `vcguide.md`  
**For security:** See `vcsecurity.md`  
**For data structure:** See `database_schema.md`
