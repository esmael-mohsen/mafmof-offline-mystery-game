import 'package:equatable/equatable.dart';

class StageTimerEntity extends Equatable {
  const StageTimerEntity({
    required this.stageNumber,
    required this.durationSeconds,
    required this.remainingSeconds,
    required this.isRunning,
    this.warningThresholdSeconds = 30,
    this.hasTriggeredWarningSfx = false,
  });

  final int stageNumber;
  final int durationSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final int warningThresholdSeconds;
  final bool hasTriggeredWarningSfx;

  bool get isWarning => remainingSeconds <= warningThresholdSeconds;

  StageTimerEntity copyWith({
    int? stageNumber,
    int? durationSeconds,
    int? remainingSeconds,
    bool? isRunning,
    int? warningThresholdSeconds,
    bool? hasTriggeredWarningSfx,
  }) {
    return StageTimerEntity(
      stageNumber: stageNumber ?? this.stageNumber,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      warningThresholdSeconds:
          warningThresholdSeconds ?? this.warningThresholdSeconds,
      hasTriggeredWarningSfx:
          hasTriggeredWarningSfx ?? this.hasTriggeredWarningSfx,
    );
  }

  @override
  List<Object?> get props => [
        stageNumber,
        durationSeconds,
        remainingSeconds,
        isRunning,
        warningThresholdSeconds,
        hasTriggeredWarningSfx,
      ];
}
