import '../../domain/entities/case_variant_entity.dart';
import '../../domain/entities/character_entity.dart';
import '../../domain/entities/content_visibility_tier.dart';
import '../../domain/entities/role_detail_entity.dart';
import '../../domain/entities/stage_entity.dart';
import '../models/case_variant_model.dart';
import '../models/character_model.dart';
import '../models/role_assignment_model.dart';
import '../models/stage_model.dart';

CaseVariantEntity caseVariantToEntity({
  required CaseVariantModel variant,
  required List<CharacterModel> characters,
  required List<RoleAssignmentModel> roleAssignments,
  required List<StageModel> stages,
  required ContentVisibilityTier visibility,
}) {
  return CaseVariantEntity(
    id: variant.id,
    caseId: variant.caseId,
    playerCount: variant.playerCount,
    displayLabel: variant.displayLabel,
    publicSynopsis: variant.publicSynopsis,
    finalExplanation: visibility == ContentVisibilityTier.private
        ? variant.finalExplanation
        : null,
    innocentWinText: visibility == ContentVisibilityTier.private
        ? variant.innocentWinText
        : null,
    mafiaWinText: visibility == ContentVisibilityTier.private
        ? variant.mafiaWinText
        : null,
    stageCount: variant.stageCount,
    isPlayable: variant.isPlayable,
    visibilityTier: visibility,
    characters: characters
        .map(
          (character) => CharacterEntity(
            id: character.id,
            name: character.name,
            title: character.title,
            portraitAssetPath: character.portraitAssetPath,
            publicBio: character.publicBio,
            isActiveParticipant: character.isActiveParticipant,
            displayOrder: character.displayOrder,
            evidenceNote: character.evidenceNote,
          ),
        )
        .toList(growable: false),
    roleDetails: visibility == ContentVisibilityTier.private
        ? roleAssignments
            .map(
              (role) => RoleDetailEntity(
                characterId: role.characterId,
                team: role.team,
                roleName: role.roleName,
                publicInfo: role.publicInfo,
                secret: role.secret,
                secretMeaning: role.secretMeaning,
                goal: role.goal,
                tasks: role.tasks,
                specialAbility: role.specialAbility,
                mustNotSay: role.mustNotSay,
              ),
            )
            .toList(growable: false)
        : const <RoleDetailEntity>[],
    stages: visibility == ContentVisibilityTier.private
        ? stages
            .map(
              (stage) => StageEntity(
                id: stage.id,
                stageNumber: stage.stageNumber,
                title: stage.title,
                hostScript: stage.hostScript,
                publicClue: stage.publicClue,
                expectedFocus: stage.expectedFocus,
                discussionSeconds: stage.discussionSeconds,
                voteType: stage.voteType,
                hostNote: stage.hostNote,
                imageAssetPath: stage.imageAssetPath,
                audioAssetPath: stage.audioAssetPath,
                audioTitle: stage.audioTitle,
                audioDurationSeconds: stage.audioDurationSeconds,
              ),
            )
            .toList(growable: false)
        : const <StageEntity>[],
  );
}
