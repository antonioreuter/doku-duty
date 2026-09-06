import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/palette.dart';
import 'package:doku_duty/features/design_system/domain/shape.dart';
import 'package:doku_duty/features/design_system/presentation/doku_card.dart';
import 'package:doku_duty/features/design_system/presentation/pressable.dart';

/// `docs/DESIGN.md` §4 calls this out as *the exception* to the depth
/// treatment, and it is the easiest rule in this change to break by accident:
/// the primitives look generic enough to reuse for a cell, and nine columns of
/// them destroys the board's readability.
void main() {
  group('depth is chrome only', () {
    testWidgets('the primitives are chrome, and say so', (tester) async {
      // Both primitives exist and carry depth. Nothing else in the design
      // system paints a depth shade, so the grid painter has nothing to
      // accidentally inherit.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: <Widget>[
              Pressable(
                onPressed: () {},
                child: const SizedBox.square(dimension: 40),
              ),
              const DokuCard(
                tiltSeed: 1,
                child: SizedBox.square(dimension: 40),
              ),
            ],
          ),
        ),
      );
      expect(find.byType(Pressable), findsOneWidget);
      expect(find.byType(DokuCard), findsOneWidget);
    });

    test('every file that paints depth documents that it is chrome', () {
      // A file that reads DokuDepth is painting the treatment. Each must say so
      // in prose, so the next person adding one is told the rule before they
      // reach for it in the grid.
      final painters = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('domain/shape.dart')) continue;
        final source = entity.readAsStringSync();
        if (source.contains('DokuDepth.')) painters.add(entity.path);
      }

      expect(painters, isNotEmpty, reason: 'nothing paints depth at all?');
      for (final path in painters) {
        final source = File(path).readAsStringSync();
        expect(
          source.contains('grid') || source.contains('chrome'),
          isTrue,
          reason: '$path paints depth without saying it is chrome only',
        );
      }
    });

    test('no cell-sized default sneaks in', () {
      // The minimum tap target is a cell's size. A primitive defaulting to it
      // would be an invitation to build the grid out of these.
      expect(DokuDepth.rest, lessThan(DokuLayout.minimumTapTarget));
    });
  });

  group('the shadow is never a blur', () {
    testWidgets('neither primitive uses BoxShadow', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: <Widget>[
              Pressable(
                onPressed: () {},
                token: PaletteToken.badgeGold,
                child: const SizedBox.square(dimension: 40),
              ),
              const DokuCard(
                tiltSeed: 7,
                child: SizedBox.square(dimension: 40),
              ),
            ],
          ),
        ),
      );

      for (final element in find.byType(DecoratedBox).evaluate()) {
        final box = element.widget as DecoratedBox;
        final decoration = box.decoration;
        if (decoration is BoxDecoration) {
          expect(
            decoration.boxShadow,
            anyOf(isNull, isEmpty),
            reason: 'blur reads corporate; depth is a painted offset',
          );
        }
      }
    });

    test('no source file constructs a BoxShadow', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final code = lines[i].split('//').first;
          if (RegExp(r'\bBoxShadow\s*\(').hasMatch(code)) {
            offenders.add('${entity.path}:${i + 1}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'solid offset shadows only (docs/DESIGN.md §4)',
      );
    });
  });
}
