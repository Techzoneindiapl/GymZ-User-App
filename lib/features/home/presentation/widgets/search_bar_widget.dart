import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/translations.dart';

class SearchBarWidget extends ConsumerWidget {
  const SearchBarWidget({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.hintText = 'Search Gyms, Yoga, Sports...',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final String hintText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final displayHint = hintText == 'Search Gyms, Yoga, Sports...' 
        ? (tr['search_gyms_hint'] ?? hintText) 
        : hintText;

    return Row(
      children: [
        Expanded(
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
                Icon(Icons.search, color: AppColors.textMuted, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: displayHint,
                      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
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
            child:  Padding(
              padding: EdgeInsets.all(14),
              child: Icon(Icons.tune, color: AppColors.textOnPrimary, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}