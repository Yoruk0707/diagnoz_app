// lib/features/leaderboard/data/repositories/firebase_leaderboard_repository.dart
//
// NEDEN: LeaderboardRepository'nin Firestore implementasyonu.
// Firestore'dan leaderboard çeker, 5 dakika client-side cache uygular.
//
// Referans: firebase_game_repository.dart pattern (Either<Failure, T>)
//           database_schema.md § leaderboard_weekly, leaderboard_monthly
//           vcguide.md § Performance Optimization (5 dk cache)
//           vcguide.md § Edge Case 4 (FieldValue.increment — yazma tarafı)
//           CLAUDE.md § Firestore Cost Optimization
//           CLAUDE.md § Error Handling ("Wrap ALL async operations in try-catch")

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';

/// Firebase leaderboard repository — Firestore + 5 dk in-memory cache.
///
/// NEDEN: vcguide.md § Performance Optimization — leaderboard genelde
/// aynı veriyi gösterir, her seferinde Firestore'dan çekmek pahalı.
/// 5 dakika cache ile %99 read maliyeti azaltılır.
///
/// Yazma tarafı (FieldValue.increment) firestore_game_datasource.dart'ta
/// batch write ile yapılır — bu repository sadece OKUMA yapar.
class FirebaseLeaderboardRepository implements LeaderboardRepository {
  final FirebaseFirestore _firestore;

  // ─────────────────────────────────────────────
  // CACHE — 5 dakika in-memory
  // ─────────────────────────────────────────────

  // NEDEN: vcguide.md § Performance Optimization.
  // Cache key: "weekly_w04_2026_l50" veya "monthly_m01_2026_l50".
  // Her key için son fetch zamanı + veri tutulur.
  final Map<String, _CacheEntry<List<LeaderboardEntry>>> _cache = {};

  // NEDEN: 5 dakika = 300 saniye — vcguide.md'deki önerilen süre.
  // Daha kısa = çok Firestore read, daha uzun = stale data riski.
  static const Duration _cacheDuration = Duration(minutes: 5);

  // NEDEN: Bellek sızıntısı önleme — sınırsız cache büyümesi engellenir.
  // 20 entry yeterli (weekly + monthly × birkaç farklı limit kombinasyonu).
  static const int _maxCacheSize = 20;

  // NEDEN: DI ile test edilebilirlik. Mock Firestore inject edilebilir.
  FirebaseLeaderboardRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════
  // PUBLIC — LeaderboardRepository interface
  // ═══════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<LeaderboardEntry>>> getWeeklyLeaderboard({
    required int weekNumber,
    required int year,
    int limit = 50,
  }) async {
    // NEDEN: Geçersiz parametre ile Firestore query yapmayı engelle.
    if (weekNumber < 1 || weekNumber > 53) {
      return const Left(ServerFailure(
        'Geçersiz hafta numarası.',
        code: 'invalid-week-number',
      ));
    }
    if (limit < 1 || limit > 100) {
      return const Left(ServerFailure(
        'Geçersiz limit değeri.',
        code: 'invalid-limit',
      ));
    }

    final cacheKey = 'weekly_w${weekNumber}_${year}_l$limit';

    // NEDEN: Cache'te varsa ve 5 dk dolmadıysa, Firestore'a gitme.
    final cached = _getFromCache(cacheKey);
    if (cached != null) return Right(cached);

    try {
      // NEDEN: database_schema.md query pattern.
      // weekNumber + year ile filtrele, score DESC sırala.
      // userId ile secondary sort — eşit skorlarda stabil sıralama.
      final snapshot = await _firestore
          .collection('leaderboard_weekly')
          .where('weekNumber', isEqualTo: weekNumber)
          .where('year', isEqualTo: year)
          .orderBy('score', descending: true)
          .orderBy('userId')
          .limit(limit)
          .get();

      final entries = snapshot.docs
          .map((doc) => _fromFirestore(doc, LeaderboardPeriod.weekly))
          .toList();

      // NEDEN: Başarılı sonucu cache'e yaz.
      _putToCache(cacheKey, entries);

      return Right(entries);
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('[LEADERBOARD] Firebase error in getWeeklyLeaderboard: ${e.code}');
      }
      return Left(ServerFailure(
        'Haftalık liderlik tablosu yüklenemedi.',
        code: e.code,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('[LEADERBOARD] Error in getWeeklyLeaderboard: $e');
      }
      return const Left(ServerFailure(
        'Haftalık liderlik tablosu yüklenemedi.',
      ));
    }
  }

  @override
  Future<Either<Failure, List<LeaderboardEntry>>> getMonthlyLeaderboard({
    required int month,
    required int year,
    int limit = 50,
  }) async {
    // NEDEN: Geçersiz parametre ile Firestore query yapmayı engelle.
    if (month < 1 || month > 12) {
      return const Left(ServerFailure(
        'Geçersiz ay değeri.',
        code: 'invalid-month',
      ));
    }
    if (limit < 1 || limit > 100) {
      return const Left(ServerFailure(
        'Geçersiz limit değeri.',
        code: 'invalid-limit',
      ));
    }

    final cacheKey = 'monthly_m${month}_${year}_l$limit';

    // NEDEN: Cache kontrolü — 5 dk dolmadıysa Firestore'a gitme.
    final cached = _getFromCache(cacheKey);
    if (cached != null) return Right(cached);

    try {
      // NEDEN: userId ile secondary sort — eşit skorlarda stabil sıralama.
      final snapshot = await _firestore
          .collection('leaderboard_monthly')
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .orderBy('score', descending: true)
          .orderBy('userId')
          .limit(limit)
          .get();

      final entries = snapshot.docs
          .map((doc) => _fromFirestore(doc, LeaderboardPeriod.monthly))
          .toList();

      _putToCache(cacheKey, entries);

      return Right(entries);
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('[LEADERBOARD] Firebase error in getMonthlyLeaderboard: ${e.code}');
      }
      return Left(ServerFailure(
        'Aylık liderlik tablosu yüklenemedi.',
        code: e.code,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('[LEADERBOARD] Error in getMonthlyLeaderboard: $e');
      }
      return const Left(ServerFailure(
        'Aylık liderlik tablosu yüklenemedi.',
      ));
    }
  }

  @override
  Future<Either<Failure, int>> getUserRank({
    required String userId,
    required LeaderboardPeriod period,
    int? weekNumber,
    int? month,
    required int year,
  }) async {
    // NEDEN: Parametre validasyonu — geçersiz değerlerle query yapmayı engelle.
    if (userId.isEmpty) {
      return const Left(ServerFailure(
        'Kullanıcı kimliği boş olamaz.',
        code: 'invalid-user-id',
      ));
    }
    if (period == LeaderboardPeriod.weekly &&
        (weekNumber == null || weekNumber < 1 || weekNumber > 53)) {
      return const Left(ServerFailure(
        'Geçersiz hafta numarası.',
        code: 'invalid-week-number',
      ));
    }
    if (period == LeaderboardPeriod.monthly &&
        (month == null || month < 1 || month > 12)) {
      return const Left(ServerFailure(
        'Geçersiz ay değeri.',
        code: 'invalid-month',
      ));
    }

    try {
      // NEDEN: Önce cache'teki listeye bak — ekstra Firestore query'den kaçın.
      // Default limit 50 ile cache key oluştur (getUserRank default limit kullanır).
      final cacheKey = period == LeaderboardPeriod.weekly
          ? 'weekly_w${weekNumber}_${year}_l50'
          : 'monthly_m${month}_${year}_l50';

      final cached = _getFromCache(cacheKey);
      if (cached != null) {
        final index = cached.indexWhere((e) => e.userId == userId);
        // NEDEN: 1-indexed sıralama. Listede yoksa 0.
        return Right(index >= 0 ? index + 1 : 0);
      }

      // NEDEN: Cache'te yoksa Firestore'dan ilgili leaderboard'u çek.
      // getUserRank genelde leaderboard sayfasından sonra çağrılır,
      // bu yüzden cache'te olma ihtimali yüksek.
      final Either<Failure, List<LeaderboardEntry>> result;
      if (period == LeaderboardPeriod.weekly) {
        result = await getWeeklyLeaderboard(
          weekNumber: weekNumber!,
          year: year,
        );
      } else {
        result = await getMonthlyLeaderboard(
          month: month!,
          year: year,
        );
      }

      return result.fold(
        (failure) => Left(failure),
        (entries) {
          final index = entries.indexWhere((e) => e.userId == userId);
          return Right(index >= 0 ? index + 1 : 0);
        },
      );
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('[LEADERBOARD] Firebase error in getUserRank: ${e.code}');
      }
      return Left(ServerFailure(
        'Sıralama bilgisi alınamadı.',
        code: e.code,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('[LEADERBOARD] Error in getUserRank: $e');
      }
      return const Left(ServerFailure('Sıralama bilgisi alınamadı.'));
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CACHE HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Cache'ten veri al — 5 dk dolmuşsa null döner.
  ///
  /// NEDEN: Stale data önleme. 5 dk sonra cache invalidate olur.
  /// Immutable kopya döner — caller cache'i mutate edemez.
  List<LeaderboardEntry>? _getFromCache(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    final elapsed = DateTime.now().difference(entry.timestamp);
    if (elapsed > _cacheDuration) {
      _cache.remove(key);
      return null;
    }

    // NEDEN: Immutable kopya — caller .add()/.remove() yapsa bile
    // cache'teki orijinal liste bozulmaz.
    return List.unmodifiable(entry.data);
  }

  /// Cache'e veri yaz — max 20 entry, en eski silinir (basit LRU).
  ///
  /// NEDEN: Bellek sızıntısı önleme. Farklı hafta/ay/limit kombinasyonları
  /// ile cache sınırsız büyüyebilir.
  void _putToCache(String key, List<LeaderboardEntry> data) {
    // NEDEN: Basit LRU — cache dolu ise en eski timestamp'li entry silinir.
    if (!_cache.containsKey(key) && _cache.length >= _maxCacheSize) {
      String? oldestKey;
      DateTime? oldestTime;
      for (final entry in _cache.entries) {
        if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
          oldestKey = entry.key;
          oldestTime = entry.value.timestamp;
        }
      }
      if (oldestKey != null) {
        _cache.remove(oldestKey);
      }
    }
    _cache[key] = _CacheEntry(data: data, timestamp: DateTime.now());
  }

  // ═══════════════════════════════════════════════════════════
  // FIRESTORE MAPPING
  // ═══════════════════════════════════════════════════════════

  /// Firestore document → LeaderboardEntry.
  ///
  /// NEDEN: Null-safe parsing — eksik field'lar default değer alır.
  /// Firestore'da field yoksa crash yerine graceful fallback.
  LeaderboardEntry _fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    LeaderboardPeriod period,
  ) {
    final data = doc.data() ?? {};

    return LeaderboardEntry(
      userId: data['userId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Anonim',
      university: data['university'] as String?,
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
      casesPlayed: data['casesPlayed'] as int? ?? 0,
      gamesPlayed: data['gamesPlayed'] as int? ?? 0,
      weekNumber: period == LeaderboardPeriod.weekly
          ? data['weekNumber'] as int?
          : null,
      month: period == LeaderboardPeriod.monthly
          ? data['month'] as int?
          : null,
      year: data['year'] as int? ?? DateTime.now().year,
      lastUpdated: _parseTimestamp(data['lastUpdated']),
    );
  }

  /// Firestore Timestamp → DateTime.
  ///
  /// NEDEN: Firestore Timestamp tipi direkt DateTime'a cast edilemez.
  /// Null veya yanlış tip gelirse null döner (crash önleme).
  DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  // WEEK NUMBER UTILITY
  // ═══════════════════════════════════════════════════════════

  /// ISO 8601 hafta numarası hesapla.
  ///
  /// NEDEN: Firestore'daki weekNumber field'ı ISO 8601 standardında.
  /// Dart'ta built-in week number yok, manuel hesaplama gerekli.
  /// firestore_game_datasource.dart'taki ile aynı algoritma.
  static int getIsoWeekNumber(DateTime date) {
    // NEDEN: ISO 8601'de hafta Pazartesi başlar.
    // Yılın ilk Perşembe'si hangi haftadaysa, o hafta 1. haftadır.
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    final jan1 = DateTime(thursday.year, 1, 1);
    final dayOfYear = thursday.difference(jan1).inDays;
    return (dayOfYear / 7).floor() + 1;
  }
}

// ═══════════════════════════════════════════════════════════
// CACHE ENTRY — private helper
// ═══════════════════════════════════════════════════════════

/// Cache girişi — veri + timestamp.
///
/// NEDEN: TTL-based cache. timestamp ile 5 dk kontrolü yapılır.
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  const _CacheEntry({required this.data, required this.timestamp});
}
