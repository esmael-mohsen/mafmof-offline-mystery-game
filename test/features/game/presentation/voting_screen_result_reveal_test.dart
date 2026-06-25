import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mafmof/app/router/app_routes.dart';
import 'package:mafmof/features/game/presentation/screens/voting_screen.dart';

import '../../../support/test_game_harness.dart';

void main() {
  late TestGameHarness harness;

  setUp(() async {
    harness = await TestGameHarness.create();
    await harness.prepareVariant(5);
    await harness.startSession(const ['A', 'B', 'C', 'D', 'E']);
    await harness.completeRoleReveal();
  });

  tearDown(() async {
    await harness.dispose();
  });

  testWidgets('shows a result reveal before returning to host dashboard',
      (tester) async {
    final session = harness.cubit.state.activeSession!;
    final router = GoRouter(
      initialLocation: '/voting',
      routes: [
        GoRoute(
          path: '/voting',
          builder: (_, __) => VotingScreen(
            sessionId: session.sessionId,
            stageNumber: 1,
          ),
        ),
        GoRoute(
          name: AppRoutes.hostDashboard.name,
          path: '/host/:sessionId',
          builder: (_, __) => const Scaffold(body: Text('HOST')),
        ),
        GoRoute(
          name: AppRoutes.finalReveal.name,
          path: '/final/:sessionId',
          builder: (_, __) => const Scaffold(body: Text('FINAL')),
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

    final round = harness.cubit.state.currentVoteRound!;
    for (final voterId in round.eligibleVoterIds) {
      final targetId = voterId == 'shady' ? 'nader' : 'shady';
      await harness.cubit.castVote(voterId, targetId);
      await tester.pumpAndSettle();
      await tester.tap(_primaryStepButton());
      await tester.pumpAndSettle();
    }

    expect(_resultRevealOverlay(), findsOneWidget);
    expect(find.text('HOST'), findsNothing);

    await tester.tap(_resultRevealOverlay());
    await tester.pumpAndSettle();

    expect(find.text('HOST'), findsOneWidget);
  });
}

Finder _primaryStepButton() {
  return find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_VotingPrimaryStepButton',
  );
}

Finder _resultRevealOverlay() {
  return find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_VoteResultRevealOverlay',
  );
}
