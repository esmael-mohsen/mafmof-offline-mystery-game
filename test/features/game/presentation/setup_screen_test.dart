import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mafmof/app/router/app_routes.dart';
import 'package:mafmof/app/theme/app_theme.dart';
import 'package:mafmof/core/constants/app_text.dart';
import 'package:mafmof/features/game/presentation/screens/setup_screen.dart';

import '../../../support/test_game_harness.dart';

void main() {
  testWidgets('renders cinematic setup and starts a session', (tester) async {
    final harness = await TestGameHarness.create();
    addTearDown(harness.dispose);

    final router = GoRouter(
      initialLocation: '/case/case01_farah_eltagamoa/setup',
      routes: [
        GoRoute(
          name: AppRoutes.caseDetails.name,
          path: AppRoutes.caseDetails.path,
          builder: (_, __) => const Text('case-details'),
          routes: [
            GoRoute(
              name: AppRoutes.setupGame.name,
              path: 'setup',
              builder: (_, state) => SetupScreen(
                caseId: state.pathParameters['caseId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          name: AppRoutes.roleReveal.name,
          path: AppRoutes.roleReveal.path,
          builder: (_, state) => Text(
            'role-reveal:${state.pathParameters['sessionId']}',
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider.value(
        value: harness.cubit,
        child: MaterialApp.router(
          theme: AppTheme.dark(),
          routerConfig: router,
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(AppText.setupTitle), findsOneWidget);
    expect(find.text(AppText.selectPlayerCount), findsOneWidget);
    expect(find.text(AppText.startSessionAction), findsOneWidget);

    await tester.tap(find.text('5').first);
    await tester.pumpAndSettle();

    expect(find.text(AppText.variantReady), findsNothing);
    expect(find.text(AppText.playerNamesTitle), findsOneWidget);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(5));

    const names = ['أحمد', 'سارة', 'ليلى', 'كريم', 'نهى'];
    for (var index = 0; index < names.length; index += 1) {
      await tester.enterText(fields.at(index), names[index]);
    }
    await tester.pump();

    await tester.tap(find.text(AppText.startSessionAction));
    await tester.pumpAndSettle();

    expect(find.textContaining('role-reveal:session_'), findsOneWidget);
  });
}
