import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme_provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';

class FitnessPassData {
  const FitnessPassData({
    required this.fullName,
    required this.gender,
    required this.passId,
    required this.joinedAt,
    this.selfieFilePath,
  });

  final String fullName;
  final String gender;
  final String passId;
  final DateTime joinedAt;
  final String? selfieFilePath;

  String get joinedLabel => 'Joined ${DateFormat('MMM yyyy').format(joinedAt)}';
}

class FitnessPassScreen extends ConsumerWidget {
  const FitnessPassScreen({super.key, required this.pass, this.onContinue});

  final FitnessPassData pass;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    return GradientScaffold(
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'YOUR DIGITAL PASS',
            style: AppTextStyles.label.copyWith(
              color: AppColors.primary,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  _PassCard(pass: pass), // Animated Digital Visiting Card
                  const SizedBox(height: AppSpacing.xl),
                  _QrCard(pass: pass), // Stand-alone QR Code Section
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Show this card at any GYMZ partner facility to check in instantly.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: PrimaryButton(
              label: 'Continue',
              onPressed: onContinue,
              color: const Color(0xFFFF6D00),
            ),
          ),
        ],
      ),
    );
  }
}

class _PassCard extends StatefulWidget {
  const _PassCard({required this.pass});
  final FitnessPassData pass;

  @override
  State<_PassCard> createState() => _PassCardState();
}

class _PassCardState extends State<_PassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final beginX = 5.0 - (value * 4.0);
        final endX = -2.0 - (value * 4.0);
        final beginAlignment = Alignment(beginX, 0.0);
        final endAlignment = Alignment(endX, 0.0);

        // Rotating animation for the avatar border
        final avatarAngle = (_controller.value * 3) * 2 * math.pi;
        final avatarBegin = Alignment(
          math.cos(avatarAngle),
          math.sin(avatarAngle),
        );
        final avatarEnd = Alignment(
          math.cos(avatarAngle + math.pi),
          math.sin(avatarAngle + math.pi),
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: beginAlignment,
              end: endAlignment,
              colors: const [
                Color(0xFF328570), // Glowing Greenish-teal
                Color(0xFF1D455F), // Deep blue-gray
                Color(0xFF5C2D6A), // Vibrant Purple
                Color.fromARGB(255, 84, 92, 79), // Dark Slate
                Color.fromARGB(
                  255,
                  119,
                  50,
                  133,
                ), // Loop back to start for seamlessness
                Color(0xFF1D455F),
                Color(0xFF5C2D6A),
                Color.fromARGB(255, 92, 79, 90),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.surfaceCardBorder.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & Member Tag Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/logo/gymz-logo.png',
                      width: 122,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.8),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'MEMBER',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // User Details Row
              Row(
                children: [
                  // Glowing Dynamic Swirling Avatar Border
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: const [
                          Color(0xFFA855F7), // Purple
                          Color(0xFF06B6D4), // Cyan
                          Color(0xFF22C55E), // Green
                        ],
                        begin: avatarBegin,
                        end: avatarEnd,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        color: AppColors.surfaceCard,
                        image:
                            widget.pass.selfieFilePath != null &&
                                widget.pass.selfieFilePath!.isNotEmpty
                            ? DecorationImage(
                                image:
                                    widget.pass.selfieFilePath!.startsWith(
                                      'http',
                                    )
                                    ? NetworkImage(widget.pass.selfieFilePath!)
                                          as ImageProvider
                                    : FileImage(
                                            File(widget.pass.selfieFilePath!),
                                          )
                                          as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : const DecorationImage(
                                image: NetworkImage(
                                  'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=300&auto=format&fit=crop',
                                ),
                                fit: BoxFit.cover,
                              ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 44,
                        color: AppColors.textSecondary.withOpacity(0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pass.fullName,
                          style: AppTextStyles.displayMedium.copyWith(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.pass.gender} · ${widget.pass.joinedLabel}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.pass.passId,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.5,
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
      },
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.pass});
  final FitnessPassData pass;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: QR Image & ID
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=110x110&data=${Uri.encodeComponent(pass.passId)}',
                width: 110,
                height: 110,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 110,
                    height: 110,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    width: 110,
                    height: 110,
                    child: CustomPaint(painter: _StylizedQrPainter()),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                pass.passId,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          // Right side: Bullet List Instructions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'HOW TO CHECK-IN',
                  style: TextStyle(
                    color: Color(0xFF328570), // Theme Green/Teal accent color
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint(
                  'Present this QR code at the gym check-in desk.',
                ),
                const SizedBox(height: 6),
                _buildBulletPoint(
                  'Valid at all authorized GYMZ partner facilities.',
                ),
                const SizedBox(height: 6),
                _buildBulletPoint(
                  'Non-transferable digital pass. Keep it secure.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5.0, right: 6.0),
          child: Icon(Icons.circle, size: 5, color: Colors.black54),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _StylizedQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final finderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    // Draw finder patterns
    _drawFinderPattern(canvas, const Offset(10, 10), 38, finderPaint, dotPaint);
    _drawFinderPattern(
      canvas,
      Offset(size.width - 48, 10),
      38,
      finderPaint,
      dotPaint,
    );
    _drawFinderPattern(
      canvas,
      Offset(10, size.height - 48),
      38,
      finderPaint,
      dotPaint,
    );

    // Stylized internal connectors
    canvas.drawCircle(Offset(size.width / 2, 20), 4.0, dotPaint);
    canvas.drawCircle(Offset(size.width / 2, 58), 4.0, dotPaint);
    canvas.drawCircle(Offset(size.width / 2 - 38, 58), 4.0, dotPaint);
    canvas.drawCircle(Offset(size.width / 2 + 22, 58), 4.0, dotPaint);
    canvas.drawCircle(Offset(size.width / 2 + 48, 58), 4.0, dotPaint);

    final path = Path()
      ..moveTo(size.width / 2, 20)
      ..quadraticBezierTo(size.width / 2, 58, size.width / 2 - 20, 58);
    canvas.drawPath(path, linePaint);

    final path2 = Path()
      ..moveTo(size.width / 2 - 20, size.height - 58)
      ..lineTo(size.width / 2 + 10, size.height - 58);
    canvas.drawPath(path2, linePaint);
    canvas.drawCircle(
      Offset(size.width / 2 + 30, size.height - 58),
      4.0,
      dotPaint,
    );

    final path3 = Path()
      ..moveTo(size.width - 48, size.height - 58)
      ..lineTo(size.width - 18, size.height - 58)
      ..lineTo(size.width - 18, size.height - 28);
    canvas.drawPath(path3, linePaint);
    canvas.drawCircle(Offset(size.width - 18, size.height - 18), 4.0, dotPaint);
  }

  void _drawFinderPattern(
    Canvas canvas,
    Offset topLeft,
    double size,
    Paint outlinePaint,
    Paint innerPaint,
  ) {
    final rect = Rect.fromLTWH(topLeft.dx, topLeft.dy, size, size);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, outlinePaint);

    final innerRect = Rect.fromLTWH(
      topLeft.dx + 10,
      topLeft.dy + 10,
      size - 20,
      size - 20,
    );
    final innerRrect = RRect.fromRectAndRadius(
      innerRect,
      const Radius.circular(6),
    );
    canvas.drawRRect(innerRrect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
