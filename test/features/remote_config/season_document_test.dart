import 'dart:convert';
import 'dart:io';

import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/remote_config/domain/config_value.dart';
import 'package:doku_duty/features/remote_config/domain/remote_config.dart';
import 'package:doku_duty/features/season_map/domain/node_type.dart';
import 'package:doku_duty/features/season_map/domain/season.dart';
import 'package:test/test.dart';

/// A **season** is published, not released.
///
/// The tests that matter here are the ones where the **season** is *bad*. A
/// good one arriving is visible the first time anyone looks at the trail; a bad
/// one taking the ad caps down with it, or blanking the map, would be visible
/// only to whoever was holding the phone.
void main() {
  final fixture = File(
    'test/features/remote_config/fixtures/config_with_season.json',
  ).readAsStringSync();

  /// A document carrying [season], or carrying no `season` key at all.
  ///
  /// The two are different cases and both matter: an absent key is the common,
  /// valid one, and a present-but-bad value is what the degradation tests bend.
  String withSeason(Object? season) {
    final document = <String, Object?>{
      'schema_version': 1,
      'ads.interstitials_per_session': 4,
    };
    if (season != null) document['season'] = season;
    return jsonEncode(document);
  }

  Map<String, Object?> fixtureSeason() =>
      (jsonDecode(fixture) as Map<String, Object?>)['season']!
          as Map<String, Object?>;

  group('a published season', () {
    test('the fixture parses and carries its season', () {
      final config = RemoteConfigParser.parse(fixture);
      expect(config, isNotNull);
      expect(config!.season, isNotNull);
      expect(config.season!.id, 'copper-hollow');
      expect(config.season!.name, 'Copper Hollow');
      expect(config.season!.nodes, hasLength(42));
    });

    test('it composes exactly as a compiled-in season must', () {
      final season = RemoteConfigParser.parse(fixture)!.season!;
      final counts = <NodeType, int>{};
      for (final node in season.nodes) {
        counts[node.type] = (counts[node.type] ?? 0) + 1;
      }
      expect(counts, SeasonDefinition.composition);
    });

    test('it is a different territory from the compiled-in one', () {
      // The point of the fixture: rotation is exercised without a second
      // territory being authored as content.
      final season = RemoteConfigParser.parse(fixture)!.season!;
      expect(season.id, isNot('dust-gulch'));
      expect(season.startsAt, DateTime.utc(2026, 11, 2));
      expect(season.length, const Duration(days: 42));
    });

    test('its ranks resolve', () {
      final season = RemoteConfigParser.parse(fixture)!.season!;
      expect(season.nodeAt(1).rank, Rank.greenhorn);
      expect(season.nodeAt(42).rank, isNull);
      expect(season.nodeAt(41).rank, Rank.legend);
    });
  });

  // D-127: one variant, so no rule key. A publisher who writes one anyway
  // changes nothing — the season still parses, and its variant nodes still
  // play killer, which is decided in code rather than here.
  test('a rule key on the season is ignored, not honoured or refused', () {
    final season = fixtureSeason()
      ..['rule'] = 'jigsaw'
      ..['variant'] = 'thermo';
    final parsed = RemoteConfigParser.parse(withSeason(season))!.season;
    expect(parsed, isNotNull);
    expect(parsed!.nodes, hasLength(42));
  });

  group('no season published', () {
    test('a document with no season carries none, and still parses', () {
      final config = RemoteConfigParser.parse(withSeason(null));
      expect(config, isNotNull);
      expect(config!.season, isNull);
      // Null is the caller's cue to use the compiled-in season — not an error,
      // and not an empty trail.
      expect(config[ConfigValue.interstitialsPerSession], 4);
    });

    test('the defaults carry no season', () {
      expect(RemoteConfig.defaults().season, isNull);
    });
  });

  group('a season that cannot be read degrades on its own', () {
    // Each case leaves the season null and every other key standing. This is
    // the requirement that keeps a bad trail from being an outage.
    void expectIgnored(Object? season, String reason) {
      final config = RemoteConfigParser.parse(withSeason(season));
      expect(config, isNotNull, reason: 'the document still parses: $reason');
      expect(config!.season, isNull, reason: reason);
      expect(
        config[ConfigValue.interstitialsPerSession],
        4,
        reason: 'the other keys stand: $reason',
      );
    }

    test('a season that is not an object', () {
      expectIgnored('dust gulch', 'a string is not a season');
      expectIgnored(<Object>[], 'a list is not a season');
    });

    test('a season of the wrong length', () {
      final season = fixtureSeason();
      season['nodes'] = (season['nodes']! as List<Object?>).sublist(0, 41);
      expectIgnored(season, '41 nodes is not a season');
    });

    test('a season of the wrong composition', () {
      final season = fixtureSeason();
      final nodes = List<Object?>.from(season['nodes']! as List<Object?>);
      nodes[0] = <String, Object?>{'type': 'variant', 'rank': 'greenhorn'};
      season['nodes'] = nodes;
      expectIgnored(season, '7 variants is not a season');
    });

    test('a chest in the wrong place', () {
      final season = fixtureSeason();
      final nodes = List<Object?>.from(season['nodes']! as List<Object?>);
      nodes[9] = <String, Object?>{'type': 'chest'};
      nodes[10] = <String, Object?>{'type': 'puzzle', 'rank': 'deputy'};
      season['nodes'] = nodes;
      expectIgnored(season, 'a chest does not stand at node 10');
    });

    test('a puzzle-bearing node naming no rank', () {
      final season = fixtureSeason();
      final nodes = List<Object?>.from(season['nodes']! as List<Object?>);
      nodes[0] = <String, Object?>{'type': 'puzzle'};
      season['nodes'] = nodes;
      expectIgnored(season, 'a puzzle node names a rank');
    });

    test('a node naming a rank that does not resolve', () {
      final season = fixtureSeason();
      final nodes = List<Object?>.from(season['nodes']! as List<Object?>);
      nodes[0] = <String, Object?>{'type': 'puzzle', 'rank': 'constable'};
      season['nodes'] = nodes;
      // A typo must not quietly become a node with no rank — that would be a
      // puzzle-bearing node nobody can open.
      expectIgnored(season, 'constable is not a rank');
    });

    test('a node naming a type that does not resolve', () {
      final season = fixtureSeason();
      final nodes = List<Object?>.from(season['nodes']! as List<Object?>);
      nodes[0] = <String, Object?>{'type': 'ambush', 'rank': 'greenhorn'};
      season['nodes'] = nodes;
      expectIgnored(season, 'ambush is not a node type');
    });

    test('a season missing its name, id, start, or length', () {
      for (final key in const <String>[
        'id',
        'name',
        'starts_at',
        'length_days',
      ]) {
        final season = fixtureSeason()..remove(key);
        expectIgnored(season, 'a season carries its $key');
      }
    });

    test('a season naming a puzzle is simply a node with an unknown key', () {
      // D-110 made this structurally impossible rather than forbidden: there is
      // no field to put a puzzle id in, so an extra key is ignored like any
      // other unrecognised one and the node still resolves by rank.
      final season = fixtureSeason();
      final nodes = List<Object?>.from(season['nodes']! as List<Object?>);
      nodes[0] = <String, Object?>{
        'type': 'puzzle',
        'rank': 'greenhorn',
        'puzzle_id': 'frontier-1-0007',
      };
      season['nodes'] = nodes;

      final config = RemoteConfigParser.parse(withSeason(season));
      expect(config!.season, isNotNull);
      expect(config.season!.nodeAt(1).rank, Rank.greenhorn);
      expect(
        config.season!.nodeAt(1).toJson().keys,
        isNot(contains('puzzle_id')),
      );
    });
  });

  test('a document that is not a document is still refused whole', () {
    // Unchanged behaviour, asserted here because adding a structured key is
    // exactly when someone might loosen it.
    expect(RemoteConfigParser.parse('not json'), isNull);
    expect(RemoteConfigParser.parse('[]'), isNull);
  });

  test('the publishing note documents the season keys', () {
    final doc = File(
      'lib/features/remote_config/PUBLISHING.md',
    ).readAsStringSync();
    for (final key in const <String>[
      'season',
      'season.id',
      'season.name',
      'season.starts_at',
      'season.length_days',
      'season.nodes',
    ]) {
      expect(
        doc,
        contains(key),
        reason: '$key is publishable but undocumented',
      );
    }
  });
}
