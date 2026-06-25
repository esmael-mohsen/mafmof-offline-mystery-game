import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/database_constants.dart';
import '../../../../core/database/app_database.dart';
import '../mappers/app_settings_mappers.dart';
import '../mappers/seed_to_companion_mappers.dart';
import '../models/app_settings_model.dart';
import '../models/case_model.dart';
import '../models/case_variant_model.dart';
import '../models/character_model.dart';
import '../models/role_assignment_model.dart';
import '../models/seed/case_seed_payload.dart';
import '../models/seed_metadata_model.dart';
import '../models/stage_model.dart';
import 'game_local_datasource.dart';

@LazySingleton(as: GameLocalDatasource)
class GameLocalDatasourceImpl implements GameLocalDatasource {
  GameLocalDatasourceImpl(this._database);

  final AppDatabase _database;

  @override
  Future<SeedMetadataModel?> getSeedMetadata(String seedKey) async {
    final query = _database.select(_database.seedMetadata)
      ..where((tbl) => tbl.seedKey.equals(seedKey));

    final row = await query.getSingleOrNull();
    return row == null ? null : SeedMetadataModel.fromRow(row);
  }

  @override
  Future<void> replaceCatalogWithSeed(CaseSeedPayload payload) async {
    await _database.transaction(() async {
      for (final casePayload in payload.cases) {
        final existingVariantIds = await (_database.select(_database.caseVariants)
              ..where((tbl) => tbl.caseId.equals(casePayload.id)))
            .map((row) => row.id)
            .get();

        if (existingVariantIds.isNotEmpty) {
          await (_database.delete(_database.roleAssignments)
                ..where((tbl) => tbl.variantId.isIn(existingVariantIds)))
              .go();
          await (_database.delete(_database.stages)
                ..where((tbl) => tbl.variantId.isIn(existingVariantIds)))
              .go();
          await (_database.delete(_database.variantCharacters)
                ..where((tbl) => tbl.variantId.isIn(existingVariantIds)))
              .go();
        }

        await (_database.delete(_database.caseVariants)
              ..where((tbl) => tbl.caseId.equals(casePayload.id)))
            .go();
        await (_database.delete(_database.characters)
              ..where((tbl) => tbl.caseId.equals(casePayload.id)))
            .go();
        await (_database.delete(_database.cases)
              ..where((tbl) => tbl.id.equals(casePayload.id)))
            .go();

        await _database
            .into(_database.cases)
            .insert(caseSeedToCompanion(casePayload, seedVersion: payload.seedVersion));

        await _database.batch((batch) {
          batch.insertAll(
            _database.characters,
            casePayload.characters
                .map((item) => characterSeedToCompanion(casePayload.id, item))
                .toList(growable: false),
          );

          for (final variant in casePayload.variants) {
            batch.insert(
              _database.caseVariants,
              caseVariantSeedToCompanion(casePayload.id, variant),
            );
            batch.insertAll(
              _database.variantCharacters,
              variant.variantCharacters
                  .map((item) => variantCharacterSeedToCompanion(variant.id, item))
                  .toList(growable: false),
            );
            batch.insertAll(
              _database.roleAssignments,
              variant.roleAssignments
                  .map((item) => roleAssignmentSeedToCompanion(variant.id, item))
                  .toList(growable: false),
            );
            batch.insertAll(
              _database.stages,
              variant.stages
                  .map((item) => stageSeedToCompanion(variant.id, item))
                  .toList(growable: false),
            );
          }
        });
      }

      await _database.into(_database.seedMetadata).insertOnConflictUpdate(
            SeedMetadataCompanion.insert(
              seedKey: payload.seedKey,
              seedVersion: payload.seedVersion,
              appliedAt: DateTime.now(),
              status: const Value('applied'),
            ),
          );
    });
  }

  @override
  Future<bool> hasAnyCases() async {
    final count = _database.cases.id.count();
    final query = _database.selectOnly(_database.cases)
      ..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count)! > 0;
  }

  @override
  Future<List<CaseModel>> getActiveCases() async {
    final rows = await (_database.select(_database.cases)
          ..where((tbl) => tbl.isActive.equals(true)))
        .get();
    return rows.map(CaseModel.fromRow).toList(growable: false);
  }

  @override
  Future<CaseModel?> getCaseById(String caseId) async {
    final row = await (_database.select(_database.cases)
          ..where((tbl) => tbl.id.equals(caseId)))
        .getSingleOrNull();
    return row == null ? null : CaseModel.fromRow(row);
  }

  @override
  Future<List<CaseVariantModel>> getVariantsForCase(String caseId) async {
    final rows = await (_database.select(_database.caseVariants)
          ..where((tbl) => tbl.caseId.equals(caseId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.playerCount)]))
        .get();
    return rows.map(CaseVariantModel.fromRow).toList(growable: false);
  }

  @override
  Future<CaseVariantModel?> getVariantByPlayerCount(
    String caseId,
    int playerCount,
  ) async {
    final row = await (_database.select(_database.caseVariants)
          ..where(
            (tbl) =>
                tbl.caseId.equals(caseId) & tbl.playerCount.equals(playerCount),
          ))
        .getSingleOrNull();
    return row == null ? null : CaseVariantModel.fromRow(row);
  }

  @override
  Future<List<CharacterModel>> getCharactersForCase(String caseId) async {
    final rows = await (_database.select(_database.characters)
          ..where((tbl) => tbl.caseId.equals(caseId)))
        .get();
    return rows.map(CharacterModel.fromRow).toList(growable: false);
  }

  @override
  Future<List<CharacterModel>> getCharactersForVariant(String variantId) async {
    final joinedRows = await (_database.select(_database.variantCharacters)
          ..where((tbl) => tbl.variantId.equals(variantId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.displayOrder)]))
        .join([
      innerJoin(
        _database.characters,
        _database.characters.id.equalsExp(_database.variantCharacters.characterId),
      ),
    ]).get();

    return joinedRows.map((row) {
      final character = row.readTable(_database.characters);
      final variantCharacter = row.readTable(_database.variantCharacters);
      return CharacterModel.fromRow(character).withParticipation(variantCharacter);
    }).toList(growable: false);
  }

  @override
  Future<List<RoleAssignmentModel>> getRoleAssignmentsForVariant(
    String variantId,
  ) async {
    final rows = await (_database.select(_database.roleAssignments)
          ..where((tbl) => tbl.variantId.equals(variantId)))
        .get();
    return rows.map(RoleAssignmentModel.fromRow).toList(growable: false);
  }

  @override
  Future<List<StageModel>> getStagesForVariant(String variantId) async {
    final rows = await (_database.select(_database.stages)
          ..where((tbl) => tbl.variantId.equals(variantId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.stageNumber)]))
        .get();
    return rows.map(StageModel.fromRow).toList(growable: false);
  }

  @override
  Future<AppSettingsModel> getAppSettings() async {
    final row = await (_database.select(_database.appSettings)
          ..where((tbl) => tbl.id.equals(DatabaseConstants.defaultSettingsId)))
        .getSingleOrNull();

    if (row != null) {
      return AppSettingsModel.fromRow(row);
    }

    final defaults = AppSettingsModel.defaults();
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(appSettingsModelToCompanion(defaults));
    return defaults;
  }

  @override
  Future<AppSettingsModel> saveAppSettings({
    bool? soundEnabled,
    double? soundVolume,
  }) async {
    final current = await getAppSettings();
    final updated = current.copyWith(
      soundEnabled: soundEnabled,
      soundVolume: soundVolume,
    );

    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(appSettingsModelToCompanion(updated));

    return updated;
  }
}
