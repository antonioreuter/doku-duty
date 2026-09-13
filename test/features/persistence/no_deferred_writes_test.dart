import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The guard for constraint 9.
///
/// The durability tests prove the write lands *today*. This proves nothing has
/// been inserted between the change and the write — which is how it regresses,
/// usually with a good intention attached ("coalesce these, the player is
/// typing fast").
///
/// It asserts the **shape** of the code, not its timing. A timing assertion
/// passes on a fast machine and on CI, and fails on the cheap Android phone
/// nobody tests on.
void main() {
  final persistence = Directory('lib/features/persistence');

  List<({String path, String source})> sources() =>
      <({String path, String source})>[
        for (final entity in persistence.listSync(recursive: true))
          if (entity is File &&
              entity.path.endsWith('.dart') &&
              !entity.path.endsWith('.g.dart'))
            (path: entity.path, source: entity.readAsStringSync()),
      ];

  test('nothing defers a write behind a timer or a debounce', () {
    final banned = <RegExp, String>{
      RegExp(r'\bTimer\b'): 'a timer',
      RegExp(r'\bperiodic\b'): 'a periodic callback',
      RegExp(r'\bdebounce\b', caseSensitive: false): 'a debounce',
      RegExp(r'\bthrottle\b', caseSensitive: false): 'a throttle',
      RegExp(r'\bFuture(<[^>]*>)?\.delayed\b'): 'a delay',
      RegExp(r'didChangeAppLifecycleState|AppLifecycleState'):
          'an app-lifecycle hook',
      RegExp(r'\bflush\b', caseSensitive: false): 'a flush step',
    };

    final violations = <String>[];
    for (final file in sources()) {
      final lines = file.source.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].split('//').first;
        for (final entry in banned.entries) {
          if (entry.key.hasMatch(code)) {
            violations.add('${file.path}:${i + 1} — ${entry.value}');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Note state is written on every change, never on a timer (D-33). '
          'Whatever this was meant to optimise, the thing it costs is a '
          "player's board.\n${violations.join('\n')}",
    );
  });

  test('the note write path does not batch', () {
    // drift's `batch()` is legitimate for bulk work — seeding a pack, a
    // migration. It is not legitimate on the path a single note takes, because
    // a batch is exactly the deferral this constraint forbids.
    final repository = File(
      'lib/features/persistence/data/note_repository.dart',
    ).readAsStringSync();

    final lines = repository.split('\n');
    final offenders = <String>[
      for (var i = 0; i < lines.length; i++)
        if (RegExp(r'\.batch\s*\(').hasMatch(lines[i].split('//').first))
          'note_repository.dart:${i + 1}',
    ];
    expect(
      offenders,
      isEmpty,
      reason: 'a single note change is a single statement',
    );
  });

  test('every note write is issued as its own statement', () {
    // Each public write method reaches sqlite directly. If one ever starts by
    // appending to a list or a queue, that is the buffer this forbids.
    final repository = File(
      'lib/features/persistence/data/note_repository.dart',
    ).readAsStringSync();

    for (final method in <String>['put', 'remove', 'putCells']) {
      expect(
        RegExp('Future<void> $method').hasMatch(repository),
        isTrue,
        reason: '$method is missing or changed shape',
      );
    }
    // No field holding pending work.
    expect(
      RegExp(r'final\s+(List|Queue|Map|Set)<').hasMatch(repository),
      isFalse,
      reason: 'a collection field in the repository is a write buffer',
    );
  });
}
