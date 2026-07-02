import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../home/domain/gym_model.dart';

class GymDetailScreen extends StatefulWidget {
  const GymDetailScreen({super.key, required this.gym, this.onBack, this.onBookNow, this.onShare});

  final GymModel gym;
  final VoidCallback? onBack;
  final VoidCallback? onBookNow;
  final VoidCallback? onShare;

  @override
  State<GymDetailScreen> createState() => _GymDetailScreenState();
}

class _GymDetailScreenState extends State<GymDetailScreen> {
  bool _termsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final gym = widget.gym;

    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Hero image.
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Container(
              color: AppColors.surfaceCardSolid,
              child: const Center(
                child: Icon(Icons.fitness_center, size: 60, color: AppColors.textMuted),
              ),
            ),
          ),
          // Gradient from image into card.
          Positioned(
            top: 220,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: const BoxDecoration(
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
                    _CircleIconButton(icon: Icons.arrow_back, onTap: widget.onBack),
                    _CircleIconButton(icon: Icons.share_outlined, onTap: widget.onShare),
                  ],
                ),
              ),
            ),
          ),
          // Scrollable content.
          Positioned.fill(
            top: 260,
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
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCardSolid,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: AppColors.surfaceCardBorder),
                              ),
                              child: Text('${gym.tier} · ${gym.category}', style: AppTextStyles.caption),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(gym.name, style: AppTextStyles.displayMedium),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(children: [
                                  const Icon(Icons.star, size: 16, color: AppColors.starColor),
                                  const SizedBox(width: 2),
                                  Text(gym.rating.toString(), style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                                ]),
                                Text('${gym.distanceLabel} away', style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(child: Text(gym.address, style: AppTextStyles.bodySmall)),
                        ]),
                        const SizedBox(height: AppSpacing.xs),
                        Row(children: [
                          const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: AppSpacing.xs),
                          Text(gym.timingLabel, style: AppTextStyles.bodySmall),
                        ]),
                        const SizedBox(height: AppSpacing.md),
                        Text(gym.description, style: AppTextStyles.bodySmall.copyWith(fontSize: 14)),
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
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: gym.facilities.map((f) => _FacilityChip(label: f)).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text('Usage Instructions', style: AppTextStyles.sectionTitle),
                        const SizedBox(height: AppSpacing.lg),
                        for (final instruction in gym.usageInstructions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 8, color: AppColors.primary),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: Text(instruction, style: AppTextStyles.body)),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xl),
                        // Terms & Conditions accordion.
                        Material(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
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
                                      'Standard membership terms apply. No refunds on single sessions. Management reserves the right to refuse entry.',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fixed bottom bar: price + Book Now.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
              decoration: const BoxDecoration(
                color: AppColors.backgroundBottom,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('From', style: AppTextStyles.caption),
                      Text('\u20B9${gym.pricePerSession} / session', style: AppTextStyles.price),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: PrimaryButton(label: 'Book Now', onPressed: widget.onBookNow)),
                ],
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.surfaceCardBorder),
      ),
      child: Text(label, style: AppTextStyles.body),
    );
  }
}