import 'package:equatable/equatable.dart';

import 'character_entity.dart';
import 'content_visibility_tier.dart';
import 'role_detail_entity.dart';
import 'stage_entity.dart';

class CaseVariantEntity extends Equatable {
  const CaseVariantEntity({
    required this.id,
    required this.caseId,
    required this.playerCount,
    required this.displayLabel,
    required this.publicSynopsis,
    required this.stageCount,
    required this.isPlayable,
    required this.visibilityTier,
    this.finalExplanation,
    this.innocentWinText,
    this.mafiaWinText,
    this.characters = const <CharacterEntity>[],
    this.roleDetails = const <RoleDetailEntity>[],
    this.stages = const <StageEntity>[],
  });

  final String id;
  final String caseId;
  final int playerCount;
  final String displayLabel;
  final String publicSynopsis;
  final int stageCount;
  final bool isPlayable;
  final ContentVisibilityTier visibilityTier;
  final String? finalExplanation;
  final String? innocentWinText;
  final String? mafiaWinText;
  final List<CharacterEntity> characters;
  final List<RoleDetailEntity> roleDetails;
  final List<StageEntity> stages;

  @override
  List<Object?> get props => [
        id,
        caseId,
        playerCount,
        displayLabel,
        publicSynopsis,
        stageCount,
        isPlayable,
        visibilityTier,
        finalExplanation,
        innocentWinText,
        mafiaWinText,
        characters,
        roleDetails,
        stages,
      ];
}
