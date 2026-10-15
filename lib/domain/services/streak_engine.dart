/// Calcul des séries de jours d'apprentissage.
library;

import '../models/progress.dart';

/// Résultat du calcul de série.
class StreakInfo {
  const StreakInfo({
    required this.current,
    required this.goalMetToday,
    required this.freezeUsed,
  });

  /// Longueur de la série en cours, en jours.
  final int current;

  /// `true` si l'objectif quotidien est déjà atteint aujourd'hui.
  final bool goalMetToday;

  /// `true` si la série ne tient que grâce au jour de grâce.
  final bool freezeUsed;

  static const StreakInfo empty = StreakInfo(
    current: 0,
    goalMetToday: false,
    freezeUsed: false,
  );
}

/// Calcule la série de jours consécutifs où l'objectif quotidien est atteint.
abstract final class StreakEngine {
  /// Nombre de jours manqués tolérés dans une même série.
  ///
  /// Un seul jour de grâce, accordé automatiquement et sans rien demander.
  /// L'intention est précise : un enfant qui ne touche pas à l'application le
  /// dimanche ne doit pas perdre trois semaines d'efforts. Au-delà d'un jour,
  /// la série repart — sinon elle ne veut plus rien dire.
  static const int graceDays = 1;

  /// Garde-fou de boucle : on ne remonte jamais plus loin que dix ans.
  static const int _maxLookbackDays = 3650;

  /// Série en cours à la date [today].
  ///
  /// La journée en cours ne casse jamais la série : tant que [today] n'est pas
  /// terminée, un objectif non encore atteint est simplement ignoré.
  static StreakInfo compute({
    required Map<DayKey, int> dailyXp,
    required int dailyGoalXp,
    required DateTime today,
  }) {
    if (dailyXp.isEmpty || dailyGoalXp <= 0) return StreakInfo.empty;

    bool reached(DateTime day) => (dailyXp[dayKeyOf(day)] ?? 0) >= dailyGoalXp;

    final DateTime startOfToday = DateTime(today.year, today.month, today.day);
    final bool goalMetToday = reached(startOfToday);

    // Jour le plus ancien connu : au-delà, il n'y a rien à compter.
    DateTime oldest = startOfToday;
    for (final DayKey key in dailyXp.keys) {
      final DateTime? day = parseDayKey(key);
      if (day != null && day.isBefore(oldest)) oldest = day;
    }

    int streak = 0;
    int graceLeft = graceDays;
    bool freezeUsed = false;
    DateTime cursor = goalMetToday
        ? startOfToday
        : startOfToday.subtract(const Duration(days: 1));

    for (int guard = 0; guard < _maxLookbackDays; guard++) {
      if (cursor.isBefore(oldest)) break;
      if (reached(cursor)) {
        streak++;
      } else if (graceLeft > 0) {
        graceLeft--;
        freezeUsed = true;
      } else {
        break;
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Une série qui ne reposerait que sur le jour de grâce n'existe pas.
    if (streak == 0) {
      return StreakInfo(
        current: 0,
        goalMetToday: goalMetToday,
        freezeUsed: false,
      );
    }
    return StreakInfo(
      current: streak,
      goalMetToday: goalMetToday,
      freezeUsed: freezeUsed,
    );
  }
}
