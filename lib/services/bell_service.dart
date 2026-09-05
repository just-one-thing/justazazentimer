import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

abstract class BellService {
  Future<void> playThreeBells();
  Future<void> playSingleBell();
  Future<void> stop();
  void dispose();
}

class AudioBellService implements BellService {
  AudioBellService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> playThreeBells() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/tibetan_bell_3x.wav'));
    } catch (_) {
      // Audio playback fails gracefully if device audio is unavailable
    }
  }

  @override
  Future<void> playSingleBell() async {
    try {
      await _player.stop();
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
  int threeBellsPlayCount = 0;
  int singleBellPlayCount = 0;
  int stopCount = 0;

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
