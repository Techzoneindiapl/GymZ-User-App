import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/outline_button.dart';
import '../../../home/domain/gym_model.dart';

enum BookingDialogResult { confirm, edit }

/// A premium bottom sheet that allows users to select a booking date and time.
class BookingBottomSheet extends StatefulWidget {
  const BookingBottomSheet({
    super.key,
    required this.gym,
    this.initialDate,
    this.initialTime,
  });

  final GymModel gym;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isCustomDate = false;

  final List<String> _quickTimes = [
    '07:00 AM',
    '09:00 AM',
    '12:00 PM',
    '03:00 PM',
    '05:00 PM',
    '07:00 PM',
    '09:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (widget.initialDate != null) {
      _selectedDate = DateTime(
        widget.initialDate!.year,
        widget.initialDate!.month,
        widget.initialDate!.day,
      );
      if (!_isSameDay(_selectedDate, today) && !_isSameDay(_selectedDate, tomorrow)) {
        _isCustomDate = true;
      }
    } else {
      _selectedDate = today;
    }

    _selectedTime = widget.initialTime ?? const TimeOfDay(hour: 9, minute: 0);
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final format = DateFormat("hh:mm a");
      final dateTime = format.parse(timeStr.trim());
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  bool _isQuickTime(TimeOfDay time) {
    for (final qt in _quickTimes) {
      final parsed = _parseTimeString(qt);
      if (parsed.hour == time.hour && parsed.minute == time.minute) return true;
    }
    return false;
  }

  void _selectCustomDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnAccent,
              surface: AppColors.surfaceCardSolid,
              onSurface: AppColors.textPrimary,
            ),
            dialogBackgroundColor: AppColors.backgroundBottom,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        final tomorrow = today.add(const Duration(days: 1));
        _isCustomDate = !_isSameDay(picked, today) && !_isSameDay(picked, tomorrow);
      });
    }
  }

  void _selectCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnAccent,
              surface: AppColors.surfaceCardSolid,
              onSurface: AppColors.textPrimary,
            ),
            dialogBackgroundColor: AppColors.backgroundBottom,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final isTodaySelected = _isSameDay(_selectedDate, today) && !_isCustomDate;
    final isTomorrowSelected = _isSameDay(_selectedDate, tomorrow) && !_isCustomDate;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final price = _selectedTime != null
        ? widget.gym.getPriceForTime(hour: _selectedTime!.hour, minute: _selectedTime!.minute)
        : widget.gym.currentPrice;

    final slotLabel = _selectedTime != null
        ? widget.gym.getSlotLabelForTime(hour: _selectedTime!.hour, minute: _selectedTime!.minute)
        : widget.gym.activeSlotLabel;

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.backgroundBottom,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        border: Border(top: BorderSide(color: AppColors.surfaceCardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle indicator
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
          // Title
          Text('Book a Session', style: AppTextStyles.displayMedium),
          const SizedBox(height: 4),
          Text(widget.gym.name, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.xl),

          // 1. Date Selection
          Text('SELECT DATE', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildDateChip(
                title: 'Today',
                subtitle: DateFormat('d MMM').format(today),
                isSelected: isTodaySelected,
                onTap: () {
                  setState(() {
                    _selectedDate = today;
                    _isCustomDate = false;
                  });
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildDateChip(
                title: 'Tomorrow',
                subtitle: DateFormat('d MMM').format(tomorrow),
                isSelected: isTomorrowSelected,
                onTap: () {
                  setState(() {
                    _selectedDate = tomorrow;
                    _isCustomDate = false;
                  });
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildDateChip(
                title: _isCustomDate ? DateFormat('EEE, d MMM').format(_selectedDate) : 'Other Date',
                subtitle: 'Calendar',
                isSelected: _isCustomDate,
                icon: Icons.calendar_month_outlined,
                onTap: _selectCustomDate,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // 2. Time Selection
          Text('SELECT TIME', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ..._quickTimes.map((timeStr) {
                final quickTime = _parseTimeString(timeStr);
                final isSelected = _selectedTime != null &&
                    _selectedTime!.hour == quickTime.hour &&
                    _selectedTime!.minute == quickTime.minute;
                return _buildTimeChip(
                  label: timeStr,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedTime = quickTime;
                    });
                  },
                );
              }),
              _buildTimeChip(
                label: (_selectedTime != null && !_isQuickTime(_selectedTime!))
                    ? _selectedTime!.format(context)
                    : 'Custom Time',
                isSelected: _selectedTime != null && !_isQuickTime(_selectedTime!),
                icon: Icons.access_time_outlined,
                onTap: _selectCustomTime,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Pricing Summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.surfaceCardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Total Payable', style: AppTextStyles.caption),
                        if (slotLabel.isNotEmpty) ...[
                          Text(' · ', style: AppTextStyles.caption),
                          Text(
                            slotLabel,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹$price',
                      style: AppTextStyles.price.copyWith(fontSize: 20, color: AppColors.primary),
                    ),
                  ],
                ),
                Text(
                  '1 Session Pass',
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Proceed button
          PrimaryButton(
            label: 'Proceed to Confirm',
            isEnabled: _selectedTime != null,
            onPressed: () {
              Navigator.pop(context, {
                'date': _selectedDate,
                'time': _selectedTime,
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.surfaceCardBorder,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isSelected ? AppColors.textOnAccent : AppColors.textPrimary,
                  size: 20,
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.textOnAccent : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.textOnAccent.withOpacity(0.8) : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceCardBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? AppColors.textOnAccent : AppColors.textPrimary,
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.textOnAccent : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A structured dialog asking the user to confirm the booking details.
class BookingConfirmationDialog extends StatelessWidget {
  const BookingConfirmationDialog({
    super.key,
    required this.gym,
    required this.date,
    required this.time,
  });

  final GymModel gym;
  final DateTime date;
  final TimeOfDay time;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    String dateLabel = DateFormat('EEEE, d MMMM yyyy').format(date);
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      dateLabel = 'Today, ${DateFormat('d MMMM yyyy').format(date)}';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      dateLabel = 'Tomorrow, ${DateFormat('d MMMM yyyy').format(date)}';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.surfaceCardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Circular Badge Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.iconCircleBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long_outlined, size: 28, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Title & Subtitle
            Text(
              'Confirm Booking',
              style: AppTextStyles.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Double check your session details before making the confirmation.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Structured Details Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceCardSolid,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.surfaceCardBorder),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.fitness_center_rounded,
                    label: 'Gym / Studio',
                    value: gym.name,
                    subValue: '${gym.tier} · ${gym.category}',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: dateLabel,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDetailRow(
                    icon: Icons.access_time_filled_rounded,
                    label: 'Visit Time',
                    value: time.format(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDetailRow(
                    icon: Icons.payments_rounded,
                    label: 'Amount Payable',
                    value: '₹${gym.getPriceForTime(hour: time.hour, minute: time.minute)}',
                    valueColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Buttons: Confirm & Edit
            PrimaryButton(
              label: 'Confirm',
              onPressed: () {
                Navigator.pop(context, BookingDialogResult.confirm);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            OutlineButton(
              label: 'Edit',
              
              onPressed: () {
                Navigator.pop(context, BookingDialogResult.edit);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
              if (subValue != null) ...[
                const SizedBox(height: 2),
                Text(
                  subValue,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A beautiful ticket-styled success popup that displays after booking confirmation.
class BookingSuccessDialog extends StatelessWidget {
  const BookingSuccessDialog({
    super.key,
    required this.gym,
    required this.date,
    required this.time,
    required this.bookingId,
  });

  final GymModel gym;
  final DateTime date;
  final TimeOfDay time;
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEE, d MMMM yyyy').format(date);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: AppColors.surfaceCardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Checkmark Badge
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Title
            Text(
              'Booking Confirmed!',
              style: AppTextStyles.displayMedium.copyWith(color: AppColors.success),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Your digital pass is ready for check-in.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Ticket / Pass Layout
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCardSolid,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.surfaceCardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pass ID section
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Text(
                          'PASS REFERENCE ID',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bookingId,
                          style: AppTextStyles.displayMedium.copyWith(
                            fontSize: 20,
                            color: AppColors.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dashed divider visual representation
                  Row(
                    children: List.generate(
                      15,
                      (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 1.5,
                          color: AppColors.surfaceCardBorder,
                        ),
                      ),
                    ),
                  ),

                  // Ticket Details
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _buildTicketInfo(label: 'Center', value: gym.name),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(child: _buildTicketInfo(label: 'Date', value: formattedDate)),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _buildTicketInfo(label: 'Time', value: time.format(context))),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Barcode placeholder graphic for premium look
                        const SizedBox(height: AppSpacing.sm),
                        _buildBarcodeGraphics(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Help info
            Text(
              'Present this pass at the gym counter to start your session.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Done Button
            PrimaryButton(
              label: 'Done',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketInfo({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 9,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBarcodeGraphics() {
    final random = Random();
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          32,
          (index) => Container(
            width: (index % 3 == 0) ? 3.0 : ((index % 5 == 0) ? 1.0 : 2.0),
            color: AppColors.textPrimary.withOpacity(random.nextDouble() * 0.4 + 0.3),
          ),
        ),
      ),
    );
  }
}
