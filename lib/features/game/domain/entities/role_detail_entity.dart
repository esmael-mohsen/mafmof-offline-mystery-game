import 'package:equatable/equatable.dart';

class RoleDetailEntity extends Equatable {
  const RoleDetailEntity({
    required this.characterId,
    required this.team,
    required this.roleName,
    required this.publicInfo,
    this.secret,
    this.secretMeaning,
    this.goal,
    this.tasks,
    this.specialAbility,
    this.mustNotSay,
  });

  final String characterId;
  final String team;
  final String roleName;
  final String publicInfo;
  final String? secret;
  final String? secretMeaning;
  final String? goal;
  final String? tasks;
  final String? specialAbility;
  final String? mustNotSay;

  @override
  List<Object?> get props => [
        characterId,
        team,
        roleName,
        publicInfo,
        secret,
        secretMeaning,
        goal,
        tasks,
        specialAbility,
        mustNotSay,
      ];
}
