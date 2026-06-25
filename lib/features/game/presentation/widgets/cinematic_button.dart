import 'package:flutter/material.dart';

import '../../../../core/widgets/app_buttons.dart';

class CinematicButton extends StatelessWidget {
  const CinematicButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    if (!isPrimary) {
      return AppSecondaryButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
      );
    }
    return AppPrimaryButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
    );
  }
}
