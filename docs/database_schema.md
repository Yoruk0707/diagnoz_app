# DiagnozApp: Database Schema
**Version:** 1.3
**Last Updated:** February 20, 2026
**Database:** Cloud Firestore (Firebase)  

> **Purpose:** Canonical data structure definitions for development.  
> **For Claude:** Use these exact schemas when writing Firestore code.

---

## Collections Overview

**5 Main Collections:**
1. `users/` - User profiles & stats
2. `games/` - Game sessions & history
3. `cases/` - Medical case library
4. `leaderboard_weekly/` - Weekly rankings (resets Monday)
5. `leaderboard_monthly/` - Monthly rankings (resets 1st)

---

## Schema Definitions

### users/{userId}

```typescript
interface User {
  // Identity
  phoneNumber: string;           // E.164 format: "+905551234567"
  displayName: string;            // 3-20 chars, public
  createdAt: Timestamp;
  
  // Optional Profile
  title?: "Student" | "Dr." | "Specialist" | "Resident";
  university?: string;
  profilePhotoUrl?: string;
  
  // Stats (auto-updated)
  stats: {
    totalGamesPlayed: number;
    totalCasesSolved: number;
    averageScore: number;         // totalPoints / totalCases
    weeklyScore: number;          // Resets every Monday
    monthlyScore: number;         // Resets every 1st
    bestScore: number;            // Single game max
    currentStreak: number;        // Consecutive days played
  };
  
  // Privacy
  privacy: {
    showUniversity: boolean;
    showGameHistory: boolean;
  };
}
```

**Indexes:**
- `phoneNumber` (ASC) - for login
- `stats.weeklyScore` (DESC) - for leaderboard
- `stats.monthlyScore` (DESC) - for leaderboard

**Security:**
```javascript
allow read: if true;
allow create: if request.auth.uid == userId;
allow update: if request.auth.uid == userId;
allow delete: if false;
```

---

### games/{gameId}

```typescript
interface Game {
  // Metadata
  userId: string;                 // ref: users/{userId}
  mode: "rush" | "zen" | "pvp" | "branch";
  status: "in_progress" | "completed" | "abandoned" | "timeout";
  startTime: Timestamp;
  endTime: Timestamp;
  
  // Results
  totalScore: number;             // Sum of case scores
  passesLeft: number;             // 0-2
  casesCompleted: number;         // 1-5
  totalCases: number;             // Always 5 (for now)
  
  // Case Details
  cases: CaseResult[];
}

interface CaseResult {
  caseId: string;                 // ref: cases/{caseId}
  startTime: Timestamp;
  endTime: Timestamp;
  testsRequested: string[];       // ["lab_cbc", "imaging_chest_xray", "ecg_12_lead"]
  diagnosis: string;
  isCorrect: boolean;
  timeSpent: number;              // seconds
  timeLeft: number;               // seconds remaining
  score: number;                  // Formula: (timeLeft / 100) * 10
}
```

**Indexes:**
- `userId` + `startTime` (DESC) - for game history
- `startTime` (ASC) - for analytics

**Security:**
```javascript
allow read: if request.auth.uid == resource.data.userId;
allow create: if request.auth.uid == request.resource.data.userId;
allow update, delete: if false;  // Immutable history
```

---

### cases/{caseId}

```typescript
// Specialty types (matches masterplan.md Branch Mode)
type Specialty = 
  | "emergency"       // Ã°Å¸Å¡â€˜ Emergency Medicine
  | "cardiology"      // Ã¢ÂÂ¤Ã¯Â¸Â Cardiology
  | "neurology"       // Ã°Å¸Â§Â  Neurology
  | "pediatrics"      // Ã°Å¸â€˜Â¶ Pediatrics
  | "surgery"         // Ã°Å¸â€Âª Surgery
  | "infectious"      // Ã°Å¸Â¦Â  Infectious Disease
  | "internal"        // Ã°Å¸Â©Âº Internal Medicine
  | "pulmonology"     // Ã°Å¸Â«Â Pulmonology
  | "gastroenterology"
  | "nephrology"
  | "endocrinology"
  | "psychiatry"
  | "dermatology"
  | "orthopedics";

interface Case {
  // ============================================
  // FIELD VISIBILITY BY GAME MODE
  // ============================================
  // | Field           | Rush Mode | Zen Mode |
  // |-----------------|-----------|----------|
  // | patientProfile  | âœ… Always  | âœ… Always |
  // | vitals          | âœ… Always  | âœ… Always |
  // | history         | âŒ Hidden  | âœ… Shown  |
  // | physicalExam    | âŒ Hidden  | âœ… Shown  |
  // | explanation     | âŒ Hidden  | âœ… Shown  |
  // | keyFindings     | âŒ Hidden  | âœ… Shown  |
  // | references      | âŒ Hidden  | âœ… Shown  |
  // ============================================
  
  // Metadata
  specialty: Specialty;
  difficulty: "easy" | "medium" | "hard";
  isActive: boolean;
  
  // Presentation
  patientProfile: {
    age: number;
    gender: "male" | "female" | "other";
    chiefComplaint: string;
  };
  
  vitals: {
    bp: string;                   // "140/90"
    hr: number;
    temp: number;
    rr: number;
    spo2: number;
  };
  
  // Medical History (Optional - for educational depth)
  history?: {
    medicalHistory: string[];     // ["Hipertansiyon", "Tip 2 DM"]
    medications: string[];        // ["Metformin 1000mg 2x1"]
    socialHistory?: {
      smoking?: string;           // "30 paket-yÄ±l"
      alcohol?: string;           // "Sosyal iÃ§ici"
    };
    familyHistory?: string;       // "BabasÄ± 52 yaÅŸÄ±nda MI geÃ§irmiÅŸ"
  };
  
  // Physical Examination (Optional - for educational depth)
  physicalExam?: {
    general?: string;             // "AnksiyÃ¶z, soluk, terli"
    cardiovascular?: string;      // "S1-S2 doÄŸal, S4 gallop"
    respiratory?: string;         // "Bilateral ralleri"
    abdomen?: string;             // "YumuÅŸak, hassasiyet yok"
    neurological?: string;        // "GKS 15, fokal defisit yok"
    skin?: string;                // "Turgor doÄŸal, dÃ¶kÃ¼ntÃ¼ yok"
  };
  
  // Tests - Categories match masterplan.md
  availableTests: {
    lab: LabTest[];
    imaging: ImagingTest[];
    ecg: EcgTest[];               // Separate category per masterplan.md
    special: SpecialTest[];
  };
  
  testResults: {
    [testId: string]: TestResult;
  };
  
  // Answer
  correctDiagnosis: string;
  alternativeDiagnoses: string[];
  
  // Educational
  explanation: string;
  keyFindings: string[];
  references: string[];
  
  // Analytics (auto-updated)
  analytics: {
    timesPresented: number;
    timesSolved: number;
    averageTimeSpent: number;
    mostRequestedTest: string;
  };
  
  // Content Metadata (Optional - for admin/content team)
  _metadata?: {
    version: string;              // "1.0"
    createdAt: string;            // "2026-01-30"
    author: string;               // "DiagnozApp Medical Content Team"
    reviewedBy?: string;          // "Kardiyoloji UzmanÄ±"
    icd10?: string;               // "I21.0" (for reference)
    difficultyRationale?: string; // Why this difficulty level
  };
}

// ============================================
// TEST TYPE DEFINITIONS (Complete List)
// ============================================

// Laboratory Tests
type LabTest = 
  | "cbc"              // Complete Blood Count
  | "bmp"              // Basic Metabolic Panel
  | "cmp"              // Comprehensive Metabolic Panel
  | "troponin"         // Cardiac Troponin
  | "bnp"              // B-type Natriuretic Peptide
  | "pt_ptt_inr"       // Coagulation Panel
  | "d_dimer"          // D-dimer
  | "lactate"          // Lactate
  | "lipase"           // Lipase/Amylase
  | "lfts"             // Liver Function Tests
  | "ua"               // Urinalysis
  | "urine_culture"    // Urine Culture
  | "blood_culture"    // Blood Culture
  | "abg"              // Arterial Blood Gas
  | "tsh"              // Thyroid Panel
  | "hba1c"            // Hemoglobin A1c
  | "crp"              // C-Reactive Protein
  | "procalcitonin"    // Procalcitonin
  | "csf_analysis";    // CSF Analysis (if LP done)

// Imaging Tests
type ImagingTest = 
  | "chest_xray"       // Chest X-ray
  | "abdominal_xray"   // Abdominal X-ray
  | "ct_head"          // CT Head (without contrast)
  | "ct_head_contrast" // CT Head (with contrast)
  | "ct_chest"         // CT Chest
  | "ct_abdomen"       // CT Abdomen/Pelvis
  | "ct_angio"         // CT Angiography
  | "mri_brain"        // MRI Brain
  | "mri_spine"        // MRI Spine
  | "ultrasound_abdomen"  // Abdominal Ultrasound
  | "ultrasound_pelvic"   // Pelvic Ultrasound
  | "echocardiogram"      // Echocardiography
  | "doppler_venous"      // Venous Doppler (DVT)
  | "doppler_carotid";    // Carotid Doppler

// ECG/EKG Tests (Separate category per masterplan.md)
type EcgTest = 
  | "ecg_12_lead"      // 12-lead ECG
  | "rhythm_strip";    // Rhythm Strip

// Special/Invasive Tests
type SpecialTest = 
  | "lumbar_puncture"  // Lumbar Puncture
  | "paracentesis"     // Paracentesis
  | "thoracentesis"    // Thoracentesis
  | "arthrocentesis"   // Joint Aspiration
  | "eeg"              // Electroencephalogram
  | "emg"              // Electromyography
  | "bronchoscopy"     // Bronchoscopy
  | "endoscopy"        // Upper GI Endoscopy
  | "colonoscopy";     // Colonoscopy

// Test Result Structure
interface TestResult {
  type: "text" | "image" | "both";
  value?: string;                 // For lab values: "Troponin: 2.5 ng/mL"
  interpretation?: string;        // "Elevated - indicates myocardial injury"
  imageUrl?: string;              // For imaging/ECG results
  findings?: string;              // "ST elevation in V1-V4"
  isAbnormal: boolean;
}
```

**Indexes:**
- `specialty` + `difficulty` (ASC) - for case selection
- `isActive` (ASC) - for filtering

**Security:**
```javascript
allow read: if true;              // Public (needed for gameplay)
allow write: if false;            // Admin-only via Cloud Functions
```

---

### leaderboard_weekly/{userId_wWW_YYYY}

Document ID format: `{userId}_w{weekNumber}_${year}`  
Example: `abc123_w04_2026`

```typescript
interface LeaderboardEntry {
  userId: string;
  displayName: string;            // Denormalized from users
  university: string;             // Denormalized from users
  score: number;
  casesPlayed: number;
  gamesPlayed: number;
  weekNumber: number;             // 1-52
  year: number;
  lastUpdated: Timestamp;
}
```

**Indexes:**
- `weekNumber` + `year` + `score` (DESC) - for ranking

**Security:**
```javascript
allow read: if true;
allow write: if false;            // Updated via Cloud Functions only
```

---

### leaderboard_monthly/{userId_mMM_YYYY}

Document ID format: `{userId}_m{month}_${year}`  
Example: `abc123_m01_2026`

```typescript
interface LeaderboardEntry {
  userId: string;
  displayName: string;
  university: string;
  score: number;
  casesPlayed: number;
  gamesPlayed: number;
  month: number;                  // 1-12
  year: number;
  lastUpdated: Timestamp;
}
```

**Indexes:**
- `month` + `year` + `score` (DESC)

**Security:**
```javascript
allow read: if true;
allow write: if false;
```

---

## Query Patterns

### Get User by Phone

```dart
final snapshot = await db
  .collection('users')
  .where('phoneNumber', isEqualTo: phoneNumber)
  .limit(1)
  .get();
```

### Get Weekly Leaderboard Top 50

```dart
final weekNumber = _getWeekNumber();
final year = DateTime.now().year;

final snapshot = await db
  .collection('leaderboard_weekly')
  .where('weekNumber', isEqualTo: weekNumber)
  .where('year', isEqualTo: year)
  .orderBy('score', descending: true)
  .limit(50)
  .get();
```

### Get User's Game History

```dart
final snapshot = await db
  .collection('games')
  .where('userId', isEqualTo: userId)
  .orderBy('startTime', descending: true)
  .limit(10)
  .get();
```

### Select Random Cases for Game

```dart
// Firestore doesn't support ORDER BY RANDOM()
// Use: Pre-selected random IDs from Cloud Function

final caseIds = await cloudFunction('generateGameCases', {
  'mode': 'rush',
  'count': 5,
  'seed': gameId,  // For PvP fairness
});

final cases = await db.getAll(
  caseIds.map((id) => db.collection('cases').doc(id))
);
```

### Submit Game (Atomic Update)

```dart
final batch = db.batch();

// 1. Create game document
final gameRef = db.collection('games').doc();
batch.set(gameRef, gameData);

// 2. Update user stats
final userRef = db.collection('users').doc(userId);
batch.update(userRef, {
  'stats.totalGamesPlayed': FieldValue.increment(1),
  'stats.weeklyScore': FieldValue.increment(gameScore),
  'stats.monthlyScore': FieldValue.increment(gameScore),
});

// 3. Update weekly leaderboard
final weekDocId = '${userId}_w${weekNumber}_$year';
final weekRef = db.collection('leaderboard_weekly').doc(weekDocId);
batch.set(weekRef, {
  'userId': userId,
  'score': FieldValue.increment(gameScore),
  'casesPlayed': FieldValue.increment(casesCompleted),
  'gamesPlayed': FieldValue.increment(1),
  // ... other fields
}, SetOptions(merge: true));

// 4. Update monthly leaderboard (similar)
// ...

await batch.commit();
```

---

## Data Constraints

### Size Limits
- Document max: 1 MB
- Array max: 10,000 elements
- Field name max: 1,500 bytes
- String field max: 1,048,487 bytes

### Query Limits
- Max results: 10,000 documents per query
- Offset max: No hard limit, but slow (use pagination cursors)
- Composite index max: 200 fields

### Cost (per operation)
- Read: $0.36 / 100K
- Write: $0.18 / 100K
- Delete: $0.02 / 100K
- Storage: $0.18 / GB / month

---

## Denormalization Strategy

### Why Denormalize displayName in Leaderboards?

**Normalized (don't do this):**
```
Leaderboard query: 50 reads
User profile queries: 50 Ãƒâ€” 1 = 50 reads
Total: 100 reads
```

**Denormalized (our approach):**
```
Leaderboard query: 50 reads (includes displayName)
Total: 50 reads
```

**Trade-off:**
- When displayName changes: Must update all leaderboard entries (2 extra writes)
- Frequency: ~1% of users per month
- Leaderboard reads: 1000+ per day
- **Savings: 50% read cost reduction**

### When to Denormalize?

**Denormalize IF:**
- Read frequency >> Write frequency (10:1 or more)
- Data rarely changes (displayName, university)
- Join cost is high (multiple collections)

**Don't Denormalize IF:**
- Data changes frequently
- Data is large (>1KB per field)
- Consistency is critical (financial data)

---

## Atomic Operations

### Why Use Batch Writes?

**Without Batch:**
```dart
await createGame();        // Success
await updateUserStats();   // Fails Ã¢â€ â€™ Inconsistent state!
await updateLeaderboard(); // Never runs
```

**With Batch:**
```dart
final batch = db.batch();
batch.set(gameRef, gameData);
batch.update(userRef, statsUpdate);
batch.set(leaderboardRef, leaderboardUpdate);
await batch.commit();      // All or nothing
```

**Use Cases:**
- Game submission (game + user + leaderboard)
- Pass usage (game state + user stats)
- Multi-document updates that must stay consistent

---

## Security Rules (Production)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuth() {
      return request.auth != null;
    }
    
    function isOwner(uid) {
      return request.auth.uid == uid;
    }
    
    match /users/{userId} {
      allow read: if true;
      allow create: if isAuth() && isOwner(userId);
      allow update: if isAuth() && isOwner(userId);
      allow delete: if false;
    }
    
    match /games/{gameId} {
      allow read: if isAuth() && isOwner(resource.data.userId);
      allow create: if isAuth() && isOwner(request.resource.data.userId);
      allow update, delete: if false;
    }
    
    match /cases/{caseId} {
      allow read: if true;
      allow write: if false;
    }
    
    match /leaderboard_weekly/{docId} {
      allow read: if true;
      allow write: if false;
    }
    
    match /leaderboard_monthly/{docId} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

**Key Rules:**
1. Users can read all profiles (for leaderboard display)
2. Users can only edit their own profile
3. Games are write-once (immutable history)
4. Cases are read-only (admin-only updates via Cloud Functions)
5. Leaderboards are read-only (updated by Cloud Functions)

---

## Caching Strategy

### Client-Side Cache (Hive)

**Cache these collections:**
- `cases/` Ã¢â€ â€™ Store 20 most recent cases locally
- `users/{currentUser}` Ã¢â€ â€™ Store own profile
- `leaderboard_weekly` top 50 Ã¢â€ â€™ Refresh every 5 minutes

**Don't cache:**
- `games/` Ã¢â€ â€™ History is dynamic
- Real-time leaderboard updates Ã¢â€ â€™ Use snapshot listeners

**Hive Structure:**
```dart
@HiveType(typeId: 0)
class CachedCase {
  @HiveField(0) String caseId;
  @HiveField(1) Map<String, dynamic> data;
  @HiveField(2) DateTime cachedAt;
}

// Cache expiry: 7 days
// Rotation: Load new cases weekly
```

---

## Migration Strategy

### Adding New Field to User

**Bad (breaks existing code):**
```dart
// Suddenly add required field
interface User {
  email: string;  // NEW - breaks old documents!
}
```

**Good (backward compatible):**
```dart
interface User {
  email?: string;  // Optional - old docs still valid
}

// Then gradually backfill via Cloud Function
```

### Changing Field Type

**Can't do:**
- String Ã¢â€ â€™ Number (Firestore doesn't support schema changes)

**Must do:**
1. Add new field: `scoreV2: number`
2. Migrate data via Cloud Function
3. Update code to read `scoreV2`
4. After 100% migration, remove old field

---

## Analytics & Monitoring

### Key Metrics to Track

**Firestore Usage:**
- Reads per day (quota: 50K free)
- Writes per day (quota: 20K free)
- Storage size (quota: 1GB free)

**Query Performance:**
- Leaderboard query time (<500ms)
- Game submission time (<1s)
- Case load time (<200ms)

**Data Quality:**
- Orphaned documents (games without users)
- Missing indexes (query failures)
- Duplicate entries (leaderboard)

**Monitoring Tools:**
- Firebase Console Ã¢â€ â€™ Usage tab
- Cloud Functions logs
- Crashlytics for client errors

---

## Troubleshooting

### Common Issues

**1. "Index required" error**
```
Error: The query requires an index.
```
**Solution:** Click error link Ã¢â€ â€™ auto-creates index (wait 5 min)

---

**2. "Document size exceeded" error**
```
Error: Document exceeds 1 MB limit
```
**Solution:** Use subcollections or split into multiple documents

---

**3. Race condition on score update**
```
User A: read score=100, write score=150
User B: read score=100, write score=180
Result: 180 (User A's update lost!)
```
**Solution:** Use `FieldValue.increment()` for atomic updates

---

**4. Slow leaderboard query**
```
Query takes >5 seconds
```
**Solution:** 
- Check if index exists
- Reduce limit (50 instead of 500)
- Implement pagination
- Cache results

---

## Reference

**For security:** See `vcsecurity.md`  
**For edge cases:** See `vcguide.md`  
**For game design:** See `masterplan.md`

---

**End of Schema v1.1**
