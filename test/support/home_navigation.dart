import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Switch the home shell to **free play**.
///
/// The app opens on the **trail** (D-111 keeps both, and the **trail** is the
/// spine). The two sit in an `IndexedStack`, so the one not selected is built
/// but offstage — which means a finder looking for a **rank** row finds nothing
/// until this has run.
///
/// Tapping the navigation rather than reaching past it with
/// `skipOffstage: false`, because that is the route a player takes and it is
/// the thing worth having a test walk.
Future<void> goToFreePlay(WidgetTester tester) async {
  await tester.tap(find.text('Free play'));
  await tester.pumpAndSettle();
}

/// Switch the home shell back to the **trail**.
Future<void> goToTrail(WidgetTester tester) async {
  await tester.tap(find.text('Trail'));
  await tester.pumpAndSettle();
}

/// Open a **rank** from **free play**, scrolling to it if it is below the fold.
///
/// The scroll is not incidental. At the reader's larger text sizes on the
/// smallest phone the app targets (D-84), six rows do not fit at once and the
/// list builds lazily — so a row further down is not merely off screen, it does
/// not exist yet. A plain `tap` finds nothing and reports it as an absence.
Future<void> openRank(WidgetTester tester, String rankName) async {
  final row = find.byKey(ValueKey<String>('rank-$rankName'));
  if (row.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      row,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }
  await tester.tap(row);
  await tester.pumpAndSettle();
}
