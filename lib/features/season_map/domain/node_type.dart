/// What a **node** on the **trail** is.
///
/// Fixed per **node** by the **season** definition and never changing within a
/// **season** (D-18). The type decides what opening the **node** does and what
/// it is drawn as; the state — completed, current, **not yet reached** — is a
/// separate fact that every type carries.
enum NodeType {
  /// A classic sudoku at the **node**'s **rank**. Thirty per **season**.
  puzzle,

  /// The **season**'s rule twist. Six per **season**.
  ///
  /// Plays a **killer** puzzle at the **node**'s **rank** — the only route to
  /// **killer** in the app (D-127). One variant, compiled in for every
  /// **season**, so the **season** document carries no rule key.
  variant,

  /// A reward, carrying no puzzle. Four per **season**, at 25/50/75/100%.
  ///
  /// Opening one *is* the reward. It cannot be failed, costs nothing, and needs
  /// no network. It pays 12 **stamp**s, once, through the **cabinet**'s
  /// minting service — the one place a **stamp** is earned (D-66, D-133).
  chest,

  /// The midpoint and the finale. Two per **season**.
  ///
  /// A puzzle like any other except that it retries without limit and without
  /// cost (D-22). It files no trophy until `add-trophy-cabinet`.
  boss;

  /// Whether opening this **node** opens a puzzle.
  ///
  /// The one question the rest of the app asks of a type, so it is answered
  /// here rather than by a `switch` at each call site — a fifth type would
  /// otherwise be a compile error in four places and a silent wrong answer in
  /// the fifth.
  bool get bearsPuzzle => this != chest;

  /// Whether an interstitial may ever follow this **node** completing.
  ///
  /// False for chest and boss, and compiled in rather than configurable: D-24
  /// names them alongside the daily challenge as never-eligible, and
  /// `PUBLISHING.md` records that no config key can reach placement
  /// (constraint 6). `add-ads-integration` reads this rather than re-deciding
  /// it.
  bool get mayBeFollowedByInterstitial => this == puzzle || this == variant;

  /// The key this type is published under in a **season** document.
  String get key => name;

  static NodeType? fromKey(String key) {
    for (final type in NodeType.values) {
      if (type.key == key) return type;
    }
    return null;
  }
}
