import 'package:flutter_test/flutter_test.dart';
import 'package:justazazentimer/services/session_alarm_service.dart';

void main() {
  group('MockSessionAlarmService', () {
    test('tracks initialization, scheduling, wakelock, and cancellation',
        () async {
      final alarmService = MockSessionAlarmService();

      expect(alarmService.isInitialized, isFalse);
      expect(alarmService.scheduledDuration, isNull);
      expect(alarmService.wakelockActive, isFalse);
      expect(alarmService.cancelCount, 0);

      await alarmService.initialize();
      expect(alarmService.isInitialized, isTrue);

      await alarmService.setScreenWakelock(true);
      expect(alarmService.wakelockActive, isTrue);

      await alarmService
          .scheduleSessionEndAlarm(duration: const Duration(minutes: 25));
      expect(alarmService.scheduledDuration, const Duration(minutes: 25));

      await alarmService.cancelSessionEndAlarm();
      expect(alarmService.cancelCount, 1);
      expect(alarmService.scheduledDuration, isNull);

      await alarmService.setScreenWakelock(false);
      expect(alarmService.wakelockActive, isFalse);
    });
  });
}
