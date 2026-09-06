import 'bootstrap.dart';
import 'features/platform_shell/domain/flavour.dart';

/// Entry point for the `staging` flavour.
///
/// Run with: flutter run --flavor staging -t lib/main_staging.dart
void main() => bootstrap(FlavourConfig.staging);
