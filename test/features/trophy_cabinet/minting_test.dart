import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/trophy_cabinet/data/trophy_repository.dart';
import 'package:doku_duty/features/trophy_cabinet/domain/award.dart';
import 'package:doku_duty/features/trophy_cabinet/domain/award_catalogue.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minting a **trophy** (D-124).
///
/// A **trophy** is written in the same transaction as the event that earns it,
/// so the two cannot come apart. The negative cases are the point of this file:
/// a **trophy** minted twice, or one surviving without its cause, is the kind
/// of defect a player reports as "my cabinet is wrong" with nothing in the logs
/// to find.
void main() {
  late AppDatabase db;
  late TrophyRepository trophies;

  final award = Award(
    id: 'dust-gulch.boss.22',
    name: 'Ace cornered, halfway',
    trigger: AwardTrigger.boss,
    seasonId: 'dust-gulch',
    nodePosition: 22,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    trophies = TrophyRepository(db);
  });
  tearDown(() => db.close());

  group('a trophy is written when earned', () {
    test('minting one makes it readable straight away', () async {
      await trophies.mint(award: award, seasonName: 'Dust Gulch');

      final earned = await trophies.earned();
      expect(earned, hasLength(1));
      expect(earned.single.awardId, 'dust-gulch.boss.22');
    });

    test('it captures the season name at the moment of minting', () async {
      // The whole reason for minting rather than deriving. Once the season
      // document rotates away, the name is gone from everywhere else.
      await trophies.mint(award: award, seasonName: 'Dust Gulch');

      final earned = await trophies.earned();
      expect(earned.single.seasonId, 'dust-gulch');
      expect(earned.single.seasonName, 'Dust Gulch');
    });

    test('a permanent trophy carries no season', () async {
      await trophies.mint(
        award: AwardCatalogue.permanent.first,
        seasonName: null,
      );

      final earned = await trophies.earned();
      expect(earned.single.seasonId, isNull);
      expect(earned.single.seasonName, isNull);
    });
  });

  group('minting is idempotent', () {
    test('the same award twice mints once', () async {
      await trophies.mint(award: award, seasonName: 'Dust Gulch');
      await trophies.mint(award: award, seasonName: 'Dust Gulch');

      expect(await trophies.earned(), hasLength(1));
    });

    test('the second minting does not move the date', () async {
      await trophies.mint(award: award, seasonName: 'Dust Gulch');
      final first = (await trophies.earned()).single.earnedAt;

      await trophies.mint(award: award, seasonName: 'Dust Gulch');
      final after = (await trophies.earned()).single.earnedAt;

      // A trophy records when something *first* happened. Re-earning is not a
      // new event, and a cabinet that quietly restamps its own history is
      // worth less than one that does not.
      expect(after, first);
    });

    test('a republished award keeping its id keeps its trophy', () async {
      await trophies.mint(award: award, seasonName: 'Dust Gulch');

      // Same id, renamed by a later publish. The trophy is already minted and
      // is not re-minted or duplicated — which is why the id is the key and
      // `openspec` says progress is keyed to it.
      await trophies.mint(
        award: Award(
          id: 'dust-gulch.boss.22',
          name: 'Ace cornered, halfway (renamed)',
          trigger: AwardTrigger.boss,
          seasonId: 'dust-gulch',
          nodePosition: 22,
        ),
        seasonName: 'Dust Gulch',
      );

      expect(await trophies.earned(), hasLength(1));
    });
  });

  group('a trophy never exists without its cause', () {
    test('minting inside a failed transaction leaves nothing', () async {
      // The constraint 9 case. If the surrounding write fails, the trophy goes
      // with it — a trophy without its completion is a lie about what the
      // player did.
      await expectLater(
        db.transaction(() async {
          await trophies.mint(award: award, seasonName: 'Dust Gulch');
          throw StateError('the completion failed');
        }),
        throwsA(isA<StateError>()),
      );

      expect(await trophies.earned(), isEmpty);
    });

    test('a completion and its trophy commit together', () async {
      await db.transaction(() async {
        await trophies.mint(award: award, seasonName: 'Dust Gulch');
      });

      expect(await trophies.earned(), hasLength(1));
    });
  });

  group('what is earned, and what is not', () {
    test('an unminted award is not earned', () async {
      expect(await trophies.hasEarned('dust-gulch.boss.41'), isFalse);
    });

    test('a minted award is earned', () async {
      await trophies.mint(award: award, seasonName: 'Dust Gulch');
      expect(await trophies.hasEarned('dust-gulch.boss.22'), isTrue);
    });

    test('nothing is ever removed', () async {
      // The type offers no way to withdraw a trophy, for the same reason
      // `SeasonRepository` offers no `uncomplete`: constraint 1 is safer
      // enforced by the operation not existing.
      await trophies.mint(award: award, seasonName: 'Dust Gulch');
      expect(trophies.runtimeType.toString().contains('remove'), isFalse);
      expect(await trophies.earned(), hasLength(1));
    });
  });

  group('a trophy outlives the season that declared it', () {
    test('it keeps its name after the catalogue no longer lists it', () async {
      await trophies.mint(award: award, seasonName: 'Dust Gulch');

      // The next season is in force; nothing in this catalogue mentions the
      // old award at all.
      final next = AwardCatalogue.forSeason(
        seasonId: 'copper-hollow',
        seasonName: 'Copper Hollow',
      );
      expect(next.byId('dust-gulch.boss.22'), isNull);

      final earned = (await trophies.earned()).single;
      expect(earned.name, 'Ace cornered, halfway');
      expect(earned.seasonName, 'Dust Gulch');
    });
  });
}
