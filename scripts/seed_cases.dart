// scripts/seed_cases.dart
//
// ignore_for_file: avoid_print
//
// NEDEN: Mock vakaları Firestore'a yükleyen tek seferlik CLI script.
// MockCases.allCases'taki 5 vakayı cases/ collection'a batch write ile yazar.
// print kullanımı beklenen davranış — CLI output için gerekli.
//
// Kullanım:
//   cd diagnoz_app
//   dart run scripts/seed_cases.dart
//
// Ön koşul: Firebase proje yapılandırması (firebase_options.dart) mevcut olmalı.
//
// Referans: database_schema.md § cases/{caseId}
//           CLAUDE.md § Firestore Cost Optimization (batch write)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:diagnoz_app/features/game/data/datasources/mock_cases.dart';
import 'package:diagnoz_app/features/game/data/models/case_model.dart';
import 'package:diagnoz_app/firebase_options.dart';

Future<void> main() async {
  // NEDEN: Flutter widget binding olmadan Firebase init.
  // Script ortamında WidgetsFlutterBinding gereksiz.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  print('=== DiagnozApp Case Seeder ===');
  print('${MockCases.allCases.length} vaka Firestore\'a yuklenecek.\n');

  // NEDEN: Batch write — tum vakalar tek atomik islemde yazilir.
  // Bir vaka basarisiz olursa hicbiri yazilmaz (consistency).
  // Firestore batch limiti: 500 operation — 5 vaka icin yeterli.
  final batch = firestore.batch();

  for (final medicalCase in MockCases.allCases) {
    // NEDEN: Document ID olarak mevcut case ID'yi kullaniyoruz (case_001 vb.)
    // Boylece seed tekrar calistiginda upsert (overwrite) olur, duplikasyon olmaz.
    final docRef = firestore.collection('cases').doc(medicalCase.id);
    final data = CaseModel.toFirestore(medicalCase);

    batch.set(docRef, data);
    print('  [+] ${medicalCase.id}: ${medicalCase.correctDiagnosis}');
  }

  try {
    await batch.commit();
    print('\nBasarili! ${MockCases.allCases.length} vaka yuklendi.');
  } catch (e) {
    print('\nHata! Batch write basarisiz: $e');
    // NEDEN: Script basarisizsa non-zero exit code don.
    // CI/CD pipeline'da hata yakalanabilir.
    throw Exception('Seed failed: $e');
  }
}
