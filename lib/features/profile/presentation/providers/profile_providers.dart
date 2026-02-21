// lib/features/profile/presentation/providers/profile_providers.dart
//
// NEDEN: Profil sayfası provider'ları.
// Firestore users/{userId} doc'undan kullanıcı profili + istatistikler okunur.
//
// Referans: leaderboard_providers.dart pattern
//           database_schema.md § users/{userId}
//           CLAUDE.md § State Management — Riverpod ONLY

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user.dart';

/// Mevcut kullanıcının profil verisi — Firestore users/{userId}.
///
/// NEDEN: FutureProvider.autoDispose — ekrandan çıkınca dispose.
/// Auth state'ten userId alınır → Firestore'dan profil okunur.
/// Stats, university, displayName gibi bilgiler burada gelir.
/// Firebase Auth sadece uid/phone/displayName verir — stats Firestore'da.
final currentUserProfileProvider =
    FutureProvider.autoDispose<AppUser?>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;

  // NEDEN: Firestore users/{userId} — tek document read.
  // Security rules: get = isOwner(userId), başkası okuyamaz (PII koruması).
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();

  if (!doc.exists || doc.data() == null) {
    // NEDEN: Yeni kullanıcı — henüz users doc'u oluşturulmamış.
    // Firebase Auth'tan minimum bilgi ile döndür.
    final firebaseUser = FirebaseAuth.instance.currentUser!;
    return AppUser(
      id: firebaseUser.uid,
      phoneNumber: firebaseUser.phoneNumber ?? '',
      displayName: firebaseUser.displayName,
      stats: const UserStats(),
      privacy: const UserPrivacy(),
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  final data = doc.data()!;

  // NEDEN: Firestore Map → AppUser entity dönüşümü.
  // Null-safe parsing — eksik field'lar default değer alır.
  final statsData = data['stats'] as Map<String, dynamic>? ?? {};

  return AppUser(
    id: userId,
    phoneNumber: data['phoneNumber'] as String? ?? '',
    displayName: data['displayName'] as String?,
    title: data['title'] as String?,
    university: data['university'] as String?,
    stats: UserStats(
      totalGamesPlayed: statsData['totalGamesPlayed'] as int? ?? 0,
      totalCasesSolved: statsData['totalCasesSolved'] as int? ?? 0,
      averageScore: (statsData['averageScore'] as num?)?.toDouble() ?? 0.0,
      weeklyScore: (statsData['weeklyScore'] as num?)?.toDouble() ?? 0.0,
      monthlyScore: (statsData['monthlyScore'] as num?)?.toDouble() ?? 0.0,
      bestScore: (statsData['bestScore'] as num?)?.toDouble() ?? 0.0,
      currentStreak: statsData['currentStreak'] as int? ?? 0,
    ),
    privacy: UserPrivacy(
      showUniversity:
          (data['privacy'] as Map<String, dynamic>?)?['showUniversity']
                  as bool? ??
              true,
      showGameHistory:
          (data['privacy'] as Map<String, dynamic>?)?['showGameHistory']
                  as bool? ??
              true,
    ),
    createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
  );
});

/// Firestore Timestamp → DateTime.
///
/// NEDEN: Firestore Timestamp tipi direkt DateTime'a cast edilemez.
DateTime? _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  return null;
}
