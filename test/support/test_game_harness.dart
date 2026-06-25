import 'dart:math';

import 'package:drift/native.dart';
import 'package:mafmof/core/audio/audio_service.dart';
import 'package:mafmof/core/database/app_database.dart';
import 'package:mafmof/features/game/data/datasources/game_local_datasource_impl.dart';
import 'package:mafmof/features/game/data/repositories/game_repository_impl.dart';
import 'package:mafmof/features/game/data/seeders/case_seeder.dart';
import 'package:mafmof/features/game/presentation/cubit/game_cubit.dart';

import 'test_seed_payload.dart';

class TestGameHarness {
  TestGameHarness._(
    this.database,
    this.repository,
    this.audioService,
    this.cubit,
    this.caseId,
  );

  final AppDatabase database;
  final GameRepositoryImpl repository;
  final RecordingAudioService audioService;
  final GameCubit cubit;
  final String caseId;

  static Future<TestGameHarness> create({
    Random? random,
    String caseId = 'case01_farah_eltagamoa',
    List<String>? assetPaths,
    Future<String> Function(String path)? assetLoader,
  }) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final datasource = GameLocalDatasourceImpl(database);
    final seeder = CaseSeeder.forTesting(
      datasource,
      assetPaths: assetPaths,
      assetLoader: assetLoader ?? (_) async => buildTestSeedJson(),
    );
    final repository = GameRepositoryImpl(datasource, seeder);
    final audioService = RecordingAudioService();
    final cubit = GameCubit(repository, audioService, random: random);

    await cubit.bootstrap();
    await cubit.loadCase(caseId);

    return TestGameHarness._(database, repository, audioService, cubit, caseId);
  }

  Future<void> prepareVariant(int playerCount) async {
    await cubit.prepareVariantForSetup(caseId, playerCount);
  }

  Future<void> startSession(List<String> playerNames) async {
    await cubit.startSession(
      caseId: caseId,
      playerCount: playerNames.length,
      playerNames: playerNames,
    );
  }

  Future<void> completeRoleReveal() async {
    final session = cubit.state.activeSession!;
    for (var index = session.revealIndex;
        index < session.players.length;
        index += 1) {
      await cubit.revealCurrentRole();
      await cubit.hideCurrentRole();
      await cubit.advanceRoleReveal();
    }
  }

  Future<void> dispose() async {
    await cubit.close();
    await database.close();
  }
}

class RecordingAudioService implements AudioService {
  final List<String> playedKeys = <String>[];
  bool _isEnabled = true;
  double _volume = 0.7;

  @override
  bool get isEnabled => _isEnabled;

  @override
  double get volume => _volume;

  @override
  Future<void> playSfx(String key) async {
    if (_isEnabled) {
      playedKeys.add(key);
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
  }
}
