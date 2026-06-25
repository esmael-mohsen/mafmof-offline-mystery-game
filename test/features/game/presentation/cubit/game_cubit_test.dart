import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_game_harness.dart';

void main() {
  late TestGameHarness harness;

  setUp(() async {
    harness = await TestGameHarness.create();
    await harness.prepareVariant(5);
    await harness.startSession(const ['أحمد', 'سارة', 'ليلى', 'كريم', 'نهى']);
    await harness.completeRoleReveal();
    await harness.cubit.openStage(1);
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('closing the cubit cancels the stage timer', () async {
    harness.cubit.startStageTimer();

    expect(harness.cubit.state.stageTimer?.isRunning, isTrue);

    await harness.cubit.close();

    expect(harness.cubit.isClosed, isTrue);
  });

  test('restartSession cancels the timer and clears timer state', () async {
    harness.cubit.startStageTimer();

    expect(harness.cubit.state.stageTimer?.isRunning, isTrue);

    await harness.cubit.restartSession();

    expect(harness.cubit.state.stageTimer, isNull);
    expect(harness.cubit.state.activeSession, isNull);
  });

  test('handleAppLifecycleChanged pauses running timer on background', () async {
    harness.cubit.startStageTimer();

    expect(harness.cubit.state.stageTimer?.isRunning, isTrue);

    harness.cubit.handleAppLifecycleChanged(AppLifecycleState.paused);

    expect(harness.cubit.state.stageTimer?.isRunning, isFalse);
  });
}