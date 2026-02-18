// lib/features/game/presentation/widgets/case_card_widget.dart
//
// NEDEN: Vaka bilgilerini gösteren kart — hasta profili + vital bulgular.
// Rush mode'da history/physicalExam gizli (masterplan.md § Field Visibility).
//
// Referans: ui_ux_design_clean.md § Case Presentation
//           medical_case.dart entity

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/medical_case.dart';

/// Vaka kartı — hasta bilgileri ve vital bulgular.
///
/// NEDEN: Oyuncunun ilk gördüğü bilgiler.
/// Tasarım: koyu kart, beyaz text, tıbbi görünüm.
class CaseCardWidget extends StatelessWidget {
  final MedicalCase medicalCase;
  final int caseNumber;
  final int totalCases;

  const CaseCardWidget({
    super.key,
    required this.medicalCase,
    required this.caseNumber,
    required this.totalCases,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.backgroundSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NEDEN: Vaka numarası + zorluk badge.
            _buildHeader(),
            const SizedBox(height: 12),
            const Divider(color: AppColors.backgroundTertiary),
            const SizedBox(height: 12),

            // NEDEN: Hasta profili — yaş, cinsiyet, şikayet.
            _buildPatientProfile(),
            const SizedBox(height: 16),

            // NEDEN: Vital bulgular — BP, HR, Temp, RR, SpO2.
            _buildVitals(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Vaka $caseNumber / $totalCases',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        // NEDEN: Zorluk badge — renk kodlu (yeşil/sarı/kırmızı).
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getDifficultyColor().withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getDifficultyText(),
            style: TextStyle(
              color: _getDifficultyColor(),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientProfile() {
    final profile = medicalCase.patientProfile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NEDEN: Hasta bilgisi — "58 yaş, Erkek"
        Row(
          children: [
            const Icon(Icons.person, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              '${profile.age} yaş, ${_getGenderText(profile.gender)}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // NEDEN: Başvuru şikayeti — en kritik bilgi, vurgulu göster.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                profile.chiefComplaint,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVitals() {
    final vitals = medicalCase.vitals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vital Bulgular',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // NEDEN: Grid layout — 3 sütun, kompakt gösterim.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _vitalChip('TA', vitals.bp, _isAbnormalBP(vitals.bp)),
            _vitalChip('NK', '${vitals.hr}/dk', vitals.hr > 100 || vitals.hr < 60),
            _vitalChip('Ateş', '${vitals.temp}°C', vitals.temp > 37.5),
            _vitalChip('SS', '${vitals.rr}/dk', vitals.rr > 20 || vitals.rr < 12),
            _vitalChip('SpO₂', '%${vitals.spo2}', vitals.spo2 < 95),
          ],
        ),
      ],
    );
  }

  /// NEDEN: Anormal vital → kırmızı vurgu, normal → gri.
  Widget _vitalChip(String label, String value, bool isAbnormal) {
    final color = isAbnormal ? AppColors.error : AppColors.textSecondary;
    final bgColor = isAbnormal
        ? AppColors.errorContainer
        : AppColors.backgroundTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool _isAbnormalBP(String bp) {
    // NEDEN: "160/95" → sistol>140 veya diyastol>90 → anormal
    final parts = bp.split('/');
    if (parts.length != 2) return false;
    final systol = int.tryParse(parts[0]) ?? 120;
    final diastol = int.tryParse(parts[1]) ?? 80;
    return systol > 140 || systol < 90 || diastol > 90 || diastol < 60;
  }

  Color _getDifficultyColor() {
    switch (medicalCase.difficulty) {
      case CaseDifficulty.easy:
        return AppColors.success;
      case CaseDifficulty.medium:
        return AppColors.warning;
      case CaseDifficulty.hard:
        return AppColors.error;
    }
  }

  String _getDifficultyText() {
    switch (medicalCase.difficulty) {
      case CaseDifficulty.easy:
        return 'Kolay';
      case CaseDifficulty.medium:
        return 'Orta';
      case CaseDifficulty.hard:
        return 'Zor';
    }
  }

  String _getGenderText(String gender) {
    switch (gender) {
      case 'male':
        return 'Erkek';
      case 'female':
        return 'Kadın';
      default:
        return 'Diğer';
    }
  }
}
