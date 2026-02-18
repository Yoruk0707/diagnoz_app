# Security & Production Best Practices
**Version:** 2.1 (English)  
**Last Updated:** January 30, 2026  
**For:** DiagnozApp Development Team  
**Source:** Real-world production experience + industry best practices

> **"AI code works â‰  AI code is secure"**  
> Edge cases break in production, not in development.

---

## Table of Contents

1. [Authentication & Session Management](#1-authentication--session-management)
2. [Input Validation](#2-input-validation)
3. [Rate Limiting](#3-rate-limiting)
4. [Firebase Security Rules](#4-firebase-security-rules)
5. [Git Best Practices](#5-git-best-practices)
6. [Dependency Management](#6-dependency-management)
7. [DiagnozApp-Specific Security](#7-diagnozapp-specific-security)

---

## 1. Authentication & Session Management

### Session Invalidation on Password Change

#### WRONG (What AI Will Write)

```dart
Future<void> updatePassword(String userId, String newPassword) async {
  // Update password only
  await firestore.collection('users').doc(userId).update({
    'password': hashPassword(newPassword),
  });
}

// PROBLEM: Old sessions remain active!
// Hacker with stolen token can still access account
```

#### CORRECT Solution

```dart
Future<void> updatePassword(String userId, String newPassword) async {
  final batch = firestore.batch();
  
  // 1. Update password
  batch.update(firestore.collection('users').doc(userId), {
    'password': hashPassword(newPassword),
    'passwordChangedAt': FieldValue.serverTimestamp(),
  });
  
  // 2. Invalidate all sessions
  // (Implementation depends on auth system)
  // For Firebase Auth: revoke refresh tokens
  await admin.auth().revokeRefreshTokens(userId);
  
  await batch.commit();
}

// Middleware: Check token creation time
Future<bool> validateToken(String token) async {
  final decoded = jwt.verify(token);
  final userId = decoded['userId'];
  
  final user = await firestore.collection('users').doc(userId).get();
  final passwordChangedAt = user.data()!['passwordChangedAt'] as Timestamp;
  
  // WHY: Token created before password change = invalid
  if (decoded['iat'] < passwordChangedAt.seconds) {
    throw UnauthorizedException('Token expired due to password change');
  }
  
  return true;
}
```

**Key Takeaway:** Password change = kill all sessions.

---

### Phone Number Normalization (DiagnozApp Specific)

DiagnozApp uses SMS authentication. Phone numbers need special handling:

```dart
String normalizePhoneNumber(String phone) {
  // WHY: Remove all non-digit characters
  final digitsOnly = phone.replaceAll(RegExp(r'[^\d+]'), '');
  
  // WHY: Ensure E.164 format (+country code)
  if (!digitsOnly.startsWith('+')) {
    // Assume Turkey if no country code
    return '+90$digitsOnly';
  }
  
  return digitsOnly;
}

// Usage
final normalizedPhone = normalizePhoneNumber('0555 123 4567');
// Result: "+905551234567"
```

**Duplicate Check:**
```dart
// BAD: Check exact match only
final existing = await firestore
  .collection('users')
  .where('phoneNumber', isEqualTo: phone)
  .get();

// GOOD: Check normalized phone
final normalizedPhone = normalizePhoneNumber(phone);
final existing = await firestore
  .collection('users')
  .where('phoneNumber', isEqualTo: normalizedPhone)
  .get();

if (!existing.docs.isEmpty) {
  throw Exception('Phone number already registered');
}
```

---

## 2. Input Validation

### The 90% Problem

**Research finding:** 90% of AI-generated code has security vulnerabilities due to missing input validation.

### Universal Input Validation Pattern

```dart
T validateInput<T>({
  required dynamic value,
  required Type expectedType,
  double? min,
  double? max,
  int? maxLength,
  RegExp? pattern,
}) {
  // 1. Type check
  if (value.runtimeType != expectedType) {
    throw ValidationException('Invalid type: expected $expectedType, got ${value.runtimeType}');
  }
  
  // 2. Null check
  if (value == null) {
    throw ValidationException('Value cannot be null');
  }
  
  // 3. Range check (for numbers)
  if (value is num) {
    if (min != null && value < min) {
      throw ValidationException('Value $value below minimum $min');
    }
    if (max != null && value > max) {
      throw ValidationException('Value $value above maximum $max');
    }
  }
  
  // 4. Length check (for strings)
  if (value is String) {
    if (maxLength != null && value.length > maxLength) {
      throw ValidationException('String length ${value.length} exceeds maximum $maxLength');
    }
  }
  
  // 5. Pattern check (for strings)
  if (value is String && pattern != null) {
    if (!pattern.hasMatch(value)) {
      throw ValidationException('String does not match required pattern');
    }
  }
  
  return value as T;
}
```

### DiagnozApp Validation Examples

```dart
// Validate time left
final timeLeft = validateInput<int>(
  value: timeLeftFromClient,
  expectedType: int,
  min: 0,
  max: 120,
);

// Validate diagnosis string
final diagnosis = validateInput<String>(
  value: diagnosisFromClient,
  expectedType: String,
  maxLength: 100,
  pattern: RegExp(r'^[a-zA-Z0-9\s\-]+$'),  // Alphanumeric + spaces + hyphens
);

// Validate phone number
final phone = validateInput<String>(
  value: phoneFromClient,
  expectedType: String,
  pattern: RegExp(r'^\+\d{10,15}$'),  // E.164 format
);
```

---

## 3. Rate Limiting

### SMS Rate Limiting (CRITICAL for DiagnozApp)

SMS costs money. Without rate limiting, you're vulnerable to:
1. Cost attack: Attacker spams SMS to drain budget
2. DoS attack: Flood SMS provider with requests
3. Abuse: Users request multiple codes to bypass verification

#### Implementation (Cloud Function)

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const rateLimit = require('express-rate-limit');

// WHY: Limit SMS requests to 3 per hour per phone number
const smsLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,  // 1 hour
  max: 3,  // Max 3 requests per window
  keyGenerator: (req) => {
    // WHY: Rate limit by phone number, not IP
    // (Multiple users can share same IP)
    return req.body.phoneNumber;
  },
  handler: (req, res) => {
    res.status(429).json({
      error: 'TOO_MANY_REQUESTS',
      message: 'Maximum 3 SMS codes per hour',
      retryAfter: 3600,  // seconds
    });
  },
});

exports.sendSMSCode = functions.https.onCall(
  smsLimiter,
  async (data, context) => {
    const { phoneNumber } = data;
    
    // Generate and send SMS code
    const code = generateSixDigitCode();
    await sendSMS(phoneNumber, `DiagnozApp code: ${code}`);
    
    // Store code with 5-minute expiry
    await admin.database().ref(`sms_codes/${phoneNumber}`).set({
      code: hashCode(code),
      expiresAt: Date.now() + (5 * 60 * 1000),
    });
    
    return { success: true };
  }
);
```

### Game Start Rate Limiting

```javascript
// WHY: Prevent game start spam (could be used for case farming)
const gameStartLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,  // 1 hour
  max: 20,  // Max 20 games per hour
  keyGenerator: (req) => req.auth.uid,
});

exports.startGame = functions.https.onCall(
  gameStartLimiter,
  async (data, context) => {
    // Game start logic...
  }
);
```

---

## 4. Firebase Security Rules

### Security Rules are NOT Optional

**Default behavior:** Without security rules, anyone can read/write any document.

### DiagnozApp Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function hasRole(role) {
      return get(/databases/$(database)/documents/users/$(request.auth.uid))
        .data.role == role;
    }
    
    // === USERS COLLECTION ===
    match /users/{userId} {
      // Anyone can read public profile data
      allow read: if true;
      
      // Only owner can update their own profile
      allow update: if isAuthenticated() && isOwner(userId);
      
      // Only authenticated users can create account
      allow create: if isAuthenticated() && isOwner(userId);
      
      // Cannot delete account (must contact support)
      allow delete: if false;
    }
    
    // === GAMES COLLECTION ===
    match /games/{gameId} {
      // Only owner can read their game history
      allow read: if isAuthenticated() && 
                     isOwner(resource.data.userId);
      
      // Only Cloud Functions can create games
      // (Prevents fake score injection)
      allow create: if false;
      
      // Games are immutable (audit trail)
      allow update, delete: if false;
    }
    
    // === CASES COLLECTION ===
    match /cases/{caseId} {
      // Anyone can read cases (needed for gameplay)
      allow read: if true;
      
      // Only admins can modify cases
      allow write: if isAuthenticated() && hasRole('admin');
    }
    
    // === LEADERBOARDS ===
    match /leaderboard_weekly/{docId} {
      // Anyone can read leaderboard
      allow read: if true;
      
      // Only Cloud Functions can update leaderboard
      // (Prevents score manipulation)
      allow write: if false;
    }
    
    match /leaderboard_monthly/{docId} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

### Why These Rules?

**Games: write = false**
- Prevents client from creating fake games with inflated scores
- All game creation goes through Cloud Functions (server-side validation)

**Leaderboards: write = false**
- Prevents direct score manipulation
- Updates only via Cloud Functions (atomic operations guaranteed)

**Cases: write = admin only**
- Prevents unauthorized case modifications
- Maintains medical accuracy and content quality

---

## 5. Git Best Practices

### Critical Git Commands for Senior Developers

#### 1. Interactive Rebase (Clean History)

```bash
# WHY: Clean up commit history before merging to main
git rebase -i HEAD~5

# Example:
# pick abc123 feat: add timer
# pick def456 fix: typo
# pick ghi789 feat: add score calculation
# pick jkl012 fix: validation bug
# pick mno345 feat: add leaderboard

# Clean up to:
# pick abc123 feat: add timer
# squash def456 fix: typo  # Merge into previous commit
# pick ghi789 feat: add score calculation
# squash jkl012 fix: validation bug
# pick mno345 feat: add leaderboard

# Result: 5 commits â†’ 3 commits (cleaner history)
```

#### 2. Git Bisect (Bug Hunting)

```bash
# WHY: Binary search to find bug-introducing commit
git bisect start
git bisect bad           # Current commit is bad
git bisect good v1.0     # v1.0 was working

# Git automatically checks out middle commit
# Test the code
npm test

# If bug present:
git bisect bad

# If bug not present:
git bisect good

# Git will find exact commit that introduced bug
```

#### 3. Pre-commit Hooks

```bash
# .git/hooks/pre-commit

#!/bin/bash

# WHY: Run checks before allowing commit
echo "Running pre-commit checks..."

# Lint
flutter analyze
if [ $? -ne 0 ]; then
  echo "Lint failed"
  exit 1
fi

# Format
dart format --set-exit-if-changed .
if [ $? -ne 0 ]; then
  echo "Code not formatted. Run: dart format ."
  exit 1
fi

# Unit tests
flutter test
if [ $? -ne 0 ]; then
  echo "Tests failed"
  exit 1
fi

echo "All checks passed!"
```

### Conventional Commits

```
feat: add timer system with cleanup
fix: prevent negative time in score calculation
refactor: extract validation logic to utility class
docs: add edge cases to development guide
test: add race condition tests for leaderboard
chore: update dependencies

# Format: <type>: <description>
# Types: feat, fix, refactor, docs, test, chore, perf, style
```

---

## 6. Dependency Management

### The Supply Chain Attack Problem

**2025 npm ecosystem attack:** Popular packages (chalk, debug) were compromised. 2.6 billion weekly downloads affected.

### Protection Strategy

#### 1. Use Exact Versions (Not Ranges)

```yaml
# pubspec.yaml

# BAD: Allows automatic updates
dependencies:
  riverpod: ^2.0.0  # Any 2.x.x version

# GOOD: Exact version
dependencies:
  riverpod: 2.5.1  # Only this specific version
```

**Why?**
- Reproducible builds
- Supply chain attack protection
- "It worked yesterday" problem prevention

#### 2. Lock File is Sacred

```bash
# ALWAYS commit pubspec.lock
git add pubspec.lock
git commit -m "chore: update dependencies"

# NEVER use --no-shrinkwrap or delete lock file
```

#### 3. Audit Dependencies Regularly

```bash
# Check for known vulnerabilities
flutter pub outdated

# Update with caution
flutter pub upgrade --major-versions

# After update: test thoroughly
flutter test
```

---

## 7. DiagnozApp-Specific Security

### Timer Manipulation Prevention

> **Note:** For detailed timer edge cases and code examples, see `vcguide.md` Â§ Edge Case 1.

```javascript
// PROBLEM: Client timer can be manipulated via DevTools
// SOLUTION: Validate on server

// Cloud Function
exports.submitDiagnosis = functions.https.onCall(async (data, context) => {
  const { gameId, diagnosis, clientTimeSpent } = data;
  const userId = context.auth.uid;
  
  // Get game start time from Firestore
  const gameDoc = await admin.firestore()
    .collection('games')
    .doc(gameId)
    .get();
  
  const startTime = gameDoc.data().startTime.toDate();
  const serverTimeSpent = (Date.now() - startTime.getTime()) / 1000;
  
  // WHY: Validate server time (client time can be faked)
  if (serverTimeSpent > 120) {
    throw new functions.https.HttpsError(
      'deadline-exceeded',
      'Game time exceeded 120 seconds'
    );
  }
  
  // WHY: Check for timer manipulation
  const timeDiff = Math.abs(serverTimeSpent - clientTimeSpent);
  if (timeDiff > 5) {  // 5 second tolerance for network latency
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Timer tampering detected'
    );
  }
  
  // Process diagnosis...
});
```

### Pass System Security

```javascript
// PROBLEM: Client could fake remaining passes
// SOLUTION: Store passes in Firestore, validate on server

// Cloud Function
exports.usePass = functions.https.onCall(async (data, context) => {
  const { gameId } = data;
  
  return admin.firestore().runTransaction(async (transaction) => {
    const gameRef = admin.firestore().collection('games').doc(gameId);
    const gameDoc = await transaction.get(gameRef);
    
    const passesLeft = gameDoc.data().passesLeft;
    
    // WHY: Validate passes available
    if (passesLeft <= 0) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'No passes remaining'
      );
    }
    
    // WHY: Atomic decrement (prevent race condition)
    transaction.update(gameRef, {
      passesLeft: admin.firestore.FieldValue.increment(-1),
    });
    
    return { passesLeft: passesLeft - 1 };
  });
});
```

### Leaderboard Score Validation

> **Note:** For race condition prevention details, see `vcguide.md` Â§ Edge Case 4.

```javascript
// PROBLEM: Client could submit fake scores
// SOLUTION: Calculate score on server, not client

// Cloud Function
exports.completeGame = functions.https.onCall(async (data, context) => {
  const { gameId } = data;
  const userId = context.auth.uid;
  
  const gameDoc = await admin.firestore()
    .collection('games')
    .doc(gameId)
    .get();
  
  const gameData = gameDoc.data();
  
  // WHY: Recalculate score on server (don't trust client)
  let totalScore = 0;
  for (const caseResult of gameData.cases) {
    const timeLeft = caseResult.timeLeft;
    
    // Validate time
    if (timeLeft < 0 || timeLeft > 120) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid time value'
      );
    }
    
    // Calculate score using masterplan formula
    const caseScore = (timeLeft / 100) * 10;
    totalScore += caseScore;
  }
  
  // Update leaderboard atomically
  await admin.firestore()
    .collection('users')
    .doc(userId)
    .update({
      'stats.weeklyScore': admin.firestore.FieldValue.increment(totalScore),
    });
  
  return { totalScore };
});
```

---

## Summary: Top 15 Security Rules

1. Password change invalidates ALL sessions
2. Normalize phone numbers (E.164 format)
3. Validate every input (type, range, null)
4. Firestore Security Rules = mandatory (replaces SQL prepared statements)
5. Unicode/emoji validation for text fields
6. Interactive rebase for clean Git history
7. Conventional commits (feat/fix/refactor)
8. Never commit directly to main branch
9. Atomic operations for score updates (FieldValue.increment)
10. Rate limiting on SMS (3 per hour) and game start (20 per hour)
11. Exact versions in pubspec.yaml (no ^ or ~)
12. Always commit pubspec.lock
13. Cloud Functions for all write operations (games, leaderboards)
14. Backend validation for critical data (timer, score, passes)
15. Test edge cases (race conditions, duplicate submits)

---

## For Claude (AI Assistant)

**Security is NOT optional. Always:**
1. Validate inputs (type, range, null)
2. Use atomic operations for score updates
3. Backend validation for critical data
4. Rate limiting on expensive operations
5. Clean up resources (timers, listeners)
6. Firestore Security Rules enforced
7. Include "WHY" comments for security decisions

**Don't skip security to "move faster."**  
**Security vulnerabilities are discovered in production, not development.**

---

**End of Security Guide v2.1**

**For edge cases:** See `vcguide.md`  
**For data structure:** See `database_schema.md`  
**For game design:** See `masterplan.md`
