import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymz_user/core/router/route_names.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../application/auth_provider.dart';
import '../../../../core/localization/translations.dart';

class MobileLoginScreen extends ConsumerStatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  ConsumerState<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends ConsumerState<MobileLoginScreen> {
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating;
    final tr = ref.watch(translationProvider);

    return GradientScaffold(
      body: Column(
        children: [
          // Custom AppBar Row
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28),
                  style: IconButton.styleFrom(backgroundColor: AppColors.surfaceCard),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(tr['mobile_login_title'] ?? 'Mobile Login', style: AppTextStyles.displayMedium),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    tr['mobile_login_sub'] ?? 'Enter your phone number to continue',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Phone input field wrapper
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(tr['phone_number'] ?? 'Phone Number', style: AppTextStyles.bodySmall),
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
                      hintText: tr['enter_mobile_hint'] ?? '7400105833',
                      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                      prefixText: '+91 ',
                      prefixStyle: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.lg,
                      ),
                    ),
                  ),
                  
                  if (authState.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: AppSpacing.xxxl),
                  
                  PrimaryButton(
                    label: tr['send_otp'] ?? 'Send OTP',
                    isEnabled: _isValid && !isLoading,
                    isLoading: isLoading,
                    onPressed: _handleSendOtp,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
