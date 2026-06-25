import '../../../../core/database/app_database.dart';

class RoleAssignmentModel {
  const RoleAssignmentModel({
    required this.id,
    required this.variantId,
    required this.characterId,
    required this.team,
    required this.roleName,
    required this.publicInfo,
    required this.secret,
    required this.secretMeaning,
    required this.goal,
    this.tasks,
    this.specialAbility,
    this.mustNotSay,
  });

  final String id;
  final String variantId;
  final String characterId;
  final String team;
  final String roleName;
  final String publicInfo;
  final String secret;
  final String secretMeaning;
  final String goal;
  final String? tasks;
  final String? specialAbility;
  final String? mustNotSay;

  factory RoleAssignmentModel.fromRow(RoleAssignment row) {
    return RoleAssignmentModel(
      id: row.id,
      variantId: row.variantId,
      characterId: row.characterId,
      team: row.team,
      roleName: row.roleName,
      publicInfo: row.publicInfo,
      secret: row.secret,
      secretMeaning: row.secretMeaning,
      goal: row.goal,
      tasks: row.tasks,
      specialAbility: row.specialAbility,
      mustNotSay: row.mustNotSay,
    );
  }
}
