import 'dart:io';

import 'package:test/test.dart';

/// The **lesson** catalogue and the due rule carry no Flutter import.
///
/// `technique-tutorials` is not on the project's test-first list, but this half
/// of it is the same shape as the parts that are: the rule decides whether a
/// player is ever taught anything, and it fails silently — a **lesson** that
/// stops firing teaches nothing and reports nothing. Keeping it out of Flutter
/// is what keeps it testable by the plain runner.
void main() {
  test(
    'no file under lib/features/technique_tutorials/domain imports Flutter',
    () {
      final root = Directory('lib/features/technique_tutorials/domain');
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

  // Named as well as scoped: a move out of `domain/` would pass the check above
  // by leaving its scope, which is how a guard stops guarding anything.
  test('the rule and the model are pure Dart', () {
    for (final path in const <String>[
      'lib/features/technique_tutorials/domain/due_lesson.dart',
      'lib/features/technique_tutorials/domain/lesson.dart',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: '$path has moved');
    }
  });
}
