class CaseSeedStagePayload {
  const CaseSeedStagePayload({
    required this.id,
    required this.stageNumber,
    required this.title,
    required this.hostScript,
    required this.publicClue,
    required this.hostNote,
    required this.expectedFocus,
    required this.discussionSeconds,
    required this.voteType,
    this.imageAssetPath,
    this.audioAssetPath,
    this.audioTitle,
    this.audioDurationSeconds,
  });

  final String id;
  final int stageNumber;
  final String title;
  final String hostScript;
  final String publicClue;
  final String hostNote;
  final String expectedFocus;
  final int discussionSeconds;
  final String voteType;
  final String? imageAssetPath;
  final String? audioAssetPath;
  final String? audioTitle;
  final int? audioDurationSeconds;

  factory CaseSeedStagePayload.fromJson(Map<String, dynamic> json) {
    return CaseSeedStagePayload(
      id: json['id'] as String,
      stageNumber: json['stageNumber'] as int,
      title: json['title'] as String,
      hostScript: json['hostScript'] as String,
      publicClue: json['publicClue'] as String,
      hostNote: json['hostNote'] as String,
      expectedFocus: json['expectedFocus'] as String,
      discussionSeconds: json['discussionSeconds'] as int,
      voteType: json['voteType'] as String,
      imageAssetPath: json['imageAssetPath'] as String?,
      audioAssetPath: json['audioAssetPath'] as String?,
      audioTitle: json['audioTitle'] as String?,
      audioDurationSeconds: json['audioDurationSeconds'] as int?,
    );
  }
}
