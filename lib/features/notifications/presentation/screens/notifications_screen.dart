import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Booking Confirmed!',
      description: 'Your session at Opus Fitness for tomorrow 6:00 AM has been successfully booked.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      icon: Icons.confirmation_number_outlined,
      iconBgColor: AppColors.success,
    ),
    NotificationItem(
      id: '2',
      title: 'Wallet Recharge Successful',
      description: '₹1,000 has been credited to your wallet via UPI.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      icon: Icons.add_card_outlined,
      iconBgColor: Colors.orange,
    ),
    NotificationItem(
      id: '3',
      title: 'Review submitted successfully',
      description: 'Thank you for rating Opus Fitness! Your feedback helps the community.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.star_outline,
      iconBgColor: AppColors.primary,
    ),
    NotificationItem(
      id: '4',
      title: 'New Gym Nearby!',
      description: 'Kenzo Fitness Club is now open for bookings in Ulwe, Navi Mumbai.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      icon: Icons.location_on_outlined,
      iconBgColor: Colors.blue,
    ),
  ];

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('d MMM').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AppBar Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28),
                        style: IconButton.styleFrom(backgroundColor: AppColors.surfaceCard),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text('Notifications', style: AppTextStyles.displayMedium),
                    ],
                  ),
                  if (_notifications.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _notifications.clear();
                        });
                      },
                      child: Text(
                        'Clear All',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Notifications List
              Expanded(
                child: _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'All caught up!',
                              style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'You have no new notifications.',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              setState(() {
                                _notifications.removeAt(index);
                              });
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: AppSpacing.xl),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(Icons.delete_outline, color: AppColors.danger),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.surfaceCardBorder),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: item.iconBgColor.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        item.icon,
                                        color: item.iconBgColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.lg),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: AppTextStyles.body.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                _formatTime(item.timestamp),
                                                style: AppTextStyles.caption.copyWith(
                                                  color: AppColors.textMuted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.description,
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData icon;
  final Color iconBgColor;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.iconBgColor,
  });
}
