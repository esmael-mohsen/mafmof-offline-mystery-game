import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../models/app_settings_model.dart';

AppSettingsEntity appSettingsModelToEntity(AppSettingsModel model) {
  return AppSettingsEntity(
    id: model.id,
    soundEnabled: model.soundEnabled,
    soundVolume: model.soundVolume,
  );
}

AppSettingsCompanion appSettingsModelToCompanion(AppSettingsModel model) {
  return AppSettingsCompanion.insert(
    id: Value(model.id),
    soundEnabled: Value(model.soundEnabled),
    soundVolume: Value(model.soundVolume),
  );
}
