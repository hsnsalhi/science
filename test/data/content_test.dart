import 'dart:convert';

import 'package:eureka/data/content/content_catalog.dart';
import 'package:eureka/data/content/content_loader.dart';
import 'package:eureka/design_system/figures/figure_registry.dart';
import 'package:eureka/design_system/figures/orbits_figure.dart';
import 'package:eureka/design_system/figures/solar_system_figure.dart';
import 'package:eureka/domain/models/chapter.dart';
import 'package:eureka/domain/models/education_level.dart';
import 'package:eureka/domain/models/lesson.dart';
import 'package:eureka/domain/models/question.dart';
import 'package:eureka/domain/models/subject.dart';
import 'package:eureka/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
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

  test('les matières annoncées sont présentes', () {
    expect(catalog.subjects.map((Subject s) => s.id).toSet(), <String>{
      'maths',
      'physique-chimie',
      'informatique',
      'svt',
      'technologie',
      'astronomie',
      'logique',
      'histoire-sciences',
    });
  });

  // Une matière sans palette prend la couleur de repli : toutes se
  // ressembleraient sur l'accueil, et l'accent d'un chapitre perdrait son
  // sens. Le test attrape l'oubli au moment d'ajouter une matière.
  test('chaque matière a sa propre palette', () {
    final Set<Color> bases = <Color>{};
    for (final Subject subject in catalog.subjects) {
      final Color base = SubjectPalettes.of(subject.id).base;
      expect(
        base,
        isNot(SubjectPalettes.fallback.base),
        reason: '${subject.id} n\'a pas de palette déclarée',
      );
      expect(bases.add(base), isTrue, reason: '${subject.id} : couleur déjà prise');
    }
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

  test('chaque chapitre annonce les classes concernées', () {
    for (final Chapter chapter in catalog.chapters) {
      expect(
        chapter.grades,
        isNotEmpty,
        reason: '${chapter.id} ne dit pas à quelles classes il s\'adresse',
      );
    }
  });

  // Le catalogue suit les programmes officiels : un chapitre qui renvoie à
  // une source absente est un chapitre dont plus personne ne sait d'où il
  // sort. Le contrôle se fait sur le JSON brut, la source n'étant qu'une
  // information de provenance que le modèle n'a pas à porter.
  test('chaque chapitre renvoie à un texte officiel déclaré', () async {
    final Map<String, Object?> raw =
        jsonDecode(
              await rootBundle.loadString('assets/content/catalog.json'),
            )
            as Map<String, Object?>;
    final Set<String> sources =
        (raw['sources']! as Map<String, Object?>).keys.toSet();
    expect(sources, isNotEmpty);
    for (final Object? entry in raw['chapters']! as List<Object?>) {
      final Map<String, Object?> chapter = entry! as Map<String, Object?>;
      expect(
        sources,
        contains(chapter['source']),
        reason: '${chapter['id']} cite une source inconnue',
      );
    }
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

  // Le Système solaire : les valeurs numériques du chapitre sont des
  // mesures, pas des choix pédagogiques. Une coquille y passerait
  // inaperçue à la relecture, d'où ce contrôle contre la table de la
  // figure, qui sert aussi à la dessiner.
  group('Chapitre complet : le Système solaire', () {
    late Chapter systeme;

    setUpAll(() {
      systeme = catalog.chapterById(
        'astronomie-college-le-systeme-solaire',
      )!;
    });

    test('est jouable de bout en bout', () {
      expect(systeme.isPlayable, isTrue);
      expect(systeme.lessons.length, greaterThanOrEqualTo(3));
    });

    test('les huit planètes sont rangées par distance croissante', () {
      expect(planetes.length, 8);
      for (int i = 1; i < planetes.length; i++) {
        expect(
          planetes[i].distance,
          greaterThan(planetes[i - 1].distance),
          reason: '${planetes[i].nom} n\'est pas après ${planetes[i - 1].nom}',
        );
      }
      expect(planetes[2].nom, 'Terre');
    });

    test('les réponses numériques collent aux mesures', () {
      final Map<String, double> attendu = <String, double>{};
      for (final Lesson lesson in systeme.lessons) {
        for (final Question question in lesson.questions) {
          if (question is NumericQuestion) {
            attendu[question.prompt] = question.expected;
          }
        }
      }
      final double terre = planetes[2].distance;
      expect(
        attendu.entries
            .firstWhere((MapEntry<String, double> e) =>
                e.key.contains('millions de kilomètres du Soleil'))
            .value,
        terre,
      );
      // 150 millions de km à 300 000 km/s : un peu plus de 8 minutes.
      final double minutes = terre * 1e6 / 299792.458 / 60;
      expect(minutes, closeTo(8, 0.5));
    });

    // La figure des orbites ne fait une démonstration que si ses durées
    // sont justes : c'est l'écart entre les compteurs qui enseigne
    // « plus loin, plus lent ».
    test('les périodes de révolution sont justes et croissantes', () {
      expect(periodes.length, 4);
      for (int i = 1; i < periodes.length; i++) {
        expect(periodes[i], greaterThan(periodes[i - 1]));
      }
      expect(periodes[2], 365, reason: 'l\'année terrestre');
      // Au bout d'une année terrestre, Mercure a tourné quatre fois et
      // Mars pas la moitié d'une : c'est ce que la carte doit montrer.
      expect(365 / periodes[0], closeTo(4.1, 0.1));
      expect(365 / periodes[3], closeTo(0.53, 0.02));
    });

    test('s\'appuie sur la figure du Système solaire', () {
      final Set<String> figures = <String>{};
      for (final Lesson lesson in systeme.lessons) {
        for (final LessonCard card in lesson.cards) {
          if (card.figureId != null) figures.add(card.figureId!);
        }
      }
      expect(figures, contains('systeme-solaire'));
    });
  });
}
