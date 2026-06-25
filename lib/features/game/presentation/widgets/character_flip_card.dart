import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_text.dart';
import '../../domain/entities/session_player_entity.dart';
import 'character_portrait.dart';

const Color _kBackgroundAlpha30 = Color(0x4D080A0F);
const Color _kBackgroundAlpha85 = Color(0xD9080A0F);

class CharacterFlipCard extends StatefulWidget {
  const CharacterFlipCard({
    super.key,
    required this.player,
    required this.isRevealed,
    this.onFlip,
  });

  final SessionPlayerEntity player;
  final bool isRevealed;
  final VoidCallback? onFlip;

  @override
  State<CharacterFlipCard> createState() => _CharacterFlipCardState();
}

class _CharacterFlipCardState extends State<CharacterFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 0.45),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.05), weight: 0.10),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 0.45),
    ]).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    ));

    if (widget.isRevealed) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CharacterFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed != oldWidget.isRevealed) {
      if (widget.isRevealed) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * math.pi;
        final showBack = _flipAnimation.value >= 0.5;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(showBack ? angle - math.pi : angle)
            ..scale(_scaleAnimation.value),
          child: showBack
              ? _RoleBack(player: widget.player)
              : _RoleFront(player: widget.player),
        );
      },
    );
  }
}

class _RoleFront extends StatelessWidget {
  const _RoleFront({required this.player});

  final SessionPlayerEntity player;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: AppRadius.borderRadiusXl,
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimsonGlow.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 1,
          ),
          AppShadows.deep(blurRadius: 24),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderRadiusXl,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                player.portraitAssetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: AppColors.surface,
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.3, 0.6, 1.0],
                      colors: [
                        Color(0x00000000),
                        _kBackgroundAlpha30,
                        _kBackgroundAlpha85,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.xxl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      player.characterName,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: AppColors.background.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    if (player.characterTitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        player.characterTitle!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          shadows: [
                            Shadow(
                              color:
                                  AppColors.background.withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.deepCrimson.withValues(alpha: 0.5),
                          borderRadius: AppRadius.borderRadiusPill,
                          border: Border.all(
                            color: AppColors.crimson.withValues(alpha: 0.7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.crimsonGlow.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          player.displayName,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: AppSpacing.lg,
                right: AppSpacing.lg,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.8),
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: const Icon(
                    Icons.visibility_off,
                    color: AppColors.textPrimary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBack extends StatelessWidget {
  const _RoleBack({required this.player});

  final SessionPlayerEntity player;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: AppRadius.borderRadiusXl,
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.5)),
        boxShadow: [
          AppShadows.crimsonGlow(blurRadius: 20),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderRadiusXl,
        child: SingleChildScrollView(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CharacterPortrait(
                    assetPath: player.portraitAssetPath,
                    size: 72,
                    borderRadius: AppRadius.md,
                    showGlow: true,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          player.characterName,
                          textAlign: TextAlign.right,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        if (player.characterTitle != null)
                          Text(
                            player.characterTitle!,
                            textAlign: TextAlign.right,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(
                  color: AppColors.dividerRed, height: AppSpacing.xxl),
              _DetailRow(
                label: AppText.roleLabel,
                value: player.localizedRoleName,
                icon: Icons.shield,
                isHighlighted: true,
              ),
              _DetailRow(
                label: AppText.teamLabel,
                value: player.team,
                icon: Icons.group,
              ),
              _DetailRow(
                label: AppText.publicInfoLabel,
                value: player.publicInfo,
                icon: Icons.info_outline,
              ),
              for (final section in player.privateSections)
                _DetailRow(
                  label: _labelForSection(section.key),
                  value: section.value,
                  icon: _iconForSection(section.key),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelForSection(String key) {
    switch (key) {
      case 'secret':
        return AppText.secretLabel;
      case 'secretMeaning':
        return AppText.secretMeaningLabel;
      case 'goal':
        return AppText.goalLabel;
      case 'tasks':
        return AppText.tasksLabel;
      case 'specialAbility':
        return AppText.specialAbilityLabel;
      case 'mustNotSay':
        return AppText.mustNotSayLabel;
      default:
        return key;
    }
  }

  IconData? _iconForSection(String key) {
    switch (key) {
      case 'secret':
        return Icons.lock;
      case 'secretMeaning':
        return Icons.lightbulb_outline;
      case 'goal':
        return Icons.flag;
      case 'tasks':
        return Icons.checklist;
      case 'specialAbility':
        return Icons.auto_fix_high;
      case 'mustNotSay':
        return Icons.block;
      default:
        return null;
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.icon,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: AppSpacing.detailRowPadding,
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.crimsonSubtle : AppColors.surface,
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(
            color: isHighlighted
                ? AppColors.crimson.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppColors.crimson),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.crimson,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.right,
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }
}
