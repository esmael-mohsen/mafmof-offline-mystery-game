import '../../domain/entities/case_entity.dart';
import '../models/case_model.dart';

CaseEntity caseModelToEntity(
  CaseModel model, {
  required List<int> supportedPlayerCounts,
}) {
  return CaseEntity(
    id: model.id,
    title: model.title,
    subtitle: model.subtitle,
    summary: model.summary,
    setting: model.setting,
    durationMinutes: model.durationMinutes,
    difficulty: model.difficulty,
    minPlayers: model.minPlayers,
    maxPlayers: model.maxPlayers,
    coverAssetPath: model.coverAssetPath,
    openingAssetPath: model.openingAssetPath,
    finalRevealAssetPath: model.finalRevealAssetPath,
    roleRevealBackgroundAssetPath: model.roleRevealBackgroundAssetPath,
    openingScript: model.openingScript,
    coreTruth: model.coreTruth,
    isActive: model.isActive,
    seedVersion: model.seedVersion,
    supportedPlayerCounts: supportedPlayerCounts,
  );
}
