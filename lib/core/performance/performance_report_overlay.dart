import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import 'performance_monitor.dart';

class PerformanceReportOverlay extends StatelessWidget {
  const PerformanceReportOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!PerformanceMonitor.enabled) {
      return child;
    }

    return Stack(
      children: [
        child,
        PositionedDirectional(
          start: 10,
          bottom: 12,
          child: SafeArea(
            child: _PerformanceReportButton(
              onPressed: () => _copyReport(context),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _copyReport(BuildContext context) async {
    final report = PerformanceMonitor.instance.buildReport();
    await Clipboard.setData(ClipboardData(text: report));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('تم نسخ تقرير الأداء'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _PerformanceReportButton extends StatelessWidget {
  const _PerformanceReportButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.speed_rounded, size: 16),
        label: const Text('تقرير الأداء'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crimson.withValues(alpha: 0.92),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          elevation: 8,
          shadowColor: AppColors.crimson.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
