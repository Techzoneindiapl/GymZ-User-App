import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Reusable Shimmer Loading Wrapper.
/// Adapts its colors automatically to the current theme (dark or light mode).
class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    // Use current theme flag to determine shimmer colors.
    final baseColor = AppColors.isDark
        ? const Color(0xFF1F2235) // Slightly lighter than standard background
        : const Color(0xFFE2E8F0); // Light gray
    final highlightColor = AppColors.isDark
        ? const Color(0xFF2E3247) // Highlight gray/blue for dark mode
        : const Color(0xFFF1F5F9); // Crisp white-gray for light mode

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

/// Generic Shimmer Box/Shape Block.
class ShimmerBlock extends StatelessWidget {
  const ShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.sm,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // Overridden by shimmer but required to paint shape
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton Loader representing a single GymCard.
class GymCardSkeleton extends StatelessWidget {
  const GymCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.surfaceCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top badges row (Category on left, Tier on right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBlock(width: 70, height: 20, borderRadius: AppRadius.pill),
              ShimmerBlock(width: 60, height: 20, borderRadius: AppRadius.pill),
            ],
          ),
          const Spacer(),
          // Bottom info rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBlock(width: 150, height: 18),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: const [
                      ShimmerBlock(width: 12, height: 12, borderRadius: 6),
                      SizedBox(width: 4),
                      ShimmerBlock(width: 80, height: 12),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  ShimmerBlock(width: 30, height: 10),
                  SizedBox(height: 4),
                  ShimmerBlock(width: 50, height: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerBlock(width: 120, height: 12),
              Row(
                children: const [
                  ShimmerBlock(width: 12, height: 12, borderRadius: 6),
                  SizedBox(width: 4),
                  ShimmerBlock(width: 24, height: 12),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
