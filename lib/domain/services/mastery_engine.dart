/// Maîtrise d'un chapitre, de zéro à trois étoiles.
library;

import '../models/progress.dart';

/// Calcule les étoiles de maîtrise d'un chapitre.
///
/// Le barème encode une intention pédagogique : la troisième étoile ne
/// s'obtient pas en répétant la même leçon dix fois d'affilée, mais en y
/// revenant **un autre jour**. C'est de la révision espacée rendue visible,
/// sans jamais l'imposer.
abstract final class MasteryEngine {
  /// Justesse moyenne exigée pour la deuxième étoile.
  static const double twoStarAccuracy = 0.8;

  /// Justesse moyenne exigée pour la troisième étoile.
  static const double threeStarAccuracy = 0.95;

  /// Jours de pratique distincts exigés pour la troisième étoile.
  static const int threeStarDistinctDays = 2;

  /// Nombre maximal d'étoiles.
  static const int maxStars = 3;

  /// Étoiles obtenues pour un chapitre de [lessonCount] leçons.
  ///
  /// [records] est indexé par identifiant de leçon (sans le chapitre).
  static int stars({
    required Map<String, LessonRecord> records,
    required int lessonCount,
  }) {
    if (lessonCount <= 0) return 0;
    final Iterable<LessonRecord> done = records.values.where(
      (LessonRecord r) => r.isCompleted,
    );
    if (done.length < lessonCount) return 0;

    final double averageAccuracy =
        done.fold<double>(0, (double s, LessonRecord r) => s + r.bestAccuracy) /
        done.length;
    final int bestDistinctDays = done.fold<int>(
      0,
      (int m, LessonRecord r) => r.distinctDays > m ? r.distinctDays : m,
    );

    if (averageAccuracy >= threeStarAccuracy &&
        bestDistinctDays >= threeStarDistinctDays) {
      return 3;
    }
    if (averageAccuracy >= twoStarAccuracy) return 2;
    return 1;
  }

  /// Part du chapitre terminée, de 0 à 1.
  static double completion({
    required Map<String, LessonRecord> records,
    required int lessonCount,
  }) {
    if (lessonCount <= 0) return 0;
    final int done = records.values
        .where((LessonRecord r) => r.isCompleted)
        .length;
    return (done / lessonCount).clamp(0.0, 1.0);
  }

  /// Identifiant de la prochaine leçon conseillée, ou `null` si tout est fait.
  ///
  /// On conseille la première leçon non terminée, dans l'ordre du chapitre.
  /// Ce n'est qu'un conseil : toutes les leçons restent ouvrables.
  static String? nextLessonId({
    required List<String> lessonIds,
    required Map<String, LessonRecord> records,
  }) {
    for (final String id in lessonIds) {
      if (!(records[id]?.isCompleted ?? false)) return id;
    }
    return null;
  }
}
