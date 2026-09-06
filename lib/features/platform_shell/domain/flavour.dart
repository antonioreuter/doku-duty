/// Build flavours and the values that differ between them.
///
/// Pure Dart, no Flutter import: everything downstream reads it, and it has to
/// stay unit-testable in isolation.
library;

/// The three builds, which install side by side on one device.
enum Flavour { dev, staging, prod }

/// The per-flavour values fixed at build time.
class FlavourConfig {
  const FlavourConfig._({
    required this.flavour,
    required this.appName,
    required this.bundleIdentifier,
    required this.sentryEnvironment,
  });

  /// The running flavour.
  final Flavour flavour;

  /// The name shown under the icon. Distinct per flavour so a `dev` build is
  /// recognisable on the home screen without launching it.
  final String appName;

  /// The Android `applicationId` and the iOS bundle identifier (D-69). Kept
  /// here as well as in the two build files so a mismatch is a failing test
  /// rather than a rejected upload.
  final String bundleIdentifier;

  /// The `environment` tag on every event sent to Sentry, so `dev` noise never
  /// contaminates `prod` release health.
  final String sentryEnvironment;

  /// The identifier every flavour is derived from (D-69).
  static const String baseBundleIdentifier = 'com.alreuter.dokuduty';

  static const FlavourConfig dev = FlavourConfig._(
    flavour: Flavour.dev,
    appName: 'Duty DEV',
    bundleIdentifier: '$baseBundleIdentifier.dev',
    sentryEnvironment: 'development',
  );

  static const FlavourConfig staging = FlavourConfig._(
    flavour: Flavour.staging,
    appName: 'Duty STG',
    bundleIdentifier: '$baseBundleIdentifier.staging',
    sentryEnvironment: 'staging',
  );

  static const FlavourConfig prod = FlavourConfig._(
    flavour: Flavour.prod,
    appName: 'Doku Duty',
    bundleIdentifier: baseBundleIdentifier,
    sentryEnvironment: 'production',
  );

  static const List<FlavourConfig> values = [dev, staging, prod];

  /// The config for [flavour].
  static FlavourConfig of(Flavour flavour) =>
      values.firstWhere((config) => config.flavour == flavour);

  /// Whether this is the build players get.
  bool get isProd => flavour == Flavour.prod;

  @override
  String toString() => 'FlavourConfig(${flavour.name}, $bundleIdentifier)';
}
