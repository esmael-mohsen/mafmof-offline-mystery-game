import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('vote targets are rendered in a fixed two-column grid',
      (tester) async {
    final sessionId = harness.cubit.state.activeSession!.sessionId;

    await tester.pumpWidget(
      BlocProvider.value(
        value: harness.cubit,
        child: MaterialApp(
          home: VotingScreen(sessionId: sessionId, stageNumber: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final grids = tester.widgetList<GridView>(find.byType(GridView));
    final delegate = grids
        .map((grid) => grid.gridDelegate)
        .whereType<SliverGridDelegateWithFixedCrossAxisCount>()
        .first;

    expect(delegate.crossAxisCount, 2);
  });
}
