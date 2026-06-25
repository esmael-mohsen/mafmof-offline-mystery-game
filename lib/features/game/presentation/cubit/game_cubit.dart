import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/audio/audio_service.dart';
import '../../../../core/constants/app_media.dart';
import '../../../../core/constants/app_text.dart';
import '../../../../core/errors/local_data_failure.dart';
import '../../domain/entities/case_variant_entity.dart';
import '../../domain/entities/content_visibility_tier.dart';
import '../../domain/entities/elimination_record_entity.dart';
import '../../domain/entities/final_outcome_entity.dart';
import '../../domain/entities/game_session_entity.dart';
import '../../domain/entities/session_player_entity.dart';
import '../../domain/entities/stage_entity.dart';
import '../../domain/entities/stage_timer_entity.dart';
import '../../domain/entities/voting_round_entity.dart';
import '../../domain/repositories/game_repository.dart';
import 'game_state.dart';

@injectable
class GameCubit extends Cubit<GameState> {
  GameCubit(
    this._repository,
    this._audioService, {
    Random? random,
  })  : _random = random ?? Random.secure(),
        super(const GameState());

  final GameRepository _repository;
  final AudioService _audioService;
  final Random _random;

  Timer? _stageTimer;

  Future<void> bootstrap() async {
    emit(
      state.copyWith(
        catalogStatus: CatalogStatus.loading,
        errorMessage: null,
        canRetryCatalogLoad: false,
        hasFallbackCatalog: false,
      ),
    );

    final settings = await _repository.getAppSettings();
    await _audioService.setEnabled(settings.soundEnabled);
    await _audioService.setVolume(settings.soundVolume);
    await _audioService.playSfx(AppMedia.appStartSfx);

    try {
      await _repository.initializeLocalCatalog();
      final cases = await _repository.getActiveCases();
      emit(
        state.copyWith(
          catalogStatus: CatalogStatus.ready,
          availableCases: cases,
          soundEnabled: settings.soundEnabled,
          soundVolume: settings.soundVolume,
          errorMessage: null,
          canRetryCatalogLoad: false,
          hasFallbackCatalog: false,
        ),
      );
    } on LocalDataFailure catch (failure) {
      final cases = await _repository.getActiveCases();
      final hasFallbackCatalog = cases.isNotEmpty;
      emit(
        state.copyWith(
          catalogStatus:
              hasFallbackCatalog ? CatalogStatus.ready : CatalogStatus.failure,
          availableCases: cases,
          soundEnabled: settings.soundEnabled,
          soundVolume: settings.soundVolume,
          errorMessage: failure.message,
          canRetryCatalogLoad: failure.canRetry,
          hasFallbackCatalog: hasFallbackCatalog || failure.hasFallbackCatalog,
        ),
      );
    }
  }

  Future<void> retryCatalogInitialization() => bootstrap();

  Future<void> loadCase(String caseId) async {
    final selectedCase = await _repository.getCaseById(caseId);
    CaseVariantEntity? previewVariant;
    if (selectedCase != null) {
      final variants = await _repository.getVariantsForCase(caseId);
      if (variants.isNotEmpty) {
        previewVariant = variants.reduce(
          (current, next) =>
              next.playerCount > current.playerCount ? next : current,
        );
      }
    }
    if (selectedCase != null) {
      await _audioService.playSfx(AppMedia.caseSelectSfx);
    }
    emit(
      state.copyWith(
        selectedCase: selectedCase,
        casePreviewVariant: previewVariant,
        errorMessage: selectedCase == null ? AppText.missingCaseMessage : null,
      ),
    );
  }

  Future<void> prepareVariantForSetup(String caseId, int playerCount) async {
    try {
      final variant = await _repository.getVariantByPlayerCount(
        caseId,
        playerCount,
        visibility: ContentVisibilityTier.private,
      );

      emit(
        state.copyWith(
          preparedVariant: variant,
          selectedPlayerCount: playerCount,
          errorMessage:
              variant == null ? AppText.unsupportedCountMessage : null,
        ),
      );
    } on LocalDataFailure catch (failure) {
      emit(
        state.copyWith(
          preparedVariant: null,
          selectedPlayerCount: playerCount,
          errorMessage: failure.message,
        ),
      );
    }
  }

  Future<String?> startSession({
    required String caseId,
    required int playerCount,
    required List<String> playerNames,
  }) async {
    if (!_isSupportedPlayerCount(playerCount)) {
      emit(state.copyWith(errorMessage: AppText.unsupportedCountMessage));
      return null;
    }

    final normalizedNames = playerNames.map((item) => item.trim()).toList();
    if (normalizedNames.length != playerCount ||
        normalizedNames.any((item) => item.isEmpty)) {
      emit(state.copyWith(errorMessage: AppText.blankPlayerNameMessage));
      return null;
    }

    final uniquenessKeys =
        normalizedNames.map((item) => item.toLowerCase()).toSet();
    if (uniquenessKeys.length != normalizedNames.length) {
      emit(state.copyWith(errorMessage: AppText.duplicatePlayerNameMessage));
      return null;
    }

    CaseVariantEntity? variant = state.preparedVariant;
    if (variant == null ||
        variant.caseId != caseId ||
        variant.playerCount != playerCount) {
      variant = await _repository.getVariantByPlayerCount(
        caseId,
        playerCount,
        visibility: ContentVisibilityTier.private,
      );
    }

    final selectedCase =
        state.selectedCase ?? await _repository.getCaseById(caseId);
    if (selectedCase == null || variant == null) {
      emit(state.copyWith(errorMessage: AppText.invalidSessionMessage));
      return null;
    }

    final activeCharacters = variant.characters
        .where((item) => item.isActiveParticipant)
        .toList(growable: false)
      ..sort((left, right) => left.displayOrder.compareTo(right.displayOrder));

    if (activeCharacters.length != playerCount) {
      emit(state.copyWith(errorMessage: AppText.invalidSessionMessage));
      return null;
    }

    final roleByCharacterId = {
      for (final role in variant.roleDetails) role.characterId: role,
    };

    final shuffledCharacters = activeCharacters.toList(growable: false)
      ..shuffle(_random);

    final players = <SessionPlayerEntity>[];
    for (var index = 0; index < shuffledCharacters.length; index += 1) {
      final character = shuffledCharacters[index];
      final role = roleByCharacterId[character.id];
      if (role == null) {
        emit(state.copyWith(errorMessage: AppText.invalidSessionMessage));
        return null;
      }

      players.add(
        SessionPlayerEntity(
          playerId: character.id,
          displayName: normalizedNames[index],
          characterId: character.id,
          characterName: character.name,
          characterTitle: character.title,
          portraitAssetPath: character.portraitAssetPath,
          roleName: role.roleName,
          team: role.team,
          publicInfo: role.publicInfo,
          secret: role.secret,
          secretMeaning: role.secretMeaning,
          goal: role.goal,
          tasks: role.tasks,
          specialAbility: role.specialAbility,
          mustNotSay: role.mustNotSay,
        ),
      );
    }

    final sessionId = 'session_${DateTime.now().microsecondsSinceEpoch}';
    final session = GameSessionEntity(
      sessionId: sessionId,
      caseId: selectedCase.id,
      caseTitle: selectedCase.title,
      variantId: variant.id,
      playerCount: playerCount,
      players: players,
      revealIndex: 0,
      roleRevealComplete: false,
    );

    _cancelStageTimer();
    emit(
      state.copyWith(
        selectedCase: selectedCase,
        preparedVariant: variant,
        activeSession: session,
        currentStage: null,
        stageTimer: null,
        isCurrentRoleVisible: false,
        errorMessage: null,
      ),
    );
    return sessionId;
  }

  Future<void> revealCurrentRole() async {
    if (state.activeSession == null ||
        state.activeSession!.roleRevealComplete) {
      emit(state.copyWith(errorMessage: AppText.roleRevealLockedMessage));
      return;
    }

    emit(
      state.copyWith(
        isCurrentRoleVisible: true,
        errorMessage: null,
      ),
    );
    await _audioService.playSfx(AppMedia.roleRevealSfx);
  }

  Future<void> hideCurrentRole() async {
    emit(
      state.copyWith(
        isCurrentRoleVisible: false,
        errorMessage: null,
      ),
    );
  }

  Future<bool> advanceRoleReveal() async {
    final session = state.activeSession;
    if (session == null) {
      emit(state.copyWith(errorMessage: AppText.invalidSessionMessage));
      return false;
    }

    if (state.isCurrentRoleVisible) {
      emit(state.copyWith(errorMessage: AppText.hideRoleBeforeNextMessage));
      return false;
    }

    if (session.revealIndex >= session.players.length - 1) {
      emit(
        state.copyWith(
          activeSession: session.copyWith(roleRevealComplete: true),
          errorMessage: null,
        ),
      );
      return true;
    }

    emit(
      state.copyWith(
        activeSession: session.copyWith(revealIndex: session.revealIndex + 1),
        errorMessage: null,
      ),
    );
    return false;
  }

  Future<bool> previousRoleReveal() async {
    final session = state.activeSession;
    if (session == null || session.roleRevealComplete) {
      emit(state.copyWith(errorMessage: AppText.roleRevealLockedMessage));
      return false;
    }

    if (state.isCurrentRoleVisible) {
      emit(state.copyWith(errorMessage: AppText.hideRoleBeforeNextMessage));
      return false;
    }

    if (session.revealIndex <= 0) {
      emit(state.copyWith(errorMessage: null));
      return false;
    }

    emit(
      state.copyWith(
        activeSession: session.copyWith(revealIndex: session.revealIndex - 1),
        isCurrentRoleVisible: false,
        errorMessage: null,
      ),
    );
    return true;
  }

  Future<void> openStage(int stageNumber) async {
    final session = state.activeSession;
    final variant = state.preparedVariant;
    if (session == null ||
        !session.roleRevealComplete ||
        variant == null ||
        session.isCompleted) {
      emit(
        state.copyWith(
          errorMessage: session?.isCompleted == true
              ? AppText.completedSessionMessage
              : AppText.invalidSessionMessage,
        ),
      );
      return;
    }

    final stage = _findStage(variant, stageNumber);
    if (stage == null) {
      emit(state.copyWith(errorMessage: AppText.invalidSessionMessage));
      return;
    }

    final isReviewOnly = session.isStageResolved(stageNumber);
    final nextRequiredStage = session.recommendedNextStage;
    if (!isReviewOnly && nextRequiredStage != stageNumber) {
      emit(state.copyWith(errorMessage: AppText.stageOrderBlockedMessage));
      return;
    }

    final visitedStages = <int>{
      ...session.visitedStages,
      stageNumber,
    }.toList(growable: false)
      ..sort();

    _cancelStageTimer();
    if (isReviewOnly) {
      emit(
        state.copyWith(
          activeSession: session.copyWith(
            currentStageNumber: stageNumber,
            visitedStages: visitedStages,
            timer: null,
          ),
          currentStage: stage,
          stageTimer: null,
          currentVoteRound: session.confirmedRoundForStage(stageNumber),
          isCurrentStageReadOnly: true,
          errorMessage: null,
        ),
      );
      return;
    }

    final durationSeconds =
        stage.discussionSeconds > 0 ? stage.discussionSeconds : 180;
    final timer = StageTimerEntity(
      stageNumber: stageNumber,
      durationSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      isRunning: false,
    );

    emit(
      state.copyWith(
        activeSession: session.copyWith(
          currentStageNumber: stageNumber,
          visitedStages: visitedStages,
          timer: timer,
        ),
        currentStage: stage,
        stageTimer: timer,
        currentVoteRound: null,
        isCurrentStageReadOnly: false,
        errorMessage: null,
      ),
    );
    await _audioService.playSfx(AppMedia.clueRevealSfx);
  }

  Future<void> openVoting(int stageNumber) async {
    final session = state.activeSession;
    final variant = state.preparedVariant;
    if (session == null ||
        variant == null ||
        !session.roleRevealComplete ||
        session.isCompleted) {
      emit(
        state.copyWith(
          errorMessage: session?.isCompleted == true
              ? AppText.completedSessionMessage
              : AppText.invalidSessionMessage,
        ),
      );
      return;
    }

    final stage = _findStage(variant, stageNumber);
    if (stage == null) {
      emit(state.copyWith(errorMessage: AppText.invalidSessionMessage));
      return;
    }

    pauseStageTimer();

    final isReviewOnly = session.isStageResolved(stageNumber);
    if (!isReviewOnly && session.recommendedNextStage != stageNumber) {
      emit(state.copyWith(errorMessage: AppText.stageOrderBlockedMessage));
      return;
    }

    final updatedSession = session.copyWith(
      currentStageNumber: stageNumber,
      timer: null,
    );

    if (isReviewOnly) {
      emit(
        state.copyWith(
          activeSession: updatedSession,
          currentStage: stage,
          stageTimer: null,
          currentVoteRound: session.confirmedRoundForStage(stageNumber),
          isCurrentStageReadOnly: true,
          errorMessage: null,
        ),
      );
      return;
    }

    final round = updatedSession.currentVoteRound?.stageNumber == stageNumber &&
            !(updatedSession.currentVoteRound?.isConfirmed ?? true)
        ? updatedSession.currentVoteRound!
        : _createVotingRound(updatedSession, stage);
    final syncedSession = _syncRound(updatedSession, round);

    emit(
      state.copyWith(
        activeSession: syncedSession,
        currentStage: stage,
        stageTimer: null,
        currentVoteRound: round,
        isCurrentStageReadOnly: false,
        errorMessage: null,
      ),
    );
    unawaited(_audioService.playSfx(AppMedia.voteStartSfx));
  }

  void startStageTimer() {
    final timer = state.stageTimer;
    if (timer == null) {
      return;
    }

    _cancelStageTimer();
    final runningTimer = timer.copyWith(isRunning: true);
    _setStageTimer(runningTimer);
    _audioService.playSfx(AppMedia.timerStartSfx);

    _stageTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.stageTimer;
      if (current == null || !current.isRunning) {
        return;
      }

      final remaining = current.remainingSeconds - 1;
      if (remaining <= 0) {
        _setStageTimer(
          current.copyWith(
            remainingSeconds: 0,
            isRunning: false,
          ),
        );
        _cancelStageTimer();
        return;
      }

      final warningTriggered = !current.hasTriggeredWarningSfx &&
          remaining <= current.warningThresholdSeconds;
      if (warningTriggered) {
        _audioService.playSfx(AppMedia.timerWarningSfx);
      }

      _setStageTimer(
        current.copyWith(
          remainingSeconds: remaining,
          hasTriggeredWarningSfx:
              current.hasTriggeredWarningSfx || warningTriggered,
        ),
      );
    });
  }

  void pauseStageTimer() {
    final timer = state.stageTimer;
    if (timer == null) {
      return;
    }

    _cancelStageTimer();
    _setStageTimer(timer.copyWith(isRunning: false));
  }

  void resetStageTimer() {
    final timer = state.stageTimer;
    if (timer == null) {
      return;
    }

    _cancelStageTimer();
    _setStageTimer(
      timer.copyWith(
        remainingSeconds: timer.durationSeconds,
        isRunning: false,
        hasTriggeredWarningSfx: false,
      ),
    );
  }

  void leaveStage() {
    _cancelStageTimer();
    final session = state.activeSession;
    if (session == null) {
      emit(
        state.copyWith(
          currentStage: null,
          stageTimer: null,
          currentVoteRound: null,
          isCurrentStageReadOnly: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        activeSession: session.copyWith(
          currentStageNumber: null,
          timer: null,
        ),
        currentStage: null,
        stageTimer: null,
        currentVoteRound: null,
        isCurrentStageReadOnly: false,
        errorMessage: null,
      ),
    );
  }

  void enterVoting() => leaveStage();

  Future<void> castVote(String voterId, String targetId) async {
    final session = state.activeSession;
    final round = state.currentVoteRound;
    if (session == null || round == null || round.isConfirmed) {
      emit(state.copyWith(errorMessage: AppText.invalidVoteActionMessage));
      return;
    }

    if (!round.eligibleVoterIds.contains(voterId) ||
        !round.eligibleTargetIds.contains(targetId)) {
      emit(state.copyWith(errorMessage: AppText.invalidVoteTargetMessage));
      return;
    }

    final votes = <String, String>{...round.votesByVoterId, voterId: targetId};
    final updatedRound = round.copyWith(
      votesByVoterId: votes,
      tiedPlayerIds: const <String>[],
      resolvedTargetId: null,
    );
    final syncedSession = _syncRound(session, updatedRound);

    emit(
      state.copyWith(
        activeSession: syncedSession,
        currentVoteRound: updatedRound,
        errorMessage: null,
      ),
    );
  }

  Future<void> clearVote(String voterId) async {
    final session = state.activeSession;
    final round = state.currentVoteRound;
    if (session == null || round == null || round.isConfirmed) {
      return;
    }

    final votes = <String, String>{...round.votesByVoterId}..remove(voterId);
    final updatedRound = round.copyWith(
      votesByVoterId: votes,
      tiedPlayerIds: const <String>[],
      resolvedTargetId: null,
    );
    final syncedSession = _syncRound(session, updatedRound);

    emit(
      state.copyWith(
        activeSession: syncedSession,
        currentVoteRound: updatedRound,
        errorMessage: null,
      ),
    );
  }

  Future<void> resolveCurrentVoteRound() async {
    final session = state.activeSession;
    final round = state.currentVoteRound;
    if (session == null || round == null || round.isConfirmed) {
      emit(state.copyWith(errorMessage: AppText.invalidVoteActionMessage));
      return;
    }

    if (!round.hasCompleteBallot) {
      emit(state.copyWith(errorMessage: AppText.incompleteVotesMessage));
      return;
    }

    final tallies = <String, int>{};
    for (final targetId in round.votesByVoterId.values) {
      tallies[targetId] = (tallies[targetId] ?? 0) + 1;
    }
    if (tallies.isEmpty) {
      emit(state.copyWith(errorMessage: AppText.incompleteVotesMessage));
      return;
    }

    final maxVotes =
        tallies.values.reduce((left, right) => left > right ? left : right);
    final highestIds = tallies.entries
        .where((entry) => entry.value == maxVotes)
        .map((entry) => entry.key)
        .toList(growable: false);

    if (highestIds.length > 1) {
      final updatedRound = round.copyWith(
        tiedPlayerIds: highestIds,
        resolvedTargetId: null,
      );
      final syncedSession = _syncRound(session, updatedRound);
      emit(
        state.copyWith(
          activeSession: syncedSession,
          currentVoteRound: updatedRound,
          errorMessage: AppText.tieDetectedMessage,
        ),
      );
      return;
    }

    final updatedRound = round.copyWith(
      tiedPlayerIds: const <String>[],
      resolvedTargetId: highestIds.single,
    );
    final syncedSession = _syncRound(session, updatedRound);
    emit(
      state.copyWith(
        activeSession: syncedSession,
        currentVoteRound: updatedRound,
        errorMessage: null,
      ),
    );
  }

  Future<void> startTieRevote() async {
    final session = state.activeSession;
    final round = state.currentVoteRound;
    if (session == null || round == null || !round.isTied) {
      emit(state.copyWith(errorMessage: AppText.invalidVoteActionMessage));
      return;
    }

    final nextRound = VotingRoundEntity(
      roundId:
          'round_${round.stageNumber}_${round.attemptNumber + 1}_${DateTime.now().microsecondsSinceEpoch}',
      stageNumber: round.stageNumber,
      voteType: round.voteType,
      attemptNumber: round.attemptNumber + 1,
      eligibleVoterIds: round.eligibleVoterIds,
      eligibleTargetIds: round.tiedPlayerIds,
      parentRoundId: round.roundId,
    );
    final syncedSession = _syncRound(session, nextRound);

    emit(
      state.copyWith(
        activeSession: syncedSession,
        currentVoteRound: nextRound,
        errorMessage: null,
      ),
    );
  }

  Future<void> confirmCurrentVoteRound() async {
    final session = state.activeSession;
    final variant = state.preparedVariant;
    final round = state.currentVoteRound;
    if (session == null ||
        variant == null ||
        round == null ||
        round.resolvedTargetId == null ||
        round.isConfirmed) {
      emit(state.copyWith(errorMessage: AppText.invalidVoteActionMessage));
      return;
    }

    final confirmedRound = round.copyWith(isConfirmed: true);
    var updatedSession = _syncRound(session, confirmedRound);
    final resolvedStages = <int>{
      ...updatedSession.resolvedStageNumbers,
      round.stageNumber,
    }.toList(growable: false)
      ..sort();

    updatedSession = updatedSession.copyWith(
      resolvedStageNumbers: resolvedStages,
      currentVoteRound: confirmedRound,
    );

    switch (round.voteType) {
      case 'suspicion':
        final suspicionMarks = <String, int>{...updatedSession.suspicionMarks};
        suspicionMarks[round.resolvedTargetId!] =
            (suspicionMarks[round.resolvedTargetId!] ?? 0) + 1;
        updatedSession = updatedSession.copyWith(
          suspicionMarks: suspicionMarks,
        );
        break;
      case 'elimination':
        final eliminatedId = round.resolvedTargetId!;
        final updatedPlayers = updatedSession.players
            .map(
              (player) => player.playerId == eliminatedId
                  ? player.copyWith(isEliminated: true)
                  : player,
            )
            .toList(growable: false);
        final eliminatedIds = <String>{
          ...updatedSession.eliminatedPlayerIds,
          eliminatedId,
        }.toList(growable: false);
        final eliminationRecords = [
          ...updatedSession.eliminationRecords,
          EliminationRecordEntity(
            playerId: eliminatedId,
            stageNumber: round.stageNumber,
            order: updatedSession.eliminationRecords.length + 1,
          ),
        ];
        updatedSession = updatedSession.copyWith(
          players: updatedPlayers,
          eliminatedPlayerIds: eliminatedIds,
          eliminationRecords: eliminationRecords,
        );
        final earlyOutcome = _buildEarlyFinalOutcomeIfNeeded(
          updatedSession,
          variant,
          eliminatedId,
        );
        if (earlyOutcome != null) {
          updatedSession = updatedSession.copyWith(finalOutcome: earlyOutcome);
        }
        await _audioService.playSfx(AppMedia.eliminationSfx);
        break;
      case 'final':
        updatedSession = updatedSession.copyWith(
          finalOutcome: _buildFinalOutcome(
              updatedSession, variant, round.resolvedTargetId!),
        );
        break;
      default:
        emit(state.copyWith(errorMessage: AppText.invalidVoteActionMessage));
        return;
    }

    await _audioService.playSfx(AppMedia.voteLockSfx);
    emit(
      state.copyWith(
        activeSession: updatedSession,
        currentVoteRound: confirmedRound,
        isCurrentStageReadOnly: true,
        errorMessage: null,
      ),
    );
  }

  Future<void> markFinalRevealShown() async {
    final session = state.activeSession;
    if (session == null ||
        session.finalOutcome == null ||
        session.isCompleted) {
      return;
    }

    final updatedSession = session.copyWith(isCompleted: true);
    emit(state.copyWith(activeSession: updatedSession, errorMessage: null));
    await _audioService.playSfx(AppMedia.finalRevealSfx);
    await _audioService.playSfx(
      session.finalOutcome!.winningTeam == _innocentTeamKey
          ? AppMedia.innocentWinSfx
          : AppMedia.mafiaWinSfx,
    );
  }

  Future<void> restartSession() async {
    _cancelStageTimer();
    emit(
      state.copyWith(
        activeSession: null,
        preparedVariant: null,
        selectedPlayerCount: null,
        currentStage: null,
        stageTimer: null,
        currentVoteRound: null,
        isCurrentStageReadOnly: false,
        isCurrentRoleVisible: false,
        errorMessage: null,
      ),
    );
  }

  void failClosedToHome() {
    _cancelStageTimer();
    emit(
      state.copyWith(
        activeSession: null,
        preparedVariant: null,
        selectedPlayerCount: null,
        currentStage: null,
        stageTimer: null,
        currentVoteRound: null,
        isCurrentStageReadOnly: false,
        isCurrentRoleVisible: false,
        errorMessage: AppText.sessionFailClosedMessage,
      ),
    );
  }

  Future<void> handleAppLifecycleChanged(
      AppLifecycleState lifecycleState) async {
    if (lifecycleState == AppLifecycleState.inactive ||
        lifecycleState == AppLifecycleState.hidden ||
        lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.detached) {
      if (state.isCurrentRoleVisible) {
        await hideCurrentRole();
      }
      if (state.stageTimer?.isRunning ?? false) {
        pauseStageTimer();
      }
    }
  }

  bool hasValidSession(String sessionId) {
    final session = state.activeSession;
    return session != null && session.sessionId == sessionId;
  }

  bool canAccessRoleReveal(String sessionId) {
    final session = state.activeSession;
    return session != null &&
        session.sessionId == sessionId &&
        !session.roleRevealComplete;
  }

  bool canAccessDashboard(String sessionId) {
    final session = state.activeSession;
    return session != null &&
        session.sessionId == sessionId &&
        session.roleRevealComplete &&
        !session.isCompleted;
  }

  bool canAccessStage(String sessionId, int stageNumber) {
    final session = state.activeSession;
    if (session == null ||
        session.sessionId != sessionId ||
        !session.roleRevealComplete ||
        session.isCompleted ||
        stageNumber < 1 ||
        stageNumber > 5) {
      return false;
    }
    return session.isStageResolved(stageNumber) ||
        session.recommendedNextStage == stageNumber;
  }

  bool canAccessVoting(String sessionId, int stageNumber) {
    return canAccessStage(sessionId, stageNumber);
  }

  bool canAccessFinalReveal(String sessionId) {
    final session = state.activeSession;
    return session != null &&
        session.sessionId == sessionId &&
        session.canShowFinalReveal;
  }

  Future<void> toggleSound() async {
    final updated = await _repository.updateSoundSettings(
      soundEnabled: !state.soundEnabled,
    );
    await _audioService.setEnabled(updated.soundEnabled);
    emit(
      state.copyWith(
        soundEnabled: updated.soundEnabled,
        soundVolume: updated.soundVolume,
      ),
    );
  }

  Future<void> setSoundVolume(double volume) async {
    final updated = await _repository.updateSoundSettings(soundVolume: volume);
    await _audioService.setVolume(updated.soundVolume);
    emit(
      state.copyWith(
        soundEnabled: updated.soundEnabled,
        soundVolume: updated.soundVolume,
      ),
    );
  }

  Future<void> playUiTap() => _audioService.playSfx(AppMedia.uiTapSfx);

  @override
  Future<void> close() async {
    _cancelStageTimer();
    await super.close();
  }

  bool _isSupportedPlayerCount(int playerCount) =>
      playerCount >= 5 && playerCount <= 8;

  VotingRoundEntity _createVotingRound(
    GameSessionEntity session,
    StageEntity stage, {
    int attemptNumber = 1,
    List<String>? eligibleTargetIds,
    String? parentRoundId,
  }) {
    final alivePlayers = session.players
        .where((player) => !session.isPlayerEliminated(player.playerId))
        .toList(growable: false);
    final eligiblePlayers =
        alivePlayers.map((player) => player.playerId).toList(growable: false);
    final outsideVoters = session.players
        .where((player) => session.isPlayerEliminated(player.playerId))
        .map((player) => player.playerId)
        .toList(growable: false);
    final useOutsideVoters =
        alivePlayers.length == 2 && _hasMixedMafiaAndInnocent(alivePlayers);

    return VotingRoundEntity(
      roundId:
          'round_${stage.stageNumber}_${attemptNumber}_${DateTime.now().microsecondsSinceEpoch}',
      stageNumber: stage.stageNumber,
      voteType: stage.voteType,
      attemptNumber: attemptNumber,
      eligibleVoterIds: useOutsideVoters && outsideVoters.isNotEmpty
          ? outsideVoters
          : eligiblePlayers,
      eligibleTargetIds: eligibleTargetIds ?? eligiblePlayers,
      parentRoundId: parentRoundId,
    );
  }

  StageEntity? _findStage(CaseVariantEntity variant, int stageNumber) {
    for (final stage in variant.stages) {
      if (stage.stageNumber == stageNumber) {
        return stage;
      }
    }
    return null;
  }

  void _setStageTimer(StageTimerEntity timer) {
    final session = state.activeSession;
    emit(
      state.copyWith(
        activeSession: session?.copyWith(timer: timer),
        stageTimer: timer,
      ),
    );
  }

  void _cancelStageTimer() {
    _stageTimer?.cancel();
    _stageTimer = null;
  }

  GameSessionEntity _syncRound(
    GameSessionEntity session,
    VotingRoundEntity round,
  ) {
    final rounds = [...session.voteRounds];
    final index = rounds.indexWhere((item) => item.roundId == round.roundId);
    if (index == -1) {
      rounds.add(round);
    } else {
      rounds[index] = round;
    }

    return session.copyWith(
      voteRounds: rounds,
      currentVoteRound: round,
    );
  }

  FinalOutcomeEntity _buildFinalOutcome(
    GameSessionEntity session,
    CaseVariantEntity variant,
    String accusedPlayerId,
  ) {
    final mafiaIds = session.players
        .where((player) => _isMafiaTeam(player.team))
        .map((player) => player.playerId)
        .toList(growable: false);
    final allMafiosoEliminated = mafiaIds.isNotEmpty &&
        mafiaIds.every(session.eliminatedPlayerIds.contains);
    final accusedPlayer = session.players.firstWhere(
      (player) => player.playerId == accusedPlayerId,
    );
    final accusedIsMafioso = _isMafiaTeam(accusedPlayer.team);
    final winningTeam = (accusedIsMafioso || allMafiosoEliminated)
        ? _innocentTeamKey
        : _mafiaTeamKey;

    return FinalOutcomeEntity(
      accusedPlayerId: accusedPlayerId,
      winningTeam: winningTeam,
      allMafiosoEliminatedBeforeFinal: allMafiosoEliminated,
      finalExplanation:
          variant.finalExplanation ?? AppText.assetFallbackMessage,
      roleSummary: session.players,
      eliminationSummary: session.eliminationRecords,
      suspicionSummary: session.suspicionMarks,
      innocentWinText: variant.innocentWinText,
      mafiaWinText: variant.mafiaWinText,
    );
  }

  FinalOutcomeEntity? _buildEarlyFinalOutcomeIfNeeded(
    GameSessionEntity session,
    CaseVariantEntity variant,
    String decisivePlayerId,
  ) {
    final alivePlayers = session.players
        .where((player) => !session.isPlayerEliminated(player.playerId))
        .toList(growable: false);
    final aliveMafia =
        alivePlayers.where((player) => _isMafiaTeam(player.team)).length;
    final aliveInnocents = alivePlayers.length - aliveMafia;

    if (aliveMafia == 0) {
      return _buildFinalOutcome(session, variant, decisivePlayerId);
    }

    if (aliveInnocents == 0) {
      return _buildForcedFinalOutcome(
        session: session,
        variant: variant,
        accusedPlayerId: decisivePlayerId,
        winningTeam: _mafiaTeamKey,
      );
    }

    return null;
  }

  FinalOutcomeEntity _buildForcedFinalOutcome({
    required GameSessionEntity session,
    required CaseVariantEntity variant,
    required String accusedPlayerId,
    required String winningTeam,
  }) {
    final mafiaIds = session.players
        .where((player) => _isMafiaTeam(player.team))
        .map((player) => player.playerId)
        .toList(growable: false);
    final allMafiosoEliminated = mafiaIds.isNotEmpty &&
        mafiaIds.every(session.eliminatedPlayerIds.contains);

    return FinalOutcomeEntity(
      accusedPlayerId: accusedPlayerId,
      winningTeam: winningTeam,
      allMafiosoEliminatedBeforeFinal: allMafiosoEliminated,
      finalExplanation:
          variant.finalExplanation ?? AppText.assetFallbackMessage,
      roleSummary: session.players,
      eliminationSummary: session.eliminationRecords,
      suspicionSummary: session.suspicionMarks,
      innocentWinText: variant.innocentWinText,
      mafiaWinText: variant.mafiaWinText,
    );
  }

  static const String _mafiaTeamKey = 'mafia';
  static const String _innocentTeamKey = 'innocent';

  static bool _isMafiaTeam(String team) =>
      team == _mafiaTeamKey || team == 'mafia_support';

  static bool _hasMixedMafiaAndInnocent(List<SessionPlayerEntity> players) {
    final hasMafia = players.any((player) => _isMafiaTeam(player.team));
    final hasInnocent = players.any((player) => !_isMafiaTeam(player.team));
    return hasMafia && hasInnocent;
  }
}
