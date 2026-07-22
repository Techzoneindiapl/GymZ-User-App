import 'package:flutter/material.dart';
import 'package:gymz_user/core/theme/app_colors.dart';
import 'package:gymz_user/core/theme/app_spacing.dart';
import 'package:gymz_user/core/theme/app_text_styles.dart';


class PremiumTierCard extends StatelessWidget {
  const PremiumTierCard({
    super.key,
    required this.tier,
    this.onTap,
    this.isSelected = false,
  });
  final String tier;
  final VoidCallback? onTap;
  final bool isSelected;

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
      color: isSelected ? _color.withOpacity(0.12) : AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isSelected ? _color : AppColors.surfaceCardBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tier, style: AppTextStyles.sectionTitle.copyWith(color: _color)),
                    if (isSelected)
                      Icon(Icons.check_circle, color: _color, size: 18),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isSelected ? 'Filtering gyms' : 'View gyms',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? _color.withOpacity(0.8) : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}