import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/case_entity.dart';
import '../../domain/entities/character_entity.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';

class CaseDetailsScreen extends StatefulWidget {
  const CaseDetailsScreen({super.key, required this.caseId});

  final String caseId;

  @override
  State<CaseDetailsScreen> createState() => _CaseDetailsScreenState();
}

class _CaseDetailsScreenState extends State<CaseDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameCubit>().loadCase(widget.caseId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      extendBodyBehindAppBar: true,
      body: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          final selectedCase = _findCase(state);
          final previewCharacters =
              state.casePreviewVariant?.caseId == widget.caseId
              ? state.casePreviewVariant!.characters
              : const <CharacterEntity>[];
          if (selectedCase == null) {
            return const Stack(
              children: [
                _DetailsBackdrop(child: Center(child: LoadingView())),
                _GlassBackButton(),
              ],
            );
          }

          return Stack(
            children: [
              _DetailsBackdrop(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CaseHero(
                        caseItem: selectedCase,
                        scrollController: _scrollController,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -34),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 18),
                                  child: child,
                                ),
                              );
                            },
                            child: _CaseContentPanel(
                              caseItem: selectedCase,
                              characters: previewCharacters,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const _GlassBackButton(),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _StickyStartBar(caseId: selectedCase.id),
              ),
            ],
          );
        },
      ),
    );
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

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton();

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
    );
  }
}

class _StickyStartBar extends StatelessWidget {
  final String caseId;

  const _StickyStartBar({required this.caseId});

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
        child: _StartCaseButton(caseId: caseId),
      ),
    );
  }
}

class _DetailsBackdrop extends StatelessWidget {
  final Widget child;

  const _DetailsBackdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepCrimson.withValues(alpha: 0.2),
            const Color(0xFF070709),
            const Color(0xFF070709),
          ],
          stops: const [0.0, 0.34, 1.0],
        ),
      ),
      child: child,
    );
  }
}

String _caseDossierCode(String caseId) {
  final match = RegExp(r'\d+').firstMatch(caseId);
  final number = match?.group(0)?.padLeft(2, '0') ?? '01';
  return 'CASE $number';
}

String _localizedDifficulty(String value) {
  return switch (value.toLowerCase().trim()) {
    'easy' => 'سهلة',
    'medium' => 'متوسطة',
    'hard' => 'صعبة',
    _ => value,
  };
}

class _CaseHero extends StatelessWidget {
  final CaseEntity caseItem;
  final ScrollController scrollController;

  const _CaseHero({required this.caseItem, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final heroHeight = MediaQuery.of(context).size.height * 0.58;

    return SizedBox(
      height: heroHeight.clamp(390.0, 560.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: scrollController,
            builder: (context, child) {
              final offset = scrollController.hasClients
                  ? scrollController.offset
                  : 0.0;
              final parallaxOffset = (offset * 0.16).clamp(0.0, 70.0);
              return Transform.translate(
                offset: Offset(0, parallaxOffset),
                child: child,
              );
            },
            child: Image.asset(
              caseItem.coverAssetPath,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.cardDark,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.textMuted,
                  size: 42,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF070709),
                    const Color(0xFF070709).withValues(alpha: 0.82),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.34, 0.86],
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
                _CaseStatusPill(
                  icon: Icons.folder_open_rounded,
                  label: '${_caseDossierCode(caseItem.id)} / جاهزة للعب',
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
                        color: Colors.red.shade900.withValues(alpha: 0.9),
                        blurRadius: 30,
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

class _CaseContentPanel extends StatelessWidget {
  final CaseEntity caseItem;
  final List<CharacterEntity> characters;

  const _CaseContentPanel({required this.caseItem, required this.characters});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (caseItem.durationMinutes != null)
                    _MetaBadge(
                      icon: Icons.timer_outlined,
                      label: '${caseItem.durationMinutes} دقيقة',
                    ),
                  if (caseItem.difficulty != null)
                    _MetaBadge(
                      icon: Icons.star_border_rounded,
                      label: _localizedDifficulty(caseItem.difficulty!),
                    ),
                  if (caseItem.minPlayers != null &&
                      caseItem.maxPlayers != null)
                    _MetaBadge(
                      icon: Icons.groups_rounded,
                      label:
                          '${caseItem.minPlayers}-${caseItem.maxPlayers} لاعبين',
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _CrimsonDivider(),
              const SizedBox(height: AppSpacing.lg),
              _FlipCaseInfoCard(
                summary: caseItem.summary,
                setting: caseItem.setting,
              ),
              if (characters.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                const _CrimsonDivider(),
                const SizedBox(height: AppSpacing.lg),
                _CharactersSection(characters: characters),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
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

class _FlipCaseInfoCard extends StatefulWidget {
  final String summary;
  final String? setting;

  const _FlipCaseInfoCard({required this.summary, required this.setting});

  @override
  State<_FlipCaseInfoCard> createState() => _FlipCaseInfoCardState();
}

class _FlipCaseInfoCardState extends State<_FlipCaseInfoCard> {
  bool _showBack = false;

  void _toggleSide() {
    if (widget.setting == null || widget.setting!.trim().isEmpty) {
      return;
    }
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    final hasBack = widget.setting != null && widget.setting!.trim().isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hasBack ? _toggleSide : null,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: _showBack ? math.pi : 0),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
        builder: (context, angle, child) {
          final isBack = angle > math.pi / 2;
          final displayAngle = isBack ? angle + math.pi : angle;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(displayAngle),
            child: _FlipFace(
              icon: isBack
                  ? Icons.location_on_outlined
                  : Icons.article_outlined,
              title: isBack ? 'مكان الأحداث' : 'ملخص القضية',
              body: isBack ? widget.setting! : widget.summary,
              hint: hasBack
                  ? (isBack
                        ? 'اضغط على الكارت للرجوع إلى ملخص القضية'
                        : 'اضغط على الكارت عشان تعرف مكان الأحداث')
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _FlipFace extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? hint;

  const _FlipFace({
    required this.icon,
    required this.title,
    required this.body,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 230, maxHeight: 330),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.62),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.crimson.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.crimson, size: 19),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.14),
                  border: Border.all(
                    color: AppColors.crimson.withValues(alpha: 0.3),
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rotate_90_degrees_ccw_rounded,
                  color: Colors.white70,
                  size: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                body,
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyPrimary(context).copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  height: 1.65,
                ),
              ),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white.withValues(alpha: 0.72),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    hint!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CharactersSection extends StatelessWidget {
  final List<CharacterEntity> characters;

  const _CharactersSection({required this.characters});

  @override
  Widget build(BuildContext context) {
    final orderedCharacters = [...characters]
      ..sort((left, right) => left.displayOrder.compareTo(right.displayOrder));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'شخصيات القضية',
              style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: orderedCharacters.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              return _CharacterPreviewCard(character: orderedCharacters[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _CaseStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CaseStatusPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return _BadgeShell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return _BadgeShell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.crimson, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CharacterPreviewCard extends StatelessWidget {
  final CharacterEntity character;

  const _CharacterPreviewCard({required this.character});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xFF070709).withValues(alpha: 0.48),
          border: Border.all(color: AppColors.crimson.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SizedBox.square(
                dimension: 78,
                child: Image.asset(
                  character.portraitAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.cardDark,
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              character.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
            if (character.title != null && character.title!.trim().isNotEmpty)
              Text(
                character.title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(context).copyWith(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgeShell extends StatelessWidget {
  final Widget child;

  const _BadgeShell({required this.child});

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
          child: child,
        ),
      ),
    );
  }
}

class _StartCaseButton extends StatefulWidget {
  final String caseId;

  const _StartCaseButton({required this.caseId});

  @override
  State<_StartCaseButton> createState() => _StartCaseButtonState();
}

class _StartCaseButtonState extends State<_StartCaseButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        context.read<GameCubit>().playUiTap();
        context.goNamed(
          AppRoutes.setupGame.name,
          pathParameters: {'caseId': widget.caseId},
        );
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.deepCrimson,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: _isPressed ? 0.36 : 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.crimson.withValues(
                  alpha: _isPressed ? 0.42 : 0.28,
                ),
                blurRadius: _isPressed ? 28 : 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow_rounded, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppText.continueToSetup,
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
