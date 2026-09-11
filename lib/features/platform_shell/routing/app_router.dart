import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../grid_input/presentation/puzzle_screen.dart';
import '../../grid_input/presentation/rank_picker_screen.dart';
import '../../grid_input/presentation/settings_screen.dart';

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
/// The season map and the cabinet arrive with the changes that own them —
/// adding empty placeholders now would be guessing at their arguments. The home
/// route is a **rank** picker only until `add-season-map` replaces it.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: Routes.home,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const RankPickerScreen(),
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
