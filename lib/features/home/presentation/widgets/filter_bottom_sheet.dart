import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymz_user/features/home/application/gym_filter_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';


class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late List<String> _tempTiers;
  late String _tempSortBy;
  late double _tempMaxDistance;

  final _availableTiers = const ['Platinum', 'Diamond', 'Gold', 'Silver'];

  @override
  void initState() {
    super.initState();
    _tempTiers = List.from(ref.read(selectedTiersProvider));
    _tempSortBy = ref.read(sortByProvider);
    _tempMaxDistance = ref.read(maxDistanceProvider);
  }

  void _toggleTier(String tier) {
    setState(() {
      if (_tempTiers.contains(tier)) {
        _tempTiers.remove(tier);
      } else {
        _tempTiers.add(tier);
      }
    });
  }

  void _applyFilters() {
    ref.read(selectedTiersProvider.notifier).state = _tempTiers;
    ref.read(sortByProvider.notifier).state = _tempSortBy;
    ref.read(maxDistanceProvider.notifier).state = _tempMaxDistance;
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _tempTiers = [];
      _tempSortBy = 'distance';
      _tempMaxDistance = 10.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.isDark ? AppColors.surfaceCardSolid : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: AppTextStyles.displayMedium),
              TextButton(
                onPressed: _resetFilters,
                child: Text('Reset', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 1. Tiers filter
          Text('MEMBERSHIP TIERS', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _availableTiers.map((tier) {
              final isSelected = _tempTiers.contains(tier);
              return FilterChip(
                showCheckmark: false,
                label: Text(tier, style: AppTextStyles.caption.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary)),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.surfaceCardBorder),
                ),
                onSelected: (_) => _toggleTier(tier),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 2. Distance slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MAX DISTANCE', style: AppTextStyles.label),
              Text('${_tempMaxDistance.toStringAsFixed(1)} km', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          Slider(
            value: _tempMaxDistance,
            min: 1.0,
            max: 15.0,
            divisions: 14,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.divider,
            onChanged: (val) => setState(() => _tempMaxDistance = val),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. Sort by options
          Text('SORT BY', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          _SortOptionRow(
            label: 'Closest Distance',
            value: 'distance',
            groupValue: _tempSortBy,
            onChanged: (val) => setState(() => _tempSortBy = val!),
          ),
          _SortOptionRow(
            label: 'Highest Rating',
            value: 'rating',
            groupValue: _tempSortBy,
            onChanged: (val) => setState(() => _tempSortBy = val!),
          ),
          _SortOptionRow(
            label: 'Lowest Price / Session',
            value: 'price',
            groupValue: _tempSortBy,
            onChanged: (val) => setState(() => _tempSortBy = val!),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Apply button
          PrimaryButton(
            label: 'Apply Filters',
            onPressed: _applyFilters,
          ),
        ],
      ),
    );
  }
}

class _SortOptionRow extends StatelessWidget {
  const _SortOptionRow({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.body),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
