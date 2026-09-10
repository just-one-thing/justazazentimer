import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justazazentimer/main.dart';
import 'package:justazazentimer/services/bell_service.dart';
import 'package:justazazentimer/services/dnd_service.dart';
import 'package:justazazentimer/services/session_alarm_service.dart';

void main() {
  testWidgets('ZazenTimerApp initial render, duration selection, and DND chip',
      (WidgetTester tester) async {
    final mockBell = MockBellService();
    final mockAlarm = MockSessionAlarmService();
    final mockDnd = MockDndService();
    await tester.pumpWidget(ZazenTimerApp(
      bellService: mockBell,
      alarmService: mockAlarm,
      dndService: mockDnd,
    ));

    expect(mockAlarm.isInitialized, isTrue);

    // Verify initial text and time
    expect(find.text('Zazen Meditation'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('25 minute sitting'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
    expect(find.text('Do Not Disturb during sitting'), findsOneWidget);

    // Select 15 minute preset
    await tester.tap(find.text('15 m'));
    await tester.pump();

    // Verify display updated to 15:00
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text('15 minute sitting'), findsOneWidget);
  });

  testWidgets('Test Tibetan Bell icon button triggers 3 dings',
      (WidgetTester tester) async {
    final mockBell = MockBellService();
    final mockAlarm = MockSessionAlarmService();
    final mockDnd = MockDndService();
    await tester.pumpWidget(ZazenTimerApp(
      bellService: mockBell,
      alarmService: mockAlarm,
      dndService: mockDnd,
    ));

    expect(mockBell.threeBellsPlayCount, 0);

    // Tap bell icon button
    await tester.tap(find.byIcon(Icons.notifications_active_outlined));
    await tester.pump();

    expect(mockBell.threeBellsPlayCount, 1);
    expect(
      find.text('Playing 3 Tibetan bell dings (2s interval)...'),
      findsOneWidget,
    );
  });

  testWidgets('ZazenTimerApp starts countdown, enables wakelock and controls',
      (WidgetTester tester) async {
    final mockBell = MockBellService();
    final mockAlarm = MockSessionAlarmService();
    final mockDnd = MockDndService();
    await tester.pumpWidget(ZazenTimerApp(
      bellService: mockBell,
      alarmService: mockAlarm,
      dndService: mockDnd,
    ));

    // Tap Begin button
    await tester.tap(find.text('Begin'));
    await tester.pump();

    // With prep duration (10s), phase transitions to preparation
    expect(find.text('Prepare to Sit'), findsOneWidget);
    expect(find.text('00:10'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(mockAlarm.wakelockActive, isTrue);

    // Tap Reset
    await tester.tap(find.text('Reset'));
    await tester.pump();

    // Reset should stop bell audio, cancel alarm, release wakelock and return to idle
    expect(mockBell.stopCount, greaterThanOrEqualTo(1));
    expect(mockAlarm.cancelCount, greaterThanOrEqualTo(1));
    expect(mockAlarm.wakelockActive, isFalse);
    expect(mockDnd.isDndActive, isFalse);
    expect(find.text('Zazen Meditation'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
  });

  testWidgets(
      'Bell rings 3 dings, schedules exact alarm, and enables DND when sitting starts after prep',
      (WidgetTester tester) async {
    final mockBell = MockBellService();
    final mockAlarm = MockSessionAlarmService();
    final mockDnd = MockDndService();
    await tester.pumpWidget(ZazenTimerApp(
      bellService: mockBell,
      alarmService: mockAlarm,
      dndService: mockDnd,
    ));

    // Tap Begin
    await tester.tap(find.text('Begin'));
    await tester.pump();

    // Fast-forward 10 seconds of preparation
    await tester.pump(const Duration(seconds: 10));

    // Sitting phase begins:
    // 1) 3 bells played
    // 2) Exact alarm scheduled for 25 minutes
    // 3) Wakelock kept active
    // 4) DND enabled
    expect(find.text('Zazen'), findsOneWidget);
    expect(mockBell.threeBellsPlayCount, 1);
    expect(mockAlarm.scheduledDuration, const Duration(minutes: 25));
    expect(mockAlarm.wakelockActive, isTrue);
    expect(mockDnd.isDndActive, isTrue);
    expect(find.text('Do Not Disturb Active'), findsOneWidget);

    // Fast forward through the 25 minute sitting
    await tester.pump(const Duration(minutes: 25));

    // Session completes:
    // 1) 3 bells played again
    // 2) Wakelock released
    // 3) DND disabled
    expect(find.text('Session Complete'), findsOneWidget);
    expect(mockBell.threeBellsPlayCount, 2);
    expect(mockAlarm.wakelockActive, isFalse);
    expect(mockDnd.isDndActive, isFalse);
  });

  testWidgets('Toggling DND filter chip updates configuration',
      (WidgetTester tester) async {
    final mockBell = MockBellService();
    final mockAlarm = MockSessionAlarmService();
    final mockDnd = MockDndService();
    await tester.pumpWidget(ZazenTimerApp(
      bellService: mockBell,
      alarmService: mockAlarm,
      dndService: mockDnd,
    ));

    // Find DND chip and tap it to toggle off
    await tester.tap(find.text('Do Not Disturb during sitting'));
    await tester.pump();

    // Start timer with DND disabled
    await tester.tap(find.text('Begin'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    // Sitting begins without DND
    expect(find.text('Zazen'), findsOneWidget);
    expect(mockDnd.isDndActive, isFalse);
    expect(find.text('Do Not Disturb Active'), findsNothing);
  });
}
