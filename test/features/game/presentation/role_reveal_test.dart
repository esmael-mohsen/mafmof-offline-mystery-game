import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/constants/app_text.dart';
import 'package:mafmof/features/game/presentation/screens/role_reveal_screen.dart';

import '../../../support/test_game_harness.dart';

void main() {
  late TestGameHarness harness;

  setUp(() async {
    harness = await TestGameHarness.create();
    await harness.prepareVariant(5);
    await harness.startSession(const ['أحمد', 'سارة', 'ليلى', 'كريم', 'نهى']);
  });

  tearDown(() async {
    await harness.dispose();
  });

  test(
      'starts hidden, blocks next while visible, and advances hidden to the next player',
      () async {
    expect(harness.cubit.state.isCurrentRoleVisible, isFalse);
    expect(harness.cubit.state.activeSession!.revealIndex, 0);

    await harness.cubit.revealCurrentRole();
    expect(harness.cubit.state.isCurrentRoleVisible, isTrue);

    final completedWhileVisible = await harness.cubit.advanceRoleReveal();
    expect(completedWhileVisible, isFalse);
    expect(harness.cubit.state.activeSession!.revealIndex, 0);
    expect(harness.cubit.state.errorMessage, AppText.hideRoleBeforeNextMessage);

    await harness.cubit.hideCurrentRole();
    final completed = await harness.cubit.advanceRoleReveal();

    expect(completed, isFalse);
    expect(harness.cubit.state.isCurrentRoleVisible, isFalse);
    expect(harness.cubit.state.activeSession!.revealIndex, 1);
  });

  test('auto-hides the current role card when the app is backgrounded',
      () async {
    await harness.cubit.revealCurrentRole();
    expect(harness.cubit.state.isCurrentRoleVisible, isTrue);

    await harness.cubit.handleAppLifecycleChanged(AppLifecycleState.paused);

    expect(harness.cubit.state.isCurrentRoleVisible, isFalse);
  });

  test('goes back to previous role only after hiding the visible card',
      () async {
    await harness.cubit.hideCurrentRole();
    await harness.cubit.advanceRoleReveal();
    expect(harness.cubit.state.activeSession!.revealIndex, 1);

    await harness.cubit.revealCurrentRole();
    final blocked = await harness.cubit.previousRoleReveal();
    expect(blocked, isFalse);
    expect(harness.cubit.state.activeSession!.revealIndex, 1);
    expect(harness.cubit.state.errorMessage, AppText.hideRoleBeforeNextMessage);

    await harness.cubit.hideCurrentRole();
    final movedBack = await harness.cubit.previousRoleReveal();

    expect(movedBack, isTrue);
    expect(harness.cubit.state.activeSession!.revealIndex, 0);
    expect(harness.cubit.state.isCurrentRoleVisible, isFalse);
  });

  test('completing role reveal locks re-entry and unlocks the dashboard',
      () async {
    await harness.completeRoleReveal();

    final session = harness.cubit.state.activeSession;
    expect(session, isNotNull);
    expect(session!.roleRevealComplete, isTrue);
    expect(harness.cubit.canAccessRoleReveal(session.sessionId), isFalse);
    expect(harness.cubit.canAccessDashboard(session.sessionId), isTrue);
  });

  testWidgets('role reveal screen flips from portrait front to role details',
      (tester) async {
    final sessionId = harness.cubit.state.activeSession!.sessionId;
    final currentPlayer = harness.cubit.state.activeSession!.currentPlayer!;

    await tester.pumpWidget(
      BlocProvider.value(
        value: harness.cubit,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: RoleRevealScreen(sessionId: sessionId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Image) {
          return false;
        }
        final provider = widget.image;
        return provider is AssetImage &&
            provider.assetName == currentPlayer.portraitAssetPath;
      }),
      findsOneWidget,
    );
    expect(find.text(currentPlayer.localizedRoleName), findsNothing);

    await harness.cubit.revealCurrentRole();
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Image) {
          return false;
        }
        final provider = widget.image;
        return provider is AssetImage &&
            provider.assetName == currentPlayer.portraitAssetPath;
      }),
      findsOneWidget,
    );
    expect(find.text(currentPlayer.localizedRoleName), findsOneWidget);
    expect(find.text(currentPlayer.publicInfo), findsOneWidget);
  });
}
