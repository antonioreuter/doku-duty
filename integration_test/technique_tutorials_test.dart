import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';

import '../test/drift/app_database/generated/schema_v3.dart' as v3;
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver_state.dart';
import 'package:doku_duty/features/puzzle_engine/domain/techniques/ladder.dart';
import 'package:doku_duty/features/technique_tutorials/data/lesson_repository.dart';
import 'package:doku_duty/features/technique_tutorials/domain/due_lesson.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson_catalogue.dart';
import 'package:doku_duty/features/technique_tutorials/presentation/lesson_view.dart';

/// What the **lesson**s do on a real platform.
///
/// The host suite proves the rule, the catalogue and the surface. What this
/// adds is the device's own SQLite — including the v3-to-v4 migration on a
/// database file the platform wrote — and the device's own rasteriser under
/// the walkthrough.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('every lesson still teaches what its grid holds, on the device', () {
    // The catalogue is compiled in, so this is really asking whether the
    // engine agrees with it on this platform's arithmetic.
    for (final lesson in lessonCatalogue) {
      final technique = lesson.technique;
      if (technique == null) continue;
      final parsed = Grid.parse(lesson.grid) as ValidGrid;
      final state = SolverState.fromGrid(parsed.grid);
      expect(
        techniqueFor(technique).deduce(state),
        isNotNull,
        reason: '${lesson.id} holds no ${technique.name} on this device',
      );
    }
  });

  test('a seen lesson survives a relaunch on this platform', () async {
    final dir = Directory.systemTemp.createTempSync('doku_lessons_device');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    await LessonRepository(first).markSeen('xWing');
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    addTearDown(second.close);
    expect(await LessonRepository(second).hasSeen('xWing'), isTrue);

    // And the rule reads it: a seen lesson is no longer due. The **notes
    // lesson** is marked too, because it is owed at every **rank** from
    // Sheriff up and would otherwise be the one that comes back — correctly,
    // but it is not what this test is asking about.
    await LessonRepository(second).markSeen('notes');
    final seen = await LessonRepository(second).seen();
    expect(
      dueLesson(
        puzzleRank: Rank.ranger,
        techniquesRequired: <Technique>{Technique.xWing},
        unlocked: const <Technique>{},
        seen: seen,
        catalogue: lessonCatalogue,
      ),
      isNull,
    );
  });

  test(
    'the schema arrives at 4 on this platform, with no lessons seen',
    () async {
      final dir = Directory.systemTemp.createTempSync('doku_schema_device');
      addTearDown(() => dir.deleteSync(recursive: true));
      final db = AppDatabase(NativeDatabase(File('${dir.path}/app.sqlite')));
      addTearDown(db.close);

      expect(db.schemaVersion, 4);
      // A fresh database and an upgraded one agree on this: nothing seen, so
      // every **lesson** is still due.
      expect(await LessonRepository(db).seen(), isEmpty);
    },
  );

  testWidgets('a lesson steps and places on this platform', (tester) async {
    final lesson = lessonCatalogue.firstWhere((l) => l.id == 'nakedPair');
    var done = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LessonView(
          lesson: lesson,
          onDone: ({required bool skipped}) => done++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < lesson.steps.length - 1; i++) {
      await tester.tap(find.byKey(const ValueKey<String>('lesson-next')));
      await tester.pumpAndSettle();
    }

    // A wrong digit costs nothing, on hardware as on the host.
    final wrong = lesson.placement.digit == 1 ? 2 : 1;
    await tester.tap(find.byKey(ValueKey<String>('lesson-digit-$wrong')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('lesson-wrong')), findsOneWidget);
    expect(done, 0);

    await tester.tap(
      find.byKey(ValueKey<String>('lesson-digit-${lesson.placement.digit}')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('lesson-right')), findsOneWidget);
  });

  test('a v3 database written on this device migrates to 4', () async {
    // The upgrade case, on the platform's own SQLite rather than the host's.
    // The v3 schema helper is the same one the host migration test uses, so
    // the file this creates is byte-for-byte what the previous build wrote.
    final dir = Directory.systemTemp.createTempSync('doku_v3_device');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    final stamp = DateTime.utc(2026, 9, 19, 12);
    final old = v3.DatabaseAtV3(NativeDatabase(file));
    await old
        .into(old.solvedPuzzles)
        .insert(
          v3.SolvedPuzzlesData(
            puzzleId: 'q-sheriff',
            solvedAt: stamp,
            updatedAt: stamp,
            pendingUpload: true,
          ),
        );
    await old.close();

    // The real app opens it, and the real migration runs.
    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);

    final solved = await upgraded
        .customSelect('SELECT puzzle_id FROM solved_puzzles')
        .get();
    expect(solved.single.data['puzzle_id'], 'q-sheriff');

    // The new table exists and is empty — so an upgrading player is owed every
    // **lesson**, not none of them.
    expect(await LessonRepository(upgraded).seen(), isEmpty);
  });
}
