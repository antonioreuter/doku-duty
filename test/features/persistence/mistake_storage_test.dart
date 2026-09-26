import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';
import 'package:doku_duty/features/grid_input/application/grid_providers.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_controller.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart'
    hide Pack;
import 'package:doku_duty/features/persistence/data/note_repository.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/data/puzzle_save_repository.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/puzzle_engine/data/pack_source.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/pack.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';
const String _puzzleId = 'q-greenhorn';

Grid _gridOf(String source) => (Grid.parse(source) as ValidGrid).grid;

const _puzzle = StoredPuzzle(
  id: _puzzleId,
  clues: _clues,
  solution: _solution,
  rank: Rank.greenhorn,
  seed: 1,
);

/// A one-puzzle **pack**, so the opening provider has a row to find.
final class _FakePackSource implements PackSource {
  @override
  Future<PackParseResult> read() async => Pack.parse(
    Pack(
      packId: 'frontier-1',
      version: 1,
      puzzles: <PackPuzzle>[
        PackPuzzle(
          id: _puzzleId,
          clues: _clues,
          solution: _solution,
          rank: Rank.greenhorn,
          seed: 1,
        ),
      ],
    ).encode(),
  );
}

/// Counts writes while they go to the real database underneath.
final class _CountingSink implements BoardSink {
  _CountingSink(this._inner);

  final RepositoryBoardSink _inner;
  int boardWrites = 0;
  final List<int> talliesWritten = <int>[];

  @override
  Future<void> write(String puzzleId, Board board, {required int mistakes}) {
    boardWrites++;
    talliesWritten.add(mistakes);
    return _inner.write(puzzleId, board, mistakes: mistakes);
  }

  @override
  Future<void> writeNotes(String puzzleId, Map<int, NoteSet> byCell) =>
      throw UnimplementedError();

  @override
  Future<int> complete(
    String puzzleId, {
    Set<Technique> techniquesRequired = const <Technique>{},
    Attempt attempt = Attempt.fresh,
  }) => _inner.complete(
    puzzleId,
    techniquesRequired: techniquesRequired,
    attempt: attempt,
  );
}

void main() {
  late AppDatabase db;
  late PuzzleSaveRepository saves;
  late RepositoryBoardSink sink;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    saves = PuzzleSaveRepository(db);
    sink = RepositoryBoardSink(
      saves,
      NoteRepository(db),
      ProgressionRepository(db),
    );
  });
  tearDown(() => db.close());

  PuzzleController controller({BoardSink? boardSink, int mistakes = 0}) =>
      PuzzleController(
        puzzle: _puzzle,
        sink: boardSink ?? sink,
        initial: PuzzleSession.start(
          board: Board.forPuzzle(givens: _gridOf(_clues)),
          solution: _gridOf(_solution),
          attempt: Attempt(mistakes: mistakes),
        ),
      );

  Future<int?> storedTally() async {
    final all = await saves.all();
    return all
        .where((save) => save.puzzleId == _puzzleId)
        .firstOrNull
        ?.mistakes;
  }

  // Constraint 9. A tally that reset on an app kill would be a silent
  // undercount with no symptom — and in **strict mode** it would hand the
  // player back an attempt they had already lost.
  group('the count is written with the placement that changed it', () {
    test('a wrong placement reaches the save row', () async {
      // Cell 2's solution is 4, so a 7 is wrong.
      final c = controller();
      c.tapCell(2);
      c.tapKey(const DigitKey(7));
      await pumpEventQueue();

      expect(await storedTally(), 1);
    });

    test('a right placement writes the tally it already had', () async {
      final c = controller(mistakes: 2);
      c.tapCell(2);
      c.tapKey(const DigitKey(4));
      await pumpEventQueue();

      expect(await storedTally(), 2);
    });

    test('every mistake updates the row', () async {
      final c = controller();
      for (final (cell, digit) in const <(int, int)>[(2, 9), (3, 9), (5, 9)]) {
        c.tapCell(cell);
        c.tapKey(DigitKey(digit));
        await pumpEventQueue();
      }

      expect(await storedTally(), 3);
    });

    test('the board and the tally are written together', () async {
      final counting = _CountingSink(sink);
      final c = controller(boardSink: counting);
      c.tapCell(2);
      c.tapKey(const DigitKey(7));
      await pumpEventQueue();

      expect(counting.boardWrites, 1);
      expect(counting.talliesWritten, <int>[1]);
    });
  });

  // Constraint 2: the frame the player is waiting for never waits on the
  // database.
  test('the digit is on screen before the write starts', () async {
    final counting = _CountingSink(sink);
    final c = controller(boardSink: counting);

    var digitWhenPublished = Board.empty;
    var writesWhenPublished = -1;
    c.addListener(() {
      digitWhenPublished = c.state.board.digitAt(2);
      writesWhenPublished = counting.boardWrites;
    });

    c.tapCell(2);
    c.tapKey(const DigitKey(7));

    expect(digitWhenPublished, 7);
    expect(writesWhenPublished, 0, reason: 'no write had started');

    await pumpEventQueue();
    expect(counting.boardWrites, 1);
  });

  test('the next tap is accepted while the write is in flight', () async {
    final c = controller();
    c.tapCell(2);
    c.tapKey(const DigitKey(7));
    // No await: the second tap lands on the frame after the first.
    c.tapCell(3);
    c.tapKey(const DigitKey(9));

    expect(c.state.board.digitAt(3), 9);
    expect(c.state.attempt.mistakes, 2);

    await pumpEventQueue();
    expect(await storedTally(), 2);
  });

  group('a resumed puzzle carries its tally', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          packSourceProvider.overrideWithValue(_FakePackSource()),
        ],
      );
      addTearDown(container.dispose);
    });

    test('two into an attempt is still two into it', () async {
      await sink.write(
        _puzzleId,
        Board.forPuzzle(givens: _gridOf(_clues)),
        mistakes: 2,
      );

      final opening = await container.read(
        puzzleOpeningProvider(_puzzleId).future,
      );

      expect(opening!.mistakes, 2);
    });

    test('a save with no tally reopens at zero', () async {
      await saves.save(
        puzzleId: _puzzleId,
        placedValues: const <int, int>{},
        elapsed: Duration.zero,
      );

      final opening = await container.read(
        puzzleOpeningProvider(_puzzleId).future,
      );

      expect(opening!.mistakes, 0);
    });

    test('the session opens on the tally it was handed', () async {
      final session = sessionFor(
        puzzle: _puzzle,
        placedValues: null,
        mode: InputMode.cellFirst,
        mistakes: 2,
        isStrict: true,
      );

      expect(session.attempt.mistakes, 2);
      expect(session.mistakesRemaining, 1);
      expect(session.isOver, isFalse);
    });

    test('a resumed attempt that was already lost is still lost', () async {
      final session = sessionFor(
        puzzle: _puzzle,
        placedValues: null,
        mode: InputMode.cellFirst,
        mistakes: Attempt.strictLimit,
        isStrict: true,
      );

      expect(session.isOver, isTrue);
    });
  });
}
