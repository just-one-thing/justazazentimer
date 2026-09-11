import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/timer_state.dart';
import 'services/bell_service.dart';
import 'services/dnd_service.dart';
import 'services/session_alarm_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const ZazenTimerApp());
}

class ZazenTimerApp extends StatelessWidget {
  const ZazenTimerApp({
    super.key,
    this.bellService,
    this.alarmService,
    this.dndService,
  });

  final BellService? bellService;
  final SessionAlarmService? alarmService;
  final DndService? dndService;

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
      home: ZazenTimerHomePage(
        bellService: bellService,
        alarmService: alarmService,
        dndService: dndService,
      ),
    );
  }
}

class ZazenTimerHomePage extends StatefulWidget {
  const ZazenTimerHomePage({
    super.key,
    this.bellService,
    this.alarmService,
    this.dndService,
  });

  final BellService? bellService;
  final SessionAlarmService? alarmService;
  final DndService? dndService;

  @override
  State<ZazenTimerHomePage> createState() => _ZazenTimerHomePageState();
}

class _ZazenTimerHomePageState extends State<ZazenTimerHomePage> {
  late ZazenTimerState _timerState;
  late final BellService _bellService;
  late final SessionAlarmService _alarmService;
  late final DndService _dndService;
  Timer? _ticker;
  bool _dndActive = false;

  final List<int> _presetMinutes = [10, 15, 20, 25, 30, 45];

  @override
  void initState() {
    super.initState();
    _bellService = widget.bellService ?? AudioBellService();
    _alarmService = widget.alarmService ?? AndroidSessionAlarmService();
    _dndService = widget.dndService ?? AndroidDndService();
    _alarmService.initialize();
    _bellService.initialize();
    _timerState = ZazenTimerState.initial();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _alarmService.setScreenWakelock(false);
    _alarmService.cancelSessionEndAlarm();
    _disableDnd();
    if (widget.bellService == null) {
      _bellService.dispose();
    }
    super.dispose();
  }

  Future<void> _enableDnd() async {
    if (!_timerState.config.enableDndDuringSession) return;
    final granted = await _dndService.isPermissionGranted();
    if (granted) {
      final success = await _dndService.enableDnd();
      if (mounted && success) {
        setState(() => _dndActive = true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Grant Do Not Disturb permission to silence interruptions.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => _dndService.openSettings(),
            ),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _disableDnd() async {
    if (_dndActive) {
      await _dndService.disableDnd();
      if (mounted) {
        setState(() => _dndActive = false);
      }
    }
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

  void _toggleDndSetting(bool enable) async {
    if (_timerState.isRunning) return;
    if (enable) {
      final granted = await _dndService.isPermissionGranted();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Allow Do Not Disturb access in Settings to enable this feature.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => _dndService.openSettings(),
            ),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    setState(() {
      _timerState = _timerState.copyWith(
        config: _timerState.config.copyWith(enableDndDuringSession: enable),
      );
    });
  }

  void _startTimer() {
    if (_timerState.phase == ZazenPhase.idle ||
        _timerState.phase == ZazenPhase.completed) {
      if (_timerState.config.prepDuration.inSeconds > 0) {
        // Preparation phase
        _alarmService.setScreenWakelock(true);
        setState(() {
          _timerState = _timerState.copyWith(
            phase: ZazenPhase.preparation,
            status: TimerStatus.running,
            remainingSeconds: _timerState.config.prepDuration.inSeconds,
            elapsedSeconds: 0,
          );
        });
      } else {
        // Direct sitting start -> schedule alarm, wakelock, DND & play 3 bells
        _alarmService.setScreenWakelock(true);
        _alarmService.scheduleSessionEndAlarm(
          duration: _timerState.config.sittingDuration,
        );
        _enableDnd();
        _bellService.playThreeBells();
        setState(() {
          _timerState = _timerState.copyWith(
            phase: ZazenPhase.sitting,
            status: TimerStatus.running,
            remainingSeconds: _timerState.config.sittingDuration.inSeconds,
            elapsedSeconds: 0,
          );
        });
      }
    } else if (_timerState.status == TimerStatus.paused) {
      // Resuming
      _alarmService.setScreenWakelock(true);
      if (_timerState.phase == ZazenPhase.sitting) {
        _alarmService.scheduleSessionEndAlarm(
          duration: Duration(seconds: _timerState.remainingSeconds),
        );
        _enableDnd();
      }
      setState(() {
        _timerState = _timerState.copyWith(status: TimerStatus.running);
      });
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
        // Transition from prep to sitting:
        // Schedule exact alarm, enable DND, and play 3 bells
        _alarmService.scheduleSessionEndAlarm(
          duration: _timerState.config.sittingDuration,
        );
        _enableDnd();
        _bellService.playThreeBells();
        setState(() {
          _timerState = _timerState.copyWith(
            phase: ZazenPhase.sitting,
            remainingSeconds: _timerState.config.sittingDuration.inSeconds,
            elapsedSeconds: 0,
          );
        });
      } else if (_timerState.phase == ZazenPhase.sitting) {
        // Finished -> cancel scheduled alarm, release wakelock, disable DND & play 3 bells
        _ticker?.cancel();
        _alarmService.setScreenWakelock(false);
        _alarmService.cancelSessionEndAlarm();
        _disableDnd();
        _bellService.playThreeBells();
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
    _alarmService.setScreenWakelock(false);
    _alarmService.cancelSessionEndAlarm();
    _disableDnd();
    _bellService.stop();
    setState(() {
      _timerState = _timerState.copyWith(status: TimerStatus.paused);
    });
  }

  void _resetTimer() {
    _ticker?.cancel();
    _alarmService.setScreenWakelock(false);
    _alarmService.cancelSessionEndAlarm();
    _disableDnd();
    _bellService.stop();
    setState(() {
      _timerState = ZazenTimerState.initial(_timerState.config);
    });
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
              // Top Area: Enlarged Logo & DND indicator
              Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28.0),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (_dndActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.do_not_disturb_on,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Do Not Disturb Active',
                            style: textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                        fontSize: 76,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _timerState.phase == ZazenPhase.preparation
                          ? 'Get comfortable in your seat'
                          : (_timerState.phase == ZazenPhase.completed
                              ? 'Session complete'
                              : (_timerState.phase == ZazenPhase.sitting
                                  ? 'Keep posture, breathe naturally'
                                  : '${_timerState.config.sittingDuration.inMinutes} minute sitting')),
                      style: textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Preset durations, DND toggle & Controls
              Column(
                children: [
                  if (!_timerState.isRunning &&
                      _timerState.phase != ZazenPhase.sitting) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
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

                    // Do Not Disturb Preference toggle
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: FilterChip(
                        avatar: Icon(
                          _timerState.config.enableDndDuringSession
                              ? Icons.do_not_disturb_on
                              : Icons.do_not_disturb_off_outlined,
                          size: 16,
                        ),
                        label: const Text('Do Not Disturb during sitting'),
                        selected: _timerState.config.enableDndDuringSession,
                        onSelected: (val) => _toggleDndSetting(val),
                      ),
                    ),
                  ],

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
