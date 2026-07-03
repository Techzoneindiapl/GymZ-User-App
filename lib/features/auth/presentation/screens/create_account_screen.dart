import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymz_user/core/router/route_names.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../screens/fitness_pass_screen.dart';
import '../../application/auth_provider.dart';

enum Gender { male, female, other }

class CreateAccountState {
  const CreateAccountState({
    this.fullName = '',
    this.gender = Gender.male,
    this.mobileNumber = '',
    this.email = '',
    this.pincode = '',
    this.selfieFilePath,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String fullName;
  final Gender gender;
  final String mobileNumber;
  final String email;
  final String pincode;
  final String? selfieFilePath;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isValid =>
      fullName.trim().isNotEmpty &&
      mobileNumber.length == 10 &&
      email.contains('@') &&
      pincode.length == 6 &&
      selfieFilePath != null;

  CreateAccountState copyWith({
    String? fullName,
    Gender? gender,
    String? mobileNumber,
    String? email,
    String? pincode,
    String? selfieFilePath,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreateAccountState(
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      pincode: pincode ?? this.pincode,
      selfieFilePath: selfieFilePath ?? this.selfieFilePath,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CreateAccountNotifier extends Notifier<CreateAccountState> {
  @override
  CreateAccountState build() => const CreateAccountState();

  void updateFullName(String v) => state = state.copyWith(fullName: v, clearError: true);
  void updateGender(Gender v) => state = state.copyWith(gender: v);
  void updateMobileNumber(String v) {
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    state = state.copyWith(mobileNumber: digits.length > 10 ? digits.substring(0, 10) : digits);
  }
  void updateEmail(String v) => state = state.copyWith(email: v, clearError: true);
  void updatePincode(String v) {
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    state = state.copyWith(pincode: digits.length > 6 ? digits.substring(0, 6) : digits);
  }
  void updateSelfie(String filePath) => state = state.copyWith(selfieFilePath: filePath);
}

final createAccountProvider =
    NotifierProvider<CreateAccountNotifier, CreateAccountState>(CreateAccountNotifier.new);

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key, this.onBack, this.onSubmit});

  final VoidCallback? onBack;
  final VoidCallback? onSubmit;

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final verifiedPhone = ref.read(authProvider).phone ?? '';
    _phoneController = TextEditingController(text: verifiedPhone);
    
    // Set initial phone value in notifier state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createAccountProvider.notifier).updateMobileNumber(verifiedPhone);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickSelfie(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      ref.read(createAccountProvider.notifier).updateSelfie(picked.path);
    }
  }

  Future<void> _handleRegisterSubmit() async {
    final formState = ref.read(createAccountProvider);
    if (!formState.isValid) return;

    // Use a realistic mock location formatted as: Lat/Long, Address
    const mockLocation = "19.0760,72.8777, Mumbai, Maharashtra";

    final user = await ref.read(authProvider.notifier).register(
      name: formState.fullName,
      gender: formState.gender == Gender.male 
          ? 'Male' 
          : (formState.gender == Gender.female ? 'Female' : 'Other'),
      email: formState.email,
      pincode: formState.pincode,
      selfiePath: formState.selfieFilePath!,
      location: mockLocation,
    );

    if (user != null && mounted) {
      final pass = FitnessPassData(
        fullName: user.name,
        gender: user.gender,
        passId: user.memberId,
        joinedAt: DateTime.now(),
        selfieFilePath: formState.selfieFilePath,
      );
      
      // Navigate to the dynamic fitness pass screen
      context.goNamed(RouteNames.fitnessPass, extra: pass);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createAccountProvider);
    final notifier = ref.read(createAccountProvider.notifier);
    final authState = ref.watch(authProvider);
    final isSubmitting = authState.status == AuthStatus.authenticating;

    return GradientScaffold(
      body: Column(
        children: [
          // AppBar row.
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28),
                  style: IconButton.styleFrom(backgroundColor: AppColors.surfaceCard),
                ),
                const SizedBox(width: AppSpacing.md),
                Text('Create Account', style: AppTextStyles.displayMedium),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Full Name'),
                  _InputField(hint: 'Muzammil Qureshi', onChanged: notifier.updateFullName),
                  const SizedBox(height: AppSpacing.lg),
                  _FieldLabel('Gender'),
                  const SizedBox(height: AppSpacing.sm),
                  _GenderSelector(
                    selected: state.gender,
                    onChanged: notifier.updateGender,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FieldLabel('Mobile Number'),
                  _InputField(
                    hint: '7400105833',
                    keyboardType: TextInputType.phone,
                    onChanged: notifier.updateMobileNumber,
                    controller: _phoneController,
                    enabled: false,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FieldLabel('Email Address'),
                  _InputField(
                    hint: 'you@email.com',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: notifier.updateEmail,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FieldLabel('Pincode'),
                  _InputField(
                    hint: '400050',
                    keyboardType: TextInputType.number,
                    onChanged: notifier.updatePincode,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FieldLabel('Upload Selfie'),
                  const SizedBox(height: AppSpacing.sm),
                  _SelfieUploader(
                    filePath: state.selfieFilePath,
                    onPickCamera: () => _pickSelfie(context),
                  ),
                  
                  // Display error if any
                  if (state.errorMessage != null || authState.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.errorMessage ?? authState.errorMessage!,
                      style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    label: 'Generate My Fitness Pass',
                    isEnabled: state.isValid && !isSubmitting,
                    isLoading: isSubmitting,
                    onPressed: _handleRegisterSubmit,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(label, style: AppTextStyles.bodySmall),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.controller,
    this.enabled = true,
  });
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: AppTextStyles.body.copyWith(
        color: enabled ? AppColors.textPrimary : AppColors.textMuted,
      ),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: enabled ? AppColors.surfaceCard : AppColors.surfaceCardSolid,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.selected, required this.onChanged});
  final Gender selected;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Gender.values.map((g) {
        final isSelected = g == selected;
        final label = g.name[0].toUpperCase() + g.name.substring(1);
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () => onChanged(g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.surfaceCardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SelfieUploader extends StatelessWidget {
  const _SelfieUploader({this.filePath, required this.onPickCamera});
  final String? filePath;
  final VoidCallback onPickCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.surfaceCardBorder, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(color: AppColors.iconCircleBg, shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            child: filePath != null
                ? Image.file(File(filePath!), fit: BoxFit.cover)
                : Icon(Icons.camera_alt_outlined, size: 36, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Open Camera',
            leadingIcon: Icons.camera_alt_outlined,
            onPressed: onPickCamera,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(Icons.info_outline, size: 14, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Note: Keep background plain. Portrait Aligner.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}