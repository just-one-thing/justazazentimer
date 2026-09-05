import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:justazazentimer/main.dart';
import 'package:justazazentimer/services/bell_service.dart';

void main() {
  testWidgets('ZazenTimerApp initial render and duration selection',
      (WidgetTester tester) async {
    final mockBell = MockBellService();
    await tester.pumpWidget(ZazenTimerApp(bellService: mockBell));

    // Verify initial text and time
    expect(find.text('Zazen Meditation'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('25 minute sitting'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);

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
    await tester.pumpWidget(ZazenTimerApp(bellService: mockBell));

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

  testWidgets('ZazenTimerApp starts countdown and shows controls',
      (WidgetTester tester) async {
    final mockBell = MockBellService();
    await tester.pumpWidget(ZazenTimerApp(bellService: mockBell));

    // Tap Begin button
    await tester.tap(find.text('Begin'));
    await tester.pump();

    // With prep duration (10s), phase transitions to preparation
    expect(find.text('Prepare to Sit'), findsOneWidget);
    expect(find.text('00:10'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    // Tap Reset
    await tester.tap(find.text('Reset'));
    await tester.pump();

    // Reset should stop bell audio and return to idle
    expect(mockBell.stopCount, greaterThanOrEqualTo(1));
    expect(find.text('Zazen Meditation'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
  });

  testWidgets('Bell rings 3 dings when sitting starts after prep, and upon completion',
      (WidgetTester tester) async {
    final mockBell = MockBellService();
    await tester.pumpWidget(ZazenTimerApp(bellService: mockBell));

    // Tap Begin
    await tester.tap(find.text('Begin'));
    await tester.pump();

    // Fast-forward 10 seconds of preparation
    await tester.pump(const Duration(seconds: 10));

    // Sitting phase begins -> 3 bells played
    expect(find.text('Zazen'), findsOneWidget);
    expect(mockBell.threeBellsPlayCount, 1);

    // Fast forward through the 25 minute sitting
    await tester.pump(const Duration(minutes: 25));

    // Session completes -> 3 bells played again
    expect(find.text('Session Complete'), findsOneWidget);
    expect(mockBell.threeBellsPlayCount, 2);
  });
}
