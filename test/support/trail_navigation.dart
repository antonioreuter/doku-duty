import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Find a **node** marker on the **trail**, built or not yet built.
Finder trailNode(int position) =>
    find.byKey(ValueKey<String>('trail-node-$position'), skipOffstage: false);

/// Bring a **node** into view, building it if the list has not yet.
///
/// The **trail** scrolls and builds lazily, which is the right shape for 42
/// **node**s — building all of them eagerly would put 42 markers on the cold
/// start path for a screen showing six. So a test reaching node 30 walks there,
/// the same as a player.
///
/// The jump back to the top is not a flourish. `scrollUntilVisible` only
/// travels one way, so a test that has already scrolled past a **node** could
/// never scroll back to it — and the **variant node**s sit at positions 2 and
/// 4, above almost everything else a test reaches for.
Future<void> scrollToNode(WidgetTester tester, int position) async {
  if (trailNode(position).evaluate().isNotEmpty) return;
  final scrollable = tester.state<ScrollableState>(
    find.byType(Scrollable).first,
  );
  scrollable.position.jumpTo(0);
  await tester.pumpAndSettle();
  if (trailNode(position).evaluate().isNotEmpty) return;
  await tester.scrollUntilVisible(
    trailNode(position),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Open a **node**, stepping past a **lesson** if one fires on the way in.
///
/// A **node** at Sheriff **rank** or harder is where the **notes lesson** is
/// due (D-106), and the **boss node**s sit at 22 and 41 — so opening one is
/// exactly the case where a **lesson** precedes the grid. That is correct and
/// specified: `grid-input` says a **lesson** may precede the grid and is never
/// a penalty for reaching upward. A test about the **node** steps past it in
/// one tap, which is what the player can do too.
Future<void> openTrailNode(WidgetTester tester, int position) async {
  await scrollToNode(tester, position);
  await tester.tap(trailNode(position));
  await tester.pumpAndSettle();

  final skip = find.byKey(const ValueKey<String>('lesson-skip'));
  if (skip.evaluate().isNotEmpty) {
    await tester.tap(skip);
    await tester.pumpAndSettle();
  }
}
