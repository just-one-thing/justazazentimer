enum ZazenPhase {
  idle,
  preparation,
  sitting,
  completed,
}

enum TimerStatus {
  initial,
  running,
  paused,
  finished,
}

class ZazenTimerConfig {
  const ZazenTimerConfig({
    this.sittingDuration = const Duration(minutes: 25),
    this.prepDuration = const Duration(seconds: 10),
    this.intervalBellDuration,
  });

  final Duration sittingDuration;
  final Duration prepDuration;
  final Duration? intervalBellDuration;

  ZazenTimerConfig copyWith({
    Duration? sittingDuration,
    Duration? prepDuration,
    Duration? intervalBellDuration,
  }) {
    return ZazenTimerConfig(
      sittingDuration: sittingDuration ?? this.sittingDuration,
      prepDuration: prepDuration ?? this.prepDuration,
      intervalBellDuration: intervalBellDuration ?? this.intervalBellDuration,
    );
  }
}

class ZazenTimerState {
  const ZazenTimerState({
    required this.config,
    this.phase = ZazenPhase.idle,
    this.status = TimerStatus.initial,
    this.remainingSeconds = 0,
    this.elapsedSeconds = 0,
  });

  factory ZazenTimerState.initial([ZazenTimerConfig? config]) {
    final conf = config ?? const ZazenTimerConfig();
    return ZazenTimerState(
      config: conf,
      phase: ZazenPhase.idle,
      status: TimerStatus.initial,
      remainingSeconds: conf.sittingDuration.inSeconds,
      elapsedSeconds: 0,
    );
  }

  final ZazenTimerConfig config;
  final ZazenPhase phase;
  final TimerStatus status;
  final int remainingSeconds;
  final int elapsedSeconds;

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isFinished => status == TimerStatus.finished;

  String get formattedRemaining {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  ZazenTimerState copyWith({
    ZazenTimerConfig? config,
    ZazenPhase? phase,
    TimerStatus? status,
    int? remainingSeconds,
    int? elapsedSeconds,
  }) {
    return ZazenTimerState(
      config: config ?? this.config,
      phase: phase ?? this.phase,
      status: status ?? this.status,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}
