import 'dart:io';

import 'package:test/test.dart';

/// The pack install must cost nothing at startup, and must need nothing.
///
/// Both halves matter. Three hundred inserts on the first-frame path would be
/// paid on every cold start for the life of the app, and a network call would
/// mean a fresh install in airplane mode had no puzzles at all — which is the
/// whole reason the **pack** is bundled rather than fetched (D-32).
void main() {
  final bootstrap = File('lib/bootstrap.dart').readAsStringSync();

  test('bootstrap installs the pack after the first frame, not before it', () {
    expect(bootstrap, contains('addPostFrameCallback'));

    final lines = bootstrap.split('\n');
    final runAppLine = lines.indexWhere(
      (line) => line.contains('runApp(') && !line.trim().startsWith('//'),
    );
    final installLine = lines.indexWhere(
      (line) => line.contains('packInstallationProvider'),
    );

    expect(runAppLine, isNonNegative);
    expect(installLine, isNonNegative, reason: 'the pack is never installed');
    expect(
      installLine,
      greaterThan(runAppLine),
      reason: 'the pack install moved ahead of runApp',
    );
  });

  test('the install is not awaited before the app runs', () {
    for (final line in bootstrap.split('\n')) {
      final code = line.split('//').first;
      if (!code.contains('packInstallationProvider')) continue;
      expect(
        code.contains('await ') && !code.contains('unawaited'),
        isFalse,
        reason: 'bootstrap waits for the pack install: $line',
      );
    }
  });

  // A fresh install with no network must have the full six ranks of content.
  // This change adds no network at all, and this is what keeps it that way.
  test('nothing in the puzzle engine reaches the network', () {
    final offenders = <String>[];
    for (final entity in Directory(
      'lib/features/puzzle_engine',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final forbidden in const <String>[
        'HttpClient',
        'package:http/',
        'Socket.connect',
        'WebSocket',
        'dart:html',
      ]) {
        if (source.contains(forbidden)) {
          offenders.add('${entity.path}: $forbidden');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('the pack is read from the asset bundle, not from a URL', () {
    final source = File(
      'lib/features/puzzle_engine/data/pack_source.dart',
    ).readAsStringSync();
    expect(source, contains('rootBundle'));
    expect(source, isNot(contains('http')));
  });
}
