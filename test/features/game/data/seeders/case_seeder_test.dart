import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/constants/database_constants.dart';
import 'package:mafmof/core/database/app_database.dart';
import 'package:mafmof/features/game/data/datasources/game_local_datasource_impl.dart';
import 'package:mafmof/features/game/data/seeders/case_seeder.dart';

import '../../../../support/test_seed_payload.dart';

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

  test('idempotent seeding: second call with same version does not duplicate data', () async {
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

  test('idempotent seeding: each variant has exactly 5 stages', () async {
    final seeder = CaseSeeder.forTesting(
      datasource,
      assetLoader: (_) async => buildTestSeedJson(),
    );

    await seeder.seedCatalogIfNeeded();

    for (final playerCount in [5, 6, 7, 8]) {
      final variant = await datasource.getVariantByPlayerCount(
        'case01_farah_eltagamoa',
        playerCount,
      );
      expect(variant, isNotNull);

      final stages = await datasource.getStagesForVariant(variant!.id);
      expect(stages, hasLength(DatabaseConstants.expectedStageCount));
    }
  });

  test('idempotent seeding: each variant role count matches player count', () async {
    final seeder = CaseSeeder.forTesting(
      datasource,
      assetLoader: (_) async => buildTestSeedJson(),
    );

    await seeder.seedCatalogIfNeeded();

    for (final playerCount in [5, 6, 7, 8]) {
      final variant = await datasource.getVariantByPlayerCount(
        'case01_farah_eltagamoa',
        playerCount,
      );
      expect(variant, isNotNull);

      final variantId = variant!.id;
      final roles = await datasource.getRoleAssignmentsForVariant(variantId);
      final activeCharacters = await datasource.getCharactersForVariant(variantId);
      final activeCount = activeCharacters
          .where((c) => c.isActiveParticipant)
          .length;

      expect(roles, hasLength(playerCount));
      expect(activeCount, playerCount);
    }
  });
}