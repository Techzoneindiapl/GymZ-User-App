import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymz_user/features/home/domain/gym_model.dart';
import 'package:gymz_user/features/home/presentation/widgets/category_chip.dart';
import 'package:gymz_user/features/home/presentation/widgets/gym_card.dart';
import 'package:gymz_user/features/home/presentation/widgets/premium_tier_card.dart';
import 'package:gymz_user/features/home/presentation/widgets/search_bar_widget.dart';
import 'package:gymz_user/features/home/presentation/widgets/filter_bottom_sheet.dart';
import 'package:gymz_user/features/home/application/gym_filter_provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';


class HomeScreen extends ConsumerStatefulWidget {
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
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(gymSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredGymsAsync = ref.watch(filteredGymsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _HomeHeader(
              firstName: widget.ownerFirstName,
              avatarPath: widget.avatarPath,
              onNotificationTap: widget.onNotificationTap,
              onPassTap: widget.onPassTap,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: SearchBarWidget(
              controller: _searchController,
              onChanged: (val) {
                ref.read(gymSearchQueryProvider.notifier).state = val;
              },
              onFilterTap: widget.onFilterTap ?? _showFilterBottomSheet,
            ),
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
                final category = kCategories[index];
                final isSelected = selectedCategory == category;
                return CategoryChip(
                  label: category,
                  isSelected: isSelected,
                  onTap: () {
                    final notifier = ref.read(selectedCategoryProvider.notifier);
                    if (isSelected) {
                      notifier.state = null;
                    } else {
                      notifier.state = category;
                    }
                    widget.onCategoryTap?.call(category);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _SectionHeader(title: 'Nearby Gyms', onSeeAll: widget.onSeeAllNearby),
          ),
          const SizedBox(height: AppSpacing.md),
          filteredGymsAsync.when(
            data: (filteredGyms) {
              if (filteredGyms.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      'No gyms found matching your criteria.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final gym in filteredGyms)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                      child: GymCard(
                        gym: gym,
                        onTap: () => widget.onGymTap?.call(gym),
                      ),
                    ),
                ],
              );
            },
            loading: () => const ShimmerLoading(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                    child: GymCardSkeleton(),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                    child: GymCardSkeleton(),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                    child: GymCardSkeleton(),
                  ),
                ],
              ),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  'Error loading gyms: ${err.toString().replaceAll('Exception: ', '')}',
                  style:  TextStyle(color: AppColors.danger, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _SectionHeader(title: 'Premium Tiers', onSeeAll: widget.onSeeAllTiers),
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
              ? Icon(Icons.person, color: AppColors.textSecondary)
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
          icon: Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
          style: IconButton.styleFrom(backgroundColor: AppColors.surfaceCard),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          onPressed: onPassTap,
          icon: Icon(Icons.wallet_outlined, color: AppColors.textPrimary),
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