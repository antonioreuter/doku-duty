import 'bootstrap.dart';
import 'features/platform_shell/domain/flavour.dart';

/// Entry point for the `prod` flavour.
///
/// Run with: flutter run --flavor prod -t lib/main_prod.dart
void main() => bootstrap(FlavourConfig.prod);
