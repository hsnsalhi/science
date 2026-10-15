/// Calculs d'affichage combinant contenu et progression.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/content/content_catalog.dart';
import '../domain/models/chapter.dart';
import '../domain/models/education_level.dart';
import '../domain/models/lesson.dart';
import '../domain/models/progress.dart';
import '../domain/services/mastery_engine.dart';
import 'providers.dart';

/// Chapitre et leçon proposés en reprise sur l'accueil.
class NextStep {
  const NextStep({
    required this.chapter,
    required this.lesson,
    required this.isReview,
  });

  final Chapter chapter;
  final Lesson lesson;

  /// `true` s'il s'agit d'une révision (tout est déjà terminé une fois).
  final bool isReview;
}

/// Avancement d'un chapitre pour l'élève.
class ChapterProgressView {
  const ChapterProgressView({
    required this.completion,
    required this.stars,
    required this.nextLessonId,
  });

  /// Part des leçons terminées, de 0 à 1.
  final double completion;

  /// Étoiles de maîtrise.
  final int stars;

  /// Prochaine leçon conseillée, ou `null` si tout est terminé.
  final String? nextLessonId;

  static const ChapterProgressView empty = ChapterProgressView(
    completion: 0,
    stars: 0,
    nextLessonId: null,
  );
}

/// Avancement d'un chapitre.
ChapterProgressView chapterProgressOf(Chapter chapter, ProgressState progress) {
  if (chapter.lessons.isEmpty) return ChapterProgressView.empty;
  final Map<String, LessonRecord> records = progress.recordsForChapter(
    chapter.id,
  );
  return ChapterProgressView(
    completion: MasteryEngine.completion(
      records: records,
      lessonCount: chapter.lessons.length,
    ),
    stars: MasteryEngine.stars(
      records: records,
      lessonCount: chapter.lessons.length,
    ),
    nextLessonId: MasteryEngine.nextLessonId(
      lessonIds: chapter.lessons.map((Lesson l) => l.id).toList(),
      records: records,
    ),
  );
}

/// Part des chapitres d'une matière terminés, pour un niveau donné.
double subjectCompletion(
  ContentCatalog catalog,
  ProgressState progress,
  String subjectId,
  EducationLevel level,
) {
  final List<Chapter> chapters = catalog
      .chaptersOf(subjectId, level)
      .where((Chapter c) => c.isPlayable)
      .toList(growable: false);
  if (chapters.isEmpty) return 0;
  final double sum = chapters.fold<double>(
    0,
    (double acc, Chapter c) => acc + chapterProgressOf(c, progress).completion,
  );
  return sum / chapters.length;
}

/// Prochaine étape conseillée sur l'accueil.
///
/// On suit l'ordre du programme : premier chapitre du niveau comportant une
/// leçon jamais terminée. Quand tout a été vu, on propose la première leçon
/// qui n'est pas encore parfaite — une révision, pas une impasse.
final Provider<NextStep?> nextStepProvider = Provider<NextStep?>((Ref ref) {
  final ContentCatalog catalog = ref.watch(contentCatalogProvider);
  final ProgressState progress = ref.watch(progressProvider);
  final List<Chapter> chapters = catalog.playableChapters(
    progress.profile.level,
  );
  if (chapters.isEmpty) return null;

  for (final Chapter chapter in chapters) {
    for (final Lesson lesson in chapter.lessons) {
      if (!progress.recordFor(chapter.id, lesson.id).isCompleted) {
        return NextStep(chapter: chapter, lesson: lesson, isReview: false);
      }
    }
  }
  for (final Chapter chapter in chapters) {
    for (final Lesson lesson in chapter.lessons) {
      if (!progress.recordFor(chapter.id, lesson.id).isPerfect) {
        return NextStep(chapter: chapter, lesson: lesson, isReview: true);
      }
    }
  }
  final Chapter first = chapters.first;
  return NextStep(chapter: first, lesson: first.lessons.first, isReview: true);
});
