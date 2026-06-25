import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/constants/app_text.dart';
import 'package:mafmof/features/game/presentation/screens/stage_screen.dart';

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

  testWidgets('leaving a live stage for voting requires explicit confirmation', (tester) async {
    final sessionId = harness.cubit.state.activeSession!.sessionId;

    await tester.pumpWidget(
      BlocProvider.value(
        value: harness.cubit,
        child: MaterialApp(
          home: StageScreen(sessionId: sessionId, stageNumber: 1),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final voteButton = find.text(AppText.goToVotingAction);
    await tester.scrollUntilVisible(
      voteButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(voteButton);
    await tester.pumpAndSettle();
    expect(find.text(AppText.confirmLeaveStageTitle), findsOneWidget);

    await tester.tap(find.text(AppText.cancelRestartAction));
    await tester.pumpAndSettle();
    expect(find.textContaining(AppText.stageTitle), findsOneWidget);
    expect(voteButton, findsOneWidget);
  });
}
