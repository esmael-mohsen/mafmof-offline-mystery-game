import '../../../../core/database/app_database.dart';

class VariantCharacterModel {
  const VariantCharacterModel({
    required this.id,
    required this.variantId,
    required this.characterId,
    required this.participationType,
    required this.displayOrder,
    this.evidenceNote,
  });

  final String id;
  final String variantId;
  final String characterId;
  final String participationType;
  final int displayOrder;
  final String? evidenceNote;

  factory VariantCharacterModel.fromRow(VariantCharacter row) {
    return VariantCharacterModel(
      id: row.id,
      variantId: row.variantId,
      characterId: row.characterId,
      participationType: row.participationType,
      displayOrder: row.displayOrder,
      evidenceNote: row.evidenceNote,
    );
  }
}
