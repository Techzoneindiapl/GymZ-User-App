import 'package:flutter/material.dart';
import 'package:gymz_user/core/theme/app_colors.dart';
import 'package:gymz_user/core/theme/app_spacing.dart';
import 'package:gymz_user/core/theme/app_text_styles.dart';


class PremiumTierCard extends StatelessWidget {
  const PremiumTierCard({super.key, required this.tier, this.onTap});
  final String tier;
  final VoidCallback? onTap;

  Color get _color {
    switch (tier) {
      case 'Platinum': return AppColors.tierPlatinum;
      case 'Diamond': return AppColors.tierDiamond;
      case 'Gold': return AppColors.tierGold;
      default: return AppColors.tierSilver;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(tier, style: AppTextStyles.sectionTitle.copyWith(color: _color)),
              const SizedBox(height: AppSpacing.xs),
              Text('View gyms', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}