import 'package:equatable/equatable.dart';

class EliminationRecordEntity extends Equatable {
  const EliminationRecordEntity({
    required this.playerId,
    required this.stageNumber,
    required this.order,
  });

  final String playerId;
  final int stageNumber;
  final int order;

  @override
  List<Object?> get props => [playerId, stageNumber, order];
}
