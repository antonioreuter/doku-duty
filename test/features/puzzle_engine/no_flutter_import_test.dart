import 'dart:io';

import 'package:test/test.dart';

/// The engine's pure core carries no Flutter import, so it can be unit-tested
/// by the plain runner and cannot quietly acquire a platform behaviour. The
/// import is what would introduce one, so the import is what is asserted.
///
/// Scoped to `domain/` rather than the whole feature since
/// `add-puzzle-generation`: reading the bundled **pack** needs Flutter's asset
/// bundle, and that reader lives in `data/` exactly so this rule can keep
/// holding where it matters. The solver, the grader, the uniqueness check, the
/// generator, and the pack format are all under `domain/`.
void main() {
  final offenders = <String>[];

  bool importsFlutter(File file) {
    var found = false;
    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) {
        continue;
      }
      if (trimmed.contains('package:flutter/') ||
          trimmed.contains('package:flutter_test/') ||
          trimmed.contains('package:flutter_riverpod/') ||
          trimmed.contains('dart:ui')) {
        offenders.add('${file.path}: $trimmed');
        found = true;
      }
    }
    return found;
  }

  setUp(offenders.clear);

  test('no file under lib/features/puzzle_engine/domain imports Flutter', () {
    final root = Directory('lib/features/puzzle_engine/domain');
    expect(root.existsSync(), isTrue, reason: 'run from the package root');

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      importsFlutter(entity);
    }
    expect(offenders, isEmpty);
  });

  // Named individually as well as by directory: these two are what the tool
  // runs outside a device, and a move that took either out of `domain/` would
  // pass the directory check above by leaving its scope.
  test('the pack format and the generator are pure Dart', () {
    for (final path in const <String>[
      'lib/features/puzzle_engine/domain/pack.dart',
      'lib/features/puzzle_engine/domain/generator.dart',
    ]) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path has moved');
      importsFlutter(file);
    }
    expect(offenders, isEmpty);
  });
}
