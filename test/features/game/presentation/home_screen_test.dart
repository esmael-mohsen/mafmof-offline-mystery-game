import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mafmof/app/router/app_routes.dart';
import 'package:mafmof/app/theme/app_theme.dart';
import 'package:mafmof/features/game/presentation/screens/home_screen.dart';

import '../../../support/test_game_harness.dart';

void main() {
  testWidgets('launches offline to Arabic-first Home shell', (tester) async {
    final harness = await TestGameHarness.create();
    addTearDown(harness.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          name: AppRoutes.home.name,
          path: AppRoutes.home.path,
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          name: AppRoutes.caseDetails.name,
          path: AppRoutes.caseDetails.path,
          builder: (_, state) => Text(
            'case-details:${state.pathParameters['caseId']}',
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

    expect(find.text('جميع القضايا'), findsOneWidget);
    expect(find.byIcon(Icons.folder_rounded), findsOneWidget);
    expect(find.text('1 قضايا'), findsOneWidget);
    expect(find.text('45 دقيقة'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('ابدأ التحقيق'), findsNothing);
    expect(find.byIcon(Icons.wifi_off), findsNothing);
    expect(find.byType(Directionality), findsWidgets);

    final directionality = tester.widget<Directionality>(
      find
          .ancestor(
            of: find.text('جميع القضايا'),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(directionality.textDirection, TextDirection.rtl);

    final titleText = tester.widget<Text>(find.text('جميع القضايا'));
    expect(titleText.style?.fontFamily, contains('Amiri'));

    await tester.tap(find.text('قضية فرح التجمع').first);
    await tester.pumpAndSettle();

    expect(find.text('case-details:case01_farah_eltagamoa'), findsOneWidget);
  });
}
