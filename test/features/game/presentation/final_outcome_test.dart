import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/constants/database_constants.dart';

import '../../../support/test_game_harness.dart';

void main() {
  TestGameHarness? harness;

  tearDown(() async {
    if (harness != null) {
      await harness!.dispose();
      harness = null;
    }
  });

  test(
      'single-mafia variant awards the win to innocents when the accused player is mafia',
      () async {
    harness = await _createHarnessFor(5);

    await _resolveStage(harness!, 1, 'shady');
    await _resolveStage(harness!, 2, 'nader');
    await _resolveStage(harness!, 3, 'omar');
    await _resolveStage(harness!, 4, 'laila');
    await _resolveStage(harness!, 5, 'shady');

    final outcome = harness!.cubit.state.activeSession!.finalOutcome;
    expect(outcome, isNotNull);
    expect(outcome!.winningTeam, 'innocent');
    expect(outcome.accusedPlayerId, 'shady');
    expect(outcome.allMafiosoEliminatedBeforeFinal, isFalse);
  });

  test(
      'dual-mafia variant keeps winner logic team-based in the final accusation',
      () async {
    harness = await _createHarnessFor(7);

    final session = harness!.cubit.state.activeSession!;
    expect(
      session.players
          .where((item) => item.team == 'mafia')
          .map((item) => item.playerId),
      containsAll(const ['shady', 'magdy']),
    );

    await _resolveStage(harness!, 1, 'shady');
    await _resolveStage(harness!, 2, 'laila');
    await _resolveStage(harness!, 3, 'nader');
    await _resolveStage(harness!, 4, 'sara');
    await _resolveStage(harness!, 5, 'karim');

    final outcome = harness!.cubit.state.activeSession!.finalOutcome;
    expect(outcome, isNotNull);
    expect(outcome!.winningTeam, 'mafia');
    expect(outcome.accusedPlayerId, 'karim');
    expect(outcome.allMafiosoEliminatedBeforeFinal, isFalse);
  });

  test(
      'player-count matrix keeps the full ending loop valid for 6 and 8 players too',
      () async {
    final scenarios = <int, ({List<String> stageTargets, String finalWinner})>{
      6: (
        stageTargets: const ['shady', 'nader', 'omar', 'laila', 'shady'],
        finalWinner: 'innocent',
      ),
      8: (
        stageTargets: const ['shady', 'laila', 'nader', 'sara', 'karim'],
        finalWinner: 'mafia',
      ),
    };

    for (final entry in scenarios.entries) {
      final matrixHarness = await _createHarnessFor(entry.key);

      for (var stageIndex = 0;
          stageIndex < entry.value.stageTargets.length;
          stageIndex += 1) {
        await _resolveStage(
          matrixHarness,
          stageIndex + 1,
          entry.value.stageTargets[stageIndex],
        );
      }

      final outcome = matrixHarness.cubit.state.activeSession!.finalOutcome;
      expect(outcome, isNotNull);
      expect(outcome!.winningTeam, entry.value.finalWinner);

      await matrixHarness.dispose();
    }
  });

  test('last session fifth elimination prepares the final reveal', () async {
    harness = await TestGameHarness.create(
      caseId: 'case_04_last_session',
      assetPaths: DatabaseConstants.caseSeedAssetPaths,
      assetLoader: (path) => File(path).readAsString(),
    );
    await harness!.prepareVariant(5);
    await harness!.startSession(
      List<String>.generate(5, (index) => 'لاعب ${index + 1}'),
    );
    await harness!.completeRoleReveal();

    for (var stageNumber = 1; stageNumber <= 5; stageNumber += 1) {
      final targetId = harness!.cubit.state.activeSession!.players
          .firstWhere(
            (player) => !player.isEliminated,
          )
          .playerId;
      await _resolveStage(harness!, stageNumber, targetId);
    }

    final session = harness!.cubit.state.activeSession!;
    expect(session.resolvedStageNumbers, contains(5));
    expect(session.finalOutcome, isNotNull);
    expect(session.canShowFinalReveal, isTrue);
  });
}

Future<TestGameHarness> _createHarnessFor(int playerCount) async {
  final harness = await TestGameHarness.create();
  await harness.prepareVariant(playerCount);
  final names =
      List<String>.generate(playerCount, (index) => 'لاعب ${index + 1}');
  await harness.startSession(names);
  await harness.completeRoleReveal();
  return harness;
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
