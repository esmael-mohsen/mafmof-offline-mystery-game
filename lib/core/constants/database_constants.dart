class DatabaseConstants {
  const DatabaseConstants._();

  static const databaseName = 'mafmof.sqlite';
  static const webDatabaseName = 'mafmof_web';
  static const caseCatalogSeedKey = 'case_catalog';
  static const caseSeedAssetPath =
      'assets/data/cases/case01_farah_eltagamoa.json';
  static const caseSeedAssetPaths = <String>[
    'assets/data/cases/case01_farah_eltagamoa.json',
    'assets/data/cases/case02_room_707.json',
    'assets/data/cases/case03_black_rose.json',
    'assets/data/cases/case_04_last_therapy_session.json',
    'assets/data/cases/case_04_last_session.json',
  ];
  static const defaultSettingsId = 1;
  static const defaultSoundEnabled = true;
  static const defaultSoundVolume = 0.7;
  static const minimumSupportedPlayerCount = 5;
  static const maximumSupportedPlayerCount = 8;
  static const expectedStageCount = 5;
}
