import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/database_constants.dart';
import '../../../../core/errors/local_data_failure.dart';
import '../datasources/game_local_datasource.dart';
import '../models/seed/case_seed_payload.dart';

@lazySingleton
class CaseSeeder {
  CaseSeeder(this._datasource)
      : _assetLoader = rootBundle.loadString,
        _assetPaths = DatabaseConstants.caseSeedAssetPaths;

  CaseSeeder.forTesting(
    this._datasource, {
    required Future<String> Function(String path) assetLoader,
    List<String>? assetPaths,
  })  : _assetLoader = assetLoader,
        _assetPaths = assetPaths ?? const [DatabaseConstants.caseSeedAssetPath];

  final GameLocalDatasource _datasource;
  final Future<String> Function(String path) _assetLoader;
  final List<String> _assetPaths;

  Future<void> seedCatalogIfNeeded() async {
    try {
      final payload = await _loadCatalogPayload();
      final existing = await _datasource.getSeedMetadata(payload.seedKey);

      if (existing != null && existing.seedVersion == payload.seedVersion) {
        return;
      }

      await _datasource.replaceCatalogWithSeed(payload);
    } on LocalDataFailure {
      rethrow;
    } catch (error) {
      throw LocalDataFailure(
        type: LocalDataFailureType.invalidSeed,
        message: 'تعذر تجهيز بيانات القضية المحلية.',
        canRetry: true,
      );
    }
  }

  Future<CaseSeedPayload> _loadCatalogPayload() async {
    final payloads = <CaseSeedPayload>[];

    for (final path in _assetPaths) {
      final rawJson = await _assetLoader(path);
      final seedJson = _normalizeSeedJson(
        jsonDecode(rawJson) as Map<String, dynamic>,
      );
      payloads.add(
        CaseSeedPayload.fromJson(seedJson),
      );
    }

    if (payloads.isEmpty) {
      throw const FormatException('No case seed assets registered.');
    }

    final seedKey = payloads.first.seedKey;
    final cases = <CaseSeedCasePayload>[];
    var seedVersion = payloads.first.seedVersion;

    for (final payload in payloads) {
      if (payload.seedKey != seedKey) {
        throw const FormatException(
            'Case seed assets use different seed keys.');
      }

      seedVersion =
          payload.seedVersion > seedVersion ? payload.seedVersion : seedVersion;
      cases.addAll(payload.cases);
    }

    final caseIds = <String>{};
    for (final casePayload in cases) {
      if (!caseIds.add(casePayload.id)) {
        throw FormatException('Duplicate case seed id: ${casePayload.id}');
      }
    }

    return CaseSeedPayload(
      seedKey: seedKey,
      seedVersion: seedVersion,
      cases: cases,
    );
  }

  Map<String, dynamic> _normalizeSeedJson(Map<String, dynamic> json) {
    if (json.containsKey('seedKey')) {
      return json;
    }

    if (json.containsKey('caseId')) {
      return _authoringCaseToSeedJson(json);
    }

    if (json.containsKey('case_id')) {
      return _snakeCaseAuthoringToSeedJson(json);
    }

    throw const FormatException('Unsupported case seed asset format.');
  }

  Map<String, dynamic> _snakeCaseAuthoringToSeedJson(
    Map<String, dynamic> json,
  ) {
    final caseId = json['case_id'] as String;
    final supportedPlayerCounts =
        (json['supported_player_counts'] as List<dynamic>)
            .map((item) => item as int)
            .toList(growable: false);
    final characters =
        (json['characters'] as List<dynamic>).cast<Map<String, dynamic>>();
    final stages =
        (json['stages'] as List<dynamic>).cast<Map<String, dynamic>>();
    final variants = json['variants'] as Map<String, dynamic>;
    final roleCards = json['role_cards'] as Map<String, dynamic>;
    final resultLogic = json['result_logic'] as Map<String, dynamic>;
    final fullWin = resultLogic['full_win'] as Map<String, dynamic>;
    final lose = resultLogic['lose'] as Map<String, dynamic>;
    final finalReveal = json['final_reveal'] as Map<String, dynamic>;
    final estimatedDuration =
        json['estimated_duration_minutes'] as Map<String, dynamic>;

    return {
      'seedKey': DatabaseConstants.caseCatalogSeedKey,
      'seedVersion': json['seed_version'] as int? ?? 11,
      'cases': [
        {
          'id': caseId,
          'title': json['title'] as String,
          'subtitle': json['tagline'] as String? ?? json['title_en'] as String,
          'summary': json['short_summary'] as String,
          'setting': json['setting'] as String,
          'durationMinutes': estimatedDuration['max'] as int,
          'difficulty': json['difficulty'] as String,
          'minPlayers': supportedPlayerCounts.reduce(
            (current, next) => current < next ? current : next,
          ),
          'maxPlayers': supportedPlayerCounts.reduce(
            (current, next) => current > next ? current : next,
          ),
          'coverAssetPath': _snakeAssetPathByType(json, 'cover'),
          'openingAssetPath': _snakeAssetPathById(
            json,
            'image_stage_01_empty_room',
          ),
          'finalRevealAssetPath': _snakeAssetPathById(
            json,
            'image_stage_05_laptop_final',
          ),
          'roleRevealBackgroundAssetPath': _snakeAssetPathByType(
            json,
            'role_reveal_background',
          ),
          'openingScript': json['opening_narration'] as String,
          'coreTruth': _snakeCoreTruth(json['core_truth']),
          'isActive': true,
          'characters': [
            for (final character in characters)
              {
                'id': character['id'] as String,
                'name': character['name'] as String,
                'title': character['public_role'] as String,
                'portraitAssetPath': _snakeAssetPathById(
                  json,
                  'character_${character['id']}',
                ),
                'publicBio': character['public_personality'] as String? ??
                    character['visual_description'] as String? ??
                    '',
              },
          ],
          'variants': [
            for (final playerCount in supportedPlayerCounts)
              _snakeVariantToSeedJson(
                caseId: caseId,
                playerCount: playerCount,
                source: variants['$playerCount'] as Map<String, dynamic>,
                characters: characters,
                roleCards: roleCards,
                stages: stages,
                fullJson: json,
                finalExplanation: finalReveal['script'] as String,
                innocentWinText: fullWin['text'] as String,
                mafiaWinText: lose['text'] as String,
              ),
          ],
        },
      ],
    };
  }

  Map<String, dynamic> _snakeVariantToSeedJson({
    required String caseId,
    required int playerCount,
    required Map<String, dynamic> source,
    required List<Map<String, dynamic>> characters,
    required Map<String, dynamic> roleCards,
    required List<Map<String, dynamic>> stages,
    required Map<String, dynamic> fullJson,
    required String finalExplanation,
    required String innocentWinText,
    required String mafiaWinText,
  }) {
    final activeCharacterIds = _stringList(source['active_character_ids']);
    final variantId = '${caseId}_v$playerCount';
    final characterById = {
      for (final character in characters) character['id'] as String: character,
    };

    return {
      'id': variantId,
      'playerCount': playerCount,
      'displayLabel': '$playerCount players',
      'publicSynopsis': source['notes'] as String? ??
          source['added_value'] as String? ??
          fullJson['short_summary'] as String,
      'finalExplanation': finalExplanation,
      'innocentWinText': innocentWinText,
      'mafiaWinText': mafiaWinText,
      'isPlayable': true,
      'variantCharacters': [
        for (var index = 0; index < activeCharacterIds.length; index += 1)
          {
            'id': '${variantId}_${activeCharacterIds[index]}',
            'characterId': activeCharacterIds[index],
            'participationType': 'active',
            'displayOrder': index + 1,
          },
      ],
      'roleAssignments': [
        for (final characterId in activeCharacterIds)
          _snakeRoleToSeedJson(
            variantId: variantId,
            character: characterById[characterId]!,
            roleCard: roleCards[characterId] as Map<String, dynamic>,
          ),
      ],
      'stages': [
        for (final stage in stages)
          _snakeStageToSeedJson(
            variantId: variantId,
            source: stage,
            fullJson: fullJson,
          ),
      ],
    };
  }

  Map<String, dynamic> _snakeRoleToSeedJson({
    required String variantId,
    required Map<String, dynamic> character,
    required Map<String, dynamic> roleCard,
  }) {
    final characterId = character['id'] as String;
    final front = roleCard['front'] as Map<String, dynamic>;
    final back = roleCard['back'] as Map<String, dynamic>;

    return {
      'id': '${variantId}_role_$characterId',
      'characterId': characterId,
      'team': character['role_type'] == 'culprit' ? 'mafia' : 'innocent',
      'roleName': front['public_role'] as String,
      'publicInfo': front['public_intro'] as String,
      'secret': back['private_secret'] as String,
      'secretMeaning': _stringList(back['must_hide']).join('\n'),
      'goal': back['objective'] as String,
      'tasks': _stringList(back['knows_at_start']).join('\n'),
      'mustNotSay': _stringList(back['must_hide']).join('\n'),
    };
  }

  Map<String, dynamic> _snakeStageToSeedJson({
    required String variantId,
    required Map<String, dynamic> source,
    required Map<String, dynamic> fullJson,
  }) {
    final stageId = source['id'] as String;
    final stageNumber = source['number'] as int;
    final primaryClue = _snakePrimaryClue(fullJson, stageId);
    final imageAssetPaths = _snakeAssetPathsByStage(fullJson, stageId);
    final audioAssetPaths = _snakeAudioAssetPathsByStage(fullJson, stageId);

    return {
      'id': '${variantId}_$stageId',
      'stageNumber': stageNumber,
      'title': source['title'] as String,
      'hostScript': source['host_script'] as String,
      'publicClue': _snakePublicClueText(source, primaryClue),
      'hostNote': [
        source['function'] as String?,
        ..._stringList(source['host_notes']),
        primaryClue?['true_meaning'] as String?,
        primaryClue?['connects_to_truth'] as String?,
      ].whereType<String>().join('\n'),
      'expectedFocus': source['discussion_goal'] as String,
      'discussionSeconds': _discussionSecondsForStage(stageNumber),
      'voteType': 'elimination',
      'imageAssetPath':
          imageAssetPaths.isEmpty ? null : imageAssetPaths.join('\n'),
      'audioAssetPath':
          audioAssetPaths.isEmpty ? null : audioAssetPaths.join('\n'),
      'audioTitle': audioAssetPaths.isEmpty ? null : primaryClue?['title'],
    };
  }

  Map<String, dynamic> _authoringCaseToSeedJson(Map<String, dynamic> json) {
    final caseId = json['caseId'] as String;
    final supportedPlayerCounts =
        (json['supportedPlayerCounts'] as List<dynamic>).cast<int>();
    final characters =
        (json['characters'] as List<dynamic>).cast<Map<String, dynamic>>();
    final stages =
        (json['stages'] as List<dynamic>).cast<Map<String, dynamic>>();
    final clues = (json['clues'] as List<dynamic>).cast<Map<String, dynamic>>();
    final variants = json['variants'] as Map<String, dynamic>;
    final endings = json['endings'] as Map<String, dynamic>;

    return {
      'seedKey': DatabaseConstants.caseCatalogSeedKey,
      'seedVersion': json['seedVersion'] as int? ?? 9,
      'cases': [
        {
          'id': caseId,
          'title': json['title'] as String,
          'subtitle': json['subtitle'] as String,
          'summary': json['premise'] as String,
          'setting': json['setting'] as String,
          'durationMinutes': json['estimatedDurationMinutes'] as int,
          'difficulty': json['difficulty'] as String,
          'minPlayers': supportedPlayerCounts.reduce(
            (current, next) => current < next ? current : next,
          ),
          'maxPlayers': supportedPlayerCounts.reduce(
            (current, next) => current > next ? current : next,
          ),
          'coverAssetPath': _assetPathById(json, 'case_cover'),
          'openingAssetPath': _assetPathById(json, 'opening_scene'),
          'finalRevealAssetPath': _assetPathById(json, 'final_reveal_scene'),
          'roleRevealBackgroundAssetPath': _assetPathById(
            json,
            'role_reveal_bg',
          ),
          'openingScript': json['openingScript'] as String,
          'coreTruth': json['coreTruth'] as String,
          'isActive': true,
          'characters': [
            for (final character in characters)
              {
                'id': character['characterId'] as String,
                'name': character['name'] as String,
                'title': character['title'] as String,
                'portraitAssetPath': _normalizeAuthoringAssetPath(
                  character['portraitAsset'] as String,
                ),
                'publicBio': character['publicDescription'] as String,
              },
          ],
          'variants': [
            for (final playerCount in supportedPlayerCounts)
              _authoringVariantToSeedJson(
                caseId: caseId,
                playerCount: playerCount,
                source: variants['$playerCount'] as Map<String, dynamic>,
                characters: characters,
                stages: stages,
                clues: clues,
                endings: endings,
                fullJson: json,
              ),
          ],
        },
      ],
    };
  }

  Map<String, dynamic> _authoringVariantToSeedJson({
    required String caseId,
    required int playerCount,
    required Map<String, dynamic> source,
    required List<Map<String, dynamic>> characters,
    required List<Map<String, dynamic>> stages,
    required List<Map<String, dynamic>> clues,
    required Map<String, dynamic> endings,
    required Map<String, dynamic> fullJson,
  }) {
    final variantId = '${caseId}_v$playerCount';
    final activeCharacterIds =
        (source['activeCharacterIds'] as List<dynamic>).cast<String>();
    final roleCards =
        (source['roleCards'] as List<dynamic>).cast<Map<String, dynamic>>();
    final characterById = {
      for (final character in characters)
        character['characterId'] as String: character,
    };

    return {
      'id': variantId,
      'playerCount': playerCount,
      'displayLabel': '$playerCount لاعبين',
      'publicSynopsis': source['variantNotes'] as String,
      'finalExplanation': (fullJson['hostScripts']
          as Map<String, dynamic>)['finalReveal'] as String,
      'innocentWinText': endings['fullSuccess'] as String,
      'mafiaWinText': endings['guiltyWin'] as String,
      'isPlayable': true,
      'variantCharacters': [
        for (var index = 0; index < activeCharacterIds.length; index += 1)
          {
            'id': '${variantId}_${activeCharacterIds[index]}',
            'characterId': activeCharacterIds[index],
            'participationType': 'active',
            'displayOrder': index + 1,
          },
      ],
      'roleAssignments': [
        for (final roleCard in roleCards)
          _authoringRoleToSeedJson(
            variantId: variantId,
            source: roleCard,
            character: characterById[roleCard['characterId'] as String]!,
          ),
      ],
      'stages': [
        for (final stage in stages)
          _authoringStageToSeedJson(
            variantId: variantId,
            playerCount: playerCount,
            source: stage,
            clues: clues,
            fullJson: fullJson,
          ),
      ],
    };
  }

  Map<String, dynamic> _authoringRoleToSeedJson({
    required String variantId,
    required Map<String, dynamic> source,
    required Map<String, dynamic> character,
  }) {
    final characterId = source['characterId'] as String;
    final stageNotes = source['stageNotes'] as Map<String, dynamic>?;
    final tasks = [
      source['pressureResponseHint'] as String?,
      if (stageNotes != null) ...stageNotes.values.cast<String>(),
    ].whereType<String>().join('\n');

    return {
      'id': '${variantId}_role_$characterId',
      'characterId': characterId,
      'team': character['isGuilty'] as bool ? 'mafia' : 'innocent',
      'roleName': character['title'] as String,
      'publicInfo': source['publicRole'] as String,
      'secret': source['privateInfo'] as String,
      'secretMeaning': source['whatToHide'] as String,
      'goal': source['objective'] as String,
      'tasks': tasks.isEmpty ? null : tasks,
      'mustNotSay': source['whatToHide'] as String,
    };
  }

  Map<String, dynamic> _authoringStageToSeedJson({
    required String variantId,
    required int playerCount,
    required Map<String, dynamic> source,
    required List<Map<String, dynamic>> clues,
    required Map<String, dynamic> fullJson,
  }) {
    final stageId = source['stageId'] as String;
    final stageNumber = source['stageNumber'] as int;
    final stageClues =
        clues.where((clue) => clue['stageId'] == stageId).toList();
    final primaryClue = stageClues.isEmpty ? null : stageClues.first;
    final audioAssetId = primaryClue?['audioAssetId'] as String?;

    return {
      'id': '${variantId}_$stageId',
      'stageNumber': stageNumber,
      'title': source['title'] as String,
      'hostScript': (source['variantHostScripts']
          as Map<String, dynamic>)['$playerCount'] as String,
      'publicClue': primaryClue?['publicDescription'] as String? ??
          source['publicEvent'] as String,
      'hostNote': [
        source['purpose'] as String?,
        primaryClue?['visibleMeaning'] as String?,
        primaryClue?['hiddenMeaning'] as String?,
        primaryClue?['finalExplanation'] as String?,
      ].whereType<String>().join('\n'),
      'expectedFocus': (source['discussionPrompts'] as List<dynamic>)
          .cast<String>()
          .join('\n'),
      'discussionSeconds': _discussionSecondsForStage(stageNumber),
      'voteType': stageNumber == DatabaseConstants.expectedStageCount
          ? 'final'
          : 'suspicion',
      'imageAssetPath': _assetPathById(
        fullJson,
        primaryClue?['assetId'] as String? ?? source['assetId'] as String,
      ),
      'audioAssetPath':
          audioAssetId == null ? null : _assetPathById(fullJson, audioAssetId),
      'audioTitle': audioAssetId == null ? null : primaryClue?['title'],
    };
  }

  String _snakeCoreTruth(Object? value) {
    if (value is! Map<String, dynamic>) {
      return '';
    }

    return [
      value['victim'] as String?,
      value['culprit'] as String?,
      value['crime_type'] as String?,
      value['method'] as String?,
      value['motive'] as String?,
      value['core_twist'] as String?,
    ].whereType<String>().join('\n');
  }

  Map<String, dynamic>? _snakePrimaryClue(
    Map<String, dynamic> json,
    String stageId,
  ) {
    final clues = (json['clues'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return clues
        .where((clue) => clue['stage_id'] == stageId)
        .cast<Map<String, dynamic>?>()
        .firstWhere((clue) => clue != null, orElse: () => null);
  }

  String _snakePublicClueText(
    Map<String, dynamic> stage,
    Map<String, dynamic>? primaryClue,
  ) {
    final clueIds = _stringList(stage['public_clues']);
    final base = primaryClue?['public_text'] as String? ??
        primaryClue?['title'] as String? ??
        stage['suspicion_shift'] as String? ??
        '';

    if (clueIds.isEmpty) {
      return base;
    }

    return [
      base,
      clueIds.join('\n'),
    ].where((item) => item.isNotEmpty).join('\n');
  }

  String? _snakeAssetIdByStage(
    Map<String, dynamic> json,
    String stageId,
    String type,
  ) {
    final assets = json['assets'] as Map<String, dynamic>;
    final images = (assets['images'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return images
        .where((asset) => asset['stage_id'] == stageId && asset['type'] == type)
        .map((asset) => asset['id'] as String)
        .cast<String?>()
        .firstWhere((assetId) => assetId != null, orElse: () => null);
  }

  List<String> _snakeAssetPathsByStage(
    Map<String, dynamic> json,
    String stageId,
  ) {
    final assets = json['assets'] as Map<String, dynamic>;
    final images = (assets['images'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final stageImages = images
        .where((asset) => asset['stage_id'] == stageId)
        .map((asset) => asset['path'] as String)
        .toList(growable: false);

    if (stageImages.isNotEmpty) {
      return stageImages;
    }

    final fallbackId = _snakeAssetIdByStage(json, stageId, 'stage_clue');
    return fallbackId == null
        ? const []
        : [_snakeAssetPathById(json, fallbackId)];
  }

  List<String> _snakeAudioAssetPathsByStage(
    Map<String, dynamic> json,
    String stageId,
  ) {
    final assets = json['assets'] as Map<String, dynamic>;
    final audio = (assets['audio'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return audio
        .where((asset) => asset['stage_id'] == stageId)
        .map((asset) => asset['path'] as String)
        .toList(growable: false);
  }

  String _snakeAssetPathByType(Map<String, dynamic> json, String type) {
    final assets = json['assets'] as Map<String, dynamic>;
    final images = (assets['images'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final asset = images.firstWhere(
      (item) => item['type'] == type,
      orElse: () => throw FormatException('Unknown asset type: $type'),
    );
    return asset['path'] as String;
  }

  String _snakeAssetPathById(Map<String, dynamic> json, String assetId) {
    final assets = json['assets'] as Map<String, dynamic>;
    final items = [
      ...(assets['images'] as List<dynamic>? ?? const []),
      ...(assets['audio'] as List<dynamic>? ?? const []),
    ].cast<Map<String, dynamic>>();

    final asset = items.firstWhere(
      (item) => item['id'] == assetId,
      orElse: () => throw FormatException('Unknown asset id: $assetId'),
    );
    return asset['path'] as String;
  }

  List<String> _stringList(Object? value) {
    if (value is! List<dynamic>) {
      return const [];
    }

    return value.map((item) => item as String).toList(growable: false);
  }

  String _assetPathById(Map<String, dynamic> json, String assetId) {
    final assets = json['assets'] as Map<String, dynamic>;
    final items = [
      ...(assets['images'] as List<dynamic>? ?? const []),
      ...(assets['audio'] as List<dynamic>? ?? const []),
    ].cast<Map<String, dynamic>>();

    final asset = items.firstWhere(
      (item) => item['assetId'] == assetId,
      orElse: () => throw FormatException('Unknown asset id: $assetId'),
    );
    return _normalizeAuthoringAssetPath(asset['path'] as String);
  }

  String _normalizeAuthoringAssetPath(String path) {
    return path
        .replaceFirst('assets/images/cases/', 'assets/images/')
        .replaceFirst('nadeem_raef.webp', 'nadim_raef.webp')
        .replaceFirst('samy_abdallah.webp', 'sami_abdallah.webp')
        .replaceFirst('hesham_nasr.webp', 'hisham_nasr.webp')
        .replaceFirst('original_start.mp3', 'original_recording_start.mp3')
        .replaceFirst('yara_unsent.mp3', 'yara_unsent_voice_note.mp3');
  }

  int _discussionSecondsForStage(int stageNumber) {
    return switch (stageNumber) {
      1 => 240,
      2 || 3 => 300,
      4 => 360,
      _ => 420,
    };
  }
}
