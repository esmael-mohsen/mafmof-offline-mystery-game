import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/game_session_entity.dart';
import '../../domain/entities/session_player_entity.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';

class HostDashboardScreen extends StatelessWidget {
  const HostDashboardScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          final session = state.activeSession;
          if (session == null) {
            return _InvalidDashboardState(
              onReturnHome: () => context.goNamed(AppRoutes.home.name),
            );
          }

          return Stack(
            children: [
              const _DashboardBackdrop(),
              CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      MediaQuery.of(context).padding.top + 76,
                      AppSpacing.lg,
                      AppSpacing.huge * 2,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed([
                        _SessionHeroPanel(session: session, state: state),
                        const SizedBox(height: AppSpacing.lg),
                        _StageCommandPanel(
                          sessionId: sessionId,
                          session: session,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _PlayersDossierPanel(session: session),
                        const SizedBox(height: AppSpacing.lg),
                        _HostToolsPanel(
                          sessionId: sessionId,
                          caseId: session.caseId,
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
              const _DashboardAppBar(),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardBackdrop extends StatelessWidget {
  const _DashboardBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepCrimson.withValues(alpha: 0.28),
            const Color(0xFF070709),
            const Color(0xFF070709),
          ],
          stops: const [0.0, 0.34, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: _GlowOrb(size: 190, alpha: 0.16),
          ),
          Positioned(
            top: 220,
            left: -90,
            child: _GlowOrb(size: 170, alpha: 0.1),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final double alpha;

  const _GlowOrb({required this.size, required this.alpha});

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
              blurRadius: size * 0.65,
              spreadRadius: size * 0.18,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF070709).withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.crimson.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipOval(
                  child: Material(
                    color: const Color(0xFF070709).withValues(alpha: 0.48),
                    child: InkWell(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                          return;
                        }
                        context.goNamed(AppRoutes.home.name);
                      },
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
                    AppText.hostDashboardTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
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

class _SessionHeroPanel extends StatelessWidget {
  final GameSessionEntity session;
  final GameState state;

  const _SessionHeroPanel({required this.session, required this.state});

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.deepCrimson.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.crimson.withValues(alpha: 0.22),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppText.dashboardSummaryTitle,
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.crimson,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      session.caseTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _DashboardMetricChip(
                icon: Icons.groups_rounded,
                label: '${session.playerCount} لاعبين',
              ),
              _DashboardMetricChip(
                icon: Icons.flag_rounded,
                label:
                    '${AppText.recommendedNextStageLabel}: ${session.recommendedNextStage}',
              ),
              _DashboardMetricChip(
                icon: Icons.check_circle_rounded,
                label: '${session.resolvedStageNumbers.length}/5 مراحل',
              ),
            ],
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            _DashboardErrorBanner(message: state.errorMessage!),
          ],
        ],
      ),
    );
  }
}

class _StageCommandPanel extends StatelessWidget {
  final String sessionId;
  final GameSessionEntity session;

  const _StageCommandPanel({
    required this.sessionId,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    if (session.hasFinalOutcome) {
      return _GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PanelHeader(
              icon: Icons.gavel_rounded,
              title: AppText.continueToFinalReveal,
              subtitle: 'التحقيق اتحسم. افتح الكشف النهائي بدل تكملة المراحل.',
            ),
            const SizedBox(height: AppSpacing.md),
            _DashboardActionButton(
              label: AppText.continueToFinalReveal,
              icon: Icons.lock_open_rounded,
              onPressed: () => context.goNamed(
                AppRoutes.finalReveal.name,
                pathParameters: {'sessionId': sessionId},
              ),
            ),
          ],
        ),
      );
    }

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            icon: Icons.local_activity_rounded,
            title: AppText.continueToStage,
            subtitle: 'افتح المرحلة المقترحة أو راجع مرحلة اتحسمت',
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final isTight = constraints.maxWidth < 360;
              final spacing = isTight ? AppSpacing.xs : AppSpacing.sm;
              final itemWidth = (constraints.maxWidth - (spacing * 4)) / 5;

              return Wrap(
                spacing: spacing,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var stageNumber = 1; stageNumber <= 5; stageNumber += 1)
                    SizedBox(
                      width: itemWidth,
                      child: _StageTape(
                        key: Key('stage-button-$stageNumber'),
                        stageNumber: stageNumber,
                        sessionId: sessionId,
                        session: session,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _StageProgressLine(session: session),
        ],
      ),
    );
  }
}

class _StageTape extends StatelessWidget {
  final int stageNumber;
  final String sessionId;
  final GameSessionEntity session;

  const _StageTape({
    super.key,
    required this.stageNumber,
    required this.sessionId,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final isResolved = session.isStageResolved(stageNumber);
    final isNextLiveStage = session.recommendedNextStage == stageNumber;
    final isLocked = !isResolved && !isNextLiveStage;

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppText.stageOrderBlockedMessage)),
          );
          return;
        }

        context.goNamed(
          AppRoutes.stage.name,
          pathParameters: {
            'sessionId': sessionId,
            'stageNumber': '$stageNumber',
          },
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 74,
        decoration: BoxDecoration(
          color: isResolved
              ? AppColors.deepCrimson
              : isNextLiveStage
                  ? AppColors.crimson
                  : const Color(0xFF151012).withValues(alpha: 0.86),
          border: Border.all(
            color: isLocked
                ? AppColors.crimson.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.18),
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isNextLiveStage
              ? [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isResolved
                  ? Icons.check_circle_rounded
                  : isNextLiveStage
                      ? Icons.play_arrow_rounded
                      : Icons.lock_outline_rounded,
              color: isLocked ? Colors.white38 : Colors.white,
              size: 18,
            ),
            const SizedBox(height: 3),
            Text(
              '$stageNumber',
              style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                color: isLocked ? Colors.white38 : Colors.white,
                fontSize: 28,
                height: 0.9,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              isResolved
                  ? 'تمت'
                  : isNextLiveStage
                      ? 'التالي'
                      : 'مغلق',
              style: AppTextStyles.caption(context).copyWith(
                color: isLocked ? Colors.white38 : Colors.white70,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageProgressLine extends StatelessWidget {
  final GameSessionEntity session;

  const _StageProgressLine({required this.session});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var stageNumber = 1; stageNumber <= 5; stageNumber += 1) ...[
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: session.isStageResolved(stageNumber)
                    ? AppColors.crimson
                    : stageNumber == session.recommendedNextStage
                        ? AppColors.crimson.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (stageNumber != 5) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _PlayersDossierPanel extends StatelessWidget {
  final GameSessionEntity session;

  const _PlayersDossierPanel({required this.session});

  @override
  Widget build(BuildContext context) {
    final activePlayers =
        session.players.where((item) => !item.isEliminated).toList();
    final eliminatedPlayers =
        session.players.where((item) => item.isEliminated).toList();

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            icon: Icons.badge_rounded,
            title: AppText.dashboardPlayersTitle,
            subtitle: 'ملفات اللاعبين النشطين أمام المضيف',
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 3 : 2;
              final spacing = AppSpacing.sm;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final player in activePlayers)
                    SizedBox(
                      width: itemWidth,
                      child: _PlayerDossierCard(
                        player: player,
                        suspicionMarks:
                            session.suspicionMarks[player.playerId] ?? 0,
                      ),
                    ),
                ],
              );
            },
          ),
          if (eliminatedPlayers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _CrimsonDivider(),
            const SizedBox(height: AppSpacing.md),
            _PanelHeader(
              icon: Icons.person_off_rounded,
              title: AppText.dashboardEliminatedTitle,
              subtitle: 'الأدوار تظل مخفية حتى النهاية',
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final player in eliminatedPlayers)
                  _EliminatedChip(name: player.displayName),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerDossierCard extends StatelessWidget {
  final SessionPlayerEntity player;
  final int suspicionMarks;

  const _PlayerDossierCard({
    required this.player,
    required this.suspicionMarks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0B0D).withValues(alpha: 0.86),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.deepCrimson.withValues(alpha: 0.64),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  player.displayName.characters.first,
                  style: AppTextStyles.caption(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  player.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyPrimary(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (suspicionMarks > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _MiniChip(
              label: 'شك $suspicionMarks',
              color: AppColors.suspicionChip,
            ),
          ],
        ],
      ),
    );
  }
}

class _EliminatedChip extends StatelessWidget {
  final String name;

  const _EliminatedChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mafiaWinSurface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_rounded, color: Colors.white70, size: 15),
          const SizedBox(width: 6),
          Text(
            name,
            style: AppTextStyles.caption(context).copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HostToolsPanel extends StatelessWidget {
  final String sessionId;
  final String caseId;

  const _HostToolsPanel({required this.sessionId, required this.caseId});

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            icon: Icons.construction_rounded,
            title: 'أدوات المضيف',
            subtitle: 'اختصارات التحكم في الجلسة',
          ),
          const SizedBox(height: AppSpacing.md),
          _DashboardActionButton(
            label: AppText.restartSessionAction,
            icon: Icons.restart_alt_rounded,
            isDanger: true,
            onPressed: () => _confirmRestart(context, caseId),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DashboardActionButton(
            label: AppText.hostChecklistTitle,
            icon: Icons.checklist_rounded,
            onPressed: () => context.goNamed(
              AppRoutes.hostChecklist.name,
              pathParameters: {'sessionId': sessionId},
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRestart(BuildContext context, String caseId) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
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
            );
          },
        ) ??
        false;

    if (!confirmed || !context.mounted) {
      return;
    }

    await context.read<GameCubit>().restartSession();
    if (!context.mounted) {
      return;
    }

    context.goNamed(
      AppRoutes.setupGame.name,
      pathParameters: {'caseId': caseId},
    );
  }
}

class _DashboardActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isDanger;
  final VoidCallback onPressed;

  const _DashboardActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDanger = false,
  });

  @override
  State<_DashboardActionButton> createState() => _DashboardActionButtonState();
}

class _DashboardActionButtonState extends State<_DashboardActionButton> {
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
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: widget.isDanger
                ? AppColors.deepCrimson.withValues(alpha: 0.72)
                : const Color(0xFF151012),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: AppTextStyles.buttonLabel(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;

  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: const Color(0xFF070709).withValues(alpha: 0.62),
            border: Border.all(
              color: AppColors.crimson.withValues(alpha: 0.26),
              width: 1.1,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.48),
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

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PanelHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.caption(context).copyWith(
                  color: Colors.white60,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DashboardMetricChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return _MiniChip(label: label, icon: icon);
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const _MiniChip({required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color ?? AppColors.deepCrimson.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white70, size: 15),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrimsonDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.crimson.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _DashboardErrorBanner extends StatelessWidget {
  final String message;

  const _DashboardErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.deepCrimson.withValues(alpha: 0.2),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.34)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySecondary(context).copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InvalidDashboardState extends StatelessWidget {
  final VoidCallback onReturnHome;

  const _InvalidDashboardState({required this.onReturnHome});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _DashboardBackdrop(),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _GlassPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.crimson,
                    size: 46,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppText.sessionFailClosedMessage,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyPrimary(context).copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _DashboardActionButton(
                    label: AppText.returnHome,
                    icon: Icons.home_rounded,
                    onPressed: onReturnHome,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
