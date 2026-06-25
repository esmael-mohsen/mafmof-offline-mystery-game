import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/app/router/app_router.dart';
import 'package:mafmof/app/theme/app_theme.dart';
import 'package:mafmof/core/constants/app_text.dart';

import '../../../support/test_game_harness.dart';

void main() {
  late TestGameHarness harness;

  setUp(() async {
    harness = await TestGameHarness.create();
  });

  tearDown(() async {
    await harness.dispose();
  });

  testWidgets(
    'catalog and setup flows keep private role details hidden before gameplay',
    (tester) async {
      await _pumpHarnessApp(tester, harness);
      await _pumpUntilFound(tester, find.text(AppText.viewCaseDetails));

      expect(find.text(AppText.viewCaseDetails), findsOneWidget);
      expect(find.textContaining(AppText.secretLabel), findsNothing);
      expect(
        find.textContaining(AppText.finalRevealExplanationTitle),
        findsNothing,
      );

      final detailsButton = find.text(AppText.viewCaseDetails);
      await tester.scrollUntilVisible(
        detailsButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(detailsButton);
      await _pumpUntilFound(tester, find.text(AppText.continueToSetup));

      expect(find.text(AppText.continueToSetup), findsOneWidget);
      expect(
        find.textContaining(AppText.finalRevealExplanationTitle),
        findsNothing,
      );

      await tester.tap(find.text(AppText.continueToSetup));
      await _pumpUntilFound(tester, find.text('5'));

      await tester.tap(find.text('5'));
      await _pumpUntilFound(tester, find.text(AppText.startSessionAction));

      expect(find.text(AppText.startSessionAction), findsOneWidget);
      expect(find.textContaining(AppText.secretLabel), findsNothing);
      expect(find.textContaining(AppText.stageHostNoteTitle), findsNothing);
    },
  );
}

Future<void> _pumpHarnessApp(
  WidgetTester tester,
  TestGameHarness harness,
) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = AppRouter().router;
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
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40; i += 1) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}
