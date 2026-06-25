import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/game_cards.dart';

class CinematicCard extends StatelessWidget {
  const CinematicCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return GlassDarkCard(
      padding: padding,
      margin: margin,
      borderRadius: AppRadius.md,
      child: child,
    );
  }
}
