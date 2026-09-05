# Just A Zazen Timer (Android)

A minimalist, distraction-free Zazen (Zen meditation) timer app built with Flutter and Kotlin.

## Features & Target Platform
- **Target OS**: Android 15 (API 35) and newer (Android 16+ ready)
- **Language**: Dart (Flutter 3.47+) & Kotlin (AGP 9.1+)
- **Design**: Clean Material 3 zen aesthetic, supporting light and dark themes with system edge-to-edge support.

## Project Structure
- [`lib/main.dart`](file:///home/lorenzo/Workspace/justazazentimer/lib/main.dart) - Main app entry point and meditation timer UI
- [`lib/models/timer_state.dart`](file:///home/lorenzo/Workspace/justazazentimer/lib/models/timer_state.dart) - Timer configuration and state model
- [`test/models/timer_state_test.dart`](file:///home/lorenzo/Workspace/justazazentimer/test/models/timer_state_test.dart) - Unit tests for timer logic
- [`test/widget_test.dart`](file:///home/lorenzo/Workspace/justazazentimer/test/widget_test.dart) - Widget and UI interaction tests
- [`android/app/build.gradle.kts`](file:///home/lorenzo/Workspace/justazazentimer/android/app/build.gradle.kts) - Android build configuration (Kotlin DSL, `compileSdk 35`, `targetSdk 35`)

## Running the App & Tests

### Run Tests
```bash
flutter test
```

### Static Analysis
```bash
flutter analyze
```

### Run on Device or Emulator
```bash
flutter run
```
