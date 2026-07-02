import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key, this.onAllowAccess, this.onNotNow});

  final VoidCallback? onAllowAccess;
  final VoidCallback? onNotNow;

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Pulsing orange ring around the location pin.
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.iconCircleBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.location_on_outlined, size: 52, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Find Nearby Fitness Centers',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Allow location access to discover the closest gyms, studios and sports facilities around you.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _LocationOptionPill(label: 'Precise Location · Best for nearby search'),
            const SizedBox(height: AppSpacing.md),
            _LocationOptionPill(label: 'Approximate Location · Limited results'),
            const Spacer(flex: 3),
            PrimaryButton(label: 'Allow Access', onPressed: onAllowAccess),
            const SizedBox(height: AppSpacing.md),
            Material(
              color: AppColors.surfaceCardSolid,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: onNotNow,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text('Not Now', style: AppTextStyles.buttonLabel),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _LocationOptionPill extends StatelessWidget {
  const _LocationOptionPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.surfaceCardBorder),
        color: AppColors.surfaceCard,
      ),
      child: Text(label, style: AppTextStyles.body, textAlign: TextAlign.center),
    );
  }
}