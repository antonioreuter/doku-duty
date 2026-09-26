import 'dart:async';

import 'package:flutter/foundation.dart';

/// Decides when the player is told what a completion earned (D-134).
///
/// Two facts arrive in either order — the total, once the write lands, and the
/// end of the celebration — and the notice waits for both. The celebration is
/// the reward and is not talked over (constraint 6); the write never waits for
/// the celebration, so in practice the total is already here when it ends.
/// Under reduce-motion no celebration runs, so the notice shows at once.
///
/// **Once per completion.** A total is consumed when it is shown, so a later
/// celebration ending — or none — cannot bring it back.
class EarnNotice extends ChangeNotifier {
  EarnNotice({
    required this._earned,
    required this._celebration,
    required this._isCelebrating,
  }) {
    _earned.addListener(_onEarned);
    _celebration.addListener(_maybeShow);
  }

  /// Long enough to read "+23 Stamps", short enough to be gone before the
  /// player wonders whether it wants something from them.
  static const Duration shownFor = Duration(milliseconds: 2500);

  final ValueListenable<int?> _earned;
  final Listenable _celebration;
  final bool Function() _isCelebrating;

  int? _pending;
  int? _showing;
  Timer? _dismiss;

  /// The total on screen now, or null when there is no notice.
  int? get showing => _showing;

  void _onEarned() {
    final total = _earned.value;
    // Nothing earned is no notice at all — not a notice saying zero.
    if (total == null || total <= 0) return;
    _pending = total;
    _maybeShow();
  }

  void _maybeShow() {
    final pending = _pending;
    if (pending == null || _isCelebrating()) return;
    _pending = null;
    _showing = pending;
    _dismiss?.cancel();
    _dismiss = Timer(shownFor, () {
      _showing = null;
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _dismiss?.cancel();
    _earned.removeListener(_onEarned);
    _celebration.removeListener(_maybeShow);
    super.dispose();
  }
}
