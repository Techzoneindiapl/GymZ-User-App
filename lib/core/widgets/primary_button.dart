import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// The orange primary CTA button used across the user app.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isEnabled = true,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isEnabled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final disabled = !isEnabled || isLoading || onPressed == null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled ? 0.55 : 1.0,
      child: Material(
        color: color ?? AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: disabled ? null : onPressed,
          child: Container(
            width: double.infinity,
            height: 56,
            alignment: Alignment.center,
            child: isLoading
                ?  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (leadingIcon != null) ...[
                        Icon(leadingIcon, size: 18, color: AppColors.textOnPrimary),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(label, style: AppTextStyles.buttonLabel),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(trailingIcon, size: 18, color: AppColors.textOnPrimary),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}