import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mafmof/app/router/app_routes.dart';
import 'package:mafmof/core/constants/app_text.dart';
import 'package:mafmof/features/game/presentation/screens/host_dashboard_screen.dart';

import '../../../support/test_game_harness.dart';

void main() {
  late TestGameHarness harness;

  setUp(() async {
    harness = await TestGameHarness.create();
    await harness.prepareVariant(5);
    await harness.startSession(const ['أحمد', 'سارة', 'ليلى', 'كريم', 'نهى']);
    await harness.completeRoleReveal();
  });

  tearDown(() async {
    await harness.dispose();
  });

  testWidgets('dashboard opens stages and restart clears the active session',
      (tester) async {
    final sessionId = harness.cubit.state.activeSession!.sessionId;
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) =>
              HostDashboardScreen(sessionId: sessionId),
        ),
        GoRoute(
          name: AppRoutes.stage.name,
          path: AppRoutes.stage.path,
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text('stage:${state.pathParameters['stageNumber']}'),
            ),
          ),
        ),
        GoRoute(
          name: AppRoutes.setupGame.name,
          path: AppRoutes.setupGame.path,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('setup-screen')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      BlocProvider.value(
        value: harness.cubit,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppText.hostDashboardTitle), findsOneWidget);

    await tester.tap(find.byKey(const Key('stage-button-1')));
    await tester.pumpAndSettle();
    expect(find.text('stage:1'), findsOneWidget);

    router.go('/dashboard');
    await tester.pumpAndSettle();

    final restartButton = find.text(AppText.restartSessionAction);
    await tester.scrollUntilVisible(
      restartButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(restartButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppText.confirmRestartAction));
    await tester.pumpAndSettle();

    expect(find.text('setup-screen'), findsOneWidget);
    expect(harness.cubit.state.activeSession, isNull);
  });
}
