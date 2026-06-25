import '../models/app_settings_model.dart';
import '../models/case_model.dart';
import '../models/case_variant_model.dart';
import '../models/character_model.dart';
import '../models/role_assignment_model.dart';
import '../models/seed/case_seed_payload.dart';
import '../models/seed_metadata_model.dart';
import '../models/stage_model.dart';

abstract class GameLocalDatasource {
  Future<SeedMetadataModel?> getSeedMetadata(String seedKey);

  Future<void> replaceCatalogWithSeed(CaseSeedPayload payload);

  Future<bool> hasAnyCases();

  Future<List<CaseModel>> getActiveCases();

  Future<CaseModel?> getCaseById(String caseId);

  Future<List<CaseVariantModel>> getVariantsForCase(String caseId);

  Future<CaseVariantModel?> getVariantByPlayerCount(String caseId, int playerCount);

  Future<List<CharacterModel>> getCharactersForCase(String caseId);

  Future<List<CharacterModel>> getCharactersForVariant(String variantId);

  Future<List<RoleAssignmentModel>> getRoleAssignmentsForVariant(String variantId);

  Future<List<StageModel>> getStagesForVariant(String variantId);

  Future<AppSettingsModel> getAppSettings();

  Future<AppSettingsModel> saveAppSettings({
    bool? soundEnabled,
    double? soundVolume,
  });
}
