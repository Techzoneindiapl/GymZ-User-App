import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({
    super.key,
    this.onMobileNumber,
    this.onGoogle,
    this.onApple,
    this.onGuest,
    this.onContinue,
    this.onTerms,
    this.onPrivacyPolicy,
  });

  final VoidCallback? onMobileNumber;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final VoidCallback? onGuest;
  final VoidCallback? onContinue;
  final VoidCallback? onTerms;
  final VoidCallback? onPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                SizedBox(height: h * 0.1),
                _GymzLogo(),
                SizedBox(height: h * 0.06),
                Text(
                  'Sign in to start training',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                _AuthOption(
                  icon: Icons.phone_outlined,
                  iconColor: AppColors.primary,
                  label: 'Continue with Mobile Number',
                  onTap: onMobileNumber,
                ),
                const SizedBox(height: AppSpacing.md),
                _AuthOption(
                  label: 'Continue with Google',
                  onTap: onGoogle,
                  customLeading: _GoogleIcon(),
                ),
                const SizedBox(height: AppSpacing.md),
                _AuthOption(
                  icon: Icons.apple,
                  label: 'Continue with Apple',
                  onTap: onApple,
                ),
                const SizedBox(height: AppSpacing.md),
                _AuthOption(
                  icon: Icons.person_outline,
                  label: 'Continue as Guest',
                  onTap: onGuest,
                ),
                SizedBox(height: h * 0.08),
                PrimaryButton(label: 'Continue', onPressed: onContinue),
                const SizedBox(height: AppSpacing.lg),
                _TermsRow(onTerms: onTerms, onPrivacyPolicy: onPrivacyPolicy),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GymzLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyles.displayLarge.copyWith(fontSize: 42, height: 1),
            children: const [
              TextSpan(text: 'GYM', style: TextStyle(color: AppColors.textPrimary)),
              TextSpan(text: 'Z', style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'FITNESS WITHOUT BOUNDARIES',
          style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
        ),
      ],
    );
  }
}

class _AuthOption extends StatelessWidget {
  const _AuthOption({
    required this.label,
    required this.onTap,
    this.icon,
    this.iconColor = AppColors.textPrimary,
    this.customLeading,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color iconColor;
  final Widget? customLeading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.surfaceCardBorder),
          ),
          child: Row(
            children: [
              if (customLeading != null)
                customLeading!
              else if (icon != null)
                Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(label, style: AppTextStyles.body),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Text(
        'G',
        style: AppTextStyles.bodySmall.copyWith(
          color: Colors.red,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({this.onTerms, this.onPrivacyPolicy});
  final VoidCallback? onTerms;
  final VoidCallback? onPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTextStyles.caption,
        children: [
          const TextSpan(text: 'By continuing you agree to our '),
          WidgetSpan(
            child: GestureDetector(
              onTap: onTerms,
              child: Text('Terms',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
            ),
          ),
          const TextSpan(text: ' & '),
          WidgetSpan(
            child: GestureDetector(
              onTap: onPrivacyPolicy,
              child: Text('Privacy Policy',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}