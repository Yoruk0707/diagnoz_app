/// ═══════════════════════════════════════════════════════════════
/// DiagnozApp - case.dart (Entity)
/// ═══════════════════════════════════════════════════════════════
/// 
/// PURPOSE: Medical case entity for domain layer
/// 
/// SCHEMA (database_schema.md § cases):
/// - Patient profile (age, gender, chief complaint)
/// - Vital signs (BP, HR, Temp, RR, SpO2)
/// - Available tests (lab, imaging, ECG, special)
/// - Test results
/// - Correct diagnosis
/// - Difficulty (easy, medium, hard)
/// - Specialty (cardiology, neurology, etc.)
/// 
/// FIELD VISIBILITY BY MODE (database_schema.md):
/// | Field           | Rush Mode | Zen Mode |
/// |-----------------|-----------|----------|
/// | patientProfile  | ✅ Always  | ✅ Always |
/// | vitals          | ✅ Always  | ✅ Always |
/// | history         | ❌ Hidden  | ✅ Shown  |
/// | physicalExam    | ❌ Hidden  | ✅ Shown  |
/// | explanation     | ❌ Hidden  | ✅ Shown  |
/// 
/// TEST CATEGORIES (masterplan.md § Test Request System):
/// - Laboratory: CBC, Troponin, D-dimer, etc.
/// - Imaging: X-ray, CT, Ultrasound, MRI
/// - ECG: 12-lead ECG, Rhythm strip
/// - Special: Lumbar puncture, Biopsy, etc.
/// 
/// EXAMPLE:
/// ```dart
/// enum Specialty {
///   emergency,
///   cardiology,
///   neurology,
///   pediatrics,
///   surgery,
///   infectious,
///   internal,
///   pulmonology,
///   gastroenterology,
///   nephrology,
/// }
/// 
/// enum Difficulty { easy, medium, hard }
/// 
/// class Case extends Equatable {
///   final String id;
///   final Specialty specialty;
///   final Difficulty difficulty;
///   final PatientProfile patientProfile;
///   final VitalSigns vitals;
///   final MedicalHistory? history;
///   final PhysicalExam? physicalExam;
///   final AvailableTests availableTests;
///   final String correctDiagnosis;
///   final List<String> alternativeDiagnoses;
///   final String? explanation;
///   final List<String>? keyFindings;
///   
///   const Case({
///     required this.id,
///     required this.specialty,
///     required this.difficulty,
///     required this.patientProfile,
///     required this.vitals,
///     this.history,
///     this.physicalExam,
///     required this.availableTests,
///     required this.correctDiagnosis,
///     this.alternativeDiagnoses = const [],
///     this.explanation,
///     this.keyFindings,
///   });
///   
///   @override
///   List<Object?> get props => [id, correctDiagnosis];
/// }
/// 
/// class PatientProfile extends Equatable {
///   final int age;
///   final String gender; // male, female, other
///   final String chiefComplaint;
///   
///   const PatientProfile({
///     required this.age,
///     required this.gender,
///     required this.chiefComplaint,
///   });
///   
///   @override
///   List<Object?> get props => [age, gender, chiefComplaint];
/// }
/// 
/// class VitalSigns extends Equatable {
///   final String bp;      // "140/90"
///   final int hr;         // Heart rate
///   final double temp;    // Temperature
///   final int rr;         // Respiratory rate
///   final int spo2;       // Oxygen saturation
///   
///   const VitalSigns({
///     required this.bp,
///     required this.hr,
///     required this.temp,
///     required this.rr,
///     required this.spo2,
///   });
///   
///   @override
///   List<Object?> get props => [bp, hr, temp, rr, spo2];
/// }
/// 
/// class AvailableTests extends Equatable {
///   final List<String> lab;
///   final List<String> imaging;
///   final List<String> ecg;
///   final List<String> special;
///   
///   const AvailableTests({
///     this.lab = const [],
///     this.imaging = const [],
///     this.ecg = const [],
///     this.special = const [],
///   });
///   
///   @override
///   List<Object?> get props => [lab, imaging, ecg, special];
/// }
/// ```

// TODO: Implement Case entity
