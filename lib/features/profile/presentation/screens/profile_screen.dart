import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymz_user/features/auth/domain/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/text_size_provider.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../application/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.memberId,
    this.avatarPath,
    this.sessionCount = 0,
    this.gymCount = 0,
    this.memberSinceDays = 0,
    this.onCardTap,
    this.onRewards,
    this.onFitnessCard,
    this.onBookingHistory,
    this.onWallet,
    this.onSettings,
    this.onLogout,
  });

  final String name;
  final String email;
  final String memberId;
  final String? avatarPath;
  final int sessionCount;
  final int gymCount;
  final int memberSinceDays;
  final VoidCallback? onCardTap;
  final VoidCallback? onRewards;
  final VoidCallback? onFitnessCard;
  final VoidCallback? onBookingHistory;
  final VoidCallback? onWallet;
  final VoidCallback? onSettings;
  final VoidCallback? onLogout;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.inAppWebView);
    } catch (e) {
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open link: $urlString'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).fetchProfile();
    });
  }

  Future<void> _showImageSourceActionSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCardSolid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Update Profile Photo',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
              ),
              ListTile(
                leading:  Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading:  Icon(Icons.photo_camera, color: AppColors.primary),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await ref.read(profileProvider.notifier).uploadProfileImage(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildRewardsCard(int sessionCount) {
    final int sessionsInCycle = sessionCount % 50;
    final int toGo = 50 - sessionsInCycle;
    final int freeSessions = sessionCount ~/ 50;
    final double progress = sessionsInCycle / 50.0;

    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onRewards,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.iconCircleBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.card_giftcard_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rewards',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Unlock 1 free session every 50 sessions',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$sessionsInCycle / 50 sessions',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$toGo to go',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: progress,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total completed: $sessionCount',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: 'Free sessions earned: ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: '$freeSessions',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final profileState = ref.watch(profileProvider);
    final tr = ref.watch(translationProvider);

    ref.listen<AsyncValue<UserModel?>>(profileProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    return GradientScaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(profileProvider.notifier).refreshProfile(),
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceCard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr['profile'] ?? 'Profile', style: AppTextStyles.displayMedium),
                  if (profileState.isLoading)
                      SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // Profile card.
              Material(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: InkWell(
                  onTap: widget.onCardTap,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.surfaceCardBorder),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showImageSourceActionSheet(context),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: AppColors.iconCircleBg,
                                backgroundImage: widget.avatarPath != null && widget.avatarPath!.isNotEmpty
                                    ? (widget.avatarPath!.startsWith('http')
                                        ? NetworkImage(widget.avatarPath!) as ImageProvider
                                        : FileImage(File(widget.avatarPath!)) as ImageProvider)
                                    : null,
                                child: widget.avatarPath == null || widget.avatarPath!.isEmpty
                                    ? Icon(Icons.person, size: 36, color: AppColors.textSecondary)
                                    : null,
                              ),
                              if (profileState.isLoading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child:  Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCardSolid,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child:   Icon(Icons.camera_alt, size: 12, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.name, style: AppTextStyles.sectionTitle),
                              Text(widget.email, style: AppTextStyles.bodySmall),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                widget.memberId,
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onCardTap,
                          style: TextButton.styleFrom(backgroundColor: AppColors.primary, shape: const StadiumBorder()),
                          child: Text('Card', style: AppTextStyles.buttonLabel.copyWith(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Stats row.
              Row(
                children: [
                  Expanded(child: _StatCard(value: '${widget.sessionCount}', label: 'SESSIONS', valueColor: AppColors.primary)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _StatCard(value: '${widget.gymCount}', label: 'GYMS', valueColor: AppColors.primary)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _StatCard(value: '${widget.memberSinceDays} Days', label: 'MEMBER SINCE', valueColor: AppColors.primary)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // Appearance toggle.
              Text(tr['theme']?.toUpperCase() ?? 'THEME', style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ThemeToggleButton(
                        icon: Icons.dark_mode_outlined,
                        label: 'Dark Mode',
                        isSelected: isDarkMode,
                        onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
                      ),
                    ),
                    Expanded(
                      child: _ThemeToggleButton(
                        icon: Icons.light_mode_outlined,
                        label: 'Light Mode',
                        isSelected: !isDarkMode,
                        onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.light,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Text size toggle.
              Text(tr['text_size']?.toUpperCase() ?? 'TEXT SIZE', style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TextSizeToggleButton(
                        label: 'Medium',
                        isSelected: ref.watch(textSizeProvider) == TextSizeScale.medium,
                        onTap: () => ref.read(textSizeProvider.notifier).state = TextSizeScale.medium,
                      ),
                    ),
                    Expanded(
                      child: _TextSizeToggleButton(
                        label: 'Large',
                        isSelected: ref.watch(textSizeProvider) == TextSizeScale.large,
                        onTap: () => ref.read(textSizeProvider.notifier).state = TextSizeScale.large,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Language selection.
              Text(tr['language']?.toUpperCase() ?? 'LANGUAGE', style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: () => _showLanguagePicker(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceCardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.language_rounded, color: AppColors.primary, size: 24),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            ref.watch(languageProvider).nativeName,
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Rewards Card
              _buildRewardsCard(widget.sessionCount),
              const SizedBox(height: AppSpacing.lg),
              // Menu list.
              _MenuCard(
                items: [
                  _MenuItem(icon: Icons.credit_card_outlined, label: tr['fitness_card'] ?? 'Fitness Card', onTap: widget.onFitnessCard),
                  _MenuItem(icon: Icons.history_outlined, label: tr['booking_history'] ?? 'Booking History', onTap: widget.onBookingHistory),
                  _MenuItem(icon: Icons.wallet_outlined, label: tr['wallet'] ?? 'Wallet', onTap: widget.onWallet),
                  // _MenuItem(icon: Icons.settings_outlined, label: 'Settings', onTap: widget.onSettings),
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: tr['privacy_policy'] ?? 'Privacy Policy',
                    onTap: () => _launchURL('https://www.gymz.co.in/privacy'),
                  ),
                  _MenuItem(
                    icon: Icons.description_outlined,
                    label: tr['terms_and_conditions'] ?? 'Terms and Conditions',
                    onTap: () => _launchURL('https://www.gymz.co.in/terms'),
                  ),
                  _MenuItem(
                    icon: Icons.help_outline_outlined,
                    label: tr['help_and_support'] ?? 'Help & Support',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Help & Support screen coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // Logout.
              Material(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: widget.onLogout,
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.danger.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 18, color: AppColors.danger),
                        const SizedBox(width: AppSpacing.sm),
                        Text(tr['logout'] ?? 'Logout', style: AppTextStyles.buttonLabel.copyWith(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        side: BorderSide(color: AppColors.surfaceCardBorder),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentLanguage = ref.watch(languageProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Select Language',
                      style: AppTextStyles.displayMedium.copyWith(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: AppLanguage.values.length,
                        itemBuilder: (context, index) {
                          final language = AppLanguage.values[index];
                          final isSelected = currentLanguage == language;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: InkWell(
                              onTap: () {
                                ref.read(languageProvider.notifier).setLanguage(language);
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      language.nativeName,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
   _StatCard({required this.value, required this.label, required this.valueColor});
  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.surfaceCardBorder),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(value, style: AppTextStyles.sectionTitle.copyWith(color: valueColor, fontSize: 22)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({required this.icon, required this.label, required this.isSelected, required this.onTap});
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceCardSolid : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.textPrimary : AppColors.textMuted),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTextStyles.body.copyWith(fontSize: 13, color: isSelected ? AppColors.textPrimary : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _TextSizeToggleButton extends StatelessWidget {
  const _TextSizeToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceCardSolid : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.surfaceCardBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i != items.length - 1) Container(height: 1, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.subtitle, this.onTap});
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: AppColors.iconCircleBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.body),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}