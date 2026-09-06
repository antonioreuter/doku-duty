import 'package:doku_duty/features/platform_shell/domain/device_class.dart';
import 'package:test/test.dart';

void main() {
  group('deviceClassForShortestSide', () {
    test('phones are every common iPhone and Android handset width', () {
      // iPhone SE, iPhone 15, iPhone 15 Pro Max, a wide Android handset.
      for (final width in [320.0, 375.0, 393.0, 430.0, 480.0]) {
        expect(
          deviceClassForShortestSide(width),
          DeviceClass.phone,
          reason: '$width should be a phone',
        );
      }
    });

    test('tablets are iPad and Android tablet widths', () {
      // iPad mini, iPad, iPad Pro 12.9", a 10" Android tablet.
      for (final width in [744.0, 768.0, 820.0, 1024.0]) {
        expect(
          deviceClassForShortestSide(width),
          DeviceClass.tablet,
          reason: '$width should be a tablet',
        );
      }
    });

    test('the boundary itself is a tablet', () {
      expect(
        deviceClassForShortestSide(tabletShortestSideDp),
        DeviceClass.tablet,
      );
      expect(
        deviceClassForShortestSide(tabletShortestSideDp - 0.01),
        DeviceClass.phone,
      );
    });
  });
}
