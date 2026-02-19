// lib/features/leaderboard/presentation/providers/leaderboard_providers.dart
//
// NEDEN: game_providers.dart pattern'ı — Riverpod DI.
// Data → Domain → Presentation zinciri burada kurulur.
// Leaderboard ekranı bu provider'ları watch eder.
//
// Referans: game_providers.dart, auth_providers.dart
//           vcguide.md § Performance Optimization (5 dk cache)
//           CLAUDE.md § State Management — Riverpod ONLY

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_leaderboard_repository.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';

// ─────────────────────────────────────────────────────────────
// DATA LAYER — Repository
// ─────────────────────────────────────────────────────────────

/// Leaderboard repository implementasyonu.
///
/// NEDEN: Singleton — 5 dk in-memory cache tüm ekranlar arasında paylaşılır.
/// Her provider rebuild'da yeni instance = cache kaybı.
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
  (ref) => FirebaseLeaderboardRepository(),
);

// ─────────────────────────────────────────────────────────────
// PRESENTATION LAYER — UI State
// ─────────────────────────────────────────────────────────────

/// Haftalık/Aylık toggle state.
///
/// NEDEN: SegmentedButton toggle UI'dan değiştirilir.
/// Bu değişince weeklyLeaderboardProvider veya monthlyLeaderboardProvider
/// watch edilen provider değişir → otomatik rebuild.
final selectedPeriodProvider = StateProvider<LeaderboardPeriod>(
  (ref) => LeaderboardPeriod.weekly,
);

// ─────────────────────────────────────────────────────────────
// PRESENTATION LAYER — Data Fetching
// ─────────────────────────────────────────────────────────────

/// Bu haftanın liderlik tablosu.
///
/// NEDEN: FutureProvider.autoDispose — ekrandan çıkınca dispose.
/// keepAlive + 5 dk Timer ile cache süresi Riverpod seviyesinde de kontrol.
/// Repository'deki 5 dk cache + Riverpod cache = çift koruma.
final weeklyLeaderboardProvider =
    FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  // NEDEN: vcguide.md § Performance Optimization — 5 dk cache.
  // keepAlive ile provider ekrandan çıkınca hemen dispose olmaz.
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);

  final repository = ref.read(leaderboardRepositoryProvider);
  final now = DateTime.now();
  final weekNumber = FirebaseLeaderboardRepository.getIsoWeekNumber(now);

  final result = await repository.getWeeklyLeaderboard(
    weekNumber: weekNumber,
    year: now.year,
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (entries) => entries,
  );
});

/// Bu ayın liderlik tablosu.
///
/// NEDEN: weeklyLeaderboardProvider ile aynı pattern.
final monthlyLeaderboardProvider =
    FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);

  final repository = ref.read(leaderboardRepositoryProvider);
  final now = DateTime.now();

  final result = await repository.getMonthlyLeaderboard(
    month: now.month,
    year: now.year,
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (entries) => entries,
  );
});

/// Mevcut kullanıcının sıralaması.
///
/// NEDEN: Sticky footer'da gösterilir.
/// selectedPeriod'a bağlı — toggle değişince yeniden hesaplanır.
final currentUserRankProvider = FutureProvider.autoDispose<int>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  final repository = ref.read(leaderboardRepositoryProvider);
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null || userId.isEmpty) return 0;

  final now = DateTime.now();
  final weekNumber = FirebaseLeaderboardRepository.getIsoWeekNumber(now);

  final result = await repository.getUserRank(
    userId: userId,
    period: period,
    weekNumber: period == LeaderboardPeriod.weekly ? weekNumber : null,
    month: period == LeaderboardPeriod.monthly ? now.month : null,
    year: now.year,
  );

  return result.fold(
    (failure) => 0,
    (rank) => rank,
  );
});
