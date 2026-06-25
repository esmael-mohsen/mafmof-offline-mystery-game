import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/constants/app_text.dart';
import 'package:mafmof/features/game/presentation/screens/final_reveal_screen.dart';

import '../../../support/test_game_harness.dart';

void main() {
  late TestGameHarness harness;

  setUp(() async {
    harness = await TestGameHarness.create();
    await harness.prepareVariant(5);
    await harness.startSession(const ['أحمد', 'سارة', 'ليلى', 'كريم', 'نهى']);
    await harness.completeRoleReveal();
    await _resolveStage(harness, 1, 'shady');
    await _resolveStage(harness, 2, 'nader');
    await _resolveStage(harness, 3, 'omar');
    await _resolveStage(harness, 4, 'laila');
    await _resolveStage(harness, 5, 'shady');
  });

  tearDown(() async {
    await harness.dispose();
  });

  testWidgets('final reveal shows summary sections and safe image fallback',
      (tester) async {
    final sessionId = harness.cubit.state.activeSession!.sessionId;

    await tester.pumpWidget(
      BlocProvider.value(
        value: harness.cubit,
        child: MaterialApp(
          home: FinalRevealScreen(sessionId: sessionId),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining(AppText.finalRevealTitle), findsOneWidget);
    expect(find.text(AppText.restartSessionAction), findsOneWidget);
    await _expectVisibleAfterScroll(
      tester,
      find.text(AppText.finalRevealExplanationTitle),
    );
    await _expectVisibleAfterScroll(
      tester,
      find.text(AppText.finalRevealRolesTitle),
    );
    await _expectVisibleAfterScroll(
      tester,
      find.text(AppText.finalRevealEliminationsTitle),
    );
    await _expectVisibleAfterScroll(
      tester,
      find.text(AppText.finalRevealSuspicionTitle),
    );
  });
}

Future<void> _expectVisibleAfterScroll(
  WidgetTester tester,
  Finder finder,
) async {
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  expect(finder, findsOneWidget);
}

Future<void> _resolveStage(
  TestGameHarness harness,
  int stageNumber,
  String targetId,
) async {
  await harness.cubit.openVoting(stageNumber);
  final round = harness.cubit.state.currentVoteRound!;

  for (final voterId in round.eligibleVoterIds) {
    await harness.cubit.castVote(voterId, targetId);
  }

  await harness.cubit.resolveCurrentVoteRound();
  await harness.cubit.confirmCurrentVoteRound();
}
