import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../constants/app_text.dart';
import '../widgets/app_buttons.dart';
import '../widgets/mystery_scaffold.dart';
import '../../features/game/presentation/cubit/game_cubit.dart';

class MafmofPlaceholderScaffold extends StatelessWidget {
  const MafmofPlaceholderScaffold({
    super.key,
    required this.title,
    this.message = AppText.placeholderMessage,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return MysteryScaffold(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: Container(
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
                      title,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (secondaryLabel != null && onSecondary != null) ...[
            AppSecondaryButton(
              label: secondaryLabel!,
              onPressed: () => _runAction(context, onSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (primaryLabel != null && onPrimary != null)
            AppPrimaryButton(
              label: primaryLabel!,
              onPressed: () => _runAction(context, onPrimary),
            ),
        ],
      ),
    );
  }

  void _runAction(BuildContext context, VoidCallback? action) {
    context.read<GameCubit>().playUiTap();
    action?.call();
  }
}
