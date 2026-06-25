import 'package:drift/drift.dart';

import 'case_variants_table.dart';
import 'characters_table.dart';

class RoleAssignments extends Table {
  @override
  String get tableName => 'role_assignments';

  TextColumn get id => text()();

  TextColumn get variantId => text().references(CaseVariants, #id)();

  TextColumn get characterId => text().references(Characters, #id)();

  TextColumn get team => text()();

  TextColumn get roleName => text()();

  TextColumn get publicInfo => text()();

  TextColumn get secret => text()();

  TextColumn get secretMeaning => text()();

  TextColumn get goal => text()();

  TextColumn get tasks => text().nullable()();

  TextColumn get specialAbility => text().nullable()();

  TextColumn get mustNotSay => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
