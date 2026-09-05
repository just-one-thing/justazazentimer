import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/timer_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const ZazenTimerApp());
}

class ZazenTimerApp extends StatelessWidget {
  const ZazenTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Just A Zazen Timer',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF5C6B50),
        scaffoldBackgroundColor: const Color(0xFFF9F8F6),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF8A9A7B),
        scaffoldBackgroundColor: const Color(0xFF141514),
      ),
      home: const ZazenTimerHomePage(),
    );
  }
}

class ZazenTimerHomePage extends StatefulWidget {
  const ZazenTimerHomePage({super.key});

  @override
  State<ZazenTimerHomePage> createState() => _ZazenTimerHomePageState();
}

class _ZazenTimerHomePageState extends State<ZazenTimerHomePage> {
  late ZazenTimerState _timerState;
  Timer? _ticker;

  final List<int> _presetMinutes = [10, 15, 20, 25, 30, 45];

  @override
  void initState() {
    super.initState();
    _timerState = ZazenTimerState.initial();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _selectDuration(int minutes) {
    if (_timerState.isRunning) return;
    final newConfig = _timerState.config.copyWith(
      sittingDuration: Duration(minutes: minutes),
    );
    setState(() {
      _timerState = ZazenTimerState.initial(newConfig);
    });
  }

  void _startTimer() {
    if (_timerState.phase == ZazenPhase.idle ||
        _timerState.phase == ZazenPhase.completed) {
      if (_timerState.config.prepDuration.inSeconds > 0) {
        setState(() {
          _timerState = _timerState.copyWith(
            phase: ZazenPhase.preparation,
            status: TimerStatus.running,
            remainingSeconds: _timerState.config.prepDuration.inSeconds,
            elapsedSeconds: 0,
          );
        });
      } else {
        setState(() {
          _timerState = _timerState.copyWith(
            phase: ZazenPhase.sitting,
            status: TimerStatus.running,
            remainingSeconds: _timerState.config.sittingDuration.inSeconds,
            elapsedSeconds: 0,
          );
        });
      }
    } else {
      setState(() {
        _timerState = _timerState.copyWith(status: TimerStatus.running);
      });
    }

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  void _tick() {
    if (_timerState.remainingSeconds > 1) {
      setState(() {
        _timerState = _timerState.copyWith(
          remainingSeconds: _timerState.remainingSeconds - 1,
          elapsedSeconds: _timerState.elapsedSeconds + 1,
        );
      });
    } else {
      if (_timerState.phase == ZazenPhase.preparation) {
        // Transition from prep to sitting
        setState(() {
          _timerState = _timerState.copyWith(
            phase: ZazenPhase.sitting,
            remainingSeconds: _timerState.config.sittingDuration.inSeconds,
            elapsedSeconds: 0,
          );
        });
      } else if (_timerState.phase == ZazenPhase.sitting) {
        // Finished
        _ticker?.cancel();
        setState(() {
          _timerState = _timerState.copyWith(
            phase: ZazenPhase.completed,
            status: TimerStatus.finished,
            remainingSeconds: 0,
          );
        });
      }
    }
  }

  void _pauseTimer() {
    _ticker?.cancel();
    setState(() {
      _timerState = _timerState.copyWith(status: TimerStatus.paused);
    });
  }

  void _resetTimer() {
    _ticker?.cancel();
    setState(() {
      _timerState = ZazenTimerState.initial(_timerState.config);
    });
  }

  String _getPhaseTitle() {
    switch (_timerState.phase) {
      case ZazenPhase.idle:
        return 'Zazen Meditation';
      case ZazenPhase.preparation:
        return 'Prepare to Sit';
      case ZazenPhase.sitting:
        return 'Zazen';
      case ZazenPhase.completed:
        return 'Session Complete';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    _getPhaseTitle(),
                    style: textTheme.headlineSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (_timerState.phase == ZazenPhase.sitting)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Keep posture, breathe naturally',
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),

              // Central Countdown Display
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _timerState.formattedRemaining,
                      style: textTheme.displayLarge?.copyWith(
                        fontSize: 72,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _timerState.phase == ZazenPhase.preparation
                          ? 'Get comfortable in your seat'
                          : '${_timerState.config.sittingDuration.inMinutes} minute sitting',
                      style: textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Preset durations & Controls
              Column(
                children: [
                  if (!_timerState.isRunning &&
                      _timerState.phase != ZazenPhase.sitting)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Wrap(
                        spacing: 8.0,
                        alignment: WrapAlignment.center,
                        children: _presetMinutes.map((mins) {
                          final isSelected =
                              _timerState.config.sittingDuration.inMinutes ==
                                  mins;
                          return ChoiceChip(
                            label: Text('$mins m'),
                            selected: isSelected,
                            onSelected: (_) => _selectDuration(mins),
                          );
                        }).toList(),
                      ),
                    ),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_timerState.isRunning)
                        FilledButton.tonalIcon(
                          onPressed: _pauseTimer,
                          icon: const Icon(Icons.pause),
                          label: const Text('Pause'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _startTimer,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            _timerState.isPaused
                                ? 'Resume'
                                : (_timerState.isFinished
                                    ? 'Sit Again'
                                    : 'Begin'),
                          ),
                        ),
                      if (_timerState.phase != ZazenPhase.idle) ...[
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _resetTimer,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
