import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import '../constants/database_constants.dart';

QueryExecutor createDatabaseConnection() {
  return DatabaseConnection.delayed(
    _openWasmConnection(),
    dialect: SqlDialect.sqlite,
  );
}

Future<DatabaseConnection> _openWasmConnection() async {
  final result = await WasmDatabase.open(
    databaseName: DatabaseConstants.webDatabaseName,
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.dart.js'),
  );

  return result.resolvedExecutor;
}
