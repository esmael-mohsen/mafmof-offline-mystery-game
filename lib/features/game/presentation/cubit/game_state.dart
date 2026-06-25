import 'package:equatable/equatable.dart';

import '../../domain/entities/case_entity.dart';
import '../../domain/entities/case_variant_entity.dart';
import '../../domain/entities/game_session_entity.dart';
import '../../domain/entities/stage_entity.dart';
import '../../domain/entities/stage_timer_entity.dart';
import '../../domain/entities/voting_round_entity.dart';

enum CatalogStatus {
  initial,
  loading,
  ready,
  failure,
}

class GameState extends Equatable {
  const GameState({
    this.catalogStatus = CatalogStatus.initial,
    this.availableCases = const <CaseEntity>[],
    this.selectedCase,
    this.casePreviewVariant,
    this.preparedVariant,
    this.activeSession,
    this.isCurrentRoleVisible = false,
    this.currentStage,
    this.stageTimer,
    this.currentVoteRound,
    this.isCurrentStageReadOnly = false,
    this.soundEnabled = true,
    this.soundVolume = 0.7,
    this.errorMessage,
    this.canRetryCatalogLoad = false,
    this.hasFallbackCatalog = false,
    this.selectedPlayerCount,
  });

  final CatalogStatus catalogStatus;
  final List<CaseEntity> availableCases;
  final CaseEntity? selectedCase;
  final CaseVariantEntity? casePreviewVariant;
  final CaseVariantEntity? preparedVariant;
  final GameSessionEntity? activeSession;
  final bool isCurrentRoleVisible;
  final StageEntity? currentStage;
  final StageTimerEntity? stageTimer;
  final VotingRoundEntity? currentVoteRound;
  final bool isCurrentStageReadOnly;
  final bool soundEnabled;
  final double soundVolume;
  final String? errorMessage;
  final bool canRetryCatalogLoad;
  final bool hasFallbackCatalog;
  final int? selectedPlayerCount;

  static const Object _sentinel = Object();

  bool get isLoading => catalogStatus == CatalogStatus.loading;

  bool get canEnterCases => catalogStatus == CatalogStatus.ready;

  bool get hasActiveSession => activeSession != null;

  bool get roleRevealComplete => activeSession?.roleRevealComplete ?? false;

  GameState copyWith({
    CatalogStatus? catalogStatus,
    List<CaseEntity>? availableCases,
    Object? selectedCase = _sentinel,
    Object? casePreviewVariant = _sentinel,
    Object? preparedVariant = _sentinel,
    Object? activeSession = _sentinel,
    bool? isCurrentRoleVisible,
    Object? currentStage = _sentinel,
    Object? stageTimer = _sentinel,
    Object? currentVoteRound = _sentinel,
    bool? isCurrentStageReadOnly,
    bool? soundEnabled,
    double? soundVolume,
    Object? errorMessage = _sentinel,
    bool? canRetryCatalogLoad,
    bool? hasFallbackCatalog,
    Object? selectedPlayerCount = _sentinel,
  }) {
    return GameState(
      catalogStatus: catalogStatus ?? this.catalogStatus,
      availableCases: availableCases ?? this.availableCases,
      selectedCase: selectedCase == _sentinel
          ? this.selectedCase
          : selectedCase as CaseEntity?,
      casePreviewVariant: casePreviewVariant == _sentinel
          ? this.casePreviewVariant
          : casePreviewVariant as CaseVariantEntity?,
      preparedVariant: preparedVariant == _sentinel
          ? this.preparedVariant
          : preparedVariant as CaseVariantEntity?,
      activeSession: activeSession == _sentinel
          ? this.activeSession
          : activeSession as GameSessionEntity?,
      isCurrentRoleVisible: isCurrentRoleVisible ?? this.isCurrentRoleVisible,
      currentStage: currentStage == _sentinel
          ? this.currentStage
          : currentStage as StageEntity?,
      stageTimer: stageTimer == _sentinel
          ? this.stageTimer
          : stageTimer as StageTimerEntity?,
      currentVoteRound: currentVoteRound == _sentinel
          ? this.currentVoteRound
          : currentVoteRound as VotingRoundEntity?,
      isCurrentStageReadOnly:
          isCurrentStageReadOnly ?? this.isCurrentStageReadOnly,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      canRetryCatalogLoad: canRetryCatalogLoad ?? this.canRetryCatalogLoad,
      hasFallbackCatalog: hasFallbackCatalog ?? this.hasFallbackCatalog,
      selectedPlayerCount: selectedPlayerCount == _sentinel
          ? this.selectedPlayerCount
          : selectedPlayerCount as int?,
    );
  }

  @override
  List<Object?> get props => [
        catalogStatus,
        availableCases,
        selectedCase,
        casePreviewVariant,
        preparedVariant,
        activeSession,
        isCurrentRoleVisible,
        currentStage,
        stageTimer,
        currentVoteRound,
        isCurrentStageReadOnly,
        soundEnabled,
        soundVolume,
        errorMessage,
        canRetryCatalogLoad,
        hasFallbackCatalog,
        selectedPlayerCount,
      ];
}
