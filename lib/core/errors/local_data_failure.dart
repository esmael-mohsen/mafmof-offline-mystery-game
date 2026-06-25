enum LocalDataFailureType {
  invalidSeed,
  missingCatalog,
  missingCase,
  missingVariant,
  unsupportedPlayerCount,
  database,
}

class LocalDataFailure implements Exception {
  const LocalDataFailure({
    required this.type,
    required this.message,
    this.canRetry = false,
    this.hasFallbackCatalog = false,
  });

  final LocalDataFailureType type;
  final String message;
  final bool canRetry;
  final bool hasFallbackCatalog;

  @override
  String toString() => 'LocalDataFailure(type: $type, message: $message)';
}
