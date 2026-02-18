# DiagnozApp: Development Guide & Critical Edge Cases
**Version:** 2.1 (English)  
**Last Updated:** January 30, 2026  
**For:** AI assistants (Claude) writing code  
**Stack:** Flutter + Firebase (Firestore, Auth, Cloud Functions) + Riverpod

> **Purpose:** Critical edge cases and best practices for building DiagnozApp.  
> **Read this BEFORE writing any feature code.**

---

## Table of Contents

1. [Core Principles](#1-core-principles)
2. [Project Summary](#2-project-summary)
3. [Critical Edge Cases](#3-critical-edge-cases)
4. [Security Checklist](#4-security-checklist)
5. [State Management (Riverpod)](#5-state-management-riverpod)
6. [Firebase Best Practices](#6-firebase-best-practices)
7. [Testing Strategy](#7-testing-strategy)

---

## 1. Core Principles

### Every Function Needs "WHY" Comments

```dart
// WRONG: AI-generated code without explanation
double calculateScore(int timeLeft) {
  return timeLeft * 10;  // Bu formÃ¼l YANLIÅž! 80s = 800 puan yapar
}

// CORRECT: WHY comment explaining the reasoning
double calculateScore(int timeLeft) {
  // WHY: Formula from masterplan.md: (timeLeft / 100) * 10
  // 120s = 12.0 points (max), 52s = 5.2 points, 80s = 8.0 points
  // This ensures competitive balance with reasonable score ranges
  return (timeLeft / 100) * 10;
}
```

### Vibe Coding Rules for This Project

1. Every function must have a "WHY" comment (not "WHAT")
2. Code reading session: 1 hour per week
3. Ask AI to explain, then add that explanation as a comment
4. Minimum Viable = Minimum (cut ruthlessly)
5. For every feature, ask: "What happens if I remove this?"
6. Unmaintainable code = Technical debt

---

## 2. Project Summary

### Vision
World's fastest, most competitive, and most educational medical diagnosis simulation for medical students.

### Core Loop
1. **Case Presentation** â†’ Patient profile + chief complaint + vital signs
2. **Player Action** â†’ (a) Guess diagnosis (risky) OR (b) Request tests (safe but time cost)
3. **Resolution** â†’ Correct = points + next case | Wrong = elimination/penalty

### Game Modes
- **Rush (Primary):** 120s/case, test = -10s, wrong = elimination
- **Zen (Practice):** No timer, wrong = feedback, no score
- **PvP (Future):** 1v1, same cases, highest score wins
- **Branch (Future):** Filter by specialty

---

## 3. Critical Edge Cases

### Edge Case 1: Timer System (120 Second Countdown)

#### WRONG (What AI Will Write)

```dart
// Flutter/Riverpod
class TimerNotifier extends StateNotifier<int> {
  TimerNotifier() : super(120) {
    Timer.periodic(Duration(seconds: 1), (timer) {
      state--;
    });
  }
}

// PROBLEM: No cleanup! Memory leak!
// When widget unmounts, timer keeps running
// 10 mount/unmount cycles = 10 timers running simultaneously
```

#### CORRECT Solution

```dart
class TimerNotifier extends StateNotifier<int> {
  Timer? _timer;
  
  TimerNotifier() : super(120) {
    _startTimer();
  }
  
  void _startTimer() {
    // WHY: Update state every second to trigger UI rebuild
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state > 0) {
        state--;
      } else {
        // WHY: Stop timer when reaches 0 (game over)
        _timer?.cancel();
        _handleGameOver();
      }
    });
  }
  
  @override
  void dispose() {
    // WHY: Clean up timer to prevent memory leak
    // Without this, timer continues after widget disposal
    _timer?.cancel();
    super.dispose();
  }
}
```

#### CRITICAL: Client-Server Timer Sync

```dart
// PROBLEM: User can manipulate client timer via DevTools
// Solution: Validate on backend

// Game Start (Cloud Function)
Future<GameStartResponse> startGame() async {
  final startTime = FieldValue.serverTimestamp();
  
  await firestore.collection('games').doc(gameId).set({
    'userId': userId,
    'startTime': startTime,  // Server-side timestamp
    'status': 'in_progress',
  });
  
  return GameStartResponse(
    gameId: gameId,
    startTime: DateTime.now(),  // Client time for UI only
  );
}

// Diagnosis Submit (Cloud Function)
Future<void> submitDiagnosis(String gameId, String diagnosis) async {
  final gameDoc = await firestore.collection('games').doc(gameId).get();
  final startTime = (gameDoc.data()!['startTime'] as Timestamp).toDate();
  final serverTimeSpent = DateTime.now().difference(startTime).inSeconds;
  
  // WHY: Validate server-side time (client time can be manipulated)
  if (serverTimeSpent > 120) {
    throw Exception('TIME_UP: Server time exceeded 120 seconds');
  }
  
  // WHY: Check for manipulation (client vs server time diff)
  final clientTimeSpent = gameDoc.data()!['clientTimeSpent'] as int;
  if ((serverTimeSpent - clientTimeSpent).abs() > 5) {
    throw Exception('TIMER_TAMPERED: Client/server time mismatch');
  }
  
  // Process diagnosis...
}
```

**Key Takeaway:** Client timer = UI only. Server timer = validation.

---

### Edge Case 2: Score Calculation (Time to Points)

#### WRONG (What AI Will Write)

```dart
double calculateScore(int timeLeft) {
  return timeLeft * 10;  // WRONG! 80s left = 800 points (way too high!)
}

// PROBLEMS:
// 1. timeLeft can be negative (timer bug)
// 2. timeLeft can be 999 (manipulation)
// 3. Score range is wrong (should be 0-12, not 0-1200)
// 4. Overflow: timeLeft = 2147483647 * 10 = integer overflow
```

#### CORRECT Solution

```dart
double calculateScore(int timeLeft) {
  // WHY: Input validation - prevent manipulation
  if (timeLeft < 0) return 0.0;
  if (timeLeft > 120) return 0.0;  // Max time is 120s
  
  // WHY: Formula from masterplan.md: (timeLeft / 100) * 10
  // This gives score range of 0.0 to 12.0 points per case
  // Examples: 120s = 12.0, 80s = 8.0, 52s = 5.2, 0s = 0.0
  final rawScore = (timeLeft / 100) * 10;
  
  // WHY: Cap maximum score per case at 12.0 (defensive)
  return rawScore.clamp(0.0, 12.0);
}
```

**Test Cases:**
```dart
assert(calculateScore(-10) == 0.0);     // Negative time
assert(calculateScore(0) == 0.0);       // Timeout
assert(calculateScore(52) == 5.2);      // Normal case
assert(calculateScore(80) == 8.0);      // Normal case
assert(calculateScore(120) == 12.0);    // Perfect score
assert(calculateScore(999) == 0.0);     // Manipulation attempt
```

---

### Edge Case 3: Test Request System (Each Test = -10 Seconds)

#### WRONG (What AI Will Write)

```dart
void requestTest(String testType) {
  timeLeft.value -= 10;
  fetchTestResult(testType);
}

// PROBLEMS:
// 1. timeLeft can go negative
// 2. Same test requested twice = -20s total
// 3. No rate limiting, can spam requests
```

#### CORRECT Solution

```dart
class GameState extends StateNotifier<GameStateModel> {
  Future<void> requestTest(String testType) async {
    // WHY: Check sufficient time (prevent negative)
    if (state.timeLeft < 10) {
      _showError('Insufficient time remaining!');
      return;
    }
    
    // WHY: Prevent duplicate test requests (idempotency)
    if (state.requestedTests.contains(testType)) {
      _showError('Test already requested!');
      return;
    }
    
    // WHY: Optimistic update for better UX (instant feedback)
    state = state.copyWith(
      timeLeft: max(state.timeLeft - 10, 0),
      requestedTests: [...state.requestedTests, testType],
    );
    
    try {
      // Backend request
      final result = await _api.requestTest(state.caseId, testType);
      
      // Update with actual result
      state = state.copyWith(
        testResults: {...state.testResults, testType: result},
      );
    } catch (e) {
      // WHY: Rollback on error (restore time, remove test)
      state = state.copyWith(
        timeLeft: state.timeLeft + 10,
        requestedTests: state.requestedTests.where((t) => t != testType).toList(),
      );
      _showError('Failed to request test: $e');
    }
  }
}
```

#### Backend Validation (Cloud Function)

```javascript
// CRITICAL: Frontend validation = UX, Backend validation = Security

exports.requestTest = functions.https.onCall(async (data, context) => {
  const { caseId, testType } = data;
  const userId = context.auth.uid;
  
  // WHY: Check if test already requested (idempotency)
  const cacheKey = `test:${caseId}:${userId}:${testType}`;
  const cached = await admin.database().ref(cacheKey).once('value');
  
  if (cached.exists()) {
    throw new functions.https.HttpsError(
      'already-exists',
      'Test already requested'
    );
  }
  
  // WHY: Set cache to prevent duplicate requests (60s TTL)
  await admin.database().ref(cacheKey).set(true);
  await admin.database().ref(cacheKey).remove();  // Auto-expire after 60s
  
  // Fetch and return test result
  const result = await getTestResult(caseId, testType);
  return result;
});
```

---

### Edge Case 4: Leaderboard Updates (Race Condition)

#### WRONG (What AI Will Write)

```dart
// WRONG: Read-then-write pattern
Future<void> updateLeaderboard(String userId, double score) async {
  final doc = await firestore.collection('users').doc(userId).get();
  final currentScore = doc.data()!['weeklyScore'] as double;
  final newScore = currentScore + score;
  
  await firestore.collection('users').doc(userId).update({
    'weeklyScore': newScore,
  });
}

// PROBLEM: Race Condition!
// User A: Read score = 100
// User B: Read score = 100
// User A: Write score = 150 (+50)
// User B: Write score = 180 (+80)
// Expected: 100 + 50 + 80 = 230
// Actual: 180 (User A's +50 was lost!)
```

#### CORRECT Solution (Atomic Operation)

```dart
Future<void> updateLeaderboard(String userId, double score) async {
  // WHY: FieldValue.increment() is atomic (no race condition)
  // Firestore handles concurrent updates internally
  await firestore.collection('users').doc(userId).update({
    'stats.weeklyScore': FieldValue.increment(score),
    'stats.monthlyScore': FieldValue.increment(score),
    'stats.totalGamesPlayed': FieldValue.increment(1),
  });
  
  // WHY: Also update leaderboard collection (denormalized for fast queries)
  final weekNumber = _getWeekNumber(DateTime.now());
  final year = DateTime.now().year;
  final leaderboardDocId = '${userId}_w${weekNumber}_$year';
  
  await firestore.collection('leaderboard_weekly').doc(leaderboardDocId).set({
    'userId': userId,
    'score': FieldValue.increment(score),
    'casesPlayed': FieldValue.increment(5),  // Assuming 5 cases per game
    'gamesPlayed': FieldValue.increment(1),
    'weekNumber': weekNumber,
    'year': year,
    'lastUpdated': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
```

**Key Takeaway:** Always use atomic operations (FieldValue.increment) for score updates.

---

### Edge Case 5: Form Submission (Duplicate Submit)

#### WRONG (What AI Will Write)

```dart
// Button with no protection
ElevatedButton(
  onPressed: () async {
    await submitDiagnosis(diagnosis);
  },
  child: Text('Submit'),
);

// PROBLEM: User taps button 10 times rapidly
// Result: 10 submissions, 10 score updates, data corruption
```

#### CORRECT Solution

```dart
class DiagnosisSubmitButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(isSubmittingProvider);
    
    return ElevatedButton(
      // WHY: Disable button during submission
      onPressed: isSubmitting ? null : () async {
        ref.read(isSubmittingProvider.notifier).state = true;
        
        try {
          await ref.read(gameStateProvider.notifier).submitDiagnosis(diagnosis);
        } finally {
          // WHY: Re-enable button after completion (success or error)
          ref.read(isSubmittingProvider.notifier).state = false;
        }
      },
      child: isSubmitting 
        ? CircularProgressIndicator()
        : Text('Submit Diagnosis'),
    );
  }
}
```

#### Backend Protection (Cloud Function)

```javascript
exports.submitDiagnosis = functions.https.onCall(async (data, context) => {
  const { gameId, diagnosis } = data;
  const userId = context.auth.uid;
  
  // WHY: Use transaction to prevent duplicate submissions
  return admin.firestore().runTransaction(async (transaction) => {
    const gameRef = admin.firestore().collection('games').doc(gameId);
    const gameDoc = await transaction.get(gameRef);
    
    // WHY: Check if already submitted (idempotency)
    if (gameDoc.data().status === 'completed') {
      throw new functions.https.HttpsError(
        'already-exists',
        'Game already completed'
      );
    }
    
    // Process diagnosis and update atomically
    transaction.update(gameRef, {
      status: 'completed',
      finalDiagnosis: diagnosis,
      completedAt: FieldValue.serverTimestamp(),
    });
    
    // Update user score (also atomic)
    const userRef = admin.firestore().collection('users').doc(userId);
    transaction.update(userRef, {
      'stats.weeklyScore': FieldValue.increment(score),
    });
  });
});
```

---

## 4. Security Checklist

**Run this checklist before deploying any feature:**

### Input Validation
- [ ] All user inputs validated for type, range, and format
- [ ] Phone numbers validated (E.164 format: +905551234567)
- [ ] Diagnosis strings sanitized (prevent XSS)
- [ ] Time values checked for negative/overflow

### Backend Validation
- [ ] Critical data validated on server (score, time, passes)
- [ ] Never trust client data
- [ ] Firestore Security Rules written and tested
- [ ] Cloud Functions have proper error handling

### Rate Limiting
- [ ] SMS sending: Max 3 per hour per phone number
- [ ] Game start: Max 10 per hour per user
- [ ] API endpoints protected with rate limiting

### Authentication
- [ ] JWT tokens expire after 7 days
- [ ] Refresh tokens handled properly
- [ ] Phone number never exposed publicly
- [ ] Session invalidation on password change

### Data Privacy
- [ ] No sensitive data in logs
- [ ] Phone numbers hashed in analytics
- [ ] User can delete their account
- [ ] GDPR compliance checked

---

## 5. State Management (Riverpod)

### Provider Structure

```dart
// Game State Provider
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier(ref);
});

// Timer Provider (auto-disposes when not in use)
final timerProvider = StateNotifierProvider.autoDispose<TimerNotifier, int>((ref) {
  return TimerNotifier();
});

// Leaderboard Provider (cached for 5 minutes)
final leaderboardProvider = FutureProvider.autoDispose.family<List<LeaderboardEntry>, String>(
  (ref, period) async {
    // WHY: Cache for 5 minutes to reduce Firestore reads
    ref.keepAlive();
    Timer(Duration(minutes: 5), () => ref.invalidateSelf());
    
    return await ref.read(leaderboardRepositoryProvider).getLeaderboard(period);
  },
);
```

### Best Practices

**1. Use autoDispose for temporary screens:**
```dart
// Good: Timer auto-disposes when leaving game screen
final timerProvider = StateNotifierProvider.autoDispose<...>(...);

// Bad: Timer stays in memory forever
final timerProvider = StateNotifierProvider<...>(...);
```

**2. Use family for parameterized providers:**
```dart
// Good: Separate cache for each case
final caseProvider = FutureProvider.family<Case, String>((ref, caseId) async {
  return await fetchCase(caseId);
});

// Bad: Single provider for all cases (cache collision)
final caseProvider = FutureProvider<Case>((ref) async {
  return await fetchCase(currentCaseId);  // Which case??
});
```

**3. Keep business logic in StateNotifier, not widgets:**
```dart
// Good: Logic in StateNotifier
class GameStateNotifier extends StateNotifier<GameState> {
  void requestTest(String testType) {
    // Validation logic here
    if (state.timeLeft < 10) return;
    // Update logic here
  }
}

// Bad: Logic in widget
onPressed: () {
  if (timeLeft < 10) return;  // Don't do this!
  // ...
}
```

---

## 6. Firebase Best Practices

### Minimize Reads (Reads = Money)

```dart
// BAD: Read leaderboard every time user opens app
Future<List<LeaderboardEntry>> getLeaderboard() async {
  final snapshot = await firestore
    .collection('leaderboard_weekly')
    .orderBy('score', descending: true)
    .limit(50)
    .get();
  return snapshot.docs.map((doc) => LeaderboardEntry.fromFirestore(doc)).toList();
}
// If 1000 users open app = 50,000 reads per day!

// GOOD: Cache leaderboard for 5 minutes
class LeaderboardRepository {
  List<LeaderboardEntry>? _cachedLeaderboard;
  DateTime? _cacheTime;
  
  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final now = DateTime.now();
    
    // WHY: Return cached data if less than 5 minutes old
    if (_cachedLeaderboard != null && 
        _cacheTime != null && 
        now.difference(_cacheTime!).inMinutes < 5) {
      return _cachedLeaderboard!;
    }
    
    // Cache expired, fetch fresh data
    final snapshot = await firestore
      .collection('leaderboard_weekly')
      .orderBy('score', descending: true)
      .limit(50)
      .get();
    
    _cachedLeaderboard = snapshot.docs
      .map((doc) => LeaderboardEntry.fromFirestore(doc))
      .toList();
    _cacheTime = now;
    
    return _cachedLeaderboard!;
  }
}
// Savings: 50,000 reads â†’ ~150 reads per day (99% reduction!)
```

### Batch Operations

```dart
// BAD: Multiple individual writes
await firestore.collection('users').doc(userId).update({'field1': value1});
await firestore.collection('games').doc(gameId).update({'field2': value2});
await firestore.collection('leaderboard').doc(docId).set({'field3': value3});
// If one fails, others still execute (inconsistent state!)

// GOOD: Batch write (atomic)
final batch = firestore.batch();

batch.update(firestore.collection('users').doc(userId), {'field1': value1});
batch.update(firestore.collection('games').doc(gameId), {'field2': value2});
batch.set(firestore.collection('leaderboard').doc(docId), {'field3': value3});

await batch.commit();  // All or nothing!
```

### Query Optimization

```dart
// BAD: Load all cases (10,000 reads!)
final allCases = await firestore.collection('cases').get();

// GOOD: Load only needed cases (5 reads)
final randomCaseIds = await _getRandomCaseIds(count: 5);
final cases = await Future.wait(
  randomCaseIds.map((id) => firestore.collection('cases').doc(id).get())
);

// EVEN BETTER: Batch get (1 read for multiple docs)
final cases = await firestore.getAll(
  randomCaseIds.map((id) => firestore.collection('cases').doc(id))
);
```

---

## 7. Testing Strategy

### Critical Tests (Must Have)

**1. Timer Cleanup Test**
```dart
testWidgets('Timer is disposed when widget unmounts', (tester) async {
  await tester.pumpWidget(GameScreen());
  
  // Verify timer starts
  expect(find.text('120'), findsOneWidget);
  
  await tester.pump(Duration(seconds: 1));
  expect(find.text('119'), findsOneWidget);
  
  // Unmount widget
  await tester.pumpWidget(Container());
  
  // Verify no timers running (no memory leak)
  expect(tester.binding.timers.length, 0);
});
```

**2. Race Condition Test**
```dart
test('Concurrent score updates do not lose data', () async {
  final userId = 'user_123';
  
  // Simulate 2 concurrent updates
  await Future.wait([
    updateLeaderboard(userId, 50.0),
    updateLeaderboard(userId, 80.0),
  ]);
  
  // Verify final score is correct (not lost)
  final doc = await firestore.collection('users').doc(userId).get();
  expect(doc.data()!['stats']['weeklyScore'], 130.0);  // 50 + 80
});
```

**3. Duplicate Submit Test**
```dart
test('Form cannot be submitted twice', () async {
  final gameId = 'game_123';
  
  // First submit should succeed
  final result1 = await submitDiagnosis(gameId, 'MI');
  expect(result1.success, true);
  
  // Second submit should fail
  expect(
    () => submitDiagnosis(gameId, 'MI'),
    throwsA(isA<AlreadySubmittedException>()),
  );
});
```

**4. Score Calculation Test**
```dart
test('Score calculation follows masterplan formula', () {
  // Formula: (timeLeft / 100) * 10
  expect(calculateScore(120), 12.0);  // Max score
  expect(calculateScore(100), 10.0);
  expect(calculateScore(80), 8.0);
  expect(calculateScore(52), 5.2);
  expect(calculateScore(0), 0.0);     // Timeout
  expect(calculateScore(-10), 0.0);   // Invalid (negative)
  expect(calculateScore(999), 0.0);   // Invalid (manipulation)
});
```

---

## Quick Reference

### When Implementing a Feature, Always Check:

**Timer-related features:**
- [ ] Cleanup in dispose()
- [ ] Server-side validation
- [ ] Client-server time sync check

**Score/Points features:**
- [ ] Input validation (type, range, negative)
- [ ] Formula: `(timeLeft / 100) * 10` (max 12.0 per case)
- [ ] Atomic operations (FieldValue.increment)
- [ ] Backend validation

**Form submissions:**
- [ ] Disable button after first tap
- [ ] Backend idempotency check
- [ ] Transaction or batch write

**Leaderboard updates:**
- [ ] Use atomic operations
- [ ] Cache for 5 minutes
- [ ] Denormalize displayName

**Test requests:**
- [ ] Duplicate test check
- [ ] Time validation (prevent negative)
- [ ] Optimistic update + rollback on error

---

## For Claude (AI Assistant)

**Before writing ANY code:**
1. Read this guide's relevant section
2. Check if edge case applies
3. Include "WHY" comments in generated code
4. Use atomic operations for score updates
5. Always clean up timers in dispose()
6. Validate inputs (type, range, negative)
7. Backend validation for critical data
8. Score formula: `(timeLeft / 100) * 10`

**Don't skip these steps to "move faster."**  
**Edge cases break in production, not development.**

---

**End of Development Guide v2.1**

**For security details:** See `vcsecurity.md`  
**For data structure:** See `database_schema.md`  
**For game design:** See `masterplan.md`
