import 'dart:io';

import 'package:test/test.dart';

/// What an event earns is decided in pure Dart.
///
/// `stamps` is not on the project's test-first list, but the rules are the same
/// shape as the ones that are: they decide saved progress and fail silently. A
/// perfect solve that pays twice, or a milestone that never pays, has no symptom
/// a player could report.
void main() {
  test('no file under lib/features/stamps/domain imports Flutter or Drift', () {
    final root = Directory('lib/features/stamps/domain');
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

  // Named as well as scoped: moving a file out of `domain/` would otherwise
  // pass the check above by leaving its scope.
  test('the earning and its rules are pure Dart', () {
    for (final path in const <String>[
      'lib/features/stamps/domain/earning.dart',
      'lib/features/stamps/domain/earning_rules.dart',
    ]) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path has moved or gone');
      for (final line in file.readAsLinesSync()) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('import ')) continue;
        expect(trimmed.contains('package:flutter'), isFalse, reason: path);
      }
    }
  });
}
