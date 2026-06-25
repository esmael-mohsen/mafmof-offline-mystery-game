import 'package:equatable/equatable.dart';

class AppSettingsEntity extends Equatable {
  const AppSettingsEntity({
    required this.id,
    required this.soundEnabled,
    required this.soundVolume,
  });

  final int id;
  final bool soundEnabled;
  final double soundVolume;

  @override
  List<Object?> get props => [id, soundEnabled, soundVolume];
}
