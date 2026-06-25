import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/constants/database_constants.dart';
import 'package:mafmof/core/database/app_database.dart';
import 'package:mafmof/features/game/data/datasources/game_local_datasource_impl.dart';
import 'package:mafmof/features/game/data/seeders/case_seeder.dart';

import '../../support/test_seed_payload.dart';

void main() {
  late AppDatabase database;
  late GameLocalDatasourceImpl datasource;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    datasource = GameLocalDatasourceImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('first launch seeds the local catalog and metadata once', () async {
    final seeder = CaseSeeder.forTesting(
      datasource,
      assetLoader: (_) async => buildTestSeedJson(),
    );

    await seeder.seedCatalogIfNeeded();

    final cases = await datasource.getActiveCases();
    final metadata = await datasource.getSeedMetadata(
      DatabaseConstants.caseCatalogSeedKey,
    );
    final variants = await datasource.getVariantsForCase(
      'case01_farah_eltagamoa',
    );

    expect(cases, hasLength(1));
    expect(variants, hasLength(4));
    expect(metadata?.seedVersion, 1);
  });

  test('reapplying the same bundled version does not duplicate catalog data',
      () async {
    final seeder = CaseSeeder.forTesting(
      datasource,
      assetLoader: (_) async => buildTestSeedJson(),
    );

    await seeder.seedCatalogIfNeeded();
    await seeder.seedCatalogIfNeeded();

    final cases = await datasource.getActiveCases();
    final variants = await datasource.getVariantsForCase(
      'case01_farah_eltagamoa',
    );
    final characters = await datasource.getCharactersForCase(
      'case01_farah_eltagamoa',
    );

    expect(cases, hasLength(1));
    expect(variants, hasLength(4));
    expect(characters, hasLength(8));
  });

  test('a newer bundled version refreshes the catalog in place', () async {
    final initialSeeder = CaseSeeder.forTesting(
      datasource,
      assetLoader: (_) async => buildTestSeedJson(),
    );

    final upgradeSeeder = CaseSeeder.forTesting(
      datasource,
      assetLoader: (_) async => buildTestSeedJson(
        seedVersion: 2,
        caseTitleOverride: 'قضية فرح التجمع - نسخة محدثة',
      ),
    );

    await initialSeeder.seedCatalogIfNeeded();
    await upgradeSeeder.seedCatalogIfNeeded();

    final caseModel = await datasource.getCaseById('case01_farah_eltagamoa');
    final variants = await datasource.getVariantsForCase(
      'case01_farah_eltagamoa',
    );
    final metadata = await datasource.getSeedMetadata(
      DatabaseConstants.caseCatalogSeedKey,
    );

    expect(caseModel?.title, 'قضية فرح التجمع - نسخة محدثة');
    expect(variants, hasLength(4));
    expect(metadata?.seedVersion, 2);
  });

  test('multiple bundled case seed files are merged into one catalog',
      () async {
    final seedAssets = <String, String>{
      'case01': _renamedSeedJson(
        caseId: 'case01_farah_eltagamoa',
        variantPrefix: 'case01',
        seedVersion: 4,
      ),
      'case02': _renamedSeedJson(
        caseId: 'case02_room_707',
        variantPrefix: 'case02',
        seedVersion: 5,
      ),
    };
    final seeder = CaseSeeder.forTesting(
      datasource,
      assetPaths: seedAssets.keys.toList(growable: false),
      assetLoader: (path) async => seedAssets[path]!,
    );

    await seeder.seedCatalogIfNeeded();
    await seeder.seedCatalogIfNeeded();

    final cases = await datasource.getActiveCases();
    final case02Variants = await datasource.getVariantsForCase(
      'case02_room_707',
    );
    final metadata = await datasource.getSeedMetadata(
      DatabaseConstants.caseCatalogSeedKey,
    );

    expect(
        cases.map((caseModel) => caseModel.id),
        unorderedEquals([
          'case01_farah_eltagamoa',
          'case02_room_707',
        ]));
    expect(case02Variants, hasLength(4));
    expect(metadata?.seedVersion, 5);
  });

  test('registered bundled case seed files insert into the local database',
      () async {
    final seeder = CaseSeeder.forTesting(
      datasource,
      assetPaths: DatabaseConstants.caseSeedAssetPaths,
      assetLoader: (path) => File(path).readAsString(),
    );

    await seeder.seedCatalogIfNeeded();

    final cases = await datasource.getActiveCases();
    final case02Characters = await datasource.getCharactersForCase(
      'case02_room_707',
    );
    final case02Variants = await datasource.getVariantsForCase(
      'case02_room_707',
    );
    final case03Variants = await datasource.getVariantsForCase(
      'case03_black_rose',
    );
    final case04Characters = await datasource.getCharactersForCase(
      'case_04_last_therapy_session',
    );
    final case04Variants = await datasource.getVariantsForCase(
      'case_04_last_therapy_session',
    );
    final lastSessionCharacters = await datasource.getCharactersForCase(
      'case_04_last_session',
    );
    final lastSessionVariants = await datasource.getVariantsForCase(
      'case_04_last_session',
    );
    final metadata = await datasource.getSeedMetadata(
      DatabaseConstants.caseCatalogSeedKey,
    );

    expect(
      cases.map((caseModel) => caseModel.id),
      containsAll([
        'case02_room_707',
        'case03_black_rose',
        'case_04_last_therapy_session',
        'case_04_last_session',
      ]),
    );
    expect(case02Characters, hasLength(8));
    expect(case02Variants.map((variant) => variant.playerCount), [5, 6, 7, 8]);
    expect(case03Variants.map((variant) => variant.playerCount), [5, 6, 7, 8]);
    expect(case04Characters, hasLength(8));
    expect(case04Variants.map((variant) => variant.playerCount), [5, 6, 7, 8]);
    expect(lastSessionCharacters, hasLength(8));
    expect(
      lastSessionVariants.map((variant) => variant.playerCount),
      [5, 6, 7, 8],
    );
    expect(metadata?.seedVersion, 11);

    for (final variant in case02Variants) {
      final stages = await datasource.getStagesForVariant(variant.id);
      expect(stages, hasLength(DatabaseConstants.expectedStageCount));
    }

    final case03Variant5 = case03Variants.singleWhere(
      (variant) => variant.playerCount == 5,
    );
    final case03Stages =
        await datasource.getStagesForVariant(case03Variant5.id);
    final cassetteStage = case03Stages.singleWhere(
      (stage) => stage.stageNumber == 2,
    );

    expect(cassetteStage.imageAssetPath, isNotNull);
    expect(
      cassetteStage.audioAssetPath,
      'assets/audio/case03/clues/clue_2_cassette.mp3',
    );
    expect(cassetteStage.audioTitle, isNotNull);
    expect(cassetteStage.audioDurationSeconds, 25);

    final case04Variant5 = case04Variants.singleWhere(
      (variant) => variant.playerCount == 5,
    );
    final case04Stages =
        await datasource.getStagesForVariant(case04Variant5.id);
    final firstTherapyStage = case04Stages.singleWhere(
      (stage) => stage.stageNumber == 1,
    );

    expect(case04Stages, hasLength(DatabaseConstants.expectedStageCount));
    expect(
      firstTherapyStage.audioAssetPath,
      'assets/audio/cases/case_04_last_therapy_session/clues/cut_recorder.mp3',
    );

    final case04Assets = <String>[
      ...case04Characters.map((character) => character.portraitAssetPath),
      ...case04Stages.map((stage) => stage.imageAssetPath).whereType<String>(),
      ...case04Stages.map((stage) => stage.audioAssetPath).whereType<String>(),
    ].whereType<String>();

    for (final assetPath in case04Assets) {
      expect(File(assetPath).existsSync(), isTrue, reason: assetPath);
    }

    final lastSessionVariant5 = lastSessionVariants.singleWhere(
      (variant) => variant.playerCount == 5,
    );
    final lastSessionStages =
        await datasource.getStagesForVariant(lastSessionVariant5.id);

    expect(lastSessionStages, hasLength(DatabaseConstants.expectedStageCount));

    final lastSessionAssets = <String>[
      ...lastSessionCharacters.map((character) => character.portraitAssetPath),
      ...lastSessionStages
          .map((stage) => stage.imageAssetPath)
          .whereType<String>(),
      ...lastSessionStages
          .map((stage) => stage.audioAssetPath)
          .whereType<String>(),
    ]
        .whereType<String>()
        .expand((path) => path.split('\n'))
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty);

    for (final assetPath in lastSessionAssets) {
      expect(File(assetPath).existsSync(), isTrue, reason: assetPath);
    }
  });

  test('last session seeds evidence boards, ambient audio, and eliminations',
      () async {
    final seeder = CaseSeeder.forTesting(
      datasource,
      assetPaths: DatabaseConstants.caseSeedAssetPaths,
      assetLoader: (path) => File(path).readAsString(),
    );

    await seeder.seedCatalogIfNeeded();

    final variants = await datasource.getVariantsForCase(
      'case_04_last_session',
    );
    final variant5 =
        variants.singleWhere((variant) => variant.playerCount == 5);
    final stages = await datasource.getStagesForVariant(variant5.id);
    final stage2 = stages.singleWhere((stage) => stage.stageNumber == 2);
    final stage3 = stages.singleWhere((stage) => stage.stageNumber == 3);
    final stage4 = stages.singleWhere((stage) => stage.stageNumber == 4);
    final stage5 = stages.singleWhere((stage) => stage.stageNumber == 5);

    expect(stage2.voteType, 'elimination');
    expect(stage4.voteType, 'elimination');
    expect(stage5.voteType, 'elimination');
    expect(stage2.imageAssetPath!.split('\n'), hasLength(greaterThan(1)));
    expect(stage4.imageAssetPath!.split('\n'), hasLength(greaterThan(1)));
    expect(stage5.imageAssetPath!.split('\n'), hasLength(greaterThan(1)));
    expect(
        stage3.audioAssetPath!.split('\n'),
        containsAll([
          'assets/audio/cases/case_04_last_session/clues/stage_03_doctor_recording.mp3',
          'assets/audio/cases/case_04_last_session/clues/stage_03_knock.mp3',
        ]));
  });
}

String _renamedSeedJson({
  required String caseId,
  required String variantPrefix,
  required int seedVersion,
}) {
  var seedJson = buildTestSeedJson(seedVersion: seedVersion);
  seedJson = seedJson.replaceAll('case01_farah_eltagamoa', caseId);
  seedJson = seedJson.replaceAll('case01_v', '${variantPrefix}_v');

  for (final characterId in [
    'laila',
    'karim',
    'omar',
    'shady',
    'nader',
    'sara',
    'magdy',
    'bebo',
  ]) {
    seedJson =
        seedJson.replaceAll(characterId, '${variantPrefix}_$characterId');
  }

  return jsonEncode(jsonDecode(seedJson));
}
