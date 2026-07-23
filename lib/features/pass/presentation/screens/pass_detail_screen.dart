import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../gym_detail/domain/booking_model.dart';

class PassDetailScreen extends ConsumerStatefulWidget {
  const PassDetailScreen({
    super.key,
    required this.booking,
    required this.memberName,
    required this.userId,
  });

  final BookingModel booking;
  final String memberName;
  final String userId;

  @override
  ConsumerState<PassDetailScreen> createState() => _PassDetailScreenState();
}

class _PassDetailScreenState extends ConsumerState<PassDetailScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isDownloading = false;
  bool _isSharing = false;

  String get _qrPayload => '${widget.userId}/${widget.booking.bookingId}';

  Future<Uint8List?> _captureCardPng() async {
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      if (kDebugMode && boundary.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing card snapshot: $e');
      return null;
    }
  }

  Future<void> _downloadPass() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final bytes = await _captureCardPng();
      if (bytes == null) {
        throw Exception('Failed to capture card snapshot');
      }

      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gallery permission denied. Please grant permission in settings.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/GYMZ_Pass_${widget.booking.bookingId}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await Gal.putImage(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pass #${widget.booking.bookingId} downloaded to gallery!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading pass: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _sharePass() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final bytes = await _captureCardPng();
      if (bytes == null) {
        throw Exception('Failed to capture card snapshot');
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/GYMZ_Pass_${widget.booking.bookingId}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final parsedDate = DateTime.tryParse(widget.booking.bookingDate) ?? DateTime.now();
      final formattedDate = DateFormat('dd MMM yyyy').format(parsedDate);

      final shareText = 'Check out my GymZ session pass!\n\n'
          'Gym: ${widget.booking.gymName}\n'
          'Date: $formattedDate\n'
          'Time Slot: ${widget.booking.timeSlot}\n'
          'Booking ID: #${widget.booking.bookingId}\n\n'
          'Book your next workout session on GymZ!';

      await Share.shareXFiles(
        [XFile(filePath)],
        text: shareText,
        subject: 'My GymZ Booking Pass',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing pass: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final booking = widget.booking;
    final parsedDate = DateTime.tryParse(booking.bookingDate) ?? DateTime.now();
    final dateLabel = DateFormat('dd MMM yyyy').format(parsedDate);

    final status = booking.status.toLowerCase();
    final bool isActive = status == 'booked' || status == 'active';
    final bool isCompleted = status == 'completed' || status == 'attended';

    Color statusColor;
    String statusText;
    if (isActive) {
      statusColor = AppColors.success;
      statusText = tr['active'] ?? 'ACTIVE';
    } else if (isCompleted) {
      statusColor = AppColors.textSecondary;
      statusText = tr['used'] ?? 'USED';
    } else {
      statusColor = AppColors.primary;
      statusText = booking.status.toUpperCase();
    }

    return GradientScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Back button and Title
              Row(
                children: [
                  Material(
                    color: AppColors.surfaceCardSolid,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surfaceCardBorder),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    tr['pass_details'] ?? 'Pass Details',
                    style: AppTextStyles.displayMedium.copyWith(fontSize: 20),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      statusText.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Instructions info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        tr['show_qr_instructions'] ??
                            'Scan this unique QR code at the gym entrance to check in.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Session Pass Card
              RepaintBoundary(
                key: _repaintKey,
                child: _SessionPassCard(
                  memberName: widget.memberName,
                  gymName: booking.gymName,
                  passId: booking.bookingId,
                  dateLabel: dateLabel,
                  time: booking.timeSlot,
                  tier: 'Platinum',
                  qrPayload: _qrPayload,
                  statusText: statusText,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Action Buttons Row (Download / Share)
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: _isDownloading
                          ? (tr['downloading'] ?? 'Downloading...')
                          : (tr['download'] ?? 'Download'),
                      leadingIcon: _isDownloading ? null : Icons.download_outlined,
                      onPressed: _isDownloading ? null : _downloadPass,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Material(
                      color: AppColors.surfaceCardSolid,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: _isSharing ? null : _sharePass,
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
                              _isSharing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(Icons.share_outlined,
                                      size: 18, color: AppColors.textPrimary),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                _isSharing
                                    ? (tr['sharing'] ?? 'Sharing...')
                                    : (tr['share'] ?? 'Share'),
                                style: AppTextStyles.buttonLabel,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Booking Details summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.surfaceCardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr['booking_summary'] ?? 'Booking Summary',
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DetailItem(label: 'Booking ID', value: '#${booking.bookingId}'),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailItem(label: 'Gym Name', value: booking.gymName),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailItem(label: 'Session Date', value: dateLabel),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailItem(label: 'Time Slot', value: booking.timeSlot),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailItem(label: 'Amount Paid', value: '₹${booking.price}'),
                    // if (booking.paymentId.isNotEmpty) ...[
                    //   const SizedBox(height: AppSpacing.sm),
                    //   _DetailItem(label: 'Payment ID', value: booking.paymentId),
                    // ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionPassCard extends StatelessWidget {
  const _SessionPassCard({
    required this.memberName,
    required this.gymName,
    required this.passId,
    required this.dateLabel,
    required this.time,
    required this.tier,
    required this.qrPayload,
    required this.statusText,
  });

  final String memberName;
  final String gymName;
  final String passId;
  final String dateLabel;
  final String time;
  final String tier;
  final String qrPayload;
  final String statusText;

  Color get _tierColor {
    switch (tier) {
      case 'Platinum':
        return AppColors.tierPlatinum;
      case 'Diamond':
        return AppColors.tierDiamond;
      case 'Gold':
        return AppColors.tierGold;
      default:
        return AppColors.tierSilver;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.isDark
              ? const [Color(0xFF282B3D), Color(0xFF151722)]
              : const [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.surfaceCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/logo/gymz-logo.png',
                width: 90,
                fit: BoxFit.contain,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _tierColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _tierColor),
                ),
                child: Text(
                  tier.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: _tierColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Member', style: AppTextStyles.bodySmall),
          Text(memberName, style: AppTextStyles.displayMedium),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _PassFieldItem(label: 'GYM', value: gymName),
              ),
              Expanded(
                child: _PassFieldItem(label: 'PASS ID', value: passId),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _PassFieldItem(label: 'DATE', value: dateLabel)),
              Expanded(child: _PassFieldItem(label: 'TIME', value: time)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                color: Colors.white,
                padding: const EdgeInsets.all(4),
                child: Image.network(
                  'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(qrPayload)}',
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.qr_code_2,
                    size: 72,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unique Session QR Code',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan at gym entrance to verify session.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '#$passId',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
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

class _PassFieldItem extends StatelessWidget {
  const _PassFieldItem({required this.label, required this.value});
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

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
