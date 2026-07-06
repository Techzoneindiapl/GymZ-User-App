import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../home/domain/gym_model.dart';
import '../../application/gym_detail_provider.dart';

class GymDetailScreen extends ConsumerStatefulWidget {
  const GymDetailScreen({super.key, required this.gym, this.onBack, this.onBookNow, this.onShare});

  final GymModel gym;
  final VoidCallback? onBack;
  final VoidCallback? onBookNow;
  final VoidCallback? onShare;

  @override
  ConsumerState<GymDetailScreen> createState() => _GymDetailScreenState();
}

class _GymDetailScreenState extends ConsumerState<GymDetailScreen> {
  bool _termsExpanded = false;
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Watch detailed gym data provider.
    final gymDetailsAsync = ref.watch(gymDetailsProvider(widget.gym.id));

    // Use fully loaded gym details if available, fallback to basic widget.gym in background.
    final gym = gymDetailsAsync.maybeWhen(
      data: (details) => details,
      orElse: () => widget.gym,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      extendBodyBehindAppBar: true,
      // IMPORTANT: extendBody is false (default). This means Scaffold
      // automatically insets `body` above `bottomNavigationBar`, so the
      // scroll area can never be covered by the price/Book Now bar again,
      // regardless of how tall that bar renders on a given device.
      body: Stack(
        children: [
          // Hero image / gallery carousel.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: gym.galleryPhotos.isNotEmpty
                ? Stack(
                    children: [
                      PageView.builder(
                        itemCount: gym.galleryPhotos.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Image.network(
                            gym.galleryPhotos[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.surfaceCardSolid,
                              child: Center(
                                child: Icon(Icons.fitness_center, size: 60, color: AppColors.textMuted),
                              ),
                            ),
                          );
                        },
                      ),
                      if (gym.galleryPhotos.length > 1)
                        Positioned(
                          bottom: 50,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              gym.galleryPhotos.length,
                              (index) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index
                                      ? AppColors.primary
                                      : AppColors.textMuted.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : (gym.imageUrl.isNotEmpty
                    ? Image.network(
                        gym.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.surfaceCardSolid,
                          child: Center(
                            child: Icon(Icons.fitness_center, size: 60, color: AppColors.textMuted),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceCardSolid,
                        child: Center(
                          child: Icon(Icons.fitness_center, size: 60, color: AppColors.textMuted),
                        ),
                      )),
          ),
          // Gradient from image into card.
          Positioned(
            top: 270,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.backgroundBottom],
                ),
              ),
            ),
          ),
          // Top action buttons.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleIconButton(icon: Icons.chevron_left, onTap: widget.onBack),
                    _CircleIconButton(icon: Icons.share_outlined, onTap: widget.onShare),
                  ],
                ),
              ),
            ),
          ),
          // Scrollable content.
          // NOTE: bottom is now 0 — Scaffold already reserves the space
          // taken by bottomNavigationBar, so this no longer needs to guess
          // the bar's height, and content is never hidden behind it.
          Positioned(
            top: 310,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card.
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: AppColors.surfaceCardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                '${gym.tier} · ${gym.category}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, size: 20, color: AppColors.starColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      gym.rating.toStringAsFixed(1),
                                      style: AppTextStyles.displayMedium.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${gym.distanceLabel} away',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(gym.name, style: AppTextStyles.displayMedium.copyWith(fontSize: 26, fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                gym.address,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              gym.timingLabel,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          gym.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Facilities', style: AppTextStyles.sectionTitle),
                        const SizedBox(height: AppSpacing.lg),
                        GridView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: AppSpacing.sm,
                            mainAxisSpacing: AppSpacing.sm,
                            childAspectRatio: 1.7,
                          ),
                          itemCount: gym.facilities.length,
                          itemBuilder: (context, index) {
                            return _FacilityChip(label: gym.facilities[index]);
                          },
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text('Usage Instructions', style: AppTextStyles.sectionTitle),
                        const SizedBox(height: AppSpacing.lg),
                        for (final instruction in gym.usageInstructions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    instruction,
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xl),
                        // Terms & Conditions accordion.
                        Material(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              border: Border.all(color: AppColors.surfaceCardBorder),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              onTap: () => setState(() => _termsExpanded = !_termsExpanded),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Terms & Conditions', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                                        Icon(
                                          _termsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                    if (_termsExpanded) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        'Pass is valid for the booked date only and non-transferable.',
                                        style: AppTextStyles.bodySmall.copyWith(height: 1.4, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        'Late entry by more than 15 minutes will forfeit the session.',
                                        style: AppTextStyles.bodySmall.copyWith(height: 1.4, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        'Refund / reschedule available up to 2 hours before the session.',
                                        style: AppTextStyles.bodySmall.copyWith(height: 1.4, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // A little breathing room is still nice, but we no
                        // longer need a large magic-number gap to dodge the
                        // bottom bar — Scaffold handles that now.
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Fixed bottom bar: price + Book Now.
      // Moved out of the Stack and into bottomNavigationBar so Scaffold
      // reserves exactly the space this bar needs (whatever its real
      // rendered height is) and insets `body` above it automatically.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.backgroundBottom,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Builder(
            builder: (context) {
              final gymDetailsAsync = ref.watch(gymDetailsProvider(widget.gym.id));
              final gym = gymDetailsAsync.maybeWhen(
                data: (details) => details,
                orElse: () => widget.gym,
              );
              return Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        gym.activeSlotLabel.isNotEmpty ? gym.activeSlotLabel : 'From',
                        style: AppTextStyles.caption.copyWith(
                          color: gym.activeSlotLabel.isNotEmpty ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '\u20B9${gym.currentPrice}',
                            style: AppTextStyles.price.copyWith(
                              color: AppColors.primary,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            ' / session',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: PrimaryButton(label: 'Book Now', onPressed: widget.onBookNow)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}

class _FacilityChip extends StatelessWidget {
  const _FacilityChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}