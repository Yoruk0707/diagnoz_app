// lib/features/game/data/models/game_model.dart
//
// NEDEN: GameSession entity <-> Firestore document dönüşümü.
// Domain layer Firestore'u bilmez — bu model köprü görevi görür.
// CaseResult nested modeli dahil.
//
// Referans: database_schema.md § games/{gameId}
//           game_session.dart entity yapısı
//           vcguide.md § Score Calculation (score validation)

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/game_session.dart';
import '../../domain/entities/medical_case.dart';

/// Firestore ↔ GameSession dönüşüm modeli.
///
/// NEDEN: Clean Architecture — data layer Firestore Map'lerini
/// domain entity'ye çevirir. Entity Firestore'dan habersiz kalır.
class GameModel {
  /// GameSession entity → Firestore document Map.
  ///
  /// NEDEN: Oyun tamamlandığında Firestore'a kaydederken kullanılır.
  /// games/{gameId} şemasına birebir uyumlu.
  /// database_schema.md § games/{gameId}: immutable history — yazıldıktan sonra
  /// update/delete yapılmaz.
  static Map<String, dynamic> toFirestore(
    GameSession session, {
    required String userId,
  }) {
    return {
      'userId': userId,
      'mode': session.mode.name,
      'status': _statusToString(session.status),
      'startTime': Timestamp.fromDate(session.startTime),
      if (session.endTime != null)
        'endTime': Timestamp.fromDate(session.endTime!),
      'totalScore': session.totalScore,
      'passesLeft': session.passesLeft,
      'casesCompleted': session.casesCompleted,
      'totalCases': session.totalCases,
      // NEDEN: cases array — her vakanın sonucu nested map olarak saklanır.
      'cases': session.caseResults
          .map(CaseResultModel.toFirestore)
          .toList(),
    };
  }

  /// Firestore document → GameSession entity.
  ///
  /// NEDEN: Oyun geçmişi çekerken Firestore Map'i entity'ye dönüştürülür.
  /// cases listesi MedicalCase'leri içermez (sadece sonuçlar).
  /// Tam vaka bilgisi gerekiyorsa ayrıca cases/ collection'dan çekilir.
  static GameSession fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<MedicalCase> cases = const [],
  }) {
    final data = doc.data()!;

    return GameSession(
      id: doc.id,
      mode: _parseGameMode(data['mode'] as String),
      status: _parseGameStatus(data['status'] as String),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      cases: cases,
      currentCaseIndex: _parseCaseResults(data['cases']).length,
      caseResults: _parseCaseResults(data['cases']),
      passesLeft: data['passesLeft'] as int? ?? 0,
      totalScore: (data['totalScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PARSING HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// NEDEN: Firestore string → GameMode enum.
  /// Bilinmeyen mod gelirse rush'a fallback (crash önleme).
  static GameMode _parseGameMode(String value) {
    return GameMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => GameMode.rush,
    );
  }

  /// NEDEN: Firestore status string → GameStatus enum.
  /// database_schema.md: "in_progress" | "completed" | "abandoned" | "timeout"
  /// Entity'deki enum camelCase, Firestore'daki snake_case.
  static GameStatus _parseGameStatus(String value) {
    switch (value) {
      case 'in_progress':
        return GameStatus.inProgress;
      case 'completed':
        return GameStatus.completed;
      case 'abandoned':
        return GameStatus.abandoned;
      case 'timeout':
        return GameStatus.timeout;
      default:
        return GameStatus.inProgress;
    }
  }

  /// NEDEN: GameStatus enum → Firestore snake_case string.
  static String _statusToString(GameStatus status) {
    switch (status) {
      case GameStatus.inProgress:
        return 'in_progress';
      case GameStatus.completed:
        return 'completed';
      case GameStatus.abandoned:
        return 'abandoned';
      case GameStatus.timeout:
        return 'timeout';
    }
  }

  /// NEDEN: Firestore cases array → List<CaseResult>.
  static List<CaseResult> _parseCaseResults(dynamic data) {
    if (data == null) return [];
    final list = data as List<dynamic>;
    return list
        .map((item) =>
            CaseResultModel.fromFirestore(item as Map<String, dynamic>))
        .toList();
  }
}

/// CaseResult nested model — Firestore dönüşümü.
///
/// NEDEN: database_schema.md § CaseResult şemasına birebir uyumlu.
/// GameModel içinde kullanılır, ayrı dosya gereksiz (tek kullanım noktası).
class CaseResultModel {
  /// CaseResult entity → Firestore Map.
  ///
  /// NEDEN: Oyun kaydederken her vaka sonucu Map'e çevrilir.
  /// Timestamp kullanımı server-side validation için gerekli
  /// (vcguide.md § Timer System: client timer = UI only).
  static Map<String, dynamic> toFirestore(CaseResult result) {
    return {
      'caseId': result.caseId,
      'testsRequested': result.testsRequested,
      'diagnosis': result.diagnosis ?? '',
      'isCorrect': result.isCorrect,
      'timeSpent': result.timeSpent,
      'timeLeft': result.timeLeft,
      // NEDEN: Score validation — vcguide.md § Edge Case 2.
      // Client'tan gelen skor 0-12 aralığında olmalı.
      'score': result.score.clamp(0.0, 12.0),
    };
  }

  /// Firestore Map → CaseResult entity.
  static CaseResult fromFirestore(Map<String, dynamic> data) {
    return CaseResult(
      caseId: data['caseId'] as String,
      testsRequested: _parseStringList(data['testsRequested']),
      diagnosis: data['diagnosis'] as String?,
      isCorrect: data['isCorrect'] as bool? ?? false,
      timeSpent: data['timeSpent'] as int? ?? 0,
      timeLeft: data['timeLeft'] as int? ?? 0,
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    return (data as List<dynamic>).cast<String>();
  }
}
