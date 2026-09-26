import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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

import '../../support/home_navigation.dart';

/// The balance, where D-134 puts it: in the **cabinet**, and nowhere else.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Widget app() => ProviderScope(
    overrides: [
      flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
      appDatabaseProvider.overrideWith((ref) => db),
      packInstallationProvider.overrideWith(
        (ref) async => PackInstallOutcome.alreadyInstalled,
      ),
    ],
    child: const DokuDutyApp(),
  );

  Finder balance() =>
      find.byKey(const ValueKey<String>('cabinet-stamp-balance'));

  testWidgets('a player with earnings sees their sum', (tester) async {
    await StampRepository(db).earn(const <Earning>[
      Earning(key: 'chest:dust-gulch:11', amount: 12),
      Earning(key: 'perfect:q-1', amount: 3),
      Earning(key: 'daily:2026-04-09', amount: 2),
    ]);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await goToCabinet(tester);

    expect(find.bySemanticsLabel('Stamps, 17'), findsOneWidget);
  });

  testWidgets('a new player sees 0, as a number', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await goToCabinet(tester);

    expect(balance(), findsOneWidget);
    expect(find.bySemanticsLabel('Stamps, 0'), findsOneWidget);
  });

  testWidgets('it offers nothing: no button, no store, no price', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await goToCabinet(tester);

    // The balance is a receipt, not an invitation (D-66, constraint 10).
    for (final type in <Type>[
      InkWell,
      GestureDetector,
      TextButton,
      ElevatedButton,
    ]) {
      expect(
        find.descendant(of: balance(), matching: find.byType(type)),
        findsNothing,
      );
    }
  });
}
