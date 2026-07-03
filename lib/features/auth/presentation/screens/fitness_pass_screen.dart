import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';

class FitnessPassData {
  const FitnessPassData({
    required this.fullName,
    required this.gender,
    required this.passId,
    required this.joinedAt,
    this.selfieFilePath,
  });

  final String fullName;
  final String gender;
  final String passId;
  final DateTime joinedAt;
  final String? selfieFilePath;

  String get joinedLabel => 'Joined ${DateFormat('MMM yyyy').format(joinedAt)}';
}

class FitnessPassScreen extends StatelessWidget {
  const FitnessPassScreen({super.key, required this.pass, this.onContinue});

  final FitnessPassData pass;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'YOUR DIGITAL PASS',
            style: AppTextStyles.label.copyWith(color: AppColors.primary, letterSpacing: 2),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  _PassCard(pass: pass),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Show this card at any GYMZ partner facility to check in instantly.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: PrimaryButton(label: 'Continue', onPressed: onContinue),
          ),
        ],
      ),
    );
  }
}

class _PassCard extends StatelessWidget {
  const _PassCard({required this.pass});
  final FitnessPassData pass;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2F9E), Color(0xFF1A1F6E)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.surfaceCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                  children:  [
                    TextSpan(text: 'GYM', style: TextStyle(color: AppColors.textPrimary)),
                    TextSpan(text: 'z', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('MEMBER', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.primary, width: 2),
                  color: AppColors.surfaceCard,
                ),
                clipBehavior: Clip.antiAlias,
                child: pass.selfieFilePath != null
                    ? Image.file(File(pass.selfieFilePath!), fit: BoxFit.cover)
                    : Icon(Icons.person, size: 40, color: AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pass.fullName, style: AppTextStyles.sectionTitle),
                  Text('${pass.gender} · ${pass.joinedLabel}', style: AppTextStyles.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(pass.passId, style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                // QR placeholder.
                Container(
                  width: 80,
                  height: 80,
                  color: Colors.white,
                  child: const Icon(Icons.qr_code_2, size: 72, color: Colors.black),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barcode placeholder drawn with thin black lines.
                      SizedBox(height: 50, child: CustomPaint(painter: _BarcodePainter())),
                      const SizedBox(height: AppSpacing.xs),
                      Text(pass.passId, style: AppTextStyles.caption.copyWith(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight barcode visual using random-width black bars on a white
/// background — a placeholder for a real barcode generated from passId.
class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    const barWidths = [3.0, 1.5, 2.0, 1.0, 3.5, 1.0, 2.5, 1.5, 1.0, 3.0,
      2.0, 1.5, 1.0, 2.5, 1.5, 3.0, 1.0, 2.0, 1.5, 3.5];
    var x = 0.0;
    bool drawBar = true;
    for (final w in barWidths) {
      if (drawBar) canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      x += w + 2;
      drawBar = !drawBar;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}