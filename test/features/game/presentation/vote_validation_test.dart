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

  test('blocks incomplete ballots from being resolved', () async {
    await harness.cubit.openVoting(1);
    final round = harness.cubit.state.currentVoteRound!;

    await harness.cubit.castVote(round.eligibleVoterIds.first, 'shady');
    await harness.cubit.resolveCurrentVoteRound();

    expect(harness.cubit.state.errorMessage, AppText.incompleteVotesMessage);
    expect(harness.cubit.state.currentVoteRound!.resolvedTargetId, isNull);
  });

  test('blocks votes against non-eligible targets', () async {
    await harness.cubit.openVoting(1);
    final round = harness.cubit.state.currentVoteRound!;

    await harness.cubit.castVote(round.eligibleVoterIds.first, 'not-a-player');

    expect(harness.cubit.state.errorMessage, AppText.invalidVoteTargetMessage);
    expect(harness.cubit.state.currentVoteRound!.votesByVoterId, isEmpty);
  });
}
