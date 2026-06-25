import 'package:equatable/equatable.dart';

class CharacterEntity extends Equatable {
  const CharacterEntity({
    required this.id,
    required this.name,
    required this.portraitAssetPath,
    required this.publicBio,
    required this.isActiveParticipant,
    required this.displayOrder,
    this.title,
    this.evidenceNote,
  });

  final String id;
  final String name;
  final String? title;
  final String portraitAssetPath;
  final String publicBio;
  final bool isActiveParticipant;
  final int displayOrder;
  final String? evidenceNote;

  @override
  List<Object?> get props => [
        id,
        name,
        title,
        portraitAssetPath,
        publicBio,
        isActiveParticipant,
        displayOrder,
        evidenceNote,
      ];
}
