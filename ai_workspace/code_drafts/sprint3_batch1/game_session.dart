// lib/features/game/domain/entities/game_session.dart
//
// NEDEN: database_schema.md § games/{gameId} şemasına uyumlu.
// Bir oyun oturumunun tüm state'ini tutar.
// Client-side game logic bu entity üzerinden yürür.
//
// Referans: masterplan.md § Rush Mode, § Pass System, § Scoring
//           vcguide.md § Timer System, § Score Calculation
//           app_constants.dart (sabitler)

import 'package:equatable/equatable.dart';

import 'medical_case.dart';

// ═══════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════

/// Oyun modu — masterplan.md § Game Modes.
enum GameMode { rush, zen, pvp, branch }

/// Oyun durumu — database_schema.md § games/{gameId}.status
enum GameStatus { inProgress, completed, abandoned, timeout }

// ═══════════════════════════════════════════════════════════════
// CASE RESULT
// ═══════════════════════════════════════════════════════════════

/// Tek bir vakanın sonucu — database_schema.md § CaseResult.
class CaseResult extends Equatable {
  final String caseId;
  final List<String> testsRequested;
  final String? diagnosis;
  final bool isCorrect;
  final int timeSpent; // saniye
  final int timeLeft; // kalan saniye
  final double score;

  const CaseResult({
    required this.caseId,
    this.testsRequested = const [],
    this.diagnosis,
    this.isCorrect = false,
    this.timeSpent = 0,
    this.timeLeft = 0,
    this.score = 0.0,
  });

  /// NEDEN: Skor formülü masterplan.md'den: (timeLeft / 100) * 10
  /// 120s = 12.0 puan (max), 0s = 0.0 puan.
  /// vcguide.md § Edge Case 2: negatif ve overflow koruması.
  static double calculateScore(int timeLeft) {
    if (timeLeft <= 0) return 0.0;
    if (timeLeft > 120) return 12.0; // NEDEN: Manipülasyon koruması
    return (timeLeft / 100) * 10;
  }

  /// Yeni test eklenerek güncelleme — immutable pattern.
  CaseResult copyWith({
    List<String>? testsRequested,
    String? diagnosis,
    bool? isCorrect,
    int? timeSpent,
    int? timeLeft,
    double? score,
  }) {
    return CaseResult(
      caseId: caseId,
      testsRequested: testsRequested ?? this.testsRequested,
      diagnosis: diagnosis ?? this.diagnosis,
      isCorrect: isCorrect ?? this.isCorrect,
      timeSpent: timeSpent ?? this.timeSpent,
      timeLeft: timeLeft ?? this.timeLeft,
      score: score ?? this.score,
    );
  }

  @override
  List<Object?> get props => [caseId, diagnosis, isCorrect, score];
}

// ═══════════════════════════════════════════════════════════════
// MAIN ENTITY
// ═══════════════════════════════════════════════════════════════

/// Oyun oturumu entity'si — database_schema.md § games/{gameId}.
///
/// NEDEN: Immutable. Her state değişikliğinde yeni instance oluşur.
/// Bu sayede Riverpod state yönetimi temiz kalır.
class GameSession extends Equatable {
  final String id;
  final GameMode mode;
  final GameStatus status;
  final DateTime startTime;
  final DateTime? endTime;

  // NEDEN: cases = oyundaki 5 vaka, currentCaseIndex = aktif vaka.
  final List<MedicalCase> cases;
  final int currentCaseIndex;

  // NEDEN: Her vakanın sonucu ayrı tutulur — skorlama ve geçmiş için.
  final List<CaseResult> caseResults;

  // NEDEN: passesLeft oyun genelinde 2 — masterplan.md § Pass System.
  // Vaka başına değil, oyun başına.
  final int passesLeft;

  // NEDEN: totalScore = tamamlanan vakaların skor toplamı.
  final double totalScore;

  const GameSession({
    required this.id,
    required this.mode,
    this.status = GameStatus.inProgress,
    required this.startTime,
    this.endTime,
    required this.cases,
    this.currentCaseIndex = 0,
    this.caseResults = const [],
    this.passesLeft = 2,
    this.totalScore = 0.0,
  });

  // ═══════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════

  /// Aktif vaka. Null = tüm vakalar bitti.
  MedicalCase? get currentCase =>
      currentCaseIndex < cases.length ? cases[currentCaseIndex] : null;

  /// Tamamlanan vaka sayısı.
  int get casesCompleted => caseResults.length;

  /// Toplam vaka sayısı.
  int get totalCases => cases.length;

  /// Oyun bitti mi?
  bool get isGameOver => status != GameStatus.inProgress;

  /// Tüm vakalar tamamlandı mı? (Victory)
  bool get isVictory =>
      status == GameStatus.completed &&
      casesCompleted == totalCases;

  // ═══════════════════════════════════════════════════════════════
  // COPY WITH — Immutable state updates
  // ═══════════════════════════════════════════════════════════════

  GameSession copyWith({
    GameStatus? status,
    DateTime? endTime,
    int? currentCaseIndex,
    List<CaseResult>? caseResults,
    int? passesLeft,
    double? totalScore,
  }) {
    return GameSession(
      id: id,
      mode: mode,
      status: status ?? this.status,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      cases: cases,
      currentCaseIndex: currentCaseIndex ?? this.currentCaseIndex,
      caseResults: caseResults ?? this.caseResults,
      passesLeft: passesLeft ?? this.passesLeft,
      totalScore: totalScore ?? this.totalScore,
    );
  }

  @override
  List<Object?> get props => [id, status, currentCaseIndex, totalScore];
}
