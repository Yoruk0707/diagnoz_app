// lib/features/game/presentation/widgets/case_presentation_widget.dart
//
// NEDEN: Vaka bilgilerini gösterir — hasta profili, vitaller.
// Game screen'in ana body'si.
//
// Referans: masterplan.md § Case Presentation
//           ui_ux_design_clean.md § Game Screen

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/medical_case.dart';

/// Vaka sunumu — hasta bilgileri ve vitaller.
///
/// NEDEN: Ayrı widget — game screen temiz kalır.
class CasePresentationWidget extends StatelessWidget {
  final MedicalCase medicalCase;

  const CasePresentationWidget({
    super.key,
    required this.medicalCase,
  });

  @override
  Widget build(BuildContext context) {
    final patient = medicalCase.patientProfile;
    final vitals = medicalCase.vitals;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NEDEN: Hasta kartı — yaş, cinsiyet, şikayet.
          _PatientCard(patient: patient),
          const SizedBox(height: 16),
          // NEDEN: Vital bulgular — BP, HR, Temp, RR, SpO2.
          _VitalsCard(vitals: vitals),
          const SizedBox(height: 16),
          // NEDEN: Zorluk ve uzmanlık badge'leri.
          _CaseInfoRow(medicalCase: medicalCase),
        ],
      ),
    );
  }
}

/// Hasta bilgi kartı.
class _PatientCard extends StatelessWidget {
  final PatientProfile patient;

  const _PatientCard({required this.patient});

  String _genderText(String gender) {
    switch (gender) {
      case 'male':
        return 'Erkek';
      case 'female':
        return 'Kadın';
      default:
        return 'Diğer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NEDEN: Hasta başlık satırı.
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '${patient.age} yaşında ${_genderText(patient.gender)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // NEDEN: Başvuru şikayeti — en önemli bilgi.
          const Text(
            'Başvuru Şikayeti',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            patient.chiefComplaint,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vital bulgular grid'i.
class _VitalsCard extends StatelessWidget {
  final Vitals vitals;

  const _VitalsCard({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Text(
                'Vital Bulgular',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // NEDEN: 3 sütun grid — kompakt gösterim.
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _VitalChip(label: 'TA', value: vitals.bp, unit: 'mmHg'),
              _VitalChip(label: 'Nabız', value: '${vitals.hr}', unit: '/dk'),
              _VitalChip(label: 'Ateş', value: '${vitals.temp}', unit: '°C'),
              _VitalChip(label: 'SS', value: '${vitals.rr}', unit: '/dk'),
              _VitalChip(label: 'SpO2', value: '${vitals.spo2}', unit: '%'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tek vital değer chip'i.
class _VitalChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _VitalChip({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Zorluk + uzmanlık badge'leri.
class _CaseInfoRow extends StatelessWidget {
  final MedicalCase medicalCase;

  const _CaseInfoRow({required this.medicalCase});

  Color _difficultyColor(CaseDifficulty difficulty) {
    switch (difficulty) {
      case CaseDifficulty.easy:
        return AppColors.success;
      case CaseDifficulty.medium:
        return AppColors.warning;
      case CaseDifficulty.hard:
        return AppColors.error;
    }
  }

  String _difficultyText(CaseDifficulty difficulty) {
    switch (difficulty) {
      case CaseDifficulty.easy:
        return 'Kolay';
      case CaseDifficulty.medium:
        return 'Orta';
      case CaseDifficulty.hard:
        return 'Zor';
    }
  }

  String _specialtyText(Specialty specialty) {
    switch (specialty) {
      case Specialty.cardiology:
        return 'Kardiyoloji';
      case Specialty.neurology:
        return 'Nöroloji';
      case Specialty.pulmonology:
        return 'Göğüs Hastalıkları';
      case Specialty.surgery:
        return 'Genel Cerrahi';
      case Specialty.emergency:
        return 'Acil Tıp';
      case Specialty.internal:
        return 'Dahiliye';
      case Specialty.pediatrics:
        return 'Pediatri';
      case Specialty.infectious:
        return 'Enfeksiyon';
      case Specialty.gastroenterology:
        return 'Gastroenteroloji';
      case Specialty.nephrology:
        return 'Nefroloji';
    }
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(medicalCase.difficulty);

    return Row(
      children: [
        // NEDEN: Zorluk badge'i — renkli.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: diffColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: diffColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            _difficultyText(medicalCase.difficulty),
            style: TextStyle(
              color: diffColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // NEDEN: Uzmanlık badge'i — primary renk.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _specialtyText(medicalCase.specialty),
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
