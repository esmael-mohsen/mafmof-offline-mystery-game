import 'package:equatable/equatable.dart';

class StageEntity extends Equatable {
  const StageEntity({
    required this.id,
    required this.stageNumber,
    required this.title,
    required this.publicClue,
    required this.expectedFocus,
    required this.discussionSeconds,
    required this.voteType,
    this.hostScript,
    this.hostNote,
    this.imageAssetPath,
    this.audioAssetPath,
    this.audioTitle,
    this.audioDurationSeconds,
  });

  final String id;
  final int stageNumber;
  final String title;
  final String? hostScript;
  final String publicClue;
  final String expectedFocus;
  final int discussionSeconds;
  final String voteType;
  final String? hostNote;
  final String? imageAssetPath;
  final String? audioAssetPath;
  final String? audioTitle;
  final int? audioDurationSeconds;

  @override
  List<Object?> get props => [
        id,
        stageNumber,
        title,
        hostScript,
        publicClue,
        expectedFocus,
        discussionSeconds,
        voteType,
        hostNote,
        imageAssetPath,
        audioAssetPath,
        audioTitle,
        audioDurationSeconds,
      ];
}
