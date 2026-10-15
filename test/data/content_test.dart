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

  /// Garde-fou d'un chapitre entièrement rédigé.
  ///
  /// Chaque réponse numérique est recalculée à la main dans
  /// [reponsesVerifiees] : si quelqu'un retouche un énoncé sans refaire le
  /// calcul, la suite tombe au lieu de laisser une réponse fausse atteindre
  /// un élève. Une question numérique ajoutée sans être vérifiée fait
  /// également échouer le test — on ne peut pas l'oublier.
  void verifieChapitreRedige(
    String chapterId,
    Map<String, double> reponsesVerifiees,
  ) {
    group('Chapitre rédigé : $chapterId', () {
      late Chapter chapitre;

      setUpAll(() {
        chapitre = catalog.chapterById(chapterId)!;
      });

      test('propose quatre leçons fournies', () {
        expect(chapitre.isPlayable, isTrue);
        expect(chapitre.objectives, isNotEmpty);
        expect(chapitre.lessons.length, greaterThanOrEqualTo(4));
        for (final Lesson lesson in chapitre.lessons) {
          expect(
            lesson.cards.length,
            greaterThanOrEqualTo(4),
            reason: '$chapterId/${lesson.id} : moins de quatre cartes',
          );
          expect(
            lesson.questions.length,
            greaterThanOrEqualTo(4),
            reason: '$chapterId/${lesson.id} : moins de quatre questions',
          );
        }
      });

      test('enchaîne cours, entraînement et défi', () {
        final Set<LessonKind> kinds = chapitre.lessons
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

      test('nomme une erreur classique dans chaque leçon', () {
        for (final Lesson lesson in chapitre.lessons) {
          expect(
            lesson.cards.any((LessonCard c) => c.kind == LessonCardKind.astuce),
            isTrue,
            reason: '$chapterId/${lesson.id} : aucune carte « astuce »',
          );
        }
      });

      test('varie les types d\'exercice', () {
        final Set<QuestionKind> kinds = <QuestionKind>{
          for (final Lesson lesson in chapitre.lessons)
            for (final Question question in lesson.questions) question.kind,
        };
        expect(
          kinds.length,
          greaterThanOrEqualTo(5),
          reason: '$chapterId : seulement ${kinds.length} types d\'exercice',
        );
      });

      test('les réponses numériques ont été recalculées', () {
        int checked = 0;
        for (final Lesson lesson in chapitre.lessons) {
          for (final Question question in lesson.questions) {
            if (question is! NumericQuestion) continue;
            final String key = '${lesson.id}/${question.id}';
            final double? value = reponsesVerifiees[key];
            expect(
              value,
              isNotNull,
              reason: 'réponse numérique non vérifiée : $chapterId/$key',
            );
            expect(
              question.expected,
              closeTo(value!, question.tolerance),
              reason: '$chapterId/$key',
            );
            checked++;
          }
        }
        expect(
          checked,
          reponsesVerifiees.length,
          reason:
              '$chapterId : une réponse vérifiée ne correspond à '
              'aucune question',
        );
      });
    });
  }

  verifieChapitreRedige('maths-college-les-fractions', const <String, double>{
    'ecrire/q4': 12, // les 2/5 de 30 élèves
    'ecrire/q6': 1.75, // 7 ÷ 4
    'additionner/q5': 1.25, // 3/4 L versés avec 1/2 L
    'additionner/q6': 0.5, // 5/6 − 2/6 = 3/6
    'multiplier/q2': 27, // les 3/5 de 45 billes
    'multiplier/q5': 90, // 240 pages moins les 5/8 déjà lues
  });

  verifieChapitreRedige(
    'maths-college-les-nombres-relatifs',
    const <String, double>{
      'reperer/q4': 10, // de −6 °C à 4 °C
      'additionner/q1': -8, // (−5) + (−3)
      'additionner/q2': -5, // (−8) + 3
      'additionner/q6': 4, // niveau −3, sept étages plus haut
      'enchainer/q1': -1, // 7 − 9 + 4 − 3
      'enchainer/q2': -4, // (−6) + 9 − (−4) − 11
      'enchainer/q6': 45, // −45 + 120 − 30
      'multiplier/q1': 42, // (−6) × (−7)
      'multiplier/q2': -40, // trois facteurs négatifs
      'multiplier/q5': -8, // (−72) ÷ 9
    },
  );

  verifieChapitreRedige(
    'maths-college-la-proportionnalite',
    const <String, double>{
      'reconnaitre/q3': 2.5, // 10 € pour 4 kg
      'calculer/q1': 8.4, // 6 € pour 5 cahiers, puis 7 cahiers
      'calculer/q2': 27.5, // 7,50 € pour 3 kg, puis 11 kg
      'calculer/q6': 750, // 450 g pour 6 personnes, puis 10
      'pourcentages/q1': 9, // 20 % de 45
      'pourcentages/q2': 56, // 80 € remisés de 30 %
      'pourcentages/q3': 48, // 12 sur 25
      'pourcentages/q6': 276, // 240 € augmentés de 15 %
      'problemes/q1': 80, // 240 km en 3 h
      'problemes/q2': 18, // 24 km/h pendant 0,75 h
      'problemes/q3': 8, // 4 cm au 1/200, en mètres
    },
  );

  verifieChapitreRedige(
    'maths-college-les-equations-du-premier-degre',
    const <String, double>{
      'comprendre/q3': 5, // x + 7 = 12
      'resoudre/q1': 5, // 3x + 5 = 20
      'resoudre/q2': 4, // 7x − 4 = 24
      'resoudre/q5': -4, // 2x + 9 = 1
      'entrainer/q1': 5, // 5x + 3 = 2x + 18
      'entrainer/q2': 7, // 3(x − 2) = 15
      'entrainer/q3': 2, // −3x + 7 = 1
      'entrainer/q6': 4, // 6x − 5 = 3x + 7
      'mise-en-equation/q1': 35, // x + 12 = 47
      'mise-en-equation/q2': 8, // largeur, périmètre 46 et écart 7
      'mise-en-equation/q3': 15, // longueur du même rectangle
      'mise-en-equation/q5': 36, // Léa, triple de Tom, total 48
    },
  );

  verifieChapitreRedige(
    'maths-college-le-theoreme-de-thales',
    const <String, double>{
      'calculer/q1': 12, // 3/9 = 4/AC
      'calculer/q2': 6, // 4/10 = MN/15
      'calculer/q4': 3, // 2,5/7,5 appliqué à 9
      'entrainer/q1': 4.8, // 12 × 0,4
      'entrainer/q2': 7.5, // 3 ÷ 0,4
      'entrainer/q3': 20, // 8 ÷ (6/15)
      'entrainer/q5': 3, // 9 × 4 ÷ 12
      'reciproque/q3': 8, // arbre : 12 × 1 ÷ 1,5
      'reciproque/q5': 9.6, // 6 ÷ (5/8), avec AB = 5 + 3
    },
  );

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
