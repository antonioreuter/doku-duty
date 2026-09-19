import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/technique_tutorials/data/lesson_repository.dart';

void main() {
  late AppDatabase db;
  late LessonRepository lessons;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    lessons = LessonRepository(db);
  });
  tearDown(() => db.close());

  group('seen', () {
    test('a lesson nobody has met has not been seen', () async {
      expect(await lessons.seen(), isEmpty);
      expect(await lessons.hasSeen('naked-pair'), isFalse);
    });

    test('marking one seen makes it read as seen', () async {
      await lessons.markSeen('naked-pair');

      expect(await lessons.hasSeen('naked-pair'), isTrue);
      expect(await lessons.seen(), <String>{'naked-pair'});
    });

    test('marking does not touch any other lesson', () async {
      await lessons.markSeen('x-wing');

      expect(await lessons.hasSeen('naked-pair'), isFalse);
      expect(await lessons.seen(), <String>{'x-wing'});
    });

    test(
      'marking the same lesson twice is not an error and counts once',
      () async {
        // A replay, or a lesson skipped twice from the settings list. Seen is a
        // fact, not a count, so repeating it changes nothing.
        await lessons.markSeen('hidden-single');
        await lessons.markSeen('hidden-single');

        expect(await lessons.seen(), <String>{'hidden-single'});
      },
    );

    test('several lessons accumulate', () async {
      for (final id in <String>['hidden-single', 'naked-pair', 'notes']) {
        await lessons.markSeen(id);
      }

      expect(await lessons.seen(), <String>{
        'hidden-single',
        'naked-pair',
        'notes',
      });
    });
  });

  group('the record survives being written', () {
    test(
      'a lesson marked seen is on disk before the app could be taken away',
      () async {
        final dir = Directory.systemTemp.createTempSync('doku_lessons');
        addTearDown(() => dir.deleteSync(recursive: true));
        final file = File('${dir.path}/app.sqlite');

        final first = AppDatabase(NativeDatabase(file));
        await LessonRepository(first).markSeen('swordfish');
        await first.close();

        final second = AppDatabase(NativeDatabase(file));
        addTearDown(second.close);
        expect(await LessonRepository(second).hasSeen('swordfish'), isTrue);
      },
    );
  });
}
