import 'dart:convert';
import 'dart:io';

import 'package:doku_duty/features/remote_config/application/remote_config_provider.dart';
import 'package:doku_duty/features/remote_config/domain/config_value.dart';
import 'package:doku_duty/features/remote_config/domain/remote_config.dart';
import 'package:doku_duty/features/season_map/domain/season_one.dart';
import 'package:doku_duty/features/trophy_cabinet/application/cabinet_providers.dart';
import 'package:doku_duty/features/trophy_cabinet/domain/award_catalogue.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A bad `awards` list, end to end: from the published document to what the
/// **cabinet** offers.
///
/// `award_catalogue_test.dart` covers the parsing. This covers the part that
/// cannot be seen from there — that a publishing mistake reaches the player as
/// the fallback, never as a failure, the way a bad **season** and a bad daily
/// schedule already do (D-125).
void main() {
  final fixture =
      jsonDecode(
            File(
              'test/features/remote_config/fixtures/config_with_season.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;

  /// The fixture's **season**, with its `awards` key set to [awards].
  String withAwards(Object? awards, {Map<String, Object?>? season}) {
    final document = Map<String, Object?>.of(fixture);
    final published = Map<String, Object?>.of(
      season ?? fixture['season']! as Map<String, Object?>,
    );
    published['awards'] = awards;
    document['season'] = published;
    return jsonEncode(document);
  }

  AwardCatalogue catalogueFor(String document) {
    final config = RemoteConfigParser.parse(document);
    expect(config, isNotNull, reason: 'the document itself was refused');
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(remoteConfigProvider.notifier).apply(config!);
    return container.read(awardCatalogueProvider);
  }

  List<String> fallbackIds(String seasonId, String seasonName) => <String>[
    for (final award in AwardCatalogue.compiledInFor(
      seasonId: seasonId,
      seasonName: seasonName,
    ))
      award.id,
  ];

  group('a malformed award list degrades to the fallback', () {
    for (final (label, awards) in <(String, Object?)>[
      ('not a list', <String, Object?>{'id': 'x'}),
      ('a string', 'awards'),
      (
        'every entry unreadable',
        <Object?>[
          'not an object',
          <String, Object?>{'name': 'No id', 'trigger': 'boss'},
          <String, Object?>{'id': 'b', 'name': 'Boss', 'trigger': 'boss'},
          <String, Object?>{'id': 'x', 'name': 'X', 'trigger': 'shrug'},
        ],
      ),
      ('an empty list', const <Object?>[]),
    ]) {
      test(label, () {
        final catalogue = catalogueFor(withAwards(awards));

        expect(
          catalogue.seasonal.map((a) => a.id),
          fallbackIds('copper-hollow', 'Copper Hollow'),
        );
        expect(
          catalogue.awards.where((a) => a.isPermanent),
          hasLength(AwardCatalogue.permanent.length),
        );
      });
    }

    test('the rest of the document still applies', () {
      // The ad caps and the **season** survive a bad `awards` list — one key
      // at a time, as the remote-config requirement demands.
      final config = RemoteConfigParser.parse(withAwards('awards'))!;

      expect(config.season?.id, 'copper-hollow');
      expect(config[ConfigValue.interstitialsPerSession], 6);
    });

    test('a partly readable list keeps what it can read', () {
      final catalogue = catalogueFor(
        withAwards(<Object?>[
          'not an object',
          <String, Object?>{
            'id': 'copper.closed',
            'name': 'Copper Hollow, closed',
            'trigger': 'season_complete',
          },
        ]),
      );

      expect(catalogue.seasonal.map((a) => a.id), <String>['copper.closed']);
    });
  });

  group('a refused season takes its awards with it', () {
    test('they are not filed under the compiled-in season', () {
      // The **trail** falls back to the compiled-in **season** when the
      // published one is refused. Its **award**s must not follow the player
      // there under the wrong territory's id.
      final broken = Map<String, Object?>.of(
        fixture['season']! as Map<String, Object?>,
      )..['nodes'] = const <Object?>[];
      final catalogue = catalogueFor(
        withAwards(<Object?>[
          <String, Object?>{
            'id': 'copper.closed',
            'name': 'Copper Hollow, closed',
            'trigger': 'season_complete',
          },
        ], season: broken),
      );

      final season = SeasonOne.season;
      expect(
        catalogue.seasonal.map((a) => a.id),
        fallbackIds(season.id, season.name),
      );
      expect(catalogue.byId('copper.closed'), isNull);
    });
  });
}
