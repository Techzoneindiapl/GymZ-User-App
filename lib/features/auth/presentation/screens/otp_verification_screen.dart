import 'dart:async';
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

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  
  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    final phone = ref.read(authProvider).phone;
    if (phone != null) {
      final success = await ref.read(authProvider.notifier).sendOtp(phone);
      if (success) {
        _startTimer();
      }
    }
  }

  String _getOtp() {
    return _controllers.map((c) => c.text).join();
  }

  bool _isOtpComplete() {
    return _getOtp().length == 4;
  }

  Future<void> _handleVerify() async {
    final otp = _getOtp();
    if (otp.length != 4) return;

    final response = await ref.read(authProvider.notifier).verifyOtp(otp);
    if (response != null && mounted) {
      if (response.isRegistered) {
        // User is already registered: go to location permissions or home page
        context.goNamed(RouteNames.locationPermission);
      } else {
        // User is verified but has not registered yet: go to registration screen
        context.goNamed(RouteNames.createAccount);
      }
    }
  }

  void _onFieldChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _handleVerify();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating;
    final phone = authState.phone ?? '';

    return GradientScaffold(
      body: Column(
        children: [
          // AppBar Row
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
                Text('Verify OTP', style: AppTextStyles.displayMedium),
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
                    'We sent a 4-digit code to',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '+91 ${phone.substring(0, 5)} ${phone.substring(5)}',
                    style: AppTextStyles.sectionTitle.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Row of 4 inputs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      return SizedBox(
                        width: 70,
                        height: 70,
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) {
                            if (event is RawKeyDownEvent && 
                                event.logicalKey == LogicalKeyboardKey.backspace && 
                                _controllers[index].text.isEmpty && 
                                index > 0) {
                              _controllers[index - 1].clear();
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: AppTextStyles.displayMedium.copyWith(
                              fontSize: 26,
                              color: AppColors.primary,
                            ),
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.surfaceCard,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                borderSide: BorderSide(
                                  color: AppColors.surfaceCardBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                borderSide: BorderSide(
                                  color: AppColors.surfaceCardBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                borderSide:  BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (val) => _onFieldChanged(index, val),
                          ),
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Timer row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _canResend ? "Didn't receive code? " : "Resend OTP in ",
                        style: AppTextStyles.bodySmall,
                      ),
                      if (!_canResend)
                        Text(
                          '${_secondsRemaining}s',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _handleResend,
                          child: Text(
                            'Resend OTP',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  if (authState.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
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
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  PrimaryButton(
                    label: 'Verify & Continue',
                    isEnabled: _isOtpComplete() && !isLoading,
                    isLoading: isLoading,
                    onPressed: _handleVerify,
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
