import 'package:equatable/equatable.dart';

import 'elimination_record_entity.dart';
import 'final_outcome_entity.dart';
import 'session_player_entity.dart';
import 'stage_timer_entity.dart';
import 'voting_round_entity.dart';

class GameSessionEntity extends Equatable {
  const GameSessionEntity({
    required this.sessionId,
    required this.caseId,
    required this.caseTitle,
    required this.variantId,
    required this.playerCount,
    required this.players,
    required this.revealIndex,
    required this.roleRevealComplete,
    this.visitedStages = const <int>[],
    this.resolvedStageNumbers = const <int>[],
    this.currentStageNumber,
    this.timer,
    this.eliminatedPlayerIds = const <String>[],
    this.suspicionMarks = const <String, int>{},
    this.currentVoteRound,
    this.voteRounds = const <VotingRoundEntity>[],
    this.eliminationRecords = const <EliminationRecordEntity>[],
    this.finalOutcome,
    this.isCompleted = false,
  });

  final String sessionId;
  final String caseId;
  final String caseTitle;
  final String variantId;
  final int playerCount;
  final List<SessionPlayerEntity> players;
  final int revealIndex;
  final bool roleRevealComplete;
  final List<int> visitedStages;
  final List<int> resolvedStageNumbers;
  final int? currentStageNumber;
  final StageTimerEntity? timer;
  final List<String> eliminatedPlayerIds;
  final Map<String, int> suspicionMarks;
  final VotingRoundEntity? currentVoteRound;
  final List<VotingRoundEntity> voteRounds;
  final List<EliminationRecordEntity> eliminationRecords;
  final FinalOutcomeEntity? finalOutcome;
  final bool isCompleted;

  SessionPlayerEntity? get currentPlayer {
    if (revealIndex < 0 || revealIndex >= players.length) {
      return null;
    }
    return players[revealIndex];
  }

  int get recommendedNextStage {
    for (var index = 1; index <= 5; index += 1) {
      if (!resolvedStageNumbers.contains(index)) {
        return index;
      }
    }
    return 5;
  }

  bool get hasFinalOutcome => finalOutcome != null;

  bool get canShowFinalReveal => finalOutcome != null;

  bool isStageResolved(int stageNumber) => resolvedStageNumbers.contains(stageNumber);

  bool isPlayerEliminated(String playerId) => eliminatedPlayerIds.contains(playerId);

  VotingRoundEntity? confirmedRoundForStage(int stageNumber) {
    for (final round in voteRounds.reversed) {
      if (round.stageNumber == stageNumber && round.isConfirmed) {
        return round;
      }
    }
    return null;
  }

  GameSessionEntity copyWith({
    String? sessionId,
    String? caseId,
    String? caseTitle,
    String? variantId,
    int? playerCount,
    List<SessionPlayerEntity>? players,
    int? revealIndex,
    bool? roleRevealComplete,
    List<int>? visitedStages,
    List<int>? resolvedStageNumbers,
    Object? currentStageNumber = _sentinel,
    Object? timer = _sentinel,
    List<String>? eliminatedPlayerIds,
    Map<String, int>? suspicionMarks,
    Object? currentVoteRound = _sentinel,
    List<VotingRoundEntity>? voteRounds,
    List<EliminationRecordEntity>? eliminationRecords,
    Object? finalOutcome = _sentinel,
    bool? isCompleted,
  }) {
    return GameSessionEntity(
      sessionId: sessionId ?? this.sessionId,
      caseId: caseId ?? this.caseId,
      caseTitle: caseTitle ?? this.caseTitle,
      variantId: variantId ?? this.variantId,
      playerCount: playerCount ?? this.playerCount,
      players: players ?? this.players,
      revealIndex: revealIndex ?? this.revealIndex,
      roleRevealComplete: roleRevealComplete ?? this.roleRevealComplete,
      visitedStages: visitedStages ?? this.visitedStages,
      resolvedStageNumbers: resolvedStageNumbers ?? this.resolvedStageNumbers,
      currentStageNumber: currentStageNumber == _sentinel
          ? this.currentStageNumber
          : currentStageNumber as int?,
      timer: timer == _sentinel ? this.timer : timer as StageTimerEntity?,
      eliminatedPlayerIds: eliminatedPlayerIds ?? this.eliminatedPlayerIds,
      suspicionMarks: suspicionMarks ?? this.suspicionMarks,
      currentVoteRound: currentVoteRound == _sentinel
          ? this.currentVoteRound
          : currentVoteRound as VotingRoundEntity?,
      voteRounds: voteRounds ?? this.voteRounds,
      eliminationRecords: eliminationRecords ?? this.eliminationRecords,
      finalOutcome: finalOutcome == _sentinel
          ? this.finalOutcome
          : finalOutcome as FinalOutcomeEntity?,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [
        sessionId,
        caseId,
        caseTitle,
        variantId,
        playerCount,
        players,
        revealIndex,
        roleRevealComplete,
        visitedStages,
        resolvedStageNumbers,
        currentStageNumber,
        timer,
        eliminatedPlayerIds,
        suspicionMarks,
        currentVoteRound,
        voteRounds,
        eliminationRecords,
        finalOutcome,
        isCompleted,
      ];
}
