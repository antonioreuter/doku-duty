import 'package:doku_duty/features/platform_shell/application/orientation.dart';
import 'package:doku_duty/features/platform_shell/domain/device_class.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a phone is locked to portrait', () {
    expect(orientationsFor(DeviceClass.phone), [DeviceOrientation.portraitUp]);
  });

  test('a tablet may rotate', () {
    final tablet = orientationsFor(DeviceClass.tablet);

    expect(tablet, contains(DeviceOrientation.landscapeLeft));
    expect(tablet, contains(DeviceOrientation.landscapeRight));
    expect(tablet, contains(DeviceOrientation.portraitUp));
  });
}
