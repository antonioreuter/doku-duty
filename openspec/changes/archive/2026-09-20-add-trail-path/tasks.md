# Tasks — add-trail-path

## 1. The decision

- [x] 1.1 Append **D-113** to `docs/DECISIONS.md`: the **trail** path is
      decoration and carries no state. Record the argument — the marker already
      carries walked-ness three ways (colour, glyph, size), so a stateful path
      would be a fourth encoding of unambiguous information and would spend a
      colour token's documented job on redundancy.
- [x] 1.2 In the same entry, record that `hairline` is the wrong token for this
      line despite being the obvious choice: at 1.07:1 on `sand` it is invisible,
      because it is a tint of the page background and is only legible on `bone`.
      `inkSoft` is used instead, at 4.50:1. Without this note a later change
      "corrects" the line back to `hairline` and silently erases it.

## 2. The painter

- [x] 2.1 Add `TrailPathPainter` in
      `lib/features/season_map/presentation/trail_path_painter.dart` — a
      `CustomPainter` drawing one segment from the previous **node**'s anchor to
      this row's anchor, given both alignments and the row geometry. No state
      parameters: it must be impossible to pass it a `NodeState`.
- [x] 2.2 Unit-test the painter's geometry: the segment starts and ends on the
      correct side for odd and even **node** positions, and the first **node**
      draws no incoming segment.
- [x] 2.3 Test that the painter's `shouldRepaint` returns false for identical
      geometry, so scrolling the 42-row list does not repaint every segment.

## 3. Wiring it into the trail

- [x] 3.1 Paint the segment behind the marker in `_TrailRow`
      (`trail_screen.dart`), so the line is under the marker, its glyph, and its
      label. Do **not** reuse the `ValueKey('trail-path')` already on the
      `ListView` — it is taken, and duplicating it would break the existing
      `trail_screen_test.dart` finders.
- [x] 3.2 Ensure the line contributes no semantics node. **`ExcludeSemantics`
      as this task originally specified is wrong** — the `CustomPaint`'s child
      is the marker, so excluding would silence the markers too. A
      `CustomPainter` with no `semanticsBuilder` adds no semantics node at all,
      so the correct implementation is to assert that rather than wrap
      anything. The specified outcome is unchanged.
- [x] 3.3 Widget-test that all 42 **node**s still resolve by their existing
      `trail-node-<n>` keys and that every existing `trail_screen_test.dart`
      assertion still passes unchanged.

## 4. The requirement's own tests

- [x] 4.1 Test the line carries no state: render a **trail** with completed,
      current, and **not yet reached** **node**s, and assert the painter is
      constructed identically for a completed row and an unreached row.
- [x] 4.2 Test no new hue: assert the painter's colour is `DokuColours.inkSoft`
      and that it is a derived tint of one of the eight tokens, not a literal.
- [x] 4.3 Test the first frame: extend the existing assertion that nothing reads
      the database on the path to the first frame, confirming the line is drawn
      before progress resolves.
- [x] 4.4 Update the two goldens in `test/features/season_map/goldens/`
      (`trail_new_player.png`, `trail_mid_season.png`) and confirm by eye that
      the diff is the line and nothing else. **It is not quite "nothing else"**:
      the 44px markers sit ~6px further from the edge because of the uniform
      anchor box, while the 60px **current node** is unmoved. Checked against
      the previous goldens side by side; alternation, sizes, labels, and the
      header are otherwise identical. Recorded in the proposal's "Not doing".

## 5. Spec and docs

- [x] 5.1 Note in `trail_screen.dart` that alternating alignment gives the
      *shape* of the winding and the painter gives the *linking* — the existing
      comment claims alternation alone "is what makes it a path rather than a
      list", and it should not survive this change unqualified.
- [x] 5.2 Confirmed `docs/DESIGN.md` needs no new value: §3 already gives
      "Interior detail stroke: 2", which is what the line uses, against the
      marker's 3px outer contour. Nothing added.

## Platform checks

- [x] Verified on iOS — iPhone 17 simulator (iOS 26.5), dev flavour. The line
      is drawn and correctly positioned, clear of the Dynamic Island and the
      home indicator. `integration_test/season_map_test.dart` still passes all
      four: safe area unchanged at top 62.0pt / bottom 34.0pt with the nav at
      840.0 of 874.0pt, the **current node** reachable without scrolling, all 42
      **node**s reachable, and a completion surviving a real SQLite round trip.
- [x] Verified on Android — Pixel 10 Pro emulator, Android 17 (API 37), dev
      flavour, cold launch after `pm clear`. The line is drawn, winds through
      all built **node**s, and passes behind both the 60px **current node** and
      the 44px padlocked ones at the same inset. Caught the pre-progress frame
      too: the line is already complete while the header still reads "Trail
      progress" with no count, which is the requirement's own first-frame
      scenario confirmed on a device. **The outstanding physical-device debt is
      not touched by this change** — this is an emulator, and the mid-tier
      Android latency and haptics profile carried against changes 6, 11 and 15
      is unchanged.
- [x] Accessibility: `trail_accessibility_test.dart` passes all 12 unchanged —
      nothing overflows or truncates at 1x, 2x, 3x, 4x or 5x; every **node**
      announces its number, type, and state; colour removed still leaves every
      state, **chest node** and **boss node** distinguishable. The line adds no
      semantics node (`semanticsBuilder` is null, asserted directly), and the
      trail announces exactly as many **node**s as it draws segments. The
      uniform anchor box is what keeps this true above 2x: the label now paints
      wider than the marker instead of widening it, so the line does not drift
      off the circle as text grows.
