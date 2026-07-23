import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/localization/translations.dart';
import '../../application/onboarding_notifier.dart';
import '../../domain/onboarding_slide.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../../core/router/route_names.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.onSkip, this.onGetStarted});

  final VoidCallback? onSkip;
  final VoidCallback? onGetStarted;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    final notifier = ref.read(onboardingProvider.notifier);
    final current = ref.read(onboardingProvider).currentIndex;
    if (current < kOnboardingSlides.length - 1) {
      notifier.nextSlide(kOnboardingSlides.length);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuint,
      );
    } else {
      widget.onGetStarted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) async {
      if (next.status == AuthStatus.authenticated && mounted) {
        final permission = await Geolocator.checkPermission();
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        final hasPermission = permission == LocationPermission.whileInUse || permission == LocationPermission.always;
        if (mounted) {
          if (!hasPermission || !serviceEnabled) {
            context.goNamed(RouteNames.locationPermission);
          } else {
            context.goNamed(RouteNames.home);
          }
        }
      }
    });

    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          final permission = await Geolocator.checkPermission();
          final serviceEnabled = await Geolocator.isLocationServiceEnabled();
          final hasPermission = permission == LocationPermission.whileInUse || permission == LocationPermission.always;
          if (mounted) {
            if (!hasPermission || !serviceEnabled) {
              context.goNamed(RouteNames.locationPermission);
            } else {
              context.goNamed(RouteNames.home);
            }
          }
        }
      });
    }

    final state = ref.watch(onboardingProvider);
    final currentIndex = state.currentIndex;
    final isLast = currentIndex == kOnboardingSlides.length - 1;
    final tr = ref.watch(translationProvider);

    return GradientScaffold(
      body: Stack(
        children: [
          // Background Glow Blobs for premium atmosphere
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.isDark ? const Color(0x1F00BCD4) : const Color(0x0C00BCD4),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.isDark ? const Color(0x11C6FF00) : const Color(0x08C6FF00),
              ),
            ),
          ),
          // Backdrop blur over glowing elements
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: const SizedBox.shrink(),
            ),
          ),

          // Content PageView
          PageView.builder(
            controller: _pageController,
            itemCount: kOnboardingSlides.length,
            onPageChanged: ref.read(onboardingProvider.notifier).goToSlide,
            itemBuilder: (context, index) {
              return _OnboardingPage(slide: kOnboardingSlides[index], index: index);
            },
          ),

          // Skip Button
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.xl,
            child: TextButton(
              onPressed: widget.onSkip,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                backgroundColor: AppColors.surfaceCard.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  side: BorderSide(color: AppColors.surfaceCardBorder.withOpacity(0.5)),
                ),
              ),
              child: Text(tr['skip'] ?? 'Skip', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),

          // Bottom Bar containing indicators and primary buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomBar(
              currentIndex: currentIndex,
              totalSlides: kOnboardingSlides.length,
              isLast: isLast,
              onNext: _onNext,
              onGetStarted: widget.onGetStarted,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends ConsumerWidget {
  const _OnboardingPage({required this.slide, required this.index});

  final OnboardingSlide slide;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          
          // Glassmorphic Illustration Card with entry scale animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.7, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(44),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(42),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.02),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      slide.icon, 
                      size: 82, 
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.xxxl + AppSpacing.md),
          
          // Title & Subtitle with dynamic fade-in/slide-up animations
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutQuad,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1.0 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                Text(
                  index == 0 ? (tr['onboarding_title_1'] ?? slide.title) : (tr['onboarding_title_2'] ?? slide.title),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayLarge.copyWith(height: 1.2),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  index == 0 ? (tr['onboarding_sub_1'] ?? slide.subtitle) : (tr['onboarding_sub_2'] ?? slide.subtitle),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.totalSlides,
    required this.isLast,
    required this.onNext,
    required this.onGetStarted,
  });

  final int currentIndex;
  final int totalSlides;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback? onGetStarted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSlides, (index) {
              final isActive = index == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutExpo,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.surfaceCardBorder.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.xxl),
          
          // Unified Action Button
          PrimaryButton(
            label: isLast ? (tr['get_started'] ?? 'Get Started') : (tr['next'] ?? 'Next'), 
            onPressed: isLast ? onGetStarted : onNext,
          ),
        ],
      ),
    );
  }
}