import 'case_seed_stage_payload.dart';

class CaseSeedVariantCharacterPayload {
  const CaseSeedVariantCharacterPayload({
    required this.id,
    required this.characterId,
    required this.participationType,
    required this.displayOrder,
    this.evidenceNote,
  });

  final String id;
  final String characterId;
  final String participationType;
  final int displayOrder;
  final String? evidenceNote;

  factory CaseSeedVariantCharacterPayload.fromJson(Map<String, dynamic> json) {
    return CaseSeedVariantCharacterPayload(
      id: json['id'] as String,
      characterId: json['characterId'] as String,
      participationType: json['participationType'] as String,
      displayOrder: json['displayOrder'] as int,
      evidenceNote: json['evidenceNote'] as String?,
    );
  }
}

class CaseSeedRoleAssignmentPayload {
  const CaseSeedRoleAssignmentPayload({
    required this.id,
    required this.characterId,
    required this.team,
    required this.roleName,
    required this.publicInfo,
    required this.secret,
    required this.secretMeaning,
    required this.goal,
    this.tasks,
    this.specialAbility,
    this.mustNotSay,
  });

  final String id;
  final String characterId;
  final String team;
  final String roleName;
  final String publicInfo;
  final String secret;
  final String secretMeaning;
  final String goal;
  final String? tasks;
  final String? specialAbility;
  final String? mustNotSay;

  factory CaseSeedRoleAssignmentPayload.fromJson(Map<String, dynamic> json) {
    return CaseSeedRoleAssignmentPayload(
      id: json['id'] as String,
      characterId: json['characterId'] as String,
      team: json['team'] as String,
      roleName: json['roleName'] as String,
      publicInfo: json['publicInfo'] as String,
      secret: json['secret'] as String,
      secretMeaning: json['secretMeaning'] as String,
      goal: json['goal'] as String,
      tasks: json['tasks'] as String?,
      specialAbility: json['specialAbility'] as String?,
      mustNotSay: json['mustNotSay'] as String?,
    );
  }
}

class CaseSeedVariantPayload {
  const CaseSeedVariantPayload({
    required this.id,
    required this.playerCount,
    required this.displayLabel,
    required this.publicSynopsis,
    required this.finalExplanation,
    required this.innocentWinText,
    required this.mafiaWinText,
    required this.isPlayable,
    required this.variantCharacters,
    required this.roleAssignments,
    required this.stages,
  });

  final String id;
  final int playerCount;
  final String displayLabel;
  final String publicSynopsis;
  final String finalExplanation;
  final String innocentWinText;
  final String mafiaWinText;
  final bool isPlayable;
  final List<CaseSeedVariantCharacterPayload> variantCharacters;
  final List<CaseSeedRoleAssignmentPayload> roleAssignments;
  final List<CaseSeedStagePayload> stages;

  factory CaseSeedVariantPayload.fromJson(Map<String, dynamic> json) {
    return CaseSeedVariantPayload(
      id: json['id'] as String,
      playerCount: json['playerCount'] as int,
      displayLabel: json['displayLabel'] as String,
      publicSynopsis: json['publicSynopsis'] as String,
      finalExplanation: json['finalExplanation'] as String,
      innocentWinText: json['innocentWinText'] as String,
      mafiaWinText: json['mafiaWinText'] as String,
      isPlayable: json['isPlayable'] as bool,
      variantCharacters: (json['variantCharacters'] as List<dynamic>)
          .map(
            (item) => CaseSeedVariantCharacterPayload.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      roleAssignments: (json['roleAssignments'] as List<dynamic>)
          .map(
            (item) => CaseSeedRoleAssignmentPayload.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      stages: (json['stages'] as List<dynamic>)
          .map(
            (item) => CaseSeedStagePayload.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }
}
