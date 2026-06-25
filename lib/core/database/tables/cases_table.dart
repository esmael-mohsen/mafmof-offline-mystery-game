import 'package:drift/drift.dart';

class Cases extends Table {
  @override
  String get tableName => 'cases';

  TextColumn get id => text()();

  TextColumn get title => text()();

  TextColumn get subtitle => text()();

  TextColumn get summary => text()();

  TextColumn get setting => text().nullable()();

  IntColumn get durationMinutes => integer().nullable()();

  TextColumn get difficulty => text().nullable()();

  IntColumn get minPlayers => integer().nullable()();

  IntColumn get maxPlayers => integer().nullable()();

  TextColumn get coverAssetPath => text()();

  TextColumn get openingAssetPath => text().nullable()();

  TextColumn get finalRevealAssetPath => text().nullable()();

  TextColumn get roleRevealBackgroundAssetPath => text().nullable()();

  TextColumn get openingScript => text().nullable()();

  TextColumn get coreTruth => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  IntColumn get seedVersion => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
