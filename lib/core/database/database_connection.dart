import 'package:drift/drift.dart';

import 'database_connection_io.dart'
    if (dart.library.js_interop) 'database_connection_web.dart' as impl;

QueryExecutor openDatabaseConnection() => impl.createDatabaseConnection();
