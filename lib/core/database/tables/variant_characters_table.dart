import 'package:drift/drift.dart';

import 'case_variants_table.dart';
import 'characters_table.dart';

class VariantCharacters extends Table {
  @override
  String get tableName => 'variant_characters';

  TextColumn get id => text()();

  TextColumn get variantId => text().references(CaseVariants, #id)();

  TextColumn get characterId => text().references(Characters, #id)();

  TextColumn get participationType => text()();

  IntColumn get displayOrder => integer()();

  TextColumn get evidenceNote => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
