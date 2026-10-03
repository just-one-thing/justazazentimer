import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/timer_state.dart';
import 'services/bell_service.dart';
import 'services/dnd_service.dart';
import 'services/session_alarm_service.dart';

/// External project links
const String kKofiUrl = 'https://ko-fi.com/lorenzobaracchi';
const String kRepoUrl = 'https://github.com/just-one-thing/justazazentimer';
const String kLicenseUrl = 'https://www.gnu.org/licenses/gpl-3.0.html';

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

  Future<void> _launchExternalUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $urlString'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAboutDialog() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18.0),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Just A Zazen Timer',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.0.0',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A minimalist, distraction-free Zazen meditation timer built for quiet focus.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _launchExternalUrl(kLicenseUrl),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.balance,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'GNU GPL v3.0 License',
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _launchExternalUrl(kKofiUrl),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5E5B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size.fromHeight(44),
                ),
                icon: const Icon(Icons.favorite, size: 18),
                label: const Text(
                  'Support on Ko-fi',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _launchExternalUrl(kRepoUrl),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size.fromHeight(44),
                ),
                icon: const Icon(Icons.code, size: 18),
                label: const Text('Source Code (GitHub)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
              // Top Area: Enlarged Logo, About Button & DND indicator
              Stack(
                alignment: Alignment.topCenter,
                children: [
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
                  if (!_timerState.isRunning &&
                      _timerState.phase != ZazenPhase.sitting)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        tooltip: 'About & Support',
                        icon: const Icon(Icons.info_outline),
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                        onPressed: _showAboutDialog,
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
