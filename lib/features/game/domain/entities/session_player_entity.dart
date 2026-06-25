import 'package:equatable/equatable.dart';

class SessionPlayerEntity extends Equatable {
  const SessionPlayerEntity({
    required this.playerId,
    required this.displayName,
    required this.characterId,
    required this.characterName,
    required this.portraitAssetPath,
    required this.roleName,
    required this.team,
    required this.publicInfo,
    this.characterTitle,
    this.secret,
    this.secretMeaning,
    this.goal,
    this.tasks,
    this.specialAbility,
    this.mustNotSay,
    this.isEliminated = false,
  });

  final String playerId;
  final String displayName;
  final String characterId;
  final String characterName;
  final String? characterTitle;
  final String portraitAssetPath;
  final String roleName;
  final String team;
  final String publicInfo;
  final String? secret;
  final String? secretMeaning;
  final String? goal;
  final String? tasks;
  final String? specialAbility;
  final String? mustNotSay;
  final bool isEliminated;

  SessionPlayerEntity copyWith({
    String? playerId,
    String? displayName,
    String? characterId,
    String? characterName,
    String? portraitAssetPath,
    String? roleName,
    String? team,
    String? publicInfo,
    Object? characterTitle = _sentinel,
    Object? secret = _sentinel,
    Object? secretMeaning = _sentinel,
    Object? goal = _sentinel,
    Object? tasks = _sentinel,
    Object? specialAbility = _sentinel,
    Object? mustNotSay = _sentinel,
    bool? isEliminated,
  }) {
    return SessionPlayerEntity(
      playerId: playerId ?? this.playerId,
      displayName: displayName ?? this.displayName,
      characterId: characterId ?? this.characterId,
      characterName: characterName ?? this.characterName,
      portraitAssetPath: portraitAssetPath ?? this.portraitAssetPath,
      roleName: roleName ?? this.roleName,
      team: team ?? this.team,
      publicInfo: publicInfo ?? this.publicInfo,
      characterTitle: characterTitle == _sentinel
          ? this.characterTitle
          : characterTitle as String?,
      secret: secret == _sentinel ? this.secret : secret as String?,
      secretMeaning: secretMeaning == _sentinel
          ? this.secretMeaning
          : secretMeaning as String?,
      goal: goal == _sentinel ? this.goal : goal as String?,
      tasks: tasks == _sentinel ? this.tasks : tasks as String?,
      specialAbility: specialAbility == _sentinel
          ? this.specialAbility
          : specialAbility as String?,
      mustNotSay:
          mustNotSay == _sentinel ? this.mustNotSay : mustNotSay as String?,
      isEliminated: isEliminated ?? this.isEliminated,
    );
  }

  static const Object _sentinel = Object();

  List<MapEntry<String, String>> get privateSections {
    final sections = <MapEntry<String, String>>[];

    void addIfPresent(String label, String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        sections.add(MapEntry(label, trimmed));
      }
    }

    addIfPresent('secret', secret);
    addIfPresent('secretMeaning', secretMeaning);
    addIfPresent('goal', goal);
    addIfPresent('tasks', tasks);
    addIfPresent('specialAbility', specialAbility);
    addIfPresent('mustNotSay', mustNotSay);

    return sections;
  }

  bool get isMafiaTeam => team == 'mafia' || team == 'mafia_support';

  String get localizedRoleName {
    final normalized = roleName.trim().toLowerCase();
    if (team == 'mafia_support' ||
        normalized == 'agent' ||
        normalized.contains('support')) {
      return 'مساعد المافيا';
    }
    if (team == 'mafia' ||
        normalized == 'mafioso' ||
        normalized.contains('killer')) {
      return 'مافيا';
    }
    if (normalized == 'detective') {
      return 'المحقق';
    }
    if (normalized == 'witness') {
      return 'شاهد';
    }
    if (normalized.contains('innocent suspect')) {
      return 'بريء مشتبه به';
    }
    if (normalized.contains('innocent')) {
      return 'بريء';
    }
    return roleName;
  }

  String get localizedTeamName {
    if (team == 'mafia') {
      return 'فريق المافيا';
    }
    if (team == 'mafia_support') {
      return 'داعم للمافيا';
    }
    return 'فريق الأبرياء';
  }

  String? mafiaIntelLine(List<SessionPlayerEntity> players) {
    if (!isMafiaTeam) {
      return null;
    }

    final mafioso = players
        .where(
            (player) => player.playerId != playerId && player.team == 'mafia')
        .map((player) => player.displayName)
        .toList(growable: false);
    final support = players
        .where((player) =>
            player.playerId != playerId && player.team == 'mafia_support')
        .map((player) => player.displayName)
        .toList(growable: false);

    final sections = <String>[];
    if (mafioso.isNotEmpty) {
      sections.add('المافيا معاك: ${mafioso.join('، ')}');
    }
    if (support.isNotEmpty) {
      sections.add('مساعد المافيا: ${support.join('، ')}');
    }
    if (sections.isEmpty) {
      return 'أنت عضو المافيا الوحيد في هذه النسخة.';
    }
    return sections.join('\n');
  }

  @override
  List<Object?> get props => [
        playerId,
        displayName,
        characterId,
        characterName,
        characterTitle,
        portraitAssetPath,
        roleName,
        team,
        publicInfo,
        secret,
        secretMeaning,
        goal,
        tasks,
        specialAbility,
        mustNotSay,
        isEliminated,
      ];
}
