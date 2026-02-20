# DiagnozApp - Proje Durumu
Son Guncelleme: 20 Subat 2026

## Tamamlanan Sprintler

### Sprint 1: Foundation & Navigation âœ…
- app_constants.dart (oyun mekanikleri, rate limiting, UI sabitleri)
- app_strings.dart (Turkce UI metinleri)
- 4 placeholder ekran (Home, Game, Leaderboard, Profile)
- GoRouter + ShellRoute + bottom navigation bar
- Firebase projesi: diagnozapp-96805 (Blaze plan)
- firebase_options.dart olusturuldu (web, ios, android, macos, windows)
- Theme tip duzeltmeleri: CardThemeData, DialogThemeData, TabBarThemeData
- Crashlytics web guard eklendi (kIsWeb check)
- Zone mismatch duzeltmesi (ensureInitialized runZonedGuarded icine tasindi)

### Sprint 2: Authentication âœ…
Tamamlanma: 12 Subat 2026

**Batch 1 - Domain Layer (5 dosya):**
- lib/core/errors/failures.dart (AuthFailure.unknown factory sonradan eklendi)
- lib/core/utils/input_validator.dart
- lib/features/auth/domain/entities/app_user.dart
- lib/features/auth/domain/repositories/auth_repository.dart (interface)
- lib/features/auth/domain/usecases/send_verification_code.dart
- lib/features/auth/domain/usecases/verify_sms_code.dart
- lib/features/auth/domain/usecases/get_current_user.dart
- lib/features/auth/domain/usecases/sign_out.dart

**Batch 2 - Data Layer (2 dosya + Senaca review):**
- lib/features/auth/data/repositories/firebase_auth_repository.dart
- lib/features/auth/data/models/user_model.dart
- Senaca security review gecti

**Batch 3 - State Management (3 dosya):**
- lib/features/auth/presentation/providers/auth_state.dart (sealed class pattern)
- lib/features/auth/presentation/providers/auth_notifier.dart (StateNotifier)
- lib/features/auth/presentation/providers/auth_providers.dart (DI chain)

**Batch 4 - Auth Screens (3 dosya):**
- lib/features/auth/presentation/pages/splash_page.dart
- lib/features/auth/presentation/pages/phone_input_page.dart
- lib/features/auth/presentation/pages/otp_verification_page.dart

**Batch 5 - Router Integration:**
- lib/core/router/app_router.dart (full rewrite - auth routes + shell route)

**Batch 6 - Firebase Console Setup:**
- Phone Auth enabled
- Test phone number configured (code: 123456)
- Blaze plan aktif (1000 SMS/gun kotasi)

**Test Sonucu:** Splash -> Phone Input -> OTP -> Home akisi Chrome'da calisiyor âœ…

### Sprint 3: Core Game Loop (Rush Mode) âœ…
Tamamlanma: 16 Subat 2026

**Batch 1 - Domain Entities (2 dosya):**
- lib/features/game/domain/entities/medical_case.dart (Specialty, PatientProfile, Vitals, TestResult, MedicalCase)
- lib/features/game/domain/entities/game_session.dart (GameMode, GameStatus, CaseResult, GameSession)
- Eski iskelet dosyalar temizlendi (case.dart, game_state.dart silindi)

**Batch 2 - Domain Layer (3 dosya):**
- lib/features/game/domain/repositories/game_repository.dart (interface)
- lib/features/game/domain/usecases/start_game.dart
- lib/features/game/domain/usecases/submit_diagnosis.dart (DiagnosisResult, tani eslestirme, skor hesaplama)

**Batch 3 - Data Layer (2 dosya):**
- lib/features/game/data/datasources/mock_cases.dart (5 Turkce tibbi vaka)
- lib/features/game/data/repositories/local_game_repository.dart (mock data implementasyonu)

**5 Mock Vaka:**
1. Akut Anterior Miyokard Enfarktusu (Kardiyoloji - Orta)
2. Toplum Kokenli Pnomoni (Pulmonoloji - Kolay)
3. Akut Apandisit (Cerrahi - Kolay)
4. Bakteriyel Menenjit (Noroloji - Zor)
5. Masif Pulmoner Emboli (Acil - Zor)

**Batch 4 - State Management (3 dosya):**
- lib/features/game/presentation/providers/game_state.dart (GameInitial, GameLoading, GamePlaying, GameCaseResult, GameOver, GameError)
- lib/features/game/presentation/providers/game_notifier.dart (timer, test isteme, tani gonderme, oyun akisi)
- lib/features/game/presentation/providers/game_providers.dart (Riverpod DI zinciri)

**Batch 5 - UI (3 dosya):**
- lib/features/game/presentation/pages/game_screen.dart (tum oyun state'lerinin UI'i)
- lib/features/game/presentation/widgets/timer_widget.dart (dairesel countdown)
- lib/features/game/presentation/widgets/case_card_widget.dart (hasta bilgisi + vitaller)

**Batch 7 - Router Baglantisi:**
- lib/features/game/presentation/pages/game_page.dart (placeholder â†’ GameScreen'e delege)

**Bug Fix:**
- TextEditingController timer rebuild'de sifirlaniyordu â†’ ConsumerStatefulWidget'a tasindi

**Test Sonucu:** Tam oyun dongusu Chrome'da calisiyor âœ…
- Oyna butonu â†’ Vaka sunumu â†’ Test isteme (-10sn) â†’ Tani girisi â†’ Dogru/Yanlis feedback â†’ Sonraki vaka â†’ Oyun bitti ekrani

### Sprint 4: Firebase Integration + Leaderboard âœ…
Tamamlanma: 20 Subat 2026

**Firestore Data Layer:**
- lib/features/game/data/datasources/firestore_case_datasource.dart (vaka CRUD + seedCases)
- lib/features/game/data/datasources/firestore_game_datasource.dart (oyun CRUD + atomic batch write)
- lib/features/game/data/models/game_model.dart (Firestore serialization)
- lib/features/game/data/repositories/firebase_game_repository.dart (GameRepository Firestore impl)
- lib/features/game/domain/usecases/submit_game_usecase.dart (validation + submit)

**Leaderboard Feature:**
- lib/features/leaderboard/domain/entities/leaderboard_entry.dart
- lib/features/leaderboard/domain/repositories/leaderboard_repository.dart (interface)
- lib/features/leaderboard/data/repositories/firebase_leaderboard_repository.dart (5 dk cache)
- lib/features/leaderboard/presentation/providers/leaderboard_providers.dart
- lib/features/leaderboard/presentation/pages/leaderboard_page.dart (haftalik/aylik tab)

**Shared Utilities:**
- lib/core/utils/date_utils.dart (ISO 8601 week number — DRY)

**Firebase Configuration:**
- firestore.rules (security rules — field allowlist, owner checks, delete: false)
- firestore.indexes.json (composite indexes: leaderboard_weekly, leaderboard_monthly)
- firebase.json (firestore rules + indexes config)

**Home Page Upgrade:**
- lib/features/home/presentation/pages/home_page.dart (oyun istatistikleri + debug seed butonu)

**Atomic Batch Write (submitGame):**
- 4 koleksiyon tek transaction: games + users + leaderboard_weekly + leaderboard_monthly
- FieldValue.increment() ile race condition koruması
- set() + merge:true ile olmayan doc olusturma
- 10 asamali client-side validation (score, time, passes, duplicate, NaN)

**Bug Fixes (6 adet):**
1. TextField temizlenmeme — ref.listen ile GamePlaying gecisinde clear()
2. passesLeft validation — .clamp(0, passesPerGame) ile eleme durumu
3. Composite index eksikligi — firestore.indexes.json olusturuldu
4. Security rules batch write bloklama — field allowlist + leaderboard write izni
5. batch.update() non-existent doc — set() + merge:true’ya gecis
6. ISO 8601 week number mismatch — shared utility’ye tasindi

**Test Sonucu:** Tam oyun + Firestore kayit + leaderboard Chrome’da calisiyor âœ…

## Aktif Sprint
Sprint 5: Planlanacak

### Sprint 5 Kapsam (Beklenen)
- correctDiagnosis alani cases_private koleksiyonuna tasima
- Server-side timer validation (Cloud Functions)
- Leaderboard tab refresh bug duzeltme (ref.invalidate)
- Profil sayfasi (kullanici istatistikleri)
- Daha fazla tibbi vaka ekleme
- Admin vaka yonetimi (Cloud Functions)

## Bilinen Sorunlar
- Leaderboard tab'ina tiklaninca veri gelmiyor, sayfa yenilenince geliyor (provider invalidate eksik — Sprint 5)
- macos ve windows Firebase kayitlari gereksiz eklendi (zararsiz)
- reCAPTCHA Enterprise uyarilari Chrome console'da (fonksiyonu etkilemiyor)
- correctDiagnosis alani client'tan gorunur — Sprint 5'te cases_private'a tasinacak
- Mock data'da 5 vaka var, tekrar edebiliyorlar (daha fazla vaka eklenecek)

## GitHub Repository
- URL: https://github.com/Yoruk0707/diagnoz_app
- Branch: main
- Public repo (Firebase client-side keys guvenli, gercek guvenlik Firestore Rules'da)

## Claude Dosya Erisim Yontemi
**GitHub Raw Link Pattern (ONEMLI):**
Claude, projedeki dosyalari okumak icin GitHub raw linklerini kullanabilir.
Kullanici su formatta link yapistirir, Claude web_fetch ile okur:

```
https://raw.githubusercontent.com/Yoruk0707/diagnoz_app/main/lib/path/to/file.dart
```

Ornek:
```
https://raw.githubusercontent.com/Yoruk0707/diagnoz_app/main/lib/features/auth/domain/repositories/auth_repository.dart
```

**Dizin listesi icin GitHub API:**
```
https://api.github.com/repos/Yoruk0707/diagnoz_app/contents/lib/features/game/domain/entities
```

**Kurallar:**
- Her link kullanici tarafindan yapistirilmali (Claude URL construct edemez)
- Push sonrasi guncel dosyalar gorunur
- API cache olabilir, birkac dakika beklemek gerekebilir
- Alternatif: terminalde `cat lib/path/to/file.dart`

## Git Workflow
```bash
# Her batch sonrasi:
git add -A && git commit -m "descriptive message" && git push

# Token remote URL'de gomulu (tek kullanici proje)
```

## Dosya Yapisi
```
lib/
â”œâ”€â”€ main.dart
â”œâ”€â”€ app.dart
â”œâ”€â”€ firebase_options.dart
â”œâ”€â”€ core/
â”‚   â”œâ”€â”€ constants/
â”‚   â”‚   â”œâ”€â”€ app_constants.dart
â”‚   â”‚   â””â”€â”€ app_strings.dart
â”‚   â”œâ”€â”€ errors/
â”‚   â”‚   â””â”€â”€ failures.dart
â”‚   â”œâ”€â”€ router/
â”‚   â”‚   â””â”€â”€ app_router.dart
â”‚   â”œâ”€â”€ theme/
â”‚   â”‚   â”œâ”€â”€ app_colors.dart
â”‚   â”‚   â”œâ”€â”€ app_spacing.dart
â”‚   â”‚   â”œâ”€â”€ app_theme.dart
â”‚   â”‚   â””â”€â”€ app_typography.dart
â”‚   â”œâ”€â”€ utils/
â”‚   â”‚   â”œâ”€â”€ input_validator.dart
â”‚   â”‚   â””â”€â”€ date_utils.dart (ISO 8601 week number)
â”œâ”€â”€ features/
â”‚   â”œâ”€â”€ auth/
â”‚   â”‚   â”œâ”€â”€ data/
â”‚   â”‚   â”‚   â”œâ”€â”€ models/user_model.dart
â”‚   â”‚   â”‚   â””â”€â”€ repositories/firebase_auth_repository.dart
â”‚   â”‚   â”œâ”€â”€ domain/
â”‚   â”‚   â”‚   â”œâ”€â”€ entities/app_user.dart
â”‚   â”‚   â”‚   â”œâ”€â”€ repositories/auth_repository.dart
â”‚   â”‚   â”‚   â””â”€â”€ usecases/ (send_verification_code, verify_sms_code, get_current_user, sign_out)
â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚       â”œâ”€â”€ pages/ (splash_page, phone_input_page, otp_verification_page)
â”‚   â”‚       â””â”€â”€ providers/ (auth_state, auth_notifier, auth_providers)
â”‚   â”œâ”€â”€ game/
â”‚   â”‚   â”œâ”€â”€ data/
â”‚   â”‚   â”‚   â”œâ”€â”€ datasources/ (mock_cases, firestore_case_datasource, firestore_game_datasource)
â”‚   â”‚   â”‚   â”œâ”€â”€ models/game_model.dart
â”‚   â”‚   â”‚   â””â”€â”€ repositories/ (local_game_repository, firebase_game_repository)
â”‚   â”‚   â”œâ”€â”€ domain/
â”‚   â”‚   â”‚   â”œâ”€â”€ entities/ (medical_case.dart, game_session.dart)
â”‚   â”‚   â”‚   â”œâ”€â”€ repositories/game_repository.dart (interface)
â”‚   â”‚   â”‚   â””â”€â”€ usecases/ (start_game, submit_diagnosis, submit_game_usecase)
â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚       â”œâ”€â”€ pages/ (game_page.dart, game_screen.dart)
â”‚   â”‚       â”œâ”€â”€ providers/ (game_state, game_notifier, game_providers)
â”‚   â”‚       â””â”€â”€ widgets/ (timer_widget, case_card_widget)
â”‚   â”œâ”€â”€ home/presentation/pages/home_page.dart (istatistikler + debug seed)
â”‚   â”œâ”€â”€ leaderboard/
â”‚   â”‚   â”œâ”€â”€ data/repositories/firebase_leaderboard_repository.dart (5 dk cache)
â”‚   â”‚   â”œâ”€â”€ domain/ (leaderboard_entry, leaderboard_repository interface)
â”‚   â”‚   â””â”€â”€ presentation/ (leaderboard_providers, leaderboard_page)
â”‚   â””â”€â”€ profile/presentation/pages/profile_page.dart (placeholder)
```
