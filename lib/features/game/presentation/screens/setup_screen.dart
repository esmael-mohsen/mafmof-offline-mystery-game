import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/case_entity.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.caseId});

  final String caseId;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final List<TextEditingController> _playerNameControllers =
      <TextEditingController>[];
  int? _lastPreparedCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameCubit>().loadCase(widget.caseId);
    });
  }

  @override
  void dispose() {
    for (final controller in _playerNameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: BlocConsumer<GameCubit, GameState>(
        listenWhen: (previous, current) =>
            previous.selectedPlayerCount != current.selectedPlayerCount,
        listener: (context, state) {
          _syncPlayerControllers(state.selectedPlayerCount ?? 0);
        },
        builder: (context, state) {
          final selectedCase = _findCase(state);
          if (selectedCase == null) {
            return const Stack(
              children: [
                _SetupBackdrop(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.crimson),
                  ),
                ),
                _SetupBackButton(),
              ],
            );
          }

          return Stack(
            children: [
              _SetupBackdrop(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 112),
                  children: [
                    _SetupHero(caseItem: selectedCase),
                    Transform.translate(
                      offset: const Offset(0, -34),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: _SetupPanel(
                          caseItem: selectedCase,
                          state: state,
                          playerSlots: _buildPlayerSlotsGrid(),
                          onSelectCount: (count) => context
                              .read<GameCubit>()
                              .prepareVariantForSetup(widget.caseId, count),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _SetupBackButton(),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _StickyStartBar(
                  enabled: state.preparedVariant != null,
                  onPressed: state.preparedVariant == null
                      ? null
                      : () => _startSession(context, state),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerSlotsGrid() {
    return _EvidenceBoard(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.sm) / 2;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.md,
          children: [
            for (var index = 0;
                index < _playerNameControllers.length;
                index += 1)
              SizedBox(
                width: itemWidth,
                child: _EvidencePlayerSlotCard(
                  index: index,
                  controller: _playerNameControllers[index],
                  isLast: index == _playerNameControllers.length - 1,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _startSession(BuildContext context, GameState state) async {
    final playerCount = state.selectedPlayerCount;
    if (playerCount == null) {
      return;
    }

    final sessionId = await context.read<GameCubit>().startSession(
          caseId: widget.caseId,
          playerCount: playerCount,
          playerNames: _playerNameControllers
              .map((controller) => controller.text)
              .toList(growable: false),
        );

    if (!context.mounted || sessionId == null) {
      return;
    }

    context.read<GameCubit>().playUiTap();
    context.goNamed(
      AppRoutes.roleReveal.name,
      pathParameters: {'sessionId': sessionId},
    );
  }

  void _syncPlayerControllers(int targetCount) {
    if (_lastPreparedCount == targetCount) {
      return;
    }
    _lastPreparedCount = targetCount;

    if (targetCount < _playerNameControllers.length) {
      final removed = _playerNameControllers.sublist(targetCount).toList();
      _playerNameControllers.removeRange(
        targetCount,
        _playerNameControllers.length,
      );
      for (final controller in removed) {
        controller.dispose();
      }
    } else {
      while (_playerNameControllers.length < targetCount) {
        _playerNameControllers.add(TextEditingController());
      }
    }
    setState(() {});
  }

  CaseEntity? _findCase(GameState state) {
    if (state.selectedCase?.id == widget.caseId) {
      return state.selectedCase;
    }

    for (final item in state.availableCases) {
      if (item.id == widget.caseId) {
        return item;
      }
    }

    return null;
  }
}

class _SetupBackdrop extends StatelessWidget {
  final Widget child;

  const _SetupBackdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepCrimson.withValues(alpha: 0.22),
            const Color(0xFF070709),
            const Color(0xFF070709),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class _SetupBackButton extends StatelessWidget {
  const _SetupBackButton();

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: MediaQuery.of(context).padding.top + 12,
      start: AppSpacing.md,
      child: ClipOval(
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
                context.goNamed(
                  AppRoutes.caseDetails.name,
                  pathParameters: {'caseId': _caseIdFromPath(context)},
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
      ),
    );
  }
}

String _caseIdFromPath(BuildContext context) {
  return GoRouterState.of(context).pathParameters['caseId'] ??
      'case01_farah_eltagamoa';
}

class _SetupHero extends StatelessWidget {
  final CaseEntity caseItem;

  const _SetupHero({required this.caseItem});

  @override
  Widget build(BuildContext context) {
    final heroHeight = MediaQuery.of(context).size.height * 0.58;

    return SizedBox(
      height: heroHeight.clamp(390.0, 560.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            caseItem.coverAssetPath,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => Container(color: AppColors.cardDark),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF070709),
                    const Color(0xFF070709).withValues(alpha: 0.78),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: 92,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SetupPill(
                  icon: Icons.tune_rounded,
                  label: AppText.setupTitle,
                ),
                const SizedBox(height: AppSpacing.sm * 5),
                Text(
                  caseItem.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heroSignatureTitle(context).copyWith(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Colors.red.shade900.withValues(alpha: 0.8),
                        blurRadius: 26,
                      ),
                    ],
                  ),
                ),
                if (caseItem.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm * 3),
                  Text(
                    caseItem.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupPanel extends StatelessWidget {
  final CaseEntity caseItem;
  final GameState state;
  final Widget playerSlots;
  final ValueChanged<int> onSelectCount;

  const _SetupPanel({
    required this.caseItem,
    required this.state,
    required this.playerSlots,
    required this.onSelectCount,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            icon: Icons.groups_rounded,
            title: AppText.selectPlayerCount,
            subtitle: 'اختار عدد اللاعبين المناسب للقضية',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final count in caseItem.supportedPlayerCounts)
                _PlayerCountTape(
                  count: count,
                  isSelected: state.selectedPlayerCount == count,
                  onTap: () => onSelectCount(count),
                ),
            ],
          ),
          if (state.preparedVariant != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const _CrimsonDivider(),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(
              icon: Icons.badge_outlined,
              title: AppText.playerNamesTitle,
              subtitle: 'اكتب أسماء اللاعبين بالترتيب قبل كشف الأدوار',
            ),
            const SizedBox(height: AppSpacing.md),
            playerSlots,
          ],
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ErrorBanner(message: state.errorMessage!),
          ],
        ],
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
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: const Color(0xFF070709).withValues(alpha: 0.62),
            border: Border.all(
              color: AppColors.crimson.withValues(alpha: 0.28),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.crimson.withValues(alpha: 0.12),
                blurRadius: 34,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
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
        const SizedBox(width: 8),
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

class _PlayerCountTape extends StatelessWidget {
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlayerCountTape({
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 66,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.deepCrimson
              : const Color(0xFF070709).withValues(alpha: 0.48),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.26)
                : AppColors.crimson.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.28),
                    blurRadius: 18,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                color: Colors.white,
                fontSize: 28,
                height: 0.9,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'لاعبين',
              style: AppTextStyles.caption(context).copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceBoard extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)
      builder;

  const _EvidenceBoard({required this.builder});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: CustomPaint(
        painter: _EvidenceBoardPainter(),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFF0B090A).withValues(alpha: 0.66),
            border: Border.all(
              color: AppColors.crimson.withValues(alpha: 0.26),
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(builder: builder),
        ),
      ),
    );
  }
}

class _EvidenceBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.crimson.withValues(alpha: 0.18)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final glowPaint = Paint()
      ..color = AppColors.crimson.withValues(alpha: 0.06)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()
      ..color = AppColors.crimson.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    final points = <Offset>[
      Offset(size.width * 0.18, size.height * 0.18),
      Offset(size.width * 0.74, size.height * 0.13),
      Offset(size.width * 0.86, size.height * 0.52),
      Offset(size.width * 0.35, size.height * 0.88),
      Offset(size.width * 0.10, size.height * 0.58),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 3.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EvidencePlayerSlotCard extends StatefulWidget {
  final int index;
  final TextEditingController controller;
  final bool isLast;

  const _EvidencePlayerSlotCard({
    required this.index,
    required this.controller,
    required this.isLast,
  });

  @override
  State<_EvidencePlayerSlotCard> createState() =>
      _EvidencePlayerSlotCardState();
}

class _EvidencePlayerSlotCardState extends State<_EvidencePlayerSlotCard> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleNameChanged);
  }

  @override
  void didUpdateWidget(covariant _EvidencePlayerSlotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleNameChanged);
      widget.controller.addListener(_handleNameChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleNameChanged);
    super.dispose();
  }

  void _handleNameChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasName = widget.controller.text.trim().isNotEmpty;
    final rotation = widget.index.isEven ? -0.01 : 0.01;

    return Transform.rotate(
      angle: rotation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 10),
        decoration: BoxDecoration(
          color: hasName
              ? const Color(0xFF161011).withValues(alpha: 0.96)
              : const Color(0xFFE8E0D1).withValues(alpha: 0.92),
          border: Border.all(
            color: hasName
                ? AppColors.crimson.withValues(alpha: 0.64)
                : Colors.white.withValues(alpha: 0.18),
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.36),
              blurRadius: 12,
              offset: const Offset(0, 7),
            ),
            if (hasName)
              BoxShadow(
                color: AppColors.crimson.withValues(alpha: 0.24),
                blurRadius: 18,
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 38,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.deepCrimson.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.crimson.withValues(alpha: 0.24),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
            Container(
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasName
                    ? AppColors.crimson.withValues(alpha: 0.13)
                    : const Color(0xFF191112).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasName
                      ? AppColors.crimson.withValues(alpha: 0.36)
                      : Colors.black.withValues(alpha: 0.22),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.person_search_rounded,
                    color: Colors.white.withValues(alpha: hasName ? 0.2 : 0.3),
                    size: 34,
                  ),
                  PositionedDirectional(
                    top: 7,
                    start: 8,
                    child: Text(
                      'P-${widget.index + 1}'.padLeft(4, '0'),
                      style: AppTextStyles.caption(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: 6,
                    end: 7,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: hasName
                          ? const Icon(
                              Icons.check_circle_rounded,
                              key: ValueKey('ready'),
                              color: AppColors.crimson,
                              size: 17,
                            )
                          : Icon(
                              Icons.radio_button_unchecked_rounded,
                              key: const ValueKey('empty'),
                              color: Colors.white.withValues(alpha: 0.45),
                              size: 17,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasName ? 'جاهز للكشف' : 'مجهول',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color: hasName
                    ? Colors.white.withValues(alpha: 0.78)
                    : const Color(0xFF241719).withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: widget.controller,
              textAlign: TextAlign.center,
              textInputAction:
                  widget.isLast ? TextInputAction.done : TextInputAction.next,
              style: AppTextStyles.bodyPrimary(context).copyWith(
                color: hasName ? Colors.white : const Color(0xFF1F1718),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: AppText.playerNameHint,
                isDense: true,
                filled: true,
                fillColor: hasName
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.42),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerSlotCard extends StatefulWidget {
  final int index;
  final TextEditingController controller;
  final bool isLast;

  const _PlayerSlotCard({
    required this.index,
    required this.controller,
    required this.isLast,
  });

  @override
  State<_PlayerSlotCard> createState() => _PlayerSlotCardState();
}

class _PlayerSlotCardState extends State<_PlayerSlotCard> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleNameChanged);
  }

  @override
  void didUpdateWidget(covariant _PlayerSlotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleNameChanged);
      widget.controller.addListener(_handleNameChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleNameChanged);
    super.dispose();
  }

  void _handleNameChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasName = widget.controller.text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFF070709).withValues(alpha: 0.48),
        border: Border.all(
          color: hasName
              ? AppColors.crimson.withValues(alpha: 0.55)
              : AppColors.crimson.withValues(alpha: 0.22),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: hasName
            ? [
                BoxShadow(
                  color: AppColors.crimson.withValues(alpha: 0.16),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.14),
                  border: Border.all(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${widget.index + 1}'.padLeft(2, '0'),
                  style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'لاعب ${widget.index + 1}',
                  style: AppTextStyles.caption(context).copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: hasName
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('ready'),
                        color: AppColors.crimson,
                        size: 20,
                      )
                    : Icon(
                        Icons.person_outline_rounded,
                        key: const ValueKey('empty'),
                        color: Colors.white.withValues(alpha: 0.45),
                        size: 20,
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: widget.controller,
            textInputAction:
                widget.isLast ? TextInputAction.done : TextInputAction.next,
            style: AppTextStyles.bodyPrimary(context)
                .copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: AppText.playerNameHint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.deepCrimson.withValues(alpha: 0.18),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySecondary(
          context,
        ).copyWith(color: Colors.white70),
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
            AppColors.crimson.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.22),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _SetupPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SetupPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF070709).withValues(alpha: 0.5),
            border: Border.all(color: AppColors.crimson.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.crimson, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.caption(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyStartBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onPressed;

  const _StickyStartBar({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF070709).withValues(alpha: 0.82),
            const Color(0xFF070709),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: _StartSessionButton(enabled: enabled, onPressed: onPressed),
      ),
    );
  }
}

class _StartSessionButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback? onPressed;

  const _StartSessionButton({required this.enabled, required this.onPressed});

  @override
  State<_StartSessionButton> createState() => _StartSessionButtonState();
}

class _StartSessionButtonState extends State<_StartSessionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel:
          widget.enabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 56,
          decoration: BoxDecoration(
            color: widget.enabled ? AppColors.deepCrimson : AppColors.disabled,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: _isPressed ? 0.36 : 0.16),
            ),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: AppColors.crimson.withValues(
                        alpha: _isPressed ? 0.42 : 0.28,
                      ),
                      blurRadius: _isPressed ? 28 : 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow_rounded, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppText.startSessionAction,
                style: AppTextStyles.buttonLabel(context).copyWith(
                  color: Colors.white,
                  fontSize: 16,
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
