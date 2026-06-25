import '../../../../core/database/app_database.dart';

class CaseVariantModel {
  const CaseVariantModel({
    required this.id,
    required this.caseId,
    required this.playerCount,
    required this.displayLabel,
    required this.publicSynopsis,
    required this.finalExplanation,
    required this.stageCount,
    required this.isPlayable,
    this.innocentWinText,
    this.mafiaWinText,
  });

  final String id;
  final String caseId;
  final int playerCount;
  final String displayLabel;
  final String publicSynopsis;
  final String finalExplanation;
  final String? innocentWinText;
  final String? mafiaWinText;
  final int stageCount;
  final bool isPlayable;

  factory CaseVariantModel.fromRow(CaseVariant row) {
    return CaseVariantModel(
      id: row.id,
      caseId: row.caseId,
      playerCount: row.playerCount,
      displayLabel: row.displayLabel,
      publicSynopsis: row.publicSynopsis,
      finalExplanation: row.finalExplanation,
      innocentWinText: row.innocentWinText,
      mafiaWinText: row.mafiaWinText,
      stageCount: row.stageCount,
      isPlayable: row.isPlayable,
    );
  }
}
