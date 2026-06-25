import 'package:flutter/material.dart';

import '../../../../core/widgets/mystery_scaffold.dart';
import '../../../../core/theme/app_spacing.dart';

class CinematicScreenShell extends StatelessWidget {
  const CinematicScreenShell({
    super.key,
    required this.title,
    required this.child,
    this.padding = AppSpacing.screenPadding,
    this.appBarActions,
    this.showLogoInAppBar = false,
    this.showBackButton = false,
    this.onBack,
  });

  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final List<Widget>? appBarActions;
  final bool showLogoInAppBar;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return MysteryScaffold(
      title: title,
      padding: padding,
      appBarActions: appBarActions,
      showLogoInAppBar: showLogoInAppBar,
      showBackButton: showBackButton,
      onBack: onBack,
      child: child,
    );
  }
}
