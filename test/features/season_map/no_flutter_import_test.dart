import 'dart:io';

import 'package:test/test.dart';

/// The **season** model and the ordering rule carry no Flutter import.
///
/// `season-map` is not on the project's test-first list, but these two are the
/// same shape as the parts that are: between them they decide what the player
/// has completed and where they stand, and they fail silently — a **current
/// node** that drifts backwards withdraws progress with no error anywhere.
/// Keeping them out of Flutter is what keeps them testable by the plain runner.
void main() {
  test('no file under lib/features/season_map/domain imports Flutter', () {
    final root = Directory('lib/features/season_map/domain');
    expect(root.existsSync(), isTrue, reason: 'run from the package root');

    final offenders = <String>[];
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      for (final line in entity.readAsLinesSync()) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) {
          continue;
        }
        if (trimmed.contains('package:flutter/') ||
            trimmed.contains('package:flutter_test/') ||
            trimmed.contains('package:flutter_riverpod/') ||
            trimmed.contains('package:drift/') ||
            trimmed.contains('dart:ui')) {
          offenders.add('${entity.path}: $trimmed');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  // Named as well as scoped: a move out of `domain/` would pass the check above
  // by leaving its scope, which is how a guard stops guarding anything.
  test('the model, the rule, and season one are pure Dart', () {
    for (final path in const <String>[
      'lib/features/season_map/domain/season.dart',
      'lib/features/season_map/domain/node_type.dart',
      'lib/features/season_map/domain/trail_progress.dart',
      'lib/features/season_map/domain/season_one.dart',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: '$path has moved');
    }
  });
}
