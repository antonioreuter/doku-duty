import 'dart:io';

import 'package:test/test.dart';

/// The date, the **calendar**, the **streak freeze**, and schedule resolution
/// carry no Flutter import.
///
/// `daily-challenge` is not on the project's test-first list — that list is the
/// puzzle engine, notes, the mistake model, and **rank** progression, and this
/// change does not extend it. These files are kept to the same standard anyway
/// because they are the same shape as the ones that are on it: they decide what
/// the player has done and for how long, and they fail silently. A **streak**
/// that drops by one is indistinguishable from a day the player genuinely
/// missed, so there is no symptom to notice and no bug report to file.
void main() {
  test('no file under lib/features/daily_challenge/domain imports Flutter', () {
    final root = Directory('lib/features/daily_challenge/domain');
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

  // Named as well as scoped, for the reason the season-map guard gives: moving
  // a file out of `domain/` would pass the scoped check by leaving its scope.
  test(
    'the date, the calendar, the freeze, and the schedule are pure Dart',
    () {
      for (final path in const <String>[
        'lib/features/daily_challenge/domain/daily_date.dart',
        'lib/features/daily_challenge/domain/daily_calendar.dart',
        'lib/features/daily_challenge/domain/streak_freeze.dart',
        'lib/features/daily_challenge/domain/daily_schedule.dart',
        'lib/features/daily_challenge/domain/daily_resolver.dart',
        'lib/features/daily_challenge/domain/daily_board_source.dart',
        'lib/features/daily_challenge/domain/clock_trust.dart',
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
    },
  );
}
