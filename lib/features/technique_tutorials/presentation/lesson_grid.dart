import 'package:flutter/widgets.dart';

import '../../design_system/presentation/doku_colours.dart';
import '../../design_system/presentation/doku_type.dart';

/// The small fixed grid a **lesson** is taught on.
///
/// Its own painter rather than `GridPainter`. That one draws **note**s,
/// **completion tint**s, peer highlighting, **mistake** flagging and the
/// selection — a **lesson** needs none of it, and inheriting all of it would
/// mean every future change to the real board had to reason about what it does
/// to a tutorial.
class LessonGrid extends StatelessWidget {
  const LessonGrid({
    required this.grid,
    required this.marked,
    this.answerCell,
    this.answerDigit,
    super.key,
  });

  /// Eighty-one characters, `.` for empty.
  final String grid;

  /// The cells the current step is about.
  final List<int> marked;

  /// The cell the player is being asked to fill, once they are.
  final int? answerCell;

  /// Shown once the player has placed it correctly.
  final int? answerDigit;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _LessonGridPainter(
          grid: grid,
          marked: marked.toSet(),
          answerCell: answerCell,
          answerDigit: answerDigit,
          valueStyle: TypeRole.gridValue.style,
        ),
        // The grid is decoration around the text a screen reader actually
        // needs; the step's sentence carries the teaching and is a sibling of
        // this, so the picture is excluded rather than announced cell by cell.
        child: const ExcludeSemantics(child: SizedBox.expand()),
      ),
    );
  }
}

class _LessonGridPainter extends CustomPainter {
  _LessonGridPainter({
    required this.grid,
    required this.marked,
    required this.answerCell,
    required this.answerDigit,
    required this.valueStyle,
  });

  final String grid;
  final Set<int> marked;
  final int? answerCell;
  final int? answerDigit;
  final TextStyle valueStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final cell = side / 9;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, side, side),
      Paint()..color = DokuColours.bone,
    );

    // Marked cells carry a fill *and* a ring. The ring is the reason: colour is
    // never the only signal for a state (constraint 5), and a player who cannot
    // tell the fill from the paper can still see the outline.
    final fill = Paint()..color = DokuColours.badgeGold.withValues(alpha: 0.22);
    final ring = Paint()
      ..color = DokuColours.badgeGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final index in marked) {
      final rect = _rectFor(index, cell).deflate(1);
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, ring);
    }

    if (answerCell != null) {
      final rect = _rectFor(answerCell!, cell).deflate(1);
      canvas.drawRect(
        rect,
        Paint()
          ..color = DokuColours.cactusGreen
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    final thin = Paint()
      ..color = DokuColours.hairline
      ..strokeWidth = 1;
    final thick = Paint()
      ..color = DokuColours.duskInk
      ..strokeWidth = 2;
    for (var i = 0; i <= 9; i++) {
      final at = i * cell;
      final paint = i % 3 == 0 ? thick : thin;
      canvas.drawLine(Offset(at, 0), Offset(at, side), paint);
      canvas.drawLine(Offset(0, at), Offset(side, at), paint);
    }

    for (var index = 0; index < 81; index++) {
      final glyph = index == answerCell && answerDigit != null
          ? '$answerDigit'
          : grid[index];
      if (glyph == '.') continue;
      final painter = TextPainter(
        text: TextSpan(
          text: glyph,
          style: valueStyle.copyWith(
            fontSize: cell * 0.6,
            color: index == answerCell
                ? DokuColours.cactusGreen
                : DokuColours.duskInk,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final rect = _rectFor(index, cell);
      painter.paint(
        canvas,
        Offset(
          rect.left + (cell - painter.width) / 2,
          rect.top + (cell - painter.height) / 2,
        ),
      );
    }
  }

  Rect _rectFor(int index, double cell) =>
      Rect.fromLTWH((index % 9) * cell, (index ~/ 9) * cell, cell, cell);

  @override
  bool shouldRepaint(_LessonGridPainter old) =>
      old.grid != grid ||
      old.marked.length != marked.length ||
      !old.marked.containsAll(marked) ||
      old.answerCell != answerCell ||
      old.answerDigit != answerDigit;
}
