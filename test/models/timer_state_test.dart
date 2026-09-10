import 'package:flutter_test/flutter_test.dart';
import 'package:justazazentimer/models/timer_state.dart';

void main() {
  group('ZazenTimerConfig', () {
    test('default configuration has 25 min sitting and 10 sec prep with DND enabled', () {
      const config = ZazenTimerConfig();
      expect(config.sittingDuration, const Duration(minutes: 25));
      expect(config.prepDuration, const Duration(seconds: 10));
      expect(config.intervalBellDuration, isNull);
      expect(config.enableDndDuringSession, isTrue);
    });

    test('copyWith properly overrides values', () {
      const config = ZazenTimerConfig();
      final updated = config.copyWith(
        sittingDuration: const Duration(minutes: 40),
        prepDuration: Duration.zero,
        intervalBellDuration: const Duration(minutes: 10),
        enableDndDuringSession: false,
      );
      expect(updated.sittingDuration, const Duration(minutes: 40));
      expect(updated.prepDuration, Duration.zero);
      expect(updated.intervalBellDuration, const Duration(minutes: 10));
      expect(updated.enableDndDuringSession, isFalse);
    });
  });

  group('ZazenTimerState', () {
    test('initial state defaults correctly', () {
      final state = ZazenTimerState.initial();
      expect(state.phase, ZazenPhase.idle);
      expect(state.status, TimerStatus.initial);
      expect(state.remainingSeconds, 25 * 60);
      expect(state.elapsedSeconds, 0);
      expect(state.isRunning, isFalse);
      expect(state.isPaused, isFalse);
      expect(state.isFinished, isFalse);
      expect(state.formattedRemaining, '25:00');
    });

    test('formattedRemaining formats minutes and seconds with zero-padding', () {
      final state = ZazenTimerState(
        config: const ZazenTimerConfig(),
        remainingSeconds: 65,
      );
      expect(state.formattedRemaining, '01:05');

      final stateZero = ZazenTimerState(
        config: const ZazenTimerConfig(),
        remainingSeconds: 0,
      );
      expect(stateZero.formattedRemaining, '00:00');
    });

    test('state transitions through phases', () {
      var state = ZazenTimerState.initial();
      expect(state.phase, ZazenPhase.idle);

      state = state.copyWith(
        phase: ZazenPhase.preparation,
        status: TimerStatus.running,
        remainingSeconds: 10,
      );
      expect(state.phase, ZazenPhase.preparation);
      expect(state.isRunning, isTrue);

      state = state.copyWith(
        phase: ZazenPhase.sitting,
        remainingSeconds: 25 * 60,
      );
      expect(state.phase, ZazenPhase.sitting);

      state = state.copyWith(
        phase: ZazenPhase.completed,
        status: TimerStatus.finished,
        remainingSeconds: 0,
      );
      expect(state.phase, ZazenPhase.completed);
      expect(state.isFinished, isTrue);
    });
  });
}
