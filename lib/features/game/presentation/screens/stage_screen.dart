import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/stage_entity.dart';
import '../../domain/entities/stage_timer_entity.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../widgets/vote_summary_banner.dart';

class StageTimerSelectorState {
  const StageTimerSelectorState({
    required this.timer,
    required this.isReadOnly,
  });

  final StageTimerEntity? timer;
  final bool isReadOnly;
}

List<String> _stageMediaPaths(String? value) {
  return (value ?? '')
      .split('\n')
      .map((path) => path.trim())
      .where((path) => path.isNotEmpty)
      .toList(growable: false);
}

bool _isLastSessionAmbientAudioPath(String path) {
  return path.contains('case_04_last_session') &&
      !path.contains('stage_03_doctor_recording');
}

bool get _isRunningInWidgetTest {
  return WidgetsBinding.instance.runtimeType.toString().contains('Test');
}

class StageScreen extends StatefulWidget {
  const StageScreen({
    super.key,
    required this.sessionId,
    required this.stageNumber,
  });

  final String sessionId;
  final int stageNumber;

  @override
  State<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends State<StageScreen> with WidgetsBindingObserver {
  late final GameCubit _cubit;
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarLifted = false;
  bool _isNavigatingToVoting = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _cubit = context.read<GameCubit>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.openStage(widget.stageNumber);
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (!_isNavigatingToVoting) {
      _cubit.leaveStage();
    }
    super.dispose();
  }

  void _handleScroll() {
    _updateAppBarLift(
      _scrollController.hasClients && _scrollController.offset > 4,
    );
  }

  void _updateAppBarLift(bool shouldLift) {
    if (shouldLift == _isAppBarLifted) {
      return;
    }

    setState(() => _isAppBarLifted = shouldLift);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _cubit.handleAppLifecycleChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) {
        _cubit.leaveStage();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF070709),
        body: BlocBuilder<GameCubit, GameState>(
          builder: (context, state) {
            final stage = state.currentStage;
            if (stage == null) {
              return const Stack(
                children: [
                  _StageBackdrop(),
                  Center(
                    child: CircularProgressIndicator(color: AppColors.crimson),
                  ),
                ],
              );
            }

            return Stack(
              children: [
                const _StageBackdrop(),
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    _updateAppBarLift(notification.metrics.pixels > 4);
                    return false;
                  },
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      MediaQuery.of(context).padding.top + 76,
                      AppSpacing.lg,
                      MediaQuery.of(context).padding.bottom + 150,
                    ),
                    children: [
                      if (state.isCurrentStageReadOnly) ...[
                        const VoteSummaryBanner(
                          message: AppText.stageReviewBanner,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _EvidenceFlipCard(stage: stage),
                      const SizedBox(height: AppSpacing.lg),
                      BlocSelector<GameCubit, GameState,
                          StageTimerSelectorState>(
                        selector: (state) => StageTimerSelectorState(
                          timer: state.stageTimer,
                          isReadOnly: state.isCurrentStageReadOnly,
                        ),
                        builder: (context, timerState) {
                          final timer = timerState.timer;
                          if (timerState.isReadOnly || timer == null) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            children: [
                              _TimerPanel(
                                remainingText:
                                    _formatDuration(timer.remainingSeconds),
                                isAtInitialDuration: timer.remainingSeconds ==
                                    timer.durationSeconds,
                                isRunning: timer.isRunning,
                                isWarning: timer.isWarning,
                                onStartOrResume: () {
                                  if (timer.isRunning) {
                                    return;
                                  }
                                  _cubit.startStageTimer();
                                },
                                onPause: () => _cubit.pauseStageTimer(),
                                onReset: () => _cubit.resetStageTimer(),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                          );
                        },
                      ),
                      _StageActionsPanel(
                        isReadOnly: state.isCurrentStageReadOnly,
                        onBackToDashboard: () => context.goNamed(
                          AppRoutes.hostDashboard.name,
                          pathParameters: {'sessionId': widget.sessionId},
                        ),
                      ),
                    ],
                  ),
                ),
                _StageAppBar(
                  stageNumber: widget.stageNumber,
                  isLifted: _isAppBarLifted,
                ),
                _StageBottomCta(
                  isReadOnly: state.isCurrentStageReadOnly,
                  bottomInset: MediaQuery.of(context).padding.bottom,
                  onPressed: () => _goToVoting(context, state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _goToVoting(BuildContext context, GameState state) async {
    if (!state.isCurrentStageReadOnly) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: const Color(0xFF111015),
              title: const Text(AppText.confirmLeaveStageTitle),
              content: const Text(AppText.confirmLeaveStageMessage),
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
                  child: const Text(AppText.goToVotingAction),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed || !context.mounted) {
        return;
      }
    }

    _isNavigatingToVoting = true;
    context.goNamed(
      AppRoutes.voting.name,
      pathParameters: {
        'sessionId': widget.sessionId,
        'stageNumber': '${widget.stageNumber}',
      },
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _StageBackdrop extends StatelessWidget {
  const _StageBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepCrimson.withValues(alpha: 0.24),
            const Color(0xFF070709),
            const Color(0xFF070709),
          ],
          stops: const [0.0, 0.28, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _GlowOrb(size: 190, alpha: 0.13),
          ),
          Positioned(
            bottom: 160,
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

class _StageAppBar extends StatelessWidget {
  final int stageNumber;
  final bool isLifted;

  const _StageAppBar({
    required this.stageNumber,
    required this.isLifted,
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
          filter: ImageFilter.blur(
            sigmaX: isLifted ? 22 : 8,
            sigmaY: isLifted ? 22 : 8,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF070709).withValues(
                alpha: isLifted ? 0.86 : 0.18,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.crimson.withValues(
                  alpha: isLifted ? 0.34 : 0.08,
                ),
              ),
              boxShadow: isLifted
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.46),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.12),
                        blurRadius: 20,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Material(
                      color: const Color(0xFF070709).withValues(alpha: 0.42),
                      shape: CircleBorder(
                        side: BorderSide(
                          color: AppColors.crimson.withValues(alpha: 0.24),
                        ),
                      ),
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
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: Center(
                      child: Text(
                        '${AppText.stageTitle} $stageNumber',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTextStyles.sectionAmiriTitle(context).copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color:
                                  Colors.red.shade900.withValues(alpha: 0.68),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
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

class _EvidenceFlipCard extends StatefulWidget {
  final StageEntity stage;

  const _EvidenceFlipCard({required this.stage});

  @override
  State<_EvidenceFlipCard> createState() => _EvidenceFlipCardState();
}

class _EvidenceFlipCardState extends State<_EvidenceFlipCard> {
  bool _showDetails = false;
  bool _hasShownImage = false;

  @override
  Widget build(BuildContext context) {
    final imagePaths = _stageMediaPaths(widget.stage.imageAssetPath);
    final audioPaths = _stageMediaPaths(widget.stage.audioAssetPath);
    final manualAudioPaths = audioPaths
        .where((path) => !_isLastSessionAmbientAudioPath(path))
        .toList(growable: false);
    final ambientAudioPaths = audioPaths
        .where(_isLastSessionAmbientAudioPath)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ambientAudioPaths.isNotEmpty)
          _AmbientAudioLoops(assetPaths: ambientAudioPaths),
        _EvidenceImageFront(
          stage: widget.stage,
          imagePaths: imagePaths,
          hasShownImage: _hasShownImage,
          onOpenFullScreen: (imagePath) => _openAudienceImage(
            context,
            imagePath,
          ),
        ),
        if (manualAudioPaths.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _EvidenceAudioPanel(
            assetPath: manualAudioPaths.first,
            title: widget.stage.audioTitle,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _FlipToggleButton(
          showingDetails: _showDetails,
          hasShownImage: _hasShownImage,
          onPressed: () => setState(() => _showDetails = !_showDetails),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: _EvidenceDetailsBack(stage: widget.stage),
          ),
          crossFadeState: _showDetails
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }

  Future<void> _openAudienceImage(
    BuildContext context,
    String? imagePath,
  ) async {
    if (imagePath == null) {
      return;
    }

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) =>
            _AudienceEvidenceImage(imagePath: imagePath),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() => _hasShownImage = true);
  }
}

class _EvidenceImageFront extends StatelessWidget {
  final StageEntity stage;
  final List<String> imagePaths;
  final bool hasShownImage;
  final ValueChanged<String?> onOpenFullScreen;

  const _EvidenceImageFront({
    required this.stage,
    required this.imagePaths,
    required this.hasShownImage,
    required this.onOpenFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePaths.length > 1) {
      return _EvidenceBoard(
        stage: stage,
        imagePaths: imagePaths,
        hasShownImage: hasShownImage,
        onOpenFullScreen: onOpenFullScreen,
      );
    }

    final imagePath = imagePaths.isEmpty ? null : imagePaths.first;

    return _GlassShell(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: imagePath == null ? null : () => onOpenFullScreen(imagePath),
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imagePath != null)
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _EvidenceFallback(),
                    )
                  else
                    _EvidenceFallback(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF070709).withValues(alpha: 0.88),
                          const Color(0xFF070709).withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.34, 0.72],
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: _EvidenceStatusBadge(hasShownImage: hasShownImage),
                  ),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stage.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppTextStyles.sectionAmiriTitle(context).copyWith(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color:
                                    Colors.red.shade900.withValues(alpha: 0.74),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'اضغط لعرض الصورة كاملة للاعبين',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption(context).copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                          ),
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
    );
  }
}

class _EvidenceBoard extends StatelessWidget {
  final StageEntity stage;
  final List<String> imagePaths;
  final bool hasShownImage;
  final ValueChanged<String?> onOpenFullScreen;

  const _EvidenceBoard({
    required this.stage,
    required this.imagePaths,
    required this.hasShownImage,
    required this.onOpenFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('evidence-board'),
      child: _GlassShell(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      stage.title,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _EvidenceStatusBadge(hasShownImage: hasShownImage),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: imagePaths.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 16 / 10,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemBuilder: (context, index) {
                final imagePath = imagePaths[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onOpenFullScreen(imagePath),
                    borderRadius: BorderRadius.circular(14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        imagePath,
                        key: const ValueKey('evidence-board-image'),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _EvidenceFallback(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientAudioLoops extends StatefulWidget {
  final List<String> assetPaths;

  const _AmbientAudioLoops({required this.assetPaths});

  @override
  State<_AmbientAudioLoops> createState() => _AmbientAudioLoopsState();
}

class _AmbientAudioLoopsState extends State<_AmbientAudioLoops> {
  final List<AudioPlayer> _players = <AudioPlayer>[];

  @override
  void initState() {
    super.initState();
    if (_isRunningInWidgetTest) {
      return;
    }
    _startAll();
  }

  @override
  void didUpdateWidget(covariant _AmbientAudioLoops oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPaths.join('\n') == widget.assetPaths.join('\n')) {
      return;
    }
    _stopAll();
    if (!_isRunningInWidgetTest) {
      _startAll();
    }
  }

  @override
  void dispose() {
    _stopAll();
    super.dispose();
  }

  void _startAll() {
    for (final assetPath in widget.assetPaths) {
      final player = AudioPlayer();
      _players.add(player);
      _startLoop(player, assetPath);
    }
  }

  Future<void> _startLoop(AudioPlayer player, String assetPath) async {
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.35);
      await player.play(AssetSource(assetPath.replaceFirst('assets/', '')));
    } catch (_) {
      // Optional ambient audio should never block stage flow.
    }
  }

  void _stopAll() {
    for (final player in _players) {
      player.dispose();
    }
    _players.clear();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _EvidenceAudioPanel extends StatefulWidget {
  final String assetPath;
  final String? title;

  const _EvidenceAudioPanel({
    required this.assetPath,
    required this.title,
  });

  @override
  State<_EvidenceAudioPanel> createState() => _EvidenceAudioPanelState();
}

class _EvidenceAudioPanelState extends State<_EvidenceAudioPanel> {
  late final AudioPlayer _player;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  Duration get _duration => Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPositionChanged.listen((position) {
      if (!mounted) {
        return;
      }
      setState(() => _position = position);
    });
    _player.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
      if (!mounted) {
        return;
      }
      setState(() => _isPlaying = false);
      return;
    }

    final sourcePath = widget.assetPath.replaceFirst('assets/', '');
    await _player.play(AssetSource(sourcePath));
    if (!mounted) {
      return;
    }
    setState(() => _isPlaying = true);
  }

  Future<void> _seek(double progress) async {
    final duration = _duration;
    if (duration == Duration.zero) {
      return;
    }

    final target = Duration(
      milliseconds: (duration.inMilliseconds * progress).round(),
    );
    await _player.seek(target);
    if (!mounted) {
      return;
    }
    setState(() => _position = target);
  }

  @override
  Widget build(BuildContext context) {
    final duration = _duration;
    final durationMs = duration.inMilliseconds;
    final positionMs = _position.inMilliseconds.clamp(0, durationMs);
    final progress = durationMs == 0 ? 0.0 : positionMs / durationMs;

    return _GlassShell(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            _AudioPlayButton(
              isPlaying: _isPlaying,
              onPressed: _togglePlayback,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        color: AppColors.goldSubtle.withValues(alpha: 0.95),
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          widget.title ?? 'تسجيل الدليل',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.bodyPrimary(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: AppColors.crimson,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.14),
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: durationMs == 0 ? null : _seek,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: AppTextStyles.caption(context).copyWith(
                          color: Colors.white60,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        duration == Duration.zero
                            ? 'ملف صوتي'
                            : _formatDuration(duration),
                        style: AppTextStyles.caption(context).copyWith(
                          color: Colors.white60,
                          fontWeight: FontWeight.w800,
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
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _AudioPlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _AudioPlayButton({
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.crimson.withValues(alpha: 0.95),
            AppColors.deepCrimson.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.28),
            blurRadius: 18,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(isPlaying),
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _AudienceEvidenceImage extends StatelessWidget {
  final String imagePath;

  const _AudienceEvidenceImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final frameWidth = screenSize.width * 0.94;
    final frameHeight = screenSize.height * 0.66;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.46),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: frameWidth,
              height: frameHeight,
              child: _EvidenceOverlayFrame(imagePath: imagePath),
            ),
          ),
          PositionedDirectional(
            start: AppSpacing.lg,
            end: AppSpacing.lg,
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
            child: _EvidenceMinimizeButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceMinimizeButton extends StatelessWidget {
  const _EvidenceMinimizeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF111015).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.crimson.withValues(alpha: 0.42),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppColors.crimson.withValues(alpha: 0.18),
                  blurRadius: 22,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                const Icon(
                  Icons.fullscreen_exit_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'تصغير الصورة',
                  style: AppTextStyles.buttonLabel(context).copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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

class _EvidenceStatusBadge extends StatelessWidget {
  final bool hasShownImage;

  const _EvidenceStatusBadge({required this.hasShownImage});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: hasShownImage
            ? AppColors.crimson.withValues(alpha: 0.82)
            : Colors.black.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: hasShownImage
              ? Colors.white.withValues(alpha: 0.2)
              : AppColors.crimson.withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(
              alpha: hasShownImage ? 0.32 : 0.16,
            ),
            blurRadius: hasShownImage ? 20 : 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            hasShownImage
                ? Icons.check_circle_rounded
                : Icons.open_in_full_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            hasShownImage ? 'جاهز للتفاصيل' : 'اعرض للاعبين',
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

class _EvidenceOverlayFrame extends StatelessWidget {
  final String imagePath;

  const _EvidenceOverlayFrame({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF070709).withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.crimson.withValues(alpha: 0.42),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.66),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: AppColors.crimson.withValues(alpha: 0.2),
                blurRadius: 28,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: Colors.black,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    boundaryMargin: const EdgeInsets.all(48),
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: SizedBox(
                          width: constraints.maxHeight,
                          height: constraints.maxWidth,
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EvidenceFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardDark,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        AppText.assetFallbackMessage,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySecondary(context).copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EvidenceDetailsBack extends StatelessWidget {
  final StageEntity stage;

  const _EvidenceDetailsBack({required this.stage});

  @override
  Widget build(BuildContext context) {
    return _GlassShell(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailHeader(stage: stage),
          const SizedBox(height: AppSpacing.md),
          _StageSection(
            title: AppText.stagePublicClueTitle,
            body: stage.publicClue,
            icon: Icons.visibility_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          _StageSection(
            title: AppText.stageHostNoteTitle,
            body: stage.hostNote ?? AppText.assetFallbackMessage,
            icon: Icons.sticky_note_2_rounded,
            tone: _StageSectionTone.gold,
          ),
          if (stage.hostScript != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _StageSection(
              title: AppText.stageHostScriptTitle,
              body: stage.hostScript!,
              icon: Icons.menu_book_rounded,
              tone: _StageSectionTone.dark,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _StageSection(
            title: AppText.stageFocusTitle,
            body: stage.expectedFocus,
            icon: Icons.center_focus_strong_rounded,
          ),
          if (stage.discussionSeconds <= 0) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              AppText.timerFallbackNote,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: Colors.white60,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final StageEntity stage;

  const _DetailHeader({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.deepCrimson.withValues(alpha: 0.74),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${stage.stageNumber}',
            style: AppTextStyles.sectionAmiriTitle(context).copyWith(
              color: Colors.white,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            stage.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionAmiriTitle(context).copyWith(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

enum _StageSectionTone { normal, gold, dark }

class _StageSection extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final _StageSectionTone tone;

  const _StageSection({
    required this.title,
    required this.body,
    required this.icon,
    this.tone = _StageSectionTone.normal,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (tone) {
      _StageSectionTone.gold => AppColors.goldSubtle.withValues(alpha: 0.8),
      _StageSectionTone.dark => const Color(0xFF151020).withValues(alpha: 0.86),
      _ => const Color(0xFF0F0B0D).withValues(alpha: 0.86),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.crimson, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.crimson,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyPrimary(context).copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipToggleButton extends StatefulWidget {
  final bool showingDetails;
  final bool hasShownImage;
  final VoidCallback onPressed;

  const _FlipToggleButton({
    required this.showingDetails,
    required this.hasShownImage,
    required this.onPressed,
  });

  @override
  State<_FlipToggleButton> createState() => _FlipToggleButtonState();
}

class _FlipToggleButtonState extends State<_FlipToggleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isReady = widget.hasShownImage || widget.showingDetails;
    final label = widget.showingDetails
        ? 'إخفاء تفاصيل الدليل'
        : widget.hasShownImage
            ? 'إظهار تفاصيل الدليل'
            : 'بعد عرض الصورة: افتح التفاصيل';

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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 52,
          decoration: BoxDecoration(
            color: isReady
                ? AppColors.deepCrimson
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isReady
                  ? Colors.white.withValues(alpha: 0.14)
                  : AppColors.crimson.withValues(alpha: 0.24),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.crimson.withValues(alpha: isReady ? 0.26 : 0.12),
                blurRadius: isReady ? 18 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                widget.showingDetails
                    ? Icons.visibility_off_rounded
                    : widget.hasShownImage
                        ? Icons.article_rounded
                        : Icons.lock_open_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.buttonLabel(context).copyWith(
                    color: Colors.white,
                    fontSize:
                        widget.hasShownImage || widget.showingDetails ? 16 : 14,
                    fontWeight: FontWeight.w800,
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

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({
    required this.remainingText,
    required this.isAtInitialDuration,
    required this.isRunning,
    required this.isWarning,
    required this.onStartOrResume,
    required this.onPause,
    required this.onReset,
  });

  final String remainingText;
  final bool isAtInitialDuration;
  final bool isRunning;
  final bool isWarning;
  final VoidCallback onStartOrResume;
  final VoidCallback onPause;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return _GlassShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(
            icon: Icons.timer_rounded,
            title: 'مؤقت الدليل',
            subtitle: 'ابدأ العد بعد ما كل اللاعبين يشوفوا الصورة.',
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  isWarning
                      ? AppColors.deepCrimson.withValues(alpha: 0.48)
                      : AppColors.deepCrimson.withValues(alpha: 0.22),
                  Colors.black.withValues(alpha: 0.28),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isWarning
                    ? AppColors.crimson.withValues(alpha: 0.58)
                    : AppColors.crimson.withValues(alpha: 0.26),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.crimson.withValues(
                    alpha: isWarning ? 0.24 : 0.12,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'الوقت المتبقي',
                  style: AppTextStyles.caption(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  remainingText,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.timerDisplay(context).copyWith(
                    color: isWarning ? AppColors.danger : Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: AppColors.crimson.withValues(
                          alpha: isWarning ? 0.76 : 0.38,
                        ),
                        blurRadius: isWarning ? 22 : 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isWarning) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppText.timerWarningLabel,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const _CrimsonDivider(),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _TimerActionChip(
                icon: isRunning
                    ? Icons.hourglass_bottom_rounded
                    : Icons.play_arrow_rounded,
                label: isRunning || isAtInitialDuration
                    ? AppText.timerStartAction
                    : AppText.timerResumeAction,
                onPressed: onStartOrResume,
              ),
              _TimerActionChip(
                icon: Icons.pause_rounded,
                label: AppText.timerPauseAction,
                isPrimary: false,
                onPressed: isRunning ? onPause : null,
              ),
              _TimerActionChip(
                icon: Icons.restart_alt_rounded,
                label: AppText.timerResetAction,
                isPrimary: false,
                onPressed: onReset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageActionsPanel extends StatelessWidget {
  final bool isReadOnly;
  final VoidCallback onBackToDashboard;

  const _StageActionsPanel({
    required this.isReadOnly,
    required this.onBackToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassShell(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StageActionKicker(
            icon: isReadOnly
                ? Icons.fact_check_rounded
                : Icons.how_to_vote_rounded,
            label: isReadOnly ? 'وضع المراجعة' : 'لوحة المضيف',
          ),
          const SizedBox(height: AppSpacing.sm),
          _StageSecondaryAction(
            icon: Icons.dashboard_customize_rounded,
            label: AppText.backToDashboardAction,
            onPressed: onBackToDashboard,
          ),
        ],
      ),
    );
  }
}

class _StageBottomCta extends StatelessWidget {
  final bool isReadOnly;
  final double bottomInset;
  final VoidCallback onPressed;

  const _StageBottomCta({
    required this.isReadOnly,
    required this.bottomInset,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xFF070709).withValues(alpha: 0.72),
                const Color(0xFF070709).withValues(alpha: 0.96),
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              bottomInset + AppSpacing.md,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070709).withValues(alpha: 0.66),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.crimson.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.42),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _StagePrimaryAction(
                    icon: isReadOnly
                        ? Icons.bar_chart_rounded
                        : Icons.how_to_vote_rounded,
                    label: isReadOnly
                        ? AppText.viewVoteResultAction
                        : AppText.goToVotingAction,
                    onPressed: onPressed,
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

class _StageActionKicker extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StageActionKicker({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: AppColors.deepCrimson.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.crimson.withValues(alpha: 0.26),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.86)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption(context).copyWith(
                color: Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.deepCrimson.withValues(alpha: 0.36),
              border: Border.all(
                color: AppColors.crimson.withValues(alpha: 0.36),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _TimerActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const _TimerActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  State<_TimerActionChip> createState() => _TimerActionChipState();
}

class _TimerActionChipState extends State<_TimerActionChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final foreground =
        isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.35);

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        child: AnimatedOpacity(
          opacity: isEnabled ? 1 : 0.56,
          duration: const Duration(milliseconds: 160),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: widget.isPrimary
                  ? AppColors.deepCrimson.withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: widget.isPrimary
                    ? AppColors.crimson.withValues(alpha: 0.52)
                    : Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: widget.isPrimary && isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 18, color: foreground),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  widget.label,
                  style: AppTextStyles.buttonLabel(context).copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
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

class _StagePrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _StagePrimaryAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _StageActionButton(
      icon: icon,
      label: label,
      isPrimary: true,
      onPressed: onPressed,
    );
  }
}

class _StageSecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _StageSecondaryAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _StageActionButton(
      icon: icon,
      label: label,
      isPrimary: false,
      onPressed: onPressed,
    );
  }
}

class _StageActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _StageActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isPrimary
              ? AppColors.deepCrimson
              : Colors.white.withValues(alpha: 0.06),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isPrimary
                  ? AppColors.crimson.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.rtl,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.buttonLabel(context).copyWith(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassShell({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
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
