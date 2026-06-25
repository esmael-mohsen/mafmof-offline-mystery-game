import 'package:flutter_test/flutter_test.dart';

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

  test('stage one suspicion and stage two elimination progress sequentially',
      () async {
    await _resolveStage(harness, 1, 'shady');

    final afterStageOne = harness.cubit.state.activeSession!;
    expect(afterStageOne.suspicionMarks['shady'], 1);
    expect(afterStageOne.resolvedStageNumbers, contains(1));
    expect(afterStageOne.recommendedNextStage, 2);

    await _resolveStage(harness, 2, 'nader');

    final afterStageTwo = harness.cubit.state.activeSession!;
    expect(afterStageTwo.eliminatedPlayerIds, contains('nader'));
    expect(
      afterStageTwo.players
          .firstWhere((item) => item.playerId == 'nader')
          .isEliminated,
      isTrue,
    );
    expect(afterStageTwo.recommendedNextStage, 3);

    await harness.cubit.openVoting(3);
    final thirdRound = harness.cubit.state.currentVoteRound!;
    expect(thirdRound.eligibleVoterIds, isNot(contains('nader')));
    expect(thirdRound.eligibleTargetIds, isNot(contains('nader')));
  });

  test('eliminated players vote when only mafia and one innocent remain',
      () async {
    await _resolveStage(harness, 1, 'shady');
    await _resolveStage(harness, 2, 'nader');
    await _resolveStage(harness, 3, 'omar');
    await _resolveStage(harness, 4, 'laila');

    await harness.cubit.openVoting(5);
    final finalRound = harness.cubit.state.currentVoteRound!;

    expect(finalRound.eligibleTargetIds.toSet(), {'karim', 'shady'});
    expect(finalRound.eligibleVoterIds.toSet(), {'nader', 'omar', 'laila'});
  });

  test('innocents win early when all mafia players are eliminated', () async {
    await _resolveStage(harness, 1, 'shady');
    await _resolveStage(harness, 2, 'shady');

    final outcome = harness.cubit.state.activeSession!.finalOutcome;
    expect(outcome, isNotNull);
    expect(outcome!.winningTeam, 'innocent');
    expect(outcome.accusedPlayerId, 'shady');
  });
}

Future<void> _resolveStage(
  TestGameHarness harness,
  int stageNumber,
  String targetId,
) async {
  await harness.cubit.openVoting(stageNumber);
  final round = harness.cubit.state.currentVoteRound!;
  expect(round.eligibleTargetIds, contains(targetId));

  for (final voterId in round.eligibleVoterIds) {
    await harness.cubit.castVote(voterId, targetId);
  }

  await harness.cubit.resolveCurrentVoteRound();
  await harness.cubit.confirmCurrentVoteRound();
}
