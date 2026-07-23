import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/router/route_names.dart';
import '../../application/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    this.onGoogle,
    this.onApple,
    this.onGuest,
    this.onTerms,
    this.onPrivacyPolicy,
  });

  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final VoidCallback? onGuest;
  final VoidCallback? onTerms;
  final VoidCallback? onPrivacyPolicy;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late final TextEditingController _phoneController;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _phoneController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      _isValid = _phoneController.text.length == 10;
    });
  }

  Future<void> _handleSendOtp() async {
    if (!_isValid) return;
    
    final success = await ref.read(authProvider.notifier).sendOtp(_phoneController.text);
    if (success && mounted) {
      context.pushNamed(RouteNames.verifyOtp);
    }
  }

  Widget _animatedOption(Widget child, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating;

    return GradientScaffold(
      body: Stack(
        children: [
          // Background Glow Blobs matching onboarding design system
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.isDark ? const Color(0x1F00BCD4) : const Color(0x0C00BCD4),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.isDark ? const Color(0x11C6FF00) : const Color(0x06C6FF00),
              ),
            ),
          ),
          // Backdrop blur over glowing elements
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: const SizedBox.shrink(),
            ),
          ),

          // Main form layout
          LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    SizedBox(height: h * 0.12),
                    _GymzLogo(),
                    SizedBox(height: h * 0.04),
                    Text(
                      tr['sign_in_to_start'] ?? 'Sign in to start training',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Phone Number text field embedded directly
                    _animatedOption(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs),
                            child: Text(
                              tr['phone_number'] ?? 'Phone Number',
                              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: AppTextStyles.body,
                            cursorColor: AppColors.primary,
                            maxLength: 10,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: tr['enter_mobile_hint'] ?? '7400105833',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                              prefixText: '+91 ',
                              prefixStyle: AppTextStyles.body.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceCard.withOpacity(0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                borderSide: BorderSide(
                                  color: AppColors.surfaceCardBorder.withOpacity(0.6),
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                borderSide: BorderSide(
                                  color: AppColors.surfaceCardBorder.withOpacity(0.6),
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.lg,
                              ),
                            ),
                          ),
                        ],
                      ),
                      0,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Staggered login options below the phone field
                    _animatedOption(
                      _AuthOption(
                        label: tr['continue_google'] ?? 'Continue with Google',
                        onTap: widget.onGoogle,
                        customLeading: _GoogleIcon(),
                        iconColor: AppColors.textPrimary,
                      ),
                      1,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _animatedOption(
                      _AuthOption(
                        icon: Icons.apple,
                        label: tr['continue_apple'] ?? 'Continue with Apple',
                        onTap: widget.onApple,
                        iconColor: AppColors.textPrimary,
                      ),
                      2,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _animatedOption(
                      _AuthOption(
                        icon: Icons.person_outline,
                        label: tr['guest_login'] ?? 'Continue as Guest',
                        onTap: widget.onGuest,
                        iconColor: AppColors.textPrimary,
                      ),
                      3,
                    ),
                    SizedBox(height: h * 0.05),
                    
                    // Display error if any
                    if (authState.errorMessage != null) ...[
                      _animatedOption(
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            authState.errorMessage!,
                            style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        4,
                      ),
                    ],
                    
                    _animatedOption(
                      PrimaryButton(
                        label: tr['continue'] ?? 'Continue', 
                        isEnabled: _isValid && !isLoading,
                        isLoading: isLoading,
                        onPressed: _handleSendOtp,
                      ),
                      4,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _animatedOption(
                      _TermsRow(onTerms: widget.onTerms, onPrivacyPolicy: widget.onPrivacyPolicy),
                      5,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GymzLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.85, end: 1.0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Column(
        children: [
          Image.asset(
            'assets/logo/gymz-logo.png',
            height: 110,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback text if the image asset is not found in local builds
              return RichText(
                text: TextSpan(
                  style: AppTextStyles.displayLarge.copyWith(fontSize: 42, height: 1),
                  children: [
                    TextSpan(text: 'GYM', style: TextStyle(color: AppColors.textPrimary)),
                    TextSpan(text: 'Z', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'FITNESS WITHOUT BOUNDARIES',
            style: AppTextStyles.caption.copyWith(
              letterSpacing: 2.0,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthOption extends StatelessWidget {
  const _AuthOption({
    required this.label,
    required this.onTap,
    this.icon,
    required this.iconColor,
    this.customLeading,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color iconColor;
  final Widget? customLeading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: onTap,
              child: Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.surfaceCardBorder.withOpacity(0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    if (customLeading != null)
                      customLeading!
                    else if (icon != null)
                      Icon(icon, size: 22, color: iconColor)
                    else
                      const SizedBox(width: 22),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
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
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Text(
        'G',
        style: AppTextStyles.bodySmall.copyWith(
          color: Colors.red,
          fontWeight: FontWeight.w900,
          fontSize: 14,
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
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: onTerms,
              child: Text(
                'Terms',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const TextSpan(text: ' & '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: onPrivacyPolicy,
              child: Text(
                'Privacy Policy',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}