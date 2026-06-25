import 'case_seed_variant_payload.dart';

class CaseSeedCharacterPayload {
  const CaseSeedCharacterPayload({
    required this.id,
    required this.name,
    required this.title,
    required this.portraitAssetPath,
    required this.publicBio,
  });

  final String id;
  final String name;
  final String title;
  final String portraitAssetPath;
  final String publicBio;

  factory CaseSeedCharacterPayload.fromJson(Map<String, dynamic> json) {
    return CaseSeedCharacterPayload(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      portraitAssetPath: json['portraitAssetPath'] as String,
      publicBio: json['publicBio'] as String? ?? '',
    );
  }
}

class CaseSeedCasePayload {
  const CaseSeedCasePayload({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.setting,
    required this.durationMinutes,
    required this.difficulty,
    required this.minPlayers,
    required this.maxPlayers,
    required this.coverAssetPath,
    required this.openingAssetPath,
    required this.finalRevealAssetPath,
    required this.roleRevealBackgroundAssetPath,
    required this.openingScript,
    required this.coreTruth,
    required this.isActive,
    required this.characters,
    required this.variants,
  });

  final String id;
  final String title;
  final String subtitle;
  final String summary;
  final String setting;
  final int durationMinutes;
  final String difficulty;
  final int minPlayers;
  final int maxPlayers;
  final String coverAssetPath;
  final String openingAssetPath;
  final String finalRevealAssetPath;
  final String roleRevealBackgroundAssetPath;
  final String openingScript;
  final String coreTruth;
  final bool isActive;
  final List<CaseSeedCharacterPayload> characters;
  final List<CaseSeedVariantPayload> variants;

  factory CaseSeedCasePayload.fromJson(Map<String, dynamic> json) {
    return CaseSeedCasePayload(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      summary: json['summary'] as String,
      setting: json['setting'] as String,
      durationMinutes: json['durationMinutes'] as int,
      difficulty: json['difficulty'] as String,
      minPlayers: json['minPlayers'] as int,
      maxPlayers: json['maxPlayers'] as int,
      coverAssetPath: json['coverAssetPath'] as String,
      openingAssetPath: json['openingAssetPath'] as String,
      finalRevealAssetPath: json['finalRevealAssetPath'] as String,
      roleRevealBackgroundAssetPath: json['roleRevealBackgroundAssetPath'] as String,
      openingScript: json['openingScript'] as String,
      coreTruth: json['coreTruth'] as String,
      isActive: json['isActive'] as bool,
      characters: (json['characters'] as List<dynamic>)
          .map(
            (item) => CaseSeedCharacterPayload.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      variants: (json['variants'] as List<dynamic>)
          .map(
            (item) => CaseSeedVariantPayload.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }
}

class CaseSeedPayload {
  const CaseSeedPayload({
    required this.seedKey,
    required this.seedVersion,
    required this.cases,
  });

  final String seedKey;
  final int seedVersion;
  final List<CaseSeedCasePayload> cases;

  factory CaseSeedPayload.fromJson(Map<String, dynamic> json) {
    return CaseSeedPayload(
      seedKey: json['seedKey'] as String,
      seedVersion: json['seedVersion'] as int,
      cases: (json['cases'] as List<dynamic>)
          .map(
            (item) => CaseSeedCasePayload.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }
}
