import 'package:doku_duty/features/daily_challenge/domain/daily_board_source.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_resolver.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_schedule.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:flutter_test/flutter_test.dart';

/// A board is one row of a **pack**, as far as this capability cares.
class _Board implements DailyBoard {
  const _Board(this.id, this.rank, {this.isKiller = false});

  @override
  final String id;
  @override
  final Rank rank;
  @override
  String get clues => '0' * 81;
  @override
  String get solution => '1' * 81;
  @override
  final bool isKiller;
}

/// A stand-in **pack**, recording what was asked of it.
///
/// It has no generator and no grader to call, which is how the "nothing is
/// generated on the device" requirement is asserted rather than assumed: there
/// is no route from here to one.
class _FakeSource implements DailyBoardSource {
  _FakeSource(this.boards);

  final List<_Board> boards;
  final List<String> asked = <String>[];

  @override
  Future<DailyBoard?> byId(String id) async {
    asked.add('byId:$id');
    for (final b in boards) {
      if (b.id == id) return b;
    }
    return null;
  }

  @override
  Future<DailyBoard?> byRankAndSeed(Rank rank, int seed) async {
    asked.add('bySeed:${rank.name}:$seed');
    // Classic only, as the contract says and the real source does.
    final atRank = boards.where((b) => b.rank == rank && !b.isKiller).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (atRank.isEmpty) return null;
    return atRank[seed % atRank.length];
  }
}

List<_Board> _fullPack() => <_Board>[
  for (final rank in Rank.values)
    for (var i = 0; i < 5; i++) _Board('${rank.name}-$i', rank),
];

void main() {
  final date = DailyDate(2026, 3, 16); // A Monday — Greenhorn on the ramp.

  group('the schedule names an installed puzzle', () {
    test('that puzzle is the board', () async {
      final source = _FakeSource(
        _fullPack()..add(const _Board('q-042', Rank.sheriff)),
      );
      final resolver = DailyResolver(
        schedule: DailySchedule(entries: {date: 'q-042'}),
        source: source,
      );

      final board = await resolver.boardFor(date);

      expect(board!.id, 'q-042');
      expect(source.asked, contains('byId:q-042'));
    });
  });

  group('the schedule names a puzzle that is not installed', () {
    test('it falls back to the derived board rather than failing', () async {
      final source = _FakeSource(_fullPack());
      final resolver = DailyResolver(
        schedule: DailySchedule(entries: {date: 'q-not-installed'}),
        source: source,
      );

      final board = await resolver.boardFor(date);

      expect(board, isNotNull, reason: 'the player was left with no daily');
      expect(board!.rank, Rank.greenhorn);
      expect(source.asked.first, 'byId:q-not-installed');
    });
  });

  // D-127: the **daily challenge** is always classic. A publish naming a
  // **killer** puzzle is a mistake in the schedule, and it is refused exactly
  // as one naming an uninstalled puzzle is — by falling through, not failing.
  group('the schedule names a killer puzzle', () {
    test(
      'it is refused, and the date falls back to its derived board',
      () async {
        final source = _FakeSource(
          _fullPack()
            ..add(const _Board('k-042', Rank.greenhorn, isKiller: true)),
        );
        final resolver = DailyResolver(
          schedule: DailySchedule(entries: {date: 'k-042'}),
          source: source,
        );

        final board = await resolver.boardFor(date);

        expect(board, isNotNull);
        expect(board!.id, isNot('k-042'));
        expect(board.isKiller, isFalse);
        expect(board.rank, Rank.greenhorn);
        expect(source.asked.first, 'byId:k-042');
      },
    );

    test('the fallback is the same board an unknown id gets', () async {
      Future<String?> boardId(String named) async => (await DailyResolver(
        schedule: DailySchedule(entries: {date: named}),
        source: _FakeSource(
          _fullPack()
            ..add(const _Board('k-042', Rank.greenhorn, isKiller: true)),
        ),
      ).boardFor(date))?.id;

      expect(await boardId('k-042'), await boardId('q-not-installed'));
    });
  });

  group('the derived board', () {
    test('it follows the weekly ramp', () async {
      final resolver = DailyResolver(
        schedule: DailySchedule.empty(),
        source: _FakeSource(_fullPack()),
      );

      expect(
        (await resolver.boardFor(DailyDate(2026, 3, 16)))!.rank,
        Rank.greenhorn,
      );
      expect(
        (await resolver.boardFor(DailyDate(2026, 3, 22)))!.rank,
        Rank.legend,
      );
    });

    test('the same date and the same pack always give the same board', () async {
      // Task 2.5's claim. Two resolvers built separately stand in for two runs
      // of the process: nothing about the board may come from when it was
      // asked, only from the date and what is installed.
      final first = DailyResolver(
        schedule: DailySchedule.empty(),
        source: _FakeSource(_fullPack()),
      );
      final second = DailyResolver(
        schedule: DailySchedule.empty(),
        source: _FakeSource(_fullPack()),
      );

      for (var day = 1; day <= 31; day++) {
        final d = DailyDate(2026, 3, day);
        expect((await first.boardFor(d))!.id, (await second.boardFor(d))!.id);
      }
    });

    test(
      'a different pack may give a different board, and that is the deal',
      () async {
        // D-115 states the cost plainly, so a test states it too: past the
        // schedule, two players with different packs can diverge. What must not
        // happen is either of them getting nothing.
        final small = DailyResolver(
          schedule: DailySchedule.empty(),
          source: _FakeSource(<_Board>[const _Board('a', Rank.greenhorn)]),
        );
        final large = DailyResolver(
          schedule: DailySchedule.empty(),
          source: _FakeSource(_fullPack()),
        );

        expect(await small.boardFor(date), isNotNull);
        expect(await large.boardFor(date), isNotNull);
      },
    );
  });

  group('the pack cannot supply the ramp rank', () {
    test(
      'it widens to the nearest rank rather than offering nothing',
      () async {
        // Constraint 1: running out is an absence, never a wall. A pack with no
        // Greenhorn puzzles must still produce a Monday daily.
        final source = _FakeSource(<_Board>[
          const _Board('m-0', Rank.marshal),
          const _Board('m-1', Rank.marshal),
        ]);
        final resolver = DailyResolver(
          schedule: DailySchedule.empty(),
          source: source,
        );

        final board = await resolver.boardFor(date);

        expect(board, isNotNull);
        expect(board!.rank, Rank.marshal);
      },
    );

    test('an empty pack is the one case with no board', () async {
      // Nothing installed at all is a different failure — there is no puzzle
      // in the app to offer — and it is reported as an absence, not a crash.
      final resolver = DailyResolver(
        schedule: DailySchedule.empty(),
        source: _FakeSource(<_Board>[]),
      );

      expect(await resolver.boardFor(date), isNull);
    });
  });

  group('nothing is generated on the device', () {
    test('every board comes back carrying its solution and its rank', () async {
      final resolver = DailyResolver(
        schedule: DailySchedule.empty(),
        source: _FakeSource(_fullPack()),
      );

      for (var day = 1; day <= 31; day++) {
        final board = (await resolver.boardFor(DailyDate(2026, 3, day)))!;
        expect(board.solution.length, 81);
        expect(board.clues.length, 81);
        expect(Rank.values, contains(board.rank));
      }
    });

    test('the resolver only ever reads, never builds', () async {
      final source = _FakeSource(_fullPack());
      final resolver = DailyResolver(
        schedule: DailySchedule.empty(),
        source: source,
      );

      await resolver.boardFor(date);

      // Every call is a lookup. `DailyBoardSource` has no route to the
      // generator or the grader, which is the structural half of constraint 8
      // — the test names it so the interface is not widened later (D-32).
      expect(
        source.asked.every(
          (a) => a.startsWith('byId:') || a.startsWith('bySeed:'),
        ),
        isTrue,
      );
    });
  });
}
