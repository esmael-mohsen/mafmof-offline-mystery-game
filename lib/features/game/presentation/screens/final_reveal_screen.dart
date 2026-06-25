import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_media.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/elimination_record_entity.dart';
import '../../domain/entities/final_outcome_entity.dart';
import '../../domain/entities/session_player_entity.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../widgets/cinematic_button.dart';
import '../widgets/player_status_chip.dart';

class FinalRevealScreen extends StatefulWidget {
  const FinalRevealScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  State<FinalRevealScreen> createState() => _FinalRevealScreenState();
}

class _FinalRevealScreenState extends State<FinalRevealScreen> {
  late final GameCubit _cubit;
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarLifted = false;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<GameCubit>();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.markFinalRevealShown();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    final shouldLift =
        _scrollController.hasClients && _scrollController.offset > 4;
    if (shouldLift == _isAppBarLifted) {
      return;
    }
    setState(() => _isAppBarLifted = shouldLift);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          final session = state.activeSession;
          final outcome = session?.finalOutcome;
          final imagePath = state.selectedCase?.finalRevealAssetPath ??
              AppMedia.finalRevealImage;

          if (session == null || outcome == null) {
            return Stack(
              children: [
                _FinalRevealBackdrop(imagePath: imagePath),
                _FinalRevealAppBar(
                  sessionId: widget.sessionId,
                  isLifted: true,
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _MissingOutcomePanel(
                      onReturnHome: () => context.goNamed(AppRoutes.home.name),
                    ),
                  ),
                ),
              ],
            );
          }

          final accusedName =
              _playerName(session.players, outcome.accusedPlayerId);
          final winText = outcome.winningTeam == 'mafia'
              ? outcome.mafiaWinText
              : outcome.innocentWinText;

          return Stack(
            children: [
              _FinalRevealBackdrop(imagePath: imagePath),
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  final shouldLift = notification.metrics.pixels > 4;
                  if (shouldLift != _isAppBarLifted) {
                    setState(() => _isAppBarLifted = shouldLift);
                  }
                  return false;
                },
                child: ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    MediaQuery.of(context).padding.top + 86,
                    AppSpacing.lg,
                    MediaQuery.of(context).padding.bottom + 198,
                  ),
                  children: [
                    _FinalHeroPanel(
                      outcome: outcome,
                      imagePath: imagePath,
                      accusedName: accusedName,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (winText != null && winText.trim().isNotEmpty) ...[
                      _RevealSection(
                        icon: Icons.emoji_events_rounded,
                        title: outcome.winningTeam == 'mafia'
                            ? AppText.winnerMafiaLabel
                            : AppText.winnerInnocentLabel,
                        child: _RevealBodyText(winText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    _RevealSection(
                      icon: Icons.article_rounded,
                      title: AppText.finalRevealExplanationTitle,
                      child: _RevealBodyText(outcome.finalExplanation),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _RevealSection(
                      icon: Icons.badge_rounded,
                      title: AppText.finalRevealRolesTitle,
                      child: _RolesGrid(
                        players: session.players,
                        accusedPlayerId: outcome.accusedPlayerId,
                        suspicionSummary: outcome.suspicionSummary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _RevealSection(
                      icon: Icons.timeline_rounded,
                      title: AppText.finalRevealEliminationsTitle,
                      child: _EliminationTimeline(
                        records: outcome.eliminationSummary,
                        players: session.players,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _RevealSection(
                      icon: Icons.visibility_rounded,
                      title: AppText.finalRevealSuspicionTitle,
                      child: _SuspicionSummary(
                        players: session.players,
                        suspicionSummary: outcome.suspicionSummary,
                      ),
                    ),
                  ],
                ),
              ),
              _FinalRevealAppBar(
                sessionId: widget.sessionId,
                isLifted: _isAppBarLifted,
              ),
              _FinalBottomActions(
                onRestart: () => _restartSession(context, session.caseId),
                onHome: () => context.goNamed(AppRoutes.home.name),
              ),
            ],
          );
        },
      ),
    );
  }

  String _playerName(List<SessionPlayerEntity> players, String playerId) {
    return players.firstWhere((item) => item.playerId == playerId).displayName;
  }

  Future<void> _restartSession(BuildContext context, String caseId) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF111015),
            title: const Text(AppText.restartSessionTitle),
            content: const Text(AppText.restartSessionMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(AppText.cancelRestartAction),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                ),
                child: const Text(AppText.confirmRestartAction),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !context.mounted) {
      return;
    }

    await _cubit.restartSession();
    if (!context.mounted) {
      return;
    }

    context.goNamed(
      AppRoutes.setupGame.name,
      pathParameters: {'caseId': caseId},
    );
  }
}

class _FinalRevealBackdrop extends StatelessWidget {
  const _FinalRevealBackdrop({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.deepCrimson.withValues(alpha: 0.42),
                  const Color(0xFF070709).withValues(alpha: 0.9),
                  const Color(0xFF070709),
                ],
                stops: const [0, 0.34, 1],
              ),
            ),
          ),
        ),
        const Positioned(
          top: -90,
          right: -80,
          child: _RevealGlow(size: 220, alpha: 0.14),
        ),
        const Positioned(
          bottom: 170,
          left: -100,
          child: _RevealGlow(size: 210, alpha: 0.1),
        ),
      ],
    );
  }
}

class _RevealGlow extends StatelessWidget {
  const _RevealGlow({
    required this.size,
    required this.alpha,
  });

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.crimson.withValues(alpha: alpha),
              blurRadius: size * 0.7,
              spreadRadius: size * 0.18,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalRevealAppBar extends StatelessWidget {
  const _FinalRevealAppBar({
    required this.sessionId,
    required this.isLifted,
  });

  final String sessionId;
  final bool isLifted;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isLifted ? 22 : 10,
            sigmaY: isLifted ? 22 : 10,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF070709).withValues(
                alpha: isLifted ? 0.84 : 0.42,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.crimson.withValues(
                  alpha: isLifted ? 0.34 : 0.16,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLifted ? 0.44 : 0.22),
                  blurRadius: isLifted ? 24 : 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipOval(
                  child: Material(
                    color: const Color(0xFF070709).withValues(alpha: 0.5),
                    child: InkWell(
                      onTap: () => context.goNamed(
                        AppRoutes.hostDashboard.name,
                        pathParameters: {'sessionId': sessionId},
                      ),
                      child: const SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppText.finalRevealTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: Colors.red.shade900.withValues(alpha: 0.68),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 46 + AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FinalHeroPanel extends StatelessWidget {
  const _FinalHeroPanel({
    required this.outcome,
    required this.imagePath,
    required this.accusedName,
  });

  final FinalOutcomeEntity outcome;
  final String imagePath;
  final String accusedName;

  @override
  Widget build(BuildContext context) {
    final isMafiaWin = outcome.winningTeam == 'mafia';
    final accent = isMafiaWin ? AppColors.crimson : AppColors.success;
    final winnerLabel =
        isMafiaWin ? AppText.winnerMafiaLabel : AppText.winnerInnocentLabel;

    return _RevealGlassPanel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 0.92,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: AppColors.cardDark,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.36),
                      const Color(0xFF070709).withValues(alpha: 0.92),
                    ],
                    stops: const [0, 0.48, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.lg,
              right: AppSpacing.lg,
              child: _RevealPill(
                icon: Icons.lock_open_rounded,
                label: AppText.finalRevealCompletedBanner,
                color: accent,
              ),
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    winnerLabel,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.heroSignatureTitle(context).copyWith(
                      color: Colors.white,
                      fontSize: 38,
                      shadows: [
                        Shadow(
                          color: accent.withValues(alpha: 0.78),
                          blurRadius: 26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _RevealPill(
                        icon: Icons.gavel_rounded,
                        label: '${AppText.finalAccusedLabel}: $accusedName',
                        color: AppColors.crimson,
                      ),
                      _RevealPill(
                        icon: outcome.allMafiosoEliminatedBeforeFinal
                            ? Icons.verified_rounded
                            : Icons.warning_rounded,
                        label: outcome.allMafiosoEliminatedBeforeFinal
                            ? 'تم إسقاط الخطر قبل النهاية'
                            : 'الخطر وصل للنهاية',
                        color: accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealSection extends StatelessWidget {
  const _RevealSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _RevealGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.crimson.withValues(alpha: 0.26),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _CrimsonDivider(),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _RevealGlassPanel extends StatelessWidget {
  const _RevealGlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF0C0A0D).withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: AppColors.crimson.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CrimsonDivider extends StatelessWidget {
  const _CrimsonDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.crimson.withValues(alpha: 0.52),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _RevealBodyText extends StatelessWidget {
  const _RevealBodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      softWrap: true,
      style: AppTextStyles.bodyPrimary(context).copyWith(
        color: AppColors.textPrimary,
        height: 1.68,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _RolesGrid extends StatelessWidget {
  const _RolesGrid({
    required this.players,
    required this.accusedPlayerId,
    required this.suspicionSummary,
  });

  final List<SessionPlayerEntity> players;
  final String accusedPlayerId;
  final Map<String, int> suspicionSummary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        final width =
            (constraints.maxWidth - (AppSpacing.sm * (columns - 1))) / columns;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final player in players)
              _RoleDossierCard(
                width: width,
                player: player,
                suspicionCount: suspicionSummary[player.playerId] ?? 0,
                isAccused: player.playerId == accusedPlayerId,
              ),
          ],
        );
      },
    );
  }
}

class _RoleDossierCard extends StatelessWidget {
  const _RoleDossierCard({
    required this.width,
    required this.player,
    required this.suspicionCount,
    required this.isAccused,
  });

  final double width;
  final SessionPlayerEntity player;
  final int suspicionCount;
  final bool isAccused;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isAccused ? 0.1 : 0.055),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isAccused
                ? AppColors.crimson.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 58,
                height: 58,
                child: Image.asset(
                  player.portraitAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: AppColors.cardDark),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    player.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.cardTitle(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${player.characterName} | ${player.localizedRoleName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _MiniStatusChip(label: _teamLabel(player.team)),
                      if (player.isEliminated)
                        const _MiniStatusChip(
                          label: AppText.eliminatedStatusLabel,
                          color: AppColors.mafiaWinSurface,
                        ),
                      if (suspicionCount > 0)
                        _MiniStatusChip(
                          label: 'شك $suspicionCount',
                          color: AppColors.suspicionChip,
                        ),
                      if (isAccused)
                        const _MiniStatusChip(
                          label: AppText.finalAccusedLabel,
                          color: AppColors.info,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _teamLabel(String team) {
    if (team == 'mafia' || team == 'mafia_support') {
      return AppText.winnerMafiaLabel;
    }
    if (team == 'innocent') {
      return AppText.winnerInnocentLabel;
    }
    return team;
  }
}

class _EliminationTimeline extends StatelessWidget {
  const _EliminationTimeline({
    required this.records,
    required this.players,
  });

  final List<EliminationRecordEntity> records;
  final List<SessionPlayerEntity> players;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyRevealState(message: AppText.noEliminationsYetLabel);
    }

    return Column(
      children: [
        for (final record in records)
          _TimelineRow(
            label: '${AppText.votingStageLabel} ${record.stageNumber}',
            value: _playerName(record.playerId),
          ),
      ],
    );
  }

  String _playerName(String playerId) {
    return players.firstWhere((item) => item.playerId == playerId).displayName;
  }
}

class _SuspicionSummary extends StatelessWidget {
  const _SuspicionSummary({
    required this.players,
    required this.suspicionSummary,
  });

  final List<SessionPlayerEntity> players;
  final Map<String, int> suspicionSummary;

  @override
  Widget build(BuildContext context) {
    final suspiciousPlayers = players
        .where((player) => (suspicionSummary[player.playerId] ?? 0) > 0)
        .toList(growable: false);

    if (suspiciousPlayers.isEmpty) {
      return const _EmptyRevealState(message: AppText.noSuspicionMarksYetLabel);
    }

    return Column(
      children: [
        for (final player in suspiciousPlayers)
          _TimelineRow(
            label: player.displayName,
            value: 'شك ${suspicionSummary[player.playerId]}',
            valueColor: AppColors.gold,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppTextStyles.bodySecondary(context).copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            PlayerStatusChip(
              label: value,
              color: (valueColor ?? AppColors.mafiaWinSurface).withValues(
                alpha: 0.72,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealPill extends StatelessWidget {
  const _RevealPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF070709).withValues(alpha: 0.62),
        borderRadius: AppRadius.borderRadiusPill,
        border: Border.all(color: color.withValues(alpha: 0.46)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatusChip extends StatelessWidget {
  const _MiniStatusChip({
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? AppColors.crimson.withValues(alpha: 0.16),
        borderRadius: AppRadius.borderRadiusPill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption(context).copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EmptyRevealState extends StatelessWidget {
  const _EmptyRevealState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySecondary(context).copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FinalBottomActions extends StatelessWidget {
  const _FinalBottomActions({
    required this.onRestart,
    required this.onHome,
  });

  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color(0xFF070709).withValues(alpha: 0.78),
              const Color(0xFF070709).withValues(alpha: 0.98),
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFF070709).withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.crimson.withValues(alpha: 0.24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.crimson.withValues(alpha: 0.1),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FinalActionButton(
                      label: AppText.restartSessionAction,
                      icon: Icons.restart_alt_rounded,
                      onPressed: onRestart,
                      isPrimary: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FinalActionButton(
                      label: AppText.returnHome,
                      icon: Icons.home_rounded,
                      onPressed: onHome,
                      isPrimary: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinalActionButton extends StatefulWidget {
  const _FinalActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  State<_FinalActionButton> createState() => _FinalActionButtonState();
}

class _FinalActionButtonState extends State<_FinalActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 110),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: widget.isPrimary ? 54 : 48,
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppColors.crimson,
                      AppColors.deepCrimson.withValues(alpha: 0.92),
                    ],
                  )
                : null,
            color:
                widget.isPrimary ? null : Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isPrimary
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.crimson.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.buttonLabel(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
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

class _MissingOutcomePanel extends StatelessWidget {
  const _MissingOutcomePanel({required this.onReturnHome});

  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    return _RevealGlassPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_clock_rounded,
              color: AppColors.crimson, size: 42),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppText.sessionFailClosedMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyPrimary(context).copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CinematicButton(
            label: AppText.returnHome,
            onPressed: onReturnHome,
          ),
        ],
      ),
    );
  }
}
