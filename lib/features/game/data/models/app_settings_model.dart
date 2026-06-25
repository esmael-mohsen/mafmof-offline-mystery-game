import '../../../../core/constants/database_constants.dart';
import '../../../../core/database/app_database.dart';

class AppSettingsModel {
  const AppSettingsModel({
    required this.id,
    required this.soundEnabled,
    required this.soundVolume,
  });

  final int id;
  final bool soundEnabled;
  final double soundVolume;

  factory AppSettingsModel.defaults() {
    return const AppSettingsModel(
      id: DatabaseConstants.defaultSettingsId,
      soundEnabled: DatabaseConstants.defaultSoundEnabled,
      soundVolume: DatabaseConstants.defaultSoundVolume,
    );
  }

  factory AppSettingsModel.fromRow(AppSetting row) {
    return AppSettingsModel(
      id: row.id,
      soundEnabled: row.soundEnabled,
      soundVolume: row.soundVolume,
    );
  }

  AppSettingsModel copyWith({bool? soundEnabled, double? soundVolume}) {
    return AppSettingsModel(
      id: id,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
    );
  }
}
