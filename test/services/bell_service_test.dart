import 'package:flutter_test/flutter_test.dart';
import 'package:justazazentimer/services/bell_service.dart';

void main() {
  group('MockBellService', () {
    test('tracks play and stop calls correctly', () async {
      final service = MockBellService();

      expect(service.threeBellsPlayCount, 0);
      expect(service.singleBellPlayCount, 0);
      expect(service.stopCount, 0);

      await service.playThreeBells();
      expect(service.threeBellsPlayCount, 1);

      await service.playSingleBell();
      expect(service.singleBellPlayCount, 1);

      await service.stop();
      expect(service.stopCount, 1);
    });
  });
}
