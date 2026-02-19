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

import '../../domain/entities/medical_case.dart';
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

  /// Firestore cases collection referansı.
  CollectionReference<Map<String, dynamic>> get _casesRef =>
      _firestore.collection('cases');

  /// Belirli bir vakayı ID ile getir.
  ///
  /// NEDEN: Test sonucu gösterme ve vaka detayı için tek document okuma.
  /// Maliyet: 1 read.
  Future<MedicalCase> getCaseById(String caseId) async {
    final doc = await _casesRef.doc(caseId).get();

    if (!doc.exists) {
      throw Exception('Case not found: $caseId');
    }

    return CaseModel.fromFirestore(doc);
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

    return cases.take(count).toList();
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

    return snapshot.docs.map(CaseModel.fromFirestore).toList();
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

    return caseIds
        .where(caseMap.containsKey)
        .map((id) => caseMap[id]!)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // CONSTANTS
  // ═══════════════════════════════════════════════════════════════

  /// NEDEN: Tek seferde çekilecek maksimum vaka sayısı.
  /// MVP'de 50 vaka, ileride artarsa bu limit read maliyetini kontrol eder.
  static const int _maxPoolSize = 50;
}
