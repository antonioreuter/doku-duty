import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/stamps/data/stamp_repository.dart';
import 'package:doku_duty/features/stamps/domain/earning.dart';

/// Where **stamp**s may not appear, and what they may never be beside.
///
/// Constraint 10 and D-66: earned in play, never bought. D-134: shown in the
/// **cabinet** and the earn notice, never on the **trail**.
void main() {
  testWidgets('the trail shows no stamp count, even with a balance', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await StampRepository(
      db,
    ).earn(const <Earning>[Earning(key: 'chest:dust-gulch:11', amount: 12)]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
          appDatabaseProvider.overrideWith((ref) => db),
          packInstallationProvider.overrideWith(
            (ref) async => PackInstallOutcome.alreadyInstalled,
          ),
        ],
        child: const DokuDutyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The app opens on the **trail**; everything offstage — the **cabinet**
    // among it — is out of the finder's reach, which is the point.
    expect(
      find.textContaining(RegExp('stamp', caseSensitive: false)),
      findsNothing,
    );
  });

  test('no line of the app that names stamps also sells anything', () {
    // Code, not commentary: a comment saying "D-66 prices a daily at 2" is the
    // rule written down, and a string saying "Buy 50 Stamps" is the rule
    // broken. Every non-comment line that mentions a **stamp** is checked for
    // the vocabulary of a sale.
    final sale = RegExp(
      r'\b(buy|price|purchase|store|shop|bundle|sku|offer|deal|pack of)\b|\$\d',
      caseSensitive: false,
    );
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.steps.dart')) {
        continue;
      }
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//')) continue;
        if (!line.toLowerCase().contains('stamp')) continue;
        if (sale.hasMatch(line)) {
          offenders.add('${entity.path}:${i + 1}: $line');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
