import 'package:flutter_test/flutter_test.dart';

import '../../support/test_game_harness.dart';

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

  test('final reveal guard stays closed until stage five is confirmed', () async {
    final sessionId = harness.cubit.state.activeSession!.sessionId;
    expect(harness.cubit.canAccessFinalReveal(sessionId), isFalse);

    await _resolveStage(harness, 1, 'shady');
    await _resolveStage(harness, 2, 'nader');
    await _resolveStage(harness, 3, 'omar');
    await _resolveStage(harness, 4, 'laila');
    expect(harness.cubit.canAccessFinalReveal(sessionId), isFalse);

    await _resolveStage(harness, 5, 'shady');
    expect(harness.cubit.canAccessFinalReveal(sessionId), isTrue);
  });
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
