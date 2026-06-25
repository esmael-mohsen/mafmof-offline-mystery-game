import 'package:equatable/equatable.dart';

class CaseEntity extends Equatable {
  const CaseEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.coverAssetPath,
    required this.isActive,
    required this.seedVersion,
    this.supportedPlayerCounts = const <int>[],
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
  final List<int> supportedPlayerCounts;

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        summary,
        setting,
        durationMinutes,
        difficulty,
        minPlayers,
        maxPlayers,
        coverAssetPath,
        openingAssetPath,
        finalRevealAssetPath,
        roleRevealBackgroundAssetPath,
        openingScript,
        coreTruth,
        isActive,
        seedVersion,
        supportedPlayerCounts,
      ];
}
