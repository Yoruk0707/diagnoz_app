// lib/features/game/presentation/providers/game_providers.dart
//
// NEDEN: auth_providers.dart pattern'ı — Riverpod DI.
// Data → Domain → Presentation zinciri burada kurulur.
//
// Referans: auth_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/local_game_repository.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/usecases/start_game.dart';
import '../../domain/usecases/submit_diagnosis.dart';
import 'game_notifier.dart';
import 'game_state.dart';

// ─────────────────────────────────────────────────────────────
// DATA LAYER
// ─────────────────────────────────────────────────────────────

/// Game repository implementasyonu.
///
/// NEDEN: Sprint 3 → LocalGameRepository (mock data).
/// Sprint 4'te → FirebaseGameRepository ile override edilecek.
final gameRepositoryProvider = Provider<GameRepository>(
  (ref) => LocalGameRepository(),
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
  ),
);
