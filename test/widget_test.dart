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

    // Verify logo and initial time display
    expect(find.byType(Image), findsOneWidget);
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

  testWidgets('ZazenTimerApp renders top logo prominently',
      (WidgetTester tester) async {
    final mockBell = MockBellService();
    final mockAlarm = MockSessionAlarmService();
    final mockDnd = MockDndService();
    await tester.pumpWidget(ZazenTimerApp(
      bellService: mockBell,
      alarmService: mockAlarm,
      dndService: mockDnd,
    ));

    // Logo image is present
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<Image>(imageFinder);
    expect(imageWidget.width, 200);
    expect(imageWidget.height, 200);
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
    expect(find.text('Get comfortable in your seat'), findsOneWidget);
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
    expect(find.text('25 minute sitting'), findsOneWidget);
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
    expect(find.text('Keep posture, breathe naturally'), findsOneWidget);
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
    expect(find.text('Session complete'), findsOneWidget);
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
    expect(find.text('Keep posture, breathe naturally'), findsOneWidget);
    expect(mockDnd.isDndActive, isFalse);
    expect(find.text('Do Not Disturb Active'), findsNothing);
  });

  testWidgets(
      'About dialog displays app info, GPLv3 license, and Ko-fi button',
      (WidgetTester tester) async {
    final mockBell = MockBellService();
    final mockAlarm = MockSessionAlarmService();
    final mockDnd = MockDndService();
    await tester.pumpWidget(ZazenTimerApp(
      bellService: mockBell,
      alarmService: mockAlarm,
      dndService: mockDnd,
    ));

    // Tap info icon in top corner
    final infoButtonFinder = find.byTooltip('About & Support');
    expect(infoButtonFinder, findsOneWidget);
    await tester.tap(infoButtonFinder);
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('Just A Zazen Timer'), findsWidgets);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('GNU GPL v3.0 License'), findsOneWidget);
    expect(find.text('Support on Ko-fi'), findsOneWidget);
    expect(find.text('Source Code (GitHub)'), findsOneWidget);

    // Tap Close button
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // Dialog dismissed
    expect(find.text('GNU GPL v3.0 License'), findsNothing);
  });
}

