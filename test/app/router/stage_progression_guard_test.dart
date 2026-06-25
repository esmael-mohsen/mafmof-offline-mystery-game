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

  test('stage guard allows the next live stage and resolved review only', () async {
    final sessionId = harness.cubit.state.activeSession!.sessionId;

    expect(harness.cubit.canAccessStage(sessionId, 1), isTrue);
    expect(harness.cubit.canAccessStage(sessionId, 3), isFalse);

    await _resolveStage(harness, 1, 'shady');

    expect(harness.cubit.canAccessStage(sessionId, 1), isTrue);
    expect(harness.cubit.canAccessStage(sessionId, 2), isTrue);
    expect(harness.cubit.canAccessStage(sessionId, 3), isFalse);
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
