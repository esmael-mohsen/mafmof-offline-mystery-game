import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/database/app_database.dart';
import 'package:mafmof/features/game/data/datasources/game_local_datasource_impl.dart';
import 'package:mafmof/features/game/data/repositories/game_repository_impl.dart';
import 'package:mafmof/features/game/data/seeders/case_seeder.dart';

import '../../../support/test_seed_payload.dart';

void main() {
  late AppDatabase database;
  late GameRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    final datasource = GameLocalDatasourceImpl(database);
    final seeder = CaseSeeder.forTesting(
      datasource,
      assetLoader: (_) async => buildTestSeedJson(),
    );
    repository = GameRepositoryImpl(datasource, seeder);
  });

  tearDown(() async {
    await database.close();
  });

  test('bootstrap exposes Case 01 in the active local catalog', () async {
    await repository.initializeLocalCatalog();

    final cases = await repository.getActiveCases();
    final selectedCase = await repository.getCaseById('case01_farah_eltagamoa');

    expect(cases, hasLength(1));
    expect(cases.single.title, 'قضية فرح التجمع');
    expect(selectedCase?.summary, contains('ملف غامض'));
  });
}
