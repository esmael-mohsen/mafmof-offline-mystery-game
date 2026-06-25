import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/constants/database_constants.dart';
import 'package:mafmof/core/constants/app_text.dart';
import 'package:mafmof/features/game/domain/entities/session_player_entity.dart';

import '../../../support/test_game_harness.dart';

void main() {
  late TestGameHarness harness;

  setUp(() async {
    harness = await TestGameHarness.create(random: Random(2));
    await harness.prepareVariant(5);
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('blocks starting a session for unsupported player counts', () async {
    await harness.cubit.startSession(
      caseId: 'case01_farah_eltagamoa',
      playerCount: 4,
      playerNames: const ['أحمد', 'سارة', 'ليلى', 'كريم'],
    );

    expect(harness.cubit.state.activeSession, isNull);
    expect(harness.cubit.state.errorMessage, AppText.unsupportedCountMessage);
  });

  test('blocks starting a session when any player name is blank after trimming',
      () async {
    await harness.cubit.startSession(
      caseId: 'case01_farah_eltagamoa',
      playerCount: 5,
      playerNames: const ['أحمد', '   ', 'ليلى', 'كريم', 'نهى'],
    );

    expect(harness.cubit.state.activeSession, isNull);
    expect(harness.cubit.state.errorMessage, AppText.blankPlayerNameMessage);
  });

  test('blocks starting a session when names are duplicated case-insensitively',
      () async {
    await harness.cubit.startSession(
      caseId: 'case01_farah_eltagamoa',
      playerCount: 5,
      playerNames: const ['Ahmed', 'ahmed', 'ليلى', 'كريم', 'نهى'],
    );

    expect(harness.cubit.state.activeSession, isNull);
    expect(
        harness.cubit.state.errorMessage, AppText.duplicatePlayerNameMessage);
  });

  test('creates one randomized session player per active role assignment',
      () async {
    const names = ['أحمد', 'سارة', 'ليلى', 'كريم', 'نهى'];

    await harness.startSession(names);

    final session = harness.cubit.state.activeSession;
    expect(session, isNotNull);
    expect(session!.sessionId, isNotEmpty);
    expect(session.playerCount, 5);
    expect(session.players, hasLength(5));
    expect(session.players.map((item) => item.displayName).toList(), names);
    expect(
      session.players.map((item) => item.characterId).toSet(),
      const {'laila', 'karim', 'omar', 'shady', 'nader'},
    );
    expect(
      session.players.map((item) => item.characterId).toList(),
      isNot(const ['laila', 'karim', 'omar', 'shady', 'nader']),
    );
    expect(session.revealIndex, 0);
    expect(session.roleRevealComplete, isFalse);
    expect(harness.cubit.state.isCurrentRoleVisible, isFalse);
  });

  test('case 04 bundled data starts a valid role reveal session', () async {
    await harness.dispose();
    harness = await TestGameHarness.create(
      random: Random(2),
      caseId: 'case_04_last_therapy_session',
      assetPaths: DatabaseConstants.caseSeedAssetPaths,
      assetLoader: (path) => File(path).readAsString(),
    );

    await harness.prepareVariant(5);
    final preparedVariant = harness.cubit.state.preparedVariant!;
    final activeCharacters = preparedVariant.characters
        .where((character) => character.isActiveParticipant)
        .toList(growable: false);
    final roleCharacterIds =
        preparedVariant.roleDetails.map((role) => role.characterId).toSet();
    expect(activeCharacters, hasLength(5));
    expect(
        roleCharacterIds, containsAll(activeCharacters.map((item) => item.id)));

    final sessionId = await harness.cubit.startSession(
      caseId: 'case_04_last_therapy_session',
      playerCount: 5,
      playerNames: const ['أحمد', 'سارة', 'ليلى', 'كريم', 'نهى'],
    );

    final session = harness.cubit.state.activeSession;
    expect(sessionId, isNotNull, reason: harness.cubit.state.errorMessage);
    expect(session, isNotNull, reason: harness.cubit.state.errorMessage);
    expect(session!.sessionId, sessionId);
    expect(harness.cubit.canAccessRoleReveal(sessionId!), isTrue);
    expect(session.players, hasLength(5));
  });

  test('localizes role labels and shows mafia allies intel', () {
    const mafia = SessionPlayerEntity(
      playerId: 'p1',
      displayName: 'player 1',
      characterId: 'c1',
      characterName: 'character 1',
      portraitAssetPath: 'portrait.webp',
      roleName: 'Mafioso',
      team: 'mafia',
      publicInfo: 'public',
    );
    const support = SessionPlayerEntity(
      playerId: 'p2',
      displayName: 'player 2',
      characterId: 'c2',
      characterName: 'character 2',
      portraitAssetPath: 'portrait.webp',
      roleName: 'Agent',
      team: 'mafia_support',
      publicInfo: 'public',
    );
    const detective = SessionPlayerEntity(
      playerId: 'p3',
      displayName: 'player 3',
      characterId: 'c3',
      characterName: 'character 3',
      portraitAssetPath: 'portrait.webp',
      roleName: 'Detective',
      team: 'innocent',
      publicInfo: 'public',
    );

    expect(mafia.localizedRoleName, 'مافيا');
    expect(support.localizedRoleName, 'مساعد المافيا');
    expect(detective.localizedRoleName, 'المحقق');
    expect(mafia.localizedTeamName, 'فريق المافيا');
    expect(detective.localizedTeamName, 'فريق الأبرياء');
    expect(
      mafia.mafiaIntelLine(const [mafia, support, detective]),
      contains('player 2'),
    );
    expect(
      support.mafiaIntelLine(const [mafia, support, detective]),
      contains('player 1'),
    );
    expect(detective.mafiaIntelLine(const [mafia, support, detective]), isNull);
  });
}
