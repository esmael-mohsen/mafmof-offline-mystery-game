import 'package:drift/drift.dart';

import 'cases_table.dart';

class CaseVariants extends Table {
  @override
  String get tableName => 'case_variants';

  TextColumn get id => text()();

  TextColumn get caseId => text().references(Cases, #id)();

  IntColumn get playerCount => integer()();

  TextColumn get displayLabel => text()();

  TextColumn get publicSynopsis => text()();

  TextColumn get finalExplanation => text()();

  TextColumn get innocentWinText => text().nullable()();

  TextColumn get mafiaWinText => text().nullable()();

  IntColumn get stageCount => integer()();

  BoolColumn get isPlayable => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {caseId, playerCount},
      ];
}
