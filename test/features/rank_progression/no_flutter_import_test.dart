import 'dart:io';

import 'package:test/test.dart';

/// The progression rule carries no Flutter import.
///
/// `rank-progression` is on the project's test-first list, and the reason is
/// the same one that put the engine and the mistake model there: a silent bug
/// here corrupts permanent player progress, so it has to be testable by the
/// plain runner with no platform in the way. The import is what would introduce
/// one, so the import is what is asserted — the same guard
/// `puzzle_engine/domain` already carries.
void main() {
  test(
    'no file under lib/features/rank_progression/domain imports Flutter',
    () {
      final root = Directory('lib/features/rank_progression/domain');
      expect(root.existsSync(), isTrue, reason: 'run from the package root');

      final offenders = <String>[];
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        for (final line in entity.readAsLinesSync()) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('import ') &&
              !trimmed.startsWith('export ')) {
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
    },
  );

  // Named as well as scoped by directory: a move that took the rule out of
  // `domain/` would pass the check above by leaving its scope, which is exactly
  // how the guard would stop guarding anything.
  test('the rank rule is pure Dart', () {
    final file = File('lib/features/rank_progression/domain/player_rank.dart');
    expect(file.existsSync(), isTrue, reason: 'the rank rule has moved');
  });
}
