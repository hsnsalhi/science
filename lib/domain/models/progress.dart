/// État de progression de l'élève, intégralement local à l'appareil.
library;

import 'education_level.dart';
import 'rank.dart';

/// Jour civil, au format `AAAA-MM-JJ`.
///
/// Les séries et objectifs quotidiens raisonnent en jours civils locaux, pas
/// en instants : terminer une leçon à 23 h 50 puis une autre à 0 h 10 doit
/// compter pour deux jours.
typedef DayKey = String;

/// Convertit une date en [DayKey].
DayKey dayKeyOf(DateTime date) {
  final String m = date.month.toString().padLeft(2, '0');
  final String d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

/// Analyse un [DayKey]. Renvoie `null` si la chaîne est invalide.
DateTime? parseDayKey(DayKey key) {
  final List<String> parts = key.split('-');
  if (parts.length != 3) return null;
  final int? y = int.tryParse(parts[0]);
  final int? m = int.tryParse(parts[1]);
  final int? d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// Identité et préférences d'apprentissage de l'élève.
///
/// Aucune donnée n'est obligatoire : [firstName] peut rester vide, et il
/// n'existe ni adresse e-mail, ni identifiant, ni date de naissance. C'est
/// l'absence de collecte qui rend l'application utilisable par un enfant sans
/// démarche de consentement.
class LearnerProfile {
  const LearnerProfile({
    this.firstName,
    this.level = EducationLevel.college,
    this.dailyGoalXp = 20,
    this.onboarded = false,
  });

  /// Prénom, purement pour personnaliser l'accueil. Facultatif.
  final String? firstName;

  /// Niveau scolaire choisi : il détermine le contenu mis en avant, sans
  /// jamais interdire l'accès aux autres niveaux.
  final EducationLevel level;

  /// Objectif d'XP quotidien.
  final int dailyGoalXp;

  /// `true` une fois l'onboarding terminé.
  final bool onboarded;

  LearnerProfile copyWith({
    String? firstName,
    EducationLevel? level,
    int? dailyGoalXp,
    bool? onboarded,
    bool clearFirstName = false,
  }) {
    return LearnerProfile(
      firstName: clearFirstName ? null : (firstName ?? this.firstName),
      level: level ?? this.level,
      dailyGoalXp: dailyGoalXp ?? this.dailyGoalXp,
      onboarded: onboarded ?? this.onboarded,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'firstName': firstName,
    'level': level.id,
    'dailyGoalXp': dailyGoalXp,
    'onboarded': onboarded,
  };

  factory LearnerProfile.fromJson(Map<String, Object?> json) {
    final Object? name = json['firstName'];
    final Object? goal = json['dailyGoalXp'];
    return LearnerProfile(
      firstName: name is String && name.isNotEmpty ? name : null,
      level:
          EducationLevel.tryParse(json['level'] as String?) ??
          EducationLevel.college,
      dailyGoalXp: goal is num ? goal.toInt() : 20,
      onboarded: json['onboarded'] == true,
    );
  }
}

/// Historique d'une leçon.
class LessonRecord {
  const LessonRecord({
    this.attempts = 0,
    this.bestCorrect = 0,
    this.bestTotal = 0,
    this.firstDay,
    this.lastDay,
    this.distinctDays = 0,
  });

  /// Nombre de fois où la leçon a été terminée.
  final int attempts;

  /// Meilleur score obtenu : [bestCorrect] bonnes réponses sur [bestTotal].
  final int bestCorrect;
  final int bestTotal;

  /// Premier et dernier jour de pratique.
  final DayKey? firstDay;
  final DayKey? lastDay;

  /// Nombre de jours distincts où la leçon a été travaillée. Sert à la
  /// troisième étoile : on ne maîtrise pas une notion vue une seule fois.
  final int distinctDays;

  /// `true` si la leçon a été terminée au moins une fois.
  bool get isCompleted => attempts > 0;

  /// Meilleure justesse obtenue, de 0 à 1.
  double get bestAccuracy => bestTotal == 0 ? 0 : bestCorrect / bestTotal;

  /// `true` si la leçon a été réussie sans faute.
  bool get isPerfect => bestTotal > 0 && bestCorrect == bestTotal;

  /// Enregistre une nouvelle tentative terminée.
  LessonRecord register({
    required int correct,
    required int total,
    required DayKey day,
  }) {
    final bool better = total > 0 && correct / total > bestAccuracy;
    final bool newDay = lastDay != day;
    return LessonRecord(
      attempts: attempts + 1,
      bestCorrect: better ? correct : bestCorrect,
      bestTotal: better ? total : bestTotal,
      firstDay: firstDay ?? day,
      lastDay: day,
      distinctDays: newDay ? distinctDays + 1 : distinctDays,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'a': attempts,
    'c': bestCorrect,
    't': bestTotal,
    'f': firstDay,
    'l': lastDay,
    'd': distinctDays,
  };

  factory LessonRecord.fromJson(Map<String, Object?> json) {
    int intOf(String key) {
      final Object? value = json[key];
      return value is num ? value.toInt() : 0;
    }

    return LessonRecord(
      attempts: intOf('a'),
      bestCorrect: intOf('c'),
      bestTotal: intOf('t'),
      firstDay: json['f'] as String?,
      lastDay: json['l'] as String?,
      distinctDays: intOf('d'),
    );
  }
}

/// Résultat d'une leçon terminée, transmis à l'enregistrement.
class LessonOutcome {
  const LessonOutcome({
    required this.chapterId,
    required this.lessonId,
    required this.correct,
    required this.total,
    required this.xpEarned,
    required this.firstTimeCompleted,
  });

  final String chapterId;
  final String lessonId;

  /// Bonnes réponses du premier coup.
  final int correct;

  /// Nombre de questions.
  final int total;

  /// XP réellement accordés.
  final int xpEarned;

  /// `true` si c'était la première fois que la leçon était terminée.
  final bool firstTimeCompleted;

  /// Justesse de la session, de 0 à 1.
  double get accuracy => total == 0 ? 0 : correct / total;
}

/// Clé d'une leçon dans [ProgressState.lessons].
String lessonKey(String chapterId, String lessonId) => '$chapterId/$lessonId';

/// Photographie complète de la progression, telle qu'elle est persistée.
class ProgressState {
  const ProgressState({
    this.profile = const LearnerProfile(),
    this.totalXp = 0,
    this.lessons = const <String, LessonRecord>{},
    this.dailyXp = const <DayKey, int>{},
    this.bestStreak = 0,
  });

  final LearnerProfile profile;

  /// Total d'XP cumulés depuis l'installation.
  final int totalXp;

  /// Historique par leçon, indexé par [lessonKey].
  final Map<String, LessonRecord> lessons;

  /// XP gagnés par jour civil. Sert aux séries et au graphique d'activité.
  final Map<DayKey, int> dailyXp;

  /// Plus longue série jamais atteinte.
  final int bestStreak;

  /// Rang courant.
  Rank get rank => Rank.forXp(totalXp);

  /// XP du jour [day].
  int xpOn(DayKey day) => dailyXp[day] ?? 0;

  /// Historique d'une leçon (jamais `null` : un enregistrement vide sinon).
  LessonRecord recordFor(String chapterId, String lessonId) =>
      lessons[lessonKey(chapterId, lessonId)] ?? const LessonRecord();

  /// Historiques des leçons d'un chapitre.
  Map<String, LessonRecord> recordsForChapter(String chapterId) {
    final String prefix = '$chapterId/';
    return <String, LessonRecord>{
      for (final MapEntry<String, LessonRecord> e in lessons.entries)
        if (e.key.startsWith(prefix)) e.key.substring(prefix.length): e.value,
    };
  }

  ProgressState copyWith({
    LearnerProfile? profile,
    int? totalXp,
    Map<String, LessonRecord>? lessons,
    Map<DayKey, int>? dailyXp,
    int? bestStreak,
  }) {
    return ProgressState(
      profile: profile ?? this.profile,
      totalXp: totalXp ?? this.totalXp,
      lessons: lessons ?? this.lessons,
      dailyXp: dailyXp ?? this.dailyXp,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'version': 1,
    'profile': profile.toJson(),
    'totalXp': totalXp,
    'bestStreak': bestStreak,
    'lessons': <String, Object?>{
      for (final MapEntry<String, LessonRecord> e in lessons.entries)
        e.key: e.value.toJson(),
    },
    'dailyXp': dailyXp,
  };

  factory ProgressState.fromJson(Map<String, Object?> json) {
    final Object? rawLessons = json['lessons'];
    final Object? rawDaily = json['dailyXp'];
    final Object? rawProfile = json['profile'];
    final Object? xp = json['totalXp'];
    final Object? best = json['bestStreak'];
    return ProgressState(
      profile: rawProfile is Map
          ? LearnerProfile.fromJson(rawProfile.cast<String, Object?>())
          : const LearnerProfile(),
      totalXp: xp is num ? xp.toInt() : 0,
      bestStreak: best is num ? best.toInt() : 0,
      lessons: rawLessons is Map
          ? <String, LessonRecord>{
              for (final MapEntry<Object?, Object?> e in rawLessons.entries)
                if (e.key is String && e.value is Map)
                  e.key! as String: LessonRecord.fromJson(
                    (e.value! as Map).cast<String, Object?>(),
                  ),
            }
          : const <String, LessonRecord>{},
      dailyXp: rawDaily is Map
          ? <DayKey, int>{
              for (final MapEntry<Object?, Object?> e in rawDaily.entries)
                if (e.key is String && e.value is num)
                  e.key! as String: (e.value! as num).toInt(),
            }
          : const <DayKey, int>{},
    );
  }
}
