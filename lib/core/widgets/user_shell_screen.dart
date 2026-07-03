import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/pass/presentation/screens/my_pass_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../theme/app_colors.dart';
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

    return GradientScaffold(
      bottomBar: _UserBottomNavBar(currentIndex: currentIndex, tabs: _tabs, onTap: _onTabTapped),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: NeverScrollableScrollPhysics(),
        children: [
          HomeScreen(
            onGymTap: (gym) {
              context.pushNamed(
                RouteNames.gymDetail,
                pathParameters: {'id': gym.id},
                extra: gym,
              );
            },
          ),
          const _ExplorePlaceholder(),
          MyPassScreen(
            pass: PassData(
              memberName: 'Aasif Khan',
              gymName: 'Iron Forge Studio',
              passId: 'GZ-P-08741',
              date: DateTime(2026, 6, 18),
              time: '7:30 PM',
              tier: 'Platinum',
            ),
            upcomingPasses: const [
              UpcomingPass(
                gymName: 'Lotus Yoga Sanctuary',
                date: '20 Jun',
                time: '6:30 AM',
                session: 'Hatha',
                dayOfMonth: 20,
                isActive: true,
              ),
            ],
          ),
          const _PassesPlaceholder(),
          ProfileScreen(
            name: 'Aasif Khan',
            email: 'aasif@email.com',
            memberId: 'GZ-2026-08741',
            sessionCount: 42,
            gymCount: 7,
            memberSinceDays: 12,
          ),
        ],
      ),
    );
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
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
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

class _ExplorePlaceholder extends StatelessWidget {
  const _ExplorePlaceholder();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Explore', style: TextStyle(color: Colors.white, fontSize: 20)));
}

class _PassesPlaceholder extends StatelessWidget {
  const _PassesPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Passes', style: TextStyle(color: Colors.white, fontSize: 20)));
}