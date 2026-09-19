import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/completion_effects/application/completion_settings.dart';
import 'package:doku_duty/features/completion_effects/domain/unit_completion.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/presentation/settings_screen.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/application/settings_providers.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/settings_repository.dart';
import 'package:doku_duty/features/persistence/domain/app_setting.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Grid _grid(String source) => (Grid.parse(source) as ValidGrid).grid;

void main() {
  // The persisted notifiers read the platform view, which needs a binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
  });
  tearDown(() => db.close());

  group('what a new player gets', () {
    // The tints are the default behaviour, so the setting that departs from it
    // is the one that is off — the same shape as every other row in the app.
    test('the hide switch is off, so the tints are drawn', () async {
      expect(await settings.read(AppSetting.hideCompletionTints), isFalse);
      expect(AppSetting.hideCompletionTints.defaultValue, isFalse);
    });

    test('every stored setting is still off by default', () async {
      for (final setting in AppSetting.values) {
        expect(
          setting.defaultValue,
          isFalse,
          reason: '${setting.name} would be the first row that ships on',
        );
      }
    });

    testWidgets('the row says what it does, and what it leaves alone', (
      tester,
    ) async {
      final row = SettingsScreen.rows[AppSetting.hideCompletionTints]!;

      expect(row.live, isTrue, reason: 'a row that lies is worse than no row');
      expect(
        row.detail.toLowerCase(),
        contains('corner marks stay'),
        reason: 'the player has to know the signal survives the tint',
      );
    });
  });

  group('the switch is stored and takes effect at once', () {
    testWidgets('turning it on publishes and persists it', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          persistedHideCompletionTintsOverride,
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(hideCompletionTintsProvider), isFalse);

      final notifier = container.read(hideCompletionTintsProvider.notifier);
      notifier.set(true);

      expect(
        container.read(hideCompletionTintsProvider),
        isTrue,
        reason:
            'a puzzle already on screen must see the change now, not on '
            'the next launch',
      );
      await (notifier as PersistedHideCompletionTints).lastWrite;
      expect(await settings.read(AppSetting.hideCompletionTints), isTrue);
    });

    testWidgets('a stored choice arrives after the first frame', (
      tester,
    ) async {
      await settings.write(AppSetting.hideCompletionTints, value: true);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          persistedHideCompletionTintsOverride,
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(hideCompletionTintsProvider),
        isFalse,
        reason:
            'the default is returned synchronously — no disk read on the '
            'cold-start path (D-85)',
      );
      final notifier =
          container.read(hideCompletionTintsProvider.notifier)
              as PersistedHideCompletionTints;
      await notifier.hydrated;
      expect(container.read(hideCompletionTintsProvider), isTrue);
    });
  });

  group('a reopened puzzle', () {
    // The tint is derived from the board, so there is nothing to restore and
    // nothing that can come back wrong.
    test('shows its tints from the board it restored', () {
      const clues =
          '53..7....6..195....98....6.8...6...34..8.3..17...2...6.'
          '6....28....419..5....8..79';
      final givens = _grid(clues);

      // Fill row 0 exactly as the save would have left it.
      var played = Board.forPuzzle(givens: givens);
      for (final cell in GridGeometry.unitsOfKind(UnitKind.row)[0].cells) {
        if (played.isGiven(cell)) continue;
        played =
            (played.place(cell, _grid(_solution).digitAt(cell)) as EditApplied)
                .board;
      }

      final reopened = Board.restore(
        givens: givens,
        placedValues: played.toPlacedValues(),
      );

      expect(
        UnitCompletion.tintedCells(reopened),
        UnitCompletion.tintedCells(played),
        reason:
            'the same board yields the same tints — nothing was stored, so '
            'nothing could be lost',
      );
      expect(UnitCompletion.tintedCells(reopened), isNotEmpty);
    });

    test('announces nothing, because opening is not a placement', () {
      const clues =
          '53..7....6..195....98....6.8...6...34..8.3..17...2...6.'
          '6....28....419..5....8..79';
      final givens = _grid(clues);
      var played = Board.forPuzzle(givens: givens);
      for (final cell in GridGeometry.unitsOfKind(UnitKind.row)[0].cells) {
        if (played.isGiven(cell)) continue;
        played =
            (played.place(cell, _grid(_solution).digitAt(cell)) as EditApplied)
                .board;
      }

      final reopened = Board.restore(
        givens: givens,
        placedValues: played.toPlacedValues(),
      );

      // `forChange` compares two boards. A reopened board is compared with
      // itself — nothing changed, so nothing completed and no celebration is
      // owed. The fresh state belongs to the placement, not to the save.
      for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
        expect(
          UnitCompletion.forChange(
            before: reopened,
            after: reopened,
            cell: cell,
          ).isEmpty,
          isTrue,
        );
      }
    });
  });
}
