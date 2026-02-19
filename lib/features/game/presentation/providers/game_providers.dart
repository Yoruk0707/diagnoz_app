// lib/features/game/presentation/providers/game_providers.dart
//
// NEDEN: auth_providers.dart pattern'ı — Riverpod DI.
// Data → Domain → Presentation zinciri burada kurulur.
//
// Sprint 4 güncellemesi: LocalGameRepository → FirebaseGameRepository.
// Firestore datasource'ları ve SubmitGameUsecase eklendi.
//
// Referans: auth_providers.dart
//           CLAUDE.md § State Management — Riverpod ONLY

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firestore_case_datasource.dart';
import '../../data/datasources/firestore_game_datasource.dart';
import '../../data/repositories/firebase_game_repository.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/usecases/start_game.dart';
import '../../domain/usecases/submit_diagnosis.dart';
import '../../domain/usecases/submit_game_usecase.dart';
import 'game_notifier.dart';
import 'game_state.dart';

// ─────────────────────────────────────────────────────────────
// DATA LAYER — Datasources
// ─────────────────────────────────────────────────────────────

/// Firestore case datasource — cases collection'dan veri çeker.
///
/// NEDEN: Sprint 4 — MockCases yerine Firestore.
/// FirebaseGameRepository bu datasource'u kullanır.
final firestoreCaseDatasourceProvider = Provider<FirestoreCaseDatasource>(
  (ref) => FirestoreCaseDatasource(),
);

/// Firestore game datasource — games collection CRUD + batch writes.
///
/// NEDEN: Oyun kaydetme, geçmiş çekme, atomic leaderboard güncelleme.
final firestoreGameDatasourceProvider = Provider<FirestoreGameDatasource>(
  (ref) => FirestoreGameDatasource(),
);

// ─────────────────────────────────────────────────────────────
// DATA LAYER — Repository
// ─────────────────────────────────────────────────────────────

/// Game repository implementasyonu.
///
/// NEDEN: Sprint 4 → FirebaseGameRepository (Firestore).
/// Sprint 3'teki LocalGameRepository yerine geçti.
/// Datasource'lar DI ile inject ediliyor.
final gameRepositoryProvider = Provider<GameRepository>(
  (ref) => FirebaseGameRepository(
    caseDatasource: ref.read(firestoreCaseDatasourceProvider),
    gameDatasource: ref.read(firestoreGameDatasourceProvider),
  ),
);

/// Firebase game repository — concrete type provider.
///
/// NEDEN: SubmitGameUsecase, GameRepository interface'inde olmayan
/// submitGame() method'una erişmek için concrete type gerektirir.
/// Sprint 4'te interface genişletilince bu provider kaldırılabilir.
final firebaseGameRepositoryProvider = Provider<FirebaseGameRepository>(
  (ref) => FirebaseGameRepository(
    caseDatasource: ref.read(firestoreCaseDatasourceProvider),
    gameDatasource: ref.read(firestoreGameDatasourceProvider),
  ),
);

// ─────────────────────────────────────────────────────────────
// DOMAIN LAYER (Use Cases)
// ─────────────────────────────────────────────────────────────

/// Oyun başlatma use case provider.
final startGameProvider = Provider<StartGame>(
  (ref) => StartGame(ref.read(gameRepositoryProvider)),
);

/// Tanı gönderme use case provider.
///
/// NEDEN: SubmitDiagnosis repository'ye bağımlı değil (pure logic),
/// ama provider pattern tutarlılığı için burada.
final submitDiagnosisProvider = Provider<SubmitDiagnosis>(
  (ref) => const SubmitDiagnosis(),
);

/// Oyun kaydetme use case provider.
///
/// NEDEN: Oyun bitince Firestore'a atomic batch write.
/// Input validation (score, time, passes) bu use case'de yapılır.
final submitGameUsecaseProvider = Provider<SubmitGameUsecase>(
  (ref) => SubmitGameUsecase(ref.read(firebaseGameRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────
// PRESENTATION LAYER (State Management)
// ─────────────────────────────────────────────────────────────

/// Ana game state notifier.
///
/// NEDEN: UI bu provider'ı watch eder.
/// autoDispose — ekrandan çıkınca timer cleanup otomatik.
/// vcguide.md § Timer System: dispose() temizliği.
final gameNotifierProvider =
    StateNotifierProvider.autoDispose<GameNotifier, GameState>(
  (ref) => GameNotifier(
    startGame: ref.read(startGameProvider),
    submitDiagnosis: ref.read(submitDiagnosisProvider),
    submitGameUsecase: ref.read(submitGameUsecaseProvider),
  ),
);
