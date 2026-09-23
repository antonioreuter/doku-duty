import 'package:flutter/material.dart';

import '../../design_system/presentation/doku_colours.dart';
import '../../design_system/presentation/doku_type.dart';
import '../../puzzle_engine/domain/technique.dart';
import '../../technique_tutorials/domain/lesson_catalogue.dart';
import '../data/statistics_repository.dart';

/// Lifetime and per-technique statistics.
///
/// **Read, never recounted.** Every number here comes from the counters
/// `rank_progression` writes at the moment of a **solve record**. The
/// **cabinet** keeps none of its own, so it and the rest of the app cannot
/// disagree about what the player has done.
class StatisticsPanel extends StatelessWidget {
  const StatisticsPanel({required this.statistics, super.key});

  final CabinetStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('cabinet-statistics'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Statistics', style: TypeRole.body.style),
        const SizedBox(height: 8),
        _Line(
          id: 'puzzles-solved',
          label: 'Puzzles solved',
          value: '${statistics.puzzlesSolved}',
        ),
        _Line(
          id: 'perfect-solves',
          label: 'Solved with no mistakes',
          value: '${statistics.perfectSolves}',
        ),
        _Line(
          id: 'play-time',
          label: 'Time at the desk',
          value: _hours(statistics.totalPlayTime),
        ),
        const SizedBox(height: 12),
        Text('By technique', style: TypeRole.body.style),
        const SizedBox(height: 8),
        for (final technique in Technique.values)
          _Line(
            id: 'technique-${technique.name}',
            label: _nameOf(technique),
            // Zero is stated rather than hidden. A technique the player has
            // not met yet is a thing to meet, and a gap in a list of numbers
            // reads as a number that failed to load.
            value: '${statistics.countFor(technique)}',
          ),
      ],
    );
  }

  /// The technique's name, taken from the **lesson** that teaches it.
  ///
  /// **Not a second list.** `lesson_catalogue.dart` already names every
  /// technique for the player, and a separate set of names here would drift
  /// from it — the **cabinet** would call something a "naked pair" while the
  /// **lesson** teaching it called it something else. Full house and naked
  /// single have no **lesson** on purpose (D-106), so those fall back to the
  /// identifier split into words.
  static String _nameOf(Technique technique) {
    for (final lesson in lessonCatalogue) {
      if (lesson.technique == technique) return lesson.title;
    }
    return _humanised(technique.name);
  }

  static String _humanised(String camel) {
    final words = camel.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => ' ${m[0]!.toLowerCase()}',
    );
    return words[0].toUpperCase() + words.substring(1);
  }

  static String _hours(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final hours = d.inMinutes ~/ 60;
    final minutes = d.inMinutes % 60;
    return minutes == 0 ? '$hours h' : '$hours h $minutes min';
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.id, required this.label, required this.value});

  final String id;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: TypeRole.label.style.copyWith(color: DokuColours.inkSoft),
    );
    final valueText = Text(value, style: TypeRole.label.style);
    // Above 2x the value moves under its label, the threshold the navigation
    // uses. Side by side, "Time at the desk" and its hours overflow the
    // smallest phone the app targets (D-84) at 4x.
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 2;

    return Semantics(
      // Said as one statement, so a screen reader gets the number attached to
      // what it counts rather than a column of bare figures.
      label: '$label, $value',
      // Its own node, for the same reason as a shelf entry: the panel is one
      // Column, and the statistics would otherwise be read as one run-on line.
      container: true,
      excludeSemantics: true,
      child: Padding(
        key: ValueKey<String>('cabinet-stat-$id'),
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[labelText, valueText],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: labelText),
                  const SizedBox(width: 12),
                  valueText,
                ],
              ),
      ),
    );
  }
}
