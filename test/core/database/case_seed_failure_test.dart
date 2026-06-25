import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/database/app_database.dart';
import 'package:mafmof/core/errors/local_data_failure.dart';
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

  test('invalid bundled content fails with a local-data error', () async {
    final seeder = CaseSeeder.forTesting(
      datasource,
      assetLoader: (_) async => '{"seedKey":"case_catalog","seedVersion":"bad"}',
    );

    expect(
      seeder.seedCatalogIfNeeded,
      throwsA(
        isA<LocalDataFailure>().having(
          (failure) => failure.type,
          'type',
          LocalDataFailureType.invalidSeed,
        ),
      ),
    );
  });

  test('failed upgrade attempt preserves the last valid catalog', () async {
    final initialSeeder = CaseSeeder.forTesting(
      datasource,
      assetLoader: (_) async => buildTestSeedJson(),
    );
    final failingSeeder = CaseSeeder.forTesting(
      datasource,
      assetLoader: (_) async => '{"seedKey":"case_catalog","seedVersion":2,"cases":[]',
    );

    await initialSeeder.seedCatalogIfNeeded();
    await expectLater(
      failingSeeder.seedCatalogIfNeeded,
      throwsA(isA<LocalDataFailure>()),
    );

    final cases = await datasource.getActiveCases();
    expect(cases, hasLength(1));
    expect(cases.single.title, 'قضية فرح التجمع');
  });
}
