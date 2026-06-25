import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_data.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class HostChecklistScreen extends StatefulWidget {
  const HostChecklistScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<HostChecklistScreen> createState() => _HostChecklistScreenState();
}

class _HostChecklistScreenState extends State<HostChecklistScreen> {
  final Set<String> _checkedItemIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupItems();
    final totalItems = HostPlaytestChecklist.items.length;
    final checkedCount = _checkedItemIds.length;

    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: Stack(
        children: [
          const _ChecklistBackdrop(),
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  MediaQuery.of(context).padding.top + 76,
                  AppSpacing.lg,
                  AppSpacing.huge,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    _ChecklistSummaryPanel(
                      checkedCount: checkedCount,
                      totalItems: totalItems,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final entry in groupedItems.entries) ...[
                      _ChecklistCategoryPanel(
                        category: entry.key,
                        items: entry.value,
                        checkedItemIds: _checkedItemIds,
                        onToggle: _toggleItem,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ]),
                ),
              ),
            ],
          ),
          _ChecklistAppBar(sessionId: widget.sessionId),
        ],
      ),
    );
  }

  Map<String, List<HostPlaytestChecklistItem>> _groupItems() {
    final groupedItems = <String, List<HostPlaytestChecklistItem>>{};
    for (final item in HostPlaytestChecklist.items) {
      groupedItems.putIfAbsent(
          item.category, () => <HostPlaytestChecklistItem>[]);
      groupedItems[item.category]!.add(item);
    }
    return groupedItems;
  }

  void _toggleItem(String itemId) {
    setState(() {
      if (!_checkedItemIds.add(itemId)) {
        _checkedItemIds.remove(itemId);
      }
    });
  }
}

class _ChecklistBackdrop extends StatelessWidget {
  const _ChecklistBackdrop();

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
            top: -80,
            left: -70,
            child: _GlowOrb(size: 190, alpha: 0.13),
          ),
          Positioned(
            bottom: 120,
            right: -90,
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

class _ChecklistAppBar extends StatelessWidget {
  final String sessionId;

  const _ChecklistAppBar({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: AppSpacing.md,
      right: AppSpacing.md,
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
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SizedBox(
              height: 46,
              child: Center(
                child: Text(
                  AppText.hostChecklistTitle,
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
            ),
          ),
          const SizedBox(width: 46 + AppSpacing.sm),
        ],
      ),
    );
  }
}

class _ChecklistSummaryPanel extends StatelessWidget {
  final int checkedCount;
  final int totalItems;

  const _ChecklistSummaryPanel({
    required this.checkedCount,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalItems == 0 ? 0.0 : checkedCount / totalItems;

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
                  Icons.fact_check_rounded,
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
                      'ملف مراجعة المضيف',
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.crimson,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$checkedCount من $totalItems بنود جاهزة',
                      style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.crimson.withValues(alpha: 0.9),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'راجع البنود قبل وأثناء الجلسة للحفاظ على الخصوصية وسلاسة اللعب.',
            style: AppTextStyles.caption(context).copyWith(
              color: Colors.white60,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCategoryPanel extends StatelessWidget {
  final String category;
  final List<HostPlaytestChecklistItem> items;
  final Set<String> checkedItemIds;
  final ValueChanged<String> onToggle;

  const _ChecklistCategoryPanel({
    required this.category,
    required this.items,
    required this.checkedItemIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final checkedCount =
        items.where((item) => checkedItemIds.contains(item.id)).length;

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CategoryHeader(
            category: category,
            checkedCount: checkedCount,
            totalCount: items.length,
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < items.length; index += 1) ...[
            _ChecklistItemCard(
              item: items[index],
              isChecked: checkedItemIds.contains(items[index].id),
              onTap: () => onToggle(items[index].id),
            ),
            if (index != items.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String category;
  final int checkedCount;
  final int totalCount;

  const _CategoryHeader({
    required this.category,
    required this.checkedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(_categoryIcon(category), color: Colors.white, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _categoryLabel(category),
                style: AppTextStyles.sectionAmiriTitle(context).copyWith(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$checkedCount/$totalCount تم فحصها',
                style: AppTextStyles.caption(context).copyWith(
                  color: Colors.white60,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _PriorityLegend(category: category),
      ],
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'Setup':
        return AppText.hostChecklistCategorySetup;
      case 'Privacy':
        return AppText.hostChecklistCategoryPrivacy;
      case 'Gameplay':
        return AppText.hostChecklistCategoryGameplay;
      default:
        return category;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Setup':
        return Icons.tune_rounded;
      case 'Privacy':
        return Icons.privacy_tip_rounded;
      case 'Gameplay':
        return Icons.sports_esports_rounded;
      default:
        return Icons.checklist_rounded;
    }
  }
}

class _PriorityLegend extends StatelessWidget {
  final String category;

  const _PriorityLegend({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        border: Border.all(color: AppColors.crimson.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category.toUpperCase(),
        style: AppTextStyles.caption(context).copyWith(
          color: Colors.white54,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ChecklistItemCard extends StatelessWidget {
  final HostPlaytestChecklistItem item;
  final bool isChecked;
  final VoidCallback onTap;

  const _ChecklistItemCard({
    required this.item,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = item.importance == 'P1';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isChecked
                ? AppColors.deepCrimson.withValues(alpha: 0.34)
                : const Color(0xFF0F0B0D).withValues(alpha: 0.86),
            border: Border.all(
              color: isChecked
                  ? AppColors.crimson.withValues(alpha: 0.52)
                  : AppColors.crimson.withValues(alpha: 0.18),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isChecked
                      ? AppColors.crimson
                      : Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isChecked
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppColors.crimson.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(
                  isChecked
                      ? Icons.check_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: Colors.white,
                  size: isChecked ? 18 : 15,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _ImportanceChip(
                          label: item.importance,
                          isCritical: isCritical,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      item.instructionAr,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodyPrimary(context).copyWith(
                        color: isChecked
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportanceChip extends StatelessWidget {
  final String label;
  final bool isCritical;

  const _ImportanceChip({required this.label, required this.isCritical});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isCritical
            ? AppColors.deepCrimson.withValues(alpha: 0.72)
            : AppColors.goldSubtle.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isCritical
              ? AppColors.crimson.withValues(alpha: 0.4)
              : AppColors.gold.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          color: Colors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w900,
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
