// lib/features/leaderboard/domain/repositories/leaderboard_repository.dart
//
// NEDEN: auth_repository.dart pattern'ı — abstract interface.
// Domain layer Firestore'u bilmez. Data layer bu interface'i implement eder.
// Test'te mock'lanır, domain layer saf kalır.
//
// Referans: auth_repository.dart
//           database_schema.md § leaderboard_weekly, leaderboard_monthly
//           vcguide.md § Performance Optimization (5 dk cache)

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/leaderboard_entry.dart';

/// Leaderboard repository interface — domain layer Firebase'i bilmez.
///
/// NEDEN: Dependency Inversion. Data layer bu interface'i implement eder.
/// Firebase_leaderboard_repository bu interface'i uygular.
abstract class LeaderboardRepository {
  /// Haftalık liderlik tablosunu getir.
  ///
  /// [weekNumber] ISO 8601 hafta numarası (1-53).
  /// [year] Yıl (örn. 2026).
  /// [limit] Maksimum sonuç sayısı (default: 50).
  ///
  /// Başarılı → Right(List<LeaderboardEntry>) — score DESC sıralı.
  ///
  /// Olası hatalar:
  /// - [ServerFailure] → Firestore bağlantı hatası
  /// - [CacheFailure] → Cache okuma hatası
  Future<Either<Failure, List<LeaderboardEntry>>> getWeeklyLeaderboard({
    required int weekNumber,
    required int year,
    int limit = 50,
  });

  /// Aylık liderlik tablosunu getir.
  ///
  /// [month] Ay (1-12).
  /// [year] Yıl (örn. 2026).
  /// [limit] Maksimum sonuç sayısı (default: 50).
  ///
  /// Başarılı → Right(List<LeaderboardEntry>) — score DESC sıralı.
  ///
  /// Olası hatalar:
  /// - [ServerFailure] → Firestore bağlantı hatası
  /// - [CacheFailure] → Cache okuma hatası
  Future<Either<Failure, List<LeaderboardEntry>>> getMonthlyLeaderboard({
    required int month,
    required int year,
    int limit = 50,
  });

  /// Kullanıcının sıralamasını getir.
  ///
  /// [userId] Firebase Auth UID.
  /// [period] weekly veya monthly.
  /// [weekNumber] Hafta numarası (weekly için zorunlu).
  /// [month] Ay (monthly için zorunlu).
  /// [year] Yıl.
  ///
  /// Başarılı → Right(int) — 1-indexed sıralama. 0 = kullanıcı listede yok.
  ///
  /// Olası hatalar:
  /// - [ServerFailure] → Firestore bağlantı hatası
  Future<Either<Failure, int>> getUserRank({
    required String userId,
    required LeaderboardPeriod period,
    int? weekNumber,
    int? month,
    required int year,
  });
}
