import 'package:eureka/domain/models/progress.dart';
import 'package:eureka/domain/models/rank.dart';
import 'package:eureka/domain/services/mastery_engine.dart';
import 'package:eureka/domain/services/progress_engine.dart';
import 'package:eureka/domain/services/streak_engine.dart';
import 'package:eureka/domain/services/xp_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Jour civil de référence des tests.
final DateTime today = DateTime(2026, 3, 15);

DayKey daysAgo(int n) => dayKeyOf(today.subtract(Duration(days: n)));

void main() {
  group('XpEngine', () {
    test('récompense davantage une réussite du premier coup', () {
      expect(
        XpEngine.xpForAnswer(firstTry: true),
        greaterThan(XpEngine.xpForAnswer(firstTry: false)),
      );
    });

    test('une erreur rapporte quand même des XP', () {
      expect(XpEngine.xpForAnswer(firstTry: false), greaterThan(0));
    });

    test('la progression de rang reste bornée entre 0 et 1', () {
      for (final int xp in <int>[0, 1, 149, 150, 2499, 100000]) {
        expect(XpEngine.rankProgress(xp), inInclusiveRange(0.0, 1.0));
      }
    });

    test('le dernier rang n\'a pas de suivant', () {
      expect(XpEngine.xpToNextRank(999999), isNull);
      expect(Rank.forXp(999999), Rank.genie);
    });

    test('le rang suit les seuils déclarés', () {
      expect(Rank.forXp(0), Rank.curieux);
      expect(Rank.forXp(Rank.explorateur.requiredXp), Rank.explorateur);
      expect(Rank.forXp(Rank.explorateur.requiredXp - 1), Rank.curieux);
    });
  });

  group('StreakEngine', () {
    StreakInfo compute(Map<DayKey, int> daily, {int goal = 20}) =>
        StreakEngine.compute(dailyXp: daily, dailyGoalXp: goal, today: today);

    test('aucune activité, aucune série', () {
      expect(compute(const <DayKey, int>{}).current, 0);
    });

    test('compte les jours consécutifs atteignant l\'objectif', () {
      final StreakInfo info = compute(<DayKey, int>{
        daysAgo(0): 25,
        daysAgo(1): 20,
        daysAgo(2): 40,
      });
      expect(info.current, 3);
      expect(info.goalMetToday, isTrue);
    });

    test('un jour en dessous de l\'objectif ne compte pas', () {
      expect(compute(<DayKey, int>{daysAgo(0): 10, daysAgo(1): 30}).current, 1);
    });

    test('la journée en cours ne casse pas la série', () {
      final StreakInfo info = compute(<DayKey, int>{
        daysAgo(1): 30,
        daysAgo(2): 30,
      });
      expect(info.current, 2);
      expect(info.goalMetToday, isFalse);
    });

    test('un seul jour manqué est pardonné', () {
      final StreakInfo info = compute(<DayKey, int>{
        daysAgo(0): 20,
        // daysAgo(1) manquant : jour de grâce.
        daysAgo(2): 20,
        daysAgo(3): 20,
      });
      expect(info.current, 3);
      expect(info.freezeUsed, isTrue);
    });

    test('deux jours manqués cassent la série', () {
      final StreakInfo info = compute(<DayKey, int>{
        daysAgo(0): 20,
        daysAgo(3): 20,
        daysAgo(4): 20,
      });
      expect(info.current, 1);
    });

    test('un objectif nul ne produit pas de série', () {
      expect(compute(<DayKey, int>{daysAgo(0): 50}, goal: 0).current, 0);
    });
  });

  group('MasteryEngine', () {
    LessonRecord record({
      required int correct,
      required int total,
      int days = 1,
    }) => LessonRecord(
      attempts: 1,
      bestCorrect: correct,
      bestTotal: total,
      firstDay: daysAgo(0),
      lastDay: daysAgo(0),
      distinctDays: days,
    );

    test('aucune étoile tant que tout n\'est pas terminé', () {
      expect(
        MasteryEngine.stars(
          records: <String, LessonRecord>{'a': record(correct: 5, total: 5)},
          lessonCount: 2,
        ),
        0,
      );
    });

    test('une étoile pour un chapitre terminé sans précision', () {
      expect(
        MasteryEngine.stars(
          records: <String, LessonRecord>{'a': record(correct: 1, total: 5)},
          lessonCount: 1,
        ),
        1,
      );
    });

    test('deux étoiles à partir de 80 % de justesse', () {
      expect(
        MasteryEngine.stars(
          records: <String, LessonRecord>{'a': record(correct: 4, total: 5)},
          lessonCount: 1,
        ),
        2,
      );
    });

    test('la troisième étoile exige un retour un autre jour', () {
      final Map<String, LessonRecord> parfaitEnUnJour = <String, LessonRecord>{
        'a': record(correct: 5, total: 5),
      };
      expect(
        MasteryEngine.stars(records: parfaitEnUnJour, lessonCount: 1),
        2,
        reason: 'un sans-faute en une seule séance ne vaut que deux étoiles',
      );
      expect(
        MasteryEngine.stars(
          records: <String, LessonRecord>{
            'a': record(correct: 5, total: 5, days: 2),
          },
          lessonCount: 1,
        ),
        3,
      );
    });

    test('conseille la première leçon non terminée', () {
      expect(
        MasteryEngine.nextLessonId(
          lessonIds: <String>['a', 'b', 'c'],
          records: <String, LessonRecord>{'a': record(correct: 1, total: 1)},
        ),
        'b',
      );
    });
  });

  group('ProgressEngine', () {
    test('cumule les XP et enregistre la leçon', () {
      const ProgressState initial = ProgressState();
      final ProgressState after = ProgressEngine.applyOutcome(
        initial,
        const LessonOutcome(
          chapterId: 'ch',
          lessonId: 'le',
          correct: 4,
          total: 5,
          xpEarned: 44,
          firstTimeCompleted: true,
        ),
        now: today,
      );

      expect(after.totalXp, 44);
      expect(after.xpOn(dayKeyOf(today)), 44);
      expect(after.recordFor('ch', 'le').isCompleted, isTrue);
      expect(after.recordFor('ch', 'le').bestAccuracy, closeTo(0.8, 1e-9));
      expect(initial.totalXp, 0, reason: 'l\'état initial reste intact');
    });

    test('met à jour la meilleure série', () {
      ProgressState state = const ProgressState();
      for (int i = 3; i >= 0; i--) {
        state = ProgressEngine.applyOutcome(
          state,
          const LessonOutcome(
            chapterId: 'ch',
            lessonId: 'le',
            correct: 5,
            total: 5,
            xpEarned: 30,
            firstTimeCompleted: false,
          ),
          now: today.subtract(Duration(days: i)),
        );
      }
      expect(state.bestStreak, 4);
    });

    test('ne garde pas un historique quotidien illimité', () {
      ProgressState state = ProgressState(
        dailyXp: <DayKey, int>{
          for (int i = 0; i < ProgressEngine.retainedDays + 50; i++)
            dayKeyOf(today.subtract(Duration(days: i))): 5,
        },
      );
      state = ProgressEngine.applyOutcome(
        state,
        const LessonOutcome(
          chapterId: 'ch',
          lessonId: 'le',
          correct: 1,
          total: 1,
          xpEarned: 10,
          firstTimeCompleted: true,
        ),
        now: today,
      );
      expect(
        state.dailyXp.length,
        lessThanOrEqualTo(ProgressEngine.retainedDays + 1),
      );
    });
  });

  group('Sérialisation', () {
    test('un aller-retour JSON conserve la progression', () {
      final ProgressState state = ProgressEngine.applyOutcome(
        const ProgressState(
          profile: LearnerProfile(firstName: 'Inès', onboarded: true),
        ),
        const LessonOutcome(
          chapterId: 'ch',
          lessonId: 'le',
          correct: 3,
          total: 4,
          xpEarned: 34,
          firstTimeCompleted: true,
        ),
        now: today,
      );

      final ProgressState restored = ProgressState.fromJson(state.toJson());

      expect(restored.totalXp, state.totalXp);
      expect(restored.profile.firstName, 'Inès');
      expect(restored.profile.onboarded, isTrue);
      expect(restored.recordFor('ch', 'le').bestCorrect, 3);
      expect(restored.dailyXp, state.dailyXp);
    });

    test('des données corrompues donnent un état vide, pas une exception', () {
      final ProgressState state = ProgressState.fromJson(<String, Object?>{
        'totalXp': 'beaucoup',
        'lessons': 'cassé',
        'dailyXp': 42,
      });
      expect(state.totalXp, 0);
      expect(state.lessons, isEmpty);
    });
  });
}
