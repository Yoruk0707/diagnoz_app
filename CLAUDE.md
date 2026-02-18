# DiagnozApp - Claude Code Project Rules

## Project Overview

DiagnozApp: Competitive medical diagnosis simulation game for Turkish medical students.
Stack: Flutter (Dart) + Firebase (Firestore, Auth, Cloud Functions) + Riverpod
Architecture: Clean Architecture (presentation/domain/data layers)
Target: Turkish market, university students

## Current Status

- Sprint 1 (Foundation) ✅
- Sprint 2 (Auth - SMS Phone) ✅
- Sprint 3 (Core Game Loop - Rush Mode) ✅
- Sprint 4 (Firebase Integration + Leaderboard) → IN PROGRESS
- Web version running on Chrome (localhost)
- GitHub: https://github.com/Yoruk0707/diagnoz_app

## Core Game Loop

Case Presentation → Player Action (Guess/Test) → Result → Score/Next
- Rush Mode: 120s/case, test=-10s, wrong=elimination, 2 passes per game
- Scoring: (timeLeft / 100) * 10 per case

## CRITICAL RULES (Non-Negotiable)

### 1. NEDEN (WHY) Comments - MANDATORY
Every non-obvious function MUST have a // NEDEN: ... or // WHY: ... commen, not WHAT. The code shows what.

### 2. Timer System - SECURITY CRITICAL
- Client timer = UI ONLY (can be manipulated via DevTools)
- Server validates: startTime vs submitTime via Cloud Functions
- MUST cleanup timer in dispose() → prevents memory leak
- Timer + TextInput on same screen → MUST use ConsumerStatefulWidget (NOT ConsumerWidget)

### 3. Leaderboard - Race Condition Prevention
- NEVER read-then-write scores (race condition!)
- ALWAYS use FieldValue.increment() for atomic updates
- Use batch writes for multi-document updates (game + user + leaderboard)
- Cache leaderboard for 5 minutes client-side

### 4. Form Submission - Duplicate Prevention
- Disable button after first tap (isSubmitting state)
- Backend: Check if already submitted before processing
- Re-enable button in finally block (success or error)

### 5. Input Validation
- Validate ALL user inputs: type, range, null checks
- Phone: E.164 format (+905551234567)
- Diagnosis strings: sanitize (prevent XSS)
- Frontend validation = UX onlackend validation = Security

### 6. Firestore Cost Optimization
- Reads = Money. Minimize queries.
- Use whereIn() instead of multiple individual queries
- Pagination: Load 20 items max, not all documents
- Cache: leaderboard (5 min), cases (7 days via Hive)

### 7. Memory & State Cleanup
- MUST dispose controllers/subscriptions in dispose()
- MUST cancel timers in dispose()
- TextEditingController → always in StatefulWidget state, never in build()

### 8. Error Handling
- Wrap ALL async operations in try-catch
- Show user-friendly Turkish error messages
- No stack traces in production logs

## Language Rules

- Code/variables/comments: ENGLISH always
- UI strings/error messages: TURKISH always

## Architecture - Clean Architecture
```
lib/
  core/
    constants/     # app_constants.dart, app_strings.dart
    errors/        # failures.dart
    theme/         # app_theme.dart, app_colors.dart
    router/        # app_router.dart (GoRouter)
    utils/         # input_validator.dart
  features/
    auth/
    domain/      # entities, repositories (interfaces), usecases
      data/        # models, repositories (implementations), datasources
      presentation/ # pages, widgets, providers (Riverpod)
    game/
      domain/
      data/
      presentation/
    leaderboard/
      domain/
      data/
      presentation/
```

## State Management - Riverpod ONLY

- StateNotifier + StateNotifierProvider for complex state
- Provider for simple DI
- FutureProvider for async data
- NO setState(), NO ChangeNotifier, NO BLoC

## Firebase Security Rules

- users/: read=all, write=owner only, delete=never
- games/: read=owner, create=owner, update/delete=never (immutable)
- cases/: read=all, write=never (admin via Cloud Functions)
- leaderboard: read=all, write=never (Cloud Functions only)

## Database Schema (Key Collections)

### users/{userId}
- phoneNumber (E.164), displayName, createdAt
- stats: { totalGamesPlayed, weeklyScore, monthlyScore, bestScore }

### games/{gameId}
- userId, mode, status, startTime, endTime, totalScore, passesLeft
- cases: [{ caseId, diagnosis, correct, timeSpent, score, testsUsed }]

### cases/{caseId}
- specialty, difficulty, chiefComplaint, patientProfile, vitals
- correctDiagnosis, availableTests[], differentialDiagnosis[]

### leaderboard_weekly/{userId_wWW_YYYY}
- userId, displayName, score, casesPlayed, weekNumber, year

## Known Lessons (Past Mistakes - DON'T REPEAT)

1. Crashlytics + Web: Guard with kIsWeb check
2. Zone Mismatch: ensureInitialized() MUST be INSIDE runZonedGuarded
3. Material 3 Types: Use CardThemeData not CardTheme
4. Missing Factory: Ensure ALL factory constructors exist in failures.dart
5. Interface Mismatch: Domain return types MUST match data implementation
6. TextEditingController + Timer: Use ConsumerStatefulWidget
7. Const Propagation: Use static const (not static final + const)
8. Old Skeleton Files: Run flutter analyze at sprint start

## Git Workflow

- Commits: Conventional format (feat:, fix:, refactor:, chore:)
- Never commit directly to main
- Always commit pubspec.lock
- Exact versions in pubspec.yaml (no ^ or ~)

## CTO Mindset - STOP ME IF:

If a proposed change will:
- Create a security vulnerability → STOP and propose secure alternative
- Cost unnecessary Firebase money → STOP and propose optimization
- Cause race conditions → STOP and propose atomic operations
- Leak memory → STOP and propose proper cleanup
- Break in production → STOP and explain why
