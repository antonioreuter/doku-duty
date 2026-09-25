import 'package:doku_duty/features/daily_challenge/application/daily_service.dart';
import 'package:doku_duty/features/daily_challenge/data/daily_repository.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_board_source.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_resolver.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_schedule.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _Board implements DailyBoard {
  const _Board(this.id, this.rank);
  @override
  final String id;
  @override
  final Rank rank;
  @override
  String get clues => '0' * 81;
  @override
  String get solution => '1' * 81;
  @override
  bool get isKiller => false;
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
      offset: const Duration(seconds: 1),
      now: () => DateTime(date.year, date.month, date.day, 10),
    ),
  );

  group('the day is written before anything is celebrated', () {
    test(
      'the completion is on the calendar by the time it is returned',
      () async {
        final service = serviceOn(DailyDate(2026, 3, 20));

        final completion = await service.complete(
          DatedDay(date: DailyDate(2026, 3, 20), isVerified: true),
        );

        // The ordering this test exists for. When the caller has the completion
        // in hand — the thing it would show a celebration for — the row is
        // already in sqlite. Celebrating first and writing after loses the day
        // to an app kill during the animation, and the player has every reason
        // to believe it counted (constraint 9).
        expect(await repository.wasCompleted(completion.date), isTrue);
      },
    );

    test('the streak reported is the streak that was stored', () async {
      for (var day = 18; day <= 19; day++) {
        await repository.completeDay(
          DatedDay(date: DailyDate(2026, 3, day), isVerified: true),
        );
      }

      final completion = await serviceOn(
        DailyDate(2026, 3, 20),
      ).complete(DatedDay(date: DailyDate(2026, 3, 20), isVerified: true));
      final stored = (await repository.calendar()).streakOn(
        DailyDate(2026, 3, 20),
      );

      expect(completion.streak, 3);
      expect(completion.streak, stored);
    });

    test('a milestone is every seventh day', () async {
      for (var day = 14; day <= 19; day++) {
        await repository.completeDay(
          DatedDay(date: DailyDate(2026, 3, day), isVerified: true),
        );
      }

      final completion = await serviceOn(
        DailyDate(2026, 3, 20),
      ).complete(DatedDay(date: DailyDate(2026, 3, 20), isVerified: true));

      expect(completion.streak, 7);
      expect(completion.isStreakMilestone, isTrue);
    });

    test('an ordinary day is not a milestone', () async {
      final completion = await serviceOn(
        DailyDate(2026, 3, 20),
      ).complete(DatedDay(date: DailyDate(2026, 3, 20), isVerified: true));
      expect(completion.streak, 1);
      expect(completion.isStreakMilestone, isFalse);
    });
  });

  group('the day recorded is the one the board was opened for (D-132)', () {
    test('a daily opened before midnight credits that day', () async {
      // Opened on the 14th, solved after the clock has turned to the 15th.
      final completion = await serviceOn(
        DailyDate(2026, 3, 15),
      ).complete(DatedDay(date: DailyDate(2026, 3, 14), isVerified: false));

      expect(completion.date, DailyDate(2026, 3, 14));
      final calendar = await repository.calendar();
      expect(calendar.wasCompleted(DailyDate(2026, 3, 14)), isTrue);
      expect(calendar.wasCompleted(DailyDate(2026, 3, 15)), isFalse);
    });
  });

  group('opening the app settles an absence', () {
    test(
      'one missed day is frozen automatically, without being asked',
      () async {
        // There is no prompt in this flow and no method to accept one. The
        // freeze is spent on the way in (D-20).
        await repository.completeDay(
          DatedDay(date: DailyDate(2026, 3, 18), isVerified: true),
        );

        final status = await serviceOn(DailyDate(2026, 3, 20)).today();

        expect(status.calendar.wasFrozen(DailyDate(2026, 3, 19)), isTrue);
        expect(status.streak, 2, reason: 'the 18th and the frozen 19th');
        expect(status.freezeIsHeld, isFalse, reason: 'it was just spent');
      },
    );

    test('two missed days break the streak and spend nothing', () async {
      await repository.completeDay(
        DatedDay(date: DailyDate(2026, 3, 17), isVerified: true),
      );

      final status = await serviceOn(DailyDate(2026, 3, 20)).today();

      expect(status.streak, 0);
      expect(status.calendar.frozen, isEmpty);
      expect(
        status.freezeIsHeld,
        isTrue,
        reason: 'a freeze was spent on an absence it could not bridge',
      );
    });

    test('a long absence does not come back with a pile of freezes', () async {
      await repository.completeDay(
        DatedDay(date: DailyDate(2026, 1, 1), isVerified: true),
      );

      final status = await serviceOn(DailyDate(2026, 6, 1)).today();

      expect(status.streak, 0);
      expect(status.freezeIsHeld, isTrue);
      expect(status.calendar.frozen, isEmpty);
    });

    test('a brand new player settles nothing and holds one', () async {
      final status = await serviceOn(DailyDate(2026, 3, 20)).today();

      expect(status.streak, 0);
      expect(status.calendar.completed, isEmpty);
      expect(status.calendar.frozen, isEmpty);
      expect(status.freezeIsHeld, isTrue);
    });

    test('an unbroken player settles nothing', () async {
      await repository.completeDay(
        DatedDay(date: DailyDate(2026, 3, 19), isVerified: true),
      );

      final status = await serviceOn(DailyDate(2026, 3, 20)).today();

      expect(status.calendar.frozen, isEmpty);
      expect(status.freezeIsHeld, isTrue);
      expect(status.streak, 1);
    });

    test('settling twice in one day spends only one freeze', () async {
      await repository.completeDay(
        DatedDay(date: DailyDate(2026, 3, 18), isVerified: true),
      );

      final service = serviceOn(DailyDate(2026, 3, 20));
      await service.today();
      final second = await service.today();

      expect(second.calendar.frozen, hasLength(1));
    });
  });

  group('today', () {
    test('it offers a board', () async {
      final status = await serviceOn(DailyDate(2026, 3, 20)).today();
      expect(status.board, isNotNull);
    });

    test('a completed day is reported as completed', () async {
      final service = serviceOn(DailyDate(2026, 3, 20));
      await service.complete(
        DatedDay(date: DailyDate(2026, 3, 20), isVerified: true),
      );

      expect((await service.today()).isCompleted, isTrue);
    });
  });
}
