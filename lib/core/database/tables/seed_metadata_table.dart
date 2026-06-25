import 'package:drift/drift.dart';

class SeedMetadata extends Table {
  @override
  String get tableName => 'seed_metadata';

  TextColumn get seedKey => text()();

  IntColumn get seedVersion => integer()();

  DateTimeColumn get appliedAt => dateTime()();

  TextColumn get status => text().withDefault(const Constant('applied'))();

  @override
  Set<Column<Object>> get primaryKey => {seedKey};
}
