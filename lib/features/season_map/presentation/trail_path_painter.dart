import 'package:flutter/widgets.dart';

import '../../design_system/presentation/doku_colours.dart';

/// The line linking one **node** on the **trail** to the one before it.
///
/// **It carries no state, and that is deliberate** (D-113). There is no
/// `NodeState` parameter here, and no `diameter` either — not even the
/// marker's own circle, which grows at the **current node**. Nothing about a
/// **node** reaches this painter: the marker already
/// says whether a **node** is completed, current, or **not yet reached**, three
/// ways over — by colour, by glyph, and by size — so a path that also encoded
/// progress would be a fourth signal for something unambiguous, and it would
/// have to spend `badgeGold`'s or `cactusGreen`'s documented job to do it
/// (constraint 4).
///
/// **The colour is `inkSoft`, and `hairline` is wrong** however much it looks
/// right. `hairline` is a tint of `sand`, which is the page the **trail** is
/// drawn on, and measures 1.07:1 against it — invisible. It works as an
/// interior grid line only because a grid cell is `bone`. `inkSoft` is the tint
/// of `duskInk` at 4.50:1 on `sand`, so the markers are drawn in primary ink
/// and the connector in secondary ink. D-113 records this so the line is not
/// "corrected" back to `hairline` and silently erased.
class TrailPathPainter extends CustomPainter {
  const TrailPathPainter({
    required this.isLeft,
    required this.isFirst,
    required this.isLast,
  });

  /// Which side this row's marker sits on. The row before it sits on the other.
  final bool isLeft;

  /// The first **node** has nothing above it to join.
  final bool isFirst;

  /// The last **node** has nothing below it, so the line stops rather than
  /// running off the end of the **season**.
  final bool isLast;

  /// Horizontal padding on a trail row, from `_TrailRow`.
  static const double rowInset = 32;

  /// Every marker is laid out in a box this wide (D-114), whatever its circle
  /// measures and whatever the text scale, so that both anchors are the same
  /// distance from their edge and the line meets a 44px circle and a 60px one
  /// alike.
  static const double anchorWidth = 60;

  /// Vertical padding on a trail row, from `_TrailRow`.
  static const double rowVerticalPad = 10;

  /// `docs/DESIGN.md` §3 — interior detail stroke. The marker's own contour is
  /// 3, so the connector reads as subordinate to it rather than competing.
  static const double strokeWidth = 2;

  static const double _anchorInset = rowInset + anchorWidth / 2;

  /// Where the line meets the marker, measured from the row's top edge.
  ///
  /// The centre of the *anchor box*, not of the circle — so it does not move
  /// when a **node** becomes current and its circle grows from 44 to 60. That
  /// is the whole point: taking the circle's own size would make this painter
  /// state-dependent, which D-113 forbids, and it would buy nothing, because
  /// either terminus is hidden behind the marker at both sizes.
  static const double _anchorCentreY = rowVerticalPad + anchorWidth / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final double myX = isLeft ? _anchorInset : size.width - _anchorInset;
    final double previousX = isLeft ? size.width - _anchorInset : _anchorInset;
    const double centreY = _anchorCentreY;

    final paint = Paint()
      ..color = DokuColours.inkSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (!isFirst) {
      // Enters at the top edge directly below where the previous row's stub
      // left off, so the two meet with no seam across the row boundary.
      path.moveTo(previousX, 0);
      path.cubicTo(previousX, centreY * 0.5, myX, centreY * 0.5, myX, centreY);
    }

    if (!isLast) {
      // Straight down to the row's bottom edge, which is where the next row
      // starts its curve. Keeping the crossing inside one row means neither
      // row has to know the other's height.
      path.moveTo(myX, centreY);
      path.lineTo(myX, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  /// Geometry only. There is no state to compare, because none is accepted.
  bool shouldRepaint(TrailPathPainter old) =>
      old.isLeft != isLeft || old.isFirst != isFirst || old.isLast != isLast;
}
