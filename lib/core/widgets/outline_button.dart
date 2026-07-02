import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Dark outline button (e.g. "Next", "Not Now", "Share") used
/// alongside the primary orange button on several screens.
class OutlineButton extends StatelessWidget {
  const OutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCardSolid,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.surfaceCardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: AppTextStyles.buttonLabel),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(trailingIcon, size: 18, color: AppColors.textPrimary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}