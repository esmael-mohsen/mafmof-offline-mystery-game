import '../../../../core/database/app_database.dart';
import 'package:drift/drift.dart';
import '../models/seed/case_seed_payload.dart';
import '../models/seed/case_seed_variant_payload.dart';
import '../models/seed/case_seed_stage_payload.dart';

CasesCompanion caseSeedToCompanion(
  CaseSeedCasePayload payload, {
  required int seedVersion,
}) {
  return CasesCompanion.insert(
    id: payload.id,
    title: payload.title,
    subtitle: payload.subtitle,
    summary: payload.summary,
    setting: Value(payload.setting),
    durationMinutes: Value(payload.durationMinutes),
    difficulty: Value(payload.difficulty),
    minPlayers: Value(payload.minPlayers),
    maxPlayers: Value(payload.maxPlayers),
    coverAssetPath: payload.coverAssetPath,
    openingAssetPath: Value(payload.openingAssetPath),
    finalRevealAssetPath: Value(payload.finalRevealAssetPath),
    roleRevealBackgroundAssetPath: Value(payload.roleRevealBackgroundAssetPath),
    openingScript: Value(payload.openingScript),
    coreTruth: Value(payload.coreTruth),
    isActive: Value(payload.isActive),
    seedVersion: seedVersion,
  );
}

CharactersCompanion characterSeedToCompanion(
  String caseId,
  CaseSeedCharacterPayload payload,
) {
  return CharactersCompanion.insert(
    id: payload.id,
    caseId: caseId,
    name: payload.name,
    title: Value(payload.title),
    portraitAssetPath: payload.portraitAssetPath,
    publicBio: Value(payload.publicBio),
  );
}

CaseVariantsCompanion caseVariantSeedToCompanion(
  String caseId,
  CaseSeedVariantPayload payload,
) {
  return CaseVariantsCompanion.insert(
    id: payload.id,
    caseId: caseId,
    playerCount: payload.playerCount,
    displayLabel: payload.displayLabel,
    publicSynopsis: payload.publicSynopsis,
    finalExplanation: payload.finalExplanation,
    innocentWinText: Value(payload.innocentWinText),
    mafiaWinText: Value(payload.mafiaWinText),
    stageCount: payload.stages.length,
    isPlayable: Value(payload.isPlayable),
  );
}

VariantCharactersCompanion variantCharacterSeedToCompanion(
  String variantId,
  CaseSeedVariantCharacterPayload payload,
) {
  return VariantCharactersCompanion.insert(
    id: payload.id,
    variantId: variantId,
    characterId: payload.characterId,
    participationType: payload.participationType,
    displayOrder: payload.displayOrder,
    evidenceNote: Value(payload.evidenceNote),
  );
}

RoleAssignmentsCompanion roleAssignmentSeedToCompanion(
  String variantId,
  CaseSeedRoleAssignmentPayload payload,
) {
  return RoleAssignmentsCompanion.insert(
    id: payload.id,
    variantId: variantId,
    characterId: payload.characterId,
    team: payload.team,
    roleName: payload.roleName,
    publicInfo: payload.publicInfo,
    secret: payload.secret,
    secretMeaning: payload.secretMeaning,
    goal: payload.goal,
    tasks: Value(payload.tasks),
    specialAbility: Value(payload.specialAbility),
    mustNotSay: Value(payload.mustNotSay),
  );
}

StagesCompanion stageSeedToCompanion(
  String variantId,
  CaseSeedStagePayload payload,
) {
  return StagesCompanion.insert(
    id: payload.id,
    variantId: variantId,
    stageNumber: payload.stageNumber,
    title: payload.title,
    hostScript: Value(payload.hostScript),
    publicClue: payload.publicClue,
    hostNote: payload.hostNote,
    expectedFocus: payload.expectedFocus,
    discussionSeconds: payload.discussionSeconds,
    voteType: payload.voteType,
    imageAssetPath: Value(payload.imageAssetPath),
    audioAssetPath: Value(payload.audioAssetPath),
    audioTitle: Value(payload.audioTitle),
    audioDurationSeconds: Value(payload.audioDurationSeconds),
  );
}
