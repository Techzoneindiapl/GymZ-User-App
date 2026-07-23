import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/domain/gym_model.dart';
import '../../../home/presentation/widgets/category_chip.dart';
import '../../../home/presentation/widgets/gym_card.dart';
import '../../../home/presentation/widgets/search_bar_widget.dart';
import '../../../home/presentation/widgets/filter_bottom_sheet.dart';
import '../../../home/application/gym_filter_provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/localization/language_provider.dart';


class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, required this.onGymTap});

  final ValueChanged<GymModel> onGymTap;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(gymSearchQueryProvider),
    );
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

  void _resetAllFilters() {
    ref.read(gymSearchQueryProvider.notifier).state = '';
    ref.read(selectedCategoryProvider.notifier).state = null;
    ref.read(selectedTiersProvider.notifier).state = const [];
    ref.read(sortByProvider.notifier).state = 'distance';
    ref.read(maxDistanceProvider.notifier).state = 10.0;
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final filteredGymsAsync = ref.watch(filteredGymsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final tr = ref.watch(translationProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gymsListProvider);
        },
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceCard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr['explore'] ?? 'Explore', style: AppTextStyles.displayMedium),
              const SizedBox(height: AppSpacing.lg),

              // Search Bar
              SearchBarWidget(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(gymSearchQueryProvider.notifier).state = val;
                },
                onFilterTap: _showFilterBottomSheet,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Categories Row
              Text(tr['categories'] ?? 'Categories', style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kCategories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final category = kCategories[index];
                    final isSelected = selectedCategory == category;
                    final String translatedCategory;
                    switch (category) {
                      case 'Gym':
                        translatedCategory = tr['category_gym'] ?? 'Gym';
                        break;
                      case 'Yoga':
                        translatedCategory = tr['category_yoga'] ?? 'Yoga';
                        break;
                      case 'Sports':
                        translatedCategory = tr['category_sports'] ?? 'Sports';
                        break;
                      case 'Zumba':
                        translatedCategory = tr['category_zumba'] ?? 'Zumba';
                        break;
                      default:
                        translatedCategory = category;
                    }
                    return CategoryChip(
                      label: translatedCategory,
                      isSelected: isSelected,
                      categoryName: category,
                      onTap: () {
                        final notifier = ref.read(
                          selectedCategoryProvider.notifier,
                        );
                        if (isSelected) {
                          notifier.state = null;
                        } else {
                          notifier.state = category;
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Listings Section
              filteredGymsAsync.when(
                data: (filteredGyms) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            filteredGyms.isEmpty
                                ? (tr['fitness_centers'] ?? 'Fitness Centers')
                                : 'Found ${filteredGyms.length} ${filteredGyms.length == 1 ? 'center' : 'centers'}',
                            style: AppTextStyles.sectionTitle,
                          ),
                          if (filteredGyms.isNotEmpty)
                            TextButton(
                              onPressed: _resetAllFilters,
                              child: Text(
                                tr['clear_all'] ?? 'Clear All',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (filteredGyms.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCard,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.surfaceCardBorder,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.search_off_outlined,
                                    size: 36,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                 Text(
                                  tr['no_gyms_found'] ?? 'No fitness centers found',
                                  style: AppTextStyles.sectionTitle.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xl,
                                  ),
                                  child: Text(
                                    'Try expanding your search distance, selecting a different category, or resetting all filters.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                ElevatedButton.icon(
                                  onPressed: _resetAllFilters,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: Text(tr['reset_all'] ?? 'Reset All Filters'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredGyms.length,
                          itemBuilder: (context, index) {
                            final gym = filteredGyms[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.lg,
                              ),
                              child: GymCard(
                                gym: gym,
                                onTap: () => widget.onGymTap(gym),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
                loading: () => const ShimmerLoading(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.lg),
                        child: GymCardSkeleton(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.lg),
                        child: GymCardSkeleton(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.lg),
                        child: GymCardSkeleton(),
                      ),
                    ],
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.danger,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Something went wrong',
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          err.toString().replaceAll('Exception: ', ''),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
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
}
