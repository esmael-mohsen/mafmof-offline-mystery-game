import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafmof/core/database/app_database.dart';
import 'package:mafmof/features/game/data/datasources/game_local_datasource_impl.dart';
import 'package:mafmof/features/game/data/repositories/game_repository_impl.dart';
import 'package:mafmof/features/game/data/seeders/case_seeder.dart';
import 'package:mafmof/features/game/domain/entities/content_visibility_tier.dart';

import '../../../support/test_seed_payload.dart';

void main() {
  late AppDatabase database;
  late GameRepositoryImpl repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    final datasource = GameLocalDatasourceImpl(database);
    final seeder = CaseSeeder.forTesting(
      datasource,
      assetLoader: (_) async => buildTestSeedJson(),
    );
    repository = GameRepositoryImpl(datasource, seeder);
    await repository.initializeLocalCatalog();
  });

  tearDown(() async {
    await database.close();
  });

  test('private variant access returns complete playable content', () async {
    final variant = await repository.getVariantByPlayerCount(
      'case01_farah_eltagamoa',
      5,
    );

    expect(variant, isNotNull);
    expect(variant!.playerCount, 5);
    expect(
      variant.characters.where((item) => item.isActiveParticipant),
      hasLength(5),
    );
    expect(variant.roleDetails, hasLength(5));
    expect(variant.stages, hasLength(5));
    expect(variant.finalExplanation, isNotEmpty);
  });

  test('summary visibility omits private role and ending details', () async {
    final variant = await repository.getVariantByPlayerCount(
      'case01_farah_eltagamoa',
      6,
      visibility: ContentVisibilityTier.summary,
    );

    expect(variant, isNotNull);
    expect(variant!.playerCount, 6);
    expect(variant.finalExplanation, isNull);
    expect(variant.roleDetails, isEmpty);
    expect(variant.stages, isEmpty);
  });
}
