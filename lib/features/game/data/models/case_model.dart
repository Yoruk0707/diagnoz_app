// lib/features/game/data/models/case_model.dart
//
// NEDEN: MedicalCase entity <-> Firestore document dönüşümü.
// Domain layer Firestore'u bilmez — bu model köprü görevi görür.
//
// Referans: database_schema.md § cases/{caseId}
//           medical_case.dart entity yapısı
//           mock_cases.dart mevcut veri formatı

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/medical_case.dart';

/// Firestore ↔ MedicalCase dönüşüm modeli.
///
/// NEDEN: Clean Architecture — data layer Firestore Map'lerini
/// domain entity'ye çevirir. Entity Firestore'dan habersiz kalır.
class CaseModel {
  /// Firestore document → MedicalCase entity.
  ///
  /// NEDEN: Firestore'dan gelen Map<String, dynamic>'i domain entity'ye
  /// dönüştürüyor. Null-safe parsing ile eksik alanlarda crash önlenir.
  static MedicalCase fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return MedicalCase(
      id: doc.id,
      specialty: _parseSpecialty(data['specialty'] as String),
      difficulty: _parseDifficulty(data['difficulty'] as String),
      patientProfile: _parsePatientProfile(
        data['patientProfile'] as Map<String, dynamic>,
      ),
      vitals: _parseVitals(data['vitals'] as Map<String, dynamic>),
      history: _parseStringMap(data['history']),
      physicalExam: _parseStringMap(data['physicalExam']),
      availableTests: _parseAvailableTests(data['availableTests']),
      testResults: _parseTestResults(data['testResults']),
      // NEDEN: cases collection'da correctDiagnosis artık yok (Sprint 5 güvenlik).
      // cases_private'tan enrichWithPrivateData() ile doldurulur.
      // Geriye uyumluluk: eski seed'li dökümanlar hâlâ bu alana sahip olabilir.
      correctDiagnosis: data['correctDiagnosis'] as String? ?? '',
      alternativeDiagnoses: _parseStringList(data['alternativeDiagnoses']),
      explanation: data['explanation'] as String? ?? '',
      keyFindings: _parseStringList(data['keyFindings']),
    );
  }

  /// MedicalCase entity → Firestore document Map.
  ///
  /// NEDEN: seed_cases.dart ve Cloud Functions'dan Firestore'a yazarken
  /// entity'yi Map'e çeviriyoruz. analytics alanı server-side eklenir.
  static Map<String, dynamic> toFirestore(MedicalCase medicalCase) {
    return {
      'specialty': medicalCase.specialty.name,
      'difficulty': medicalCase.difficulty.name,
      'isActive': true,
      'patientProfile': {
        'age': medicalCase.patientProfile.age,
        'gender': medicalCase.patientProfile.gender,
        'chiefComplaint': medicalCase.patientProfile.chiefComplaint,
      },
      'vitals': {
        'bp': medicalCase.vitals.bp,
        'hr': medicalCase.vitals.hr,
        'temp': medicalCase.vitals.temp,
        'rr': medicalCase.vitals.rr,
        'spo2': medicalCase.vitals.spo2,
      },
      if (medicalCase.history != null) 'history': medicalCase.history,
      if (medicalCase.physicalExam != null)
        'physicalExam': medicalCase.physicalExam,
      'availableTests': _availableTestsToFirestore(medicalCase.availableTests),
      'testResults': _testResultsToFirestore(medicalCase.testResults),
      // NEDEN: correctDiagnosis + alternativeDiagnoses cases collection'a YAZILMAZ.
      // Sprint 5 güvenlik: Bu veriler cases_private koleksiyonunda saklanır.
      // DevTools'ta cases incelendiğinde doğru cevap görünmez.
      'explanation': medicalCase.explanation,
      'keyFindings': medicalCase.keyFindings,
      // NEDEN: analytics alanı sıfırdan başlar, Cloud Functions günceller.
      'analytics': {
        'timesPresented': 0,
        'timesSolved': 0,
        'averageTimeSpent': 0,
        'mostRequestedTest': '',
      },
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE DATA (cases_private collection)
  // ═══════════════════════════════════════════════════════════════

  /// MedicalCase → cases_private document Map.
  ///
  /// NEDEN: Seed ve Cloud Functions cases_private'a bu veriyi yazar.
  /// Sadece correctDiagnosis + alternativeDiagnoses — minimum veri prensibi.
  static Map<String, dynamic> toFirestorePrivate(MedicalCase medicalCase) {
    return {
      'correctDiagnosis': medicalCase.correctDiagnosis,
      'alternativeDiagnoses': medicalCase.alternativeDiagnoses,
    };
  }

  /// cases_private verisini MedicalCase entity'ye birleştir.
  ///
  /// NEDEN: cases collection'dan gelen entity'de correctDiagnosis boş.
  /// cases_private'tan okunan veri ile zenginleştirilir.
  /// Yeni MedicalCase döner (immutable pattern).
  static MedicalCase enrichWithPrivateData(
    MedicalCase base,
    Map<String, dynamic> privateData,
  ) {
    return MedicalCase(
      id: base.id,
      specialty: base.specialty,
      difficulty: base.difficulty,
      patientProfile: base.patientProfile,
      vitals: base.vitals,
      history: base.history,
      physicalExam: base.physicalExam,
      availableTests: base.availableTests,
      testResults: base.testResults,
      correctDiagnosis: privateData['correctDiagnosis'] as String? ?? '',
      alternativeDiagnoses:
          _parseStringList(privateData['alternativeDiagnoses']),
      explanation: base.explanation,
      keyFindings: base.keyFindings,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PARSING HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// NEDEN: Firestore'daki string → enum dönüşümü.
  /// Bilinmeyen specialty gelirse emergency'ye fallback (crash önleme).
  static Specialty _parseSpecialty(String value) {
    return Specialty.values.firstWhere(
      (s) => s.name == value,
      orElse: () => Specialty.emergency,
    );
  }

  /// NEDEN: Bilinmeyen difficulty gelirse medium'a fallback.
  static CaseDifficulty _parseDifficulty(String value) {
    return CaseDifficulty.values.firstWhere(
      (d) => d.name == value,
      orElse: () => CaseDifficulty.medium,
    );
  }

  static PatientProfile _parsePatientProfile(Map<String, dynamic> data) {
    return PatientProfile(
      age: data['age'] as int,
      gender: data['gender'] as String,
      chiefComplaint: data['chiefComplaint'] as String,
    );
  }

  static Vitals _parseVitals(Map<String, dynamic> data) {
    return Vitals(
      bp: data['bp'] as String,
      hr: data['hr'] as int,
      temp: (data['temp'] as num).toDouble(),
      rr: data['rr'] as int,
      spo2: data['spo2'] as int,
    );
  }

  /// NEDEN: Optional Map<String, String> alanları (history, physicalExam)
  /// Firestore'da null olabilir — Zen Mode'da kullanılır, Rush'ta gizli.
  static Map<String, String>? _parseStringMap(dynamic data) {
    if (data == null) return null;
    final map = data as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(key, value as String));
  }

  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    return (data as List<dynamic>).cast<String>();
  }

  /// NEDEN: availableTests Firestore'da categorized map olarak saklanıyor
  /// (database_schema.md § availableTests) ama entity'de flat List<TestResult>.
  /// Firestore yapısı: { lab: [...], imaging: [...], ecg: [...], special: [...] }
  /// Entity yapısı: List<TestResult> (mock_cases.dart ile uyumlu).
  static List<TestResult> _parseAvailableTests(dynamic data) {
    if (data == null) return [];

    // NEDEN: Firestore'da iki format destekleniyor:
    // 1. Flat list (seed_cases.dart ile yüklenen)
    // 2. Categorized map (database_schema.md formatı)
    if (data is List) {
      return _parseTestResultList(data);
    }

    final map = data as Map<String, dynamic>;
    final tests = <TestResult>[];

    // NEDEN: Her kategoriyi dolaş ve flat listeye dönüştür.
    for (final entry in map.entries) {
      final category = _parseTestCategory(entry.key);
      final testList = entry.value as List<dynamic>? ?? [];
      for (final testData in testList) {
        tests.add(_parseSingleTestResult(
          testData as Map<String, dynamic>,
          category,
        ));
      }
    }

    return tests;
  }

  static List<TestResult> _parseTestResultList(List<dynamic> list) {
    return list.map((item) {
      final data = item as Map<String, dynamic>;
      final category = _parseTestCategory(data['category'] as String);
      return _parseSingleTestResult(data, category);
    }).toList();
  }

  static TestResult _parseSingleTestResult(
    Map<String, dynamic> data,
    TestCategory category,
  ) {
    return TestResult(
      testId: data['testId'] as String,
      category: category,
      displayName: data['displayName'] as String,
      value: data['value'] as String?,
      interpretation: data['interpretation'] as String?,
      imageUrl: data['imageUrl'] as String?,
      findings: data['findings'] as String?,
      isAbnormal: data['isAbnormal'] as bool? ?? false,
    );
  }

  static TestCategory _parseTestCategory(String value) {
    return TestCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => TestCategory.lab,
    );
  }

  /// NEDEN: testResults entity'de Map<String, TestResult> ama Firestore'da
  /// Map<String, Map>. Boş map ile başlar, test istenince dolmaz
  /// (client-side availableTests'ten populate edilir).
  static Map<String, TestResult> _parseTestResults(dynamic data) {
    if (data == null || data is! Map) return {};
    final map = data as Map<String, dynamic>;

    return map.map((key, value) {
      final testData = value as Map<String, dynamic>;
      final category = _parseTestCategory(testData['category'] as String);
      return MapEntry(key, _parseSingleTestResult(testData, category));
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // SERIALIZATION HELPERS (Entity → Firestore)
  // ═══════════════════════════════════════════════════════════════

  /// NEDEN: availableTests'i Firestore'a flat list olarak yazıyoruz.
  /// Seed script ve Cloud Functions bu formatı kullanır.
  static List<Map<String, dynamic>> _availableTestsToFirestore(
    List<TestResult> tests,
  ) {
    return tests.map((test) {
      return {
        'testId': test.testId,
        'category': test.category.name,
        'displayName': test.displayName,
        if (test.value != null) 'value': test.value,
        if (test.interpretation != null)
          'interpretation': test.interpretation,
        if (test.imageUrl != null) 'imageUrl': test.imageUrl,
        if (test.findings != null) 'findings': test.findings,
        'isAbnormal': test.isAbnormal,
      };
    }).toList();
  }

  /// NEDEN: testResults başlangıçta boş map. Entity'deki map'i
  /// Firestore formatına çevirir (genelde seed'de boş olacak).
  static Map<String, dynamic> _testResultsToFirestore(
    Map<String, TestResult> testResults,
  ) {
    return testResults.map((key, test) {
      return MapEntry(key, {
        'testId': test.testId,
        'category': test.category.name,
        'displayName': test.displayName,
        if (test.value != null) 'value': test.value,
        if (test.interpretation != null)
          'interpretation': test.interpretation,
        if (test.imageUrl != null) 'imageUrl': test.imageUrl,
        if (test.findings != null) 'findings': test.findings,
        'isAbnormal': test.isAbnormal,
      });
    });
  }
}
