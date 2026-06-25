import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mafmof/app/router/app_routes.dart';
import 'package:mafmof/app/theme/app_theme.dart';
import 'package:mafmof/core/constants/app_text.dart';
import 'package:mafmof/features/game/presentation/screens/case_details_screen.dart';

import '../../../support/test_game_harness.dart';

void main() {
  testWidgets('renders cinematic case details and continues to setup', (
    tester,
  ) async {
    final harness = await TestGameHarness.create();
    addTearDown(harness.dispose);

    final router = GoRouter(
      initialLocation: '/case/case01_farah_eltagamoa',
      routes: [
        GoRoute(
          name: AppRoutes.home.name,
          path: AppRoutes.home.path,
          builder: (_, __) => const Text('home'),
        ),
        GoRoute(
          name: AppRoutes.caseDetails.name,
          path: AppRoutes.caseDetails.path,
          builder: (_, state) => CaseDetailsScreen(
            caseId: state.pathParameters['caseId']!,
          ),
        ),
        GoRoute(
          name: AppRoutes.setupGame.name,
          path: AppRoutes.setupGame.path,
          builder: (_, state) => Text(
            'setup:${state.pathParameters['caseId']}',
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

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);

    router.go('/case/case01_farah_eltagamoa');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('قضية فرح التجمع'), findsWidgets);
    expect(find.text('ملخص القضية'), findsOneWidget);
    expect(
      find.text('اضغط على الكارت عشان تعرف مكان الأحداث'),
      findsOneWidget,
    );
    expect(find.text('45 دقيقة'), findsOneWidget);
    expect(find.text('متوسطة'), findsOneWidget);
    expect(find.text('5-8 لاعبين'), findsOneWidget);
    expect(find.text('CASE 01 / جاهزة للعب'), findsOneWidget);
    expect(find.byIcon(Icons.rotate_90_degrees_ccw_rounded), findsOneWidget);
    expect(find.text('نسخ اللاعبين المتاحة'), findsNothing);
    expect(find.text('شخصيات القضية'), findsOneWidget);
    expect(find.text('ليلى'), findsOneWidget);
    expect(find.text('كريم'), findsOneWidget);
    expect(find.text(AppText.continueToSetup), findsOneWidget);

    await tester.tap(find.text('ملخص القضية'));
    await tester.pumpAndSettle();

    expect(find.text('مكان الأحداث'), findsOneWidget);
    expect(
      find.text('اضغط على الكارت للرجوع إلى ملخص القضية'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text(AppText.continueToSetup));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppText.continueToSetup));
    await tester.pumpAndSettle();

    expect(find.text('setup:case01_farah_eltagamoa'), findsOneWidget);
  });
}
