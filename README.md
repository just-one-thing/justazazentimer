# Just A Zazen Timer (Android)

A minimalist, distraction-free Zazen (Zen meditation) timer app built with Flutter and Kotlin.

## Features & Target Platform
- **Target OS**: Android 15 (API 35) and newer (Android 16+ ready)
- **Language**: Dart (Flutter 3.47+) & Kotlin (AGP 9.1+)
- **Design**: Clean Material 3 zen aesthetic, supporting light and dark themes with system edge-to-edge support.
- **Audio**: Tibetan singing bowl sound (3 dings spaced 2 seconds apart at start and end).
- **Silent Mode Bypass**: Configured with Android Alarm stream (`USAGE_ALARM`) audio attributes to play audibly even when the phone ringer is set to Silent or Vibrate.
- **Do Not Disturb (DND) Integration**: Automatically silences calls and notification interruptions (`INTERRUPTION_FILTER_ALARMS`) during meditation sitting and restores normal mode upon session end.
- **Background Wakeup**: Android exact alarms (`AlarmManager.setExactAndAllowWhileIdle`), wake-lock management, and native system notification sound in Android `res/raw/`.

## Project Structure
- [`lib/main.dart`](file:///home/lorenzo/Workspace/justazazentimer/lib/main.dart) - Main app entry point, DND management, and meditation timer UI
- [`lib/models/timer_state.dart`](file:///home/lorenzo/Workspace/justazazentimer/lib/models/timer_state.dart) - Timer configuration and state model
- [`lib/services/bell_service.dart`](file:///home/lorenzo/Workspace/justazazentimer/lib/services/bell_service.dart) - Tibetan bell audio playback service with Alarm stream context
- [`lib/services/dnd_service.dart`](file:///home/lorenzo/Workspace/justazazentimer/lib/services/dnd_service.dart) - Android Do Not Disturb platform channel service
- [`lib/services/session_alarm_service.dart`](file:///home/lorenzo/Workspace/justazazentimer/lib/services/session_alarm_service.dart) - Exact alarm and screen wakelock service
- [`test/models/timer_state_test.dart`](file:///home/lorenzo/Workspace/justazazentimer/test/models/timer_state_test.dart) - Unit tests for timer logic
- [`test/services/bell_service_test.dart`](file:///home/lorenzo/Workspace/justazazentimer/test/services/bell_service_test.dart) - Unit tests for bell audio service
- [`test/services/dnd_service_test.dart`](file:///home/lorenzo/Workspace/justazazentimer/test/services/dnd_service_test.dart) - Unit tests for DND service
- [`test/services/session_alarm_service_test.dart`](file:///home/lorenzo/Workspace/justazazentimer/test/services/session_alarm_service_test.dart) - Unit tests for alarm and wakelock service
- [`test/widget_test.dart`](file:///home/lorenzo/Workspace/justazazentimer/test/widget_test.dart) - Widget and UI interaction tests
- [`android/app/build.gradle.kts`](file:///home/lorenzo/Workspace/justazazentimer/android/app/build.gradle.kts) - Android build configuration (Kotlin DSL, `compileSdk 35`, `targetSdk 35`)

---

## Testing the App

### 1. Automated Test Suite (Fastest)
Run all automated unit and widget tests directly in the terminal without an emulator:
```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart
flutter test test/services/dnd_service_test.dart
flutter test test/services/bell_service_test.dart
flutter test test/services/session_alarm_service_test.dart
flutter test test/models/timer_state_test.dart

# Run tests with code coverage
flutter test --coverage
```

### 2. Instant Local Visual Testing (Web & Desktop)
You can run and interact with the timer immediately on your development machine with hot-reload enabled:

```bash
# Launch in Google Chrome
flutter run -d chrome

# Launch as a native Linux desktop window
flutter run -d linux
```

*Note: While running, press `r` in the terminal to hot-reload code changes or `R` to hot-restart.*

### 3. Physical Android Device (Android 15+)
To test on a physical Android phone:
1. Enable **Developer Options**:
   - Go to **Settings > About Phone** and tap **Build Number** 7 times.
   - Go to **Settings > System > Developer Options** and enable **USB Debugging**.
2. Connect your phone via USB.
3. Verify your device is detected:
   ```bash
   flutter devices
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### 4. Android Virtual Device (Emulator)
To test in an official Android 15 emulator:
1. In Android Studio, open the **Virtual Device Manager**.
2. Create a device and select the **API 35 ("VanillaIceCream")** system image.
3. Start the virtual device.
4. Run:
   ```bash
   flutter run
   ```

---

## Code Quality & Static Analysis

```bash
flutter analyze
```
