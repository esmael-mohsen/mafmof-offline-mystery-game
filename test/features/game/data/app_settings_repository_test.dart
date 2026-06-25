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

  test('creates default sound settings on first read', () async {
    final settings = await repository.getAppSettings();

    expect(settings.soundEnabled, isTrue);
    expect(settings.soundVolume, closeTo(0.7, 0.001));
  });

  test('persists sound enabled state and volume updates', () async {
    await repository.updateSoundSettings(
      soundEnabled: false,
      soundVolume: 0.35,
    );

    final settings = await repository.getAppSettings();

    expect(settings.soundEnabled, isFalse);
    expect(settings.soundVolume, closeTo(0.35, 0.001));
  });
}
