import 'package:eureka/data/content/content_catalog.dart';
import 'package:eureka/data/content/content_loader.dart';
import 'package:eureka/design_system/figures/figure_registry.dart';
import 'package:eureka/domain/models/chapter.dart';
import 'package:eureka/domain/models/education_level.dart';
import 'package:eureka/domain/models/lesson.dart';
import 'package:eureka/domain/models/question.dart';
import 'package:eureka/domain/models/subject.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie le contenu réellement embarqué dans l'application.
///
/// Ces tests sont le filet de sécurité de l'écriture pédagogique : toute
/// coquille dans un fichier JSON (champ oublié, figure inexistante,
/// identifiant en double) fait échouer la suite avant d'atteindre un élève.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;

  setUpAll(() async {
    catalog = await ContentLoader().load();
  });

  test('le catalogue se charge sans erreur', () {
    expect(catalog.subjects, isNotEmpty);
    expect(catalog.chapters, isNotEmpty);
  });

  test('les quatre matières annoncées sont présentes', () {
    expect(catalog.subjects.map((Subject s) => s.id).toSet(), <String>{
      'maths',
      'physique-chimie',
      'informatique',
      'svt',
    });
  });

  test('chaque matière couvre les quatre niveaux', () {
    for (final Subject subject in catalog.subjects) {
      for (final EducationLevel level in EducationLevel.values) {
        expect(
          catalog.chaptersOf(subject.id, level),
          isNotEmpty,
          reason: '${subject.name} n\'annonce rien en ${level.label}',
        );
      }
    }
  });

  test('les identifiants de chapitre sont uniques', () {
    final Set<String> seen = <String>{};
    for (final Chapter chapter in catalog.chapters) {
      expect(seen.add(chapter.id), isTrue, reason: 'doublon ${chapter.id}');
    }
  });

  test('au moins un chapitre est entièrement jouable', () {
    expect(catalog.chapters.where((Chapter c) => c.isPlayable), isNotEmpty);
  });

  group('Chapitres jouables', () {
    test('ont des leçons, des cartes ou des questions, et des XP', () {
      for (final Chapter chapter in catalog.chapters.where(
        (Chapter c) => c.isPlayable,
      )) {
        expect(chapter.lessons, isNotEmpty, reason: chapter.id);
        expect(chapter.totalXp, greaterThan(0), reason: chapter.id);
        for (final Lesson lesson in chapter.lessons) {
          expect(
            lesson.cards.isNotEmpty || lesson.questions.isNotEmpty,
            isTrue,
            reason: '${chapter.id}/${lesson.id}',
          );
          expect(lesson.xpReward, greaterThan(0));
          expect(lesson.estimatedMinutes, greaterThan(0));
        }
      }
    });

    test('les identifiants de leçon sont uniques dans leur chapitre', () {
      for (final Chapter chapter in catalog.chapters) {
        final Set<String> ids = <String>{};
        for (final Lesson lesson in chapter.lessons) {
          expect(ids.add(lesson.id), isTrue, reason: chapter.id);
        }
      }
    });

    test('les identifiants de question sont uniques dans leur leçon', () {
      for (final Chapter chapter in catalog.chapters) {
        for (final Lesson lesson in chapter.lessons) {
          final Set<String> ids = <String>{};
          for (final Question question in lesson.questions) {
            expect(
              ids.add(question.id),
              isTrue,
              reason: '${chapter.id}/${lesson.id}',
            );
          }
        }
      }
    });

    test('chaque question porte une explication utile', () {
      for (final Chapter chapter in catalog.chapters) {
        for (final Lesson lesson in chapter.lessons) {
          for (final Question question in lesson.questions) {
            expect(
              question.explanation.trim().length,
              greaterThan(20),
              reason:
                  'explication trop courte : '
                  '${chapter.id}/${lesson.id}/${question.id}',
            );
          }
        }
      }
    });

    test('chaque question affiche une solution lisible', () {
      for (final Chapter chapter in catalog.chapters) {
        for (final Lesson lesson in chapter.lessons) {
          for (final Question question in lesson.questions) {
            expect(question.solutionLabel.trim(), isNotEmpty);
          }
        }
      }
    });
  });

  test('toute figure citée existe dans l\'annuaire', () {
    final Set<String> cited = <String>{};
    for (final Chapter chapter in catalog.chapters) {
      for (final Lesson lesson in chapter.lessons) {
        for (final LessonCard card in lesson.cards) {
          if (card.figureId != null) cited.add(card.figureId!);
        }
        for (final Question question in lesson.questions) {
          if (question.figureId != null) cited.add(question.figureId!);
        }
      }
    }
    for (final String id in cited) {
      expect(
        FigureRegistry.contains(id),
        isTrue,
        reason: 'figure "$id" citée par le contenu mais absente du registre',
      );
    }
    expect(cited, isNotEmpty, reason: 'aucune figure interactive utilisée');
  });

  group('Chapitre complet : le théorème de Pythagore', () {
    late Chapter pythagore;

    setUpAll(() {
      pythagore = catalog.chapterById(
        'maths-college-le-theoreme-de-pythagore',
      )!;
    });

    test('propose un parcours de bout en bout', () {
      expect(pythagore.isPlayable, isTrue);
      expect(pythagore.lessons.length, greaterThanOrEqualTo(4));
      expect(pythagore.objectives, isNotEmpty);
    });

    test('enchaîne cours, entraînement et défi', () {
      final Set<LessonKind> kinds = pythagore.lessons
          .map((Lesson l) => l.kind)
          .toSet();
      expect(
        kinds,
        containsAll(<LessonKind>[
          LessonKind.cours,
          LessonKind.entrainement,
          LessonKind.defi,
        ]),
      );
    });

    test('exerce les sept types de question', () {
      final Set<QuestionKind> kinds = <QuestionKind>{
        for (final Lesson lesson in pythagore.lessons)
          for (final Question question in lesson.questions) question.kind,
      };
      expect(kinds, containsAll(QuestionKind.values));
    });

    test('les réponses numériques respectent bien Pythagore', () {
      // Un garde-fou de contenu : si quelqu'un modifie un énoncé 3-4-5 sans
      // recalculer la réponse, ce test tombe.
      const Map<String, double> expected = <String, double>{
        'theoreme/q3': 5, // côtés 3 et 4
        'calculer/q1': 10, // côtés 6 et 8
        'calculer/q2': 12, // hypoténuse 13, côté 5
        'calculer/q4': 100, // écran 80 × 60
        'calculer/q5': 1.41, // côtés 1 et 1, soit la racine de 2
        'reciproque/q3': 6, // échelle 6,5 m à 2,5 m du mur
      };
      int checked = 0;
      for (final Lesson lesson in pythagore.lessons) {
        for (final Question question in lesson.questions) {
          if (question is! NumericQuestion) continue;
          final double? value = expected['${lesson.id}/${question.id}'];
          expect(
            value,
            isNotNull,
            reason:
                'réponse numérique non vérifiée : '
                '${lesson.id}/${question.id}',
          );
          expect(
            question.expected,
            closeTo(value!, question.tolerance),
            reason: '${lesson.id}/${question.id}',
          );
          checked++;
        }
      }
      expect(checked, expected.length);
    });
  });
}
