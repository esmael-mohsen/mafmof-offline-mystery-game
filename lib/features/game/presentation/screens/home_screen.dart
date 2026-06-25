import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_media.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/case_entity.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameCubit>().bootstrap();
    });

    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: _isScrolled
              ? Colors.black.withValues(alpha: 0.85)
              : Colors.transparent,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _isScrolled ? 15.0 : 0.0,
                sigmaY: _isScrolled ? 15.0 : 0.0,
              ),
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: Image.asset(
                    AppMedia.logoPath,
                    height: 65,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.games,
                      color: AppColors.crimson,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const _HomeBackdrop(
              child: Center(
                child: LoadingView(message: AppText.catalogLoading),
              ),
            );
          }
          if (!state.canEnterCases && state.errorMessage != null) {
            return _HomeBackdrop(
              child: _CinematicMessageState(
                icon: Icons.folder_off_rounded,
                title: 'تعذر فتح القضايا',
                message: state.errorMessage!,
                actionLabel: AppText.retryCatalog,
                onAction: state.canRetryCatalogLoad
                    ? () =>
                          context.read<GameCubit>().retryCatalogInitialization()
                    : null,
              ),
            );
          }

          final topCases = state.availableCases.take(3).toList();
          final allCases = state.availableCases;

          if (allCases.isEmpty) {
            return const _HomeBackdrop(
              child: _CinematicMessageState(
                icon: Icons.folder_open_rounded,
                title: 'لا توجد قضايا متاحة',
                message: 'ارجع لاحقا بعد إضافة قضايا جديدة.',
              ),
            );
          }

          return _HomeBackdrop(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                if (topCases.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _HeroSlider(topCases: topCases)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.xl + 10,
                        AppSpacing.xl,
                        AppSpacing.md,
                      ),
                      child: _CasesSectionHeader(caseCount: allCases.length),
                    ),
                  ),
                ],
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 500,
                          mainAxisSpacing: 22.0,
                          crossAxisSpacing: 22.0,
                          childAspectRatio: 1.55,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = allCases[index];
                      return _CinematicCard(caseItem: item);
                    }, childCount: allCases.length),
                  ),
                ),
                if (state.errorMessage != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: _InlineErrorBanner(message: state.errorMessage!),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeBackdrop extends StatelessWidget {
  final Widget child;

  const _HomeBackdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepCrimson.withValues(alpha: 0.18),
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

class _CasesSectionHeader extends StatelessWidget {
  final int caseCount;

  const _CasesSectionHeader({required this.caseCount});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF070709).withValues(alpha: 0.42),
            border: Border.all(
              color: AppColors.crimson.withValues(alpha: 0.22),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder_rounded,
                color: const Color.fromARGB(255, 140, 19, 30),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'جميع القضايا',
                  style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                  ),
                ),
              ),
              _CountChip(label: '$caseCount قضايا'),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;

  const _CountChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.crimson.withValues(alpha: 0.16),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.34)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(
          context,
        ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CinematicMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CinematicMessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 42),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary(
                context,
              ).copyWith(color: Colors.white70),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  final String message;

  const _InlineErrorBanner({required this.message});

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

class _HeroSlider extends StatefulWidget {
  final List<CaseEntity> topCases;
  const _HeroSlider({required this.topCases});

  @override
  State<_HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<_HeroSlider> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Large banner size
    final height = MediaQuery.of(context).size.height * 0.55;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) {
              setState(() {
                _currentIndex = idx;
              });
            },
            itemCount: widget.topCases.length,
            itemBuilder: (context, index) {
              final caseItem = widget.topCases[index];
              return GestureDetector(
                onTap: () {
                  context.read<GameCubit>().playUiTap();
                  context.goNamed(
                    AppRoutes.caseDetails.name,
                    pathParameters: {'caseId': caseItem.id},
                  );
                },
                child: AnimatedScale(
                  scale: _currentIndex == index ? 1.0 : 0.95,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        caseItem.coverAssetPath,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppColors.cardDark),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                const Color(0xFF070709),
                                const Color(0xFF070709).withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.3, 0.8],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 54,
                        left: 20,
                        right: 20,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              caseItem.title,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.heroSignatureTitle(context)
                                  .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 34,
                                    shadows: [
                                      Shadow(
                                        color: Colors.red.shade900.withValues(
                                          alpha: 0.9,
                                        ),
                                        blurRadius: 30,
                                      ),
                                    ],
                                  ),
                            ),
                            if (caseItem.subtitle.trim().isNotEmpty) ...[
                              const SizedBox(height: 15),
                              Text(
                                caseItem.subtitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.sectionAmiriTitle(context)
                                    .copyWith(
                                      color: Colors.grey.withValues(
                                        alpha: 0.78,
                                      ),
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
                ),
              );
            },
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.topCases.length, (index) {
                final isSelected = index == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSelected ? 34 : 14,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.deepCrimson
                        : Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.crimson.withValues(alpha: 0.38),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _CinematicCard extends StatefulWidget {
  final CaseEntity caseItem;
  const _CinematicCard({required this.caseItem});

  @override
  State<_CinematicCard> createState() => _CinematicCardState();
}

class _CinematicCardState extends State<_CinematicCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        context.read<GameCubit>().playUiTap();
        context.goNamed(
          AppRoutes.caseDetails.name,
          pathParameters: {'caseId': widget.caseItem.id},
        );
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isPressed
                  ? AppColors.crimson.withValues(alpha: 0.75)
                  : AppColors.crimson.withValues(alpha: 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.crimson.withValues(alpha: 0.14),
                blurRadius: _isPressed ? 42 : 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  widget.caseItem.coverAssetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade900),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF070709).withValues(alpha: 0.95),
                          const Color(0xFF070709).withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.48, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.bottomCenter,
                        radius: 1.05,
                        colors: [
                          AppColors.crimson.withValues(alpha: 0.28),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.72],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    children: [
                      if (widget.caseItem.durationMinutes != null)
                        _InfoBadge(
                          icon: Icons.timer_outlined,
                          label: '${widget.caseItem.durationMinutes} دقيقة',
                        ),
                      const Spacer(),
                      if (widget.caseItem.difficulty != null)
                        _InfoBadge(
                          icon: Icons.star_border_rounded,
                          label: widget.caseItem.difficulty!,
                        ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 18,
                  left: 18,
                  right: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.caseItem.title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heroSignatureTitle(context)
                            .copyWith(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                const Shadow(
                                  color: Colors.black,
                                  blurRadius: 6,
                                ),
                                Shadow(
                                  color: Colors.red.shade900.withValues(
                                    alpha: 0.55,
                                  ),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF070709).withValues(alpha: 0.42),
            border: Border.all(
              color: AppColors.crimson.withValues(alpha: 0.28),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.crimson),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: Colors.white70, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
