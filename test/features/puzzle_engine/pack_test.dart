import 'dart:convert';

import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/cage.dart';
import 'package:doku_duty/features/puzzle_engine/domain/pack.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';

import 'support/killer.dart';
import 'support/positions.dart';

Pack _pack({List<PackPuzzle>? puzzles}) => Pack(
  packId: 'frontier-1',
  version: 3,
  puzzles:
      puzzles ??
      <PackPuzzle>[
        PackPuzzle(
          id: 'q1',
          clues: referenceClues,
          solution: referenceSolution,
          rank: Rank.deputy,
          seed: 4242,
        ),
        PackPuzzle(
          id: 'q2',
          clues: referenceClues,
          solution: referenceSolution,
          rank: Rank.legend,
          seed: 99,
        ),
      ],
);

Pack _parsed(String source) => (Pack.parse(source) as ParsedPack).pack;

void main() {
  group('round trip', () {
    // D-32: each puzzle carries its solution, its required-technique grade, and
    // its seed. Nothing is derived on read that was not written — a solution
    // recomputed at load time would be a second answer to what the puzzle is.
    test('a pack survives encoding and reading back', () {
      final original = _pack();
      final restored = _parsed(original.encode());

      expect(restored.packId, original.packId);
      expect(restored.version, original.version);
      expect(restored.puzzles, hasLength(2));
      for (var i = 0; i < original.puzzles.length; i++) {
        final before = original.puzzles[i];
        final after = restored.puzzles[i];
        expect(after.id, before.id);
        expect(after.clues, before.clues);
        expect(after.solution, before.solution);
        expect(after.rank, before.rank);
        expect(after.seed, before.seed);
      }
      expect(restored, original);
    });

    test('encoding twice gives the same bytes', () {
      expect(_pack().encode(), _pack().encode());
    });

    test('the puzzle order is the order it was written in', () {
      final restored = _parsed(_pack().encode());
      expect(restored.puzzles.map((p) => p.id), <String>['q1', 'q2']);
    });

    test('the rank is stored by its name, so it is readable in a diff', () {
      final json = jsonDecode(_pack().encode()) as Map<String, dynamic>;
      final first = (json['puzzles'] as List<dynamic>).first;
      expect((first as Map<String, dynamic>)['rank'], 'deputy');
    });
  });

  group('a malformed pack is a value, never an exception', () {
    void expectRejected(String source, PackProblem problem) {
      final result = Pack.parse(source);
      expect(result, isA<InvalidPack>(), reason: source);
      final invalid = result as InvalidPack;
      expect(invalid.problem, problem, reason: invalid.description);
      expect(invalid.description, isNotEmpty);
    }

    test('text that is not JSON', () {
      expectRejected('not json at all', PackProblem.notJson);
      expectRejected('', PackProblem.notJson);
    });

    test('JSON that is not an object', () {
      expectRejected('[1, 2, 3]', PackProblem.notAnObject);
      expectRejected('"a string"', PackProblem.notAnObject);
    });

    test('a missing field', () {
      expectRejected('{"version": 1, "puzzles": []}', PackProblem.missingField);
      expectRejected(
        '{"packId": "p", "puzzles": []}',
        PackProblem.missingField,
      );
      expectRejected('{"packId": "p", "version": 1}', PackProblem.missingField);
    });

    test('a field of the wrong type', () {
      expectRejected(
        '{"packId": 7, "version": 1, "puzzles": []}',
        PackProblem.wrongType,
      );
      expectRejected(
        '{"packId": "p", "version": "one", "puzzles": []}',
        PackProblem.wrongType,
      );
      expectRejected(
        '{"packId": "p", "version": 1, "puzzles": {}}',
        PackProblem.wrongType,
      );
    });

    test('a grid that is not eighty-one characters', () {
      final json = jsonDecode(_pack().encode()) as Map<String, dynamic>;
      (json['puzzles'] as List<dynamic>)[0]['clues'] = '123';
      expectRejected(jsonEncode(json), PackProblem.invalidGrid);
    });

    test('a grid holding a character that is not a digit or a blank', () {
      final json = jsonDecode(_pack().encode()) as Map<String, dynamic>;
      (json['puzzles'] as List<dynamic>)[0]['solution'] = 'x' * 81;
      expectRejected(jsonEncode(json), PackProblem.invalidGrid);
    });

    test('a rank that is not one of the six', () {
      final json = jsonDecode(_pack().encode()) as Map<String, dynamic>;
      (json['puzzles'] as List<dynamic>)[0]['rank'] = 'inspector';
      expectRejected(jsonEncode(json), PackProblem.unknownRank);
    });

    test('two puzzles under one id', () {
      final json = jsonDecode(_pack().encode()) as Map<String, dynamic>;
      (json['puzzles'] as List<dynamic>)[1]['id'] = 'q1';
      expectRejected(jsonEncode(json), PackProblem.duplicateId);
    });

    test('a pack with no puzzles at all', () {
      expectRejected(
        '{"packId": "p", "version": 1, "puzzles": []}',
        PackProblem.emptyPack,
      );
    });

    test('reading never throws, whatever it is handed', () {
      for (final source in <String>[
        '',
        'nonsense',
        '{',
        'null',
        '{"packId": null, "version": null, "puzzles": null}',
      ]) {
        expect(() => Pack.parse(source), returnsNormally, reason: source);
      }
    });

    test('the description says which puzzle was wrong', () {
      final json = jsonDecode(_pack().encode()) as Map<String, dynamic>;
      (json['puzzles'] as List<dynamic>)[1]['rank'] = 'inspector';
      final invalid = Pack.parse(jsonEncode(json)) as InvalidPack;
      expect(invalid.description, contains('q2'));
    });
  });

  // A pack format that rejects what it does not recognise strands an installed
  // app on the first file that adds a field. Tolerating the unknown is what
  // lets a later pack carry, say, a variant without this reader being updated
  // first.
  group('forward compatibility', () {
    test('an unknown field on the pack is ignored, not rejected', () {
      final json = jsonDecode(_pack().encode()) as Map<String, dynamic>;
      json['territory'] = 'dust-flats';
      json['nodes'] = <int>[1, 2, 3];

      final result = Pack.parse(jsonEncode(json));
      expect(result, isA<ParsedPack>());
      expect((result as ParsedPack).pack.puzzles, hasLength(2));
    });

    test('an unknown field on a puzzle is ignored, not rejected', () {
      final json = jsonDecode(_pack().encode()) as Map<String, dynamic>;
      (json['puzzles'] as List<dynamic>)[0]['thermometers'] = <int>[1, 2];

      final result = Pack.parse(jsonEncode(json));
      expect(result, isA<ParsedPack>());
      expect((result as ParsedPack).pack.puzzles.first.id, 'q1');
    });

    test('an ignored field does not survive a re-encode', () {
      final json = jsonDecode(_pack().encode()) as Map<String, dynamic>;
      json['territory'] = 'dust-flats';
      final reencoded = _parsed(jsonEncode(json)).encode();
      expect(reencoded, isNot(contains('territory')));
    });
  });

  // Written in `add-season-map` as "an unknown `variant` field is ignored", to
  // hand the format over to this change. **Killer** is the variant, and its
  // **cage**s are the field (D-127).
  group('cages', () {
    final cages = referenceKillerCages(referenceSolution);
    PackPuzzle killerPuzzle({CageSet? withCages}) => PackPuzzle(
      id: 'k1',
      clues: '.' * 81,
      solution: referenceSolution,
      rank: Rank.sheriff,
      seed: 7,
      cages: withCages ?? cages,
    );

    test('a killer puzzle reads and round-trips its cages', () {
      final original = _pack(
        puzzles: <PackPuzzle>[killerPuzzle(), _pack().puzzles.first],
      );
      final restored = _parsed(original.encode());

      final killer = restored.puzzles.first;
      expect(killer.cages, isNotNull);
      expect(
        <String>[for (final cage in killer.cages!.cages) '$cage'],
        <String>[for (final cage in cages.cages) '$cage'],
      );
      expect(restored, original);
      expect(restored.encode(), original.encode());
    });

    test('a classic puzzle has none, and writes no cages field', () {
      final restored = _parsed(_pack().encode());
      expect(restored.puzzles.first.cages, isNull);
      final json = jsonDecode(_pack().encode()) as Map<String, dynamic>;
      expect(
        ((json['puzzles'] as List<dynamic>).first as Map<String, dynamic>)
            .containsKey('cages'),
        isFalse,
      );
    });

    test('cages are written as a sum and cells per cage', () {
      final json =
          jsonDecode(_pack(puzzles: <PackPuzzle>[killerPuzzle()]).encode())
              as Map<String, dynamic>;
      final first =
          (((json['puzzles'] as List<dynamic>).single
                      as Map<String, dynamic>)['cages']
                  as List<dynamic>)
              .first;
      expect(first, <String, Object>{
        'sum': 12,
        'cells': <int>[0, 1, 2],
      });
    });

    test('a malformed cage set is refused as a value', () {
      final json =
          jsonDecode(_pack(puzzles: <PackPuzzle>[killerPuzzle()]).encode())
              as Map<String, dynamic>;
      final row =
          (json['puzzles'] as List<dynamic>).single as Map<String, dynamic>;
      // Drop the first cage: three cells are then in none.
      (row['cages'] as List<dynamic>).removeAt(0);

      final result = Pack.parse(jsonEncode(json));
      expect(result, isA<InvalidPack>());
      expect((result as InvalidPack).problem, PackProblem.invalidCages);
      expect(result.description, contains('k1'));
    });

    test('cages of the wrong shape are refused as a value', () {
      for (final bad in <Object>[
        'aaab',
        <Object>[7],
        <Object>[
          <String, Object>{
            'sum': '12',
            'cells': <int>[0],
          },
        ],
        <Object>[
          <String, Object>{'sum': 12},
        ],
      ]) {
        final json =
            jsonDecode(_pack(puzzles: <PackPuzzle>[killerPuzzle()]).encode())
                as Map<String, dynamic>;
        ((json['puzzles'] as List<dynamic>).single
                as Map<String, dynamic>)['cages'] =
            bad;
        final result = Pack.parse(jsonEncode(json));
        expect(result, isA<InvalidPack>(), reason: '$bad');
        expect((result as InvalidPack).problem, PackProblem.invalidCages);
      }
    });

    test('cages the solution does not satisfy are refused', () {
      // The reference cages over a different solution: its sums are wrong.
      const other =
          '123456789456789123789123456214365897365897214897214365531642978642978531978531642';
      final result = Pack.parse(
        _pack(
          puzzles: <PackPuzzle>[
            PackPuzzle(
              id: 'k2',
              clues: '.' * 81,
              solution: other,
              rank: Rank.sheriff,
              seed: 7,
              cages: cages,
            ),
          ],
        ).encode(),
      );
      expect(result, isA<InvalidPack>());
      expect((result as InvalidPack).problem, PackProblem.invalidCages);
    });
  });
}
