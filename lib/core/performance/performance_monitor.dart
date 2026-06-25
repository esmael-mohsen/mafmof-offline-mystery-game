import 'dart:collection';

import 'package:flutter/scheduler.dart';

class PerformanceMonitor {
  PerformanceMonitor._();

  static final PerformanceMonitor instance = PerformanceMonitor._();

  static const bool enabled = false;
  static const String buildLabel = '1.0.0+6';

  final Map<String, _RouteFrameStats> _routeStats =
      <String, _RouteFrameStats>{};
  final List<_RouteVisit> _routeVisits = <_RouteVisit>[];
  final DateTime _startedAt = DateTime.now();

  String _currentRoute = 'AppStart';
  bool _isStarted = false;

  void start() {
    if (!enabled || _isStarted) {
      return;
    }
    _isStarted = true;
    SchedulerBinding.instance.addTimingsCallback(_recordFrameTimings);
    markRoute(_currentRoute);
  }

  void markRoute(String routeName) {
    if (!enabled) {
      return;
    }
    final normalizedName = routeName.trim().isEmpty ? 'Unknown' : routeName;
    if (_currentRoute == normalizedName && _routeVisits.isNotEmpty) {
      return;
    }
    _currentRoute = normalizedName;
    _routeStats.putIfAbsent(_currentRoute, _RouteFrameStats.new);
    _routeVisits.add(_RouteVisit(_currentRoute, DateTime.now()));
  }

  String buildReport() {
    final buffer = StringBuffer()
      ..writeln('MAFMOF PERFORMANCE REPORT')
      ..writeln('Build: $buildLabel')
      ..writeln('Started: ${_startedAt.toIso8601String()}')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('Current route: $_currentRoute')
      ..writeln('')
      ..writeln('HOW TO READ')
      ..writeln('- Build high = widgets/layout/state work is heavy.')
      ..writeln('- Raster high = painting/GPU/images/blur/shadows are heavy.')
      ..writeln('- Slow16 is frames over 16ms; Slow32 is visibly bad jank.')
      ..writeln('')
      ..writeln('ROUTE SUMMARY');

    final sortedStats =
        SplayTreeMap<String, _RouteFrameStats>.from(_routeStats);
    if (sortedStats.isEmpty) {
      buffer.writeln('No frame timings recorded yet.');
    } else {
      for (final entry in sortedStats.entries) {
        buffer
          ..writeln('')
          ..writeln(entry.key)
          ..writeln(entry.value.toReportLine());
      }
    }

    buffer
      ..writeln('')
      ..writeln('ROUTE VISITS');

    for (final visit in _routeVisits.take(30)) {
      buffer.writeln('- ${visit.time.toIso8601String()}  ${visit.routeName}');
    }

    if (_routeVisits.length > 30) {
      buffer.writeln('- ... ${_routeVisits.length - 30} more visits');
    }

    return buffer.toString();
  }

  void reset() {
    _routeStats.clear();
    _routeVisits.clear();
    markRoute(_currentRoute);
  }

  void _recordFrameTimings(List<FrameTiming> timings) {
    final stats = _routeStats.putIfAbsent(_currentRoute, _RouteFrameStats.new);
    for (final timing in timings) {
      stats.add(timing);
    }
  }
}

class _RouteFrameStats {
  int frameCount = 0;
  int slowOver16Ms = 0;
  int slowOver32Ms = 0;
  int buildHeavyFrames = 0;
  int rasterHeavyFrames = 0;
  int balancedHeavyFrames = 0;

  Duration totalBuild = Duration.zero;
  Duration totalRaster = Duration.zero;
  Duration totalFrame = Duration.zero;
  Duration worstBuild = Duration.zero;
  Duration worstRaster = Duration.zero;
  Duration worstFrame = Duration.zero;

  void add(FrameTiming timing) {
    final build = timing.buildDuration;
    final raster = timing.rasterDuration;
    final frame = build + raster;

    frameCount++;
    totalBuild += build;
    totalRaster += raster;
    totalFrame += frame;

    if (build > worstBuild) {
      worstBuild = build;
    }
    if (raster > worstRaster) {
      worstRaster = raster;
    }
    if (frame > worstFrame) {
      worstFrame = frame;
    }

    if (frame.inMicroseconds > 16000) {
      slowOver16Ms++;
    }
    if (frame.inMicroseconds > 32000) {
      slowOver32Ms++;
    }

    if (frame.inMicroseconds > 16000) {
      final buildMicros = build.inMicroseconds;
      final rasterMicros = raster.inMicroseconds;
      if (buildMicros > rasterMicros * 1.25) {
        buildHeavyFrames++;
      } else if (rasterMicros > buildMicros * 1.25) {
        rasterHeavyFrames++;
      } else {
        balancedHeavyFrames++;
      }
    }
  }

  String toReportLine() {
    if (frameCount == 0) {
      return 'Frames: 0';
    }

    final avgBuild = totalBuild.inMicroseconds / frameCount / 1000;
    final avgRaster = totalRaster.inMicroseconds / frameCount / 1000;
    final avgFrame = totalFrame.inMicroseconds / frameCount / 1000;
    final slow16Percent = slowOver16Ms / frameCount * 100;
    final slow32Percent = slowOver32Ms / frameCount * 100;
    final diagnosis = _diagnosis();

    return [
      'Frames: $frameCount',
      'Slow16: $slowOver16Ms (${slow16Percent.toStringAsFixed(1)}%)',
      'Slow32: $slowOver32Ms (${slow32Percent.toStringAsFixed(1)}%)',
      'Avg build: ${avgBuild.toStringAsFixed(2)}ms',
      'Avg raster: ${avgRaster.toStringAsFixed(2)}ms',
      'Avg frame: ${avgFrame.toStringAsFixed(2)}ms',
      'Worst build: ${_ms(worstBuild)}',
      'Worst raster: ${_ms(worstRaster)}',
      'Worst frame: ${_ms(worstFrame)}',
      'Heavy: build=$buildHeavyFrames raster=$rasterHeavyFrames balanced=$balancedHeavyFrames',
      'Diagnosis: $diagnosis',
    ].join('\n');
  }

  String _diagnosis() {
    if (frameCount < 20) {
      return 'Need more interaction on this screen.';
    }
    if (slowOver16Ms == 0) {
      return 'Looks smooth in this sample.';
    }
    if (rasterHeavyFrames > buildHeavyFrames * 1.4) {
      return 'Raster-heavy jank. Check blur, shadows, clipping, images, and GPU paint cost.';
    }
    if (buildHeavyFrames > rasterHeavyFrames * 1.4) {
      return 'Build-heavy jank. Check rebuilds, layout, state updates, and large widget trees.';
    }
    return 'Mixed jank. Check both build/layout and paint/GPU work.';
  }

  String _ms(Duration duration) {
    return '${(duration.inMicroseconds / 1000).toStringAsFixed(2)}ms';
  }
}

class _RouteVisit {
  const _RouteVisit(this.routeName, this.time);

  final String routeName;
  final DateTime time;
}
