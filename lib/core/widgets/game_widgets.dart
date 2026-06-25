import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class StageProgressIndicator extends StatelessWidget {
  const StageProgressIndicator({
    super.key,
    required this.currentStage,
    required this.totalStages,
    required this.resolvedStages,
  });

  final int currentStage;
  final int totalStages;
  final List<int> resolvedStages;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          for (var i = 1; i <= totalStages; i++)
            _StageDot(
              stageNumber: i,
              isResolved: resolvedStages.contains(i),
              isCurrent: i == currentStage,
            ),
        ],
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({
    required this.stageNumber,
    required this.isResolved,
    required this.isCurrent,
  });

  final int stageNumber;
  final bool isResolved;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? AppColors.crimson
        : isResolved
            ? AppColors.deepCrimson
            : AppColors.disabled;

    final glowShadow = isCurrent
        ? [
            BoxShadow(
              color: AppColors.crimsonGlow.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ]
        : null;

    return Expanded(
      child: Container(
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadius.borderRadiusSm,
          boxShadow: glowShadow,
        ),
        alignment: Alignment.center,
        child: Text(
          '$stageNumber',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isCurrent || isResolved
                    ? AppColors.textPrimary
                    : AppColors.disabledText,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class GameActionPanel extends StatelessWidget {
  const GameActionPanel({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.appBarBackground,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.name,
    this.isEliminated = false,
    this.suspicionCount = 0,
    this.chips = const [],
  });

  final String name;
  final bool isEliminated;
  final int suspicionCount;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isEliminated ? AppColors.mafiaWinSurface : AppColors.cardDark,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: isEliminated
              ? AppColors.crimson.withValues(alpha: 0.3)
              : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isEliminated
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ...chips,
        ],
      ),
    );
  }
}

class ClueCard extends StatelessWidget {
  const ClueCard({
    super.key,
    required this.title,
    required this.body,
    this.icon,
    this.backgroundColor,
  });

  final String title;
  final String body;
  final IconData? icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.sectionPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.sectionDark,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.crimson),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.crimson,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.55,
                ),
            textAlign: TextAlign.right,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}
