// lib/features/game/data/datasources/firestore_case_datasource.dart
//
// NEDEN: Firestore'dan tıbbi vakaları çeken data source.
// Sprint 4 — MockCases yerine gerçek Firestore verisi.
// LocalGameRepository → FirebaseGameRepository bu datasource'u kullanacak.
//
// Referans: database_schema.md § cases/{caseId}
//           database_schema.md § Query Patterns (Select Random Cases)
//           CLAUDE.md § Firestore Cost Optimization

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/medical_case.dart';
import '../datasources/mock_cases.dart';
import '../models/case_model.dart';

/// Firestore case datasource — cases collection'dan veri çeker.
///
/// NEDEN: Data source layer doğrudan Firestore SDK ile konuşur.
/// Repository bu class'ı sarmalayıp Either<Failure, T> döndürür.
class FirestoreCaseDatasource {
  final FirebaseFirestore _firestore;

  // NEDEN: DI ile test edilebilirlik. Mock Firestore inject edilebilir.
  FirestoreCaseDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore cases collection referansı (public — correctDiagnosis yok).
  CollectionReference<Map<String, dynamic>> get _casesRef =>
      _firestore.collection('cases');

  /// NEDEN: cases_private — correctDiagnosis + alternativeDiagnoses burada.
  /// DevTools'ta cases incelendiğinde doğru cevap görünmez.
  /// Sprint 5 güvenlik taşıması (MVP ara çözümü).
  CollectionReference<Map<String, dynamic>> get _casesPrivateRef =>
      _firestore.collection('cases_private');

  /// Belirli bir vakayı ID ile getir.
  ///
  /// NEDEN: Test sonucu gösterme ve vaka detayı için tek document okuma.
  /// cases + cases_private paralel okunur (maliyet: 2 read).
  Future<MedicalCase> getCaseById(String caseId) async {
    // NEDEN: Paralel fetch — cases + cases_private aynı anda.
    final results = await Future.wait([
      _casesRef.doc(caseId).get(),
      _casesPrivateRef.doc(caseId).get(),
    ]);

    final doc = results[0];
    final privateDoc = results[1];

    if (!doc.exists) {
      throw Exception('Case not found: $caseId');
    }

    final medicalCase = CaseModel.fromFirestore(doc);

    // NEDEN: cases_private'tan correctDiagnosis + alternativeDiagnoses al.
    if (privateDoc.exists && privateDoc.data() != null) {
      return CaseModel.enrichWithPrivateData(medicalCase, privateDoc.data()!);
    }

    return medicalCase;
  }

  /// Rastgele vakalar getir — oyun başlangıcında kullanılır.
  ///
  /// NEDEN: Firestore native random query desteklemez.
  /// Strateji: isActive vakaları çek, client-side shuffle yap.
  /// [count] kadar vaka döndür.
  ///
  /// Maliyet: En fazla [_maxPoolSize] read (aktif vakalar).
  /// database_schema.md § Select Random Cases — Cloud Function alternatifi
  /// ileride eklenecek, şimdilik client-side yeterli (50 vaka MVP).
  ///
  /// Opsiyonel [specialty] ve [difficulty] filtreleri Branch Mode için.
  Future<List<MedicalCase>> getRandomCases({
    required int count,
    Specialty? specialty,
    CaseDifficulty? difficulty,
  }) async {
    // NEDEN: Tüm aktif vakaları çekip client-side shuffle.
    // MVP'de 50 vaka var — maliyet kabul edilebilir.
    // 200+ vaka olduğunda Cloud Function'a geçilecek.
    Query<Map<String, dynamic>> query =
        _casesRef.where('isActive', isEqualTo: true);

    // NEDEN: Branch Mode'da specialty filtresi.
    // Composite index gerekli: specialty + isActive (database_schema.md § Indexes).
    if (specialty != null) {
      query = query.where('specialty', isEqualTo: specialty.name);
    }

    // NEDEN: Difficulty filtresi — vaka seçim algoritmasında
    // zorluk dağılımı sağlamak için (2 easy, 2 medium, 1 hard).
    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty.name);
    }

    // NEDEN: Havuz boyutunu sınırla — Firestore read maliyeti.
    // 50 vaka × 1 read = $0.00018. Kabul edilebilir.
    final snapshot = await query.limit(_maxPoolSize).get();

    if (snapshot.docs.length < count) {
      throw Exception(
        'Yeterli vaka yok. Gereken: $count, Mevcut: ${snapshot.docs.length}',
      );
    }

    // NEDEN: Client-side shuffle — her oyunda farklı sıralama.
    final cases = snapshot.docs.map(CaseModel.fromFirestore).toList()..shuffle();

    final selected = cases.take(count).toList();

    // NEDEN: Sadece seçilen vakalar için cases_private'tan correctDiagnosis al.
    // Havuzdaki 50 vakanın hepsini okumak gereksiz maliyet (50 yerine 5 read).
    return _enrichCasesWithPrivateData(selected);
  }

  /// Specialty + difficulty ile filtrelenmiş vakaları getir.
  ///
  /// NEDEN: Vaka seçim algoritması zorluk dağılımı uygulamak için
  /// her difficulty'den ayrı ayrı çekebilir (2 easy, 2 medium, 1 hard).
  /// Maliyet: difficulty başına 1 query = 3 read batch.
  Future<List<MedicalCase>> getCasesByFilter({
    Specialty? specialty,
    CaseDifficulty? difficulty,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query =
        _casesRef.where('isActive', isEqualTo: true);

    if (specialty != null) {
      query = query.where('specialty', isEqualTo: specialty.name);
    }

    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty.name);
    }

    // NEDEN: Pagination — CLAUDE.md § Firestore Cost Optimization.
    // Maksimum 20 vaka, daha fazlası için cursor-based pagination gerekir.
    final snapshot = await query.limit(limit).get();

    final cases = snapshot.docs.map(CaseModel.fromFirestore).toList();

    // NEDEN: cases_private'tan correctDiagnosis zenginleştirme.
    return _enrichCasesWithPrivateData(cases);
  }

  /// Birden fazla vakayı ID listesiyle getir.
  ///
  /// NEDEN: Cloud Function'dan gelen case ID listesiyle bulk fetch.
  /// whereIn max 30 element destekler — 5 vaka için yeterli.
  /// Maliyet: 1 query (whereIn tek sorgu).
  ///
  /// Referans: CLAUDE.md § "Use whereIn() instead of multiple individual queries"
  Future<List<MedicalCase>> getCasesByIds(List<String> caseIds) async {
    if (caseIds.isEmpty) return [];

    // NEDEN: Firestore whereIn limiti 30 element.
    // casesPerGame = 5, asla aşılmaz.
    assert(caseIds.length <= 30, 'whereIn max 30 element destekler');

    final snapshot = await _casesRef
        .where(FieldPath.documentId, whereIn: caseIds)
        .get();

    // NEDEN: whereIn sıralama garantisi vermez.
    // ID sırasını koru — PvP'de her iki oyuncu aynı sırayı görmeli.
    final caseMap = {
      for (final doc in snapshot.docs) doc.id: CaseModel.fromFirestore(doc),
    };

    final orderedCases = caseIds
        .where(caseMap.containsKey)
        .map((id) => caseMap[id]!)
        .toList();

    // NEDEN: cases_private'tan correctDiagnosis zenginleştirme.
    return _enrichCasesWithPrivateData(orderedCases);
  }

  // ═══════════════════════════════════════════════════════════════
  // SEED (Debug Only)
  // ═══════════════════════════════════════════════════════════════

  /// MockCases'taki 5 vakayı Firestore'a batch write ile yükler.
  ///
  /// NEDEN: Sprint 4 geçişi — Firestore'a ilk veri yükleme.
  /// Sprint 5: Public veri cases'e, private veri cases_private'a yazılır.
  /// Sadece debug modda çağrılır (kDebugMode guard home_page'de).
  /// Idempotent: Her collection bağımsız kontrol edilir.
  /// Document ID'ler: case_001, case_002, ... (mock_cases.dart'taki id'ler).
  /// Maliyet: 5×2 read (cases + cases_private exists check) + N write.
  Future<int> seedCases() async {
    assert(kDebugMode, 'seedCases() sadece debug modda çağrılmalı');

    final batch = _firestore.batch();
    int publicAdded = 0;
    int privateAdded = 0;
    int migrated = 0;

    for (final medicalCase in MockCases.allCases) {
      // NEDEN: cases ve cases_private bağımsız kontrol edilir.
      // Eski seed'ler sadece cases'e yazdı — cases_private eksik olabilir.
      // Her iki collection'ı ayrı ayrı kontrol et → migration-safe.
      final docRef = _casesRef.doc(medicalCase.id);
      final privateDocRef = _casesPrivateRef.doc(medicalCase.id);

      final results = await Future.wait([
        docRef.get(),
        privateDocRef.get(),
      ]);

      final publicDoc = results[0];
      final privateExists = results[1].exists;

      if (!publicDoc.exists) {
        batch.set(docRef, CaseModel.toFirestore(medicalCase));
        publicAdded++;
      } else {
        // NEDEN: Migration — eski cases doc'larında correctDiagnosis kalmış olabilir.
        // Security review: cases collection'da doğru cevap kalırsa tüm taşıma boşa gider.
        // FieldValue.delete() ile sadece o alanlar silinir, diğer veriye dokunulmaz.
        final data = publicDoc.data();
        if (data != null && data.containsKey('correctDiagnosis')) {
          batch.update(docRef, {
            'correctDiagnosis': FieldValue.delete(),
            'alternativeDiagnoses': FieldValue.delete(),
          });
          migrated++;
        }
      }

      if (!privateExists) {
        batch.set(privateDocRef, CaseModel.toFirestorePrivate(medicalCase));
        privateAdded++;
      }
    }

    if (publicAdded > 0 || privateAdded > 0 || migrated > 0) {
      await batch.commit();
    }

    debugPrint('Seed: cases=$publicAdded eklendi, '
        'cases_private=$privateAdded eklendi, '
        'migrated=$migrated (correctDiagnosis silindi), '
        '${MockCases.allCases.length} toplam vaka.');

    return publicAdded + privateAdded + migrated;
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE DATA ENRICHMENT
  // ═══════════════════════════════════════════════════════════════

  /// cases_private'tan correctDiagnosis + alternativeDiagnoses alıp
  /// MedicalCase listesine birleştirir.
  ///
  /// NEDEN: cases collection'da correctDiagnosis yok (Sprint 5 güvenlik).
  /// Firestore rules cases_private'ta list=false → whereIn query YASAK.
  /// Tek tek get ile paralel fetch yapılır (Future.wait).
  /// Maliyet: N read (casesPerGame=5 → 5 paralel get).
  Future<List<MedicalCase>> _enrichCasesWithPrivateData(
    List<MedicalCase> cases,
  ) async {
    if (cases.isEmpty) return cases;

    // NEDEN: cases_private'ta list=false (security review).
    // whereIn = list query → permission-denied olur.
    // Tek tek doc.get() ile paralel fetch — güvenli ve hızlı.
    final privateDocs = await Future.wait(
      cases.map((c) => _casesPrivateRef.doc(c.id).get()),
    );

    final privateMap = {
      for (final doc in privateDocs)
        if (doc.exists && doc.data() != null) doc.id: doc.data()!,
    };

    return cases.map((medicalCase) {
      final privateData = privateMap[medicalCase.id];
      if (privateData != null) {
        return CaseModel.enrichWithPrivateData(medicalCase, privateData);
      }
      return medicalCase;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // CONSTANTS
  // ═══════════════════════════════════════════════════════════════

  /// NEDEN: Tek seferde çekilecek maksimum vaka sayısı.
  /// MVP'de 50 vaka, ileride artarsa bu limit read maliyetini kontrol eder.
  static const int _maxPoolSize = 50;
}
