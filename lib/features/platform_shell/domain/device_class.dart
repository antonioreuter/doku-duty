/// Whether the device is a phone or a tablet.
///
/// Pure Dart, no Flutter import, because the threshold is the only interesting
/// part and it should be testable without a binding.
library;

/// Phones and tablets, for layout decisions.
enum DeviceClass { phone, tablet }

/// The shortest-side width in logical pixels at which a device counts as a
/// tablet. 600dp is the Android breakpoint and puts every iPad on the tablet
/// side and every iPhone, including the Max sizes, on the phone side.
const double tabletShortestSideDp = 600;

/// Classifies a device by the shortest side of its screen, in logical pixels.
DeviceClass deviceClassForShortestSide(double shortestSideDp) =>
    shortestSideDp >= tabletShortestSideDp
    ? DeviceClass.tablet
    : DeviceClass.phone;
