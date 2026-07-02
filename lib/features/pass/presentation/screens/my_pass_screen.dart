import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';

class PassData {
  const PassData({
    required this.memberName,
    required this.gymName,
    required this.passId,
    required this.date,
    required this.time,
    required this.tier,
  });

  final String memberName;
  final String gymName;
  final String passId;
  final DateTime date;
  final String time;
  final String tier;

  String get dateLabel => DateFormat('dd MMM yyyy').format(date);
}

class UpcomingPass {
  const UpcomingPass({
    required this.gymName,
    required this.date,
    required this.time,
    required this.session,
    required this.dayOfMonth,
    this.isActive = false,
  });

  final String gymName;
  final String date;
  final String time;
  final String session;
  final int dayOfMonth;
  final bool isActive;
}

class MyPassScreen extends StatelessWidget {
  const MyPassScreen({
    super.key,
    required this.pass,
    this.upcomingPasses = const [],
    this.onDownload,
    this.onShare,
  });

  final PassData pass;
  final List<UpcomingPass> upcomingPasses;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text('My Pass', style: AppTextStyles.displayMedium),
            const SizedBox(height: AppSpacing.xl),
            _ActivePassCard(pass: pass),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Download',
                    leadingIcon: Icons.download_outlined,
                    onPressed: onDownload,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Material(
                    color: AppColors.surfaceCardSolid,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: onShare,
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.surfaceCardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.share_outlined, size: 18, color: AppColors.textPrimary),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Share', style: AppTextStyles.buttonLabel),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (upcomingPasses.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxl),
              Text('Upcoming Passes', style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.md),
              for (final upcoming in upcomingPasses)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _UpcomingPassItem(pass: upcoming),
                ),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _ActivePassCard extends StatelessWidget {
  const _ActivePassCard({required this.pass});
  final PassData pass;

  Color get _tierColor {
    switch (pass.tier) {
      case 'Platinum': return AppColors.tierPlatinum;
      case 'Diamond': return AppColors.tierDiamond;
      case 'Gold': return AppColors.tierGold;
      default: return AppColors.tierSilver;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2580), Color(0xFF0D1150)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.surfaceCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
                  children: const [
                    TextSpan(text: 'GYM', style: TextStyle(color: AppColors.textPrimary)),
                    TextSpan(text: 'z', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _tierColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _tierColor),
                ),
                child: Text(
                  pass.tier.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(color: _tierColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Member', style: AppTextStyles.bodySmall),
          Text(pass.memberName, style: AppTextStyles.displayMedium),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _PassField(label: 'GYM', value: pass.gymName),
              ),
              Expanded(
                child: _PassField(label: 'PASS ID', value: pass.passId),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _PassField(label: 'DATE', value: pass.dateLabel)),
              Expanded(child: _PassField(label: 'TIME', value: pass.time)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                color: Colors.white,
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.qr_code_2, size: 64, color: Colors.black),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan this QR at the gym entrance to check in.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '#${pass.passId}',
                      style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassField extends StatelessWidget {
  const _PassField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _UpcomingPassItem extends StatelessWidget {
  const _UpcomingPassItem({required this.pass});
  final UpcomingPass pass;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.surfaceCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.iconCircleBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              '${pass.dayOfMonth}',
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pass.gymName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                Text('${pass.date} · ${pass.time} · ${pass.session}', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          if (pass.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.active.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.active),
              ),
              child: Text('ACTIVE', style: AppTextStyles.caption.copyWith(color: AppColors.active, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}