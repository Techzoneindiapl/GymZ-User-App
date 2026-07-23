import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/text_size_provider.dart';

import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  final notificationService = container.read(notificationServiceProvider);
  await notificationService.init();
  await notificationService.requestPermissions();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const GymzUserApp(),
    ),
  );
}

class GymzUserApp extends ConsumerWidget {
  const GymzUserApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    AppColors.isDark = themeMode == ThemeMode.dark;

    final textSizeScale = ref.watch(textSizeProvider);

    return MaterialApp.router(
      title: 'GymZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenScale = (screenWidth / 390.0).clamp(0.85, 1.25);
        final userScale = textSizeScale == TextSizeScale.large ? 1.25 : 1.0;
        
        AppTextStyles.textScaleFactor = screenScale * userScale;
        return child ?? const SizedBox.shrink();
      },
    );
  }
}