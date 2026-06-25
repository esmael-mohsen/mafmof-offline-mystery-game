import 'package:equatable/equatable.dart';

class VotingRoundEntity extends Equatable {
  const VotingRoundEntity({
    required this.roundId,
    required this.stageNumber,
    required this.voteType,
    required this.attemptNumber,
    required this.eligibleVoterIds,
    required this.eligibleTargetIds,
    this.votesByVoterId = const <String, String>{},
    this.tiedPlayerIds = const <String>[],
    this.resolvedTargetId,
    this.isConfirmed = false,
    this.parentRoundId,
  });

  final String roundId;
  final int stageNumber;
  final String voteType;
  final int attemptNumber;
  final List<String> eligibleVoterIds;
  final List<String> eligibleTargetIds;
  final Map<String, String> votesByVoterId;
  final List<String> tiedPlayerIds;
  final String? resolvedTargetId;
  final bool isConfirmed;
  final String? parentRoundId;

  bool get hasCompleteBallot => votesByVoterId.length == eligibleVoterIds.length;

  bool get isTied => tiedPlayerIds.isNotEmpty && resolvedTargetId == null;

  bool get isReviewOnly => isConfirmed;

  String? voteFor(String voterId) => votesByVoterId[voterId];

  VotingRoundEntity copyWith({
    String? roundId,
    int? stageNumber,
    String? voteType,
    int? attemptNumber,
    List<String>? eligibleVoterIds,
    List<String>? eligibleTargetIds,
    Map<String, String>? votesByVoterId,
    List<String>? tiedPlayerIds,
    Object? resolvedTargetId = _sentinel,
    bool? isConfirmed,
    Object? parentRoundId = _sentinel,
  }) {
    return VotingRoundEntity(
      roundId: roundId ?? this.roundId,
      stageNumber: stageNumber ?? this.stageNumber,
      voteType: voteType ?? this.voteType,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      eligibleVoterIds: eligibleVoterIds ?? this.eligibleVoterIds,
      eligibleTargetIds: eligibleTargetIds ?? this.eligibleTargetIds,
      votesByVoterId: votesByVoterId ?? this.votesByVoterId,
      tiedPlayerIds: tiedPlayerIds ?? this.tiedPlayerIds,
      resolvedTargetId: resolvedTargetId == _sentinel
          ? this.resolvedTargetId
          : resolvedTargetId as String?,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      parentRoundId: parentRoundId == _sentinel
          ? this.parentRoundId
          : parentRoundId as String?,
    );
  }

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [
        roundId,
        stageNumber,
        voteType,
        attemptNumber,
        eligibleVoterIds,
        eligibleTargetIds,
        votesByVoterId,
        tiedPlayerIds,
        resolvedTargetId,
        isConfirmed,
        parentRoundId,
      ];
}
