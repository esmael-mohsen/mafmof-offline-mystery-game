import 'package:drift/drift.dart';

import 'case_variants_table.dart';

class Stages extends Table {
  @override
  String get tableName => 'stages';

  TextColumn get id => text()();

  TextColumn get variantId => text().references(CaseVariants, #id)();

  IntColumn get stageNumber => integer()();

  TextColumn get title => text()();

  TextColumn get hostScript => text().nullable()();

  TextColumn get publicClue => text()();

  TextColumn get hostNote => text()();

  TextColumn get expectedFocus => text()();

  IntColumn get discussionSeconds => integer()();

  TextColumn get voteType => text()();

  TextColumn get imageAssetPath => text().nullable()();

  TextColumn get audioAssetPath => text().nullable()();

  TextColumn get audioTitle => text().nullable()();

  IntColumn get audioDurationSeconds => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {variantId, stageNumber},
      ];
}
