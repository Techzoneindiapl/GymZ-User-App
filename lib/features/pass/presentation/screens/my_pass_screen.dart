import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymz_user/features/auth/application/auth_provider.dart';
import 'package:gymz_user/features/gym_detail/domain/booking_model.dart';
import 'package:gymz_user/features/pass/application/booking_history_provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/user_shell_screen.dart';
import '../../../../core/widgets/shimmer_loading.dart';


class MyPassScreen extends ConsumerStatefulWidget {
  const MyPassScreen({super.key});

  @override
  ConsumerState<MyPassScreen> createState() => _MyPassScreenState();
}

class _MyPassScreenState extends ConsumerState<MyPassScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isDownloading = false;
  bool _isSharing = false;

  Future<Uint8List?> _captureCardPng() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Allow frame build to complete
      if (boundary.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing card screenshot: $e');
      return null;
    }
  }

  Future<void> _downloadPass(BookingModel booking) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final bytes = await _captureCardPng();
      if (bytes == null) {
        throw Exception('Failed to capture card snapshot');
      }

      // Check and request access
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

      // Write bytes to temporary file
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/GYMZ_Pass_${booking.bookingId}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Save to gallery
      await Gal.putImage(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pass #${booking.bookingId} downloaded to gallery!'),
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

  Future<void> _sharePass(BookingModel booking) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final bytes = await _captureCardPng();
      if (bytes == null) {
        throw Exception('Failed to capture card snapshot');
      }

      // Write bytes to temporary file
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/GYMZ_Pass_${booking.bookingId}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Format date for text details
      final parsedDate = DateTime.tryParse(booking.bookingDate) ?? DateTime.now();
      final formattedDate = DateFormat('dd MMM yyyy').format(parsedDate);

      // Share
      final shareText = 'Check out my GymZ session pass!\n\n'
          'Gym: ${booking.gymName}\n'
          'Date: $formattedDate\n'
          'Time Slot: ${booking.timeSlot}\n'
          'Booking ID: #${booking.bookingId}\n\n'
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

  // Stores user-submitted ratings locally: key = bookingId, value = {'rating': double, 'comment': String}
  final Map<String, Map<String, dynamic>> _submittedReviews = {};

  final List<BookingModel> _fallbackCompletedBookings = [
    BookingModel(
      id: 'c1',
      customerId: 'u1',
      gymId: 'g1',
      gymName: 'Iron Forge Studio',
      gymAddress: '12, Linking Road, Bandra West, Mumbai',
      galleryPhotos: const [],
      bookingDate: '2026-07-18T10:00:00Z',
      timeSlot: '08:00 AM - 09:00 AM',
      price: 249.0,
      status: 'completed',
      bookingId: 'BK-82910',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    BookingModel(
      id: 'c2',
      customerId: 'u1',
      gymId: 'g2',
      gymName: 'Lotus Yoga Sanctuary',
      gymAddress: '7, Hill Road, Bandra West, Mumbai',
      galleryPhotos: const [],
      bookingDate: '2026-07-20T10:00:00Z',
      timeSlot: '06:00 PM - 07:00 PM',
      price: 199.0,
      status: 'completed',
      bookingId: 'BK-10398',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  void _openRatingBottomSheet(BookingModel booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _RatingBottomSheet(
            booking: booking,
            onSubmit: (rating, comment) {
              setState(() {
                _submittedReviews[booking.bookingId] = {
                  'rating': rating,
                  'comment': comment,
                };
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Thank you! Review for ${booking.gymName} submitted.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTab(AsyncValue<List<BookingModel>> bookingsState, String userName, String userId) {
    return bookingsState.when(
      loading: () => const ShimmerLoading(
        child: _MyPassScreenSkeleton(),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Failed to load passes: $error',
            style: AppTextStyles.body.copyWith(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (bookings) {
        final bookedPasses = bookings.where((b) => b.status.toLowerCase() == 'booked').toList();

        if (bookedPasses.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.read(bookingHistoryProvider.notifier).refreshHistory(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _EmptyPassState(ref: ref),
            ),
          );
        }

        final latestBooking = bookedPasses.first;
        final upcomingBookings = bookedPasses.sublist(1);

        final parsedDate = DateTime.tryParse(latestBooking.bookingDate) ?? DateTime.now();
        final formattedDate = DateFormat('dd MMM yyyy').format(parsedDate);

        return RefreshIndicator(
          onRefresh: () => ref.read(bookingHistoryProvider.notifier).refreshHistory(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RepaintBoundary(
                  key: _repaintKey,
                  child: _ActivePassCard(
                    memberName: userName,
                    gymName: latestBooking.gymName,
                    passId: latestBooking.bookingId,
                    dateLabel: formattedDate,
                    time: latestBooking.timeSlot,
                    tier: 'Platinum',
                    userId: userId,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: _isDownloading ? 'Downloading...' : 'Download',
                        leadingIcon: _isDownloading ? null : Icons.download_outlined,
                        onPressed: _isDownloading ? null : () => _downloadPass(latestBooking),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Material(
                        color: AppColors.surfaceCardSolid,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          onTap: _isSharing ? null : () => _sharePass(latestBooking),
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
                                    : Icon(Icons.share_outlined, size: 18, color: AppColors.textPrimary),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  _isSharing ? 'Sharing...' : 'Share',
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
                if (upcomingBookings.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Text('Upcoming Passes', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: AppSpacing.md),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: upcomingBookings.length,
                    itemBuilder: (context, index) {
                      final upcoming = upcomingBookings[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _UpcomingPassItem(booking: upcoming),
                      );
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRateGymsTab(AsyncValue<List<BookingModel>> bookingsState) {
    return bookingsState.when(
      loading: () => const ShimmerLoading(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: _UpcomingPassSkeleton(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Failed to load history: $error',
            style: AppTextStyles.body.copyWith(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (bookings) {
        final completedBookings = bookings
            .where((b) => b.status.toLowerCase() == 'completed' || b.status.toLowerCase() == 'attended')
            .toList();

        final displayList = completedBookings.isNotEmpty ? completedBookings : _fallbackCompletedBookings;

        return RefreshIndicator(
          onRefresh: () => ref.read(bookingHistoryProvider.notifier).refreshHistory(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.xl),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final booking = displayList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _CompletedPassItem(
                  booking: booking,
                  submittedReview: _submittedReviews[booking.bookingId],
                  onRateTap: () => _openRatingBottomSheet(booking),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(bookingHistoryProvider);
    final user = ref.watch(authProvider).user;
    final userName = user?.name ?? 'Guest User';
    final userId = user?.memberId ?? 'GZ-GUEST';

    return DefaultTabController(
      length: 2,
      child: GradientScaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                child: Text('My Pass', style: AppTextStyles.displayMedium),
              ),
              const SizedBox(height: AppSpacing.md),
              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: AppTextStyles.body,
                tabs: const [
                  Tab(text: 'Upcoming Passes'),
                  Tab(text: 'Rate Gyms'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildUpcomingTab(bookingsState, userName, userId),
                    _buildRateGymsTab(bookingsState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePassCard extends StatelessWidget {
  const _ActivePassCard({
    required this.memberName,
    required this.gymName,
    required this.passId,
    required this.dateLabel,
    required this.time,
    required this.tier,
    required this.userId,
  });

  final String memberName;
  final String gymName;
  final String passId;
  final String dateLabel;
  final String time;
  final String tier;
  final String userId;

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
                  style: AppTextStyles.caption.copyWith(color: _tierColor, fontWeight: FontWeight.w700),
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
                child: _PassField(label: 'GYM', value: gymName),
              ),
              Expanded(
                child: _PassField(label: 'PASS ID', value: passId),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _PassField(label: 'DATE', value: dateLabel)),
              Expanded(child: _PassField(label: 'TIME', value: time)),
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
                child: Image.network(
                  'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${Uri.encodeComponent(userId)}',
                  width: 64,
                  height: 64,
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
                    size: 64,
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
                      'Scan this QR at the gym entrance to check in.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '#$passId',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
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
  const _UpcomingPassItem({required this.booking});
  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(booking.bookingDate) ?? DateTime.now();
    final dayStr = parsedDate.day.toString();
    final monthStr = DateFormat('MMM').format(parsedDate);
    final isToday = parsedDate.year == DateTime.now().year &&
        parsedDate.month == DateTime.now().month &&
        parsedDate.day == DateTime.now().day;

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
              dayStr,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.gymName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                Text('$dayStr $monthStr · ${booking.timeSlot} · Single Session', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.success),
              ),
              child: Text(
                'TODAY',
                style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyPassState extends StatelessWidget {
  const _EmptyPassState({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.surfaceCardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.airplane_ticket_outlined, size: 64, color: AppColors.primary.withOpacity(0.8)),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No Active Bookings',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Explore fitness centers and book a session to get your check-in pass card here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 200,
            child: PrimaryButton(
              label: 'Explore Gyms',
              onPressed: () {
                ref.read(shellTabIndexProvider.notifier).state = 1;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MyPassScreenSkeleton extends StatelessWidget {
  const _MyPassScreenSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          
          // Card skeleton container
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(color: AppColors.surfaceCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    ShimmerBlock(width: 80, height: 24),
                    ShimmerBlock(width: 80, height: 24, borderRadius: 6),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const ShimmerBlock(width: 60, height: 12),
                const SizedBox(height: AppSpacing.sm),
                const ShimmerBlock(width: 180, height: 28),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: const [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBlock(width: 40, height: 10),
                          SizedBox(height: 4),
                          ShimmerBlock(width: 100, height: 16),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBlock(width: 50, height: 10),
                          SizedBox(height: 4),
                          ShimmerBlock(width: 80, height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: const [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBlock(width: 40, height: 10),
                          SizedBox(height: 4),
                          ShimmerBlock(width: 90, height: 16),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBlock(width: 40, height: 10),
                          SizedBox(height: 4),
                          ShimmerBlock(width: 70, height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(height: 1, color: AppColors.divider),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    const ShimmerBlock(width: 72, height: 72),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerBlock(width: double.infinity, height: 12),
                          SizedBox(height: 6),
                          ShimmerBlock(width: 80, height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Download / Share buttons
          Row(
            children: const [
              Expanded(
                child: ShimmerBlock(width: double.infinity, height: 56, borderRadius: AppRadius.pill),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: ShimmerBlock(width: double.infinity, height: 56, borderRadius: AppRadius.pill),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Upcoming Passes', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          // Upcoming list items
          _UpcomingPassSkeleton(),
          const SizedBox(height: AppSpacing.md),
          _UpcomingPassSkeleton(),
        ],
      ),
    );
  }
}

class _UpcomingPassSkeleton extends StatelessWidget {
  const _UpcomingPassSkeleton();

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
          const ShimmerBlock(width: 44, height: 44, borderRadius: AppRadius.md),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBlock(width: 140, height: 14),
                SizedBox(height: 6),
                ShimmerBlock(width: 180, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedPassItem extends StatelessWidget {
  const _CompletedPassItem({
    required this.booking,
    required this.submittedReview,
    required this.onRateTap,
  });

  final BookingModel booking;
  final Map<String, dynamic>? submittedReview;
  final VoidCallback onRateTap;

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(booking.bookingDate) ?? DateTime.now();
    final dayStr = parsedDate.day.toString();
    final monthStr = DateFormat('MMM').format(parsedDate);

    final isRated = submittedReview != null;
    final rating = isRated ? submittedReview!['rating'] as double : 0.0;

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
              dayStr,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.gymName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                Text('$dayStr $monthStr · ${booking.timeSlot} · Completed', style: AppTextStyles.bodySmall),
                if (isRated) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            Icons.star,
                            size: 14,
                            color: i < rating.toInt() ? AppColors.starColor : AppColors.textSecondary.withOpacity(0.3),
                          );
                        }),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Rated',
                        style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (!isRated)
            ElevatedButton(
              onPressed: onRateTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Rate',
                style: AppTextStyles.buttonLabel.copyWith(fontSize: 12),
              ),
            )
          else
            IconButton(
              icon:  Icon(Icons.check_circle, color: AppColors.success, size: 24),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.surfaceCardSolid,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                    title: Text(booking.gymName, style: AppTextStyles.sectionTitle),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Rating: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  Icons.star,
                                  size: 16,
                                  color: i < rating.toInt() ? AppColors.starColor : AppColors.textSecondary.withOpacity(0.3),
                                );
                              }),
                            ),
                          ],
                        ),
                        if (submittedReview!['comment'] != null && (submittedReview!['comment'] as String).isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          const Text('Review:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(submittedReview!['comment'] as String),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RatingBottomSheet extends StatefulWidget {
  const _RatingBottomSheet({
    required this.booking,
    required this.onSubmit,
  });

  final BookingModel booking;
  final Function(double rating, String comment) onSubmit;

  @override
  State<_RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<_RatingBottomSheet> {
  double _rating = 5;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
          Text(
            'Rate your session',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.booking.gymName,
            style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
              children: [
                Text(
                  'How was your workout experience?',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    final isSelected = starIndex <= _rating;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = starIndex.toDouble();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                        child: Icon(
                          Icons.star,
                          size: 40,
                          color: isSelected ? AppColors.starColor : AppColors.textSecondary.withOpacity(0.3),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'ADD A COMMENT (OPTIONAL)',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your feedback about cleanliness, equipment, or staff...',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: AppColors.surfaceCardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: AppColors.surfaceCardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: _isLoading ? 'Submitting...' : 'Submit Review',
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() => _isLoading = true);
                    await Future<void>.delayed(const Duration(seconds: 1));
                    widget.onSubmit(_rating, _commentController.text);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
          ),
        ],
      ),
    );
  }
}