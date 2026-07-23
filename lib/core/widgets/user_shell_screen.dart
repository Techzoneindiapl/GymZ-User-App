import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/explore/presentation/screens/explore_screen.dart';
import '../../features/pass/presentation/screens/my_pass_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/auth/presentation/screens/fitness_pass_screen.dart';
import '../../features/auth/application/auth_provider.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_provider.dart';
import '../router/route_names.dart';
import 'gradient_scaffold.dart';

final shellTabIndexProvider = StateProvider<int>((ref) => 0);

class UserShellScreen extends ConsumerStatefulWidget {
  const UserShellScreen({super.key});

  @override
  ConsumerState<UserShellScreen> createState() => _UserShellScreenState();
}

class _UserShellScreenState extends ConsumerState<UserShellScreen> {
  late final PageController _pageController;

  static const _tabs = [
    _NavTab(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavTab(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explore'),
    _NavTab(icon: Icons.wallet_outlined, activeIcon: Icons.wallet, label: 'Wallet', isCentral: true),
    _NavTab(icon: Icons.confirmation_number_outlined, activeIcon: Icons.confirmation_number, label: 'Passes'),
    _NavTab(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: ref.read(shellTabIndexProvider));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    ref.read(shellTabIndexProvider.notifier).state = index;
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  void _onPageChanged(int index) {
    ref.read(shellTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(shellTabIndexProvider);
    // Watch themeModeProvider so the bottom bar refreshes instantly on theme change
    ref.watch(themeModeProvider);

    // Listen to changes in the shellTabIndexProvider (for programmatic switching from anywhere in the app)
    ref.listen<int>(shellTabIndexProvider, (previous, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog(context);
        if (shouldExit && context.mounted) {
          await SystemNavigator.pop();
        }
      },
      child: GradientScaffold(
        bottomBar: _UserBottomNavBar(currentIndex: currentIndex, tabs: _tabs, onTap: _onTabTapped),
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const NeverScrollableScrollPhysics(),
          children: [
          HomeScreen(
            ownerFirstName: ref.watch(authProvider).user?.name ?? 'Guest User',
            avatarPath: ref.watch(authProvider).user?.selfieUrl,
            onGymTap: (gym) {
              context.pushNamed(
                RouteNames.gymDetail,
                pathParameters: {'id': gym.id},
                extra: gym,
              );
            },
            onPassTap: () => _onTabTapped(2),
            onNotificationTap: () {
              context.pushNamed(RouteNames.notifications);
            },
          ),
          ExploreScreen(
            onGymTap: (gym) {
              context.pushNamed(
                RouteNames.gymDetail,
                pathParameters: {'id': gym.id},
                extra: gym,
              );
            },
          ),
          const WalletScreen(),
          const MyPassScreen(),
          ProfileScreen(
            name: ref.watch(authProvider).user?.name ?? 'Guest User',
            email: ref.watch(authProvider).user?.email ?? 'guest@gymz.com',
            memberId: ref.watch(authProvider).user?.memberId ?? 'GZ-GUEST',
            avatarPath: ref.watch(authProvider).user?.selfieUrl,
            sessionCount: ref.watch(authProvider).user?.sessionsCount ?? 0,
            gymCount: ref.watch(authProvider).user?.gymsCount ?? 0,
            memberSinceDays: ref.watch(authProvider).user?.memberSinceDays ?? 0,
            onCardTap: () {
              final user = ref.read(authProvider).user;
              context.pushNamed(
                RouteNames.fitnessPass,
                queryParameters: {'fromProfile': 'true'},
                extra: FitnessPassData(
                  fullName: user?.name ?? 'Guest User',
                  gender: user?.gender ?? 'Male',
                  passId: user?.memberId ?? 'GZ-GUEST',
                  joinedAt: DateTime.now().subtract(Duration(days: user?.memberSinceDays ?? 0)),
                  selfieFilePath: user?.selfieUrl,
                ),
              );
            },
            onFitnessCard: () {
              final user = ref.read(authProvider).user;
              context.pushNamed(
                RouteNames.fitnessPass,
                queryParameters: {'fromProfile': 'true'},
                extra: FitnessPassData(
                  fullName: user?.name ?? 'Guest User',
                  gender: user?.gender ?? 'Male',
                  passId: user?.memberId ?? 'GZ-GUEST',
                  joinedAt: DateTime.now().subtract(Duration(days: user?.memberSinceDays ?? 0)),
                  selfieFilePath: user?.selfieUrl,
                ),
              );
            },
            onBookingHistory: () => _onTabTapped(3),
            onWallet: () => _onTabTapped(2),
            onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.goNamed(RouteNames.auth);
              }
            },
          ),
        ],
      ),
    ),
  );
}

  Future<bool> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: BorderSide(color: AppColors.surfaceCardBorder),
          ),
          title: Row(
            children: [
              Icon(Icons.exit_to_app_rounded, color: AppColors.danger, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Exit App',
                style: AppTextStyles.displayMedium.copyWith(fontSize: 20, color: AppColors.textPrimary),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to exit GymZ?',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Exit',
                style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _UserBottomNavBar extends StatelessWidget {
  const _UserBottomNavBar({required this.currentIndex, required this.tabs, required this.onTap});

  final int currentIndex;
  final List<_NavTab> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration:  BoxDecoration(
        color: AppColors.bottomBarBg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final isSelected = currentIndex == index;

            if (tab.isCentral) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  child: Transform.translate(
                    offset: const Offset(0, -14),
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.isDark ? AppColors.primary : null,
                        gradient: !AppColors.isDark
                            ? LinearGradient(
                                colors: [
                                  AppColors.accentStart,
                                  AppColors.accentEnd,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: (AppColors.isDark ? AppColors.primary : AppColors.accentStart).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(isSelected ? tab.activeIcon : tab.icon, color: AppColors.textOnPrimary, size: 26),
                    ),
                  ),
                ),
              );
            }

            final color = isSelected ? AppColors.primary : AppColors.textMuted;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isSelected ? tab.activeIcon : tab.icon, color: color, size: 22),
                    const SizedBox(height: 3),
                    Text(tab.label, style: AppTextStyles.navLabel.copyWith(color: color)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({required this.icon, required this.activeIcon, required this.label, this.isCentral = false});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCentral;
}