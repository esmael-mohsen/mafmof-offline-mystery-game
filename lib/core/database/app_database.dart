import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../constants/database_constants.dart';
import 'database_connection.dart';
import 'tables/app_settings_table.dart';
import 'tables/case_variants_table.dart';
import 'tables/cases_table.dart';
import 'tables/characters_table.dart';
import 'tables/role_assignments_table.dart';
import 'tables/seed_metadata_table.dart';
import 'tables/stages_table.dart';
import 'tables/variant_characters_table.dart';

part 'app_database.g.dart';

@lazySingleton
@DriftDatabase(
  tables: [
    AppSettings,
    SeedMetadata,
    Cases,
    CaseVariants,
    Characters,
    VariantCharacters,
    RoleAssignments,
    Stages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          for (final table in allSchemaEntities) {
            if (table is TableInfo<Table, dynamic>) {
              await migrator.deleteTable(table.actualTableName);
            }
          }
          await migrator.createAll();
        },
      );
}
