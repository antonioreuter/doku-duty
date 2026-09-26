import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/grid_input/application/grid_providers.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_controller.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';

import '../../persistence/support/fixture_pack.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// The app's own wiring over an in-memory database holding the fixture pack.
///
/// **The sink is the production `boardSinkProvider`, never one built by hand.**
/// Every hook `wire-completion-events` fixed had a passing test of its own; what
/// was missing was the line in the provider that called it. A test that
/// constructs its own sink cannot see that line.
class ProductionSolve {
  ProductionSolve._(this.db, this.container);

  final AppDatabase db;
  final ProviderContainer container;

  /// The **stamp**s the last [solve] reported to the screen, or null if it
  /// reported nothing.
  int? lastEarned;

  /// In memory, or on [file] where a test needs the platform's own SQLite to
  /// write to disk and read back.
  static Future<ProductionSolve> open({
    List<Override> overrides = const <Override>[],
    File? file,
  }) async {
    final db = AppDatabase(
      file == null ? NativeDatabase.memory() : NativeDatabase(file),
    );
    await installFixturePack(PackRepository(db));
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
        packInstallationProvider.overrideWith(
          (ref) async => PackInstallOutcome.alreadyInstalled,
        ),
        ...overrides,
      ],
    );
    return ProductionSolve._(db, container);
  }

  Future<void> close() async {
    container.dispose();
    await db.close();
  }

  /// Plays `fixture-<rank>` to the end through the production sink.
  ///
  /// Asserts the solve landed, unless [expectFailure] — then returns what the
  /// controller reported instead, for a test that injected the failure.
  Future<List<Object>> solve(Rank rank, {bool expectFailure = false}) async {
    final puzzle = fixturePuzzle('fixture-${rank.name}', rank);
    final errors = <Object>[];
    final controller = PuzzleController(
      puzzle: puzzle,
      sink: container.read(boardSinkProvider),
      techniquesRequired: const <Technique>{Technique.nakedSingle},
      initial: sessionFor(
        puzzle: puzzle,
        placedValues: null,
        mode: InputMode.cellFirst,
      ),
      // The controller routes a failed write away from the player (D-03), so
      // a test that does not collect it would pass over a rolled-back solve.
      onError: (error, _) => errors.add(error),
    );
    for (var cell = 0; cell < 81; cell++) {
      if (_clues[cell] != '.') continue;
      controller.tapCell(cell);
      controller.tapKey(DigitKey(int.parse(_solution[cell])));
    }
    // The writes are started unawaited so the frame never waits on them; the
    // completion is a chain of transactions, so give it real time to land.
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    lastEarned = controller.stampsEarned.value;
    controller.dispose();
    if (expectFailure) return errors;
    expect(errors, isEmpty);
    // Guards the reproduction: a test failing because the solve never landed
    // would look exactly like one failing for the bug it names.
    expect(await PackRepository(db).isSolved(puzzle.id), isTrue);
    return errors;
  }
}
