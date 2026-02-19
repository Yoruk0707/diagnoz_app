// lib/features/game/presentation/providers/game_state.dart
//
// NEDEN: Auth pattern'ını takip eder (abstract base + concrete subclasses).
// Equatable ile state karşılaştırma, gereksiz rebuild önleme.
//
// Referans: auth_state.dart pattern'ı
//           masterplan.md § Game States

import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/medical_case.dart';

/// Game akışının base state'i.
abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

/// Oyun henüz başlamadı — ana ekranda "Oyna" butonu görünür.
class GameInitial extends GameState {
  const GameInitial();
}

/// Vakalar yükleniyor (oyun başlatılıyor).
///
/// NEDEN: UI'da loading spinner + buton disable.
class GameLoading extends GameState {
  const GameLoading();
}

/// Aktif oyun — vaka gösteriliyor, timer çalışıyor.
///
/// [session] tüm oyun state'i (vakalar, skor, paslar).
/// [timeLeft] kalan süre (saniye) — timer widget için.
/// [requestedTests] bu vakada istenen testler — UI'da göster.
/// [revealedTests] sonuçları açılmış testler — test sheet'te göster.
class GamePlaying extends GameState {
  final GameSession session;
  final int timeLeft;
  final List<String> requestedTests;
  final Map<String, TestResult> revealedTests;

  const GamePlaying({
    required this.session,
    required this.timeLeft,
    this.requestedTests = const [],
    this.revealedTests = const {},
  });

  /// NEDEN: Convenience getter — UI'da sık kullanılır.
  MedicalCase? get currentCase => session.currentCase;
  int get caseNumber => session.currentCaseIndex + 1;
  int get totalCases => session.totalCases;
  int get passesLeft => session.passesLeft;
  double get totalScore => session.totalScore;

  @override
  List<Object?> get props => [
        session,
        timeLeft,
        requestedTests,
        revealedTests,
      ];
}

/// Tanı sonucu gösteriliyor — doğru/yanlış feedback.
///
/// NEDEN: Sonuç ekranı 2-3 saniye gösterilir, sonra
/// sonraki vakaya geçilir veya oyun biter.
class GameCaseResult extends GameState {
  final GameSession session;
  final bool isCorrect;
  final double score;
  final String correctDiagnosis;
  final String userDiagnosis;

  const GameCaseResult({
    required this.session,
    required this.isCorrect,
    required this.score,
    required this.correctDiagnosis,
    required this.userDiagnosis,
  });

  @override
  List<Object?> get props => [session, isCorrect, score];
}

/// Oyun bitti — final skor gösteriliyor.
///
/// NEDEN: Oyun biter (tüm vakalar bitti veya eleme).
/// UI: skor özeti, tekrar oyna butonu.
///
/// [isSubmitting] Firestore'a skor kaydedilirken true.
/// [isSubmitted] Skor başarıyla kaydedildiyse true.
/// [submitError] Kayıt hatası mesajı (varsa).
///
/// NEDEN: vcguide.md § Edge Case 5 — UI'da duplicate submit koruması.
/// isSubmitting true iken "Tekrar Oyna" butonu gösterilmez.
class GameOver extends GameState {
  final GameSession session;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? submitError;

  const GameOver({
    required this.session,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.submitError,
  });

  double get totalScore => session.totalScore;
  int get casesCompleted => session.casesCompleted;
  int get totalCases => session.totalCases;
  bool get isVictory => session.isVictory;

  /// NEDEN: Immutable state update — Firestore submit durumu değişince.
  GameOver copyWith({
    bool? isSubmitting,
    bool? isSubmitted,
    String? submitError,
  }) {
    return GameOver(
      session: session,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      submitError: submitError ?? this.submitError,
    );
  }

  @override
  List<Object?> get props => [session, isSubmitting, isSubmitted, submitError];
}

/// Oyun sırasında hata oluştu.
///
/// NEDEN: auth_state.dart pattern'ı — previousState ile geri dönüş.
class GameError extends GameState {
  final Failure failure;
  final GameState previousState;

  const GameError({
    required this.failure,
    required this.previousState,
  });

  @override
  List<Object?> get props => [failure, previousState];
}
