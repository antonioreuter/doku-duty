import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The config layer must cost nothing at startup.
///
/// The persistence layer has the same guard for the same reason: everything
/// added to the first-frame path is paid on every cold start for the life of
/// the app, and the 2-second budget has no slack budgeted for a network call.
void main() {
  test('bootstrap starts the refresh after the first frame, not before it', () {
    final bootstrap = File('lib/bootstrap.dart').readAsStringSync();

    // The refresh is reachable only through a post-frame callback.
    expect(bootstrap, contains('addPostFrameCallback'));

    final lines = bootstrap.split('\n');
    final runAppLine = lines.indexWhere(
      (l) => l.contains('runApp(') && !l.startsWith('//'),
    );
    final refreshLine = lines.indexWhere(
      (l) => l.contains('configRefresherProvider'),
    );

    expect(runAppLine, isNonNegative);
    expect(refreshLine, isNonNegative);
    expect(
      refreshLine,
      greaterThan(runAppLine),
      reason: 'the config refresh moved ahead of runApp',
    );
  });

  test('the refresh is not awaited before the app runs', () {
    final bootstrap = File('lib/bootstrap.dart').readAsStringSync();
    for (final line in bootstrap.split('\n')) {
      final code = line.split('//').first;
      if (code.contains('configRefresherProvider')) {
        expect(
          code.contains('await ') && !code.contains('unawaited'),
          isFalse,
          reason: 'bootstrap waits for the config refresh: $line',
        );
      }
    }
  });

  test(
    'nothing in the config layer reads a file or a directory at import time',
    () {
      // The transport is the only I/O, and it is constructed lazily behind a
      // provider. A top-level initialiser doing work would run on import.
      final dir = Directory('lib/features/remote_config');
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        expect(
          RegExp(
            r'^final \w+ = (HttpClient|File|Directory)\(',
            multiLine: true,
          ).hasMatch(source),
          isFalse,
          reason: '${entity.path} does work at import time',
        );
      }
    },
  );
}
