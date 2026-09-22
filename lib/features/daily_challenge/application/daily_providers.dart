import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../persistence/application/database_provider.dart';
import '../../persistence/data/app_database.dart';
import '../../persistence/data/pack_repository.dart';
import '../data/daily_repository.dart';
import '../domain/daily_board_source.dart';
import '../domain/daily_date.dart';
import '../domain/daily_resolver.dart';
import '../domain/daily_schedule.dart';
import 'daily_service.dart';

final dailyRepositoryProvider = Provider<DailyRepository>(
  (ref) => DailyRepository(ref.watch(appDatabaseProvider)),
);

/// A stored puzzle row, seen as a board.
///
/// The adapter exists so `domain/` never has to know Drift: [DailyBoard] is
/// four getters and the row already has all four.
class _PackBoard implements DailyBoard {
  const _PackBoard(this._puzzle);

  final Puzzle _puzzle;

  @override
  String get id => _puzzle.id;
  @override
  Rank get rank => _puzzle.rank;
  @override
  String get clues => _puzzle.clues;
  @override
  String get solution => _puzzle.solution;
}

class _PackBoardSource implements DailyBoardSource {
  const _PackBoardSource(this._packs);

  final PackRepository _packs;

  @override
  Future<DailyBoard?> byId(String id) async {
    final puzzle = await _packs.puzzleById(id);
    return puzzle == null ? null : _PackBoard(puzzle);
  }

  @override
  Future<DailyBoard?> byRankAndSeed(Rank rank, int seed) async {
    final puzzle = await _packs.puzzleByRankAndSeed(rank, seed);
    return puzzle == null ? null : _PackBoard(puzzle);
  }
}

final dailyBoardSourceProvider = Provider<DailyBoardSource>(
  (ref) => _PackBoardSource(PackRepository(ref.watch(appDatabaseProvider))),
);

/// The published schedule.
///
/// Empty until a document is published, and that is a working state rather than
/// a degraded one: every date still resolves, through the derived board
/// (D-115). `add-daily-challenge` ships no compiled-in run — the shape is here
/// and the first publish fills it, which is the same way the **season**
/// document works.
final dailyScheduleProvider = Provider<DailySchedule>(
  (ref) => DailySchedule.empty(),
);

/// The clock the **daily challenge** trusts.
///
/// Offset is null until a sync has reported one, so every day recorded before
/// then is marked unverified — the ordinary offline case, not a suspicion
/// (`docs/TECH_STACK.md` §3b). `add-cloud-sync` (29) supplies the offset; until
/// it exists the field is honestly null rather than a zero pretending to be
/// authoritative.
final dailyClockProvider = Provider<DailyClock>(
  (ref) => DailyClock(offset: null),
);

final dailyResolverProvider = Provider<DailyResolver>(
  (ref) => DailyResolver(
    schedule: ref.watch(dailyScheduleProvider),
    source: ref.watch(dailyBoardSourceProvider),
  ),
);

final dailyServiceProvider = Provider<DailyService>(
  (ref) => DailyService(
    repository: ref.watch(dailyRepositoryProvider),
    resolver: ref.watch(dailyResolverProvider),
    clock: ref.watch(dailyClockProvider),
  ),
);

/// Where the player stands today.
///
/// Reading it settles any absence, so a **streak freeze** is spent on the way
/// in rather than by a background process there is no room for (D-20).
final dailyStatusProvider = FutureProvider<DailyStatus>(
  (ref) => ref.watch(dailyServiceProvider).today(),
);
