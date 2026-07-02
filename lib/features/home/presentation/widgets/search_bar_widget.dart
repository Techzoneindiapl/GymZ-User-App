import 'package:flutter/material.dart';
import 'package:gymz_user/core/theme/app_colors.dart';
import 'package:gymz_user/core/theme/app_spacing.dart';
import 'package:gymz_user/core/theme/app_text_styles.dart';



class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key, this.onTap, this.onFilterTap});
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.surfaceCardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Search Gyms, Yoga, Sports', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onFilterTap,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Icon(Icons.tune, color: AppColors.textOnPrimary, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}