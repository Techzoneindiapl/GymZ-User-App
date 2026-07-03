import 'package:flutter/material.dart';
import 'package:gymz_user/core/theme/app_colors.dart';
import 'package:gymz_user/core/theme/app_spacing.dart';
import 'package:gymz_user/core/theme/app_text_styles.dart';
import '../../domain/gym_model.dart';

class GymCard extends StatelessWidget {
  const GymCard({super.key, required this.gym, required this.onTap});

  final GymModel gym;
  final VoidCallback onTap;

  Color get _tierColor {
    switch (gym.tier) {
      case 'Platinum': return AppColors.tierPlatinum;
      case 'Diamond': return AppColors.tierDiamond;
      case 'Gold': return AppColors.tierGold;
      default: return AppColors.tierSilver;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: AppColors.surfaceCardSolid,
              child:  Center(
                child: Icon(Icons.fitness_center, size: 48, color: AppColors.textMuted),
              ),
            ),
            // Dark gradient overlay for text readability.
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xCC000000)],
                  ),
                ),
              ),
            ),
            // Category badge (top left).
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(gym.category, style: AppTextStyles.caption.copyWith(color: Colors.white)),
              ),
            ),
            // Tier badge (top right).
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _tierColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  gym.tier,
                  style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            // Bottom info row.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(gym.name, style: AppTextStyles.sectionTitle),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 2),
                                Text(gym.distanceLabel, style: AppTextStyles.caption),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('From', style: AppTextStyles.caption),
                            Text('\u20B9${gym.pricePerSession}', style: AppTextStyles.price),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(gym.timingLabel, style: AppTextStyles.caption),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: AppColors.starColor),
                            const SizedBox(width: 2),
                            Text(gym.rating.toString(), style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}