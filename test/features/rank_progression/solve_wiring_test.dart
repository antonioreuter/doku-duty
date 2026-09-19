import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/grid_input/application/grid_providers.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_controller.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/note_repository.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/data/puzzle_save_repository.dart';
import 'package:doku_duty/features/persistence/data/statistics_repository.dart';
import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';

import '../persistence/support/fixture_pack.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// Play [controller] to a finished board, or stop [short] of the last cell.
Future<void> _solve(PuzzleController controller, {int short = 0}) async {
  final empty = <int>[
    for (var cell = 0; cell < 81; cell++)
      if (_clues[cell] == '.') cell,
  ];
  for (final cell in empty.take(empty.length - short)) {
    controller.tapCell(cell);
    controller.tapKey(DigitKey(int.parse(_solution[cell])));
  }
  // The writes are started unawaited so the frame never waits on the database
  // (constraint 9's rule, constraint 2's reason). Give them a turn to land.
  await Future<void>.delayed(Duration.zero);
}

PuzzleController _controllerFor(AppDatabase db, Rank rank) {
  final puzzle = fixturePuzzle('fixture-${rank.name}', rank);
  return PuzzleController(
    puzzle: puzzle,
    sink: RepositoryBoardSink(
      PuzzleSaveRepository(db),
      NoteRepository(db),
      ProgressionRepository(db),
    ),
    techniquesRequired: const <Technique>{Technique.nakedSingle},
    initial: sessionFor(
      puzzle: puzzle,
      placedValues: null,
      mode: InputMode.cellFirst,
    ),
  );
}

void main() {
  late AppDatabase db;
  late ProgressionRepository progression;
  late StatisticsRepository stats;
  late PackRepository packs;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    progression = ProgressionRepository(db);
    stats = StatisticsRepository(db);
    packs = PackRepository(db);
    await installFixturePack(packs);
  });
  tearDown(() => db.close());

  group('finishing a puzzle', () {
    test('writes the solve record and raises the rank', () async {
      final controller = _controllerFor(db, Rank.sheriff);
      addTearDown(controller.dispose);

      expect(await progression.playerRank(), Rank.greenhorn);

      await _solve(controller);

      expect(controller.isSolved, isTrue);
      expect(await packs.isSolved('fixture-sheriff'), isTrue);
      expect((await stats.lifetime()).puzzlesSolved, 1);
      expect(await stats.countFor(Technique.nakedSingle), 1);
      expect(await progression.playerRank(), Rank.sheriff);
    });

    test('does not wait for the completion cascade', () async {
      // Nothing is pumped here: no timer is advanced and no animation frame is
      // produced. A **cascade** runs 520ms and the puzzle-completion sequence
      // longer still (D-47), so a record that waited for either could not be
      // readable yet. Constraint 2 cuts both ways — the effect must not delay
      // the write any more than the write may delay the effect.
      final controller = _controllerFor(db, Rank.deputy);
      addTearDown(controller.dispose);

      await _solve(controller);

      expect(await packs.isSolved('fixture-deputy'), isTrue);
    });

    test('counts once however many times the board is completed', () async {
      final controller = _controllerFor(db, Rank.marshal);
      addTearDown(controller.dispose);

      await _solve(controller);
      // Erase the last cell and put it back: the board is completed a second
      // time, by the route a real player would take.
      final last = <int>[
        for (var cell = 0; cell < 81; cell++)
          if (_clues[cell] == '.') cell,
      ].last;
      controller.tapCell(last);
      controller.tapKey(const EraseKey());
      controller.tapKey(DigitKey(int.parse(_solution[last])));
      await Future<void>.delayed(Duration.zero);

      expect((await stats.lifetime()).puzzlesSolved, 1);
      expect(await stats.countFor(Technique.nakedSingle), 1);
    });
  });

  group('a puzzle that was not finished', () {
    test('an unfinished board records nothing', () async {
      final controller = _controllerFor(db, Rank.ranger);
      addTearDown(controller.dispose);

      await _solve(controller, short: 1);

      expect(controller.isSolved, isFalse);
      expect(await packs.isSolved('fixture-ranger'), isFalse);
      expect((await stats.lifetime()).puzzlesSolved, 0);
      expect(await progression.playerRank(), Rank.greenhorn);
      expect(await progression.unlockedTechniques(), isEmpty);
    });

    test(
      'a full board that disagrees with the solution records nothing',
      () async {
        // The board is complete but wrong. Nothing here tells the player so —
        // auto-check is off by default (constraint 1) — and nothing records a
        // solve either.
        final controller = _controllerFor(db, Rank.legend);
        addTearDown(controller.dispose);

        final empty = <int>[
          for (var cell = 0; cell < 81; cell++)
            if (_clues[cell] == '.') cell,
        ];
        for (final cell in empty) {
          final right = int.parse(_solution[cell]);
          controller.tapCell(cell);
          controller.tapKey(
            DigitKey(cell == empty.last ? (right % 9) + 1 : right),
          );
        }
        await Future<void>.delayed(Duration.zero);

        expect(controller.isSolved, isFalse);
        expect(await packs.isSolved('fixture-legend'), isFalse);
        expect((await stats.lifetime()).puzzlesSolved, 0);
        expect(await progression.playerRank(), Rank.greenhorn);
      },
    );
  });

  group('grading never sits on the input path', () {
    test('the controller cannot grade — it does not import the grader', () {
      // Structural, because the cost is structural: `grade` is a full solver
      // run, and constraint 2's budget has no room for one on a tap. Holding
      // the technique set from the open is what keeps it off, and an import
      // here is how that would quietly be undone.
      final controller = File(
        'lib/features/grid_input/application/puzzle_controller.dart',
      );
      expect(controller.existsSync(), isTrue);
      final imports = controller
          .readAsLinesSync()
          .map((line) => line.trim())
          .where((line) => line.startsWith('import '));
      expect(
        imports.where((line) => line.contains('grader.dart')),
        isEmpty,
        reason: 'grading moved onto the input path',
      );
    });

    test('the board and the session do not import the grader', () {
      final offenders = <String>[];
      for (final dir in const <String>[
        'lib/features/grid_input/domain',
        'lib/features/completion_effects/domain',
      ]) {
        for (final entity in Directory(dir).listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          for (final line in entity.readAsLinesSync()) {
            if (line.trim().startsWith('import ') &&
                line.contains('grader.dart')) {
              offenders.add(entity.path);
            }
          }
        }
      }
      expect(offenders, isEmpty);
    });

    test(
      'placing, erasing and undoing leave the technique set alone',
      () async {
        final controller = _controllerFor(db, Rank.deputy);
        addTearDown(controller.dispose);

        const before = <Technique>{Technique.nakedSingle};
        expect(controller.techniquesRequired, before);

        controller.tapCell(2);
        controller.tapKey(const DigitKey(4));
        controller.tapKey(const EraseKey());
        controller.tapKey(const UndoKey());
        await Future<void>.delayed(Duration.zero);

        expect(controller.techniquesRequired, before);
      },
    );
  });

  group('the record survives an app kill', () {
    test('it is on disk before the app could be taken away', () async {
      final dir = Directory.systemTemp.createTempSync('doku_solve_record');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/app.sqlite');

      final first = AppDatabase(NativeDatabase(file));
      await installFixturePack(PackRepository(first));
      final controller = PuzzleController(
        puzzle: fixturePuzzle('fixture-ranger', Rank.ranger),
        sink: RepositoryBoardSink(
          PuzzleSaveRepository(first),
          NoteRepository(first),
          ProgressionRepository(first),
        ),
        techniquesRequired: const <Technique>{Technique.xWing},
        initial: sessionFor(
          puzzle: fixturePuzzle('fixture-ranger', Rank.ranger),
          placedValues: null,
          mode: InputMode.cellFirst,
        ),
      );
      await _solve(controller);
      controller.dispose();
      // No graceful shutdown beyond closing the handle: whatever is not
      // committed by now is what a killed process would lose.
      await first.close();

      final second = AppDatabase(NativeDatabase(file));
      addTearDown(second.close);
      final reopened = ProgressionRepository(second);

      expect(await PackRepository(second).isSolved('fixture-ranger'), isTrue);
      expect((await StatisticsRepository(second).lifetime()).puzzlesSolved, 1);
      expect(await reopened.playerRank(), Rank.ranger);
      expect(await reopened.unlockedTechniques(), <Technique>{Technique.xWing});
    });
  });
}
