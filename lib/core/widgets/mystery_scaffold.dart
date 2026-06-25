import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'mystery_app_bar.dart';

class MysteryScaffold extends StatelessWidget {
  const MysteryScaffold({
    super.key,
    required this.title,
    required this.child,
    this.padding = AppSpacing.screenPadding,
    this.appBarActions,
    this.showCinematicGradient = true,
    this.showLogoInAppBar = false,
    this.showBackButton = false,
    this.onBack,
    this.useCustomAppBar = true,
  });

  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final List<Widget>? appBarActions;
  final bool showCinematicGradient;
  final bool showLogoInAppBar;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool useCustomAppBar;

  @override
  Widget build(BuildContext context) {
    final appBar = useCustomAppBar
        ? MysteryAppBar(
            title: title,
            showLogo: showLogoInAppBar,
            showBackButton: showBackButton,
            onBack: onBack,
            actions: appBarActions,
          )
        : AppBar(
            title: Text(title),
            actions: appBarActions,
          );

    return Scaffold(
      appBar: appBar,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: showCinematicGradient ? AppColors.cinematicGradient : null,
          color: showCinematicGradient ? null : AppColors.background,
        ),
        child: SafeArea(
          top: useCustomAppBar,
          child: Padding(
            padding: padding,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, value, animatedChild) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 16),
                    child: animatedChild,
                  ),
                );
              },
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class CinematicBackground extends StatelessWidget {
  const CinematicBackground({
    super.key,
    required this.child,
    this.showGradient = true,
  });

  final Widget child;
  final bool showGradient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: showGradient ? AppColors.cinematicGradient : null,
        color: showGradient ? null : AppColors.background,
      ),
      child: child,
    );
  }
}
