import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mafmof/app/router/app_router.dart';
import 'package:mafmof/app/theme/app_theme.dart';
import 'package:mafmof/core/constants/app_text.dart';

import '../../support/test_game_harness.dart';

void main() {
  late TestGameHarness harness;

  setUp(() async {
    harness = await TestGameHarness.create();
  });

  tearDown(() async {
    await harness.dispose();
  });

  testWidgets('invalid placeholder context shows safe Home recovery', (
    tester,
  ) async {
    await _pumpHarnessApp(tester, harness);
    await _pumpUntilFound(tester, find.text(AppText.appTitle));

    final context = tester.element(find.text(AppText.appTitle));
    GoRouter.of(context).go('/game/placeholder/stage/not-a-number');
    await _pumpUntilFound(tester, find.text(AppText.invalidPlaceholderTitle));

    expect(find.text(AppText.invalidPlaceholderTitle), findsWidgets);
    expect(find.text(AppText.returnHome), findsOneWidget);

    await tester.tap(find.text(AppText.returnHome));
    await _pumpUntilFound(tester, find.text(AppText.homeTitle));

    expect(find.text(AppText.homeTitle), findsOneWidget);
  });

  testWidgets('invalid session routes fail closed', (tester) async {
    await _pumpHarnessApp(tester, harness);
    await _pumpUntilFound(tester, find.text(AppText.appTitle));

    final context = tester.element(find.text(AppText.appTitle));
    GoRouter.of(context).go('/game/stale-session/dashboard');
    await _pumpUntilFound(tester, find.text(AppText.invalidPlaceholderTitle));

    expect(find.text(AppText.invalidPlaceholderTitle), findsWidgets);
    expect(find.text(AppText.returnHome), findsOneWidget);
  });
}

Future<void> _pumpHarnessApp(
  WidgetTester tester,
  TestGameHarness harness,
) async {
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
