import 'bootstrap.dart';
import 'features/platform_shell/domain/flavour.dart';

/// Entry point for the `dev` flavour.
///
/// Run with: flutter run --flavor dev -t lib/main_dev.dart
void main() => bootstrap(FlavourConfig.dev);
