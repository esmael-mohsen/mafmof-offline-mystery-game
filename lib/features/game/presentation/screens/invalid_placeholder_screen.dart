import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/mystery_scaffold.dart';

class InvalidPlaceholderScreen extends StatelessWidget {
  const InvalidPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MysteryScaffold(
      title: AppText.invalidPlaceholderTitle,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.elevatedSurface,
                borderRadius: AppRadius.borderRadiusMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppText.invalidPlaceholderTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppText.invalidPlaceholderMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: AppText.returnHome,
              onPressed: () => context.goNamed(AppRoutes.home.name),
            ),
          ],
        ),
      ),
    );
  }
}
