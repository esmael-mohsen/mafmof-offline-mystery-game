import '../../../../core/database/app_database.dart';

class StageModel {
  const StageModel({
    required this.id,
    required this.variantId,
    required this.stageNumber,
    required this.title,
    required this.publicClue,
    required this.hostNote,
    required this.expectedFocus,
    required this.discussionSeconds,
    required this.voteType,
    this.hostScript,
    this.imageAssetPath,
    this.audioAssetPath,
    this.audioTitle,
    this.audioDurationSeconds,
  });

  final String id;
  final String variantId;
  final int stageNumber;
  final String title;
  final String? hostScript;
  final String publicClue;
  final String hostNote;
  final String expectedFocus;
  final int discussionSeconds;
  final String voteType;
  final String? imageAssetPath;
  final String? audioAssetPath;
  final String? audioTitle;
  final int? audioDurationSeconds;

  factory StageModel.fromRow(Stage row) {
    return StageModel(
      id: row.id,
      variantId: row.variantId,
      stageNumber: row.stageNumber,
      title: row.title,
      hostScript: row.hostScript,
      publicClue: row.publicClue,
      hostNote: row.hostNote,
      expectedFocus: row.expectedFocus,
      discussionSeconds: row.discussionSeconds,
      voteType: row.voteType,
      imageAssetPath: row.imageAssetPath,
      audioAssetPath: row.audioAssetPath,
      audioTitle: row.audioTitle,
      audioDurationSeconds: row.audioDurationSeconds,
    );
  }
}
