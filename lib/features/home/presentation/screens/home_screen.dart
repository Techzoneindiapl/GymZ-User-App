import 'package:flutter/material.dart';
import 'package:gymz_user/features/home/domain/gym_model.dart';
import 'package:gymz_user/features/home/presentation/widgets/category_chip.dart';
import 'package:gymz_user/features/home/presentation/widgets/gym_card.dart';
import 'package:gymz_user/features/home/presentation/widgets/premium_tier_card.dart';
import 'package:gymz_user/features/home/presentation/widgets/search_bar_widget.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.ownerFirstName = 'Aasif',
    this.avatarPath,
    this.onGymTap,
    this.onSeeAllNearby,
    this.onSeeAllTiers,
    this.onCategoryTap,
    this.onSearchTap,
    this.onFilterTap,
    this.onNotificationTap,
    this.onPassTap,
  });

  final String ownerFirstName;
  final String? avatarPath;
  final ValueChanged<GymModel>? onGymTap;
  final VoidCallback? onSeeAllNearby;
  final VoidCallback? onSeeAllTiers;
  final ValueChanged<String>? onCategoryTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onPassTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _HomeHeader(
              firstName: ownerFirstName,
              avatarPath: avatarPath,
              onNotificationTap: onNotificationTap,
              onPassTap: onPassTap,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: SearchBarWidget(onTap: onSearchTap, onFilterTap: onFilterTap),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _SectionHeader(title: 'Categories', onSeeAll: () {}),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: kCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                return CategoryChip(
                  label: kCategories[index],
                  onTap: () => onCategoryTap?.call(kCategories[index]),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _SectionHeader(title: 'Nearby Gyms', onSeeAll: onSeeAllNearby),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final gym in kSampleGyms)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
              child: GymCard(
                gym: gym,
                onTap: () => onGymTap?.call(gym),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _SectionHeader(title: 'Premium Tiers', onSeeAll: onSeeAllTiers),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.8,
              children: const [
                PremiumTierCard(tier: 'Platinum'),
                PremiumTierCard(tier: 'Diamond'),
                PremiumTierCard(tier: 'Gold'),
                PremiumTierCard(tier: 'Silver'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.firstName,
    required this.avatarPath,
    required this.onNotificationTap,
    required this.onPassTap,
  });

  final String firstName;
  final String? avatarPath;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onPassTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.surfaceCard,
          backgroundImage: avatarPath != null ? AssetImage(avatarPath!) : null,
          child: avatarPath == null
              ? const Icon(Icons.person, color: AppColors.textSecondary)
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello,', style: AppTextStyles.bodySmall),
              Text('$firstName \uD83D\uDC4B', style: AppTextStyles.sectionTitle),
            ],
          ),
        ),
        IconButton(
          onPressed: onNotificationTap,
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
          style: IconButton.styleFrom(backgroundColor: AppColors.surfaceCard),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          onPressed: onPassTap,
          icon: const Icon(Icons.wallet_outlined, color: AppColors.textPrimary),
          style: IconButton.styleFrom(backgroundColor: AppColors.surfaceCard),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        GestureDetector(
          onTap: onSeeAll,
          child: Text('See all', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
        ),
      ],
    );
  }
}