// lib/features/game/domain/entities/medical_case.dart
//
// NEDEN: database_schema.md § cases/{caseId} şemasına birebir uyumlu.
// Rush Mode'da sadece patientProfile + vitals + availableTests görünür.
// Zen Mode'da history, physicalExam, explanation da gösterilir.
//
// Referans: masterplan.md § Core Game Loop, § Test Request System
//           database_schema.md § cases/{caseId}

import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════

/// Tıbbi uzmanlık dalları — database_schema.md'den.
enum Specialty {
  emergency,
  cardiology,
  neurology,
  pediatrics,
  surgery,
  infectious,
  internal,
  pulmonology,
  gastroenterology,
  nephrology,
  endocrinology,
  psychiatry,
  dermatology,
  orthopedics,
}

/// Vaka zorluk seviyesi.
enum CaseDifficulty { easy, medium, hard }

/// Test kategorileri — masterplan.md § Test Request System.
/// NEDEN: Her kategori -10s, aynı test tekrar istenirse ücret yok (idempotency).
enum TestCategory { lab, imaging, ecg, special }

// ═══════════════════════════════════════════════════════════════
// VALUE OBJECTS
// ═══════════════════════════════════════════════════════════════

/// Hasta profili — her modda gösterilir.
class PatientProfile extends Equatable {
  final int age;
  final String gender; // "male", "female", "other"
  final String chiefComplaint;

  const PatientProfile({
    required this.age,
    required this.gender,
    required this.chiefComplaint,
  });

  @override
  List<Object?> get props => [age, gender, chiefComplaint];
}

/// Vital bulgular — her modda gösterilir.
class Vitals extends Equatable {
  final String bp; // "140/90"
  final int hr;
  final double temp;
  final int rr;
  final int spo2;

  const Vitals({
    required this.bp,
    required this.hr,
    required this.temp,
    required this.rr,
    required this.spo2,
  });

  @override
  List<Object?> get props => [bp, hr, temp, rr, spo2];
}

/// Tek bir test sonucu.
class TestResult extends Equatable {
  final String testId;
  final TestCategory category;
  final String displayName;
  final String? value;
  final String? interpretation;
  final String? imageUrl;
  final String? findings;
  final bool isAbnormal;

  const TestResult({
    required this.testId,
    required this.category,
    required this.displayName,
    this.value,
    this.interpretation,
    this.imageUrl,
    this.findings,
    this.isAbnormal = false,
  });

  @override
  List<Object?> get props => [testId, category, displayName];
}

// ═══════════════════════════════════════════════════════════════
// MAIN ENTITY
// ═══════════════════════════════════════════════════════════════

/// Tıbbi vaka entity'si — database_schema.md § cases/{caseId}.
///
/// NEDEN: Immutable entity. Firestore'dan gelen veri bu yapıya map'lenir.
/// Rush Mode'da sadece [patientProfile], [vitals], [availableTests] kullanılır.
/// Zen Mode'da tüm alanlar gösterilir.
class MedicalCase extends Equatable {
  final String id;
  final Specialty specialty;
  final CaseDifficulty difficulty;

  // NEDEN: Her modda görünür — temel hasta bilgisi.
  final PatientProfile patientProfile;
  final Vitals vitals;

  // NEDEN: Zen Mode'da gösterilir, Rush'ta gizli.
  final Map<String, String>? history; // medicalHistory, medications vs.
  final Map<String, String>? physicalExam; // cardiovascular, respiratory vs.

  // NEDEN: Test isteme sistemi — masterplan.md § Test Request System.
  // Key = testId ("lab_cbc", "ecg_12_lead" vb.), Value = TestResult.
  // availableTests: bu vakada istenebilecek testler.
  // testResults: test sonuçları (istenince görünür).
  final List<TestResult> availableTests;
  final Map<String, TestResult> testResults;

  // NEDEN: Tanı doğrulama — correctDiagnosis ile karşılaştırılır.
  final String correctDiagnosis;
  final List<String> alternativeDiagnoses;

  // NEDEN: Zen Mode educational feedback.
  final String explanation;
  final List<String> keyFindings;

  const MedicalCase({
    required this.id,
    required this.specialty,
    required this.difficulty,
    required this.patientProfile,
    required this.vitals,
    this.history,
    this.physicalExam,
    required this.availableTests,
    required this.testResults,
    required this.correctDiagnosis,
    this.alternativeDiagnoses = const [],
    this.explanation = '',
    this.keyFindings = const [],
  });

  @override
  List<Object?> get props => [id];
}
