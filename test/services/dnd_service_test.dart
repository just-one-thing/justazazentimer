import 'package:flutter_test/flutter_test.dart';
import 'package:justazazentimer/services/dnd_service.dart';

void main() {
  group('MockDndService', () {
    test('tracks permission, enable, disable, and settings calls', () async {
      final dndService = MockDndService();

      expect(await dndService.isPermissionGranted(), isTrue);
      expect(dndService.isDndActive, isFalse);
      expect(dndService.enableDndCount, 0);
      expect(dndService.disableDndCount, 0);

      final enabled = await dndService.enableDnd();
      expect(enabled, isTrue);
      expect(dndService.isDndActive, isTrue);
      expect(dndService.enableDndCount, 1);

      final disabled = await dndService.disableDnd();
      expect(disabled, isTrue);
      expect(dndService.isDndActive, isFalse);
      expect(dndService.disableDndCount, 1);

      await dndService.openSettings();
      expect(dndService.openSettingsCount, 1);
    });

    test('fails to enable when permission is denied', () async {
      final dndService = MockDndService();
      dndService.permissionGranted = false;

      expect(await dndService.isPermissionGranted(), isFalse);
      final enabled = await dndService.enableDnd();
      expect(enabled, isFalse);
      expect(dndService.isDndActive, isFalse);
    });
  });
}
