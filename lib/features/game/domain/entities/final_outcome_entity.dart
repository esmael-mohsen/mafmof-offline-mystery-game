import 'package:equatable/equatable.dart';

import 'elimination_record_entity.dart';
import 'session_player_entity.dart';

class FinalOutcomeEntity extends Equatable {
  const FinalOutcomeEntity({
    required this.accusedPlayerId,
    required this.winningTeam,
    required this.allMafiosoEliminatedBeforeFinal,
    required this.finalExplanation,
    this.roleSummary = const <SessionPlayerEntity>[],
    this.eliminationSummary = const <EliminationRecordEntity>[],
    this.suspicionSummary = const <String, int>{},
    this.innocentWinText,
    this.mafiaWinText,
  });

  final String accusedPlayerId;
  final String winningTeam;
  final bool allMafiosoEliminatedBeforeFinal;
  final String finalExplanation;
  final List<SessionPlayerEntity> roleSummary;
  final List<EliminationRecordEntity> eliminationSummary;
  final Map<String, int> suspicionSummary;
  final String? innocentWinText;
  final String? mafiaWinText;

  @override
  List<Object?> get props => [
        accusedPlayerId,
        winningTeam,
        allMafiosoEliminatedBeforeFinal,
        finalExplanation,
        roleSummary,
        eliminationSummary,
        suspicionSummary,
        innocentWinText,
        mafiaWinText,
      ];
}
