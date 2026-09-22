import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../grid_input/presentation/puzzle_screen.dart';
import '../../grid_input/presentation/settings_screen.dart';
import '../presentation/home_shell.dart';

/// Route paths, so nothing addresses a screen by a bare string.
abstract final class Routes {
  static const String home = '/';
  static const String settings = '/settings';

  /// A puzzle is addressed by its id, never by position in a list.
  static const String puzzle = '/puzzle/:puzzleId';

  static String puzzlePath(String puzzleId) => '/puzzle/$puzzleId';

  static void goPuzzle(BuildContext context, String puzzleId) =>
      GoRouter.of(context).push(puzzlePath(puzzleId));

  static void goSettings(BuildContext context) =>
      GoRouter.of(context).push(settings);
}

/// The router.
///
/// Home is the **trail** and **free play** behind one navigation bar. The daily
/// challenge and the cabinet arrive with the changes that own them — adding
/// empty placeholders now would be guessing at their arguments, which is why
/// this comment said the same thing about the **trail** until `add-season-map`
/// landed it.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: Routes.home,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.puzzle,
        builder: (context, state) =>
            PuzzleScreen(puzzleId: state.pathParameters['puzzleId']!),
      ),
    ],
  );
}
