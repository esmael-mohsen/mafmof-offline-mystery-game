import '../../../../core/database/app_database.dart';

class CaseModel {
  const CaseModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.coverAssetPath,
    required this.isActive,
    required this.seedVersion,
    this.setting,
    this.durationMinutes,
    this.difficulty,
    this.minPlayers,
    this.maxPlayers,
    this.openingAssetPath,
    this.finalRevealAssetPath,
    this.roleRevealBackgroundAssetPath,
    this.openingScript,
    this.coreTruth,
  });

  final String id;
  final String title;
  final String subtitle;
  final String summary;
  final String? setting;
  final int? durationMinutes;
  final String? difficulty;
  final int? minPlayers;
  final int? maxPlayers;
  final String coverAssetPath;
  final String? openingAssetPath;
  final String? finalRevealAssetPath;
  final String? roleRevealBackgroundAssetPath;
  final String? openingScript;
  final String? coreTruth;
  final bool isActive;
  final int seedVersion;

  factory CaseModel.fromRow(Case row) {
    return CaseModel(
      id: row.id,
      title: row.title,
      subtitle: row.subtitle,
      summary: row.summary,
      setting: row.setting,
      durationMinutes: row.durationMinutes,
      difficulty: row.difficulty,
      minPlayers: row.minPlayers,
      maxPlayers: row.maxPlayers,
      coverAssetPath: row.coverAssetPath,
      openingAssetPath: row.openingAssetPath,
      finalRevealAssetPath: row.finalRevealAssetPath,
      roleRevealBackgroundAssetPath: row.roleRevealBackgroundAssetPath,
      openingScript: row.openingScript,
      coreTruth: row.coreTruth,
      isActive: row.isActive,
      seedVersion: row.seedVersion,
    );
  }
}
