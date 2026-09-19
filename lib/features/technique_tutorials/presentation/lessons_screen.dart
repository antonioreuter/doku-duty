import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/presentation/doku_type.dart';
import '../../design_system/presentation/paper_grain.dart';
import '../application/lesson_providers.dart';
import '../domain/lesson.dart';
import '../domain/lesson_catalogue.dart';
import 'lesson_view.dart';

/// Every **lesson**, replayable.
///
/// **Reparented by change 16.** `docs/SPEC.md` §5.1 puts this in the cabinet,
/// which does not exist yet; it lives behind a row on the settings screen until
/// it does. Everything that decides what is in the list is here rather than in
/// the screen around it, so `add-trophy-cabinet` can adopt this widget whole
/// instead of rebuilding it.
class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(seenLessonsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Lessons', style: TypeRole.screenTitle.style)),
      body: PaperGrain(
        child: ListView(
          children: <Widget>[
            for (final lesson in lessonCatalogue)
              ListTile(
                key: ValueKey<String>('lesson-row-${lesson.id}'),
                title: Text(lesson.title, style: TypeRole.body.style),
                // "Not yet seen", never "locked" — nothing here is withheld,
                // and a player can read any **lesson** at any time, including
                // for a technique they have not met (constraint 1).
                subtitle: Text(
                  (seen.value ?? const <String>{}).contains(lesson.id)
                      ? 'Seen'
                      : 'Not yet seen',
                  style: TypeRole.label.style,
                ),
                onTap: () => _replay(context, ref, lesson),
              ),
          ],
        ),
      ),
    );
  }

  void _replay(BuildContext context, WidgetRef ref, Lesson lesson) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LessonView(
          lesson: lesson,
          onDone: ({required bool skipped}) async {
            // Seen either way, exactly as a **lesson** that fired on its own.
            // Seen is a fact rather than a count, so replaying one already seen
            // writes the same row again and changes nothing — and no
            // **technique unlock**, counter, **rank** or statistic is touched
            // from here at all.
            await ref.read(lessonRepositoryProvider).markSeen(lesson.id);
            ref.invalidate(seenLessonsProvider);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
