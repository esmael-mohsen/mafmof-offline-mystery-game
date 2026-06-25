import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class VoteSummaryBanner extends StatelessWidget {
  const VoteSummaryBanner({
    super.key,
    required this.message,
    this.backgroundColor,
  });

  final String message;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.sectionPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.goldSubtle,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
      ),
    );
  }
}
