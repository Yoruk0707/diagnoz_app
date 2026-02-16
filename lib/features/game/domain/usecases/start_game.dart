// lib/features/game/domain/usecases/start_game.dart
//
// NEDEN: Use case iş kurallarını repository'den ayırır.
// Oyun başlatma validasyonu burada, data erişimi repository'de.
//
// Referans: send_verification_code.dart pattern'ı
//           masterplan.md § Rush Mode
//           app_constants.dart (casesPerGame)

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/game_session.dart';
import '../entities/medical_case.dart';
import '../repositories/game_repository.dart';

/// Yeni oyun başlatma use case.
///
/// NEDEN: Oyun başlatma iş kuralları:
/// 1. Yeterli vaka var mı? (casesPerGame = 5)
/// 2. GameSession oluştur
/// 3. Sprint 4'te: rate limit kontrolü (gameStartMaxPerHour = 20)
class StartGame {
  final GameRepository _repository;

  const StartGame(this._repository);

  /// [mode] oyun modu.
  /// [specialty] opsiyonel filtre (Branch mode).
  ///
  /// Başarılı → Right(GameSession) — UI oyunu başlatır.
  Future<Either<Failure, GameSession>> call({
    required GameMode mode,
    Specialty? specialty,
  }) async {
    // NEDEN: Repository'ye delege et — Sprint 3'te mock, Sprint 4'te Firestore.
    // Rate limit kontrolü Sprint 4'te Cloud Function'da yapılacak.
    return _repository.startGame(
      mode: mode,
      specialty: specialty,
    );
  }
}
