import 'package:doku_duty/features/trophy_cabinet/domain/award.dart';
import 'package:doku_duty/features/trophy_cabinet/domain/award_catalogue.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the **cabinet** offers, before anyone has earned any of it.
///
/// D-21 needs an unearned **award** to be *shown*, which means the list has to
/// exist independently of the player. These tests are that list's contract.
void main() {
  group('a published season declares its own', () {
    test('a well-formed list is read', () {
      final awards = Award.listFromJson(<Object?>[
        <String, Object?>{
          'id': 'copper.boss.22',
          'name': 'The assayer, cornered',
          'trigger': 'boss',
          'node_position': 22,
        },
        <String, Object?>{
          'id': 'copper.closed',
          'name': 'Copper Hollow, closed',
          'trigger': 'season_complete',
        },
      ], seasonId: 'copper-hollow');

      expect(awards, hasLength(2));
      expect(awards.first.name, 'The assayer, cornered');
      expect(awards.first.nodePosition, 22);
      expect(awards.last.trigger, AwardTrigger.seasonComplete);
    });

    test('a season can award something this build never heard of', () {
      // The point of publishing rather than compiling in (D-125): a territory
      // gets a trophy of its own without a client release.
      final awards = Award.listFromJson(<Object?>[
        <String, Object?>{
          'id': 'copper.the-clock',
          'name': 'The town clock, rewound',
          'trigger': 'season_complete',
        },
      ], seasonId: 'copper-hollow');

      expect(awards.single.name, 'The town clock, rewound');
    });
  });

  group('what the client refuses', () {
    test('a malformed entry is refused and the others kept', () {
      final awards = Award.listFromJson(<Object?>[
        <String, Object?>{
          'id': 'good',
          'name': 'Kept',
          'trigger': 'boss',
          'node_position': 22,
        },
        'not an object',
        <String, Object?>{'name': 'No id', 'trigger': 'boss'},
        <String, Object?>{'id': 'no-name', 'trigger': 'boss'},
        <String, Object?>{'id': 'bad-trigger', 'name': 'x', 'trigger': 'shrug'},
      ], seasonId: 's');

      expect(awards, hasLength(1));
      expect(awards.single.id, 'good');
    });

    test('a boss award without a position is refused', () {
      // It could never be matched to the completion that earns it, so it would
      // sit unfiled for ever — worse than absent, because it reads as something
      // the player failed to get.
      final awards = Award.listFromJson(<Object?>[
        <String, Object?>{'id': 'b', 'name': 'Boss', 'trigger': 'boss'},
      ], seasonId: 's');

      expect(awards, isEmpty);
    });

    test('a list that is not a list yields none', () {
      expect(Award.listFromJson(null, seasonId: 's'), isEmpty);
      expect(Award.listFromJson('nope', seasonId: 's'), isEmpty);
      expect(Award.listFromJson(42, seasonId: 's'), isEmpty);
    });
  });

  group('the fallback keeps the cabinet whole', () {
    test('nothing published still populates the season', () {
      final catalogue = AwardCatalogue.forSeason(
        seasonId: 'dust-gulch',
        seasonName: 'Dust Gulch',
      );

      expect(catalogue.seasonal, isNotEmpty);
      expect(
        catalogue.seasonal.where((a) => a.trigger == AwardTrigger.boss),
        hasLength(2),
      );
      expect(
        catalogue.seasonal.any((a) => a.trigger == AwardTrigger.seasonComplete),
        isTrue,
      );
    });

    test('the fallback bosses sit where D-120 fixes them', () {
      final catalogue = AwardCatalogue.forSeason(
        seasonId: 'dust-gulch',
        seasonName: 'Dust Gulch',
      );

      final positions = catalogue.seasonal
          .where((a) => a.trigger == AwardTrigger.boss)
          .map((a) => a.nodePosition)
          .toSet();

      // 22 and 41, the layout the story adapts to rather than moves.
      expect(positions, <int>{22, 41});
    });

    test('a published list replaces the fallback rather than joining it', () {
      final catalogue = AwardCatalogue.forSeason(
        seasonId: 'copper-hollow',
        seasonName: 'Copper Hollow',
        published: Award.listFromJson(<Object?>[
          <String, Object?>{
            'id': 'copper.closed',
            'name': 'Copper Hollow, closed',
            'trigger': 'season_complete',
          },
        ], seasonId: 'copper-hollow'),
      );

      expect(catalogue.seasonal, hasLength(1));
      expect(catalogue.seasonal.single.id, 'copper.closed');
    });

    test('the season-complete award names the territory', () {
      // D-119 frames a season ending as the case closing. The name carries the
      // territory so a later change can draw it as one without re-deriving.
      final catalogue = AwardCatalogue.forSeason(
        seasonId: 'dust-gulch',
        seasonName: 'Dust Gulch',
      );

      final closed = catalogue.seasonal.firstWhere(
        (a) => a.trigger == AwardTrigger.seasonComplete,
      );
      expect(closed.name, contains('Dust Gulch'));
    });
  });

  group('permanent awards', () {
    test('they are present whatever is published', () {
      for (final published in <List<Award>>[
        const <Award>[],
        Award.listFromJson(<Object?>[
          <String, Object?>{
            'id': 'x',
            'name': 'X',
            'trigger': 'season_complete',
          },
        ], seasonId: 's'),
      ]) {
        final catalogue = AwardCatalogue.forSeason(
          seasonId: 's',
          seasonName: 'S',
          published: published,
        );
        expect(
          catalogue.awards.where((a) => a.isPermanent),
          isNotEmpty,
          reason: 'the permanent layer depended on a publish',
        );
      }
    });

    test('they belong to no season, so rotation cannot take them', () {
      for (final award in AwardCatalogue.permanent) {
        expect(award.seasonId, isNull);
        expect(award.isPermanent, isTrue);
      }
    });

    test('a rank award exists for every rank above the starting one', () {
      final ranks = AwardCatalogue.permanent
          .where((a) => a.trigger == AwardTrigger.rankReached)
          .map((a) => a.rankName)
          .toSet();

      // Greenhorn is where everyone begins, so there is nothing to mark.
      expect(ranks, <String>{'sheriff', 'marshal', 'ranger', 'legend'});
    });

    test('ids are unique, because progress is keyed to them', () {
      final catalogue = AwardCatalogue.forSeason(
        seasonId: 'dust-gulch',
        seasonName: 'Dust Gulch',
      );
      final ids = catalogue.awards.map((a) => a.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });
  });
}
