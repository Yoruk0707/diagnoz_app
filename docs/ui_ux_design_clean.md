# DiagnozApp: UI/UX Design Specification
**Version:** 1.1  
**Last Updated:** January 30, 2026  
**Design Philosophy:** Clinical Precision  
**Target:** Turkish Medical Students

> **Purpose:** Complete UI/UX specification with all states, edge cases, and technical implementation notes.  
> **For developers:** Every screen includes 5 states + edge cases + performance notes.  
> **For game design:** See `masterplan.md`

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Design System](#2-design-system)
3. [Component Library](#3-component-library)
4. [Screen Specifications](#4-screen-specifications)
5. [Navigation Flow](#5-navigation-flow)
6. [Animation Guidelines](#6-animation-guidelines)
7. [Error Handling Patterns](#7-error-handling-patterns)
8. [Accessibility](#8-accessibility)
9. [Performance Checklist](#9-performance-checklist)
10. [Technical Implementation Notes](#10-technical-implementation-notes)

---

## 1. Design Philosophy

### Vision: "Clinical Precision"

**NOT** a candy-colored game app.  
**YES** a modernized, fast, competitive hospital software feel.

```
+-------------------------------------------------------------+
|  "Acil Servis Monitoru" havasi                              |
|  Profesyonel, guvenilir, hizli                              |
|  Tip ogrencilerinin gece calismasina uygun                  |
+-------------------------------------------------------------+
```

### Core Principles

1. **Sterile & Clean:** No unnecessary decorations
2. **Speed First:** Every interaction feels instant
3. **Trust:** Professional blue palette inspires confidence
4. **Focus:** One primary action per screen
5. **Clarity:** Information hierarchy is crystal clear

### Target User Context

- **When:** Late night study sessions (dark mode essential)
- **Where:** Mobile phone, often one-handed
- **Mood:** Focused, competitive, time-pressured
- **Need:** Quick feedback, clear results, no confusion

---

## 2. Design System

### 2.1 Color Palette

#### Dark Theme (Default)

```
BACKGROUNDS
|-- Background Primary:    #121212  (Main background)
|-- Background Secondary:  #1E1E1E  (Cards, elevated surfaces)
|-- Background Tertiary:   #2C2C2C  (Input fields, disabled areas)
+-- Surface:               #252525  (Dialogs, bottom sheets)

PRIMARY COLORS
|-- Primary:               #2196F3  (Professional Blue)
|-- Primary Light:         #64B5F6  (Hover states)
|-- Primary Dark:          #1976D2  (Pressed states)
+-- Primary Container:     #1E3A5F  (Chips, tags background)

SEMANTIC COLORS
|-- Success:               #4CAF50  (Correct diagnosis)
|-- Success Container:     #1B3D1F  (Success background)
|-- Error:                 #F44336  (Wrong diagnosis, critical)
|-- Error Container:       #3D1B1B  (Error background)
|-- Warning:               #FFC107  (Caution, time warning)
|-- Warning Container:     #3D3517  (Warning background)
+-- Info:                  #2196F3  (Informational)

TEXT COLORS
|-- Text Primary:          #FFFFFF  (Headings, important text)
|-- Text Secondary:        #B0B0B0  (Body text, descriptions)
|-- Text Tertiary:         #757575  (Hints, placeholders)
+-- Text Disabled:         #4A4A4A  (Disabled elements)

TIMER COLORS (Special)
|-- Timer Safe:            #4CAF50  (120s - 60s)
|-- Timer Caution:         #FFC107  (59s - 15s)
|-- Timer Critical:        #F44336  (14s - 0s)
+-- Timer Pulse Glow:      #FF5252  (Last 10s animation)
```

#### Light Theme (Optional - v2.0)

```
Reserved for future implementation.
Dark mode is MVP default.
```

### 2.2 Typography

#### Font Family

```
Primary:     Inter (or system default San Francisco/Roboto)
Monospace:   JetBrains Mono (Timer, scores, lab values)
```

**WHY Monospace for Timer?**
- Numbers have fixed width
- "111" and "000" take same space
- No layout shift during countdown
- Professional medical equipment aesthetic

#### Type Scale

```
Display Large:   32sp / Bold      (Game Over Score)
Display Medium:  28sp / Bold      (Timer Countdown)
Headline:        24sp / SemiBold  (Screen Titles)
Title Large:     20sp / SemiBold  (Card Headers)
Title Medium:    16sp / SemiBold  (Section Headers)
Body Large:      16sp / Regular   (Primary Content)
Body Medium:     14sp / Regular   (Secondary Content)
Body Small:      12sp / Regular   (Captions, hints)
Label:           12sp / Medium    (Buttons, chips)
```

### 2.3 Spacing System

```
Base Unit: 4dp

XS:    4dp   (Inline spacing)
SM:    8dp   (Related elements)
MD:   16dp   (Section spacing)
LG:   24dp   (Card padding)
XL:   32dp   (Screen padding horizontal)
XXL:  48dp   (Major section breaks)
```

### 2.4 Border Radius

```
None:      0dp   (Progress bars)
Small:     4dp   (Chips, small buttons)
Medium:    8dp   (Cards, inputs)
Large:    12dp   (Bottom sheets, dialogs)
Full:     50%    (Avatars, circular buttons)
```

### 2.5 Elevation (Dark Theme)

```
Level 0:   0dp   (Flat surfaces)
Level 1:   1dp   (Cards) - subtle border instead of shadow
Level 2:   2dp   (Bottom navigation)
Level 3:   4dp   (App bar, FAB)
Level 4:   8dp   (Dialogs, bottom sheets)
```

**Note:** In dark theme, use subtle borders (#2C2C2C) instead of shadows for elevation.

---

## 3. Component Library

### 3.1 Buttons

#### Primary Button (CTA)

```
+---------------------------------+
|         TANI KOY                |  <- Text: White, 14sp Medium
|                                 |  <- Background: #2196F3
+---------------------------------+
    Height: 48dp
    Padding: 16dp horizontal
    Border Radius: 8dp
    
States:
|-- Default:    #2196F3 background
|-- Pressed:    #1976D2 background
|-- Disabled:   #2C2C2C background, #4A4A4A text
+-- Loading:    #2196F3 background + CircularProgressIndicator
```

#### Secondary Button

```
+---------------------------------+
|         TEST ISTE               |  <- Text: #2196F3
|                                 |  <- Background: transparent
+---------------------------------+
    Border: 1dp #2196F3
    
States:
|-- Default:    Transparent, #2196F3 border
|-- Pressed:    #1E3A5F background
+-- Disabled:   #2C2C2C border, #4A4A4A text
```

#### Danger Button

```
+---------------------------------+
|         OYUNU BITIR             |  <- Text: White
|                                 |  <- Background: #F44336
+---------------------------------+
```

### 3.2 Timer Component

**CRITICAL COMPONENT - Memory leak prevention required**

```
+-------------------------------------------------------------+
| â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘ |  <- Linear Progress
+-------------------------------------------------------------+
|                          87                                 |  <- Monospace, 28sp
|                        saniye                               |  <- 12sp, Secondary
+-------------------------------------------------------------+

Color Behavior:
|-- 120s - 60s:  #4CAF50 (Green/Safe)
|-- 59s - 15s:   #FFC107 (Yellow/Caution)  
+-- 14s - 0s:    #F44336 (Red/Critical) + Pulse animation

Technical Requirements:
|-- Timer must be in separate StatefulWidget
|-- Timer.periodic must be cancelled in dispose()
|-- Use Riverpod autoDispose provider
+-- Client timer = UI only, server validates actual time
```

### 3.3 Test Request Chip

```
+--------------+
| [LAB] CBC    |  <- Requested test
|    -10s      |  <- Time cost indicator
+--------------+

States:
|-- Available:     #1E3A5F background, #64B5F6 text
|-- Requested:     #2196F3 background, white text, checkmark icon
|-- Disabled:      #2C2C2C background, #4A4A4A text (already requested)
+-- Insufficient:  #3D1B1B background (not enough time)
```

### 3.4 Vital Signs Card

```
+-------------------------------------------------------------+
|  Vital Signs                                                |
+-------------------------------------------------------------+
|  [HR] 95 bpm       |  [BP] 140/90 mmHg                      |
|  [Temp] 37.2C      |  [RR] 18/min                           |
|  [SpO2] 98%                                                 |
+-------------------------------------------------------------+

Abnormal values: Show in #F44336 (Error color)
Normal values: Show in #B0B0B0 (Secondary text)
```

### 3.5 Lab Result Item

```
+-------------------------------------------------------------+
|  WBC                                      12.000 /uL  [UP]  |
|  Normal: 4.500 - 11.000                                     |
+-------------------------------------------------------------+

Value States:
|-- Normal:    #B0B0B0 text, no indicator
|-- High:      #F44336 text, [UP] indicator
|-- Low:       #2196F3 text, [DOWN] indicator
+-- Critical:  #F44336 text, Bold, [!] indicator
```

### 3.6 Leaderboard Row

```
+-------------------------------------------------------------+
|  [1st]  1   AH   Dr. Ahmet Yilmaz    245.6 puan    52 oyun  |
+-------------------------------------------------------------+
|  [2nd]  2   MY   MedStudent          238.2 puan    48 oyun  |
+-------------------------------------------------------------+
|  [3rd]  3   SK   FutureDr            232.1 puan    45 oyun  |
+-------------------------------------------------------------+
|      4   ...  ...                  ...          ...         |
+-------------------------------------------------------------+

Current User Row (Sticky Footer):
+-------------------------------------------------------------+
|  [You]  42  YK   You                 156.3 puan    28 oyun  |
+-------------------------------------------------------------+
    Background: #1E3A5F (highlighted)
    Always visible at bottom
```

### 3.7 Avatar Component

```
+-------+
|  AH   |  <- Initials, 14sp Bold, White
+-------+
    Size: 40dp (list), 64dp (profile)
    Background: Generated from name hash
    Shape: Circle
    
MVP: Initials only
v2.0: Image upload support
```

### 3.8 Case Result Card

```
Correct:
+-------------------------------------------------------------+
|  [OK]  Vaka 1: Miyokard Infarktusu                          |
|      Sure: 52s | Puan: 5.2                                  |
+-------------------------------------------------------------+
    Left border: 4dp #4CAF50

Wrong:
+-------------------------------------------------------------+
|  [X]  Vaka 3: Pnomoni                                       |
|      Senin cevabin: Bronsit | Dogru: Pnomoni                |
|      [Detaylari Gor ->]                                     |
+-------------------------------------------------------------+
    Left border: 4dp #F44336
```

---

## 4. Screen Specifications

### 4.1 Splash Screen

```
+-----------------------------------------+
|                                         |
|                                         |
|              [LOGO]                     |
|            DiagnozApp                   |
|                                         |
|         o o o (loading dots)            |
|                                         |
|                                         |
+-----------------------------------------+
```

**States:**
| State | Display | Duration |
|-------|---------|----------|
| Loading | Logo + animated dots | 1-2s |
| Auth Check | Same visual | Until Firebase responds |
| Error | Logo + "Baglanti hatasi" + Retry button | Until user action |

**Technical Notes:**
- Check Firebase Auth state
- Pre-fetch essential data if logged in
- Maximum 3 seconds, then show error

---

### 4.2 Auth Screen (SMS Verification)

```
+-----------------------------------------+
|  <-                                     |
|                                         |
|              [LOGO]                     |
|                                         |
|  Telefon Numaraniz                      |
|  +---------------------------------+    |
|  | +90 | 555 123 4567              |    |
|  +---------------------------------+    |
|                                         |
|  +---------------------------------+    |
|  |         KOD GONDER              |    |
|  +---------------------------------+    |
|                                         |
|  Devam ederek Kullanim Kosullarini     |
|  kabul etmis olursunuz.                 |
|                                         |
+-----------------------------------------+

After Code Sent:
+-----------------------------------------+
|  <-                                     |
|                                         |
|  Dogrulama Kodu                         |
|  +90 555 *** **67 numarasina           |
|  gonderildi.                            |
|                                         |
|  +---+ +---+ +---+ +---+ +---+ +---+    |
|  | 1 | | 2 | | 3 | | 4 | | 5 | | 6 |    |
|  +---+ +---+ +---+ +---+ +---+ +---+    |
|                                         |
|  Kod gelmedi mi? (45s)                  |
|  [Tekrar Gonder] - disabled until 0    |
|                                         |
+-----------------------------------------+
```

**States:**

| State | Phone Input | Code Input |
|-------|-------------|------------|
| Empty | Placeholder visible | - |
| Typing | Real-time formatting | Auto-focus next digit |
| Loading | Button shows spinner | Auto-submit on 6th digit |
| Error | Red border + message | Shake animation + clear |
| Success | - | Navigate to Home |

**Edge Cases:**
- Invalid phone format -> Show error, don't send
- Rate limited (3 SMS/hour) -> Show "Cok fazla deneme. X dakika sonra tekrar deneyin."
- Wrong code 3 times -> Lock for 5 minutes
- Network error -> "Baglanti hatasi. Tekrar deneyin."

**Technical Notes:**
```dart
// Rate limiting check BEFORE sending SMS
// Phone normalization to E.164 format
// Auto-submit when 6 digits entered
// Countdown timer for resend button (60s)
// Mask phone number in confirmation (555 *** **67)
```

---

### 4.3 Home Screen

```
+-----------------------------------------+
|  DiagnozApp              [Profile]      |
+-----------------------------------------+
|                                         |
|  Merhaba, Ahmet!                        |
|                                         |
|  +---------------------------------+    |
|  |                                 |    |
|  |      [RUN] RUSH MODE            |    |
|  |      120s | 5 Vaka | Rekabet    |    |
|  |                                 |    |
|  |      [  OYNA  ]                 |    |
|  |                                 |    |
|  +---------------------------------+    |
|                                         |
|  +---------------------------------+    |
|  |  [ZEN] ZEN MODE                 |    |
|  |  Suresiz | Ogren | Pratik       |    |
|  |  [YAKINDA]                      |    |
|  +---------------------------------+    |
|                                         |
|  -------------------------------------  |
|                                         |
|  [STATS] Bu Hafta                       |
|  +---------------------------------+    |
|  |  Siralaman: #42 | 156.3 puan    |    |
|  |  12 oyun | %68 dogruluk         |    |
|  |  [Liderlik Tablosu ->]          |    |
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
|  [Home]      [Leaderboard]   [Profile]  |
+-----------------------------------------+
```

**States:**

| State | Display |
|-------|---------|
| Loading | Skeleton placeholders for stats |
| Success | Full content as shown |
| Error (Stats) | Stats card shows "Yuklenemedi" + retry |
| Offline | Cached stats + "Cevrimdisi" badge |
| New User | Stats show "Ilk oyununu oyna!" |

**Edge Cases:**
- First time user -> Hide stats, show welcome message
- No games this week -> Show "Bu hafta henuz oynamadin"
- Network error -> Show cached data if available

---

### 4.4 Game Screen (Rush Mode)

**This is the MOST CRITICAL screen. Every state must be defined.**

**Mode-Based Content Display:**
| Content | Rush Mode | Zen Mode |
|---------|-----------|----------|
| Patient Profile | [OK] Shown | [OK] Shown |
| Chief Complaint | [OK] Shown | [OK] Shown |
| Vitals | [OK] Shown | [OK] Shown |
| Medical History | [X] Hidden | [OK] Expandable |
| Physical Exam | [X] Hidden | [OK] Expandable |
| Explanation | [X] Hidden | [OK] After answer |
| References | [X] Hidden | [OK] After answer |

**Rush Mode Layout:**

```
+-----------------------------------------+
|  Vaka 1/5                    [HP][HP]   |
+-----------------------------------------+
| â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘â–‘ |
|                  87                     |
|                saniye                   |
+-----------------------------------------+
|                                         |
|  [Hasta Bilgisi]  [Tetkikler]          |
|  -------------------------------------  |
|                                         |
|  [PATIENT] 45 yasinda erkek hasta       |
|                                         |
|  [COMPLAINT] Sikayet:                   |
|  "2 saattir gogus agrisi var,           |
|   sol kola yayiliyor"                   |
|                                         |
|  [VITALS] Vitaller:                     |
|  HR 95 bpm  |  BP 140/90 mmHg           |
|  Temp 37.2C  |  RR 18/min               |
|  SpO2: 98%                              |
|                                         |
|  -------------------------------------  |
|                                         |
|  [TEST] Test Iste (-10s):               |
|  [Laboratuvar v]  [Goruntuleme v]       |
|  [EKG v]          [Ozel v]              |
|                                         |
+-----------------------------------------+
|  +---------------------------------+    |
|  |         TANI KOY                |    |
|  +---------------------------------+    |
|                                         |
|  [PAS] 2 hakkin kaldi                   |
+-----------------------------------------+
```

**Tab 2: Tetkikler (Test Results)**

```
+-----------------------------------------+
|  [Hasta Bilgisi]  [Tetkikler]          |
|  -------------------------------------  |
|                                         |
|  [LAB] Istenen Testler:                 |
|                                         |
|  +---------------------------------+    |
|  |  [LAB] CBC (Tam Kan Sayimi)     |    |
|  |  WBC: 12.000 /uL          [UP]  |    |
|  |  Hgb: 14.2 g/dL                 |    |
|  |  Plt: 245.000 /uL               |    |
|  +---------------------------------+    |
|                                         |
|  +---------------------------------+    |
|  |  [ECG] EKG (12 Derivasyon)      |    |
|  |  +---------------------------+  |    |
|  |  |    [EKG Thumbnail]        |  |    |
|  |  |    Tap to zoom            |  |    |
|  |  +---------------------------+  |    |
|  |  ST elevasyonu V1-V4           |    |
|  +---------------------------------+    |
|                                         |
|  Henuz test istemedin?                  |
|  [Test Iste ->]                         |
|                                         |
+-----------------------------------------+
```

**States:**

| State | Timer | Content | Actions |
|-------|-------|---------|---------|
| Loading Case | Paused/Hidden | Skeleton | Disabled |
| Playing | Counting down | Full content | All enabled |
| Test Loading | Continues | Spinner on test | Test button disabled |
| Submitting | Paused | Dimmed | All disabled |
| Correct | Stopped (green) | Success overlay | Auto-next (2s) |
| Wrong | Stopped (red) | Error overlay | Continue/Game Over |
| Timeout | 0 (red) | Timeout overlay | Game Over |
| Paused (App Background) | Paused | Blur overlay | Resume on foreground |

**Edge Cases:**

| Scenario | Behavior |
|----------|----------|
| Double-tap submit | Disable button after first tap |
| Request same test twice | Show "Zaten istendi" toast, no time deduction |
| Time < 10s, request test | Show confirmation "Sadece Xs kaldi. Emin misin?" |
| App goes background | Pause timer, blur screen, resume on foreground |
| Network error during test | Rollback time deduction, show error |
| Network error during submit | Retry with exponential backoff |
| Back button during game | Show "Oyundan cikmak istedigine emin misin?" dialog |

**Technical Notes:**
```dart
// CRITICAL: Timer cleanup in dispose()
// CRITICAL: Disable submit button immediately on tap
// CRITICAL: Server-side time validation
// Tab state preserved when switching
// Test results cached in local state
// Optimistic UI update for test requests
```

---

### 4.5 Diagnosis Input Screen

```
+-----------------------------------------+
|  <-  Tani Sec                           |
+-----------------------------------------+
|                                         |
|  +---------------------------------+    |
|  | [SEARCH] Tani ara...            |    |
|  +---------------------------------+    |
|                                         |
|  Onerilen:                              |
|  +---------------------------------+    |
|  |  [HEART] Miyokard Infarktusu    |    |
|  +---------------------------------+    |
|  |  [HEART] Unstabil Angina        |    |
|  +---------------------------------+    |
|  |  [LUNG] Pulmoner Emboli         |    |
|  +---------------------------------+    |
|  |  [BONE] Kostokondrit            |    |
|  +---------------------------------+    |
|                                         |
|  Typing "myo":                          |
|  +---------------------------------+    |
|  |  Miyokard Infarktusu            |    |
|  |  Miyokardit                     |    |
|  |  Miyopati                       |    |
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+

Confirmation:
+-----------------------------------------+
|                                         |
|  Secilen Tani:                          |
|  +---------------------------------+    |
|  |  [HEART] Miyokard Infarktusu    |    |
|  +---------------------------------+    |
|                                         |
|  [!] Bu islem geri alinamaz!            |
|                                         |
|  +---------------------------------+    |
|  |         ONAYLA                  |    |
|  +---------------------------------+    |
|                                         |
|  [Vazgec]                               |
|                                         |
+-----------------------------------------+
```

**States:**

| State | Search | Results |
|-------|--------|---------|
| Empty | Placeholder | Common diagnoses |
| Typing | User input | Fuzzy search results |
| No Results | User input | "Sonuc bulunamadi" |
| Selected | Filled | Confirmation dialog |
| Submitting | Disabled | Loading spinner |

**Technical Notes:**
```dart
// Fuzzy search with Levenshtein distance
// Debounce search input (300ms)
// Maximum 10 results shown
// Recent/common diagnoses cached locally
// Timer continues during this screen
```

---

### 4.6 Game Result Overlays

**Correct Diagnosis:**
```
+-----------------------------------------+
|                                         |
|              [CHECK]                    |
|                                         |
|         DOGRU!                          |
|                                         |
|    Miyokard Infarktusu                  |
|                                         |
|    +5.2 puan                            |
|    (52 saniye kaldi)                    |
|                                         |
|    Sonraki vakaya geciliyor...          |
|    â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–‘â–‘ 2s                        |
|                                         |
+-----------------------------------------+
```

**Wrong Diagnosis:**
```
+-----------------------------------------+
|                                         |
|              [X]                        |
|                                         |
|         YANLIS                          |
|                                         |
|    Senin cevabin: Angina Pektoris       |
|    Dogru cevap: Miyokard Infarktusu     |
|                                         |
|    [HP][--] 1 hakkin kaldi              |
|                                         |
|  +---------------------------------+    |
|  |         DEVAM ET                |    |
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
```

**Game Over (No Passes):**
```
+-----------------------------------------+
|                                         |
|              [SKULL]                    |
|                                         |
|         OYUN BITTI                      |
|                                         |
|    Tum haklarini kullandin              |
|                                         |
|  +---------------------------------+    |
|  |       SONUCLARI GOR             |    |
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
```

**Timeout:**
```
+-----------------------------------------+
|                                         |
|              [CLOCK]                    |
|                                         |
|         SURE DOLDU!                     |
|                                         |
|    Zamaninda tani koyamadin             |
|                                         |
|  +---------------------------------+    |
|  |       SONUCLARI GOR             |    |
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
```

---

### 4.7 Game Summary Screen

```
+-----------------------------------------+
|  X                                      |
+-----------------------------------------+
|                                         |
|              [TROPHY]                   |
|                                         |
|           27.0                          |  <- Animated counter
|           PUAN                          |
|                                         |
|  -------------------------------------  |
|                                         |
|    [OK] 4 Dogru    [X] 1 Yanlis         |
|    [TIME] Ort. 68s   [CHART] %80 Basari |
|                                         |
|  -------------------------------------  |
|                                         |
|  Vaka Detaylari:                        |
|  +---------------------------------+    |
|  | [OK] Vaka 1: MI           5.2 p|    |
|  | [OK] Vaka 2: Pnomoni      7.8 p|    |
|  | [X] Vaka 3: Menenjit     0 puan|    |
|  |    [Detaylari Gor ->]          |    |
|  | [OK] Vaka 4: Apandisit    6.1 p|    |
|  | [OK] Vaka 5: DVT          7.9 p|    |
|  +---------------------------------+    |
|                                         |
|  -------------------------------------  |
|                                         |
|  [CHART] Siralaman: #42 -> #38 (+4)     |
|                                         |
|  +---------------------------------+    |
|  |       [REFRESH] TEKRAR OYNA     |    |  <- Primary CTA
|  +---------------------------------+    |
|                                         |
|  [Leaderboard]  [Ana Sayfa]             |
|                                         |
+-----------------------------------------+
```

**States:**

| State | Display |
|-------|---------|
| Loading | Score skeleton, spinner |
| Success | Full summary as shown |
| Score Submitting | "Puan kaydediliyor..." |
| Submit Error | "Puan kaydedilemedi" + Retry |
| Offline | "Cevrimici olunca kaydedilecek" |

**Technical Notes:**
```dart
// Score counter animation: 0 -> final (1.5s duration)
// Rank change calculated client-side (optimistic)
// Actual rank confirmed after server response
// "Tekrar Oyna" resets game state completely
// Clear navigation stack to prevent back-to-game
```

---

### 4.8 Leaderboard Screen

```
+-----------------------------------------+
|  <-  Liderlik Tablosu                   |
+-----------------------------------------+
|  [  Haftalik  ]  [  Aylik  ]            |
+-----------------------------------------+
|                                         |
|  [1st] 1   AH   Dr. Ahmet      245.6 p  |
|  [2nd] 2   MY   MedStudent     238.2 p  |
|  [3rd] 3   SK   FutureDr       232.1 p  |
|  ---  4   TK   Resident       228.5 p   |
|  ---  5   EY   MedGirl        225.3 p   |
|  ---  6   ...  ...            ...       |
|  ---  7   ...  ...            ...       |
|  ---  8   ...  ...            ...       |
|  .                                      |
|  .                                      |
|  .  (scrollable)                        |
|                                         |
+-----------------------------------------+
|  [YOU] 42  YK   Sen            156.3 p  |  <- Sticky Footer
|           12 oyun | Bu hafta            |
+-----------------------------------------+
```

**States:**

| State | List | Sticky Footer |
|-------|------|---------------|
| Loading | Skeleton rows (10) | Skeleton |
| Success | Full list | User's row |
| Empty | "Henuz kimse oynamadi" | Hidden |
| Error | "Yuklenemedi" + Retry | "---" |
| Offline | Cached list + badge | Cached data |
| User Not Ranked | Full list | "Henuz siralama yok" |

**Edge Cases:**
- User scrolls fast -> Use `ListView.builder` (lazy loading)
- 10K+ users -> Pagination (load 50 at a time)
- User not in top 100 -> Sticky footer shows actual rank
- Tab switch -> Preserve scroll position per tab

**Technical Notes:**
```dart
// CRITICAL: Use ListView.builder, NOT ListView
// Cache leaderboard for 5 minutes
// Sticky footer always visible (not in scroll)
// Pull-to-refresh for manual update
// Pagination cursor-based (not offset)
```

---

### 4.9 Profile Screen

```
+-----------------------------------------+
|  <-  Profil                    [GEAR]   |
+-----------------------------------------+
|                                         |
|              +-------+                  |
|              |  AH   |                  |  <- Avatar (initials)
|              +-------+                  |
|           Dr. Ahmet Yilmaz              |
|           Istanbul Universitesi         |
|                                         |
|  -------------------------------------  |
|                                         |
|  [CHART] Istatistikler                  |
|  +---------------------------------+    |
|  |  [GAME] Toplam Oyun   |    156  |    |
|  |  [OK] Cozulen Vaka    |    624  |    |
|  |  [UP] Ort. Puan/Oyun  |    5.2  |    |
|  |  [TROPHY] En Yuksek   |   32.4  |    |
|  |  [FIRE] Gunluk Seri   |    7    |    |
|  +---------------------------------+    |
|                                         |
|  -------------------------------------  |
|                                         |
|  [HISTORY] Son Oyunlar                  |
|  +---------------------------------+    |
|  |  Bugun 14:32    27.0 puan  4/5 |    |
|  |  Bugun 12:15    31.2 puan  5/5 |    |
|  |  Dun 23:45      18.5 puan  3/5 |    |
|  |  [Tumunu Gor ->]               |    |
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
|  [Home]      [Leaderboard]   [Profile]  |
+-----------------------------------------+
```

**States:**

| State | Stats | History |
|-------|-------|---------|
| Loading | Skeleton | Skeleton |
| Success | Full stats | Recent 3 games |
| Error | "Yuklenemedi" | "Yuklenemedi" |
| New User | All zeros | "Henuz oyun yok" |
| Offline | Cached | Cached |

---

### 4.10 Settings Screen

```
+-----------------------------------------+
|  <-  Ayarlar                            |
+-----------------------------------------+
|                                         |
|  [USER] Hesap                           |
|  +---------------------------------+    |
|  |  Isim Degistir               -> |    |
|  |  Universite Degistir         -> |    |
|  |  Unvan Degistir              -> |    |
|  +---------------------------------+    |
|                                         |
|  [LOCK] Gizlilik                        |
|  +---------------------------------+    |
|  |  Universiteyi Goster      [ON] |    |  <- Toggle
|  |  Oyun Gecmisini Goster   [OFF] |    |
|  +---------------------------------+    |
|                                         |
|  [PHONE] Uygulama                       |
|  +---------------------------------+    |
|  |  Bildirimler              [ON] |    |
|  |  Ses Efektleri            [ON] |    |
|  |  Titresim                [OFF] |    |
|  +---------------------------------+    |
|                                         |
|  -------------------------------------  |
|                                         |
|  [INFO] Hakkinda                        |
|  +---------------------------------+    |
|  |  Surum: 1.0.0                   |    |
|  |  Gizlilik Politikasi         -> |    |
|  |  Kullanim Kosullari          -> |    |
|  +---------------------------------+    |
|                                         |
|  -------------------------------------  |
|                                         |
|  +---------------------------------+    |
|  |  [EXIT] Cikis Yap               |    |
|  +---------------------------------+    |
|                                         |
+-----------------------------------------+
```

---

## 5. Navigation Flow

### 5.1 State Machine

```
                         APP LAUNCH
                             |
                             v
                    +---------------+
                    |    SPLASH     |
                    +-------+-------+
                            |
              +-------------+-------------+
              |             |             |
         (no token)    (has token)   (error)
              |             |             |
              v             v             v
        +----------+  +----------+  +----------+
        |   AUTH   |  |   HOME   |  |  ERROR   |
        +----+-----+  +----+-----+  +----+-----+
             |             |             |
        (success)          |         (retry)
             |             |             |
             +-------------+-------------+
                           |
         +-----------------+-----------------+
         |                 |                 |
         v                 v                 v
    +---------+      +-----------+     +---------+
    |  GAME   |      |LEADERBOARD|     | PROFILE |
    +----+----+      +-----------+     +----+----+
         |                                   |
         v                                   v
    +----------+                       +----------+
    |  CASE    |<--------------+       | SETTINGS |
    | (1-5)    |               |       +----------+
    +----+-----+               |
         |                     |
    +----v-----+               |
    | DIAGNOSIS|               |
    |  INPUT   |               |
    +----+-----+               |
         |                     |
    +----v-----+    +-------+  |
    |  RESULT  |--->| NEXT  |--+
    | OVERLAY  |    | CASE  |
    +----+-----+    +-------+
         |
    (game over)
         |
    +----v-----+
    | SUMMARY  |
    +----+-----+
         |
    +----v-----+
    |   HOME   |<-- (play again / home)
    +----------+
```

### 5.2 Navigation Rules

| From | To | Method | Back Behavior |
|------|----|--------|---------------|
| Splash | Auth/Home | Replace | Exit app |
| Auth | Home | Replace | Exit app |
| Home | Game | Push | Confirm dialog |
| Game | Summary | Replace | N/A (no back) |
| Summary | Home | Clear stack | N/A |
| Any | Profile | Push | Pop |
| Any | Settings | Push | Pop |

**Critical:** After game ends, navigation stack must be cleared to prevent returning to game screen.

---

## 6. Animation Guidelines

### 6.1 Timing Standards

```
Micro (feedback):      100ms   (button press, toggle)
Short (transition):    200ms   (tab switch, list item)
Medium (emphasis):     300ms   (modal appear, overlay)
Long (dramatic):       500ms   (score counter, celebration)
```

### 6.2 Easing Curves

```dart
Standard:     Curves.easeInOut      // Most UI transitions
Decelerate:   Curves.easeOut        // Entering elements
Accelerate:   Curves.easeIn         // Exiting elements
Spring:       Curves.elasticOut     // Playful feedback (correct answer)
Linear:       Curves.linear         // Progress bars, timers
```

### 6.3 Specific Animations

| Element | Animation | Duration | Curve |
|---------|-----------|----------|-------|
| Timer pulse | Scale 1.0 -> 1.05 -> 1.0 | 500ms | easeInOut |
| Correct answer | Scale + fade in | 300ms | elasticOut |
| Wrong answer | Shake horizontal | 300ms | easeInOut |
| Score counter | Number increment | 1500ms | easeOut |
| Tab switch | Fade + slide | 200ms | easeInOut |
| Button press | Scale 0.95 | 100ms | easeIn |
| List item appear | Fade + slide up | 200ms | easeOut |
| Modal appear | Fade + scale 0.9 -> 1.0 | 300ms | easeOut |

### 6.4 Timer Critical Animation (Last 10 seconds)

```dart
// Pulse animation for urgency
AnimationController _pulseController;

@override
void initState() {
  _pulseController = AnimationController(
    duration: Duration(milliseconds: 500),
    vsync: this,
  )..repeat(reverse: true);
}

// Animation values
// Scale: 1.0 -> 1.05
// Color: #F44336 with varying opacity (0.8 -> 1.0)
// Optional: Glow effect with BoxShadow

@override
void dispose() {
  _pulseController.dispose();  // CRITICAL: Prevent memory leak
  super.dispose();
}
```

---

## 7. Error Handling Patterns

### 7.1 Error Types

| Type | Display | Action |
|------|---------|--------|
| Network | Banner + retry | Pull-to-refresh or button |
| Server (5xx) | Modal + retry | Retry button |
| Client (4xx) | Toast + info | Explain issue |
| Validation | Inline error | Fix and resubmit |
| Auth expired | Modal | Re-login |
| Unknown | Modal | Contact support |

### 7.2 Error Messages (Turkish)

```dart
class ErrorMessages {
  static const networkError = 'Baglanti hatasi. Internet baglantini kontrol et.';
  static const serverError = 'Sunucu hatasi. Lutfen daha sonra tekrar dene.';
  static const timeoutError = 'Istek zaman asimina ugradi. Tekrar dene.';
  static const authError = 'Oturum suresi doldu. Tekrar giris yap.';
  static const validationError = 'Lutfen bilgileri kontrol et.';
  static const unknownError = 'Bir hata olustu. Lutfen tekrar dene.';
  static const rateLimitError = 'Cok fazla deneme. {minutes} dakika sonra tekrar dene.';
  static const offlineError = 'Cevrimdisisin. Bazi ozellikler kullanilamayabilir.';
}
```

### 7.3 Error Display Components

**Toast (Non-blocking):**
```
+-----------------------------------------+
|  [!]  Baglanti hatasi                   |
+-----------------------------------------+
Duration: 3 seconds
Position: Bottom, above navigation
```

**Banner (Persistent):**
```
+-----------------------------------------+
|  [WIFI] Cevrimdisi modu            [X]  |
+-----------------------------------------+
Position: Top, below app bar
Dismissible: Yes
```

**Modal (Blocking):**
```
+-----------------------------------------+
|              [!]                        |
|                                         |
|     Oturum Suresi Doldu                 |
|                                         |
|     Devam etmek icin tekrar             |
|     giris yapman gerekiyor.             |
|                                         |
|  +---------------------------------+    |
|  |       GIRIS YAP                 |    |
|  +---------------------------------+    |
+-----------------------------------------+
```

---

## 8. Accessibility

### 8.1 Minimum Requirements

| Requirement | Standard | Implementation |
|-------------|----------|----------------|
| Touch target | 48dp minimum | All buttons >= 48dp |
| Color contrast | 4.5:1 (AA) | Verified in palette |
| Font scaling | Up to 2x | Use sp units |
| Screen reader | Full support | Semantic labels |
| Motion | Respect reduce motion | Check system preference |

### 8.2 Semantic Labels

```dart
// Timer
Semantics(
  label: '87 saniye kaldi',
  child: TimerWidget(),
)

// Leaderboard row
Semantics(
  label: 'Sira 1, Dr. Ahmet, 245 puan',
  child: LeaderboardRow(),
)

// Game progress
Semantics(
  label: 'Vaka 3, toplam 5 vaka',
  child: CaseIndicator(),
)
```

### 8.3 Reduced Motion

```dart
final reduceMotion = MediaQuery.of(context).disableAnimations;

AnimatedContainer(
  duration: reduceMotion ? Duration.zero : Duration(milliseconds: 300),
  // ...
)
```

---

## 9. Performance Checklist

### 9.1 Pre-Development Checklist

For each screen, verify:

- [ ] All 5 states designed (loading, empty, success, error, partial)
- [ ] Edge cases documented
- [ ] Timer/subscription cleanup noted
- [ ] Memory-intensive components identified
- [ ] Lazy loading requirements specified
- [ ] Cache strategy defined

### 9.2 Performance Targets

| Metric | Target | Critical |
|--------|--------|----------|
| App launch | <3s | Yes |
| Screen transition | <300ms | Yes |
| Game case load | <500ms | Yes |
| Leaderboard render | <16ms/frame | Yes |
| Memory (idle) | <100MB | No |
| Memory (game) | <150MB | No |

### 9.3 Known Performance Risks

| Risk | Screen | Mitigation |
|------|--------|------------|
| Large list | Leaderboard | ListView.builder + pagination |
| Timer leak | Game | Dispose in cleanup |
| Image loading | Test results | Cached network images |
| Frequent rebuilds | Timer | Isolate timer widget |
| State explosion | Game | Riverpod state management |

---

## 10. Technical Implementation Notes

### 10.1 Widget Architecture

```
lib/
+-- core/
|   +-- theme/
|   |   +-- app_colors.dart       # Color palette
|   |   +-- app_typography.dart   # Text styles
|   |   +-- app_spacing.dart      # Spacing constants
|   |   +-- app_theme.dart        # ThemeData
|   +-- widgets/
|       +-- buttons/
|       |   +-- primary_button.dart
|       |   +-- secondary_button.dart
|       |   +-- danger_button.dart
|       +-- cards/
|       |   +-- vital_card.dart
|       |   +-- lab_result_card.dart
|       |   +-- case_result_card.dart
|       +-- feedback/
|           +-- loading_overlay.dart
|           +-- error_banner.dart
|           +-- toast.dart
+-- features/
    +-- game/
    |   +-- presentation/
    |       +-- widgets/
    |           +-- timer_widget.dart      # CRITICAL: Isolated
    |           +-- case_tabs.dart
    |           +-- test_request_chip.dart
    |           +-- result_overlay.dart
    +-- leaderboard/
        +-- presentation/
            +-- widgets/
                +-- leaderboard_row.dart
                +-- sticky_footer.dart
```

### 10.2 State Management Pattern

```dart
// Game state with Riverpod
@riverpod
class GameState extends _$GameState {
  @override
  GameModel build() => GameModel.initial();
  
  // Actions
  void startCase(Case case) { ... }
  void requestTest(String testId) { ... }
  void submitDiagnosis(String diagnosis) { ... }
  void usePass() { ... }
}

// Timer as separate provider (auto-dispose)
@riverpod
class TimerNotifier extends _$TimerNotifier {
  Timer? _timer;
  
  @override
  int build() {
    ref.onDispose(() => _timer?.cancel());  // CRITICAL
    return 120;
  }
  
  void start() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (state > 0) {
        state--;
      } else {
        _timer?.cancel();
        ref.read(gameStateProvider.notifier).handleTimeout();
      }
    });
  }
}
```

### 10.3 Critical Implementation Warnings

```
[!] TIMER: Must be separate widget/provider with dispose()
[!] LEADERBOARD: Must use ListView.builder (not ListView)
[!] SUBMIT BUTTON: Must disable immediately on tap
[!] NAVIGATION: Must clear stack after game ends
[!] FORMS: Must prevent double submission
[!] IMAGES: Must use cached_network_image
[!] LISTS: Must implement pagination for >50 items
```

### 10.4 Testing Requirements

Each screen must have:
1. Widget test for all 5 states
2. Widget test for edge cases
3. Integration test for critical flows
4. Memory leak test for timer/subscriptions

---

## References

- **Game Design:** See `masterplan.md`
- **Data Structure:** See `database_schema.md`
- **Edge Cases:** See `vcguide.md`
- **Security:** See `vcsecurity.md`
- **Workflow:** See `development_workflow.md`

---

**End of UI/UX Design Specification v1.1**

This document is the single source of truth for all UI/UX decisions.
Update this document before implementing any visual changes.

**Next Steps:**
1. Review and approve design decisions
2. Create Figma/design mockups if needed
3. Begin component library implementation
4. Build screens following state specifications
