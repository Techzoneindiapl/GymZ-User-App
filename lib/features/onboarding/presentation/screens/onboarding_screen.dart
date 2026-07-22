import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../application/onboarding_notifier.dart';
import '../../domain/onboarding_slide.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

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
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
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

    return GradientScaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: kOnboardingSlides.length,
            onPageChanged: ref.read(onboardingProvider.notifier).goToSlide,
            itemBuilder: (context, index) {
              return _OnboardingPage(slide: kOnboardingSlides[index]);
            },
          ),
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.xl,
            child: TextButton(
              onPressed: widget.onSkip,
              child: Text('Skip', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            ),
          ),
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final iconColor = slide.iconBgColor == Colors.white
        ? Colors.black
        : AppColors.textOnPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          // Glowing icon tile.
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: slide.iconBgColor,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: slide.iconBgColor.withOpacity(0.5),
                  blurRadius: 48,
                  spreadRadius: 8,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(slide.icon, size: 80, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.xxxl + AppSpacing.lg),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot indicators.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSlides, (index) {
              final isActive = index == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.pillBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (isLast)
            PrimaryButton(label: 'Get Started', onPressed: onGetStarted)
          else
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: AppColors.surfaceCardSolid,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: onNext,
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.surfaceCardBorder),
                        ),
                        child: Text('Next', style: AppTextStyles.buttonLabel),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onNext,
                    child:  Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(Icons.arrow_forward, color: AppColors.textOnPrimary),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}