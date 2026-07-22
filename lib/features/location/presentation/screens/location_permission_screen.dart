import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../application/location_provider.dart';

class LocationPermissionScreen extends ConsumerWidget {
  const LocationPermissionScreen({super.key, this.onAllowAccess, this.onNotNow});

  final VoidCallback? onAllowAccess;
  final VoidCallback? onNotNow;

  Future<void> _handleAllowAccess(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(userLocationProvider.notifier).requestPermission();
    if (context.mounted) {
      if (result == LocationRequestResult.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location access granted successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
        onAllowAccess?.call();
      } else if (result == LocationRequestResult.settingsOpened) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enable location services/permissions in Settings and try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.warning,
          ),
        );
      } else {
        // Falling back to user mock coordinates
        ref.read(userLocationProvider.notifier).setMockLocation();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permission denied. Using fallback location.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.warning,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.black,
              onPressed: () {},
            ),
          ),
        );
        onAllowAccess?.call();
      }
    }
  }

  void _handleNotNow(BuildContext context, WidgetRef ref) {
    ref.read(userLocationProvider.notifier).setMockLocation();
    onNotNow?.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                decoration: BoxDecoration(
                  color: AppColors.iconCircleBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child:  Icon(Icons.location_on_outlined, size: 52, color: AppColors.primary),
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
            const _LocationOptionPill(label: 'Precise Location · Best for nearby search'),
            const SizedBox(height: AppSpacing.md),
            const _LocationOptionPill(label: 'Approximate Location · Limited results'),
            const Spacer(flex: 3),
            PrimaryButton(
              label: 'Allow Access',
              onPressed: () => _handleAllowAccess(context, ref),
            ),
            const SizedBox(height: AppSpacing.md),
            Material(
              color: AppColors.surfaceCardSolid,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () => _handleNotNow(context, ref),
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