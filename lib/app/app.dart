import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/performance/performance_report_overlay.dart';
import '../features/game/presentation/cubit/game_cubit.dart';
import '../features/game/presentation/widgets/host_hint_overlay.dart';
import 'di/injection.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MafmofApp extends StatelessWidget {
  const MafmofApp({super.key});

  @override
  Widget build(BuildContext context) {
    configureDependencies();

    return BlocProvider(
      create: (_) => getIt<GameCubit>(),
      child: MaterialApp.router(
        title: 'MafMof',
        theme: AppTheme.dark(),
        debugShowCheckedModeBanner: false,
        routerConfig: getIt<AppRouter>().router,
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: HostHintOverlay(
              child: PerformanceReportOverlay(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}
