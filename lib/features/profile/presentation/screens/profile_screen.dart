import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';

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
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return GradientScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text('Profile', style: AppTextStyles.displayMedium),
            const SizedBox(height: AppSpacing.xl),
            // Profile card.
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.surfaceCardBorder),
              ),
              child: Row(
                children: [
                  Stack(
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
                          child:  Icon(Icons.camera_alt, size: 12, color: AppColors.primary),
                        ),
                      ),
                    ],
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
            Text('APPEARANCE', style: AppTextStyles.label),
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
            // Menu list.
            _MenuCard(
              items: [
                _MenuItem(icon: Icons.card_giftcard_outlined, label: 'Rewards', subtitle: 'Unlock after every 50 sessions', onTap: widget.onRewards),
                _MenuItem(icon: Icons.credit_card_outlined, label: 'Fitness Card', onTap: widget.onFitnessCard),
                _MenuItem(icon: Icons.history_outlined, label: 'Booking History', onTap: widget.onBookingHistory),
                _MenuItem(icon: Icons.wallet_outlined, label: 'Wallet', onTap: widget.onWallet),
                _MenuItem(icon: Icons.settings_outlined, label: 'Settings', onTap: widget.onSettings),
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
                      Text('Logout', style: AppTextStyles.buttonLabel.copyWith(color: AppColors.danger)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
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