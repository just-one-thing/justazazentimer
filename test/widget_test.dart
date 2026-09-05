import 'package:flutter_test/flutter_test.dart';
import 'package:justazazentimer/main.dart';

void main() {
  testWidgets('ZazenTimerApp initial render and duration selection',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ZazenTimerApp());

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

  testWidgets('ZazenTimerApp starts countdown and shows controls',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ZazenTimerApp());

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

    // Back to idle state
    expect(find.text('Zazen Meditation'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
  });
}
