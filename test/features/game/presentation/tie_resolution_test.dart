import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/constants/app_text.dart';

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

  test('ties create a restricted revote and confirmed rounds stay immutable',
      () async {
    await harness.cubit.openVoting(1);
    final firstRound = harness.cubit.state.currentVoteRound!;
    expect(firstRound.eligibleTargetIds, containsAll(['shady', 'nader']));

    await harness.cubit.castVote(firstRound.eligibleVoterIds[0], 'shady');
    await harness.cubit.castVote(firstRound.eligibleVoterIds[1], 'shady');
    await harness.cubit.castVote(firstRound.eligibleVoterIds[2], 'nader');
    await harness.cubit.castVote(firstRound.eligibleVoterIds[3], 'nader');
    await harness.cubit.castVote(firstRound.eligibleVoterIds[4], 'omar');

    await harness.cubit.resolveCurrentVoteRound();

    final tiedRound = harness.cubit.state.currentVoteRound!;
    expect(tiedRound.isTied, isTrue);
    expect(tiedRound.tiedPlayerIds.toSet(), {'shady', 'nader'});
    expect(harness.cubit.state.errorMessage, AppText.tieDetectedMessage);

    await harness.cubit.startTieRevote();
    final revoteRound = harness.cubit.state.currentVoteRound!;
    expect(revoteRound.attemptNumber, 2);
    expect(revoteRound.eligibleTargetIds.toSet(), {'shady', 'nader'});

    for (final voterId in revoteRound.eligibleVoterIds) {
      await harness.cubit.castVote(voterId, 'shady');
    }

    await harness.cubit.resolveCurrentVoteRound();
    await harness.cubit.confirmCurrentVoteRound();

    final confirmedRound = harness.cubit.state.currentVoteRound!;
    final confirmedVotes =
        Map<String, String>.from(confirmedRound.votesByVoterId);
    expect(confirmedRound.isConfirmed, isTrue);

    await harness.cubit
        .castVote(confirmedRound.eligibleVoterIds.first, 'nader');

    expect(harness.cubit.state.errorMessage, AppText.invalidVoteActionMessage);
    expect(
        harness.cubit.state.currentVoteRound!.votesByVoterId, confirmedVotes);
  });
}
