import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/session_player_entity.dart';
import '../../domain/entities/voting_round_entity.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../widgets/cinematic_button.dart';
import '../widgets/vote_summary_banner.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({
    super.key,
    required this.sessionId,
    required this.stageNumber,
  });

  final String sessionId;
  final int stageNumber;

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  late final GameCubit _cubit;
  int _activeVoterIndex = 0;
  _VoteResultRevealData? _pendingReveal;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<GameCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.openVoting(widget.stageNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          final session = state.activeSession;
          final round = state.currentVoteRound;
          final stage = state.currentStage;
          if (session == null || round == null) {
            return Stack(
              children: [
                _VotingBackdrop(imagePath: stage?.imageAssetPath),
                _VotingAppBar(
                  sessionId: widget.sessionId,
                  stageNumber: widget.stageNumber,
                ),
                Center(
                  child: state.errorMessage == null
                      ? const CircularProgressIndicator(
                          color: AppColors.crimson,
                        )
                      : Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: _VotingBlockedState(
                            message: state.errorMessage!,
                            onBackToDashboard: () => context.goNamed(
                              AppRoutes.hostDashboard.name,
                              pathParameters: {'sessionId': widget.sessionId},
                            ),
                          ),
                        ),
                ),
              ],
            );
          }

          final players = session.players;
          final readOnly = state.isCurrentStageReadOnly || round.isConfirmed;
          final maxIndex = round.eligibleVoterIds.length;
          final safeIndex = _activeVoterIndex.clamp(0, maxIndex);
          if (safeIndex != _activeVoterIndex) {
            _activeVoterIndex = safeIndex;
          }

          final activeVoter = !readOnly && safeIndex < maxIndex && !round.isTied
              ? players.firstWhere(
                  (item) => item.playerId == round.eligibleVoterIds[safeIndex],
                )
              : null;
          final activeVoterId = activeVoter?.playerId;
          final hasSelectedVote =
              activeVoterId != null && round.voteFor(activeVoterId) != null;

          return Stack(
            children: [
              _VotingBackdrop(imagePath: stage?.imageAssetPath),
              ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  MediaQuery.of(context).padding.top + 86,
                  AppSpacing.lg,
                  MediaQuery.of(context).padding.bottom +
                      (activeVoter == null ? 156 : 174),
                ),
                children: [
                  if (state.isCurrentStageReadOnly)
                    const VoteSummaryBanner(message: AppText.stageReviewBanner)
                  else if (round.isConfirmed)
                    const VoteSummaryBanner(message: AppText.voteLockedBanner)
                  else if (round.isTied)
                    VoteSummaryBanner(
                      message:
                          '${AppText.tieDetectedMessage}\n${round.tiedPlayerIds.map((id) => _playerName(players, id)).join(' - ')}',
                      backgroundColor: AppColors.mafiaWinSurface,
                    ),
                  if (state.isCurrentStageReadOnly ||
                      round.isConfirmed ||
                      round.isTied) ...[
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    child: readOnly || safeIndex == maxIndex || round.isTied
                        ? _VotingCompletePanel(
                            key: ValueKey(
                              'complete_${round.roundId}_${round.votesByVoterId.length}',
                            ),
                            round: round,
                            players: players,
                            isReadOnly: readOnly,
                          )
                        : _SingleVoterBallotCard(
                            key: ValueKey(
                              '${round.roundId}_${round.eligibleVoterIds[safeIndex]}',
                            ),
                            voter: activeVoter!,
                            round: round,
                            players: players,
                            voterIndex: safeIndex,
                            totalVoters: maxIndex,
                            onSelect: (targetId) => _selectVote(
                              voterId: round.eligibleVoterIds[safeIndex],
                              targetId: targetId,
                            ),
                          ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _VotingErrorBanner(message: state.errorMessage!),
                  ],
                ],
              ),
              _VotingAppBar(
                sessionId: widget.sessionId,
                stageNumber: widget.stageNumber,
              ),
              if (activeVoter != null)
                _VotingStepBottomNav(
                  voterIndex: safeIndex,
                  totalVoters: maxIndex,
                  hasSelectedVote: hasSelectedVote,
                  onNext: hasSelectedVote
                      ? () => _goNextVoter(context: context, round: round)
                      : null,
                  onBack: safeIndex == 0 ? null : () => _goPreviousVoter(round),
                )
              else
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _VotingBottomActions(
                    sessionId: widget.sessionId,
                    round: round,
                    isReadOnly: state.isCurrentStageReadOnly,
                    hasFinalOutcome: session.finalOutcome != null,
                    onStartTieRevote: () {
                      setState(() {
                        _pendingReveal = null;
                        _activeVoterIndex = 0;
                      });
                      _cubit.startTieRevote();
                    },
                  ),
                ),
              if (_pendingReveal != null)
                _VoteResultRevealOverlay(
                  data: _pendingReveal!,
                  onTap: () => _handleRevealTap(context),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectVote({
    required String voterId,
    required String targetId,
  }) async {
    await _cubit.castVote(voterId, targetId);
    if (!mounted) {
      return;
    }
  }

  Future<void> _resolveRoundAndShowReveal({
    required BuildContext context,
    required VotingRoundEntity round,
  }) async {
    await _cubit.resolveCurrentVoteRound();
    if (!mounted) {
      return;
    }

    final resolvedRound = _cubit.state.currentVoteRound;
    if (resolvedRound == null || resolvedRound.isTied) {
      final latestRound = resolvedRound ?? round;
      setState(() {
        _activeVoterIndex = latestRound.eligibleVoterIds.length;
        _pendingReveal = _VoteResultRevealData.tie(
          tiedPlayers: latestRound.tiedPlayerIds
              .map((id) => _player(_cubit.state.activeSession!.players, id))
              .toList(growable: false),
        );
      });
      return;
    }

    if (resolvedRound.resolvedTargetId != null) {
      await _cubit.confirmCurrentVoteRound();
      if (!mounted || !context.mounted) {
        return;
      }
      final session = _cubit.state.activeSession;
      final target = _player(session!.players, resolvedRound.resolvedTargetId!);
      setState(() {
        _activeVoterIndex = resolvedRound.eligibleVoterIds.length;
        _pendingReveal = _VoteResultRevealData.resolved(
          voteType: resolvedRound.voteType,
          target: target,
          goesToFinalReveal: session.finalOutcome != null,
        );
      });
    }
  }

  void _handleRevealTap(BuildContext context) {
    final reveal = _pendingReveal;
    if (reveal == null) {
      return;
    }

    if (reveal.isTie) {
      setState(() => _pendingReveal = null);
      return;
    }

    final route = reveal.goesToFinalReveal
        ? AppRoutes.finalReveal
        : AppRoutes.hostDashboard;
    context.goNamed(
      route.name,
      pathParameters: {'sessionId': widget.sessionId},
    );
  }

  Future<void> _goNextVoter({
    required BuildContext context,
    required VotingRoundEntity round,
  }) async {
    final nextIndex = _activeVoterIndex + 1;
    if (nextIndex >= round.eligibleVoterIds.length) {
      await _resolveRoundAndShowReveal(context: context, round: round);
      return;
    }

    setState(() {
      _activeVoterIndex = nextIndex;
    });
  }

  void _goPreviousVoter(VotingRoundEntity round) {
    final previousIndex = (_activeVoterIndex - 1).clamp(
      0,
      round.eligibleVoterIds.length - 1,
    );
    setState(() => _activeVoterIndex = previousIndex);
  }

  String _playerName(List<SessionPlayerEntity> players, String playerId) {
    return _player(players, playerId).displayName;
  }

  SessionPlayerEntity _player(
    List<SessionPlayerEntity> players,
    String playerId,
  ) {
    return players.firstWhere((item) => item.playerId == playerId);
  }
}

class _VoteResultRevealData {
  const _VoteResultRevealData._({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.target,
    this.tiedPlayers = const <SessionPlayerEntity>[],
    this.goesToFinalReveal = false,
    this.isTie = false,
  });

  factory _VoteResultRevealData.resolved({
    required String voteType,
    required SessionPlayerEntity target,
    required bool goesToFinalReveal,
  }) {
    if (voteType == 'suspicion') {
      return _VoteResultRevealData._(
        title: 'علامة شك',
        subtitle: 'تم تسجيل علامة شك على ${target.displayName}',
        icon: Icons.visibility_rounded,
        accent: AppColors.gold,
        target: target,
        goesToFinalReveal: goesToFinalReveal,
      );
    }

    if (voteType == 'final') {
      return _VoteResultRevealData._(
        title: 'الاتهام النهائي',
        subtitle: 'تم تثبيت الاتهام على ${target.displayName}',
        icon: Icons.gavel_rounded,
        accent: AppColors.crimson,
        target: target,
        goesToFinalReveal: goesToFinalReveal,
      );
    }

    return _VoteResultRevealData._(
      title: 'خرج من القضية',
      subtitle: 'تم استبعاد ${target.displayName} من الجولة',
      icon: Icons.person_off_rounded,
      accent: AppColors.crimson,
      target: target,
      goesToFinalReveal: goesToFinalReveal,
    );
  }

  factory _VoteResultRevealData.tie({
    required List<SessionPlayerEntity> tiedPlayers,
  }) {
    return _VoteResultRevealData._(
      title: 'تعادل في التصويت',
      subtitle: 'اضغط للرجوع وبدء إعادة التصويت بين المرشحين',
      icon: Icons.balance_rounded,
      accent: AppColors.gold,
      tiedPlayers: tiedPlayers,
      isTie: true,
    );
  }

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final SessionPlayerEntity? target;
  final List<SessionPlayerEntity> tiedPlayers;
  final bool goesToFinalReveal;
  final bool isTie;
}

class _VotingBackdrop extends StatelessWidget {
  final String? imagePath;

  const _VotingBackdrop({this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imagePath != null)
          Image.asset(
            imagePath!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.deepCrimson.withValues(alpha: 0.34),
                  const Color(0xFF070709).withValues(alpha: 0.9),
                  const Color(0xFF070709),
                ],
                stops: const [0.0, 0.34, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: -100,
          right: -80,
          child: _VotingGlow(size: 210, alpha: 0.13),
        ),
        Positioned(
          bottom: 160,
          left: -90,
          child: _VotingGlow(size: 190, alpha: 0.11),
        ),
      ],
    );
  }
}

class _VotingGlow extends StatelessWidget {
  final double size;
  final double alpha;

  const _VotingGlow({required this.size, required this.alpha});

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
              blurRadius: size * 0.72,
              spreadRadius: size * 0.2,
            ),
          ],
        ),
      ),
    );
  }
}

class _VotingAppBar extends StatelessWidget {
  final String sessionId;
  final int stageNumber;

  const _VotingAppBar({
    required this.sessionId,
    required this.stageNumber,
  });

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
              color: const Color(0xFF070709).withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.crimson.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: Material(
                    color: const Color(0xFF070709).withValues(alpha: 0.5),
                    child: InkWell(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                          return;
                        }
                        context.goNamed(
                          AppRoutes.hostDashboard.name,
                          pathParameters: {'sessionId': sessionId},
                        );
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
                    '${AppText.votingTitle} $stageNumber',
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

class _VotingBlockedState extends StatelessWidget {
  final String message;
  final VoidCallback onBackToDashboard;

  const _VotingBlockedState({
    required this.message,
    required this.onBackToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return _VotingGlassPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.lock_clock_rounded,
            color: AppColors.crimson,
            size: 44,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'التصويت غير متاح الآن',
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionAmiriTitle(context).copyWith(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyPrimary(context).copyWith(
              color: Colors.white.withValues(alpha: 0.76),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CinematicButton(
            label: AppText.backToDashboardAction,
            onPressed: onBackToDashboard,
          ),
        ],
      ),
    );
  }
}

class _VotingRoundBadge extends StatelessWidget {
  final String label;

  const _VotingRoundBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.deepCrimson.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.crimson.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SingleVoterBallotCard extends StatelessWidget {
  final SessionPlayerEntity voter;
  final VotingRoundEntity round;
  final List<SessionPlayerEntity> players;
  final int voterIndex;
  final int totalVoters;
  final ValueChanged<String> onSelect;

  const _SingleVoterBallotCard({
    super.key,
    required this.voter,
    required this.round,
    required this.players,
    required this.voterIndex,
    required this.totalVoters,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTargetId = round.voteFor(voter.playerId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VotingGlassPanel(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: _CurrentVoterStrip(
            voter: voter,
            voterIndex: voterIndex,
            totalVoters: totalVoters,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _VotingGlassPanel(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TargetGrid(
                round: round,
                voterId: voter.playerId,
                players: players,
                selectedTargetId: selectedTargetId,
                onSelect: onSelect,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: selectedTargetId == null
                    ? const SizedBox.shrink()
                    : Padding(
                        key: const ValueKey('vote-saved'),
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: _VoteSavedCue(
                          targetName: players
                              .firstWhere(
                                (item) => item.playerId == selectedTargetId,
                              )
                              .displayName,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrentVoterStrip extends StatelessWidget {
  final SessionPlayerEntity voter;
  final int voterIndex;
  final int totalVoters;

  const _CurrentVoterStrip({
    required this.voter,
    required this.voterIndex,
    required this.totalVoters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.deepCrimson.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Image.asset(
                    voter.portraitAssetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: AppColors.cardDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _VotingRoundBadge(
                      label: 'مصوّت ${voterIndex + 1} من $totalVoters',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      voter.displayName,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _VoterProgressSegments(
            currentIndex: voterIndex,
            totalVoters: totalVoters,
          ),
        ],
      ),
    );
  }
}

class _VoterProgressSegments extends StatelessWidget {
  const _VoterProgressSegments({
    required this.currentIndex,
    required this.totalVoters,
  });

  final int currentIndex;
  final int totalVoters;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        for (var index = 0; index < totalVoters; index += 1) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: index == currentIndex ? 5 : 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: index < currentIndex
                    ? AppColors.crimson.withValues(alpha: 0.78)
                    : index == currentIndex
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.16),
                boxShadow: index == currentIndex
                    ? [
                        BoxShadow(
                          color: AppColors.crimson.withValues(alpha: 0.38),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          if (index != totalVoters - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _VoteSavedCue extends StatelessWidget {
  const _VoteSavedCue({required this.targetName});

  final String targetName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.deepCrimson.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.26)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'اختيارك محفوظ: $targetName',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetGrid extends StatelessWidget {
  final VotingRoundEntity round;
  final String voterId;
  final List<SessionPlayerEntity> players;
  final String? selectedTargetId;
  final ValueChanged<String> onSelect;

  const _TargetGrid({
    required this.round,
    required this.voterId,
    required this.players,
    required this.selectedTargetId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final targets = round.eligibleTargetIds
        .where((targetId) => targetId != voterId)
        .map(
          (targetId) => players.firstWhere((item) => item.playerId == targetId),
        )
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: const Color(0xFF090709).withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.crimson.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.deepCrimson.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.crimson.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Icon(
                      Icons.account_tree_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'لوحة الأدلة',
                          textAlign: TextAlign.right,
                          style:
                              AppTextStyles.sectionAmiriTitle(context).copyWith(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'اختار المشتبه به من الملفات المثبتة',
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: _EvidenceThreadsPainter(
                    lineColor: AppColors.crimson.withValues(alpha: 0.18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: targets.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 0.88,
                      ),
                      itemBuilder: (context, index) {
                        final target = targets[index];
                        return _TargetVoteCard(
                          target: target,
                          isSelected: selectedTargetId == target.playerId,
                          isDimmed: selectedTargetId != null &&
                              selectedTargetId != target.playerId,
                          onTap: () => onSelect(target.playerId),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EvidenceThreadsPainter extends CustomPainter {
  const _EvidenceThreadsPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    final points = <Offset>[
      Offset(size.width * 0.14, size.height * 0.22),
      Offset(size.width * 0.84, size.height * 0.18),
      Offset(size.width * 0.24, size.height * 0.74),
      Offset(size.width * 0.88, size.height * 0.78),
    ];

    for (var index = 0; index < points.length - 1; index += 1) {
      canvas.drawLine(points[index], points[index + 1], paint);
    }
    canvas.drawLine(points.first, points.last, paint);
  }

  @override
  bool shouldRepaint(covariant _EvidenceThreadsPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}

class _TargetVoteCard extends StatefulWidget {
  final SessionPlayerEntity target;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback onTap;

  const _TargetVoteCard({
    required this.target,
    required this.isSelected,
    required this.isDimmed,
    required this.onTap,
  });

  @override
  State<_TargetVoteCard> createState() => _TargetVoteCardState();
}

class _TargetVoteCardState extends State<_TargetVoteCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        child: AnimatedOpacity(
          opacity: widget.isDimmed ? 0.54 : 1,
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.deepCrimson.withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.isSelected
                    ? AppColors.crimson.withValues(alpha: 0.78)
                    : Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              widget.target.portraitAssetPath,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (_, __, ___) => const ColoredBox(
                                color: AppColors.cardDark,
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.42),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 48,
                        width: double.infinity,
                        color: const Color(0xFF070709).withValues(
                          alpha: widget.isSelected ? 0.66 : 0.82,
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: widget.target.isEliminated ? 5 : 11,
                              left: AppSpacing.sm,
                              right: AppSpacing.sm,
                              child: Text(
                                widget.target.displayName,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    AppTextStyles.bodyPrimary(context).copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (widget.target.isEliminated)
                              Positioned(
                                top: 25,
                                left: AppSpacing.sm,
                                right: AppSpacing.sm,
                                child: Text(
                                  AppText.eliminatedStatusLabel,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      AppTextStyles.caption(context).copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Transform.rotate(
                    angle: -0.38,
                    child: Icon(
                      Icons.push_pin_rounded,
                      color: widget.isSelected
                          ? AppColors.crimson
                          : Colors.white.withValues(alpha: 0.78),
                      size: 22,
                    ),
                  ),
                ),
                if (widget.isSelected)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.crimson,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VotingStepBottomNav extends StatelessWidget {
  const _VotingStepBottomNav({
    required this.voterIndex,
    required this.totalVoters,
    required this.hasSelectedVote,
    required this.onNext,
    required this.onBack,
  });

  final int voterIndex;
  final int totalVoters;
  final bool hasSelectedVote;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final isLastVoter = voterIndex + 1 == totalVoters;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: hasSelectedVote
                    ? Text(
                        'اختيارك محفوظ',
                        key: const ValueKey('saved'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption(context).copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Text(
                        'صوّت بسرية ثم انتقل للمصوت التالي',
                        key: const ValueKey('private'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption(context).copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    flex: 2,
                    child: _VotingPrimaryStepButton(
                      icon: Icons.arrow_back_rounded,
                      label: isLastVoter ? 'إظهار نتيجة التصويت' : 'التالي',
                      onPressed: onNext,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _VotingGhostButton(
                      icon: Icons.arrow_forward_rounded,
                      label: 'السابق',
                      onPressed: onBack,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VotingCompletePanel extends StatelessWidget {
  final VotingRoundEntity round;
  final List<SessionPlayerEntity> players;
  final bool isReadOnly;

  const _VotingCompletePanel({
    super.key,
    required this.round,
    required this.players,
    required this.isReadOnly,
  });

  @override
  Widget build(BuildContext context) {
    return _VotingGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            round.hasCompleteBallot || isReadOnly
                ? Icons.check_circle_rounded
                : Icons.how_to_vote_rounded,
            color: AppColors.crimson,
            size: 42,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            round.hasCompleteBallot || isReadOnly
                ? 'تم تسجيل كل الأصوات'
                : 'لسه فيه أصوات ناقصة',
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionAmiriTitle(context).copyWith(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final voterId in round.eligibleVoterIds)
            _VoteReceiptRow(
              voterName: players
                  .firstWhere((item) => item.playerId == voterId)
                  .displayName,
              targetName: round.voteFor(voterId) == null
                  ? AppText.noVoteYetLabel
                  : players
                      .firstWhere(
                          (item) => item.playerId == round.voteFor(voterId))
                      .displayName,
            ),
        ],
      ),
    );
  }
}

class _VoteResultRevealOverlay extends StatelessWidget {
  const _VoteResultRevealOverlay({
    required this.data,
    required this.onTap,
  });

  final _VoteResultRevealData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final target = data.target;

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 18 * value,
                  sigmaY: 18 * value,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF070709).withValues(alpha: 0.68),
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale: 0.92 + (0.08 * value),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _VotingGlassPanel(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Stack(
                    children: [
                      if (target != null)
                        AspectRatio(
                          aspectRatio: 0.82,
                          child: Image.asset(
                            target.portraitAssetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const ColoredBox(color: AppColors.cardDark),
                          ),
                        )
                      else
                        AspectRatio(
                          aspectRatio: 0.82,
                          child: _TiePortraitStack(players: data.tiedPlayers),
                        ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.08),
                                Colors.black.withValues(alpha: 0.32),
                                const Color(0xFF070709).withValues(alpha: 0.94),
                              ],
                              stops: const [0, 0.46, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.lg,
                        right: AppSpacing.lg,
                        child: _ResultTypeBadge(data: data),
                      ),
                      Positioned(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: AppSpacing.lg,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AnimatedResultStamp(data: data),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              target?.displayName ??
                                  data.tiedPlayers
                                      .map((player) => player.displayName)
                                      .join(' - '),
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.sectionAmiriTitle(context)
                                  .copyWith(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              data.subtitle,
                              textAlign: TextAlign.right,
                              style:
                                  AppTextStyles.bodySecondary(context).copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              textDirection: TextDirection.rtl,
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  color: Colors.white.withValues(alpha: 0.76),
                                  size: 18,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    data.isTie
                                        ? 'اضغط للرجوع للتصويت'
                                        : data.goesToFinalReveal
                                            ? 'اضغط لعرض الكشف النهائي'
                                            : 'اضغط للعودة للوحة المضيف',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        AppTextStyles.caption(context).copyWith(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TiePortraitStack extends StatelessWidget {
  const _TiePortraitStack({required this.players});

  final List<SessionPlayerEntity> players;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.suspicionChip.withValues(alpha: 0.95),
            AppColors.deepCrimson.withValues(alpha: 0.72),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var index = 0; index < players.length && index < 3; index += 1)
            Transform.translate(
              offset: Offset((index - 1) * 46, index.isEven ? -8 : 14),
              child: Transform.rotate(
                angle: (index - 1) * 0.12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 118,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                        width: 2,
                      ),
                    ),
                    child: Image.asset(
                      players[index].portraitAssetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: AppColors.cardDark),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultTypeBadge extends StatelessWidget {
  const _ResultTypeBadge({required this.data});

  final _VoteResultRevealData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF070709).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: data.accent.withValues(alpha: 0.46)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(data.icon, color: Colors.white, size: 17),
          const SizedBox(width: 6),
          Text(
            data.title,
            style: AppTextStyles.caption(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedResultStamp extends StatelessWidget {
  const _AnimatedResultStamp({required this.data});

  final _VoteResultRevealData data;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Transform.rotate(
            angle: data.isTie ? -0.04 : -0.11,
            child: child,
          ),
        );
      },
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: data.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: data.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: data.accent.withValues(alpha: 0.28),
                blurRadius: 22,
              ),
            ],
          ),
          child: Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionAmiriTitle(context).copyWith(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _VoteReceiptRow extends StatelessWidget {
  final String voterName;
  final String targetName;

  const _VoteReceiptRow({
    required this.voterName,
    required this.targetName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              voterName,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyPrimary(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.crimson,
              size: 18,
            ),
          ),
          Expanded(
            child: Text(
              targetName,
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyPrimary(context).copyWith(
                color: AppColors.crimson,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VotingBottomActions extends StatelessWidget {
  const _VotingBottomActions({
    required this.sessionId,
    required this.round,
    required this.isReadOnly,
    required this.hasFinalOutcome,
    required this.onStartTieRevote,
  });

  final String sessionId;
  final VotingRoundEntity round;
  final bool isReadOnly;
  final bool hasFinalOutcome;
  final VoidCallback onStartTieRevote;

  @override
  Widget build(BuildContext context) {
    if (!isReadOnly && !round.isTied && !round.isConfirmed) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF070709).withValues(alpha: 0.78),
            const Color(0xFF070709).withValues(alpha: 0.97),
          ],
          stops: const [0.0, 0.42, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + AppSpacing.md,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _buildActionContent(context),
        ),
      ),
    );
  }

  Widget _buildActionContent(BuildContext context) {
    if (!isReadOnly && !round.isConfirmed) {
      return CinematicButton(
        key: const ValueKey('tie-revote'),
        label: AppText.startTieRevoteAction,
        onPressed: round.isTied ? onStartTieRevote : null,
      );
    }

    if (round.voteType == 'final' && hasFinalOutcome) {
      return CinematicButton(
        key: const ValueKey('final-ready'),
        label: AppText.finalAccusationReadyAction,
        onPressed: () => context.goNamed(
          AppRoutes.finalReveal.name,
          pathParameters: {'sessionId': sessionId},
        ),
      );
    }

    return CinematicButton(
      key: const ValueKey('back'),
      label: AppText.backToDashboardAction,
      onPressed: () => context.goNamed(
        AppRoutes.hostDashboard.name,
        pathParameters: {'sessionId': sessionId},
      ),
    );
  }
}

class _VotingGhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _VotingGhostButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: enabled
            ? Colors.white.withValues(alpha: 0.86)
            : Colors.white.withValues(alpha: 0.28),
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: enabled ? 0.14 : 0.06),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.buttonLabel(context).copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VotingPrimaryStepButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _VotingPrimaryStepButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_VotingPrimaryStepButton> createState() =>
      _VotingPrimaryStepButtonState();
}

class _VotingPrimaryStepButtonState extends State<_VotingPrimaryStepButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 110),
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.48,
          duration: const Duration(milliseconds: 160),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.deepCrimson,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.crimson.withValues(alpha: 0.48),
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.24),
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
                Icon(widget.icon, color: Colors.white, size: 19),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.buttonLabel(context).copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VotingErrorBanner extends StatelessWidget {
  final String message;

  const _VotingErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return _VotingGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyPrimary(context).copyWith(
          color: AppColors.danger,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VotingGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _VotingGlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF070709).withValues(alpha: 0.66),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.crimson.withValues(alpha: 0.26),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.48),
                blurRadius: 24,
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
