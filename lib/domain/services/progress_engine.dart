/// Application d'un résultat de leçon à l'état de progression.
library;

import '../models/progress.dart';
import 'streak_engine.dart';

/// Transitions pures de [ProgressState].
///
/// Aucune écriture disque ici : le dépôt appelle ces fonctions puis persiste.
/// Conséquence pratique, toute la logique de progression se teste sans
/// `SharedPreferences` ni widget.
abstract final class ProgressEngine {
  /// Nombre de jours d'historique quotidien conservés.
  ///
  /// L'historique quotidien sert aux séries et au graphique d'activité ; sans
  /// borne, il grossirait indéfiniment dans le stockage local.
  static const int retainedDays = 400;

  /// Enregistre une leçon terminée.
  static ProgressState applyOutcome(
    ProgressState state,
    LessonOutcome outcome, {
    required DateTime now,
  }) {
    final DayKey day = dayKeyOf(now);
    final String key = lessonKey(outcome.chapterId, outcome.lessonId);

    final Map<String, LessonRecord> lessons = Map<String, LessonRecord>.of(
      state.lessons,
    );
    lessons[key] = state
        .recordFor(outcome.chapterId, outcome.lessonId)
        .register(correct: outcome.correct, total: outcome.total, day: day);

    final Map<DayKey, int> dailyXp = Map<DayKey, int>.of(state.dailyXp);
    dailyXp[day] = (dailyXp[day] ?? 0) + outcome.xpEarned;

    final ProgressState updated = state.copyWith(
      totalXp: state.totalXp + outcome.xpEarned,
      lessons: lessons,
      dailyXp: _prune(dailyXp, now),
    );

    final StreakInfo streak = StreakEngine.compute(
      dailyXp: updated.dailyXp,
      dailyGoalXp: updated.profile.dailyGoalXp,
      today: now,
    );
    return streak.current > updated.bestStreak
        ? updated.copyWith(bestStreak: streak.current)
        : updated;
  }

  /// Supprime les jours plus vieux que [retainedDays].
  static Map<DayKey, int> _prune(Map<DayKey, int> dailyXp, DateTime now) {
    if (dailyXp.length <= retainedDays) return dailyXp;
    final DateTime limit = now.subtract(const Duration(days: retainedDays));
    return <DayKey, int>{
      for (final MapEntry<DayKey, int> e in dailyXp.entries)
        if (!(parseDayKey(e.key)?.isBefore(limit) ?? true)) e.key: e.value,
    };
  }
}
