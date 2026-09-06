import 'package:go_router/go_router.dart';

import '../presentation/placeholder_screen.dart';

/// Route paths, so nothing addresses a screen by a bare string.
abstract final class Routes {
  static const String home = '/';
}

/// The router.
///
/// Exactly one route. The season map, the cabinet, and the puzzle screens
/// arrive with the changes that own them — adding empty placeholders now would
/// be guessing at their arguments.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const PlaceholderScreen(),
      ),
    ],
  );
}
