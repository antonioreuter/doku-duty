import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/flavour.dart';

/// The running flavour.
///
/// Fixed at build time, so it is overridden once in [bootstrap] rather than
/// computed. Reading it without that override is a programming error, not a
/// runtime condition to handle.
final flavourConfigProvider = Provider<FlavourConfig>(
  (ref) => throw StateError(
    'flavourConfigProvider must be overridden by bootstrap()',
  ),
);
