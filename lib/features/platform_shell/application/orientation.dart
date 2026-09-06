import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../domain/device_class.dart';

/// The orientations each device class is allowed.
///
/// Portrait is primary; landscape is a tablet affordance only
/// (`openspec/project.md`, Platform requirements).
List<DeviceOrientation> orientationsFor(DeviceClass deviceClass) {
  return switch (deviceClass) {
    DeviceClass.phone => const [DeviceOrientation.portraitUp],
    DeviceClass.tablet => const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
  };
}

/// The device class of the screen the app launched on.
DeviceClass currentDeviceClass(WidgetsBinding binding) {
  final view = binding.platformDispatcher.views.first;
  final size = view.physicalSize / view.devicePixelRatio;
  return deviceClassForShortestSide(size.shortestSide);
}

/// Applies the orientation lock for [deviceClass].
///
/// Deliberately not awaited by the caller: the platform channel round trip
/// must not sit on the path to the first frame.
Future<void> applyOrientationLock(DeviceClass deviceClass) {
  return SystemChrome.setPreferredOrientations(orientationsFor(deviceClass));
}
