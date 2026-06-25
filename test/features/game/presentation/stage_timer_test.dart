import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_game_harness.dart';

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

  test('starts, pauses, and resets the stage timer safely', () {
    fakeAsync((async) {
      expect(harness.cubit.state.stageTimer, isNotNull);
      expect(harness.cubit.state.stageTimer!.remainingSeconds, 180);

      harness.cubit.startStageTimer();
      async.elapse(const Duration(seconds: 3));

      expect(harness.cubit.state.stageTimer!.isRunning, isTrue);
      expect(harness.cubit.state.stageTimer!.remainingSeconds, 177);

      harness.cubit.pauseStageTimer();
      async.elapse(const Duration(seconds: 5));
      expect(harness.cubit.state.stageTimer!.remainingSeconds, 177);

      harness.cubit.resetStageTimer();
      expect(harness.cubit.state.stageTimer!.isRunning, isFalse);
      expect(harness.cubit.state.stageTimer!.remainingSeconds, 180);
    });
  });

  test('warns at 30 seconds and stops when leaving the stage', () {
    fakeAsync((async) {
      harness.cubit.startStageTimer();
      async.elapse(const Duration(seconds: 150));

      expect(harness.cubit.state.stageTimer!.remainingSeconds, 30);
      expect(harness.cubit.state.stageTimer!.isWarning, isTrue);

      harness.cubit.leaveStage();
      async.elapse(const Duration(seconds: 5));

      expect(harness.cubit.state.stageTimer, isNull);
      expect(harness.cubit.state.activeSession!.currentStageNumber, isNull);
    });
  });

  test('pauses the timer when the app is backgrounded', () {
    fakeAsync((async) {
      harness.cubit.startStageTimer();
      async.elapse(const Duration(seconds: 4));

      harness.cubit.handleAppLifecycleChanged(AppLifecycleState.paused);
      async.elapse(const Duration(seconds: 4));

      expect(harness.cubit.state.stageTimer!.isRunning, isFalse);
      expect(harness.cubit.state.stageTimer!.remainingSeconds, 176);
    });
  });
}
