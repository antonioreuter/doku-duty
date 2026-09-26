import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/stamps/application/earn_notice.dart';

/// A stand-in for the effects controller: whether the celebration is running.
class _Celebration extends ChangeNotifier {
  bool running = false;
  void set(bool value) {
    running = value;
    notifyListeners();
  }
}

/// When the earn notice shows, and for how long (D-134).
///
/// Widget tests only for the fake clock `tester.pump` drives: the dismissal is
/// a timer, and waiting two and a half real seconds per case would be a test
/// suite that teaches people to skip it.
void main() {
  late ValueNotifier<int?> earned;
  late _Celebration celebration;
  late EarnNotice notice;

  setUp(() {
    earned = ValueNotifier<int?>(null);
    celebration = _Celebration();
    notice = EarnNotice(
      earned: earned,
      celebration: celebration,
      isCelebrating: () => celebration.running,
    );
  });
  tearDown(() => notice.dispose());

  testWidgets('it waits for the celebration to finish, then shows the total', (
    tester,
  ) async {
    celebration.set(true);
    earned.value = 5;
    expect(notice.showing, isNull, reason: 'shown over the celebration');

    celebration.set(false);
    expect(notice.showing, 5);
    await tester.pump(EarnNotice.shownFor);
  });

  testWidgets('with no celebration running it shows at once', (tester) async {
    // Reduce-motion plays no sequence, so there is nothing to wait for.
    earned.value = 3;
    expect(notice.showing, 3);
    await tester.pump(EarnNotice.shownFor);
  });

  testWidgets('a completion that earned nothing shows nothing', (tester) async {
    earned.value = 0;
    await tester.pump(const Duration(seconds: 1));
    expect(notice.showing, isNull);
  });

  testWidgets('it dismisses itself', (tester) async {
    earned.value = 3;
    await tester.pump(EarnNotice.shownFor - const Duration(milliseconds: 1));
    expect(notice.showing, 3);
    await tester.pump(const Duration(milliseconds: 2));
    expect(notice.showing, isNull);
  });

  testWidgets('once per completion, however often the celebration ends', (
    tester,
  ) async {
    earned.value = 3;
    await tester.pump(EarnNotice.shownFor);
    celebration.set(true);
    celebration.set(false);
    expect(notice.showing, isNull);
  });
}
