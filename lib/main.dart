import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/performance/performance_monitor.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PerformanceMonitor.instance.start();
  configureDependencies();
  runApp(const MafmofApp());
}
