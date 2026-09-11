import 'candidates.dart';
import 'grid_geometry.dart';

/// Why a string could not be read as a grid.
enum GridProblem {
  /// Not exactly eighty-one characters.
  wrongLength,

  /// Something other than `.` or a digit one to nine.
  unrecognisedCharacter,
}

/// The outcome of reading a grid from its stored form.
///
/// A malformed grid is a value, never an exception: nothing above this layer
/// should have to catch to find out that a pack row was corrupt.
sealed class GridParseResult {
  const GridParseResult();
}

final class ValidGrid extends GridParseResult {
  const ValidGrid(this.grid);

  final Grid grid;
}

final class InvalidGrid extends GridParseResult {
  const InvalidGrid({
    required this.problem,
    required this.description,
    this.position,
  });

  final GridProblem problem;

  /// Plain description of what was wrong, for a log or a developer tool. Not
  /// player-facing copy.
  final String description;

  /// Where the offending character sat, when there was one.
  final int? position;
}

/// An immutable 9x9 grid of digits.
///
/// Cells are indexed 0..80, row-major; a blank cell holds [blank]. Nothing here
/// knows how a grid is drawn, saved, or graded.
final class Grid {
  const Grid._(this._digits);

  /// The blank cell. Distinct from any digit, and rendered as `.`.
  static const int blank = 0;

  /// The character a blank takes in the stored eighty-one-character form.
  static const String blankCharacter = '.';

  static final Grid empty = Grid._(
    List<int>.unmodifiable(List<int>.filled(GridGeometry.cellCount, blank)),
  );

  final List<int> _digits;

  /// Read a grid from the eighty-one-character form `add-persistence-layer`
  /// stores: one character per cell, `.` for empty.
  static GridParseResult parse(String source) {
    if (source.length != GridGeometry.cellCount) {
      return InvalidGrid(
        problem: GridProblem.wrongLength,
        description:
            'a grid is ${GridGeometry.cellCount} characters, not '
            '${source.length}',
      );
    }
    final digits = List<int>.filled(GridGeometry.cellCount, blank);
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      final character = source[cell];
      if (character == blankCharacter) continue;
      final digit = int.tryParse(character);
      if (digit == null ||
          digit < GridGeometry.minDigit ||
          digit > GridGeometry.maxDigit) {
        return InvalidGrid(
          problem: GridProblem.unrecognisedCharacter,
          description:
              "'$character' at $cell is neither a digit one to nine nor "
              "'$blankCharacter'",
          position: cell,
        );
      }
      digits[cell] = digit;
    }
    return ValidGrid(Grid._(List<int>.unmodifiable(digits)));
  }

  /// Build from digits already known good — 81 entries, 0 for blank.
  static Grid fromDigits(List<int> digits) {
    assert(digits.length == GridGeometry.cellCount);
    return Grid._(List<int>.unmodifiable(digits));
  }

  int digitAt(int cell) => _digits[cell];

  bool isEmptyAt(int cell) => _digits[cell] == blank;

  int get filledCount => _digits.where((digit) => digit != blank).length;

  /// The same grid with [digit] in [cell]. The original is untouched.
  Grid withDigit(int cell, int digit) {
    if (_digits[cell] == digit) return this;
    final digits = List<int>.of(_digits);
    digits[cell] = digit;
    return Grid._(List<int>.unmodifiable(digits));
  }

  Grid cleared(int cell) => withDigit(cell, blank);

  /// The digits still possible in [cell]: one to nine, less every digit already
  /// placed in one of its peers. A filled cell offers none.
  Candidates candidatesAt(int cell) {
    if (_digits[cell] != blank) return Candidates.none;
    var mask = Candidates.all.mask;
    for (final peer in GridGeometry.peersOf(cell)) {
      final digit = _digits[peer];
      if (digit != blank) mask &= ~(1 << (digit - 1));
    }
    return Candidates(mask);
  }

  /// Every cell holds a digit. Says nothing about whether they are the right
  /// ones — see [isComplete].
  bool get isFull => !_digits.contains(blank);

  /// Every cell holds a digit and no **unit** repeats one.
  bool get isComplete {
    if (!isFull) return false;
    for (final unit in GridGeometry.allUnits) {
      var seen = 0;
      for (final cell in unit.cells) {
        final bit = 1 << (_digits[cell] - 1);
        if (seen & bit != 0) return false;
        seen |= bit;
      }
    }
    return true;
  }

  /// The stored eighty-one-character form.
  String toStorageString() {
    final buffer = StringBuffer();
    for (final digit in _digits) {
      buffer.write(digit == blank ? blankCharacter : '$digit');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Grid) return false;
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      if (_digits[cell] != other._digits[cell]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_digits);

  @override
  String toString() => 'Grid(${toStorageString()})';
}
