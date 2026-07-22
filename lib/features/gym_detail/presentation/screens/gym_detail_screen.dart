import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../home/domain/gym_model.dart';
import '../../application/gym_detail_provider.dart';
import '../widgets/booking_widgets.dart';
import '../../data/repositories/booking_repository.dart';
import '../../../wallet/application/wallet_provider.dart';
import '../../../wallet/domain/wallet_model.dart';
import '../../../pass/application/booking_history_provider.dart';

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

  Color _getGenderColor(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Colors.blueAccent;
      case 'female':
        return Colors.pinkAccent;
      default:
        return Colors.purpleAccent;
    }
  }

  Future<void> _openDirections(GymModel gym) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${gym.latitude},${gym.longitude}',
    );
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(
          url,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open map: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Widget _buildDirectionButton(GymModel gym) {
    return Material(
      color: AppColors.primary.withOpacity(0.12),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _openDirections(gym),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                'Directions',
                style: AppTextStyles.buttonLabel.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startBookingFlow(GymModel gym, [DateTime? initialDate, TimeOfDay? initialTime]) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingBottomSheet(
        gym: gym,
        initialDate: initialDate,
        initialTime: initialTime,
      ),
    );

    if (result == null) return;

    final DateTime date = result['date'] as DateTime;
    final TimeOfDay time = result['time'] as TimeOfDay;

    if (!mounted) return;

    final confirmResult = await showDialog<BookingDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BookingConfirmationDialog(
        gym: gym,
        date: date,
        time: time,
      ),
    );

    if (confirmResult == BookingDialogResult.edit) {
      _startBookingFlow(gym, date, time);
      return;
    }

    if (confirmResult == BookingDialogResult.confirm && mounted) {
      // Show loading overlay
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      final timeSlotStr = '${hour.toString().padLeft(2, '0')}:$minute $period';

      try {
        final bookingRepository = ref.read(bookingRepositoryProvider);
        final response = await bookingRepository.generateBooking(
          gymId: gym.id,
          bookingDate: dateStr,
          timeSlot: timeSlotStr,
        );

        // Pop loading overlay
        if (mounted) {
          Navigator.pop(context);
        }

        // Prepend the new booking to the booking history provider
        ref.read(bookingHistoryProvider.notifier).addBooking(response.booking);

        // Update Wallet State instantly with the new balance and prepend the transaction
        final newTx = WalletTransaction(
          id: response.booking.id,
          title: '${response.booking.gymName} — Single Session',
          amount: response.booking.price,
          type: 'debit',
          createdAt: response.booking.createdAt ?? DateTime.now(),
        );

        final currentWallet = ref.read(walletProvider).value;
        if (currentWallet != null) {
          final updatedTxList = [newTx, ...currentWallet.transactions];
          ref.read(walletProvider.notifier).updateWallet(
            WalletData(
              walletBalance: response.walletBalance,
              transactions: updatedTxList,
            ),
          );
        } else {
          ref.read(walletProvider.notifier).updateWallet(
            WalletData(
              walletBalance: response.walletBalance,
              transactions: [newTx],
            ),
          );
        }

        // Show BookingSuccessDialog with returned booking ID
        if (mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => BookingSuccessDialog(
              gym: gym,
              date: date,
              time: time,
              bookingId: response.booking.bookingId,
            ),
          );
        }
      } catch (e) {
        // Pop loading overlay
        if (mounted) {
          Navigator.pop(context);
        }

        // Show Error Snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.danger,
              content: Text(
                e.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch detailed gym data provider.
    final gymDetailsAsync = ref.watch(gymDetailsProvider(widget.gym.id));

    // Use fully loaded gym details if available, fallback to basic widget.gym in background.
    final gym = gymDetailsAsync.maybeWhen(
      data: (details) => details,
      orElse: () => widget.gym,
    );

    // Build the combined list of media items.
    final List<Map<String, String>> mediaItems = [];
    if (gym.introVideo != null && gym.introVideo!.isNotEmpty) {
      mediaItems.add({'type': 'video', 'url': gym.introVideo!});
    }
    for (final img in gym.galleryPhotos) {
      mediaItems.add({'type': 'image', 'url': img});
    }
    if (mediaItems.isEmpty && gym.imageUrl.isNotEmpty) {
      mediaItems.add({'type': 'image', 'url': gym.imageUrl});
    }

    final List<String> imagesOnly = mediaItems
        .where((item) => item['type'] == 'image')
        .map((item) => item['url']!)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      extendBodyBehindAppBar: true,
      // IMPORTANT: extendBody is false (default). This means Scaffold
      // automatically insets `body` above `bottomNavigationBar`, so the
      // scroll area can never be covered by the price/Book Now bar again,
      // regardless of how tall that bar renders on a given device.
      body: Stack(
        children: [
          // Scrollable content containing both hero media and the details
          Positioned.fill(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  // Hero image / gallery carousel.
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 350,
                    child: mediaItems.isNotEmpty
                        ? Stack(
                            children: [
                              PageView.builder(
                                itemCount: mediaItems.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final item = mediaItems[index];
                                  if (item['type'] == 'video') {
                                    return _VideoPlayerSlide(url: item['url']!);
                                  } else {
                                    return GestureDetector(
                                      onTap: () {
                                        final imageIndex = imagesOnly.indexOf(item['url']!);
                                        if (imageIndex != -1) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => FullScreenImageViewer(
                                                images: imagesOnly,
                                                initialIndex: imageIndex,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Image.network(
                                        item['url']!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: AppColors.surfaceCardSolid,
                                          child: Center(
                                            child: Icon(Icons.fitness_center, size: 60, color: AppColors.textMuted),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              if (mediaItems.length > 1)
                                Positioned(
                                  bottom: 50,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      mediaItems.length,
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
                        : Container(
                            color: AppColors.surfaceCardSolid,
                            child: Center(
                              child: Icon(Icons.fitness_center, size: 60, color: AppColors.textMuted),
                            ),
                          ),
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
                  // Main content column. Note that the stack is sized by this non-positioned Column.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 310), // Matches the top offset of the scrollable content
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
                                Wrap(
                                  spacing: AppSpacing.xs,
                                  runSpacing: AppSpacing.xs,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                      ),
                                      child: Text(
                                        gym.tier,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                      ),
                                      child: Text(
                                        gym.category,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _getGenderColor(gym.gender).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                        border: Border.all(
                                          color: _getGenderColor(gym.gender),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        gym.gender,
                                        style: AppTextStyles.caption.copyWith(
                                          color: _getGenderColor(gym.gender),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
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
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${gym.reviewsCount})',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    gym.name,
                                    style: AppTextStyles.displayMedium.copyWith(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                _buildDirectionButton(gym),
                              ],
                            ),
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
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
                  Expanded(
                    child: PrimaryButton(
                      label: 'Book Now',
                      onPressed: widget.onBookNow ?? () => _startBookingFlow(gym),
                    ),
                  ),
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

class _VideoPlayerSlide extends StatefulWidget {
  const _VideoPlayerSlide({required this.url});
  final String url;

  @override
  State<_VideoPlayerSlide> createState() => _VideoPlayerSlideState();
}

class _VideoPlayerSlideState extends State<_VideoPlayerSlide> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true);
        _controller.setVolume(0.0); // Muted by default
        _controller.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: AppColors.surfaceCardSolid,
        child: const Center(
          child: Icon(Icons.error_outline, size: 40, color: Colors.white60),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            });
          },
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: AnimatedOpacity(
                opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          right: 16,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_controller.value.volume == 0.0) {
                  _controller.setVolume(1.0);
                } else {
                  _controller.setVolume(0.0);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _controller.value.volume == 0.0 ? Icons.volume_off : Icons.volume_up,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, size: 80, color: Colors.white54),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}