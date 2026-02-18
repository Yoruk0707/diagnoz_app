# DiagnozApp: Master Plan (Core Game Design)
**Version:** 2.3 (Lean)  
**Last Updated:** January 30, 2026  
**Target Platform:** Mobile (iOS & Android)  
**Primary Market:** Turkey (Medical Students)

> **Purpose:** This document defines WHAT we're building and WHY.  
> **For technical details:** See `database_schema.md`, `vcguide.md`, `ui_ux_design.md` *(to be created)*

---

## Ã°Å¸â€œâ€¹ Table of Contents

1. [Vision & Goals](#1-vision--goals)
2. [Core Game Loop](#2-core-game-loop)
3. [Game Modes](#3-game-modes)
4. [User System](#4-user-system)
5. [Leaderboard System](#5-leaderboard-system)
6. [Game Mechanics](#6-game-mechanics)
7. [MVP Scope](#7-mvp-scope)

---

## 1. Vision & Goals

### Vision Statement
The world's fastest, most competitive, and most educational medical diagnosis simulation for medical students and professionals.

### Target Feeling (Vibe)
**"Not taking an exam, but racing against time in a real emergency room."**
- Quick thinking
- Decisive action
- Adrenaline rush
- Learning through competition

### Primary Objectives

**Short-Term (3 months):**
- Launch MVP with Rush Mode + Leaderboard
- 10,000 registered users
- 70% D1 retention rate

**Medium-Term (6 months):**
- Add PvP and Zen modes
- University leaderboard competition
- 50,000 active users

**Long-Term (12 months):**
- Market leader in medical education games
- Partnerships with medical schools
- Monetization via premium features

### Success Metrics

**User Engagement:**
- Average session duration: 15 minutes
- Cases played per session: 5+
- Weekly active users: 40% of registered

**Educational Impact:**
- Users report improved diagnostic confidence
- Average score improvement over time
- 25% accuracy increase after 50 games

**Viral Growth:**
- University leaderboard drives competition
- Social sharing of high scores
- Organic word-of-mouth in medical student communities

---

## 2. Core Game Loop

### Overview
Every case follows this 3-step loop. This is the heart of the game.

```
Ã¢â€Å’Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€Â
Ã¢â€â€š  1. CASE PRESENTATION                        Ã¢â€â€š
Ã¢â€â€š     Ã¢â€ â€œ                                        Ã¢â€â€š
Ã¢â€â€š  2. PLAYER ACTION (Diagnose OR Request Test) Ã¢â€â€š
Ã¢â€â€š     Ã¢â€ â€œ                                        Ã¢â€â€š
Ã¢â€â€š  3. RESOLUTION (Correct/Wrong/Timeout)       Ã¢â€â€š
Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€Ëœ
     Ã¢â€ â€œ
  Next Case (or Game Over)
```

---

### Step 1: Case Presentation

**What the Player Sees:**
- **Patient Profile:** Age, Gender
- **Chief Complaint:** Main symptom (e.g., "Severe chest pain")
- **Vital Signs (optional):** BP, HR, Temp, RR, SpO2

**Example:**
```
Ã°Å¸â€˜Â¤ Patient: 45-year-old male
Ã°Å¸â€™Â¬ Complaint: "Severe chest pain for 2 hours, radiating to left arm"
Ã°Å¸â€œÅ  Vitals: BP 140/90, HR 95, Temp 37.2Ã‚Â°C, SpO2 98%
Ã¢ÂÂ±Ã¯Â¸Â Time: 120 seconds
```

**Design Goal:** Give just enough info to start thinking, but not enough to diagnose immediately. Force decision: "Do I need more info, or am I confident?"

---

### Step 2: Player Action

Player MUST choose one of two paths:

#### **Path A: Diagnose Immediately (High Risk, High Reward)**

**When to use:**
- Pattern recognition ("This is clearly a STEMI")
- Classic presentation
- High confidence

**Outcome if CORRECT:**
- Ã¢Å“â€¦ Maximum points (no time penalty from tests)
- Move to next case immediately
- Confidence boost

**Outcome if WRONG:**
- Ã¢ÂÅ’ Lose 1 pass
- If no passes left Ã¢â€ â€™ Game Over
- Score penalty

---

#### **Path B: Request Tests (Low Risk, Time Cost)**

**Available Test Categories:**
1. **Laboratory Tests**
   - CBC (Complete Blood Count)
   - Chemistry panel (BMP, CMP)
   - Cardiac markers (Troponin, BNP)
   - Coagulation (PT, PTT, INR)
   - Special (D-dimer, Lactate)

2. **Imaging**
   - X-ray (Chest, Abdomen)
   - CT scan
   - Ultrasound
   - MRI

3. **ECG/EKG**
   - 12-lead ECG
   - Rhythm strip

4. **Special Tests** (case-dependent)
   - Lumbar puncture
   - Biopsy
   - Bronchoscopy

**Cost:** Each test = **-10 seconds** from timer

**Result Display:**
- Text format for lab values
- Image format for imaging/ECG
- Results appear instantly (no waiting)

**Strategy:**
- Request only necessary tests
- Balance time cost vs information gain
- Think like a real doctor: "What would confirm/rule out my suspicion?"

---

### Step 3: Resolution

#### **If Diagnosis is CORRECT:**
1. Ã¢Å“â€¦ Green success animation
2. Show score for this case: `score = (timeLeft / 100) * 10`
3. Brief explanation of the diagnosis (optional)
4. Automatically load next case
5. Continue until:
   - All 5 cases completed (Victory!)
   - Timer runs out (Game Over)
   - Wrong diagnosis with no passes (Game Over)

#### **If Diagnosis is WRONG:**

**Rush Mode:**
- Ã¢ÂÅ’ Red error animation
- Deduct 1 pass
- Show: "Passes remaining: X"
- If passes remaining > 0:
  - Continue to next case
- If no passes left:
  - Game Over
  - Show final score
  - Option to play again or view leaderboard

**Zen Mode (Educational):**
- Ã¢ÂÅ’ Show "Incorrect" message
- Display "Why Wrong?" button
- Show:
  - Correct diagnosis
  - Differential diagnosis
  - Key findings that were missed
  - Link to medical literature
- No game over
- Player can retry or continue

#### **If Timer Expires (0 seconds):**

**Rush Mode:**
- Ã¢ÂÂ° Timeout animation
- Game Over
- Show final score (sum of completed cases)

**Zen Mode:**
- No penalty
- Show "Time expired" (informational)
- Player can continue without time pressure

---

## 3. Game Modes

### A. Rush Mode (Primary Competitive Mode)

**Objective:** Score maximum points without elimination

**Rules:**
- **Duration:** 120 seconds per case
- **Cases:** 5 random cases per game
- **Passes:** 2 total for entire game (not per case)
- **Test Cost:** Each test request = -10 seconds
- **Elimination:** Wrong diagnosis with no passes left = Game Over

**Scoring Formula:**
```
Case Score = (timeLeft / 100) * 10
Total Score = Sum of all case scores

Example:
- Case 1: 52s left Ã¢â€ â€™ 5.2 points
- Case 2: 78s left Ã¢â€ â€™ 7.8 points
- Case 3: 35s left Ã¢â€ â€™ 3.5 points
- Case 4: 61s left Ã¢â€ â€™ 6.1 points
- Case 5: 44s left Ã¢â€ â€™ 4.4 points
Total: 27.0 points

Maximum per case: 12.0 points (120s / 100 * 10)
Minimum per case: 0.0 points (0s left or timeout)
```

**Game Over Conditions:**
1. Timer expires (time = 0 on any case)
2. Wrong diagnosis with no passes remaining
3. Player quits voluntarily

**Victory Condition:**
- Complete all 5 cases
- Submit total score to leaderboard
- Compare with other players

**Target Audience:**
- Competitive players
- Medical students preparing for exams
- Doctors maintaining diagnostic skills

---

### B. Zen Mode (Educational/Practice)

**Objective:** Learn without pressure

**Key Differences from Rush:**
- Ã¢Å“â€¦ **No Timer:** Unlimited time per case
- Ã¢Å“â€¦ **No Scoring:** Points not calculated
- Ã¢Å“â€¦ **No Elimination:** Wrong answers don't end game
- Ã¢Å“â€¦ **Rich Feedback:**
  - Detailed explanation of correct diagnosis
  - Differential diagnosis list
  - Key clinical pearls
  - Links to PubMed/medical resources

**When to Use:**
- First-time players learning mechanics
- Studying specific medical conditions
- Reviewing mistakes from Rush mode
- Bedtime learning (no stress)

**Mode Switching:**
- Toggle switch on main screen: Rush Ã¢Å¸Â· Zen
- Instant transition
- No progress lost
- Can switch mid-game (Rush Ã¢â€ â€™ Zen only)

**Educational Features:**
- "Explain this case" button (shows full breakdown)
- "Show similar cases" (pattern recognition training)
- Case difficulty rating (Easy/Medium/Hard)
- Specialty tag (Cardiology, Neurology, etc.)

---

### C. PvP Mode (Multiplayer Duel) [Post-MVP]

**Objective:** 1v1 competitive match against friend or random player

**How It Works:**
1. **Challenge:**
   - Invite friend via link
   - OR join random matchmaking queue

2. **Match Setup:**
   - Both players select case count: 5, 7, or 10
   - System generates random case set
   - **Fairness:** Both get identical cases in identical order

3. **Gameplay:**
   - Both play simultaneously
   - Real-time score tracker shows opponent's progress
   - Standard Rush Mode rules apply

4. **Winner Determination:**
   - All cases completed Ã¢â€ â€™ highest total score wins
   - If one player eliminated Ã¢â€ â€™ opponent wins by default
   - Tie score Ã¢â€ â€™ faster average time wins

**Future Features (Post-Launch):**
- Ranked matchmaking with ELO
- Best-of-3 rounds
- Spectator mode (watch others play)
- Tournament brackets (monthly competition)

---

### D. Branch Mode (Specialty Filter) [Post-MVP]

**Objective:** Practice specific medical specialty

**How It Works:**
- Case filter on game start screen
- Select from dropdown: Mixed (default) or specific branch
- Only cases from selected specialty appear
- Same Rush/Zen rules apply

**Available Branches:**
- Ã°Å¸Å¡â€˜ Emergency Medicine
- Ã¢ÂÂ¤Ã¯Â¸Â Cardiology
- Ã°Å¸Â§Â  Neurology
- Ã°Å¸â€˜Â¶ Pediatrics
- Ã°Å¸â€Âª Surgery
- Ã°Å¸Â¦Â  Infectious Disease
- Ã°Å¸Â©Âº Internal Medicine
- Ã°Å¸Â«Â Pulmonology
- More... (expandable)

**Use Cases:**
- Medical student on cardiology rotation
- Resident preparing for specialty boards
- Practitioner maintaining specialty knowledge
- Focused study session

---

## 4. User System

### Authentication

**Method:** SMS Verification (Phone Number Only)

**Why SMS?**
- Ã¢Å“â€¦ Fast onboarding (no email verification wait)
- Ã¢Å“â€¦ Low friction (no password to remember)
- Ã¢Å“â€¦ Secure (SMS OTP)
- Ã¢Å“â€¦ Unique identity (one phone = one account)
- Ã¢Å“â€¦ Common in Turkey (target market)

**Authentication Flow:**
```
1. User enters phone number (+905551234567)
2. System sends 6-digit SMS code
3. User enters code
4. System validates code
5. If valid:
   - Create user account (if new)
   - Issue JWT token (7-day expiry)
   - Issue refresh token (30-day expiry)
6. User logged in
```

**Security Measures:**
- Rate limiting: Max 3 SMS per hour per phone
- Code expiry: 5 minutes
- Max attempts: 3 tries per code
- Block suspicious numbers (fraud detection)

**Token Management:**
- Access token: 7-day expiry (short-lived)
- Refresh token: 30-day expiry (stored securely)
- Auto-refresh when access token expires
- Logout: Invalidate both tokens

---

### User Profile

**Required Fields:**
- Phone number (unique identifier, never shown publicly)
- Display name (shown on leaderboards)

**Optional Fields:**
- Title: Student, Dr., Specialist, Resident
- University/Institution
- Graduation year
- Profile photo
- Bio (short description)

**Privacy Settings:**
- Display name visibility: Public / Friends Only / Anonymous
- University visibility: Public / Private
- Profile photo: Public / Private
- Game history: Public / Private

**Profile Stats (Auto-Generated):**
- Total games played
- Total cases solved
- Average score per case
- Best score (single game)
- Total play time
- Current win streak
- Favorite specialty (most played)

---

## 5. Leaderboard System

### Leaderboard Types

#### **1. Global Weekly Leaderboard**
- All users worldwide
- Tracks scores from Monday 00:00 to Sunday 23:59 (UTC+3 Turkey time)
- Resets every Monday at 00:00
- Displays top 100 players

**Why Weekly?**
- Fresh competition every week
- Everyone has a chance to climb
- Prevents stagnation (unlike all-time leaderboard)
- Encourages weekly engagement

---

#### **2. Global Monthly Leaderboard**
- All users worldwide
- Tracks scores from 1st 00:00 to last day 23:59 of month
- Resets on 1st of each month at 00:00
- Displays top 500 players

**Why Monthly?**
- Longer competition window
- More stable rankings
- Seasonal goals (e.g., "Top 100 this month")

---

#### **3. University Leaderboard** [Post-MVP]
- Separate tab in leaderboard screen
- Only users who entered university name
- Shows top universities by total score
- Individual contributions shown

**University Scoring:**
```
University Total Score = Sum of top 50 students' scores
Minimum qualifying students: 10
```

**Why University Leaderboard?**
- Drives viral growth (university pride)
- Social pressure to contribute
- Community building
- Potential partnerships with medical schools

**Example Display:**
```
Ã°Å¸Ââ€  Top Universities (Weekly)

1. Ã°Å¸Â¥â€¡ Istanbul University      12,450 pts (87 students)
2. Ã°Å¸Â¥Ë† Hacettepe University     11,230 pts (65 students)
3. Ã°Å¸Â¥â€° Ankara University        10,890 pts (72 students)
```

---

### Scoring Rules

**Individual Weekly Score:**
```
Weekly Score = Sum of all game scores from Monday-Sunday
Game Score = Sum of 5 case scores
Case Score = (timeLeft / 100) * 10

Example:
- Monday: 3 games Ã¢â€ â€™ 24.5 + 31.2 + 28.0 = 83.7 pts
- Wednesday: 2 games Ã¢â€ â€™ 35.1 + 29.3 = 64.4 pts
- Friday: 4 games Ã¢â€ â€™ 27.8 + 33.2 + 30.5 + 26.1 = 117.6 pts
Weekly Total: 265.7 pts
```

**Individual Monthly Score:**
- Same logic as weekly, but accumulated over entire month

**Leaderboard Display Format:**
```
Rank | Player Name    | Score  | Games | Avg/Game
-----|----------------|--------|-------|----------
1    | Ã°Å¸Ââ€  Dr.Ahmet    | 245.6  | 52    | 4.7
2    | Ã°Å¸Â¥Ë† MedStudent  | 238.2  | 48    | 5.0
3    | Ã°Å¸Â¥â€° FutureDr    | 232.1  | 45    | 5.2
...
42   | Ã°Å¸â€™Å¡ You         | 156.3  | 28    | 5.6
```

**Visual Elements:**
- Top 3: Trophy icons
- Current user: Highlighted row with scroll-to
- University badge next to name (if enabled)

---

### Tie-Breaking Rules

If two players have identical scores:
1. Higher number of games played wins (more activity)
2. If still tied: Better average score per game wins
3. If still tied: Older account wins (loyalty)

---

## 6. Game Mechanics

### Timer System

**Per-Case Timer:**
- Starts at 120 seconds
- Counts down to 0
- Displayed prominently at top of screen
- Visual warnings:
  - 120-60s: Green (calm)
  - 59-30s: Yellow (caution)
  - 29-0s: Red + pulsing animation (urgency)

**Timer Behavior:**
- **Test Request:** Instantly deduct 10 seconds
- **Minimum:** Timer cannot go below 0
- **Pause:** Not possible (simulates real emergency pressure)
- **Game Over:** When timer reaches 0 on any case

**Important Note:** Timer is for UI pressure only. Backend validates actual elapsed time for security. See `vcguide.md` Â§ Edge Case 1 for implementation details.

---

### Pass System

**Overview:**
- Players get 2 passes per game (total, not per case)
- Pass = one "free" wrong answer without game over
- Used automatically when wrong diagnosis submitted

**Pass Usage:**
```
Start: Ã¢ÂÂ¤Ã¯Â¸ÂÃ¢ÂÂ¤Ã¯Â¸Â (2 passes)
Wrong diagnosis on Case 2: Ã¢ÂÂ¤Ã¯Â¸ÂÃ°Å¸â€“Â¤ (1 pass left)
Wrong diagnosis on Case 4: Ã°Å¸â€“Â¤Ã°Å¸â€“Â¤ (0 passes left)
Wrong diagnosis on Case 5: Ã¢ËœÂ Ã¯Â¸Â GAME OVER
```

**Cannot:**
- Buy more passes mid-game
- Save passes for next game
- Transfer passes to other players

**Strategic Considerations:**
- Early game: More willing to guess (have passes as backup)
- Late game: More cautious (no safety net)
- Risk/reward calculation: "Is it worth guessing now?"

---

### Test Request System

**Test Categories & Cost:**
| Category | Time Cost | Examples |
|----------|-----------|----------|
| Laboratory | -10s | CBC, Troponin, D-dimer |
| Imaging | -10s | X-ray, CT, Ultrasound |
| ECG/EKG | -10s | 12-lead ECG |
| Special | -10s | Lumbar puncture, Biopsy |

**Important Rules:**
1. **Idempotency:** Same test requested twice = charged once
2. **Minimum Time:** Tests cannot reduce timer below 0
3. **Instant Results:** No waiting/loading time (game design choice)
4. **Multiple Tests:** Can request multiple tests before diagnosing

**Example Scenario:**
```
Start: 120s
Request Lab (CBC): 110s
Request ECG: 100s
Request Imaging (X-ray): 90s
Request Lab (Troponin): 90s (same test = no charge)
Diagnose: 90s left Ã¢â€ â€™ 9.0 points if correct
```

---

### Diagnosis Submission

**Input Method:**
- Autocomplete search box
- Database of ~1000 common diagnoses
- Fuzzy search enabled
- Example: User types "myoc" Ã¢â€ â€™ shows "Myocardial Infarction"

**Submission Flow:**
1. Player types diagnosis
2. Selects from autocomplete suggestions
3. Confirms selection
4. Backend validates:
   - Is diagnosis in valid list?
   - Has time expired?
   - Has this case already been submitted? (idempotency)
5. Return result: Correct / Wrong / Invalid

**Feedback:**
- Ã¢Å“â€¦ Correct: Green animation + score display
- Ã¢ÂÅ’ Wrong: Red animation + pass deduction
- Ã¢ÂÂ° Timeout: Time's up message

---

### Case Selection Algorithm

**Random Selection (Rush Mode):**
- Select 5 random cases from database
- Constraints:
  - No duplicate cases in same game
  - Mix of difficulties (2 easy, 2 medium, 1 hard)
  - Mix of specialties (if "Mixed" mode selected)
- Seeded random for PvP (both players get same cases)

**Branch Filter (Branch Mode):**
- Select 5 random cases from chosen specialty
- Same difficulty distribution

**Case Difficulty Rating:**
- Easy: Common presentations, classic findings
- Medium: Requires test results to diagnose
- Hard: Atypical presentation, requires advanced reasoning

---

## 7. MVP Scope (Phase 1)

### Must Have (Launch Blockers)

These features MUST be completed before launch:

Ã¢Å“â€¦ **Authentication**
- SMS verification
- Phone number login
- JWT token management

Ã¢Å“â€¦ **Rush Mode**
- 5-case game loop
- 120-second timer per case
- Test request system
- Diagnosis validation
- Pass system (2 per game)

Ã¢Å“â€¦ **Scoring System**
- Case score calculation: `(timeLeft / 100) * 10`
- Total score summation
- Score persistence

Ã¢Å“â€¦ **Weekly Leaderboard**
- Display top 100 players
- Auto-reset every Monday
- User's rank highlighted
- Scroll to current user

Ã¢Å“â€¦ **Case Database**
- Minimum 50 curated cases
- Mixed specialties (cardiology, neurology, emergency)
- Mix of difficulties
- High-quality medical accuracy

Ã¢Å“â€¦ **Basic Profile**
- Display name
- Phone number (hidden)
- View personal stats
- Game history (last 10 games)

---

### Should Have (Post-Launch Week 1-2)

These features enhance the MVP but aren't launch blockers:

Ã¢ÂÂ³ **Zen Mode**
- Untimed practice mode
- Educational feedback
- Retry mechanism

Ã¢ÂÂ³ **Monthly Leaderboard**
- Same logic as weekly
- Resets on 1st of month
- Top 500 display

Ã¢ÂÂ³ **Enhanced Profile**
- Profile photo upload
- Bio/description
- University affiliation
- Title/role selection

Ã¢ÂÂ³ **Game History Details**
- Full replay of past games
- Case-by-case breakdown
- Mistakes review

Ã¢ÂÂ³ **Search & Filter**
- Search leaderboard by name
- Filter by university
- Sort by different metrics

---

### Nice to Have (Phase 2 - Future)

These features are planned but not immediate priority:

Ã°Å¸â€Â® **PvP Mode**
- 1v1 matchmaking
- Friend challenges
- Real-time score tracking

Ã°Å¸â€Â® **Branch Mode**
- Specialty filter
- 8-10 medical branches

Ã°Å¸â€Â® **University Leaderboard**
- Team-based competition
- University rankings
- Contribution tracking

Ã°Å¸â€Â® **Achievement System**
- Badges for milestones
- Unlock special cases
- Gamification elements

Ã°Å¸â€Â® **Daily Challenges**
- Special bonus cases
- Extra points opportunity
- Limited-time events

Ã°Å¸â€Â® **Social Features**
- Share high scores
- Challenge friends
- Compare stats

Ã°Å¸â€Â® **Monetization**
- Premium cases (rare diseases)
- Remove ads
- Exclusive themes

---

## Development Priorities

### Phase 1 (Weeks 1-4): MVP Core
Focus: Get the core game loop working perfectly
- Authentication
- Rush Mode (5 cases)
- Basic leaderboard
- 50 cases

### Phase 2 (Weeks 5-6): Polish
Focus: User experience improvements
- Zen Mode
- Enhanced UI/UX
- Animations
- Sound effects

### Phase 3 (Weeks 7-8): Social
Focus: Viral growth features
- University leaderboard
- Social sharing
- Referral system

### Phase 4 (Weeks 9-12): Advanced Features
Focus: Retention and engagement
- PvP Mode
- Branch Mode
- Achievement system
- Daily challenges

---

## Success Criteria

**Week 1 Post-Launch:**
- 1,000 registered users
- 60% D1 retention
- Average 3 games per user
- <5% crash rate

**Month 1 Post-Launch:**
- 10,000 registered users
- 40% D7 retention
- Average 15 games per user
- Leaderboard engagement: 30%

**Month 3 Post-Launch:**
- 50,000 registered users
- 30% D30 retention
- User-reported educational value: 4.5/5
- Partnership with 3+ medical schools

---

## Design Philosophy

**Core Principles:**

1. **Speed First**
   - Every interaction should feel instant
   - Loading times: <2 seconds
   - No unnecessary animations blocking flow

2. **Learn by Doing**
   - No long tutorials
   - Jump straight into game
   - Learn mechanics through play

3. **Fair Competition**
   - Same cases for all players
   - No pay-to-win mechanics
   - Skill-based ranking

4. **Educational Value**
   - Medically accurate cases
   - Evidence-based explanations
   - Links to reputable sources

5. **Respect User Time**
   - Game sessions: 10-15 minutes
   - Can pause between cases
   - Progress saved automatically

---

## References & Related Documents

- **Database Schema:** See `database_schema.md`
- **Edge Cases & Best Practices:** See `vcguide.md`
- **Security Guidelines:** See `vcsecurity.md`
- **Development Workflow:** See `development_workflow.md`
- **UI/UX Design:** See `ui_ux_design.md` *(to be created)*

---

**End of Master Plan v2.3**

This document focuses on WHAT we're building and WHY.  
For HOW to build it (technical implementation), see the reference documents above.

**Next Steps:**
1. Review and approve this master plan
2. Read `database_schema.md` for data structure
3. Read `ui_ux_design.md` for visual design
4. Begin development with `development_workflow.md` as guide

**Questions? Feedback? Open an issue in the project repository.**
