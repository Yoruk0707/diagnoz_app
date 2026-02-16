// lib/features/game/data/datasources/mock_cases.dart
//
// NEDEN: Sprint 3 — Firestore yerine hardcoded mock data.
// 5 gerçekçi tıbbi vaka, Türk tıp öğrencisi hedef kitle.
// Sprint 4'te bu dosya kaldırılıp Firestore'dan çekilecek.
//
// Referans: masterplan.md § Core Game Loop
//           database_schema.md § cases/{caseId}
//           medical_case.dart entity yapısı

import '../../domain/entities/medical_case.dart';

/// Mock vaka veritabanı — Sprint 3 MVP.
///
/// NEDEN: 5 vaka yeterli core loop test için.
/// Her vaka farklı uzmanlık dalı + zorluk seviyesi.
abstract class MockCases {
  /// Tüm mock vakalar.
  static final List<MedicalCase> allCases = [
    _case1AcuteMI,
    _case2Pneumonia,
    _case3Appendicitis,
    _case4Meningitis,
    _case5Pulmonaryembolism,
  ];

  // ═══════════════════════════════════════════════════════════
  // CASE 1: Akut Miyokard Enfarktüsü (Kardiyoloji - Orta)
  // ═══════════════════════════════════════════════════════════
  static final _case1AcuteMI = const MedicalCase(
    id: 'case_001',
    specialty: Specialty.cardiology,
    difficulty: CaseDifficulty.medium,
    patientProfile: const PatientProfile(
      age: 58,
      gender: 'male',
      chiefComplaint: 'Göğüs ağrısı, sol kola yayılan, 2 saattir devam ediyor',
    ),
    vitals: const Vitals(
      bp: '160/95',
      hr: 110,
      temp: 36.8,
      rr: 22,
      spo2: 94,
    ),
    history: const {
      'medicalHistory': 'Hipertansiyon (10 yıl), Tip 2 DM (5 yıl), Sigara (30 paket-yıl)',
      'medications': 'Amlodipin 10mg, Metformin 1000mg 2x1',
      'allergies': 'Bilinen alerji yok',
    },
    physicalExam: const {
      'cardiovascular': 'S3 galop ritmi, juguler venöz dolgunluk yok',
      'respiratory': 'Bilateral bazalde ince raller',
      'abdomen': 'Doğal',
    },
    availableTests: const [
      const TestResult(
        testId: 'lab_troponin',
        category: TestCategory.lab,
        displayName: 'Troponin I',
        value: '4.8 ng/mL',
        interpretation: 'Yüksek (Normal: <0.04 ng/mL)',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'lab_cbc',
        category: TestCategory.lab,
        displayName: 'Tam Kan Sayımı',
        value: 'WBC: 12.000, Hb: 14.2, Plt: 245.000',
        interpretation: 'Hafif lökositoz',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'ecg_12lead',
        category: TestCategory.ecg,
        displayName: '12 Derivasyon EKG',
        findings: 'V1-V4 derivasyonlarında ST elevasyonu, reciprocal ST depresyonu II, III, aVF',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'imaging_chest_xray',
        category: TestCategory.imaging,
        displayName: 'PA Akciğer Grafisi',
        findings: 'Hafif pulmoner konjesyon bulguları, kardiyomegali yok',
        isAbnormal: false,
      ),
      const TestResult(
        testId: 'lab_ck_mb',
        category: TestCategory.lab,
        displayName: 'CK-MB',
        value: '45 U/L',
        interpretation: 'Yüksek (Normal: <25 U/L)',
        isAbnormal: true,
      ),
    ],
    testResults: const {},
    correctDiagnosis: 'Akut Anterior Miyokard Enfarktüsü',
    alternativeDiagnoses: const [
      'STEMI',
      'Akut MI',
      'Miyokard enfarktüsü',
      'Kalp krizi',
      'Anterior MI',
    ],
    explanation: 'ST elevasyonu V1-V4 derivasyonlarında anterior STEMI\'yi gösterir. '
        'Troponin yüksekliği miyokard hasarını doğrular. '
        'Risk faktörleri: erkek, 58 yaş, HT, DM, sigara.',
    keyFindings: const [
      'Sol kola yayılan göğüs ağrısı',
      'ST elevasyonu V1-V4',
      'Troponin I yüksek (4.8 ng/mL)',
      'S3 galop ritmi',
    ],
  );

  // ═══════════════════════════════════════════════════════════
  // CASE 2: Toplum Kökenli Pnömoni (Pulmonoloji - Kolay)
  // ═══════════════════════════════════════════════════════════
  static final _case2Pneumonia = const MedicalCase(
    id: 'case_002',
    specialty: Specialty.pulmonology,
    difficulty: CaseDifficulty.easy,
    patientProfile: const PatientProfile(
      age: 72,
      gender: 'female',
      chiefComplaint: 'Öksürük, ateş, nefes darlığı, 3 gündür',
    ),
    vitals: const Vitals(
      bp: '130/80',
      hr: 98,
      temp: 38.9,
      rr: 26,
      spo2: 91,
    ),
    history: const {
      'medicalHistory': 'KOAH (15 yıl), Osteoporoz',
      'medications': 'Tiotropium inhaler, Kalsiyum-D vitamini',
      'allergies': 'Penisilin alerjisi',
    },
    physicalExam: const {
      'respiratory': 'Sağ alt lobda bronşiyal solunum sesleri, krepitan raller',
      'cardiovascular': 'Ritmik, ek ses yok',
      'abdomen': 'Doğal',
    },
    availableTests: const [
      const TestResult(
        testId: 'lab_cbc',
        category: TestCategory.lab,
        displayName: 'Tam Kan Sayımı',
        value: 'WBC: 18.500, Hb: 11.8, Plt: 320.000',
        interpretation: 'Lökositoz, hafif anemi',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'lab_crp',
        category: TestCategory.lab,
        displayName: 'CRP',
        value: '145 mg/L',
        interpretation: 'Belirgin yüksek (Normal: <5 mg/L)',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'imaging_chest_xray',
        category: TestCategory.imaging,
        displayName: 'PA Akciğer Grafisi',
        findings: 'Sağ alt lobda konsolidasyon, hava bronkogramları mevcut',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'lab_blood_gas',
        category: TestCategory.lab,
        displayName: 'Arter Kan Gazı',
        value: 'pH: 7.47, pO2: 58, pCO2: 32, HCO3: 23',
        interpretation: 'Hipoksemi, respiratuar alkaloz',
        isAbnormal: true,
      ),
    ],
    testResults: const {},
    correctDiagnosis: 'Toplum Kökenli Pnömoni',
    alternativeDiagnoses: const [
      'Pnömoni',
      'Zatürre',
      'Akciğer enfeksiyonu',
      'Bakteriyel pnömoni',
      'Community acquired pneumonia',
    ],
    explanation: 'Ateş, öksürük, nefes darlığı triadı ve sağ alt lobda '
        'konsolidasyon bulguları pnömoniyi destekler. '
        'KOAH zemini riski artırır. Penisilin alerjisi tedavi seçimini etkiler.',
    keyFindings: const [
      'Ateş 38.9°C + produktif öksürük',
      'SpO2 91% — hipoksemi',
      'Sağ alt lobda konsolidasyon (röntgen)',
      'CRP 145 mg/L — belirgin enfeksiyon',
    ],
  );

  // ═══════════════════════════════════════════════════════════
  // CASE 3: Akut Apandisit (Cerrahi - Kolay)
  // ═══════════════════════════════════════════════════════════
  static final _case3Appendicitis = const MedicalCase(
    id: 'case_003',
    specialty: Specialty.surgery,
    difficulty: CaseDifficulty.easy,
    patientProfile: const PatientProfile(
      age: 24,
      gender: 'male',
      chiefComplaint: 'Karın ağrısı, göbek çevresinde başlayıp sağ alt kadrana yerleşen, 12 saattir',
    ),
    vitals: const Vitals(
      bp: '125/78',
      hr: 92,
      temp: 38.2,
      rr: 18,
      spo2: 98,
    ),
    history: const {
      'medicalHistory': 'Bilinen hastalık yok',
      'medications': 'Kullandığı ilaç yok',
      'allergies': 'Bilinen alerji yok',
    },
    physicalExam: const {
      'abdomen': 'McBurney noktasında hassasiyet, defans (+), Rovsing bulgusu (+), Psoas testi (+)',
      'cardiovascular': 'Doğal',
      'respiratory': 'Doğal',
    },
    availableTests: const [
      const TestResult(
        testId: 'lab_cbc',
        category: TestCategory.lab,
        displayName: 'Tam Kan Sayımı',
        value: 'WBC: 14.200, Hb: 15.1, Plt: 265.000',
        interpretation: 'Lökositoz, nötrofili',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'lab_crp',
        category: TestCategory.lab,
        displayName: 'CRP',
        value: '68 mg/L',
        interpretation: 'Yüksek (Normal: <5 mg/L)',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'imaging_usg',
        category: TestCategory.imaging,
        displayName: 'Batın USG',
        findings: 'Apendiks çapı 12mm, komprese edilemiyor, periappendiküler yağlı doku inflamasyonu',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'lab_urinalysis',
        category: TestCategory.lab,
        displayName: 'Tam İdrar Tahlili',
        value: 'Normal, lökosit (-), eritrosit (-), nitrit (-)',
        interpretation: 'Normal — üriner patoloji dışlandı',
        isAbnormal: false,
      ),
    ],
    testResults: const {},
    correctDiagnosis: 'Akut Apandisit',
    alternativeDiagnoses: const [
      'Apandisit',
      'Appendisit',
      'Akut appendisit',
    ],
    explanation: 'Klasik göç eden ağrı paterni (periumbilikal → sağ alt kadran), '
        'McBurney hassasiyeti, defans ve pozitif Rovsing/Psoas testleri '
        'akut apandisiti kuvvetle destekler. USG bulguları doğrular.',
    keyFindings: const [
      'Göç eden karın ağrısı (göbek → sağ alt kadran)',
      'McBurney hassasiyeti + defans',
      'Rovsing ve Psoas testleri pozitif',
      'USG: Apendiks 12mm, komprese edilemiyor',
    ],
  );

  // ═══════════════════════════════════════════════════════════
  // CASE 4: Bakteriyel Menenjit (Nöroloji - Zor)
  // ═══════════════════════════════════════════════════════════
  static final _case4Meningitis = const MedicalCase(
    id: 'case_004',
    specialty: Specialty.neurology,
    difficulty: CaseDifficulty.hard,
    patientProfile: const PatientProfile(
      age: 19,
      gender: 'female',
      chiefComplaint: 'Şiddetli baş ağrısı, ateş, ense sertliği, 1 gündür',
    ),
    vitals: const Vitals(
      bp: '105/65',
      hr: 118,
      temp: 39.5,
      rr: 24,
      spo2: 96,
    ),
    history: const {
      'medicalHistory': 'Bilinen hastalık yok. Üniversite yurdu öğrencisi.',
      'medications': 'Oral kontraseptif',
      'allergies': 'Bilinen alerji yok',
    },
    physicalExam: const {
      'neurological': 'Ense sertliği (+), Kernig (+), Brudzinski (+), fotofobi, GKS: 14 (E4V4M6)',
      'skin': 'Gövde ve ekstremitelerde peteşiyal döküntü',
      'cardiovascular': 'Taşikardik, dolgun değil',
    },
    availableTests: const [
      const TestResult(
        testId: 'lab_cbc',
        category: TestCategory.lab,
        displayName: 'Tam Kan Sayımı',
        value: 'WBC: 22.000, Hb: 13.5, Plt: 98.000',
        interpretation: 'Belirgin lökositoz, trombositopeni',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'lab_crp',
        category: TestCategory.lab,
        displayName: 'CRP',
        value: '210 mg/L',
        interpretation: 'Çok yüksek (Normal: <5 mg/L)',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'special_lumbar',
        category: TestCategory.special,
        displayName: 'Lomber Ponksiyon (BOS)',
        value: 'Basınç: 32 cmH2O, Protein: 280 mg/dL, Glukoz: 18 mg/dL, Hücre: 2500/mm³ (95% nötrofil)',
        interpretation: 'Bakteriyel menenjit ile uyumlu — yüksek protein, düşük glukoz, nötrofil hakimiyeti',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'imaging_ct_head',
        category: TestCategory.imaging,
        displayName: 'Beyin BT',
        findings: 'Yer kaplayan lezyon yok, beyin ödemi bulgusu yok, LP için kontrendikasyon yok',
        isAbnormal: false,
      ),
      const TestResult(
        testId: 'lab_lactate',
        category: TestCategory.lab,
        displayName: 'Laktat',
        value: '4.2 mmol/L',
        interpretation: 'Yüksek (Normal: <2 mmol/L) — sepsis bulgusu',
        isAbnormal: true,
      ),
    ],
    testResults: const {},
    correctDiagnosis: 'Bakteriyel Menenjit',
    alternativeDiagnoses: const [
      'Menenjit',
      'Akut bakteriyel menenjit',
      'Meningokok menenjiti',
      'Pürülan menenjit',
    ],
    explanation: 'Klasik triad: ateş, ense sertliği, bilinç değişikliği. '
        'Peteşiyal döküntü meningokoku düşündürür. '
        'BOS bulguları (düşük glukoz, yüksek protein, nötrofil) '
        'bakteriyel menenjiti doğrular. Acil antibiyotik gerekli.',
    keyFindings: const [
      'Ateş + ense sertliği + bilinç değişikliği (triad)',
      'Peteşiyal döküntü — meningokok?',
      'BOS: Glukoz düşük (18), protein yüksek (280), nötrofil hakim',
      'Trombositopeni — DIC başlangıcı olabilir',
    ],
  );

  // ═══════════════════════════════════════════════════════════
  // CASE 5: Pulmoner Emboli (Acil - Zor)
  // ═══════════════════════════════════════════════════════════
  static final _case5Pulmonaryembolism = const MedicalCase(
    id: 'case_005',
    specialty: Specialty.emergency,
    difficulty: CaseDifficulty.hard,
    patientProfile: const PatientProfile(
      age: 35,
      gender: 'female',
      chiefComplaint: 'Ani başlayan nefes darlığı, plöritik göğüs ağrısı, 4 saattir',
    ),
    vitals: const Vitals(
      bp: '100/60',
      hr: 125,
      temp: 37.4,
      rr: 28,
      spo2: 88,
    ),
    history: const {
      'medicalHistory': 'Oral kontraseptif kullanımı (3 yıl). 2 hafta önce İstanbul-New York uçuşu.',
      'medications': 'Oral kontraseptif',
      'allergies': 'Bilinen alerji yok',
    },
    physicalExam: const {
      'respiratory': 'Takipneik, bilateral solunum sesleri azalmış sağda daha belirgin',
      'cardiovascular': 'Taşikardik, S2 sert, sağ ventrikül heave',
      'extremities': 'Sağ baldırda şişlik ve hassasiyet (DVT?)',
    },
    availableTests: const [
      const TestResult(
        testId: 'lab_d_dimer',
        category: TestCategory.lab,
        displayName: 'D-dimer',
        value: '4.8 mg/L FEU',
        interpretation: 'Çok yüksek (Normal: <0.5 mg/L FEU)',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'lab_blood_gas',
        category: TestCategory.lab,
        displayName: 'Arter Kan Gazı',
        value: 'pH: 7.48, pO2: 55, pCO2: 28, HCO3: 21',
        interpretation: 'Hipoksemi, hipokapni, respiratuar alkaloz',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'imaging_ct_angio',
        category: TestCategory.imaging,
        displayName: 'BT Pulmoner Anjiyografi',
        findings: 'Sağ ana pulmoner arterde ve sağ alt lob segmental arterlerde dolma defekti — masif PE',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'ecg_12lead',
        category: TestCategory.ecg,
        displayName: '12 Derivasyon EKG',
        findings: 'Sinüs taşikardisi, S1Q3T3 paterni, sağ aks deviasyonu',
        isAbnormal: true,
      ),
      const TestResult(
        testId: 'lab_bnp',
        category: TestCategory.lab,
        displayName: 'BNP',
        value: '450 pg/mL',
        interpretation: 'Yüksek (Normal: <100 pg/mL) — sağ ventrikül yüklenmesi',
        isAbnormal: true,
      ),
    ],
    testResults: const {},
    correctDiagnosis: 'Masif Pulmoner Emboli',
    alternativeDiagnoses: const [
      'Pulmoner emboli',
      'PE',
      'Pulmoner tromboemboli',
      'Akciğer embolisi',
    ],
    explanation: 'Ani nefes darlığı + plöritik ağrı + risk faktörleri (OKS, uzun uçuş). '
        'Wells skoru yüksek. BT anjiyoda sağ ana pulmoner arterde dolma defekti '
        'masif PE\'yi doğrular. S1Q3T3 klasik ama nadir EKG bulgusu.',
    keyFindings: const [
      'Ani nefes darlığı + plöritik ağrı',
      'Risk: OKS + uzun uçuş (immobilizasyon)',
      'SpO2 88% + taşikardi 125',
      'BT anjio: Sağ ana pulmoner arterde dolma defekti',
    ],
  );
}
