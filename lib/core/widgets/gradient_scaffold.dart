import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.body,
    this.bottomBar,
    this.resizeToAvoidBottomInset = true,
    this.background,
    this.extendBodyBehindAppBar = false,
  });

  final Widget body;
  final Widget? bottomBar;
  final bool resizeToAvoidBottomInset;
  final Widget? background;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final hasBackground = background != null;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: AppColors.backgroundBottom,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasBackground) background!,
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: hasBackground
                    ? [
                        AppColors.backgroundTop.withOpacity(0.75),
                        AppColors.backgroundBottom.withOpacity(0.9),
                      ]
                    : const [AppColors.backgroundTop, AppColors.backgroundBottom],
              ),
            ),
            child: SafeArea(
              bottom: bottomBar == null,
              child: body,
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}