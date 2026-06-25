import '../entities/app_settings_entity.dart';
import '../entities/case_entity.dart';
import '../entities/case_variant_entity.dart';
import '../entities/content_visibility_tier.dart';

abstract class GameRepository {
  Future<void> initializeLocalCatalog();

  Future<List<CaseEntity>> getActiveCases();

  Future<CaseEntity?> getCaseById(String caseId);

  Future<List<CaseVariantEntity>> getVariantsForCase(
    String caseId, {
    ContentVisibilityTier visibility = ContentVisibilityTier.summary,
  });

  Future<CaseVariantEntity?> getVariantByPlayerCount(
    String caseId,
    int playerCount, {
    ContentVisibilityTier visibility = ContentVisibilityTier.private,
  });

  Future<AppSettingsEntity> getAppSettings();

  Future<AppSettingsEntity> updateSoundSettings({
    bool? soundEnabled,
    double? soundVolume,
  });
}
