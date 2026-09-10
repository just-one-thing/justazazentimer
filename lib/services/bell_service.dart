import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

abstract class BellService {
  Future<void> initialize();
  Future<void> playThreeBells();
  Future<void> playSingleBell();
  Future<void> stop();
  void dispose();
}

class AudioBellService implements BellService {
  AudioBellService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  bool _initialized = false;

  static final AudioContext alarmAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: true,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.alarm,
      audioFocus: AndroidAudioFocus.gainTransientExclusive,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.duckOthers},
    ),
  );

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await AudioPlayer.global.setAudioContext(alarmAudioContext);
      await _player.setAudioContext(alarmAudioContext);
      await _player.setVolume(1.0);
      _initialized = true;
    } catch (_) {
      // Graceful fallback on unsupported platforms
    }
  }

  @override
  Future<void> playThreeBells() async {
    try {
      await initialize();
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(AssetSource('sounds/tibetan_bell_3x.wav'));
    } catch (_) {
      // Audio playback fails gracefully if device audio is unavailable
    }
  }

  @override
  Future<void> playSingleBell() async {
    try {
      await initialize();
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(AssetSource('sounds/tibetan_bell.wav'));
    } catch (_) {
      // Audio playback fails gracefully
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
  }
}

class MockBellService implements BellService {
  bool isInitialized = false;
  int threeBellsPlayCount = 0;
  int singleBellPlayCount = 0;
  int stopCount = 0;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<void> playThreeBells() async {
    threeBellsPlayCount++;
  }

  @override
  Future<void> playSingleBell() async {
    singleBellPlayCount++;
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  void dispose() {}
}
