import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';

void main() {
  testWidgets('building the app shell does not open the database', (
    tester,
  ) async {
    var opened = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
          appDatabaseProvider.overrideWith((ref) {
            opened++;
            return AppDatabase(NativeDatabase.memory());
          }),
        ],
        child: const DokuDutyApp(),
      ),
    );
    // Asserted on the first frame, before pumping another. One eager `watch`
    // anywhere on the startup path breaks this, and the symptom — a slower cold
    // start on a cheap Android phone — is not something anyone notices in
    // review.
    expect(
      opened,
      0,
      reason: 'the database was constructed while reaching the first frame',
    );

    // A frame later it is allowed, and the rank picker does exactly that:
    // `add-grid-and-input` reads which puzzle is next from a post-frame
    // callback. Pinned rather than merely permitted, so moving that read back
    // onto the first frame fails above rather than passing quietly here.
    await tester.pump();
    await tester.pump();
    expect(opened, 1, reason: 'the pack is read once the app is on screen');
  });

  test('the provider is not built until it is read', () {
    var opened = 0;
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          opened++;
          return AppDatabase(NativeDatabase.memory());
        }),
      ],
    );
    addTearDown(container.dispose);

    expect(opened, 0);
    container.read(appDatabaseProvider);
    expect(opened, 1);
  });
}
