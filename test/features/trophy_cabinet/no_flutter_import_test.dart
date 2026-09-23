import 'dart:io';

import 'package:test/test.dart';

/// The **award** model and the catalogue carry no Flutter import.
///
/// `trophy-cabinet` is not on the project's test-first list, and this change
/// does not extend it. The same standard is applied anyway for the reason the
/// `season-map` and `daily-challenge` guards give: these decide what the player
/// has permanently earned, and they fail silently. A missing **trophy** looks
/// exactly like one never earned, so there is no symptom to notice and no bug
/// report to file.
void main() {
  test('no file under lib/features/trophy_cabinet/domain imports Flutter', () {
    final root = Directory('lib/features/trophy_cabinet/domain');
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
  test('the award model and the catalogue are pure Dart', () {
    for (final path in const <String>[
      'lib/features/trophy_cabinet/domain/award.dart',
      'lib/features/trophy_cabinet/domain/award_catalogue.dart',
    ]) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path has moved or gone');
      for (final line in file.readAsLinesSync()) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('import ')) continue;
        expect(
          trimmed.contains('package:flutter'),
          isFalse,
          reason: '$path took a Flutter import',
        );
      }
    }
  });
}
