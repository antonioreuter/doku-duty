import 'dart:io';

import 'package:doku_duty/features/daily_challenge/application/daily_service.dart';
import 'package:doku_duty/features/daily_challenge/data/daily_repository.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_board_source.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_resolver.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_schedule.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/domain/sync_metadata.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// What this change deliberately does **not** do.
///
/// Four capabilities will each want something from a completed **daily
/// challenge**, and none of them exists yet. The completion signal is built now
/// so that none of them has to invent its own trigger — and these tests say, in
/// the place a future implementer will look, that the absence of minting,
/// filing, advertising and syncing is a decision rather than an oversight.
///
/// Each one should be **deleted** by the change that fills its seam, not
/// edited to expect the new behaviour. A test asserting "no **stamp** is
/// minted" surviving into `add-stamps` would block the feature it was written
/// to hand over.
class _Board implements DailyBoard {
  const _Board(this.id, this.rank);
  @override
  final String id;
  @override
  final Rank rank;
  @override
  String get clues => '.' * 81;
  @override
  String get solution => '1' * 81;
}

class _Source implements DailyBoardSource {
  @override
  Future<DailyBoard?> byId(String id) async => _Board(id, Rank.sheriff);
  @override
  Future<DailyBoard?> byRankAndSeed(Rank rank, int seed) async =>
      _Board('${rank.name}-$seed', rank);
}

void main() {
  late AppDatabase db;
  late DailyRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DailyRepository(db);
  });
  tearDown(() => db.close());

  DailyService serviceOn(DailyDate date) => DailyService(
    repository: repository,
    resolver: DailyResolver(schedule: DailySchedule.empty(), source: _Source()),
    clock: DailyClock(
      offset: Duration.zero,
      now: () => DateTime(date.year, date.month, date.day, 10),
    ),
  );

  group('the completion signal exists for others to read', () {
    test('it carries the date and whether a milestone was reached', () async {
      for (var day = 14; day <= 19; day++) {
        await repository.completeDay(
          DatedDay(date: DailyDate(2026, 3, day), isVerified: true),
        );
      }

      final completion = await serviceOn(DailyDate(2026, 3, 20)).complete();

      // Both facts D-66 prices are on it: the completion itself (2 **stamp**s)
      // and the seven-day milestone (10).
      expect(completion.date, DailyDate(2026, 3, 20));
      expect(completion.streak, 7);
      expect(completion.isStreakMilestone, isTrue);
    });
  });

  group('add-stamps (18) — nothing is minted', () {
    test('completing a daily mints no stamp', () async {
      await serviceOn(DailyDate(2026, 3, 20)).complete();

      // There is no **stamp** table and no balance to move. D-66 prices a
      // completed daily at 2 and a seven-day **streak** at 10, and `add-stamps`
      // owns the one place a **stamp** may be minted (constraint 10 — earned in
      // play only, never purchasable).
      final tables = db.allTables.map((t) => t.actualTableName).toList();
      expect(
        tables.any((t) => t.contains('stamp')),
        isFalse,
        reason: 'a stamp table appeared before add-stamps',
      );
    });
  });

  group('add-trophy-cabinet (16) — nothing is filed', () {
    test('a full month files no trophy', () async {
      for (var day = 1; day <= 31; day++) {
        await repository.completeDay(
          DatedDay(date: DailyDate(2026, 3, day), isVerified: true),
        );
      }

      final calendar = await repository.calendar();
      expect(calendar.completed, hasLength(31));

      // A perfect month is exactly what `docs/SPEC.md` §5.3 says unlocks a
      // cabinet trophy, and there is nowhere yet to put one.
      final tables = db.allTables.map((t) => t.actualTableName).toList();
      expect(
        tables.any((t) => t.contains('troph')),
        isFalse,
        reason: 'a trophy table appeared before add-trophy-cabinet',
      );
    });
  });

  group('add-ads-integration (24) — the daily never carries an ad', () {
    test('no advertising code is reachable from this capability', () {
      // The rule is D-24's and it is absolute: no interstitial on the **daily
      // challenge**, ever. Written as a structural check because change 24 will
      // add the placement logic, and the cheapest way for it to get this wrong
      // is to treat every completion alike.
      final offenders = <String>[];
      for (final entity in Directory(
        'lib/features/daily_challenge',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync().toLowerCase();
        for (final word in const <String>[
          'interstitial',
          'admob',
          'applovin',
          'rewarded',
        ]) {
          // The word appears in prose in this file's own comments, so only
          // imports and identifiers count.
          for (final line in source.split('\n')) {
            final trimmed = line.trim();
            if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
            if (trimmed.contains(word)) {
              offenders.add('${entity.path}: $trimmed');
            }
          }
        }
      }
      expect(offenders, isEmpty);
    });

    test('a completion advances no ad counter', () async {
      final completion = await serviceOn(DailyDate(2026, 3, 20)).complete();

      // The signal carries the date and the **streak** and nothing an ad
      // cadence could read. Change 24 counts *node* completions (D-24); this
      // is not one, and there is no field here for it to mistake for one.
      expect(completion.date, isNotNull);
      expect(completion.streak, 1);
    });
  });

  group('add-cloud-sync (29) — the shape is ready, nothing syncs', () {
    test('both tables are listed as syncable', () {
      expect(syncableTables, contains('completed_days'));
      expect(syncableTables, contains('streak_freeze_ledgers'));
    });

    test('no streak number is stored anywhere to conflict', () {
      // §3b's rule is union the days and recompute. The schema has no column
      // for the count, which is what makes that rule the only possible one —
      // there is nothing for two devices to disagree about.
      final columns = <String>[
        for (final table in db.allTables)
          for (final column in table.$columns) column.name,
      ];
      expect(
        columns.any((c) => c.contains('streak') && c != 'streak_freeze'),
        isFalse,
        reason: 'a streak column exists, so two devices can now disagree',
      );
    });

    test('a completed day is queued for upload, not uploaded', () async {
      await serviceOn(DailyDate(2026, 3, 20)).complete();

      final rows = await db.select(db.completedDays).get();
      expect(
        rows.single.pendingUpload,
        isTrue,
        reason: 'the row was not queued for a sync that does not exist yet',
      );
    });
  });
}
