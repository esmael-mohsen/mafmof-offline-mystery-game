import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/database_constants.dart';

QueryExecutor createDatabaseConnection() {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return NativeDatabase.memory();
  }

  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(directory.path, DatabaseConstants.databaseName),
    );

    return NativeDatabase.createInBackground(file);
  });
}
