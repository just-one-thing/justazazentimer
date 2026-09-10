import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class DndService {
  Future<bool> isPermissionGranted();
  Future<void> openSettings();
  Future<bool> enableDnd();
  Future<bool> disableDnd();
}

class AndroidDndService implements DndService {
  static const MethodChannel _channel = MethodChannel('com.justazazentimer/dnd');

  @override
  Future<bool> isPermissionGranted() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final bool? granted = await _channel.invokeMethod<bool>('isDndPermissionGranted');
      return granted ?? false;
    } catch (e) {
      debugPrint('Error checking DND permission: $e');
      return false;
    }
  }

  @override
  Future<void> openSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod('openDndSettings');
    } catch (e) {
      debugPrint('Error opening DND settings: $e');
    }
  }

  @override
  Future<bool> enableDnd() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final bool? result = await _channel.invokeMethod<bool>('enableDnd');
      return result ?? false;
    } catch (e) {
      debugPrint('Error enabling DND: $e');
      return false;
    }
  }

  @override
  Future<bool> disableDnd() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final bool? result = await _channel.invokeMethod<bool>('disableDnd');
      return result ?? false;
    } catch (e) {
      debugPrint('Error disabling DND: $e');
      return false;
    }
  }
}

class MockDndService implements DndService {
  bool permissionGranted = true;
  bool isDndActive = false;
  int openSettingsCount = 0;
  int enableDndCount = 0;
  int disableDndCount = 0;

  @override
  Future<bool> isPermissionGranted() async {
    return permissionGranted;
  }

  @override
  Future<void> openSettings() async {
    openSettingsCount++;
  }

  @override
  Future<bool> enableDnd() async {
    enableDndCount++;
    if (permissionGranted) {
      isDndActive = true;
      return true;
    }
    return false;
  }

  @override
  Future<bool> disableDnd() async {
    disableDndCount++;
    isDndActive = false;
    return true;
  }
}
