import '../../../../core/database/app_database.dart';

class CharacterModel {
  const CharacterModel({
    required this.id,
    required this.caseId,
    required this.name,
    required this.portraitAssetPath,
    required this.publicBio,
    this.title,
    this.isActiveParticipant = false,
    this.displayOrder = 0,
    this.evidenceNote,
  });

  final String id;
  final String caseId;
  final String name;
  final String? title;
  final String portraitAssetPath;
  final String publicBio;
  final bool isActiveParticipant;
  final int displayOrder;
  final String? evidenceNote;

  factory CharacterModel.fromRow(Character row) {
    return CharacterModel(
      id: row.id,
      caseId: row.caseId,
      name: row.name,
      title: row.title,
      portraitAssetPath: row.portraitAssetPath,
      publicBio: row.publicBio ?? '',
    );
  }

  CharacterModel withParticipation(VariantCharacter participation) {
    return CharacterModel(
      id: id,
      caseId: caseId,
      name: name,
      title: title,
      portraitAssetPath: portraitAssetPath,
      publicBio: publicBio,
      isActiveParticipant: participation.participationType == 'active',
      displayOrder: participation.displayOrder,
      evidenceNote: participation.evidenceNote,
    );
  }
}
