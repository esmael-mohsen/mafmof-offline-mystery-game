import 'package:injectable/injectable.dart';

import '../../../../core/constants/database_constants.dart';
import '../../../../core/errors/local_data_failure.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../../domain/entities/case_entity.dart';
import '../../domain/entities/case_variant_entity.dart';
import '../../domain/entities/content_visibility_tier.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/game_local_datasource.dart';
import '../mappers/app_settings_mappers.dart';
import '../mappers/case_mappers.dart';
import '../mappers/variant_mappers.dart';
import '../models/role_assignment_model.dart';
import '../models/stage_model.dart';
import '../seeders/case_seeder.dart';

@LazySingleton(as: GameRepository)
class GameRepositoryImpl implements GameRepository {
  GameRepositoryImpl(this._datasource, this._seeder);

  final GameLocalDatasource _datasource;
  final CaseSeeder _seeder;

  @override
  Future<void> initializeLocalCatalog() async {
    await _seeder.seedCatalogIfNeeded();
  }

  @override
  Future<List<CaseEntity>> getActiveCases() async {
    final cases = await _datasource.getActiveCases();
    final entities = <CaseEntity>[];
    for (final caseModel in cases) {
      final variants = await _datasource.getVariantsForCase(caseModel.id);
      entities.add(
        caseModelToEntity(
          caseModel,
          supportedPlayerCounts: variants.map((item) => item.playerCount).toList(),
        ),
      );
    }
    return entities;
  }

  @override
  Future<CaseEntity?> getCaseById(String caseId) async {
    final caseModel = await _datasource.getCaseById(caseId);
    if (caseModel == null) {
      return null;
    }

    final variants = await _datasource.getVariantsForCase(caseId);
    return caseModelToEntity(
      caseModel,
      supportedPlayerCounts: variants.map((item) => item.playerCount).toList(),
    );
  }

  @override
  Future<List<CaseVariantEntity>> getVariantsForCase(
    String caseId, {
    ContentVisibilityTier visibility = ContentVisibilityTier.summary,
  }) async {
    final variants = await _datasource.getVariantsForCase(caseId);
    final entities = <CaseVariantEntity>[];

    for (final variant in variants) {
      entities.add(
        await _buildVariantEntity(variant.caseId, variant.playerCount, visibility),
      );
    }

    return entities;
  }

  @override
  Future<CaseVariantEntity?> getVariantByPlayerCount(
    String caseId,
    int playerCount, {
    ContentVisibilityTier visibility = ContentVisibilityTier.private,
  }) async {
    if (playerCount < DatabaseConstants.minimumSupportedPlayerCount ||
        playerCount > DatabaseConstants.maximumSupportedPlayerCount) {
      throw const LocalDataFailure(
        type: LocalDataFailureType.unsupportedPlayerCount,
        message: 'عدد اللاعبين المدعوم يجب أن يكون بين 5 و8.',
      );
    }

    final variant = await _datasource.getVariantByPlayerCount(caseId, playerCount);
    if (variant == null) {
      return null;
    }

    return _buildVariantEntity(caseId, playerCount, visibility);
  }

  @override
  Future<AppSettingsEntity> getAppSettings() async {
    final settings = await _datasource.getAppSettings();
    return appSettingsModelToEntity(settings);
  }

  @override
  Future<AppSettingsEntity> updateSoundSettings({
    bool? soundEnabled,
    double? soundVolume,
  }) async {
    final settings = await _datasource.saveAppSettings(
      soundEnabled: soundEnabled,
      soundVolume: soundVolume,
    );
    return appSettingsModelToEntity(settings);
  }

  Future<CaseVariantEntity> _buildVariantEntity(
    String caseId,
    int playerCount,
    ContentVisibilityTier visibility,
  ) async {
    final variant = await _datasource.getVariantByPlayerCount(caseId, playerCount);
    if (variant == null) {
      throw const LocalDataFailure(
        type: LocalDataFailureType.missingVariant,
        message: 'تعذر العثور على نسخة مطابقة لعدد اللاعبين.',
      );
    }

    final characters = await _datasource.getCharactersForVariant(variant.id);
    final List<RoleAssignmentModel> roles =
        visibility == ContentVisibilityTier.private
            ? await _datasource.getRoleAssignmentsForVariant(variant.id)
            : const <RoleAssignmentModel>[];
    final List<StageModel> stages =
        visibility == ContentVisibilityTier.private
            ? await _datasource.getStagesForVariant(variant.id)
            : const <StageModel>[];

    return caseVariantToEntity(
      variant: variant,
      characters: characters,
      roleAssignments: roles,
      stages: stages,
      visibility: visibility,
    );
  }
}
