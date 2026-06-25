import 'package:drift/drift.dart';

import '../../constants/database_constants.dart';

class AppSettings extends Table {
  @override
  String get tableName => 'app_settings';

  IntColumn get id =>
      integer().clientDefault(() => DatabaseConstants.defaultSettingsId)();

  BoolColumn get soundEnabled =>
      boolean().withDefault(const Constant(DatabaseConstants.defaultSoundEnabled))();

  RealColumn get soundVolume =>
      real().withDefault(const Constant(DatabaseConstants.defaultSoundVolume))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
