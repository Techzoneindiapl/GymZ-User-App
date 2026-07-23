import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymz_user/features/auth/application/auth_provider.dart';
import 'package:gymz_user/features/gym_detail/domain/booking_model.dart';
import 'package:gymz_user/features/home/data/repositories/gym_repository.dart';
import 'package:gymz_user/features/home/domain/gym_model.dart';
import 'package:gymz_user/features/pass/application/booking_history_provider.dart';
import 'package:gymz_user/features/pass/domain/review_model.dart';
import 'package:gymz_user/features/pass/presentation/screens/pass_detail_screen.dart';
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
import '../../../../core/localization/translations.dart';
import '../../../../core/localization/language_provider.dart';


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
      if (kDebugMode && boundary.debugNeedsPaint) {
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

  // Stores user-submitted ratings locally: key = gymId, value = {'rating': double, 'comment': String}
  final Map<String, Map<String, dynamic>> _submittedReviews = {};
  String _selectedBookingFilter = 'All';

  void _openRatingBottomSheet(GymModel gym) {
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
            gym: gym,
            onSubmit: (rating, comment) {
              setState(() {
                _submittedReviews[gym.id] = {
                  'rating': rating,
                  'comment': comment,
                };
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Thank you! Review for ${gym.name} submitted.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openEditRatingBottomSheet(ReviewModel review) {
    final gym = GymModel(
      id: review.gymId,
      name: review.gymName,
      category: '',
      tier: review.gymTier,
      distanceKm: 0.0,
      openingTime: '',
      closingTime: '',
      pricePerSession: 0,
      rating: review.rating,
      imageUrl: review.gymImageUrl,
      facilities: const [],
      usageInstructions: const [],
      address: '',
      description: '',
      latitude: 0.0,
      longitude: 0.0,
    );

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
            gym: gym,
            initialRating: review.rating,
            initialComment: review.comment,
            onSubmit: (rating, comment) {
              ref.refresh(myReviewsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Review for ${review.gymName} updated successfully.'),
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
    final tr = ref.watch(translationProvider);
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
        if (bookings.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.read(bookingHistoryProvider.notifier).refreshHistory(),
            child: const SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _EmptyPassState(),
            ),
          );
        }

        // Filter all bookings based on the selected chip
        final filteredListBookings = bookings.where((b) {
          final status = b.status.toLowerCase();
          final parsedDate = DateTime.tryParse(b.bookingDate) ?? DateTime.now();

          if (_selectedBookingFilter == 'Active') {
            return status == 'booked' || status == 'active';
          } else if (_selectedBookingFilter == 'Used') {
            return status == 'completed' || status == 'attended';
          } else if (_selectedBookingFilter == 'Upcoming') {
            final now = DateTime.now();
            final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
            return (status == 'booked' || status == 'active') && parsedDate.isAfter(todayEnd);
          }
          return true; // 'All'
        }).toList();

        return RefreshIndicator(
          onRefresh: () => ref.read(bookingHistoryProvider.notifier).refreshHistory(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr['my_bookings'] ?? 'My Bookings', style: AppTextStyles.sectionTitle),
                    Text(
                      '${filteredListBookings.length} ${filteredListBookings.length == 1 ? "session" : "sessions"}',
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Active', 'Used', 'Upcoming'].map((filter) {
                      final isSelected = _selectedBookingFilter == filter;
                      final String translatedFilter;
                      switch (filter) {
                        case 'All':
                          translatedFilter = tr['all'] ?? 'All';
                          break;
                        case 'Active':
                          translatedFilter = tr['active'] ?? 'Active';
                          break;
                        case 'Used':
                          translatedFilter = tr['used'] ?? 'Used';
                          break;
                        case 'Upcoming':
                          translatedFilter = tr['upcoming'] ?? 'Upcoming';
                          break;
                        default:
                          translatedFilter = filter;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(translatedFilter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedBookingFilter = filter;
                              });
                            }
                          },
                          selectedColor: AppColors.primary.withOpacity(0.15),
                          labelStyle: AppTextStyles.bodySmall.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: AppColors.surfaceCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.surfaceCardBorder,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                filteredListBookings.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                        child: Center(
                          child: Text(
                            tr['no_bookings_found'] ?? 'No bookings found.',
                            style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredListBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredListBookings[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _UpcomingPassItem(
                              booking: booking,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PassDetailScreen(
                                      booking: booking,
                                      memberName: userName,
                                      userId: userId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRateGymsTab(AsyncValue<List<GymModel>> pendingReviewsAsync) {
    return pendingReviewsAsync.when(
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
            'Failed to load pending reviews: $error',
            style: AppTextStyles.body.copyWith(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (gyms) {
        if (gyms.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(pendingReviewsProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No Pending Reviews',
                        style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'All your workout sessions are rated!',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(pendingReviewsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.xl),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: gyms.length,
            itemBuilder: (context, index) {
              final gym = gyms[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _CompletedGymItem(
                  gym: gym,
                  submittedReview: _submittedReviews[gym.id],
                  onRateTap: () => _openRatingBottomSheet(gym),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMyReviewsTab(AsyncValue<List<ReviewModel>> myReviewsAsync) {
    final tr = ref.watch(translationProvider);
    return myReviewsAsync.when(
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
            'Failed to load reviews: $error',
            style: AppTextStyles.body.copyWith(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myReviewsProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        tr['no_reviews_yet'] ?? 'No Reviews Yet',
                        style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        tr['share_experience_msg'] ?? 'Share your experience about gyms you have visited!',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(myReviewsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.xl),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _MyReviewItem(
                  review: review,
                  onEditTap: () => _openEditRatingBottomSheet(review),
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
    final tr = ref.watch(translationProvider);

    return DefaultTabController(
      length: 3,
      child: GradientScaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                child: Text(tr['my_passes'] ?? 'My Pass', style: AppTextStyles.displayMedium),
              ),
              const SizedBox(height: AppSpacing.md),
              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: AppTextStyles.body,
                tabs: [
                  Tab(text: tr['my_bookings'] ?? 'My Bookings'),
                  Tab(text: tr['rate_gyms'] ?? 'Rate Gyms'),
                  Tab(text: tr['my_reviews'] ?? 'My Reviews'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildUpcomingTab(bookingsState, userName, userId),
                    _buildRateGymsTab(ref.watch(pendingReviewsProvider)),
                    _buildMyReviewsTab(ref.watch(myReviewsProvider)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/logo/gymz-logo.png',
                width: 90,
                fit: BoxFit.contain,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Text(
                      'Recently Booked',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
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
  const _UpcomingPassItem({
    required this.booking,
    this.onTap,
  });

  final BookingModel booking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(booking.bookingDate) ?? DateTime.now();
    final dayStr = parsedDate.day.toString();
    final monthStr = DateFormat('MMM').format(parsedDate);

    final status = booking.status.toLowerCase();
    final bool isActive = status == 'booked' || status == 'active';
    final bool isCompleted = status == 'completed' || status == 'attended';

    Color badgeColor;
    String badgeText;

    if (isActive) {
      badgeColor = AppColors.success;
      badgeText = 'Active';
    } else if (isCompleted) {
      badgeColor = AppColors.textSecondary;
      badgeText = 'Used';
    } else {
      badgeColor = AppColors.primary;
      badgeText = booking.status.toUpperCase();
    }

    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
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
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: badgeColor.withOpacity(0.5)),
                ),
                child: Text(
                  badgeText,
                  style: AppTextStyles.caption.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPassState extends ConsumerWidget {
  const _EmptyPassState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
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
            tr['empty_passes'] ?? 'No Active Bookings',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            tr['empty_passes_sub'] ?? 'Explore fitness centers and book a session to get your check-in pass card here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 200,
            child: PrimaryButton(
              label: tr['explore_gyms'] ?? 'Explore Gyms',
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
}class _CompletedGymItem extends StatelessWidget {
  const _CompletedGymItem({
    required this.gym,
    required this.submittedReview,
    required this.onRateTap,
  });

  final GymModel gym;
  final Map<String, dynamic>? submittedReview;
  final VoidCallback onRateTap;

  @override
  Widget build(BuildContext context) {
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
            decoration: BoxDecoration(
              color: AppColors.iconCircleBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: gym.imageUrl.isNotEmpty
                  ? Image.network(gym.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center))
                  : const Icon(Icons.fitness_center),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gym.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                Text('${gym.tier} · ${gym.category}', style: AppTextStyles.bodySmall),
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
                    title: Text(gym.name, style: AppTextStyles.sectionTitle),
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

class _RatingBottomSheet extends ConsumerStatefulWidget {
  const _RatingBottomSheet({
    required this.gym,
    required this.onSubmit,
    this.initialRating,
    this.initialComment,
  });

  final GymModel gym;
  final Function(double rating, String comment) onSubmit;
  final double? initialRating;
  final String? initialComment;

  @override
  ConsumerState<_RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends ConsumerState<_RatingBottomSheet> {
  late double _rating;
  late final TextEditingController _commentController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 5.0;
    _commentController = TextEditingController(text: widget.initialComment);
  }

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
            widget.gym.name,
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
                    try {
                      await ref.read(gymRepositoryProvider).submitReview(
                        gymId: widget.gym.id,
                        rating: _rating,
                        comment: _commentController.text,
                      );
                      widget.onSubmit(_rating, _commentController.text);
                      ref.refresh(myReviewsProvider);
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      setState(() => _isLoading = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to submit review: $e'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _MyReviewItem extends StatelessWidget {
  const _MyReviewItem({
    required this.review,
    required this.onEditTap,
  });

  final ReviewModel review;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy').format(review.createdAt);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.iconCircleBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: review.gymImageUrl.isNotEmpty
                      ? Image.network(review.gymImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center))
                      : const Icon(Icons.fitness_center),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.gymName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                    if (review.gymTier.isNotEmpty)
                      Text(review.gymTier, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedDate,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: onEditTap,
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: Text(
                      'Edit',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                Icons.star,
                size: 16,
                color: i < review.rating.toInt() ? AppColors.starColor : AppColors.textSecondary.withOpacity(0.3),
              );
            }),
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              review.comment,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ],
          if (review.vendorReply != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.backgroundBottom.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.surfaceCardBorder.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Response from Gym Owner',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.vendorReply!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}