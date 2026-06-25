import 'package:drift/drift.dart';

import 'cases_table.dart';

class Characters extends Table {
  @override
  String get tableName => 'characters';

  TextColumn get id => text()();

  TextColumn get caseId => text().references(Cases, #id)();

  TextColumn get name => text()();

  TextColumn get title => text().nullable()();

  TextColumn get portraitAssetPath => text()();

  TextColumn get publicBio => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
