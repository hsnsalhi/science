import 'dart:math' as math;
import 'dart:convert';

import 'package:eureka/data/content/content_catalog.dart';
import 'package:eureka/data/content/content_loader.dart';
import 'package:eureka/design_system/figures/figure_registry.dart';
import 'package:eureka/design_system/figures/array_figure.dart';
import 'package:eureka/design_system/figures/binary_figure.dart';
import 'package:eureka/design_system/figures/cell_figure.dart';
import 'package:eureka/design_system/figures/circuit_figure.dart';
import 'package:eureka/design_system/figures/complexity_figure.dart';
import 'package:eureka/design_system/figures/cross_figure.dart';
import 'package:eureka/design_system/figures/derivative_figure.dart';
import 'package:eureka/design_system/figures/dna_figure.dart';
import 'package:eureka/design_system/figures/eratosthene_figure.dart';
import 'package:eureka/design_system/figures/fraction_bar_figure.dart';
import 'package:eureka/design_system/figures/reference_functions_figure.dart';
import 'package:eureka/design_system/figures/retrograde_figure.dart';
import 'package:eureka/design_system/figures/food_web_figure.dart';
import 'package:eureka/design_system/figures/gears_figure.dart';
import 'package:eureka/design_system/figures/implication_figure.dart';
import 'package:eureka/design_system/figures/loop_robot_figure.dart';
import 'package:eureka/design_system/figures/moon_phases_figure.dart';
import 'package:eureka/design_system/figures/number_line_figure.dart';
import 'package:eureka/design_system/figures/orbits_figure.dart';
import 'package:eureka/design_system/figures/parabola_figure.dart';
import 'package:eureka/design_system/figures/pattern_figure.dart';
import 'package:eureka/design_system/figures/projectile_figure.dart';
import 'package:eureka/design_system/figures/seasons_figure.dart';
import 'package:eureka/design_system/figures/sequence_figure.dart';
import 'package:eureka/design_system/figures/sensor_chain_figure.dart';
import 'package:eureka/design_system/figures/solar_system_figure.dart';
import 'package:eureka/design_system/figures/triangle_angles_figure.dart';
import 'package:eureka/design_system/figures/triangle_test_figure.dart';
import 'package:eureka/design_system/figures/turing_figure.dart';
import 'package:eureka/design_system/figures/states_figure.dart';
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

  // Exiger de chaque chapitre qu'il exerce les neuf formes serait une
  // contrainte d'écriture absurde : un chapitre de logique n'a que faire
  // d'une estimation d'ordre de grandeur. Mais une forme que personne
  // n'emploie est du code mort qui se dégrade en silence — elle doit
  // vivre quelque part.
  test('chaque forme de question est employée dans le catalogue', () {
    final Set<QuestionKind> employees = <QuestionKind>{
      for (final Chapter chapter in catalog.chapters)
        for (final Lesson lesson in chapter.lessons)
          for (final Question question in lesson.questions) question.kind,
    };
    expect(
      employees,
      containsAll(QuestionKind.values),
      reason: 'formes jamais employées : '
          '${QuestionKind.values.toSet().difference(employees).map((QuestionKind k) => k.id).join(', ')}',
    );
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

    test('varie les formes de question', () {
      final Set<QuestionKind> kinds = <QuestionKind>{
        for (final Lesson lesson in pythagore.lessons)
          for (final Question question in lesson.questions) question.kind,
      };
      expect(kinds.length, greaterThanOrEqualTo(6));
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
      // La table des périodes s'indexe avec celle des planètes : la figure
      // n'en dessine que les quatre premières, mais les deux listes doivent
      // rester alignées, sans quoi une période se retrouverait attribuée à
      // la mauvaise planète.
      expect(periodes.length, planetes.length);
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

  // Thalès : chaque réponse numérique du chapitre est recalculée depuis
  // les données de son énoncé. Une coquille dans un corrigé de maths est
  // pire qu'un chapitre absent — l'élève qui a juste se croit faux.
  group('Chapitre complet : le théorème de Thalès', () {
    late Chapter thales;

    setUpAll(() {
      thales = catalog.chapterById('maths-college-le-theoreme-de-thales')!;
    });

    double reponse(String lessonId, String questionId) {
      final Lesson lesson = thales.lessonById(lessonId)!;
      final Question q = lesson.questions.firstWhere(
        (Question x) => x.id == questionId,
      );
      return (q as NumericQuestion).expected;
    }

    test('est jouable de bout en bout', () {
      expect(thales.isPlayable, isTrue);
      expect(thales.lessons.length, 4);
      expect(thales.objectives, isNotEmpty);
    });

    test('les longueurs calculées respectent l\'égalité des rapports', () {
      // AB = 10, AD = 4, AC = 15 : AE = AD × AC ÷ AB.
      expect(reponse('le-theoreme', 'q2'), closeTo(4 * 15 / 10, 1e-9));
      // AB = 9, AD = 3, BC = 12 : DE = AD × BC ÷ AB.
      expect(reponse('calculer', 'q2'), closeTo(3 * 12 / 9, 1e-9));
      // AD = 5, AB = 8, AE = 7,5 : AC = AE × AB ÷ AD.
      expect(reponse('calculer', 'q3'), closeTo(7.5 * 8 / 5, 1e-9));
      // AB = 12, AD = 9, AC = 8 : AE = AD × AC ÷ AB.
      expect(reponse('defi-thales', 'q1'), closeTo(9 * 8 / 12, 1e-9));
      // Ombres : l'arbre est au piquet ce que 6 m d'ombre sont à 2 m.
      expect(reponse('defi-thales', 'q6'), closeTo(1.5 * 6 / 2, 1e-9));
    });

    test('la figure de Thalès est employée', () {
      final Set<String> figures = <String>{
        for (final Lesson lesson in thales.lessons) ...<String>[
          for (final LessonCard card in lesson.cards)
            if (card.figureId != null) card.figureId!,
          for (final Question question in lesson.questions)
            if (question.figureId != null) question.figureId!,
        ],
      };
      expect(figures, contains('thales'));
    });

    test('le chapitre finit par un défi', () {
      expect(thales.lessons.last.kind, LessonKind.defi);
    });
  });

  // Logique : les tris du chapitre portent sur des nombres et des
  // prédicats explicites. Plutôt que de relire les corrigés, on réévalue
  // chaque prédicat sur chaque nombre cité — une inversion de catégorie
  // dans un chapitre consacré à la rigueur serait difficile à défendre.
  group('Chapitre complet : et, ou, non', () {
    late Chapter logique;

    setUpAll(() {
      logique = catalog.chapterById('logique-college-et-ou-non')!;
    });

    ClassifyQuestion tri(String lessonId, String questionId) =>
        logique.lessonById(lessonId)!.questions.firstWhere(
              (Question q) => q.id == questionId,
            )
            as ClassifyQuestion;

    void verifierTri(
      String lessonId,
      String questionId,
      bool Function(int n) predicat,
    ) {
      final ClassifyQuestion q = tri(lessonId, questionId);
      for (final ClassifyItem item in q.items) {
        final int n = int.parse(item.text);
        // Catégorie 0 : l'affirmation est vraie.
        expect(
          item.category == 0,
          predicat(n),
          reason: '$questionId : $n est mal rangé',
        );
      }
    }

    test('est jouable de bout en bout', () {
      expect(logique.isPlayable, isTrue);
      expect(logique.lessons.length, 4);
    });

    test('« et » exige les deux conditions', () {
      verifierTri('et', 'q2', (int n) => n.isEven && n > 10);
    });

    test('« ou » se contente d\'une seule', () {
      verifierTri('ou', 'q3', (int n) => n.isEven || n > 10);
    });

    test('le défi combine impair et petitesse', () {
      verifierTri('defi-logique', 'q1', (int n) => n.isOdd || n < 5);
    });

    test('les comptes sur quatre combinaisons sont justes', () {
      int compter(bool Function(bool a, bool b) f) {
        int total = 0;
        for (final bool a in <bool>[true, false]) {
          for (final bool b in <bool>[true, false]) {
            if (f(a, b)) total++;
          }
        }
        return total;
      }

      double attendu(String lessonId, String questionId) =>
          (logique.lessonById(lessonId)!.questions.firstWhere(
                    (Question q) => q.id == questionId,
                  )
                  as NumericQuestion)
              .expected;

      expect(attendu('et', 'q4'), compter((bool a, bool b) => a && b));
      expect(attendu('ou', 'q2'), compter((bool a, bool b) => a || b));
    });
  });

  // Physique : les vitesses, distances et durées du chapitre se
  // recalculent les unes à partir des autres. Un corrigé faux y enseigne
  // une relation fausse, ce qui est pire que de ne rien enseigner.
  group('Chapitre complet : mouvements et vitesse', () {
    late Chapter vitesse;

    setUpAll(() {
      vitesse = catalog.chapterById(
        'physique-chimie-college-mouvements-et-vitesse',
      )!;
    });

    double reponse(String lessonId, String questionId) {
      final Question q = vitesse
          .lessonById(lessonId)!
          .questions
          .firstWhere((Question x) => x.id == questionId);
      return switch (q) {
        NumericQuestion(:final double expected) => expected,
        EstimateQuestion(:final double expected) => expected,
        _ => throw StateError('$questionId n\'est pas numérique'),
      };
    }

    test('est jouable de bout en bout', () {
      expect(vitesse.isPlayable, isTrue);
      expect(vitesse.lessons.length, 4);
    });

    test('les vitesses se déduisent des distances et des durées', () {
      expect(reponse('la-vitesse', 'q1'), closeTo(240 / 20, 1e-9));
      expect(reponse('defi-vitesse', 'q4'), closeTo(50 / 25, 1e-9));
    });

    test('les distances et durées suivent la même relation', () {
      expect(reponse('calculer-vitesse', 'q1'), closeTo(25 * 40, 1e-9));
      expect(reponse('calculer-vitesse', 'q2'), closeTo(300 / 15, 1e-9));
    });

    test('les conversions valent bien un facteur 3,6', () {
      // 10 m/s en km/h.
      expect(reponse('la-vitesse', 'q2'), closeTo(10 * 3.6, 1e-9));
      // 180 km/h en m/s.
      expect(reponse('defi-vitesse', 'q1'), closeTo(180 / 3.6, 1e-9));
    });

    test('l\'allure du piéton estimée reste plausible', () {
      final double marche = reponse('la-vitesse', 'q4');
      expect(marche * 3.6, closeTo(5, 1));
    });
  });

  // Génétique : les proportions annoncées dans les corrigés se
  // recalculent depuis la règle de dominance, et depuis celle que la
  // figure applique elle-même. Contenu et figure doivent dire la même
  // chose, sinon l'élève voit l'un et lit l'autre.
  group('Chapitre complet : génétique et hérédité', () {
    late Chapter genetique;

    setUpAll(() {
      genetique = catalog.chapterById('svt-college-genetique-et-heredite')!;
    });

    /// Nombre de descendants jaunes pour un croisement donné.
    int jaunes(List<bool> pere, List<bool> mere) {
      int total = 0;
      for (final bool p in pere) {
        for (final bool m in mere) {
          if (CrossFigure.estJaune(<bool>[p, m])) total++;
        }
      }
      return total;
    }

    double reponse(String lessonId, String questionId) =>
        (genetique.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(genetique.isPlayable, isTrue);
      expect(genetique.lessons.length, 4);
    });

    test('un allèle dominant suffit, deux récessifs sont nécessaires', () {
      expect(CrossFigure.estJaune(<bool>[true, true]), isTrue);
      expect(CrossFigure.estJaune(<bool>[true, false]), isTrue);
      expect(CrossFigure.estJaune(<bool>[false, true]), isTrue);
      expect(CrossFigure.estJaune(<bool>[false, false]), isFalse);
    });

    test('les proportions annoncées sont celles du croisement', () {
      const List<bool> jv = <bool>[true, false];
      const List<bool> vv = <bool>[false, false];
      const List<bool> jj = <bool>[true, true];

      // Jv × Jv : une verte sur quatre, donc trois jaunes.
      expect(4 - jaunes(jv, jv), reponse('dominant-recessif', 'q3'));
      expect(jaunes(jv, jv), reponse('defi-genetique', 'q1'));
      // Jv × vv : la moitié de vertes, ce que dit le défi q4.
      expect(jaunes(jv, vv), 2);
      // JJ × vv : toute la descendance est jaune.
      expect(jaunes(jj, vv), 4);
    });

    test('le tri des combinaisons suit la dominance', () {
      final ClassifyQuestion q =
          genetique.lessonById('dominant-recessif')!.questions.firstWhere(
                (Question x) => x.id == 'q2',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final List<bool> alleles = item.text
            .split('')
            .map((String c) => c == 'J')
            .toList();
        expect(
          item.category == 0,
          CrossFigure.estJaune(alleles),
          reason: '${item.text} est mal rangé',
        );
      }
    });

    test('le nombre de chromosomes est cohérent entre les deux questions', () {
      expect(
        reponse('support', 'q2'),
        reponse('defi-genetique', 'q6') * 2,
        reason: '46 chromosomes, soit 23 paires',
      );
    });
  });

  group('Chapitre complet : boucles et conditions', () {
    late Chapter info;

    setUpAll(() {
      info = catalog.chapterById('informatique-college-boucles-et-conditions')!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (info.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(info.isPlayable, isTrue);
      expect(info.lessons.length, 4);
    });

    test('le chemin du robot se referme à quatre tours, pas avant', () {
      // Le chapitre affirme qu'il faut quatre tours pour fermer le carré.
      // On ne le relit pas : on exécute la boucle et on regarde.
      ({int x, int y}) fin(int tours) => LoopRobotFigure.chemin(tours).last;
      final ({int x, int y}) depart = LoopRobotFigure.chemin(0).first;

      for (int tours = 1; tours <= 3; tours++) {
        expect(
          fin(tours),
          isNot(depart),
          reason: 'le chemin ne devrait pas être fermé à $tours tours',
        );
      }
      expect(fin(4), depart, reason: 'quatre tours doivent refermer le carré');
    });

    test('le carré tracé a bien quatre côtés égaux', () {
      final List<({int x, int y})> points = LoopRobotFigure.chemin(4);
      // Un « avancer de 2 » par tour, donc deux segments unitaires.
      expect(points.length, 1 + 4 * LoopRobotFigure.pas);
      // Aucun point ne sort de la grille : la figure tient dans le plateau.
      for (final ({int x, int y}) p in points) {
        expect(p.x, inInclusiveRange(0, LoopRobotFigure.cotes - 1));
        expect(p.y, inInclusiveRange(0, LoopRobotFigure.cotes - 1));
      }
      // Quatre coins distincts : c'est ce qui fait un carré et non un
      // aller-retour sur la même ligne.
      final Set<({int x, int y})> coins = <({int x, int y})>{
        for (int t = 1; t <= 4; t++) LoopRobotFigure.chemin(t).last,
      };
      expect(coins.length, 4);
    });

    test('le robot avance autant de fois qu’il y a de tours', () {
      // « répéter 4 fois : avancer de 2 » — la leçon dit quatre avancées.
      final int avancees = (LoopRobotFigure.chemin(4).length - 1) ~/
          LoopRobotFigure.pas;
      expect(avancees, reponseNum('la-boucle', 'q1'));
    });

    test('les accumulations annoncées sont recalculées', () {
      // score ← 0 ; répéter 5 fois : score ← score + 2
      int score = 0;
      for (int i = 0; i < 5; i++) {
        score += 2;
      }
      expect(score, reponseNum('composer', 'q1'));

      // score ← 1 ; répéter 3 fois : score ← score × 2
      score = 1;
      for (int i = 0; i < 3; i++) {
        score *= 2;
      }
      expect(score, reponseNum('composer', 'q2'));

      // n ← 20 ; répéter 2 fois : n ← n ÷ 2
      double n = 20;
      for (int i = 0; i < 2; i++) {
        n /= 2;
      }
      expect(n, reponseNum('defi-boucles', 'q1'));

      // score ← 0 ; répéter 4 fois : si (score < 2) alors score ← score + 1
      // Le piège du chapitre : la condition est réévaluée à chaque tour.
      score = 0;
      for (int i = 0; i < 4; i++) {
        if (score < 2) score += 1;
      }
      expect(score, reponseNum('defi-boucles', 'q6'));
    });
  });

  group('Chapitre complet : mécanismes et mouvement', () {
    late Chapter meca;

    setUpAll(() {
      meca = catalog.chapterById('technologie-college-mecanismes-et-mouvement')!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (meca.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(meca.isPlayable, isTrue);
      expect(meca.lessons.length, 4);
    });

    test('les rapports de transmission annoncés sont recalculés', () {
      // Chaque corrigé est réécrit en appel à la formule que porte la
      // figure : si l'une bouge, l'autre le dit.
      double tours(int menante, int menee, double toursMenante) =>
          toursMenante * GearsFigure.rapport(menante, menee);

      expect(tours(12, 6, 1), reponseNum('changer-la-vitesse', 'q1'));
      expect(tours(12, 36, 3), reponseNum('changer-la-vitesse', 'q2'));
      expect(tours(24, 8, 1), reponseNum('defi-mecanismes', 'q1'));
      expect(tours(15, 45, 9), reponseNum('defi-mecanismes', 'q2'));
    });

    test('le tri des roues suit le rapport, pas l’intuition', () {
      // La menante a 20 dents dans les deux tris : une menée rangée en
      // « plus vite » doit effectivement tourner plus d'un tour.
      const int menante = 20;
      final ClassifyQuestion q =
          meca.lessonById('changer-la-vitesse')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final int dents = int.parse(item.text.split(' ').first);
        final bool plusVite = GearsFigure.rapport(menante, dents) > 1;
        expect(
          item.category == 0,
          plusVite,
          reason: '${item.text} est mal rangé',
        );
      }
    });

    test('le sens de rotation suit le nombre de roues', () {
      // Trois roues : la dernière tourne comme la première. Quatre : non.
      // Le défi q3 et la leçon q2 disent les deux, il faut qu'ils
      // s'accordent avec la règle portée par la figure.
      expect(GearsFigure.memeSens(3), isTrue);
      expect(GearsFigure.memeSens(4), isFalse);
      // La leçon compte les changements de sens entre trois roues : deux
      // contacts, donc deux inversions, donc le même sens au bout.
      expect(reponseNum('transmettre', 'q2'), 2);
      expect(GearsFigure.memeSens(3), (reponseNum('transmettre', 'q2')) % 2 == 0);
    });

    test('les avances de la vis sont proportionnelles au pas', () {
      // 2 mm par tour, six tours.
      expect(2 * 6, reponseNum('transformer', 'q2'));
      // 24 mm à 3 mm par tour.
      expect(24 / 3, reponseNum('defi-mecanismes', 'q6'));
    });
  });

  group('Chapitre complet : de la Terre plate au Système solaire', () {
    late Chapter histoire;

    setUpAll(() {
      histoire = catalog.chapterById(
        'histoire-sciences-college-de-la-terre-plate-au-systeme-solaire',
      )!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (histoire.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(histoire.isPlayable, isTrue);
      expect(histoire.lessons.length, 4);
    });

    test('les mesures à la façon d’Ératosthène sont recalculées', () {
      // Le chapitre affirme qu'un angle de 7,2° vaut un cinquantième de
      // tour : on le redivise plutôt que de le relire.
      expect(360 / 7.2, reponseNum('la-terre-est-ronde', 'q1'));
      expect(
        EratostheneFigure.circonference(7.2, 800),
        reponseNum('la-terre-est-ronde', 'q2'),
      );
      expect(
        EratostheneFigure.circonference(5, 560),
        reponseNum('defi-histoire', 'q1'),
      );
    });

    test('la méthode donne le même tour quelle que soit la ville', () {
      // C'est l'affirmation portée par la figure, et le cœur de la
      // leçon : le quotient ne dépend pas de l'endroit choisi.
      for (final double angle in <double>[3, 7.2, 15, 28, 40]) {
        final double distance = EratostheneFigure.distancePourAngle(angle);
        expect(
          EratostheneFigure.circonference(angle, distance),
          closeTo(2 * math.pi * EratostheneFigure.rayonTerre, 0.001),
          reason: 'à $angle° le tour trouvé devrait être le même',
        );
      }
    });

    test('Mars recule bien dans le ciel, et jamais sur son orbite', () {
      // Les deux affirmations du chapitre, recalculées : le recul est
      // apparent (la direction observée diminue), et Mars ne fait pas
      // demi-tour (sa position autour du Soleil, elle, avance toujours).
      final List<PointDuCiel> trace = RetrogradeFigure.releve(4.4, points: 4400);
      bool unReculObserve = false;
      for (int i = 1; i < trace.length; i++) {
        if (trace[i].longitude < trace[i - 1].longitude) unReculObserve = true;
      }
      expect(unReculObserve, isTrue, reason: 'aucune rétrogradation observée');

      // Et la position de Mars autour du Soleil, elle, avance toujours :
      // chaque pas de temps la fait progresser d'un angle positif.
      double angleDe(double t) {
        final ({double x, double y}) m = RetrogradeFigure.mars(t);
        return math.atan2(m.y, m.x);
      }

      for (int i = 1; i <= 880; i++) {
        final double avant = angleDe(4.4 * (i - 1) / 880);
        final double apres = angleDe(4.4 * i / 880);
        double pas = apres - avant;
        while (pas <= -math.pi) {
          pas += 2 * math.pi;
        }
        while (pas > math.pi) {
          pas -= 2 * math.pi;
        }
        expect(
          pas,
          greaterThan(0),
          reason: 'Mars ne doit jamais reculer sur son orbite',
        );
      }
    });

    test('le recul dure quelques semaines et revient tous les deux ans', () {
      final List<PointDuCiel> trace = RetrogradeFigure.releve(9, points: 9000);
      final List<(double, double)> episodes = <(double, double)>[];
      double? debut;
      for (int i = 1; i < trace.length; i++) {
        final bool arriere = trace[i].longitude < trace[i - 1].longitude;
        if (arriere && debut == null) debut = trace[i - 1].annees;
        if (!arriere && debut != null) {
          episodes.add((debut, trace[i - 1].annees));
          debut = null;
        }
      }
      // Le premier épisode commence avant le relevé (les deux planètes
      // sont alignées à l'instant zéro) : il est tronqué, on l'écarte.
      final List<(double, double)> entiers = episodes
          .where(((double, double) e) => e.$1 > 0.01)
          .toList();
      expect(entiers.length, greaterThanOrEqualTo(3));

      for (final (double, double) episode in entiers) {
        final double mois = (episode.$2 - episode.$1) * 12;
        expect(
          mois,
          inInclusiveRange(1.5, 3.5),
          reason: 'le chapitre parle de quelques semaines, pas de mois',
        );
      }
      // « Tous les deux ans environ » : l'écart entre deux reculs est la
      // période synodique, que la figure calcule de son côté.
      expect(
        entiers[1].$1 - entiers[0].$1,
        closeTo(RetrogradeFigure.periodeSynodique, 0.02),
      );
      expect(RetrogradeFigure.periodeSynodique * 12, closeTo(25.6, 0.2));
    });

    test('l’écart entre Copernic et Galilée est le bon', () {
      expect(1610 - 1543, reponseNum('le-soleil-au-centre', 'q4'));
    });
  });

  group('Chapitre complet : la Lune et ses phases', () {
    late Chapter lune;

    setUpAll(() {
      lune = catalog.chapterById('astronomie-primaire-la-lune-et-ses-phases')!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (lune.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(lune.isPlayable, isTrue);
      expect(lune.lessons.length, 4);
    });

    test('les durées annoncées sont celles de la figure', () {
      expect(
        reponseNum('la-lune-tourne', 'q1'),
        closeTo(MoonPhasesFigure.periode, 0.1),
      );
      // Une demi-lunaison sépare la nouvelle lune de la pleine lune, et
      // la pleine lune de la suivante nouvelle lune.
      const double demie = MoonPhasesFigure.periode / 2;
      for (final double annonce in <double>[
        reponseNum('pourquoi-elle-change', 'q3'),
        reponseNum('defi-lune', 'q3'),
      ]) {
        expect(annonce, closeTo(demie, 1));
      }
    });

    test('les phases remarquables tombent sur la bonne fraction', () {
      // Le nom affiché et la part éclairée doivent s'accorder : c'est ce
      // que l'élève lit sous le dessin, les deux en même temps.
      expect(MoonPhasesFigure.fractionEclairee(0), closeTo(0, 0.001));
      expect(
        MoonPhasesFigure.fractionEclairee(MoonPhasesFigure.periode / 4),
        closeTo(0.5, 0.001),
      );
      expect(
        MoonPhasesFigure.fractionEclairee(MoonPhasesFigure.periode / 2),
        closeTo(1, 0.001),
      );
      expect(MoonPhasesFigure.nomDePhase(0), 'Nouvelle Lune');
      expect(
        MoonPhasesFigure.nomDePhase(MoonPhasesFigure.periode / 4),
        'Premier quartier',
      );
      expect(
        MoonPhasesFigure.nomDePhase(MoonPhasesFigure.periode / 2),
        'Pleine Lune',
      );
      expect(
        MoonPhasesFigure.nomDePhase(MoonPhasesFigure.periode * 3 / 4),
        'Dernier quartier',
      );
    });

    test('un quartier annoncé montre bien la moitié du disque', () {
      // Partout où la figure annonce « quartier », le disque doit être
      // éclairé à peu près de moitié ; partout où elle annonce « pleine »
      // ou « nouvelle », presque tout ou presque rien.
      for (int i = 0; i < 300; i++) {
        final double jour = MoonPhasesFigure.periode * i / 300;
        final String nom = MoonPhasesFigure.nomDePhase(jour);
        final double f = MoonPhasesFigure.fractionEclairee(jour);
        if (nom.contains('quartier')) {
          expect(f, inInclusiveRange(0.4, 0.6), reason: 'jour $jour');
        } else if (nom == 'Pleine Lune') {
          expect(f, greaterThan(0.97), reason: 'jour $jour');
        } else if (nom == 'Nouvelle Lune') {
          expect(f, lessThan(0.03), reason: 'jour $jour');
        }
      }
    });

    test('la remise en ordre des phases suit la lunaison', () {
      final OrderingQuestion q =
          lune.lessonById('les-noms-des-phases')!.questions.firstWhere(
                (Question x) => x.id == 'q1',
              )
              as OrderingQuestion;
      // L'ordre attendu par l'exercice doit être celui que la figure
      // fait défiler, et non un ordre recopié à la main.
      final List<String> attendu = MoonPhasesFigure.phases.sublist(
        0,
        q.items.length,
      );
      expect(q.items, attendu);
    });

    test('le tri croissant / décroissant suit la lunaison', () {
      final ClassifyQuestion q =
          lune.lessonById('defi-lune')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        // On retrouve le jour où la figure donne ce nom, et on vérifie
        // qu'elle grandit bien à ce moment-là.
        double? jourTrouve;
        for (int i = 0; i < 600; i++) {
          final double jour = MoonPhasesFigure.periode * i / 600;
          if (MoonPhasesFigure.nomDePhase(jour) == item.text) {
            jourTrouve = jour;
            break;
          }
        }
        expect(jourTrouve, isNotNull, reason: '${item.text} inconnue');
        expect(
          item.category == 0,
          MoonPhasesFigure.croissante(jourTrouve!),
          reason: '${item.text} est mal rangée',
        );
      }
    });
  });

  group('Chapitre complet : les fractions', () {
    late Chapter fractions;

    setUpAll(() {
      fractions = catalog.chapterById('maths-primaire-les-fractions')!;
    });

    /// Lit une fraction écrite « 3/8 » dans un énoncé du chapitre.
    ({int haut, int bas}) lire(String texte) {
      final List<String> morceaux = texte.split('/');
      return (haut: int.parse(morceaux[0]), bas: int.parse(morceaux[1]));
    }

    double reponseNum(String lessonId, String questionId) =>
        (fractions.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    ClassifyQuestion tri(String lessonId, String questionId) =>
        fractions.lessonById(lessonId)!.questions.firstWhere(
              (Question q) => q.id == questionId,
            )
            as ClassifyQuestion;

    test('est jouable de bout en bout', () {
      expect(fractions.isPlayable, isTrue);
      expect(fractions.lessons.length, 4);
    });

    test('le tri par rapport à une moitié est juste, fraction par fraction', () {
      final ClassifyQuestion q = tri('comparer', 'q2');
      for (final ClassifyItem item in q.items) {
        final ({int haut, int bas}) f = lire(item.text);
        final int signe = FractionBarFigure.comparer(f.haut, f.bas, 1, 2);
        expect(signe, isNot(0), reason: '${item.text} vaut pile une moitié');
        expect(
          item.category == 0,
          signe < 0,
          reason: '${item.text} est mal rangée',
        );
      }
    });

    test('les fractions annoncées égales à une moitié le sont', () {
      for (final ClassifyItem item in tri('fractions-egales', 'q3').items) {
        final ({int haut, int bas}) f = lire(item.text);
        expect(
          item.category == 0,
          FractionBarFigure.comparer(f.haut, f.bas, 1, 2) == 0,
          reason: '${item.text} est mal rangée',
        );
      }
    });

    test('les fractions annoncées entières le sont', () {
      for (final ClassifyItem item in tri('defi-fractions', 'q4').items) {
        final ({int haut, int bas}) f = lire(item.text);
        expect(
          item.category == 0,
          FractionBarFigure.comparer(f.haut, f.bas, 1, 1) == 0,
          reason: '${item.text} est mal rangée',
        );
      }
    });

    test('les simplifications proposées sont les bonnes', () {
      final MatchingQuestion q =
          fractions.lessonById('fractions-egales')!.questions.firstWhere(
                (Question x) => x.id == 'q1',
              )
              as MatchingQuestion;
      for (final MatchPair paire in q.pairs) {
        final ({int haut, int bas}) depart = lire(paire.left);
        final ({int haut, int bas}) arrivee = lire(paire.right);
        final ({int denominateur, int numerateur}) reduite =
            FractionBarFigure.simplifier(depart.haut, depart.bas);
        expect(
          <int>[reduite.numerateur, reduite.denominateur],
          <int>[arrivee.haut, arrivee.bas],
          reason: '${paire.left} ne se simplifie pas en ${paire.right}',
        );
      }
    });

    test('la plus grande fraction proposée est bien la bonne réponse', () {
      final SingleChoiceQuestion q =
          fractions.lessonById('defi-fractions')!.questions.firstWhere(
                (Question x) => x.id == 'q2',
              )
              as SingleChoiceQuestion;
      final ({int haut, int bas}) gagnante = lire(
        q.options.firstWhere((AnswerOption o) => o.isCorrect).text,
      );
      for (final AnswerOption option in q.options) {
        if (option.isCorrect) continue;
        final ({int haut, int bas}) autre = lire(option.text);
        expect(
          FractionBarFigure.comparer(
            gagnante.haut,
            gagnante.bas,
            autre.haut,
            autre.bas,
          ),
          greaterThan(0),
          reason: '${option.text} n’est pas plus petite que la bonne réponse',
        );
      }
    });

    test('les partages annoncés dans les énoncés tombent juste', () {
      // Un quart de douze carrés, un tiers de vingt-quatre élèves : on
      // refait la division plutôt que de relire le corrigé.
      expect(12 * FractionBarFigure.valeur(1, 4), reponseNum('partager-en-parts-egales', 'q2'));
      expect(24 * FractionBarFigure.valeur(1, 3), reponseNum('defi-fractions', 'q3'));
      // Et les moitiés : cinq dixièmes, six douzièmes.
      expect(
        FractionBarFigure.comparer(
          reponseNum('comparer', 'q3').round(),
          10,
          1,
          2,
        ),
        0,
      );
      expect(
        FractionBarFigure.comparer(
          reponseNum('defi-fractions', 'q5').round(),
          12,
          1,
          2,
        ),
        0,
      );
    });
  });

  group('Chapitre complet : le second degré', () {
    late Chapter degre;

    setUpAll(() {
      degre = catalog.chapterById('maths-lycee-second-degre')!;
    });

    /// Lit un trinôme écrit « 2x² + 3x − 2 » et en rend les coefficients.
    ///
    /// On préfère relire l'énoncé que recopier des coefficients à côté :
    /// une transcription à la main serait un second endroit où se
    /// tromper, et c'est précisément ce que ces tests évitent.
    ({double a, double b, double c}) lire(String ecriture) {
      final String net = ecriture
          .replaceAll('−', '-')
          .replaceAll('–', '-')
          .replaceAll(' ', '');
      double a = 0;
      double b = 0;
      double c = 0;
      final RegExp termes = RegExp(r'[+-]?[^+-]+');
      for (final RegExpMatch m in termes.allMatches(net)) {
        String terme = m.group(0)!;
        final bool negatif = terme.startsWith('-');
        if (terme.startsWith('+') || terme.startsWith('-')) {
          terme = terme.substring(1);
        }
        final double signe = negatif ? -1 : 1;
        if (terme.endsWith('x²')) {
          final String n = terme.substring(0, terme.length - 2);
          a = signe * (n.isEmpty ? 1 : double.parse(n));
        } else if (terme.endsWith('x')) {
          final String n = terme.substring(0, terme.length - 1);
          b = signe * (n.isEmpty ? 1 : double.parse(n));
        } else {
          c = signe * double.parse(terme);
        }
      }
      return (a: a, b: b, c: c);
    }

    double reponseNum(String lessonId, String questionId) =>
        (degre.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    ClassifyQuestion tri(String lessonId, String questionId) =>
        degre.lessonById(lessonId)!.questions.firstWhere(
              (Question q) => q.id == questionId,
            )
            as ClassifyQuestion;

    test('est jouable de bout en bout', () {
      expect(degre.isPlayable, isTrue);
      expect(degre.lessons.length, 4);
    });

    test('la lecture des trinômes est fiable', () {
      // Le lecteur sert à tous les tests qui suivent : s'il se trompe,
      // ils se tromperaient tous ensemble et d'accord entre eux.
      expect(lire('x² − 5x + 6'), (a: 1.0, b: -5.0, c: 6.0));
      expect(lire('2x² + 3x − 2'), (a: 2.0, b: 3.0, c: -2.0));
      expect(lire('−x² + 4'), (a: -1.0, b: 0.0, c: 4.0));
      expect(lire('x² + x + 1'), (a: 1.0, b: 1.0, c: 1.0));
    });

    test('les discriminants annoncés sont recalculés', () {
      double delta(String ecriture) {
        final ({double a, double b, double c}) t = lire(ecriture);
        return ParabolaFigure.discriminant(t.a, t.b, t.c);
      }

      expect(delta('x² − 5x + 6'), reponseNum('le-discriminant', 'q1'));
      expect(delta('x² + x + 1'), reponseNum('le-discriminant', 'q2'));
      expect(delta('x² − 4x + 4'), reponseNum('defi-second-degre', 'q1'));
    });

    test('le tri par nombre de racines suit le discriminant', () {
      for (final ClassifyItem item in tri('le-discriminant', 'q3').items) {
        final ({double a, double b, double c}) t = lire(item.text);
        final int combien = ParabolaFigure.racines(t.a, t.b, t.c).length;
        expect(
          item.category == 0,
          combien == 2,
          reason: '${item.text} a $combien racine(s)',
        );
      }
    });

    test('le tri par sens d’ouverture suit le signe de a', () {
      for (final ClassifyItem item in tri('defi-second-degre', 'q3').items) {
        expect(
          item.category == 0,
          lire(item.text).a > 0,
          reason: '${item.text} est mal rangé',
        );
      }
    });

    test('les racines annoncées sont celles du calcul', () {
      List<double> racinesDe(String ecriture) {
        final ({double a, double b, double c}) t = lire(ecriture);
        return ParabolaFigure.racines(t.a, t.b, t.c);
      }

      expect(
        racinesDe('x² − 5x + 6').first,
        reponseNum('resoudre-et-factoriser', 'q1'),
      );
      expect(
        racinesDe('2x² − 3x − 2').first,
        reponseNum('resoudre-et-factoriser', 'q2'),
      );
      expect(racinesDe('−x² + 4').last, reponseNum('defi-second-degre', 'q4'));
      // Racine double : une seule valeur, et c'est l'abscisse du sommet.
      final List<double> doubles = racinesDe('x² − 4x + 4');
      expect(doubles.length, 1);
      expect(doubles.single, reponseNum('defi-second-degre', 'q2'));
      expect(
        doubles.single,
        ParabolaFigure.sommet(1, -4, 4).x,
        reason: 'quand Δ = 0, la racine est le sommet',
      );
    });

    test('le sommet annoncé est le bon', () {
      final ({double x, double y}) s = ParabolaFigure.sommet(1, -6, 5);
      expect(s.x, reponseNum('la-parabole', 'q1'));
      expect(s.y, reponseNum('la-parabole', 'q2'));
    });

    test('la forme factorisée redonne le trinôme', () {
      // (x − 2)(x − 3) doit rendre x² − 5x + 6 : on développe plutôt que
      // de relire.
      final FillBlanksQuestion q =
          degre.lessonById('resoudre-et-factoriser')!.questions.firstWhere(
                (Question x) => x.id == 'q3',
              )
              as FillBlanksQuestion;
      final List<double> annoncees = q.accepted
          .map((List<String> reponses) => double.parse(reponses.first))
          .toList();
      expect(annoncees.length, 2);
      final double x1 = annoncees[0];
      final double x2 = annoncees[1];
      // Développement de (x − x₁)(x − x₂).
      expect(-(x1 + x2), -5, reason: 'le coefficient de x ne tombe pas juste');
      expect(x1 * x2, 6, reason: 'le terme constant ne tombe pas juste');
      expect(ParabolaFigure.racines(1, -5, 6), <double>[x1, x2]);
    });

    test('les discriminants appariés sont les bons', () {
      final MatchingQuestion q =
          degre.lessonById('defi-second-degre')!.questions.firstWhere(
                (Question x) => x.id == 'q6',
              )
              as MatchingQuestion;
      for (final MatchPair paire in q.pairs) {
        final ({double a, double b, double c}) t = lire(paire.left);
        final double annonce = double.parse(
          paire.right.replaceAll('Δ = ', '').replaceAll('−', '-'),
        );
        expect(
          ParabolaFigure.discriminant(t.a, t.b, t.c),
          annonce,
          reason: '${paire.left} n’a pas ce discriminant',
        );
      }
    });
  });

  group('Chapitre complet : algorithmique et complexité', () {
    late Chapter complexite;

    setUpAll(() {
      complexite = catalog.chapterById(
        'informatique-universite-algorithmique-et-complexite',
      )!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (complexite.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(complexite.isPlayable, isTrue);
      expect(complexite.lessons.length, 4);
    });

    test('les comparaisons de dichotomie annoncées sont recalculées', () {
      // Le nombre de comparaisons au pire est ⌈log₂(n+1)⌉, et c'est la
      // courbe logarithmique de la figure qui le porte.
      double comparaisons(double n) =>
          Complexite.logarithmique.operations(n + 1).ceilToDouble();

      expect(comparaisons(1000000), reponseNum('recherche-et-tri', 'q1'));
      expect(comparaisons(1024), reponseNum('defi-complexite', 'q2'));
    });

    test('les mises à l’échelle annoncées suivent la bonne classe', () {
      // Quadratique : de mille à deux mille éléments, puis de dix mille
      // à trente mille. On refait le rapport plutôt que de le relire.
      double facteur(Complexite c, double avant, double apres) =>
          c.operations(apres) / c.operations(avant);

      expect(
        1 * facteur(Complexite.quadratique, 1000, 2000),
        closeTo(reponseNum('les-classes', 'q1'), 0.001),
      );
      expect(
        2 * facteur(Complexite.quadratique, 10000, 30000),
        closeTo(reponseNum('recherche-et-tri', 'q4'), 0.001),
      );
      expect(
        3 * facteur(Complexite.lineaire, 1000000, 4000000),
        closeTo(reponseNum('defi-complexite', 'q5'), 0.001),
      );
    });

    test('l’estimation sur 2^50 tombe dans la bonne fourchette', () {
      final EstimateQuestion q =
          complexite.lessonById('les-classes')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as EstimateQuestion;
      final double jours =
          ComplexityFigure.secondes(Complexite.exponentielle.operations(50)) /
              86400;
      expect(
        (q.expected - jours).abs(),
        lessThan(q.tolerance),
        reason: 'la vraie durée est de $jours jours',
      );
      expect(jours, inInclusiveRange(q.min, q.max));
    });

    test('le classement praticable / impraticable suit les courbes', () {
      // Pour mille éléments, une machine ordinaire finit un n² en une
      // seconde ; un 2^n ne finit pas. C'est la frontière que le tri
      // des deux exercices affirme, et on la recalcule.
      final Map<String, Complexite> classes = <String, Complexite>{
        'log n': Complexite.logarithmique,
        'n': Complexite.lineaire,
        'n log n': Complexite.quasiLineaire,
        'n²': Complexite.quadratique,
        '2^n': Complexite.exponentielle,
      };
      final ClassifyQuestion q =
          complexite.lessonById('les-classes')!.questions.firstWhere(
                (Question x) => x.id == 'q2',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final Complexite? c = classes[item.text];
        expect(c, isNotNull, reason: '${item.text} n’est pas une classe connue');
        // Dix millions d'éléments, ce que « grandes données » veut
        // dire ici : au-delà d'une heure de calcul, on ne parle plus de
        // traitement mais d'attente.
        final double secondes =
            ComplexityFigure.secondes(c!.operations(10000000));
        expect(
          item.category == 0,
          secondes < 3600,
          reason: '${item.text} demande $secondes s sur dix millions',
        );
      }
    });

    test('les durées lisibles passent les bons seuils', () {
      expect(ComplexityFigure.dureeLisible(1e-9), 'instantané');
      expect(ComplexityFigure.dureeLisible(0.5), '500 ms');
      expect(ComplexityFigure.dureeLisible(90), '2 min');
      expect(ComplexityFigure.dureeLisible(86400 * 3), '3 jours');
      // Trente-six ans pour 2^60, comme l'annonce la leçon.
      final double ans =
          ComplexityFigure.secondes(Complexite.exponentielle.operations(60)) /
              31557600;
      expect(ans, closeTo(36.5, 1.5));
    });
  });

  group('Chapitre complet : états et constitution de la matière', () {
    late Chapter matiere;

    setUpAll(() {
      matiere = catalog.chapterById(
        'physique-chimie-college-etats-et-constitution-de-la-matiere',
      )!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (matiere.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(matiere.isPlayable, isTrue);
      expect(matiere.lessons.length, 4);
    });

    test('les seuils annoncés sont ceux de la figure', () {
      expect(
        reponseNum('changements-d-etat', 'q2'),
        StatesFigure.ebullition,
      );
      expect(reponseNum('defi-matiere', 'q2'), StatesFigure.fusion);
    });

    test('la figure change d’état exactement aux seuils annoncés', () {
      // Juste en dessous et juste au-dessus : c'est là que se jouent les
      // deux questions du chapitre, et une inégalité large prise pour
      // stricte ferait mentir le thermomètre.
      expect(StatesFigure.etat(-0.1), EtatMatiere.solide);
      expect(StatesFigure.etat(0), EtatMatiere.liquide);
      expect(StatesFigure.etat(99.9), EtatMatiere.liquide);
      expect(StatesFigure.etat(100), EtatMatiere.gaz);
    });

    test('les masses annoncées suivent la masse volumique de l’eau', () {
      // 1 g par cm³, et 1 kg par litre : c'est la même chose écrite
      // autrement, et les quatre énoncés doivent s'y tenir.
      const double gParCm3 = 1;
      expect(250 * gParCm3, reponseNum('masse-et-volume', 'q1'));
      expect(3 * gParCm3, reponseNum('masse-et-volume', 'q4'));
      expect(20 + 500 * gParCm3, reponseNum('defi-matiere', 'q5'));
      // Conservation de la masse : ce qui entre au congélateur en
      // ressort au gramme près.
      expect(reponseNum('masse-et-volume', 'q2'), 200);
    });

    test('le tri des changements d’état suit le sens du chauffage', () {
      // Chauffer fait passer vers un état plus désordonné : on le
      // revérifie sur le thermomètre de la figure plutôt que sur une
      // liste de noms.
      final Map<String, (double, double)> passages = <String, (double, double)>{
        'Fusion': (-10, 20),
        'Vaporisation': (20, 120),
        'Solidification': (20, -10),
        'Liquéfaction': (120, 20),
      };
      final ClassifyQuestion q =
          matiere.lessonById('defi-matiere')!.questions.firstWhere(
                (Question x) => x.id == 'q3',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final (double, double)? passage = passages[item.text];
        expect(passage, isNotNull, reason: '${item.text} inconnu');
        final bool onChauffe = passage!.$2 > passage.$1;
        expect(
          item.category == 0,
          onChauffe,
          reason: '${item.text} est mal rangé',
        );
        // Et le passage doit bien faire changer d'état.
        expect(
          StatesFigure.etat(passage.$1),
          isNot(StatesFigure.etat(passage.$2)),
          reason: '${item.text} ne change pas d’état',
        );
      }
    });
  });

  group('Chapitre complet : la dérivation', () {
    late Chapter derivation;

    setUpAll(() {
      derivation = catalog.chapterById('maths-lycee-derivation')!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (derivation.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    /// Dérivée approchée, par différence centrée.
    ///
    /// Les énoncés qui sortent du carré — 3x² − 5x + 2, x³, 4x + 7 — ne
    /// sont pas portés par la figure : on les vérifie numériquement
    /// plutôt que de recopier une règle de dérivation à côté.
    double deriveeApprochee(double Function(double) f, double a) {
      const double h = 1e-6;
      return (f(a + h) - f(a - h)) / (2 * h);
    }

    test('est jouable de bout en bout', () {
      expect(derivation.isPlayable, isTrue);
      expect(derivation.lessons.length, 4);
    });

    test('les taux d’accroissement annoncés sont recalculés', () {
      expect(
        DerivativeFigure.penteSecante(1, 0.5),
        closeTo(reponseNum('taux-d-accroissement', 'q1'), 1e-9),
      );
      expect(
        DerivativeFigure.penteSecante(2, 1),
        closeTo(reponseNum('taux-d-accroissement', 'q2'), 1e-9),
      );
      expect(
        DerivativeFigure.penteSecante(1, 0.1),
        closeTo(reponseNum('defi-derivation', 'q1'), 1e-9),
      );
    });

    test('le taux vaut bien 2a + h, comme l’affirme le cours', () {
      for (final double a in <double>[-2, -0.5, 0, 1, 3]) {
        for (final double h in <double>[1, 0.25, 0.01]) {
          expect(
            DerivativeFigure.penteSecante(a, h),
            closeTo(2 * a + h, 1e-9),
            reason: 'a = $a, h = $h',
          );
        }
      }
    });

    test('la sécante tend vers la tangente quand l’écart se referme', () {
      // L'écart entre la pente affichée et le nombre dérivé doit décroître
      // jusqu'à devenir négligeable : c'est ce que la leçon demande de
      // constater au curseur.
      double ecartPrecedent = double.infinity;
      for (final double h in <double>[1, 0.5, 0.1, 0.01, 0.001]) {
        final double ecart =
            (DerivativeFigure.penteSecante(1, h) - DerivativeFigure.derivee(1))
                .abs();
        expect(ecart, lessThan(ecartPrecedent));
        ecartPrecedent = ecart;
      }
      expect(ecartPrecedent, lessThan(0.002));
    });

    test('les nombres dérivés annoncés sont les bons', () {
      expect(
        DerivativeFigure.derivee(3),
        reponseNum('nombre-derive-et-tangente', 'q1'),
      );
      expect(
        DerivativeFigure.derivee(-2),
        reponseNum('nombre-derive-et-tangente', 'q2'),
      );
      // Hors du carré : vérification numérique.
      expect(
        deriveeApprochee((double x) => 3 * x * x - 5 * x + 2, 1),
        closeTo(reponseNum('fonction-derivee', 'q1'), 1e-4),
      );
      expect(
        deriveeApprochee((double x) => x * x * x, 2),
        closeTo(reponseNum('fonction-derivee', 'q2'), 1e-4),
      );
      expect(
        deriveeApprochee((double x) => 4 * x + 7, 10),
        closeTo(reponseNum('defi-derivation', 'q2'), 1e-4),
      );
    });

    test('l’équation de la tangente en 2 est juste', () {
      final FillBlanksQuestion q =
          derivation.lessonById('nombre-derive-et-tangente')!.questions
                  .firstWhere((Question x) => x.id == 'q3')
              as FillBlanksQuestion;
      final double pente = double.parse(q.accepted[0].first);
      final double ordonnee = -double.parse(q.accepted[1].first);
      expect(pente, DerivativeFigure.derivee(2));
      // La droite doit toucher la courbe au point d'abscisse 2.
      expect(pente * 2 + ordonnee, DerivativeFigure.f(2));
    });

    test('la dérivée s’annule là où le chapitre le dit', () {
      final double x = reponseNum('fonction-derivee', 'q3');
      double f(double t) => t * t - 4 * t;
      expect(deriveeApprochee(f, x).abs(), lessThan(1e-6));
      // Et elle change de signe : c'est ce qui fait l'extremum.
      expect(deriveeApprochee(f, x - 1), lessThan(0));
      expect(deriveeApprochee(f, x + 1), greaterThan(0));
    });

    test('le tri des variations suit le signe de la dérivée', () {
      final ClassifyQuestion q =
          derivation.lessonById('fonction-derivee')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final double x = double.parse(item.text.replaceAll('x = ', ''));
        final double pente =
            deriveeApprochee((double t) => t * t - 4 * t, x);
        expect(
          item.category == 0,
          pente < 0,
          reason: '${item.text} : la dérivée vaut $pente',
        );
      }
    });

    test('le point de tangente de pente 6 est bien sur la courbe', () {
      // Le défi demande l'ordonnée ; on retrouve d'abord l'abscisse par
      // la dérivée, puis on redescend sur la courbe.
      const double penteVoulue = 6;
      double a = 0;
      for (double essai = -5; essai <= 5; essai += 0.0001) {
        if ((DerivativeFigure.derivee(essai) - penteVoulue).abs() < 1e-9) {
          a = essai;
          break;
        }
      }
      expect(a, closeTo(3, 1e-6));
      expect(
        DerivativeFigure.f(a),
        closeTo(reponseNum('defi-derivation', 'q5'), 1e-4),
      );
    });
  });

  group('Chapitre complet : multiplier et les tables', () {
    late Chapter tables;

    setUpAll(() {
      tables = catalog.chapterById('maths-primaire-multiplier-et-les-tables')!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (tables.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    /// Lit un calcul écrit « 4 × 6 ».
    (int, int) lire(String calcul) {
      final List<String> morceaux = calcul.split('×');
      return (int.parse(morceaux[0].trim()), int.parse(morceaux[1].trim()));
    }

    test('est jouable de bout en bout', () {
      expect(tables.isPlayable, isTrue);
      expect(tables.lessons.length, 4);
    });

    test('tous les produits annoncés sont recalculés', () {
      final Map<String, (int, int)> calculs = <String, (int, int)>{
        'des-paquets-egaux/q1': (3, 5),
        'des-paquets-egaux/q2': (4, 7),
        'l-ordre-ne-change-rien/q1': (3, 8),
        'l-ordre-ne-change-rien/q2': (6, 7),
        'les-tables/q1': (8, 5),
        'les-tables/q2': (9, 6),
        'les-tables/q3': (7, 6),
        'defi-multiplication/q1': (6, 8),
        'defi-multiplication/q2': (4, 9),
        'defi-multiplication/q3': (7, 7),
        'defi-multiplication/q5': (9, 5),
      };
      calculs.forEach((String chemin, (int, int) facteurs) {
        final List<String> parts = chemin.split('/');
        expect(
          ArrayFigure.produit(facteurs.$1, facteurs.$2),
          reponseNum(parts[0], parts[1]),
          reason: '$chemin : ${facteurs.$1} × ${facteurs.$2}',
        );
      });
    });

    test('les tris de calculs tombent sur les bonnes catégories', () {
      // Chaque catégorie porte son résultat dans son nom : on multiplie
      // et on compare, plutôt que de faire confiance au rangement.
      for (final String question in <String>[
        'l-ordre-ne-change-rien/q3',
        'defi-multiplication/q4',
      ]) {
        final List<String> parts = question.split('/');
        final ClassifyQuestion q =
            tables.lessonById(parts[0])!.questions.firstWhere(
                  (Question x) => x.id == parts[1],
                )
                as ClassifyQuestion;
        for (final ClassifyItem item in q.items) {
          final (int, int) facteurs = lire(item.text);
          final int attendu = int.parse(
            q.categories[item.category].replaceAll('Fait ', ''),
          );
          expect(
            ArrayFigure.produit(facteurs.$1, facteurs.$2),
            attendu,
            reason: '${item.text} est rangé dans « ${q.categories[item.category]} »',
          );
        }
      }
    });

    test('la table de 5 du tri est bien la table de 5', () {
      final ClassifyQuestion q =
          tables.lessonById('les-tables')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final int valeur = int.parse(item.text);
        final bool dansLaTable = <int>[
          for (int i = 1; i <= 10; i++) ArrayFigure.produit(i, 5),
        ].contains(valeur);
        expect(
          item.category == 0,
          dansLaTable,
          reason: '${item.text} est mal rangé',
        );
      }
    });

    test('l’addition répétée affichée compte le bon nombre de paquets', () {
      // La figure écrit « 6 + 6 + 6 + 6 » sous le rectangle : la somme
      // doit valoir le produit, et le nombre de termes le nombre de
      // lignes. C'est la définition que le chapitre donne en premier.
      for (final (int lignes, int colonnes) in <(int, int)>[
        (3, 5),
        (4, 7),
        (1, 9),
        (10, 10),
      ]) {
        final List<String> termes =
            ArrayFigure.addition(lignes, colonnes).split(' + ');
        expect(termes.length, lignes);
        final int somme = termes
            .map(int.parse)
            .reduce((int a, int b) => a + b);
        expect(somme, ArrayFigure.produit(lignes, colonnes));
      }
    });
  });

  group('Chapitre complet : les écosystèmes', () {
    late Chapter ecosystemes;

    setUpAll(() {
      ecosystemes = catalog.chapterById('svt-primaire-les-ecosystemes')!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (ecosystemes.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(ecosystemes.isPlayable, isTrue);
      expect(ecosystemes.lessons.length, 4);
    });

    test('les comptages d’espèces affamées sont refaits sur le réseau', () {
      expect(
        FoodWebFigure.affectees('Herbe').length,
        reponseNum('retirer-une-espece', 'q1'),
      );
      expect(
        FoodWebFigure.affectees('Renard').length,
        reponseNum('retirer-une-espece', 'q2'),
      );
      expect(
        FoodWebFigure.affectees('Criquet').length,
        reponseNum('defi-ecosystemes', 'q1'),
      );
    });

    test('la disparition se propage bien le long des chaînes', () {
      // Retirer l'herbe doit affamer les quatre autres, et pas
      // seulement ceux qui la mangeaient directement : c'est ce que le
      // chapitre appelle l'effondrement.
      expect(
        FoodWebFigure.affectees('Herbe'),
        <String>{'Lapin', 'Criquet', 'Renard', 'Oiseau'},
      );
      expect(FoodWebFigure.affectees('Lapin'), <String>{'Renard'});
      expect(FoodWebFigure.affectees('Criquet'), <String>{'Oiseau'});
      expect(FoodWebFigure.affectees('Oiseau'), isEmpty);
    });

    test('le tri des disparitions suit le réseau', () {
      final ClassifyQuestion q =
          ecosystemes.lessonById('defi-ecosystemes')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        expect(
          item.category == 0,
          FoodWebFigure.affectees(item.text).isNotEmpty,
          reason: '${item.text} est mal rangé',
        );
      }
    });

    test('les chaînes à remettre en ordre existent dans le réseau', () {
      // Chaque maillon doit vraiment manger le précédent : une chaîne
      // inventée passerait inaperçue à la relecture.
      for (final String question in <String>[
        'qui-mange-qui/q3',
        'defi-ecosystemes/q3',
      ]) {
        final List<String> parts = question.split('/');
        final OrderingQuestion q =
            ecosystemes.lessonById(parts[0])!.questions.firstWhere(
                  (Question x) => x.id == parts[1],
                )
                as OrderingQuestion;
        for (int i = 1; i < q.items.length; i++) {
          final Espece predateur = FoodWebFigure.reseau.firstWhere(
            (Espece e) => e.nom == q.items[i],
          );
          expect(
            predateur.mange,
            contains(q.items[i - 1]),
            reason: '${q.items[i]} ne mange pas ${q.items[i - 1]}',
          );
        }
        // Et la chaîne commence par un producteur.
        final Espece premier = FoodWebFigure.reseau.firstWhere(
          (Espece e) => e.nom == q.items.first,
        );
        expect(premier.estProducteur, isTrue);
      }
    });

    test('le réseau n’a qu’un producteur, et il nourrit tout le monde', () {
      final List<Espece> producteurs = FoodWebFigure.reseau
          .where((Espece e) => e.estProducteur)
          .toList();
      expect(producteurs.length, 1);
      // « Toute la nourriture du pré vient des plantes » : le retrait du
      // seul producteur doit affamer toutes les autres espèces.
      expect(
        FoodWebFigure.affectees(producteurs.single.nom).length,
        FoodWebFigure.reseau.length - 1,
      );
    });
  });

  group('Chapitre complet : priorités et nombres relatifs', () {
    late Chapter relatifs;

    setUpAll(() {
      relatifs =
          catalog.chapterById('maths-college-priorites-et-nombres-relatifs')!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (relatifs.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    /// Évalue une expression en respectant les priorités.
    ///
    /// Un chapitre qui enseigne les priorités ne peut pas vérifier ses
    /// propres corrigés en recopiant des résultats à côté : il lui faut
    /// une machine qui applique les règles. Celle-ci est volontairement
    /// courte — parenthèses, puis × et ÷, puis + et −, de gauche à
    /// droite — et c'est exactement ce que la leçon énonce.
    double evaluer(String expression) {
      final String texte = expression
          .replaceAll('−', '-')
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll(' ', '');
      int position = 0;
      // Déclarée d'avance : le facteur peut contenir une parenthèse, et
      // une parenthèse contient une somme. Dart n'accepte pas qu'une
      // fonction locale en appelle une déclarée plus bas.
      late final double Function() somme;

      double facteur() {
        if (texte[position] == '(') {
          position++;
          final double valeur = somme();
          position++; // la parenthèse fermante
          return valeur;
        }
        if (texte[position] == '-') {
          position++;
          return -facteur();
        }
        final int debut = position;
        while (position < texte.length &&
            RegExp(r'[0-9.]').hasMatch(texte[position])) {
          position++;
        }
        return double.parse(texte.substring(debut, position));
      }

      double produit() {
        double valeur = facteur();
        while (position < texte.length &&
            (texte[position] == '*' || texte[position] == '/')) {
          final String signe = texte[position++];
          final double suivant = facteur();
          valeur = signe == '*' ? valeur * suivant : valeur / suivant;
        }
        return valeur;
      }

      somme = () {
        double valeur = produit();
        while (position < texte.length &&
            (texte[position] == '+' || texte[position] == '-')) {
          final String signe = texte[position++];
          final double suivant = produit();
          valeur = signe == '+' ? valeur + suivant : valeur - suivant;
        }
        return valeur;
      };

      return somme();
    }

    test('est jouable de bout en bout', () {
      expect(relatifs.isPlayable, isTrue);
      expect(relatifs.lessons.length, 4);
    });

    test('l’évaluateur respecte bien les priorités', () {
      // Il sert à vérifier tout le reste : s'il se trompait, les
      // corrigés faux passeraient avec lui.
      expect(evaluer('3 + 4 × 5'), 23);
      expect(evaluer('(3 + 4) × 5'), 35);
      expect(evaluer('20 − 8 − 3'), 9);
      expect(evaluer('24 ÷ 4 × 2'), 12);
      expect(evaluer('(−8) + 5'), -3);
      expect(evaluer('7 − (−4)'), 11);
    });

    test('tous les calculs annoncés sont réévalués', () {
      final Map<String, String> calculs = <String, String>{
        'additionner-et-soustraire/q1': '3 + (−7)',
        'additionner-et-soustraire/q2': '(−5) + (−6)',
        'additionner-et-soustraire/q3': '(−2) − (−9)',
        'priorites/q1': '3 + 4 × 5',
        'priorites/q2': '(3 + 4) × 5',
        'priorites/q3': '20 − 8 − 3',
        'priorites/q4': '2 + 3 × (7 − 5)',
        'defi-relatifs/q1': '(−8) + 5',
        'defi-relatifs/q2': '7 − (−4)',
        'defi-relatifs/q3': '10 − 2 × 3',
        'defi-relatifs/q4': '24 ÷ 4 × 2',
      };
      calculs.forEach((String chemin, String expression) {
        final List<String> parts = chemin.split('/');
        expect(
          evaluer(expression),
          reponseNum(parts[0], parts[1]),
          reason: '$chemin : $expression',
        );
      });
    });

    test('les déplacements sur la droite donnent les mêmes résultats', () {
      // La figure et l'évaluateur doivent tomber d'accord : c'est ce qui
      // garantit que le dessin illustre bien le calcul écrit.
      expect(NumberLineFigure.arrivee(3, -7), evaluer('3 + (−7)'));
      expect(NumberLineFigure.arrivee(-5, -6), evaluer('(−5) + (−6)'));
      expect(NumberLineFigure.arrivee(-2, 9), evaluer('(−2) − (−9)'));
      expect(NumberLineFigure.arrivee(-8, 5), evaluer('(−8) + 5'));
      // Et l'écriture produite par la figure est celle du chapitre.
      expect(NumberLineFigure.ecriture(3, -7), '3 + (-7) = -4');
    });

    test('le tri par signe du résultat est juste', () {
      final ClassifyQuestion q =
          relatifs.lessonById('additionner-et-soustraire')!.questions
                  .firstWhere((Question x) => x.id == 'q4')
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        expect(
          item.category == 0,
          evaluer(item.text) < 0,
          reason: '${item.text} vaut ${evaluer(item.text)}',
        );
      }
    });

    test('le tri par résultat du défi est juste', () {
      final ClassifyQuestion q =
          relatifs.lessonById('defi-relatifs')!.questions.firstWhere(
                (Question x) => x.id == 'q5',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final double attendu = double.parse(
          q.categories[item.category].replaceAll('Fait ', ''),
        );
        expect(evaluer(item.text), attendu, reason: item.text);
      }
    });

    test('la remise en ordre des relatifs est croissante', () {
      final OrderingQuestion q =
          relatifs.lessonById('les-nombres-relatifs')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as OrderingQuestion;
      final List<double> valeurs = q.items.map(evaluer).toList();
      for (int i = 1; i < valeurs.length; i++) {
        expect(
          valeurs[i],
          greaterThan(valeurs[i - 1]),
          reason: '${q.items[i]} ne suit pas ${q.items[i - 1]}',
        );
      }
    });
  });

  group('Chapitre complet : fractions et proportions', () {
    late Chapter fractions;

    setUpAll(() {
      fractions = catalog.chapterById('maths-college-fractions-et-proportions')!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (fractions.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    ({int haut, int bas}) lire(String texte) {
      final List<String> morceaux = texte.split('/');
      return (haut: int.parse(morceaux[0]), bas: int.parse(morceaux[1]));
    }

    test('est jouable de bout en bout', () {
      expect(fractions.isPlayable, isTrue);
      expect(fractions.lessons.length, 4);
    });

    test('les écritures décimales annoncées sont exactes', () {
      expect(
        FractionBarFigure.valeur(3, 4),
        closeTo(reponseNum('fraction-quotient', 'q1'), 1e-9),
      );
      expect(
        FractionBarFigure.valeur(6, 4),
        closeTo(reponseNum('fraction-quotient', 'q2'), 1e-9),
      );
      expect(
        FractionBarFigure.valeur(7, 8),
        closeTo(reponseNum('defi-fractions-college', 'q1'), 1e-9),
      );
    });

    test('les fractions annoncées égales le sont vraiment', () {
      // 3/4 = 9/12 : le numérateur demandé doit donner une fraction
      // égale, pas seulement un nombre plausible.
      expect(
        FractionBarFigure.comparer(
          reponseNum('egalites-et-comparaison', 'q1').round(),
          12,
          3,
          4,
        ),
        0,
      );
      // 18/24 simplifié : le numérateur attendu est celui de la réduite.
      expect(
        FractionBarFigure.simplifier(18, 24).numerateur,
        reponseNum('egalites-et-comparaison', 'q4'),
      );
      for (final ClassifyItem item
          in (fractions.lessonById('defi-fractions-college')!.questions
                      .firstWhere((Question x) => x.id == 'q3')
                  as ClassifyQuestion)
              .items) {
        final ({int haut, int bas}) f = lire(item.text);
        expect(
          item.category == 0,
          FractionBarFigure.comparer(f.haut, f.bas, 3, 4) == 0,
          reason: '${item.text} est mal rangée',
        );
      }
    });

    test('le tri par rapport à 1 est juste', () {
      final ClassifyQuestion q =
          fractions.lessonById('egalites-et-comparaison')!.questions.firstWhere(
                (Question x) => x.id == 'q3',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final ({int haut, int bas}) f = lire(item.text);
        expect(
          item.category == 0,
          FractionBarFigure.comparer(f.haut, f.bas, 1, 1) > 0,
          reason: '${item.text} est mal rangée',
        );
      }
    });

    test('les comparaisons annoncées sont recalculées', () {
      // 2/3 contre 3/4, puis 5/6 contre 7/9 : les deux cas où les
      // numérateurs seuls induisent en erreur.
      expect(FractionBarFigure.comparer(3, 4, 2, 3), greaterThan(0));
      expect(FractionBarFigure.comparer(5, 6, 7, 9), greaterThan(0));
    });

    test('les fractions de quantités tombent juste', () {
      expect(
        60 * FractionBarFigure.valeur(3, 4),
        reponseNum('fraction-d-une-quantite', 'q1'),
      );
      expect(
        480 * FractionBarFigure.valeur(2, 5),
        reponseNum('fraction-d-une-quantite', 'q2'),
      );
      expect(
        320 * FractionBarFigure.valeur(25, 100),
        reponseNum('fraction-d-une-quantite', 'q3'),
      );
      // Une baisse de 30 % : le prix restant vaut 70 % du prix de départ.
      expect(
        40 * FractionBarFigure.valeur(70, 100),
        reponseNum('fraction-d-une-quantite', 'q4'),
      );
      expect(
        72 * FractionBarFigure.valeur(5, 6),
        reponseNum('defi-fractions-college', 'q2'),
      );
      expect(
        240 * FractionBarFigure.valeur(15, 100),
        reponseNum('defi-fractions-college', 'q4'),
      );
    });
  });

  group('Chapitre complet : si… alors', () {
    late Chapter implication;

    setUpAll(() {
      implication = catalog.chapterById('logique-college-si-alors')!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (implication.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(implication.isPlayable, isTrue);
      expect(implication.lessons.length, 4);
    });

    test('un seul des quatre cas rend l’implication fausse', () {
      // C'est l'affirmation centrale du chapitre, et le défi la
      // chiffre : quatre cas, un seul interdit.
      final List<(bool, bool)> cas = <(bool, bool)>[
        (true, true),
        (true, false),
        (false, true),
        (false, false),
      ];
      expect(cas.length, reponseNum('contrapposee', 'q4'));
      final List<(bool, bool)> fausses = cas
          .where(((bool, bool) c) => !ImplicationFigure.implique(c.$1, c.$2))
          .toList();
      expect(fausses, <(bool, bool)>[(true, false)]);
    });

    test('la réciproque peut tomber quand l’implication tient', () {
      // Le cas de l'arrosoir : pas de pluie, sol mouillé.
      expect(ImplicationFigure.implique(false, true), isTrue);
      expect(ImplicationFigure.implique(true, false), isFalse);
    });

    test('la contraposée vaut exactement l’implication', () {
      // « si P alors M » et « si non M alors non P » doivent s'accorder
      // sur les quatre cas : c'est ce que la leçon affirme, et ce qui la
      // distingue de la réciproque.
      for (final bool p in <bool>[true, false]) {
        for (final bool m in <bool>[true, false]) {
          expect(
            ImplicationFigure.implique(p, m),
            ImplicationFigure.implique(!m, !p),
            reason: 'P=$p, M=$m',
          );
        }
      }
      // Et la réciproque, elle, diverge sur au moins un cas.
      final bool memeVerite = <(bool, bool)>[
        (true, true),
        (true, false),
        (false, true),
        (false, false),
      ].every(
        ((bool, bool) c) =>
            ImplicationFigure.implique(c.$1, c.$2) ==
            ImplicationFigure.implique(c.$2, c.$1),
      );
      expect(memeVerite, isFalse);
    });

    test('les contre-exemples proposés en sont vraiment', () {
      // « pair ⇒ divisible par 4 » : la réponse doit être paire et non
      // divisible par 4.
      final int pair = reponseNum('reciproque', 'q2').round();
      expect(pair.isEven, isTrue);
      expect(pair % 4 == 0, isFalse);
      expect(pair, lessThan(10));
      // « divisible par 3 ⇒ divisible par 6 » : divisible par 3, pas
      // par 6.
      final int trois = reponseNum('defi-implication', 'q5').round();
      expect(trois % 3, 0);
      expect(trois % 6 == 0, isFalse);
    });

    test('le tri des contre-exemples suit la définition', () {
      // « divisible par 5 ⇒ finit par 0 » : contredire demande les deux
      // conditions à la fois.
      final ClassifyQuestion q =
          implication.lessonById('ce-que-promet-une-implication')!.questions
                  .firstWhere((Question x) => x.id == 'q3')
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final int n = int.parse(item.text);
        final bool contredit = n % 5 == 0 && n % 10 != 0;
        expect(item.category == 0, contredit, reason: item.text);
      }
    });

    test('le tri des implications vraies et fausses est juste', () {
      // Chaque énoncé est réévalué sur les nombres de 1 à 200, ou sur
      // la hiérarchie des quadrilatères selon le cas.
      bool toujours(bool Function(int) regle) =>
          List<int>.generate(200, (int i) => i + 1).every(regle);

      expect(toujours((int n) => n % 10 != 0 || n % 5 == 0), isTrue);
      expect(toujours((int n) => n % 2 != 0 || n % 4 == 0), isFalse);

      final ClassifyQuestion q =
          implication.lessonById('defi-implication')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as ClassifyQuestion;
      final Map<String, bool> verites = <String, bool>{
        'Si n est divisible par 10, alors n est divisible par 5':
            toujours((int n) => n % 10 != 0 || n % 5 == 0),
        'Si c\'est un carré, alors c\'est un rectangle': true,
        'Si n est pair, alors n est divisible par 4':
            toujours((int n) => n % 2 != 0 || n % 4 == 0),
        'Si c\'est un rectangle, alors c\'est un carré': false,
      };
      for (final ClassifyItem item in q.items) {
        expect(
          verites.containsKey(item.text),
          isTrue,
          reason: '${item.text} n’est pas évalué',
        );
        expect(item.category == 0, verites[item.text], reason: item.text);
      }
    });
  });

  group('Chapitre complet : électricité, circuits et lois', () {
    late Chapter electricite;

    setUpAll(() {
      electricite = catalog.chapterById(
        'physique-chimie-college-electricite-circuits-et-lois',
      )!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (electricite.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(electricite.isPlayable, isTrue);
      expect(electricite.lessons.length, 4);
    });

    test('dévisser une lampe n’a pas le même effet selon le montage', () {
      // C'est l'affirmation que les deux questions de la leçon posent,
      // et c'est la figure qui en décide.
      bool deuxieme({required bool serie, required bool premierePresente}) =>
          CircuitFigure.allumee(
            ferme: true,
            serie: serie,
            presenteIci: true,
            presenteAilleurs: premierePresente,
          );

      expect(deuxieme(serie: true, premierePresente: true), isTrue);
      expect(deuxieme(serie: true, premierePresente: false), isFalse);
      expect(deuxieme(serie: false, premierePresente: true), isTrue);
      expect(deuxieme(serie: false, premierePresente: false), isTrue);
    });

    test('un interrupteur ouvert éteint tout, quel que soit le montage', () {
      for (final bool serie in <bool>[true, false]) {
        for (final bool presente in <bool>[true, false]) {
          expect(
            CircuitFigure.allumee(
              ferme: false,
              serie: serie,
              presenteIci: presente,
              presenteAilleurs: true,
            ),
            isFalse,
            reason: 'série=$serie, lampe présente=$presente',
          );
        }
      }
    });

    test('une lampe dévissée ne s’allume jamais', () {
      for (final bool serie in <bool>[true, false]) {
        expect(
          CircuitFigure.allumee(
            ferme: true,
            serie: serie,
            presenteIci: false,
            presenteAilleurs: true,
          ),
          isFalse,
        );
      }
    });

    test('les lois des tensions et des intensités sont recalculées', () {
      // En série, les tensions s'ajoutent : la seconde lampe reçoit ce
      // que la première laisse.
      expect(6 - 2.5, reponseNum('tension-et-intensite', 'q1'));
      // En dérivation, chaque branche reçoit toute la tension.
      expect(6, reponseNum('tension-et-intensite', 'q2'));
      // En dérivation, les intensités s'ajoutent.
      expect(
        reponseNum('tension-et-intensite', 'q3'),
        closeTo(0.2 + 0.3, 1e-9),
      );
      // Trois lampes identiques en série sous 9 V.
      expect(9 / 3, reponseNum('defi-electricite', 'q1'));
      // En série, l'intensité est la même partout.
      expect(0.25, reponseNum('defi-electricite', 'q2'));
    });

    test('la loi d’Ohm est appliquée dans les deux sens', () {
      double tension(double r, double i) => r * i;
      double intensite(double u, double r) => u / r;

      expect(tension(20, 0.3), closeTo(reponseNum('tension-et-intensite', 'q4'), 1e-9));
      expect(intensite(10, 50), closeTo(reponseNum('defi-electricite', 'q4'), 1e-9));
      // Et les deux formes doivent se répondre.
      expect(intensite(tension(20, 0.3), 20), closeTo(0.3, 1e-9));
    });
  });

  group('Chapitre complet : les saisons et l’inclinaison', () {
    late Chapter saisons;

    setUpAll(() {
      saisons = catalog.chapterById(
        'astronomie-college-les-saisons-et-l-inclinaison',
      )!;
    });

    double reponseNum(String lessonId, String questionId) {
      final Question q = saisons.lessonById(lessonId)!.questions.firstWhere(
            (Question x) => x.id == questionId,
          );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    test('est jouable de bout en bout', () {
      expect(saisons.isPlayable, isTrue);
      expect(saisons.lessons.length, 4);
    });

    test('l’inclinaison et le cercle polaire s’accordent', () {
      expect(
        SeasonsFigure.inclinaison,
        closeTo(reponseNum('pas-une-question-de-distance', 'q4'), 1),
      );
      // Le cercle polaire est à 90° moins l'inclinaison : le chapitre
      // l'annonce comme une conséquence, pas comme une coïncidence.
      expect(
        90 - SeasonsFigure.inclinaison,
        closeTo(reponseNum('la-duree-du-jour', 'q2'), 0.1),
      );
    });

    test('les durées de jour annoncées sortent du calcul', () {
      // « À la mi-juin » et « à la mi-décembre » : 5,5 et 11,5 mois
      // écoulés depuis le 1er janvier.
      expect(
        SeasonsFigure.dureeDuJour(5.5),
        closeTo(reponseNum('la-duree-du-jour', 'q1'), 0.2),
      );
      expect(
        SeasonsFigure.dureeDuJour(11.5),
        closeTo(reponseNum('defi-saisons', 'q3'), 0.2),
      );
      // Aux équinoxes, douze heures partout.
      for (final double latitude in <double>[0, 20, 48.85, 65]) {
        expect(
          SeasonsFigure.dureeDuJour(
            SeasonsFigure.solsticeJuin - 3,
            latitude: latitude,
          ),
          closeTo(12, 0.05),
          reason: 'équinoxe de mars à $latitude°',
        );
        expect(
          SeasonsFigure.dureeDuJour(
            SeasonsFigure.solsticeJuin + 3,
            latitude: latitude,
          ),
          closeTo(12, 0.05),
          reason: 'équinoxe de septembre à $latitude°',
        );
      }
    });

    test('l’équateur ne connaît pas de saison de durée', () {
      // Le chapitre affirme que le jour y dure douze heures toute
      // l'année : on parcourt les douze mois plutôt que de le croire.
      for (int m = 0; m <= 12; m++) {
        expect(
          SeasonsFigure.dureeDuJour(m.toDouble(), latitude: 0),
          closeTo(12, 0.05),
          reason: 'mois $m',
        );
      }
    });

    test('au-delà du cercle polaire, le Soleil ne se couche plus', () {
      expect(SeasonsFigure.dureeDuJour(5.69, latitude: 70), 24);
      expect(SeasonsFigure.dureeDuJour(11.69, latitude: 70), 0);
      // Et juste en dessous de la limite, le jour reste fini.
      expect(SeasonsFigure.dureeDuJour(5.69, latitude: 60), lessThan(24));
    });

    test('les deux hémisphères ont toujours des saisons opposées', () {
      const Map<String, String> opposees = <String, String>{
        'hiver': 'été',
        'été': 'hiver',
        'printemps': 'automne',
        'automne': 'printemps',
      };
      for (int m = 0; m < 12; m++) {
        final String nord = SeasonsFigure.saisonNord(m.toDouble());
        expect(
          SeasonsFigure.saisonSud(m.toDouble()),
          opposees[nord],
          reason: 'mois $m',
        );
      }
    });

    test('le tri des mois suit la saison calculée', () {
      final ClassifyQuestion q =
          saisons.lessonById('defi-saisons')!.questions.firstWhere(
                (Question x) => x.id == 'q2',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final int index = SeasonsFigure.mois.indexOf(item.text);
        expect(index, isNot(-1), reason: '${item.text} inconnu');
        // On se place au milieu du mois.
        final String saison = SeasonsFigure.saisonNord(index + 0.5);
        expect(
          item.category == 0,
          saison == 'été',
          reason: '${item.text} est en $saison au nord',
        );
      }
    });

    test('le jour est bien plus long en juin qu’en décembre, à Paris', () {
      final double juin = SeasonsFigure.dureeDuJour(5.5);
      final double decembre = SeasonsFigure.dureeDuJour(11.5);
      expect(juin, greaterThan(decembre));
      // Le chapitre annonce un écart d'environ huit heures.
      expect(juin - decembre, closeTo(8, 1));
    });
  });

  group('Chapitre complet : la cellule', () {
    late Chapter cellule;

    setUpAll(() {
      cellule = catalog.chapterById(
        'svt-college-la-cellule-et-l-organisation-du-vivant',
      )!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (cellule.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(cellule.isPlayable, isTrue);
      expect(cellule.lessons.length, 4);
    });

    test('les comptages de constituants sont ceux de la figure', () {
      expect(
        CellFigure.organites(vegetale: false).length,
        reponseNum('dans-la-cellule', 'q2'),
      );
      expect(
        CellFigure.organites(vegetale: true).length,
        reponseNum('defi-cellule', 'q2'),
      );
      expect(
        CellFigure.propresAuxVegetaux.length,
        reponseNum('animale-ou-vegetale', 'q1'),
      );
      // Et les trois comptes doivent s'additionner.
      expect(
        CellFigure.organites(vegetale: false).length +
            CellFigure.propresAuxVegetaux.length,
        CellFigure.organites(vegetale: true).length,
      );
    });

    test('le tri des constituants suit la figure', () {
      final ClassifyQuestion q =
          cellule.lessonById('animale-ou-vegetale')!.questions.firstWhere(
                (Question x) => x.id == 'q2',
              )
              as ClassifyQuestion;
      final Set<String> vegetaux = CellFigure.propresAuxVegetaux
          .map((Organite o) => o.nom)
          .toSet();
      for (final ClassifyItem item in q.items) {
        expect(
          CellFigure.tous.any((Organite o) => o.nom == item.text),
          isTrue,
          reason: '${item.text} n’existe pas dans la figure',
        );
        expect(
          item.category == 0,
          vegetaux.contains(item.text),
          reason: '${item.text} est mal rangé',
        );
      }
    });

    test('les éléments appariés existent, et du bon côté', () {
      // Les quatre parties communes d'abord.
      final MatchingQuestion communes =
          cellule.lessonById('dans-la-cellule')!.questions.firstWhere(
                (Question x) => x.id == 'q1',
              )
              as MatchingQuestion;
      final Set<String> animales = CellFigure.organites(vegetale: false)
          .map((Organite o) => o.nom)
          .toSet();
      for (final MatchPair paire in communes.pairs) {
        expect(
          animales.contains(paire.left),
          isTrue,
          reason: '${paire.left} n’est pas dans la cellule animale',
        );
      }
      expect(communes.pairs.length, animales.length);

      // Puis les trois éléments propres aux végétaux.
      final MatchingQuestion vegetales =
          cellule.lessonById('defi-cellule')!.questions.firstWhere(
                (Question x) => x.id == 'q3',
              )
              as MatchingQuestion;
      final Set<String> propres = CellFigure.propresAuxVegetaux
          .map((Organite o) => o.nom)
          .toSet();
      expect(
        vegetales.pairs.map((MatchPair p) => p.left).toSet(),
        propres,
      );
    });

    test('chaque constituant de la figure porte un rôle lisible', () {
      // La figure affiche ce texte seul, sous le dessin : une phrase
      // vide ou tronquée ne se verrait qu'en jouant.
      for (final Organite o in CellFigure.tous) {
        expect(o.role.length, greaterThan(25), reason: o.nom);
        expect(o.role.endsWith('.'), isTrue, reason: o.nom);
      }
    });

    test('les conversions de tailles tombent juste', () {
      // Combien de cellules dans un millimètre : mille micromètres
      // divisés par la taille annoncée.
      expect(1000 / 10, reponseNum('tout-est-cellules', 'q1'));
      expect(1000 / 50, reponseNum('defi-cellule', 'q5'));
    });
  });

  group('Chapitre complet : la naissance de la géométrie', () {
    late Chapter geometrie;

    setUpAll(() {
      geometrie = catalog.chapterById(
        'histoire-sciences-college-naissance-de-la-geometrie',
      )!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (geometrie.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(geometrie.isPlayable, isTrue);
      expect(geometrie.lessons.length, 4);
    });

    test('le triangle de la corde est bien rectangle', () {
      // La corde à treize nœuds donne 3-4-5, et la figure travaille sur
      // 6-8-10 : il faut que les deux vérifient la réciproque.
      bool rectangle(double a, double b, double c) =>
          (a * a + b * b - c * c).abs() < 1e-9;

      expect(rectangle(3, 4, reponseNum('defi-geometrie', 'q2')), isTrue);
      expect(
        rectangle(
          TriangleTestFigure.sideA,
          TriangleTestFigure.sideB,
          reponseNum('arpenter-les-champs', 'q2'),
        ),
        isTrue,
      );
      // Et le grand côté de la figure doit bien être le double de celui
      // de la corde : c'est ce que la carte affirme.
      expect(
        reponseNum('arpenter-les-champs', 'q2'),
        2 * reponseNum('defi-geometrie', 'q2'),
      );
      // Le troisième côté réglable doit pouvoir atteindre cette valeur.
      expect(
        reponseNum('arpenter-les-champs', 'q2'),
        inInclusiveRange(TriangleTestFigure.minC, TriangleTestFigure.maxC),
      );
    });

    test('les intervalles de la corde font bien 3 + 4 + 5', () {
      expect(3 + 4 + 5, reponseNum('arpenter-les-champs', 'q1'));
    });

    test('les hauteurs déduites des ombres sont recalculées', () {
      // Le rapport hauteur sur ombre, mesuré sur le bâton, s'applique à
      // l'objet inaccessible.
      double hauteur({
        required double hauteurBaton,
        required double ombreBaton,
        required double ombreObjet,
      }) =>
          ombreObjet * hauteurBaton / ombreBaton;

      expect(
        hauteur(hauteurBaton: 2, ombreBaton: 2, ombreObjet: 30),
        reponseNum('la-preuve-grecque', 'q2'),
      );
      expect(
        hauteur(hauteurBaton: 1, ombreBaton: 2, ombreObjet: 14),
        reponseNum('la-preuve-grecque', 'q3'),
      );
      expect(
        hauteur(hauteurBaton: 1.5, ombreBaton: 3, ombreObjet: 60),
        reponseNum('defi-geometrie', 'q3'),
      );
    });
  });

  group('Chapitre complet : capteurs et actionneurs', () {
    late Chapter capteurs;

    setUpAll(() {
      capteurs = catalog.chapterById(
        'technologie-college-capteurs-et-actionneurs',
      )!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (capteurs.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(capteurs.isPlayable, isTrue);
      expect(capteurs.lessons.length, 4);
    });

    test('le cas limite du seuil est bien celui qu’annonce le chapitre', () {
      // « température < seuil » : à égalité, le chauffage reste éteint.
      // C'est la réponse de la question du cas limite, et elle doit
      // sortir de la figure, pas d'une relecture.
      expect(SensorChainFigure.chauffe(19, 19), isFalse);
      expect(SensorChainFigure.chauffe(18.9, 19), isTrue);
      expect(SensorChainFigure.chauffe(19.1, 19), isFalse);
    });

    test('changer le seuil change la décision à mesure constante', () {
      // L'affirmation de la première leçon : la décision dépend des
      // deux valeurs, pas de la seule mesure.
      const double mesure = 18;
      expect(SensorChainFigure.chauffe(mesure, 19), isTrue);
      expect(SensorChainFigure.chauffe(mesure, 17), isFalse);
    });

    test('l’écart à combler annoncé dans le défi est le bon', () {
      // Pièce à 23 °C, seuil à 20 °C : il faut descendre sous 20.
      final double ecart = reponseNum('defi-capteurs', 'q3');
      expect(23 - ecart, 20);
      expect(SensorChainFigure.chauffe(23 - ecart, 20), isFalse);
      expect(SensorChainFigure.chauffe(23 - ecart - 0.1, 20), isTrue);
    });

    test('les deux seuils du thermostat sont séparés de la bonne valeur', () {
      expect(20 - 19, reponseNum('programmer-un-objet', 'q2'));
      // Et entre les deux, la décision dépend de ce qui précède : c'est
      // précisément pourquoi un seul seuil ferait clignoter le radiateur.
      expect(SensorChainFigure.chauffe(19.5, 19), isFalse);
      expect(SensorChainFigure.chauffe(19.5, 20), isTrue);
    });
  });

  group('Chapitre complet : le jour, la nuit et les saisons', () {
    late Chapter jourNuit;

    setUpAll(() {
      jourNuit = catalog.chapterById(
        'astronomie-primaire-jour-nuit-et-saisons',
      )!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (jourNuit.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(jourNuit.isPlayable, isTrue);
      expect(jourNuit.lessons.length, 4);
    });

    test('les durées annoncées s’emboîtent', () {
      final double heuresParJour = reponseNum('le-jour-et-la-nuit', 'q1');
      final double joursParAn = reponseNum('l-annee', 'q1');
      final double moisParSaison = reponseNum('defi-jour-nuit', 'q2');
      final double saisons = reponseNum('les-quatre-saisons', 'q1');
      final double ansBissextile = reponseNum('l-annee', 'q2');

      expect(heuresParJour, 24);
      expect(saisons * moisParSaison, 12, reason: 'les saisons font l’année');
      // Les six heures mises de côté chaque année font un jour entier au
      // bout de quatre ans : c'est l'explication donnée par la leçon.
      expect(ansBissextile * 6, heuresParJour);
      // Et l'année réelle dépasse bien 365 jours d'un quart de jour.
      expect(joursParAn + 6 / heuresParJour, closeTo(365.25, 0.01));
    });

    test('le tri des mois suit les saisons calculées', () {
      // Le chapitre du collège et celui du primaire doivent s'accorder :
      // la même figure sert aux deux.
      final ClassifyQuestion q =
          jourNuit.lessonById('les-quatre-saisons')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final int index = SeasonsFigure.mois.indexOf(item.text);
        expect(index, isNot(-1), reason: '${item.text} inconnu');
        expect(
          item.category == 0,
          SeasonsFigure.saisonNord(index + 0.5) == 'été',
          reason: item.text,
        );
      }
    });

    test('les saisons à remettre en ordre se suivent vraiment', () {
      final OrderingQuestion q =
          jourNuit.lessonById('les-quatre-saisons')!.questions.firstWhere(
                (Question x) => x.id == 'q2',
              )
              as OrderingQuestion;
      // On relit l'ordre dans la figure, en parcourant l'année.
      final List<String> vues = <String>[];
      for (int demiMois = 0; demiMois < 24; demiMois++) {
        final String saison = SeasonsFigure.saisonNord(
          SeasonsFigure.solsticeJuin - 3 + demiMois / 2,
        );
        if (vues.isEmpty || vues.last != saison) vues.add(saison);
      }
      expect(
        q.items.map((String s) => s.toLowerCase()).toList(),
        vues.take(q.items.length).toList(),
      );
    });
  });

  group('Chapitre complet : diviser et partager', () {
    late Chapter division;

    setUpAll(() {
      division = catalog.chapterById('maths-primaire-diviser-et-partager')!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (division.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(division.isPlayable, isTrue);
      expect(division.lessons.length, 4);
    });

    test('chaque quotient annoncé se vérifie par la multiplication', () {
      // C'est exactement la méthode que le chapitre enseigne : on refait
      // le calcul à l'envers, avec la figure des jetons.
      final Map<String, (int, int)> partages = <String, (int, int)>{
        'partager-equitablement/q1': (12, 3),
        'partager-equitablement/q2': (24, 6),
        'partager-equitablement/q3': (20, 4),
        'combien-de-fois/q1': (35, 5),
        'combien-de-fois/q2': (48, 6),
        'combien-de-fois/q3': (42, 7),
        'defi-division/q1': (56, 8),
        'defi-division/q5': (45, 9),
      };
      partages.forEach((String chemin, (int, int) donnees) {
        final List<String> parts = chemin.split('/');
        final int quotient = reponseNum(parts[0], parts[1]).round();
        expect(
          ArrayFigure.produit(donnees.$2, quotient),
          donnees.$1,
          reason: '$chemin : ${donnees.$1} ÷ ${donnees.$2}',
        );
      });
    });

    test('les divisions avec reste se reconstituent', () {
      // dividende = diviseur × quotient + reste, et le reste doit être
      // plus petit que le diviseur : les deux moitiés de la règle.
      void verifier({
        required int dividende,
        required int diviseur,
        required double quotient,
        required double reste,
      }) {
        expect(
          ArrayFigure.produit(diviseur, quotient.round()) + reste.round(),
          dividende,
          reason: '$dividende ÷ $diviseur',
        );
        expect(reste, lessThan(diviseur));
      }

      verifier(
        dividende: 14,
        diviseur: 3,
        quotient: reponseNum('avec-un-reste', 'q1'),
        reste: reponseNum('avec-un-reste', 'q2'),
      );
      verifier(
        dividende: 23,
        diviseur: 5,
        quotient: reponseNum('avec-un-reste', 'q3'),
        reste: 3,
      );
      verifier(
        dividende: 27,
        diviseur: 4,
        quotient: reponseNum('defi-division', 'q2'),
        reste: reponseNum('defi-division', 'q3'),
      );
    });

    test('le tri des divisions qui tombent juste est exact', () {
      final ClassifyQuestion q =
          division.lessonById('defi-division')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final List<String> morceaux = item.text.split('÷');
        final int a = int.parse(morceaux[0].trim());
        final int b = int.parse(morceaux[1].trim());
        expect(item.category == 0, a % b == 0, reason: item.text);
      }
    });

    test('les deux lectures d’une même division donnent le même nombre', () {
      // Le tri de la deuxième leçon range des questions différentes
      // sous un même calcul : il faut que ce calcul soit bien le même.
      final ClassifyQuestion q =
          division.lessonById('combien-de-fois')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final List<String> categorie = q.categories[item.category]
            .replaceAll('Se résout par ', '')
            .split('÷');
        final int a = int.parse(categorie[0].trim());
        final int b = int.parse(categorie[1].trim());
        // Les nombres cités dans l'énoncé doivent être ceux du calcul.
        expect(
          item.text.contains('$a'),
          isTrue,
          reason: '${item.text} ne parle pas de $a',
        );
        expect(
          item.text.contains('$b'),
          isTrue,
          reason: '${item.text} ne parle pas de $b',
        );
        expect(a % b, 0, reason: 'le calcul ${q.categories[item.category]}');
      }
    });
  });

  group('Chapitre complet : le contre-exemple', () {
    late Chapter contreExemple;

    setUpAll(() {
      contreExemple = catalog.chapterById('logique-college-contre-exemple')!;
    });

    int reponseEntiere(String lessonId, String questionId) =>
        (contreExemple.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected
            .round();

    bool premier(int n) {
      if (n < 2) return false;
      for (int d = 2; d * d <= n; d++) {
        if (n % d == 0) return false;
      }
      return true;
    }

    test('est jouable de bout en bout', () {
      expect(contreExemple.isPlayable, isTrue);
      expect(contreExemple.lessons.length, 4);
    });

    test('chaque contre-exemple demandé en est bien un', () {
      // Un contre-exemple doit vérifier la condition et contredire la
      // conclusion : on contrôle les deux, séparément.
      void verifier(
        int valeur, {
        required bool Function(int) condition,
        required bool Function(int) conclusion,
        required String regle,
      }) {
        expect(condition(valeur), isTrue, reason: '$valeur ne vérifie pas « $regle »');
        expect(
          conclusion(valeur),
          isFalse,
          reason: '$valeur ne contredit pas « $regle »',
        );
      }

      verifier(
        reponseEntiere('un-seul-suffit', 'q1'),
        condition: premier,
        conclusion: (int n) => n.isOdd,
        regle: 'tout nombre premier est impair',
      );
      verifier(
        reponseEntiere('un-seul-suffit', 'q4'),
        condition: (int n) => n.isEven,
        conclusion: (int n) => n % 4 == 0,
        regle: 'tout nombre pair est divisible par 4',
      );
      verifier(
        reponseEntiere('fabriquer-un-contre-exemple', 'q1'),
        condition: (int n) => n % 3 == 0,
        conclusion: (int n) => n % 9 == 0,
        regle: 'tout multiple de 3 est multiple de 9',
      );
      verifier(
        reponseEntiere('fabriquer-un-contre-exemple', 'q2'),
        condition: (int n) => n % 10 == 5,
        conclusion: (int n) => n % 10 == 0,
        regle: 'un nombre finissant par 5 est divisible par 10',
      );
      verifier(
        reponseEntiere('defi-contre-exemple', 'q1'),
        condition: (int n) => n.isOdd,
        conclusion: premier,
        regle: 'tout nombre impair est premier',
      );
      verifier(
        reponseEntiere('defi-contre-exemple', 'q4'),
        condition: (int n) => n % 6 == 0,
        conclusion: (int n) => n % 4 == 0,
        regle: 'un multiple de 6 est multiple de 4',
      );
    });

    test('les bornes annoncées dans les énoncés sont respectées', () {
      expect(reponseEntiere('un-seul-suffit', 'q4'), lessThan(10));
      expect(reponseEntiere('defi-contre-exemple', 'q1'), lessThan(15));
      // « Le plus petit » : il ne doit exister aucun contre-exemple
      // plus petit.
      final int plusPetit = reponseEntiere('defi-contre-exemple', 'q4');
      for (int n = 1; n < plusPetit; n++) {
        expect(
          n % 6 == 0 && n % 4 != 0,
          isFalse,
          reason: '$n serait un contre-exemple plus petit',
        );
      }
    });

    test('le tri des multiples de 4 sépare bien les contre-exemples', () {
      final ClassifyQuestion q =
          contreExemple.lessonById('fabriquer-un-contre-exemple')!.questions
                  .firstWhere((Question x) => x.id == 'q4')
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final int n = int.parse(item.text);
        expect(
          item.category == 0,
          n % 4 == 0 && n % 8 != 0,
          reason: item.text,
        );
      }
    });

    test('le tri des affirmations vraies ou réfutables est juste', () {
      bool toujours(bool Function(int) regle) =>
          List<int>.generate(300, (int i) => i + 1).every(regle);

      final Map<String, bool> verites = <String, bool>{
        'Tout multiple de 10 est multiple de 5':
            toujours((int n) => n % 10 != 0 || n % 5 == 0),
        'Tout carré est un rectangle': true,
        'Tout nombre impair est premier':
            toujours((int n) => !n.isOdd || premier(n)),
        'Tout rectangle est un carré': false,
      };
      final ClassifyQuestion q =
          contreExemple.lessonById('defi-contre-exemple')!.questions.firstWhere(
                (Question x) => x.id == 'q2',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        expect(verites.containsKey(item.text), isTrue, reason: item.text);
        expect(item.category == 0, verites[item.text], reason: item.text);
      }
    });
  });

  group('Chapitre complet : algorithmes et instructions', () {
    late Chapter algos;

    setUpAll(() {
      algos = catalog.chapterById(
        'informatique-college-algorithmes-et-instructions',
      )!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (algos.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(algos.isPlayable, isTrue);
      expect(algos.lessons.length, 4);
    });

    test('les distances parcourues sont celles du robot', () {
      // On exécute le programme plutôt que de multiplier de tête : le
      // chemin de la figure est la référence.
      double casesParcourues(int tours) =>
          (LoopRobotFigure.chemin(tours).length - 1).toDouble();

      expect(casesParcourues(2), reponseNum('une-suite-d-instructions', 'q2'));
      expect(casesParcourues(3), reponseNum('decrire-sans-ambiguite', 'q3'));
      expect(casesParcourues(5), reponseNum('defi-algorithmes', 'q1'));
    });

    test('le chemin se referme au rythme annoncé', () {
      final ({int x, int y}) depart = LoopRobotFigure.chemin(0).first;
      final int tours = reponseNum('l-ordre-compte', 'q3').round();
      expect(LoopRobotFigure.chemin(tours).last, depart);

      // Et après huit tours, le robot est repassé deux fois par son
      // point de départ : c'est ce que compte le défi.
      int passages = 0;
      for (int t = 1; t <= 8; t++) {
        if (LoopRobotFigure.chemin(t).last == depart) passages++;
      }
      expect(passages, reponseNum('defi-algorithmes', 'q4'));
    });

    test('avancer puis tourner ne mène pas au même endroit', () {
      // L'affirmation de la deuxième leçon. « Avancer puis tourner »
      // est un tour de boucle ; « tourner puis avancer » revient à
      // partir avec un quart de tour d'avance, c'est-à-dire à regarder
      // le deuxième segment du chemin.
      final List<({int x, int y})> chemin = LoopRobotFigure.chemin(2);
      final ({int x, int y}) apresAvancer = chemin[LoopRobotFigure.pas];
      final ({int x, int y}) apresTournerPuisAvancer =
          chemin[LoopRobotFigure.pas * 2];
      expect(apresAvancer, isNot(apresTournerPuisAvancer));
    });
  });

  group('Chapitre complet : angles et triangles', () {
    late Chapter angles;

    setUpAll(() {
      angles = catalog.chapterById('maths-college-angles-et-triangles')!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (angles.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    /// Lit « 90°, 45°, 45° » ou « 3-4-5 ».
    List<double> nombres(String texte) => RegExp(r'\d+(?:[.,]\d+)?')
        .allMatches(texte)
        .map((RegExpMatch m) => double.parse(m.group(0)!.replaceAll(',', '.')))
        .toList();

    test('est jouable de bout en bout', () {
      expect(angles.isPlayable, isTrue);
      expect(angles.lessons.length, 4);
    });

    test('les troisièmes angles annoncés sont calculés', () {
      expect(
        TriangleAnglesFigure.troisieme(60, 70),
        reponseNum('somme-des-angles', 'q1'),
      );
      expect(
        TriangleAnglesFigure.troisieme(90, 35),
        reponseNum('somme-des-angles', 'q2'),
      );
      expect(
        TriangleAnglesFigure.troisieme(45, 65),
        reponseNum('defi-angles', 'q1'),
      );
      expect(
        TriangleAnglesFigure.troisieme(90, 28),
        reponseNum('defi-angles', 'q5'),
      );
      // Équilatéral et isocèle rectangle : deux partages égaux.
      expect(
        TriangleAnglesFigure.somme / 3,
        reponseNum('somme-des-angles', 'q4'),
      );
      expect(
        (TriangleAnglesFigure.somme - 90) / 2,
        reponseNum('nature-des-triangles', 'q1'),
      );
      expect(
        (TriangleAnglesFigure.somme - 40) / 2,
        reponseNum('defi-angles', 'q2'),
      );
    });

    test('les triplets d’angles possibles font bien 180°', () {
      final ClassifyQuestion q =
          angles.lessonById('defi-angles')!.questions.firstWhere(
                (Question x) => x.id == 'q3',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final List<double> trois = nombres(item.text);
        expect(trois.length, 3, reason: item.text);
        final double somme = trois.reduce((double a, double b) => a + b);
        expect(
          item.category == 0,
          somme == TriangleAnglesFigure.somme,
          reason: '${item.text} : somme $somme',
        );
      }
    });

    test('la nature annoncée est celle que la figure calcule', () {
      // Rectangle ou obtusangle : c'est le plus grand angle qui décide,
      // et la figure porte cette règle.
      final ClassifyQuestion q =
          angles.lessonById('nature-des-triangles')!.questions.firstWhere(
                (Question x) => x.id == 'q2',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final List<double> trois = nombres(item.text);
        expect(
          trois.reduce((double a, double b) => a + b),
          TriangleAnglesFigure.somme,
          reason: '${item.text} ne fait pas 180°',
        );
        final String nature =
            TriangleAnglesFigure.nature(trois[0], trois[1]);
        expect(
          item.category == 0,
          nature == 'rectangle',
          reason: '${item.text} est $nature',
        );
      }
    });

    test('l’inégalité triangulaire est appliquée, bornes comprises', () {
      bool possible(List<double> cotes) {
        final List<double> tries = <double>[...cotes]..sort();
        return tries[2] < tries[0] + tries[1];
      }

      final ClassifyQuestion q =
          angles.lessonById('inegalite-triangulaire')!.questions.firstWhere(
                (Question x) => x.id == 'q1',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        expect(
          item.category == 0,
          possible(nombres(item.text)),
          reason: item.text,
        );
      }

      // Les bornes entières du troisième côté, avec 5 et 8.
      final double maximum = reponseNum('inegalite-triangulaire', 'q2');
      final double minimum = reponseNum('inegalite-triangulaire', 'q3');
      expect(possible(<double>[5, 8, maximum]), isTrue);
      expect(possible(<double>[5, 8, maximum + 1]), isFalse);
      expect(possible(<double>[5, 8, minimum]), isTrue);
      expect(possible(<double>[5, 8, minimum - 1]), isFalse);
      // Et le cas du défi.
      expect(possible(<double>[7, 9, 15]), isTrue);
    });
  });

  group('Chapitre complet : mouvement et interactions', () {
    late Chapter mouvement;

    setUpAll(() {
      mouvement = catalog.chapterById(
        'physique-chimie-lycee-mouvement-et-interactions',
      )!;
    });

    double reponseNum(String lessonId, String questionId) =>
        (mouvement.lessonById(lessonId)!.questions.firstWhere(
                  (Question q) => q.id == questionId,
                )
                as NumericQuestion)
            .expected;

    test('est jouable de bout en bout', () {
      expect(mouvement.isPlayable, isTrue);
      expect(mouvement.lessons.length, 4);
    });

    test('les portées annoncées sortent du calcul', () {
      expect(
        ProjectileFigure.portee(20, 45),
        closeTo(reponseNum('chute-et-projectile', 'q3'), 0.1),
      );
      expect(
        ProjectileFigure.portee(25, 45),
        closeTo(reponseNum('defi-mouvement', 'q3'), 0.1),
      );
    });

    test('45° porte le plus loin, et aucun autre angle', () {
      // Le chapitre l'affirme : on balaie les angles plutôt que de s'en
      // remettre à la formule recopiée.
      double meilleure = 0;
      double meilleurAngle = 0;
      for (double a = 1; a < 90; a += 0.25) {
        final double d = ProjectileFigure.portee(20, a);
        if (d > meilleure) {
          meilleure = d;
          meilleurAngle = a;
        }
      }
      expect(meilleurAngle, closeTo(ProjectileFigure.angleOptimal, 0.3));
      expect(
        ProjectileFigure.angleOptimal,
        reponseNum('chute-et-projectile', 'q2'),
      );
    });

    test('deux angles complémentaires portent à la même distance', () {
      final double autre = reponseNum('chute-et-projectile', 'q4');
      expect(30 + autre, 90);
      for (final double a in <double>[20, 30, 35, 40]) {
        expect(
          ProjectileFigure.portee(20, a),
          closeTo(ProjectileFigure.portee(20, 90 - a), 1e-9),
          reason: '$a° et ${90 - a}°',
        );
        // Mais les trajectoires diffèrent : le tir incliné monte plus
        // haut, comme le dit la leçon.
        expect(
          ProjectileFigure.hauteurMax(20, 90 - a),
          greaterThan(ProjectileFigure.hauteurMax(20, a)),
        );
      }
    });

    test('la chute libre annoncée est recalculée', () {
      // t = racine(2h/g), puis v = g t. La masse n'intervient nulle part.
      const double hauteur = 20;
      final double t = math.sqrt(2 * hauteur / ProjectileFigure.g);
      expect(t, closeTo(reponseNum('defi-mouvement', 'q1'), 0.05));
      expect(
        ProjectileFigure.g * t,
        closeTo(reponseNum('defi-mouvement', 'q2'), 0.1),
      );
    });

    test('le temps de vol ne dépend que de la composante verticale', () {
      // C'est l'indépendance des deux mouvements : à vitesse verticale
      // égale, deux tirs durent autant.
      final double vy = 20 * math.sin(45 * math.pi / 180);
      for (final double v in <double>[20, 25, 30]) {
        final double angle = math.asin(vy / v) * 180 / math.pi;
        expect(
          ProjectileFigure.duree(v, angle),
          closeTo(ProjectileFigure.duree(20, 45), 1e-9),
          reason: 'v = $v',
        );
      }
    });
  });

  group('Chapitre complet : représentation des données', () {
    late Chapter donnees;

    setUpAll(() {
      donnees = catalog.chapterById(
        'informatique-lycee-representation-des-donnees',
      )!;
    });

    double reponseNum(String lessonId, String questionId) {
      final Question q = donnees.lessonById(lessonId)!.questions.firstWhere(
            (Question x) => x.id == questionId,
          );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    /// Lit « 0100 1101 » et rend les huit bits.
    List<bool> lireBits(String ecriture) => ecriture
        .replaceAll(' ', '')
        .split('')
        .map((String c) => c == '1')
        .toList();

    test('est jouable de bout en bout', () {
      expect(donnees.isPlayable, isTrue);
      expect(donnees.lessons.length, 4);
    });

    test('les capacités annoncées sont des puissances de deux', () {
      expect(1 << BinaryFigure.bits, reponseNum('pourquoi-deux-etats', 'q1'));
      expect(BinaryFigure.maximum, reponseNum('pourquoi-deux-etats', 'q2'));
      expect(1 << 10, reponseNum('pourquoi-deux-etats', 'q3'));
      // Le maximum est bien le nombre de valeurs moins une : c'est le
      // piège que la leçon signale.
      expect(
        reponseNum('pourquoi-deux-etats', 'q2'),
        reponseNum('pourquoi-deux-etats', 'q1') - 1,
      );
    });

    test('les écritures binaires citées valent ce qui est annoncé', () {
      expect(
        BinaryFigure.valeur(lireBits('0100 1101')),
        reponseNum('compter-en-binaire', 'q1'),
      );
      expect(
        BinaryFigure.valeur(lireBits('1100 1000')),
        reponseNum('compter-en-binaire', 'q2'),
      );
      expect(
        BinaryFigure.valeur(lireBits('0000 1111')),
        reponseNum('defi-representation', 'q1'),
      );
      // Et la conversion fait l'aller-retour.
      for (final int n in <int>[0, 1, 77, 128, 200, 255]) {
        expect(BinaryFigure.valeur(BinaryFigure.ecriture(n)), n);
      }
    });

    test('l’hexadécimal annoncé par la figure est le bon', () {
      expect(BinaryFigure.hexadecimal(77), '4D');
      expect(BinaryFigure.hexadecimal(255), 'FF');
      expect(BinaryFigure.hexadecimal(128), '80');
      expect(BinaryFigure.hexadecimal(0), '00');
      // Un chiffre hexadécimal vaut quatre bits : la question le dit, et
      // il faut que 2⁴ égale bien le nombre de chiffres de 0 à F.
      final int bitsParChiffre =
          reponseNum('compter-en-binaire', 'q3').round();
      expect(1 << bitsParChiffre, 16);
    });

    test('le tri des écritures binaires suit leur valeur', () {
      final ClassifyQuestion q =
          donnees.lessonById('compter-en-binaire')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final int valeur = BinaryFigure.valeur(lireBits(item.text));
        expect(item.category == 0, valeur < 16, reason: '${item.text} = $valeur');
      }
    });

    test('les tailles de données annoncées sont recalculées', () {
      // Couleurs codables sur trois octets.
      const int parComposante = 1 << BinaryFigure.bits;
      expect(
        parComposante * parComposante * parComposante,
        reponseNum('textes-et-images', 'q2'),
      );
      // Images : pixels × trois octets.
      expect(
        1920 * 1080 * 3 / 1e6,
        closeTo(reponseNum('textes-et-images', 'q3'), 0.1),
      );
      expect(100 * 100 * 3, reponseNum('defi-representation', 'q4'));
      // Le minimum de bits pour écrire 100.
      final int bits = reponseNum('defi-representation', 'q2').round();
      expect((1 << bits) - 1, greaterThanOrEqualTo(100));
      expect((1 << (bits - 1)) - 1, lessThan(100));
    });
  });

  group('Chapitre complet : les suites numériques', () {
    late Chapter suites;

    setUpAll(() {
      suites = catalog.chapterById('maths-lycee-suites-numeriques')!;
    });

    double reponseNum(String lessonId, String questionId) {
      final Question q = suites.lessonById(lessonId)!.questions.firstWhere(
            (Question x) => x.id == questionId,
          );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    /// Lit « 2, 5, 8, 11 ».
    List<double> lireTermes(String texte) =>
        texte.split(',').map((String s) => double.parse(s.trim())).toList();

    test('est jouable de bout en bout', () {
      expect(suites.isPlayable, isTrue);
      expect(suites.lessons.length, 4);
    });

    test('les termes annoncés sont ceux de la figure', () {
      double arithmetique(int n, double u0, double r) => SequenceFigure.terme(
        n,
        premier: u0,
        raison: r,
        geometrique: false,
      );
      double geometrique(int n, double u0, double q) => SequenceFigure.terme(
        n,
        premier: u0,
        raison: q,
        geometrique: true,
      );

      expect(arithmetique(4, 2, 3), reponseNum('definir-une-suite', 'q2'));
      expect(arithmetique(9, 2, 3), reponseNum('suites-arithmetiques', 'q1'));
      expect(arithmetique(10, 5, 4), reponseNum('suites-arithmetiques', 'q3'));
      expect(arithmetique(12, 7, 5), reponseNum('defi-suites', 'q1'));
      expect(geometrique(10, 1, 2), reponseNum('suites-geometriques', 'q1'));
      expect(geometrique(9, 2, 3), reponseNum('suites-geometriques', 'q2'));
      expect(geometrique(4, 64, 0.5), reponseNum('defi-suites', 'q5'));
    });

    test('les deux définitions donnent le même terme', () {
      // Le chapitre affirme que u(n) = 3n + 2 et la récurrence u₀ = 2,
      // u(n+1) = u(n) + 3 décrivent la même suite.
      for (int n = 0; n <= 12; n++) {
        expect(
          3 * n + 2,
          SequenceFigure.terme(n, premier: 2, raison: 3, geometrique: false),
          reason: 'rang $n',
        );
      }
      expect(
        reponseNum('definir-une-suite', 'q1'),
        reponseNum('definir-une-suite', 'q2'),
      );
    });

    test('les sommes annoncées sont recalculées', () {
      expect(
        SequenceFigure.somme(10, premier: 2, raison: 3, geometrique: false),
        reponseNum('suites-arithmetiques', 'q2'),
      );
      expect(
        SequenceFigure.somme(10, premier: 2, raison: 3, geometrique: true),
        reponseNum('defi-suites', 'q2'),
      );
      // La formule de la moyenne des extrêmes doit redonner la somme.
      final double premier =
          SequenceFigure.terme(0, premier: 2, raison: 3, geometrique: false);
      final double dernier =
          SequenceFigure.terme(9, premier: 2, raison: 3, geometrique: false);
      expect(
        10 * (premier + dernier) / 2,
        reponseNum('suites-arithmetiques', 'q2'),
      );
    });

    test('le tri arithmétique / géométrique est exact', () {
      final ClassifyQuestion q =
          suites.lessonById('suites-geometriques')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final List<double> termes = lireTermes(item.text);
        final double difference = termes[1] - termes[0];
        final double quotient = termes[1] / termes[0];
        final bool arithmetique = <int>[1, 2, 3].every(
          (int i) => (termes[i] - termes[i - 1] - difference).abs() < 1e-9,
        );
        final bool geometrique = <int>[1, 2, 3].every(
          (int i) => (termes[i] / termes[i - 1] - quotient).abs() < 1e-9,
        );
        expect(
          item.category == 0,
          arithmetique,
          reason: '${item.text} : arithmétique = $arithmetique',
        );
        expect(
          item.category == 1,
          geometrique,
          reason: '${item.text} : géométrique = $geometrique',
        );
      }
    });

    test('la géométrique finit toujours par dépasser l’arithmétique', () {
      // L'affirmation du défi : aucune raison additive ne rattrape une
      // raison multiplicative supérieure à 1.
      for (final double r in <double>[10, 100, 1000]) {
        bool depassee = false;
        for (int n = 0; n <= 60; n++) {
          final double arith =
              SequenceFigure.terme(n, premier: 1, raison: r, geometrique: false);
          final double geo =
              SequenceFigure.terme(n, premier: 1, raison: 2, geometrique: true);
          if (geo > arith) {
            depassee = true;
            break;
          }
        }
        expect(depassee, isTrue, reason: 'raison additive $r');
      }
    });

    test('l’épaisseur de la feuille pliée est bien celle annoncée', () {
      // 0,1 mm doublée vingt fois, exprimée en mètres.
      final double epaisseur =
          0.0001 * SequenceFigure.terme(20, premier: 1, raison: 2, geometrique: true);
      expect(epaisseur, closeTo(reponseNum('defi-suites', 'q3'), 1));
    });
  });

  group('Chapitre complet : ADN, gènes et expression', () {
    late Chapter adn;

    setUpAll(() {
      adn = catalog.chapterById('svt-lycee-adn-genes-et-expression')!;
    });

    double reponseNum(String lessonId, String questionId) {
      final Question q = adn.lessonById(lessonId)!.questions.firstWhere(
            (Question x) => x.id == questionId,
          );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    /// Lit « UUC vers UUU » et renvoie les deux codons.
    List<String> lireMutation(String texte) =>
        texte.split(' vers ').map((String s) => s.trim()).toList();

    test('est jouable de bout en bout', () {
      expect(adn.isPlayable, isTrue);
      expect(adn.lessons.length, 4);
    });

    test('le code génétique embarqué est complet et bien formé', () {
      // 4³ = 64 codons de trois bases, écrits avec le seul alphabet de l'ARN.
      expect(DnaFigure.code.length, 64);
      for (final String codon in DnaFigure.code.keys) {
        expect(codon.length, 3, reason: codon);
        for (final String base in codon.split('')) {
          expect(<String>['A', 'U', 'G', 'C'], contains(base), reason: codon);
        }
      }
      expect(DnaFigure.code.keys.toSet().length, 64);
    });

    test('les nombres annoncés se recomptent dans la table', () {
      final int arrets = DnaFigure.code.values
          .where((String acide) => acide == 'Stop')
          .length;
      final int acides = DnaFigure.code.values
          .where((String acide) => acide != 'Stop')
          .toSet()
          .length;

      expect(reponseNum('du-gene-a-la-proteine', 'q1'), DnaFigure.code.length);
      expect(reponseNum('du-gene-a-la-proteine', 'q2'), acides);
      expect(reponseNum('defi-adn', 'q1'), arrets);
      expect(
        reponseNum('defi-adn', 'q2'),
        DnaFigure.code.length - arrets,
      );
      // Le chapitre annonce 20 acides aminés et 3 arrêts : c'est bien ce que
      // porte la table, et c'est de là que vient la redondance du code.
      expect(acides, 20);
      expect(arrets, 3);
    });

    test('les mutations citées ont bien l’effet annoncé', () {
      // q1 : UUC vers UUU laisse la protéine identique.
      expect(DnaFigure.acideAmine('UUC'), DnaFigure.acideAmine('UUU'));
      // q2 : UAU vers UAA interrompt la traduction.
      expect(DnaFigure.acideAmine('UAU'), isNot('Stop'));
      expect(DnaFigure.acideAmine('UAA'), 'Stop');
    });

    test('le tri des mutations se recalcule depuis la table', () {
      final ClassifyQuestion q =
          adn.lessonById('les-mutations')!.questions.firstWhere(
                (Question x) => x.id == 'q3',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final List<String> codons = lireMutation(item.text);
        final bool silencieuse =
            DnaFigure.acideAmine(codons[0]) == DnaFigure.acideAmine(codons[1]);
        expect(
          item.category == 0,
          silencieuse,
          reason: '${item.text} : '
              '${DnaFigure.acideAmine(codons[0])} vers '
              '${DnaFigure.acideAmine(codons[1])}',
        );
      }
    });

    test('la troisième base est bien la plus tolérante', () {
      // Le cours affirme qu'une mutation sur la troisième base a de bonnes
      // chances d'être silencieuse. On balaie les 61 codons codants et les
      // trois positions, et on compare les proportions.
      final List<int> silencieuses = <int>[0, 0, 0];
      final List<int> essais = <int>[0, 0, 0];
      for (final String codon in DnaFigure.code.keys) {
        if (DnaFigure.acideAmine(codon) == 'Stop') continue;
        for (int position = 0; position < 3; position++) {
          for (final String base in <String>['A', 'U', 'G', 'C']) {
            if (codon[position] == base) continue;
            final String mute = codon.replaceRange(position, position + 1, base);
            essais[position]++;
            if (DnaFigure.acideAmine(mute) == DnaFigure.acideAmine(codon)) {
              silencieuses[position]++;
            }
          }
        }
      }
      final List<double> part = <double>[
        for (int i = 0; i < 3; i++) silencieuses[i] / essais[i],
      ];
      expect(part[2], greaterThan(0.5), reason: 'troisième base : ${part[2]}');
      expect(part[2], greaterThan(part[0]));
      expect(part[2], greaterThan(part[1]));
    });

    test('l’ARN est bien la copie complémentaire du brin d’ADN', () {
      // La figure affiche le brin transcrit au-dessus de l'ARN : base pour
      // base, l'un doit se déduire de l'autre, avec T là où l'ARN porte un A.
      expect(DnaFigure.brinTranscrit('AUGUUCGGA'), 'TACAAGCCT');
      for (final String codon in DnaFigure.code.keys) {
        final String brin = DnaFigure.brinTranscrit(codon);
        expect(brin.length, 3, reason: codon);
        expect(brin, isNot(contains('U')), reason: 'l’ADN ne porte pas d’U');
        for (int i = 0; i < 3; i++) {
          expect(
            DnaFigure.complement[codon[i]],
            brin[i],
            reason: '$codon / $brin',
          );
        }
      }
    });

    test('la traduction s’arrête au premier signal d’arrêt', () {
      // AUG UUC GGA UAA UUC : la dernière phénylalanine ne doit pas être lue.
      final List<String> proteine = DnaFigure.traduire('AUGUUCGGAUAAUUC');
      expect(proteine, <String>['Met', 'Phe', 'Gly']);
      expect(DnaFigure.codons('AUGUUCGGAUAAUUC'), hasLength(5));
    });

    test('le brin complémentaire du texte à trous est exact', () {
      const Map<String, String> face = <String, String>{
        'A': 'T',
        'T': 'A',
        'G': 'C',
        'C': 'G',
      };
      final FillBlanksQuestion q =
          adn.lessonById('l-adn-support')!.questions.firstWhere(
                (Question x) => x.id == 'q3',
              )
              as FillBlanksQuestion;
      // Le brin donné est A T G C, le modèle fournit T _ C _.
      expect(q.accepted[0].first, face['T']);
      expect(q.accepted[1].first, face['C']);
    });

    test('l’appariement proposé est celui des bases', () {
      const Map<String, String> face = <String, String>{'A': 'T', 'G': 'C'};
      final MatchingQuestion q =
          adn.lessonById('l-adn-support')!.questions.firstWhere(
                (Question x) => x.id == 'q2',
              )
              as MatchingQuestion;
      for (final MatchPair pair in q.pairs) {
        expect(face[pair.left], pair.right, reason: pair.left);
      }
    });
  });


  group('Chapitre complet : suites et régularités', () {
    late Chapter regularites;

    setUpAll(() {
      regularites =
          catalog.chapterById('logique-primaire-suites-et-regularites')!;
    });

    double reponseNum(String lessonId, String questionId) {
      final Question q =
          regularites.lessonById(lessonId)!.questions.firstWhere(
                (Question x) => x.id == questionId,
              );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    /// La couleur annoncée par la bonne réponse d'un QCM.
    String bonneReponse(String lessonId, String questionId) {
      final SingleChoiceQuestion q =
          regularites.lessonById(lessonId)!.questions.firstWhere(
                (Question x) => x.id == questionId,
              )
              as SingleChoiceQuestion;
      return q.options
          .firstWhere((AnswerOption o) => o.isCorrect)
          .text
          .toLowerCase();
    }

    /// Traduit « rond-bleu » en « bleue », tel que l'énoncé le dit.
    const Map<String, String> accordees = <String, String>{
      'rouge': 'rouge',
      'bleu': 'bleue',
      'vert': 'verte',
      'orange': 'orange',
    };
    String couleur(String element) => accordees[element.split('-').last]!;

    test('est jouable de bout en bout', () {
      expect(regularites.isPlayable, isTrue);
      expect(regularites.lessons.length, 4);
    });

    test('les motifs annoncés ont la longueur annoncée', () {
      expect(
        reponseNum('voir-la-regularite', 'q1'),
        PatternFigure.periode(0),
      );
      expect(
        reponseNum('voir-la-regularite', 'q2'),
        PatternFigure.periode(1),
      );
      // La suite croissante n'a pas de motif : elle ne reboucle jamais.
      expect(PatternFigure.periode(PatternFigure.croissante), 0);
    });

    test('les couleurs lointaines se recalculent sur la figure', () {
      // Les énoncés comptent les perles à partir de 1, la figure à partir
      // de 0 : c'est le décalage le plus facile à rater, donc on le rejoue.
      expect(
        bonneReponse('aller-plus-loin', 'q1'),
        couleur(PatternFigure.element(0, 9)),
      );
      expect(
        bonneReponse('defi-regularites', 'q2'),
        couleur(PatternFigure.element(0, 20)),
      );
      expect(
        bonneReponse('aller-plus-loin', 'q2'),
        couleur(PatternFigure.element(1, 9)),
      );
      expect(
        bonneReponse('defi-regularites', 'q3'),
        couleur(PatternFigure.element(1, 14)),
      );
    });

    test('le tri des perles rouges et bleues est exact', () {
      final ClassifyQuestion q =
          regularites.lessonById('aller-plus-loin')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        // « la 15e » → 15.
        final int rang = int.parse(
          RegExp(r'\d+').firstMatch(item.text)!.group(0)!,
        );
        final String attendu = PatternFigure.element(0, rang - 1);
        expect(
          item.category,
          attendu == 'rond-rouge' ? 0 : 1,
          reason: '${item.text} : $attendu',
        );
      }
    });

    test('les comptes de perles et de points sont recalculés', () {
      final int rouges = <int>[
        for (int i = 0; i < 10; i++) i,
      ].where((int i) => PatternFigure.element(0, i) == 'rond-rouge').length;
      expect(reponseNum('aller-plus-loin', 'q3'), rouges);

      // La 7e case de la suite croissante porte sept points.
      final int septieme = int.parse(
        PatternFigure.element(PatternFigure.croissante, 6).split('-').last,
      );
      expect(reponseNum('suites-qui-grandissent', 'q1'), septieme);

      int total = 0;
      for (int i = 0; i < 6; i++) {
        total += int.parse(
          PatternFigure.element(PatternFigure.croissante, i).split('-').last,
        );
      }
      expect(reponseNum('suites-qui-grandissent', 'q2'), total);
    });

    test('les propositions de la figure sont jouables', () {
      // Trois choix distincts, dont la bonne réponse : sans cela l'élève
      // tomberait juste par hasard, ou verrait deux cases identiques.
      for (int suite = 0; suite < PatternFigure.motifs.length; suite++) {
        for (int position = 0; position < 12; position++) {
          final List<String> choix =
              PatternFigure.propositions(suite, position);
          expect(choix, hasLength(3), reason: 'suite $suite, case $position');
          expect(choix.toSet(), hasLength(3), reason: 'doublon');
          expect(choix, contains(PatternFigure.element(suite, position)));
        }
      }
    });

    test('les suites périodiques rebouclent, la croissante jamais', () {
      for (int suite = 0; suite < 2; suite++) {
        final int periode = PatternFigure.periode(suite);
        for (int position = 0; position < 20; position++) {
          expect(
            PatternFigure.element(suite, position),
            PatternFigure.element(suite, position + periode),
            reason: 'suite $suite, case $position',
          );
        }
      }
      final Set<String> vues = <String>{};
      for (int position = 0; position < 20; position++) {
        final String element =
            PatternFigure.element(PatternFigure.croissante, position);
        expect(vues.add(element), isTrue, reason: '$element revient');
      }
    });
  });


  group('Chapitre complet : programmer des déplacements', () {
    late Chapter robot;

    setUpAll(() {
      robot = catalog.chapterById(
        'informatique-primaire-programmer-des-deplacements',
      )!;
    });

    double reponseNum(String lessonId, String questionId) {
      final Question q = robot.lessonById(lessonId)!.questions.firstWhere(
            (Question x) => x.id == questionId,
          );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    /// Les cases réellement traversées pour [tours] répétitions.
    int casesParcourues(int tours) =>
        LoopRobotFigure.chemin(tours).length - 1;

    test('est jouable de bout en bout', () {
      expect(robot.isPlayable, isTrue);
      expect(robot.lessons.length, 4);
    });

    test('le carré se referme à quatre tours, et pas avant', () {
      final List<({int x, int y})> quatre = LoopRobotFigure.chemin(4);
      expect(quatre.last, quatre.first, reason: 'le carré doit se refermer');
      for (final int tours in <int>[1, 2, 3]) {
        final List<({int x, int y})> partiel =
            LoopRobotFigure.chemin(tours);
        expect(
          partiel.last == partiel.first,
          isFalse,
          reason: '$tours tours ne doivent pas refermer le chemin',
        );
      }
      expect(reponseNum('repeter-sans-recopier', 'q1'), 4);
      // Un côté par tour : c'est ce que le défi annonce.
      expect(reponseNum('defi-deplacements', 'q3'), 4);
    });

    test('les cases parcourues sont celles qu’annoncent les énoncés', () {
      expect(reponseNum('avancer-et-tourner', 'q1'), casesParcourues(3));
      expect(reponseNum('defi-deplacements', 'q1'), casesParcourues(3));
      // Deux cases par tour, « tourner » ne déplace rien.
      for (int tours = 1; tours <= 4; tours++) {
        expect(casesParcourues(tours), tours * LoopRobotFigure.pas);
      }
    });

    test('le nombre d’ordres exécutés est bien le double des tours', () {
      // La boucle s'écrit en une ligne mais exécute deux ordres par tour.
      expect(reponseNum('repeter-sans-recopier', 'q2'), 4 * 2);
    });

    test('le cinquième tour repasse sur un côté déjà parcouru', () {
      final Set<String> deja = LoopRobotFigure.chemin(4)
          .map((({int x, int y}) p) => '${p.x},${p.y}')
          .toSet();
      final List<({int x, int y})> cinq = LoopRobotFigure.chemin(5);
      for (int i = 8; i < cinq.length; i++) {
        expect(
          deja,
          contains('${cinq[i].x},${cinq[i].y}'),
          reason: 'la case ${cinq[i]} devrait déjà avoir été visitée',
        );
      }
    });

    test('deux quarts de tour font bien un demi-tour', () {
      // Le premier côté et le troisième doivent se parcourir en sens
      // opposés : c'est l'affirmation de la question sur les directions.
      final List<({int x, int y})> chemin = LoopRobotFigure.chemin(4);
      final ({int x, int y}) premier = (
        x: chemin[1].x - chemin[0].x,
        y: chemin[1].y - chemin[0].y,
      );
      final ({int x, int y}) troisieme = (
        x: chemin[5].x - chemin[4].x,
        y: chemin[5].y - chemin[4].y,
      );
      expect(troisieme.x, -premier.x);
      expect(troisieme.y, -premier.y);
      expect(reponseNum('avancer-et-tourner', 'q3'), 4);
    });

    test('le robot ne sort jamais de la grille', () {
      for (int tours = 0; tours <= 8; tours++) {
        for (final ({int x, int y}) p in LoopRobotFigure.chemin(tours)) {
          expect(p.x, inInclusiveRange(0, LoopRobotFigure.cotes - 1));
          expect(p.y, inInclusiveRange(0, LoopRobotFigure.cotes - 1));
        }
      }
    });
  });


  group('Chapitre complet : le Soleil et les planètes', () {
    late Chapter systeme;

    setUpAll(() {
      systeme = catalog.chapterById(
        'astronomie-primaire-le-soleil-et-les-planetes',
      )!;
    });

    double reponseNum(String lessonId, String questionId) {
      final Question q = systeme.lessonById(lessonId)!.questions.firstWhere(
            (Question x) => x.id == questionId,
          );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    Planete parNom(String nom) =>
        planetes.firstWhere((Planete p) => p.nom == nom);

    test('est jouable de bout en bout', () {
      expect(systeme.isPlayable, isTrue);
      expect(systeme.lessons.length, 4);
    });

    test('les comptes de planètes sont ceux de la table', () {
      expect(reponseNum('les-huit-planetes', 'q1'), planetes.length);
      // La Terre est la troisième en partant du Soleil.
      expect(
        planetes.indexWhere((Planete p) => p.nom == 'Terre') + 1,
        reponseNum('defi-soleil-planetes', 'q1'),
      );
      // Les quatre rocheuses sont celles d'avant Jupiter.
      final int rocheuses =
          planetes.indexWhere((Planete p) => p.nom == 'Jupiter');
      expect(reponseNum('defi-soleil-planetes', 'q6'), rocheuses);
      expect(rocheuses, 4);
    });

    test('la table est bien rangée par distance croissante', () {
      // Tout le chapitre repose sur cet ordre : si la table changeait,
      // la remise en ordre des planètes deviendrait fausse en silence.
      for (int i = 1; i < planetes.length; i++) {
        expect(
          planetes[i].distance,
          greaterThan(planetes[i - 1].distance),
          reason: planetes[i].nom,
        );
      }
      final OrderingQuestion q =
          systeme.lessonById('les-huit-planetes')!.questions.firstWhere(
                (Question x) => x.id == 'q2',
              )
              as OrderingQuestion;
      final List<double> distances = q.items
          .map((String nom) => parNom(nom.replaceAll('la ', '')).distance)
          .toList();
      for (int i = 1; i < distances.length; i++) {
        expect(distances[i], greaterThan(distances[i - 1]));
      }
    });

    test('Mercure est la plus proche et Jupiter la plus grosse', () {
      final Planete proche = planetes.reduce(
        (Planete a, Planete b) => a.distance < b.distance ? a : b,
      );
      expect(proche.nom, 'Mercure');
      final Planete grosse = planetes.reduce(
        (Planete a, Planete b) => a.diametre > b.diametre ? a : b,
      );
      expect(grosse.nom, 'Jupiter');
      // « Toutes les autres planètes réunies tiendraient à l'intérieur » :
      // c'est une affaire de volumes, pas de diamètres. Additionner les
      // diamètres donnerait le résultat inverse, et l'affirmation serait
      // fausse — c'est ce test qui a attrapé la première version.
      double volume(Planete p) => math.pow(p.diametre, 3).toDouble();
      final double autres = planetes
          .where((Planete p) => p.nom != 'Jupiter')
          .fold(0.0, (double somme, Planete p) => somme + volume(p));
      expect(volume(grosse), greaterThan(autres));
    });

    test('les rapports annoncés se recalculent', () {
      final double terre = parNom('Terre').diametre;
      expect(
        parNom('Jupiter').diametre / terre,
        closeTo(reponseNum('les-huit-planetes', 'q4'), 0.5),
      );
      expect(
        parNom('Neptune').distance / parNom('Terre').distance,
        closeTo(reponseNum('surtout-du-vide', 'q1'), 1),
      );
    });

    test('les temps de lumière annoncés sont les bons', () {
      expect(
        SolarSystemFigure.minutesLumiere(parNom('Terre').distance),
        closeTo(reponseNum('le-soleil-notre-etoile', 'q2'), 0.5),
      );
      expect(
        SolarSystemFigure.minutesLumiere(parNom('Neptune').distance),
        closeTo(reponseNum('surtout-du-vide', 'q2'), 5),
      );
    });

    test('le tri rocheuses / géantes suit la table', () {
      final ClassifyQuestion q =
          systeme.lessonById('les-huit-planetes')!.questions.firstWhere(
                (Question x) => x.id == 'q3',
              )
              as ClassifyQuestion;
      final int premiereGeante =
          planetes.indexWhere((Planete p) => p.nom == 'Jupiter');
      for (final ClassifyItem item in q.items) {
        final int rang =
            planetes.indexWhere((Planete p) => p.nom == item.text);
        expect(rang, isNonNegative, reason: item.text);
        expect(
          item.category,
          rang < premiereGeante ? 0 : 1,
          reason: item.text,
        );
        // Une géante est forcément plus grosse que toutes les rocheuses.
        if (item.category == 1) {
          expect(
            planetes[rang].diametre,
            greaterThan(parNom('Terre').diametre),
            reason: item.text,
          );
        }
      }
    });

    test('l’image du Soleil-balle garde les bonnes proportions', () {
      // « La Terre à vingt mètres, Neptune à six cents. »
      final double facteur = 20 / parNom('Terre').distance;
      expect(parNom('Neptune').distance * facteur, closeTo(600, 50));
    });
  });


  group('Chapitre complet : comment ça tient, comment ça bouge', () {
    late Chapter objets;

    setUpAll(() {
      objets = catalog.chapterById('technologie-primaire-comment-ca-bouge')!;
    });

    double reponseNum(String lessonId, String questionId) {
      final Question q = objets.lessonById(lessonId)!.questions.firstWhere(
            (Question x) => x.id == questionId,
          );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    String bonneReponse(String lessonId, String questionId) {
      final SingleChoiceQuestion q =
          objets.lessonById(lessonId)!.questions.firstWhere(
                (Question x) => x.id == questionId,
              )
              as SingleChoiceQuestion;
      return q.options.firstWhere((AnswerOption o) => o.isCorrect).text;
    }

    test('est jouable de bout en bout', () {
      expect(objets.isPlayable, isTrue);
      expect(objets.lessons.length, 4);
    });

    test('les rapports de transmission sont ceux de la figure', () {
      // 12 dents qui en entraînent 6 : deux tours pour un.
      expect(
        GearsFigure.rapport(12, 6),
        reponseNum('plus-vite-ou-plus-fort', 'q1'),
      );
      // 12 dents qui en entraînent 24 : il faut deux tours de la menante
      // pour un tour de la menée, donc un seul tour pendant deux.
      expect(
        GearsFigure.rapport(12, 24) * 2,
        reponseNum('plus-vite-ou-plus-fort', 'q2'),
      );
      expect(
        GearsFigure.rapport(12, 4),
        reponseNum('defi-tenir-bouger', 'q1'),
      );
    });

    test('le rapport ne dépend que du nombre de dents', () {
      // L'affirmation du cours : « tout se joue sur le nombre de dents ».
      // Doubler les deux roues ne change donc rien au rapport.
      for (final int menante in <int>[6, 12, 24]) {
        for (final int menee in <int>[4, 6, 12, 24]) {
          expect(
            GearsFigure.rapport(menante, menee),
            closeTo(GearsFigure.rapport(menante * 2, menee * 2), 1e-9),
            reason: '$menante / $menee',
          );
        }
      }
    });

    test('le sens de rotation suit la parité du nombre de roues', () {
      expect(GearsFigure.memeSens(2), isFalse);
      expect(
        bonneReponse('ca-bouge', 'q2'),
        GearsFigure.memeSens(3)
            ? 'Oui, dans le même sens'
            : 'Non, en sens contraire',
      );
      expect(
        bonneReponse('ca-bouge', 'q3'),
        GearsFigure.memeSens(4)
            ? 'Oui, dans le même sens'
            : 'Non, en sens contraire',
      );
      expect(
        bonneReponse('defi-tenir-bouger', 'q2'),
        GearsFigure.memeSens(5)
            ? 'Oui, dans le même sens'
            : 'Non, en sens contraire',
      );
    });

    test('plus de dents veut bien dire moins de tours', () {
      // L'affirmation du défi, vérifiée sur toute la plage de la figure.
      double precedent = double.infinity;
      for (int dents = 4; dents <= 36; dents++) {
        final double tours = GearsFigure.rapport(
          GearsFigure.dentsMenante,
          dents,
        );
        expect(tours, lessThan(precedent), reason: '$dents dents');
        precedent = tours;
      }
    });
  });


  group('Chapitre complet : mesurer le monde', () {
    late Chapter mesures;

    setUpAll(() {
      mesures =
          catalog.chapterById('histoire-sciences-primaire-mesurer-le-monde')!;
    });

    double reponseNum(String lessonId, String questionId) {
      final Question q = mesures.lessonById(lessonId)!.questions.firstWhere(
            (Question x) => x.id == questionId,
          );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    test('est jouable de bout en bout', () {
      expect(mesures.isPlayable, isTrue);
      expect(mesures.lessons.length, 4);
    });

    test('un cinquantième de tour fait bien l’angle annoncé', () {
      expect(360 / 50, closeTo(reponseNum('mesurer-la-terre', 'q1'), 0.2));
    });

    test('la mesure d’Ératosthène se refait sur la figure', () {
      final double angle = reponseNum('mesurer-la-terre', 'q1');
      final double trouvee = EratostheneFigure.circonference(angle, 800);
      expect(trouvee, closeTo(reponseNum('mesurer-la-terre', 'q2'), 500));
      // « Moins de 1 pour cent d'erreur », dit l'explication.
      const double reelle = 2 * math.pi * EratostheneFigure.rayonTerre;
      expect((trouvee - reelle).abs() / reelle, lessThan(0.01));
    });

    test('l’écart annoncé entre 40 000 km et la vraie valeur est exact', () {
      const double reelle = 2 * math.pi * EratostheneFigure.rayonTerre;
      expect(
        reelle - 40000,
        closeTo(reponseNum('defi-mesurer-le-monde', 'q2'), 5),
      );
    });

    test('le quart de méridien est bien le quart du tour', () {
      expect(
        reponseNum('une-mesure-pour-tous', 'q1') / 4,
        closeTo(reponseNum('defi-mesurer-le-monde', 'q4'), 50),
      );
      // Le mètre : dix-millionième du quart. Le compte doit retomber.
      final double quartEnMetres =
          reponseNum('defi-mesurer-le-monde', 'q4') *
          reponseNum('une-mesure-pour-tous', 'q2');
      expect(quartEnMetres, closeTo(1e7, 5e4));
    });

    test('la méthode marche pour d’autres villes', () {
      // Si le raisonnement tient, n'importe quel couple angle / distance
      // pris sur la vraie Terre doit redonner la même circonférence.
      const double reelle = 2 * math.pi * EratostheneFigure.rayonTerre;
      for (final double angle in <double>[2, 5, 7.2, 12, 30]) {
        final double distance = EratostheneFigure.distancePourAngle(angle);
        expect(
          EratostheneFigure.circonference(angle, distance),
          closeTo(reelle, 1),
          reason: 'angle de $angle degrés',
        );
      }
    });
  });


  group('Chapitre complet : les états de l’eau au primaire', () {
    late Chapter etats;

    setUpAll(() {
      etats = catalog.chapterById(
        'physique-chimie-primaire-les-etats-de-la-matiere',
      )!;
    });

    double reponseNum(String lessonId, String questionId) {
      final Question q = etats.lessonById(lessonId)!.questions.firstWhere(
            (Question x) => x.id == questionId,
          );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    String bonneReponse(String lessonId, String questionId) {
      final SingleChoiceQuestion q =
          etats.lessonById(lessonId)!.questions.firstWhere(
                (Question x) => x.id == questionId,
              )
              as SingleChoiceQuestion;
      return q.options.firstWhere((AnswerOption o) => o.isCorrect).text;
    }

    /// Le nom d'état tel que les énoncés l'écrivent.
    String nomEtat(double celsius) => switch (StatesFigure.etat(celsius)) {
      EtatMatiere.solide => 'Solide',
      EtatMatiere.liquide => 'Liquide',
      EtatMatiere.gaz => 'Gaz',
    };

    test('est jouable de bout en bout', () {
      expect(etats.isPlayable, isTrue);
      expect(etats.lessons.length, 4);
    });

    test('les deux seuils annoncés sont ceux de la figure', () {
      expect(reponseNum('changer-d-etat', 'q1'), StatesFigure.fusion);
      expect(reponseNum('changer-d-etat', 'q2'), StatesFigure.ebullition);
      expect(
        StatesFigure.ebullition - StatesFigure.fusion,
        reponseNum('defi-etats', 'q3'),
      );
    });

    test('les états annoncés sont ceux que calcule la figure', () {
      expect(bonneReponse('changer-d-etat', 'q3'), nomEtat(20));
      expect(bonneReponse('defi-etats', 'q1'), nomEtat(-10));
      expect(bonneReponse('defi-etats', 'q2'), nomEtat(150));
    });

    test('les seuils séparent bien les trois états', () {
      // Juste en dessous, juste au-dessus : c'est là qu'une erreur de
      // comparaison stricte se verrait.
      expect(StatesFigure.etat(-0.1), EtatMatiere.solide);
      expect(StatesFigure.etat(0), EtatMatiere.liquide);
      expect(StatesFigure.etat(99.9), EtatMatiere.liquide);
      expect(StatesFigure.etat(100), EtatMatiere.gaz);
      for (double t = -40; t <= 200; t += 0.5) {
        final EtatMatiere etat = StatesFigure.etat(t);
        if (t < StatesFigure.fusion) {
          expect(etat, EtatMatiere.solide, reason: '$t');
        } else if (t < StatesFigure.ebullition) {
          expect(etat, EtatMatiere.liquide, reason: '$t');
        } else {
          expect(etat, EtatMatiere.gaz, reason: '$t');
        }
      }
    });

    test('le nombre de particules est une constante, pas un réglage', () {
      // « Rien ne se perd » : la leçon demande que le compte de billes ne
      // dépende d'aucune température. Le vérifier en balayant le
      // thermomètre serait une tautologie — `particules` est une
      // constante. Ce qui se vérifie ici, c'est qu'elle en est bien une,
      // et qu'aucune signature de la figure ne la fait dépendre de l'état.
      expect(StatesFigure.particules, 36);
    });

    test('le rangement du plus froid au plus chaud suit les seuils', () {
      final OrderingQuestion q =
          etats.lessonById('defi-etats')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as OrderingQuestion;
      const Map<String, double> temoins = <String, double>{
        'la glace': -10,
        'l’eau liquide': 20,
        'la vapeur': 150,
      };
      final List<double> suite = q.items
          .map((String item) => temoins[item.replaceAll("'", '’')]!)
          .toList();
      for (int i = 1; i < suite.length; i++) {
        expect(suite[i], greaterThan(suite[i - 1]));
        expect(
          StatesFigure.etat(suite[i]),
          isNot(StatesFigure.etat(suite[i - 1])),
        );
      }
    });
  });


  group('Chapitre complet : les circuits au primaire', () {
    late Chapter circuits;

    setUpAll(() {
      circuits = catalog.chapterById(
        'physique-chimie-primaire-les-circuits-electriques',
      )!;
    });

    bool reponseVF(String lessonId, String questionId) {
      final TrueFalseQuestion q =
          circuits.lessonById(lessonId)!.questions.firstWhere(
                (Question x) => x.id == questionId,
              )
              as TrueFalseQuestion;
      return q.expected;
    }

    test('est jouable de bout en bout', () {
      expect(circuits.isPlayable, isTrue);
      expect(circuits.lessons.length, 4);
    });

    test('la mise en garde électrique est bien une carte d’avertissement', () {
      // Un enfant doit voir que cette carte n'est pas une astuce avant même
      // de l'avoir lue : le type de carte porte cette distinction.
      final Lesson boucle = circuits.lessonById('une-boucle-fermee')!;
      final LessonCard garde = boucle.cards.firstWhere(
        (LessonCard c) => c.kind == LessonCardKind.avertissement,
      );
      expect(garde.body, contains('pile'));
      expect(garde.body, contains('prise'));
    });

    test('les trois situations du défi se recalculent sur la figure', () {
      // Interrupteur ouvert, dérivation, les deux lampes : éteint.
      expect(
        CircuitFigure.allumee(
          ferme: false,
          serie: false,
          presenteIci: true,
          presenteAilleurs: true,
        ),
        reponseVF('defi-circuits', 'q1'),
      );
      // Fermé, dérivation, l'autre lampe retirée : allumé quand même.
      expect(
        CircuitFigure.allumee(
          ferme: true,
          serie: false,
          presenteIci: true,
          presenteAilleurs: false,
        ),
        reponseVF('defi-circuits', 'q2'),
      );
      // Fermé, série, l'autre lampe retirée : éteint.
      expect(
        CircuitFigure.allumee(
          ferme: true,
          serie: true,
          presenteIci: true,
          presenteAilleurs: false,
        ),
        reponseVF('defi-circuits', 'q3'),
      );
    });

    test('le tri des quatre situations est exact', () {
      final ClassifyQuestion q =
          circuits.lessonById('defi-circuits')!.questions.firstWhere(
                (Question x) => x.id == 'q4',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final bool ferme = item.text.startsWith('fermé');
        final bool serie = item.text.contains('en série');
        final bool autrePresente = !item.text.contains('retirée');
        final bool allumee = CircuitFigure.allumee(
          ferme: ferme,
          serie: serie,
          presenteIci: true,
          presenteAilleurs: autrePresente,
        );
        expect(item.category, allumee ? 0 : 1, reason: item.text);
      }
    });

    test('l’interrupteur ouvert éteint tout, quel que soit le montage', () {
      // L'affirmation de la troisième leçon, balayée sur tous les cas.
      for (final bool serie in <bool>[true, false]) {
        for (final bool ici in <bool>[true, false]) {
          for (final bool ailleurs in <bool>[true, false]) {
            expect(
              CircuitFigure.allumee(
                ferme: false,
                serie: serie,
                presenteIci: ici,
                presenteAilleurs: ailleurs,
              ),
              isFalse,
              reason: 'série=$serie ici=$ici ailleurs=$ailleurs',
            );
          }
        }
      }
    });

    test('la dérivation rend les deux lampes indépendantes', () {
      // Le cœur du chapitre : en dérivation, l'état de l'autre lampe
      // n'entre pas dans le résultat ; en série, il décide de tout.
      for (final bool ailleurs in <bool>[true, false]) {
        expect(
          CircuitFigure.allumee(
            ferme: true,
            serie: false,
            presenteIci: true,
            presenteAilleurs: ailleurs,
          ),
          isTrue,
          reason: 'dérivation, autre lampe présente = $ailleurs',
        );
        expect(
          CircuitFigure.allumee(
            ferme: true,
            serie: true,
            presenteIci: true,
            presenteAilleurs: ailleurs,
          ),
          ailleurs,
          reason: 'série, autre lampe présente = $ailleurs',
        );
      }
    });
  });


  group('Chapitre complet : les lois de Kepler', () {
    late Chapter kepler;

    setUpAll(() {
      kepler = catalog.chapterById('astronomie-lycee-lois-de-kepler')!;
    });

    double reponseNum(String lessonId, String questionId) {
      final Question q = kepler.lessonById(lessonId)!.questions.firstWhere(
            (Question x) => x.id == questionId,
          );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    /// Période, en années terrestres, pour un demi-grand axe en unités
    /// astronomiques. C'est la troisième loi, et rien d'autre.
    double periode(double demiGrandAxe) =>
        math.sqrt(math.pow(demiGrandAxe, 3).toDouble());

    test('est jouable de bout en bout', () {
      expect(kepler.isPlayable, isTrue);
      expect(kepler.lessons.length, 4);
    });

    test('la troisième loi tient sur les huit planètes', () {
      // L'énoncé du chapitre, éprouvé sur les tables de la figure plutôt
      // que sur les quatre planètes qu'elle dessine. L'unité est la Terre
      // elle-même : son rapport vaut donc 1 par construction, et c'est
      // l'écart des sept autres qui dit si la loi tient.
      final double anneeTerrestre = periodes[2];
      final double uniteAstronomique = planetes[2].distance;
      for (int i = 0; i < planetes.length; i++) {
        final double t = periodes[i] / anneeTerrestre;
        final double a = planetes[i].distance / uniteAstronomique;
        expect(
          t * t / math.pow(a, 3),
          closeTo(1, 0.02),
          reason: planetes[i].nom,
        );
      }
    });

    test('les périodes annoncées se recalculent par la loi', () {
      expect(periode(1.52), closeTo(reponseNum('la-troisieme-loi', 'q1'), 0.1));
      expect(periode(5.2), closeTo(reponseNum('la-troisieme-loi', 'q2'), 0.6));
      expect(periode(2), closeTo(reponseNum('la-troisieme-loi', 'q3'), 0.1));
      expect(periode(30), closeTo(reponseNum('defi-kepler', 'q6'), 10));
    });

    test('les valeurs calculées retrouvent les périodes mesurées', () {
      // Mars et Jupiter sont annoncées par la loi ; les tables donnent
      // leur période observée. Les deux doivent se rejoindre.
      for (final ({String nom, double reponse, double marge}) cas
          in <({String nom, double reponse, double marge})>[
            (nom: 'Mars', reponse: reponseNum('la-troisieme-loi', 'q1'), marge: 0.1),
            (nom: 'Jupiter', reponse: reponseNum('la-troisieme-loi', 'q2'), marge: 0.6),
          ]) {
        final int rang = planetes.indexWhere((Planete p) => p.nom == cas.nom);
        expect(
          periodes[rang] / periodes[2],
          closeTo(cas.reponse, cas.marge),
          reason: cas.nom,
        );
      }
    });

    test('le problème inverse se résout aussi', () {
      // Huit ans de période, quelle distance ? La loi se lit dans les deux
      // sens, et c'est ce que demande le défi.
      final double a = reponseNum('defi-kepler', 'q2');
      expect(periode(a), closeTo(8, 0.5));
    });

    test('le nombre de tours de Mercure est celui des tables', () {
      expect(
        periodes[2] / periodes[0],
        closeTo(reponseNum('la-troisieme-loi', 'q4'), 0.3),
      );
    });

    test('l’ordre des années suit celui des distances', () {
      final OrderingQuestion q =
          kepler.lessonById('defi-kepler')!.questions.firstWhere(
                (Question x) => x.id == 'q5',
              )
              as OrderingQuestion;
      final List<double> annees = q.items.map((String nom) {
        final int rang = planetes.indexWhere(
          (Planete p) => p.nom == nom.replaceAll('la ', ''),
        );
        expect(rang, isNonNegative, reason: nom);
        return periodes[rang];
      }).toList();
      for (int i = 1; i < annees.length; i++) {
        expect(annees[i], greaterThan(annees[i - 1]));
      }
    });
  });


  group('Chapitre complet : direct, contraposée, absurde', () {
    late Chapter preuves;

    setUpAll(() {
      preuves =
          catalog.chapterById('logique-lycee-types-de-demonstration')!;
    });

    bool reponseVF(String lessonId, String questionId) {
      final TrueFalseQuestion q =
          preuves.lessonById(lessonId)!.questions.firstWhere(
                (Question x) => x.id == questionId,
              )
              as TrueFalseQuestion;
      return q.expected;
    }

    double reponseNum(String lessonId, String questionId) {
      final Question q = preuves.lessonById(lessonId)!.questions.firstWhere(
            (Question x) => x.id == questionId,
          );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    const List<bool> valeurs = <bool>[true, false];

    test('est jouable de bout en bout', () {
      expect(preuves.isPlayable, isTrue);
      expect(preuves.lessons.length, 4);
    });

    test('la contraposée est bien équivalente à l’implication', () {
      // L'affirmation centrale du chapitre, vérifiée sur les quatre cas.
      for (final bool a in valeurs) {
        for (final bool b in valeurs) {
          expect(
            ImplicationFigure.implique(a, b),
            ImplicationFigure.implique(!b, !a),
            reason: 'A=$a, B=$b',
          );
        }
      }
      expect(reponseVF('la-contraposee', 'q2'), isTrue);
      expect(reponseVF('defi-demonstrations', 'q3'), isTrue);
    });

    test('la réciproque, elle, ne l’est pas', () {
      final List<String> contre = <String>[
        for (final bool a in valeurs)
          for (final bool b in valeurs)
            if (ImplicationFigure.implique(a, b) !=
                ImplicationFigure.implique(b, a))
              'A=$a, B=$b',
      ];
      expect(contre, isNotEmpty, reason: 'il faut au moins un cas qui sépare');
      expect(reponseVF('la-contraposee', 'q3'), isFalse);
      expect(reponseVF('defi-demonstrations', 'q4'), isFalse);
    });

    test('le raisonnement par l’absurde repose sur une équivalence', () {
      // « A et non B » est exactement la négation de « si A alors B » :
      // c'est ce qui autorise à partir de ce couple pour chercher une
      // contradiction.
      for (final bool a in valeurs) {
        for (final bool b in valeurs) {
          expect(
            ImplicationFigure.implique(a, b),
            !(a && !b),
            reason: 'A=$a, B=$b',
          );
        }
      }
    });

    test('l’implication n’est fausse que dans un seul cas', () {
      final List<String> faux = <String>[
        for (final bool a in valeurs)
          for (final bool b in valeurs)
            if (!ImplicationFigure.implique(a, b)) 'A=$a, B=$b',
      ];
      expect(faux, <String>['A=true, B=false']);
    });

    test('la contraposée de « n² pair donne n pair » se vérifie', () {
      // Le chapitre démontre l'énoncé par sa contraposée : n impair donne
      // n² impair. Les deux sont rejoués sur une plage d'entiers.
      for (int n = 0; n <= 300; n++) {
        expect(n.isOdd, (n * n).isOdd, reason: 'n = $n');
        if ((n * n).isEven) expect(n.isEven, isTrue, reason: 'n = $n');
      }
    });

    test('aucune fraction simple ne donne racine de 2', () {
      // La preuve par l'absurde conclut qu'il n'existe aucun couple
      // d'entiers avec p² = 2q². On ne démontre rien en énumérant, mais
      // un contre-exemple, lui, invaliderait le chapitre.
      for (int q = 1; q <= 400; q++) {
        for (int p = 1; p <= 600; p++) {
          expect(p * p == 2 * q * q, isFalse, reason: '$p / $q');
        }
      }
    });

    test('le produit des premiers, plus un, échappe à la liste', () {
      // L'argument d'Euclide : le nombre formé n'est divisible par aucun
      // premier de la liste, et a pourtant un diviseur premier.
      const List<int> premiers = <int>[2, 3, 5, 7, 11, 13];
      for (int k = 1; k <= premiers.length; k++) {
        final List<int> liste = premiers.take(k).toList();
        final int n =
            liste.fold(1, (int produit, int p) => produit * p) + 1;
        for (final int p in liste) {
          expect(n % p, 1, reason: 'liste de $k premiers, divisé par $p');
        }
        // Un diviseur premier existe, et il est hors de la liste.
        int diviseur = 2;
        while (n % diviseur != 0) {
          diviseur++;
        }
        expect(liste, isNot(contains(diviseur)), reason: 'n = $n');
      }
      expect(reponseNum('par-l-absurde', 'q3'), 2 * 3 * 5 * 7 + 1);
      expect(reponseNum('defi-demonstrations', 'q5'), 2 * 3 * 5 + 1);
    });
  });


  group('Chapitre complet : Turing et la naissance de l’informatique', () {
    late Chapter turing;

    setUpAll(() {
      turing = catalog.chapterById(
        'histoire-sciences-lycee-turing-et-l-informatique',
      )!;
    });

    double reponseNum(String lessonId, String questionId) {
      final Question q = turing.lessonById(lessonId)!.questions.firstWhere(
            (Question x) => x.id == questionId,
          );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    /// Le nombre de pas que met la machine à s'arrêter sur [ruban].
    int pasJusquALArret(String ruban, {int maxPas = 100}) {
      EtatMachine courant = TuringFigure.depart(ruban);
      int pas = 0;
      while (!courant.termine && pas < maxPas) {
        courant = TuringFigure.pas(courant);
        pas++;
      }
      return pas;
    }

    test('est jouable de bout en bout', () {
      expect(turing.isPlayable, isTrue);
      expect(turing.lessons.length, 4);
    });

    test('la machine calcule bien une addition', () {
      // Le programme n'est pas à croire sur parole : son ruban final est
      // confronté à l'arithmétique, pour toutes les valeurs que huit cases
      // peuvent porter sans déborder.
      for (int valeur = 0; valeur < 255; valeur++) {
        final EtatMachine fin = TuringFigure.executer(
          TuringFigure.ruban(valeur),
        );
        expect(fin.termine, isTrue, reason: 'valeur $valeur');
        expect(
          TuringFigure.valeur(fin.ruban),
          valeur + 1,
          reason: 'ruban ${TuringFigure.ruban(valeur)}',
        );
      }
    });

    test('les nombres de pas annoncés sont ceux de la machine', () {
      expect(
        pasJusquALArret(TuringFigure.rubanInitial),
        reponseNum('la-machine-de-turing', 'q3'),
      );
      expect(pasJusquALArret('00000111'), reponseNum('defi-turing', 'q1'));
      expect(pasJusquALArret('00000110'), reponseNum('defi-turing', 'q2'));
      // Le ruban de départ vaut bien 11, et la machine en fait 12.
      expect(TuringFigure.valeur(TuringFigure.rubanInitial), 11);
      expect(
        TuringFigure.valeur(
          TuringFigure.executer(TuringFigure.rubanInitial).ruban,
        ),
        reponseNum('la-machine-de-turing', 'q2'),
      );
    });

    test('le nombre de pas est celui des 1 de droite, plus un', () {
      // L'explication de la leçon, éprouvée sur toute la plage.
      for (int valeur = 0; valeur < 255; valeur++) {
        final String ruban = TuringFigure.ruban(valeur);
        int uns = 0;
        for (int i = ruban.length - 1; i >= 0 && ruban[i] == '1'; i--) {
          uns++;
        }
        expect(pasJusquALArret(ruban), uns + 1, reason: ruban);
      }
    });

    test('un pas ne change qu’une case et déplace la tête d’un cran', () {
      // La définition même de la machine : pas de mémoire cachée, pas de
      // saut. C'est ce que la figure doit montrer, et donc respecter.
      for (int valeur = 0; valeur < 64; valeur++) {
        EtatMachine courant = TuringFigure.depart(TuringFigure.ruban(valeur));
        while (!courant.termine && courant.tete >= 0) {
          final EtatMachine suivant = TuringFigure.pas(courant);
          expect(suivant.tete, courant.tete - 1);
          int differences = 0;
          for (int i = 0; i < courant.ruban.length; i++) {
            if (courant.ruban[i] != suivant.ruban[i]) differences++;
          }
          expect(differences, lessThanOrEqualTo(1), reason: courant.ruban);
          courant = suivant;
        }
      }
    });

    test('une machine arrêtée le reste', () {
      final EtatMachine fin = TuringFigure.executer('00000110');
      expect(fin.termine, isTrue);
      expect(TuringFigure.pas(fin), fin);
    });
  });


  group('Chapitre complet : tri et recherche', () {
    late Chapter algos;

    setUpAll(() {
      algos = catalog.chapterById(
        'informatique-lycee-algorithmique-tri-et-recherche',
      )!;
    });

    double reponseNum(String lessonId, String questionId) {
      final Question q = algos.lessonById(lessonId)!.questions.firstWhere(
            (Question x) => x.id == questionId,
          );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    /// Comparaisons d'une recherche dichotomique, dans le pire cas.
    ///
    /// Chaque comparaison écarte l'élément du milieu et l'une des deux
    /// moitiés. Le pire cas garde la plus grande des deux : prendre la
    /// plus petite donnerait une comparaison de moins et flatterait
    /// l'algorithme d'un cran.
    int dichotomie(int n) {
      int restant = n;
      int comparaisons = 0;
      while (restant > 0) {
        comparaisons++;
        final int apresLeMilieu = restant - 1;
        restant = apresLeMilieu - apresLeMilieu ~/ 2;
      }
      return comparaisons;
    }

    /// Comparaisons d'un tri par sélection, réellement exécuté.
    int triSelection(List<int> tableau) {
      final List<int> t = List<int>.of(tableau);
      int comparaisons = 0;
      for (int i = 0; i < t.length - 1; i++) {
        int mini = i;
        for (int j = i + 1; j < t.length; j++) {
          comparaisons++;
          if (t[j] < t[mini]) mini = j;
        }
        final int echange = t[i];
        t[i] = t[mini];
        t[mini] = echange;
      }
      expect(t, orderedEquals(List<int>.of(tableau)..sort()));
      return comparaisons;
    }

    /// Comparaisons d'un tri par insertion, réellement exécuté.
    int triInsertion(List<int> tableau) {
      final List<int> t = List<int>.of(tableau);
      int comparaisons = 0;
      for (int i = 1; i < t.length; i++) {
        int j = i - 1;
        final int valeur = t[i];
        while (j >= 0) {
          comparaisons++;
          if (t[j] <= valeur) break;
          t[j + 1] = t[j];
          j--;
        }
        t[j + 1] = valeur;
      }
      expect(t, orderedEquals(List<int>.of(tableau)..sort()));
      return comparaisons;
    }

    test('est jouable de bout en bout', () {
      expect(algos.isPlayable, isTrue);
      expect(algos.lessons.length, 4);
    });

    test('les comparaisons de la dichotomie sont celles annoncées', () {
      expect(dichotomie(1000), reponseNum('chercher-dans-un-tableau', 'q1'));
      expect(
        dichotomie(1000000),
        reponseNum('chercher-dans-un-tableau', 'q2'),
      );
      expect(dichotomie(64), reponseNum('defi-tri-recherche', 'q2'));
      // La formule du cours : partie entière de log₂ n, plus 1.
      for (int n = 1; n <= 5000; n++) {
        expect(
          dichotomie(n),
          (math.log(n) / math.ln2).floor() + 1,
          reason: 'n = $n',
        );
      }
    });

    test('le tri par sélection fait bien n(n−1)/2 comparaisons', () {
      // Le tri est réellement exécuté, et son résultat vérifié trié : le
      // compte ne vaudrait rien s'il venait d'un algorithme faux.
      final math.Random hasard = math.Random(7);
      for (final int n in <int>[2, 5, 10, 20, 50]) {
        final List<int> tableau = <int>[
          for (int i = 0; i < n; i++) hasard.nextInt(1000),
        ];
        expect(triSelection(tableau), n * (n - 1) ~/ 2, reason: 'n = $n');
        // Et le compte ne dépend pas du contenu : déjà trié, ou à l'envers.
        expect(
          triSelection(List<int>.of(tableau)..sort()),
          n * (n - 1) ~/ 2,
        );
        expect(
          triSelection(List<int>.of(tableau)..sort((int a, int b) => b - a)),
          n * (n - 1) ~/ 2,
        );
      }
      expect(triSelection(<int>[9, 3, 7, 1, 8, 2, 6, 4, 10, 5]),
          reponseNum('trier-en-n-carre', 'q1'));
      final List<int> cent = <int>[for (int i = 100; i > 0; i--) i];
      expect(triSelection(cent), reponseNum('defi-tri-recherche', 'q1'));
    });

    test('le tri par insertion dépend du tableau, lui', () {
      const int n = 10;
      final List<int> trie = <int>[for (int i = 0; i < n; i++) i];
      final List<int> envers = <int>[for (int i = n; i > 0; i--) i];
      expect(triInsertion(trie), n - 1);
      expect(triInsertion(trie), reponseNum('trier-en-n-carre', 'q2'));
      expect(triInsertion(envers), n * (n - 1) ~/ 2);
      // C'est ce contraste que le chapitre oppose à la sélection.
      expect(triInsertion(trie), lessThan(triInsertion(envers)));
      expect(triSelection(trie), triSelection(envers));
    });

    test('le quadratique est bien multiplié par cent', () {
      expect(
        Complexite.quadratique.operations(1000) /
            Complexite.quadratique.operations(100),
        closeTo(100, 1e-9),
      );
    });

    test('n log n reste très en dessous de n², et l’écart grandit', () {
      double ecart(double n) =>
          Complexite.quadratique.operations(n) /
          Complexite.quasiLineaire.operations(n);
      expect(ecart(1000), greaterThan(40));
      double precedent = 0;
      for (final double n in <double>[100, 1000, 10000, 100000]) {
        expect(ecart(n), greaterThan(precedent), reason: 'n = $n');
        precedent = ecart(n);
      }
    });

    test('le temps annoncé pour un million d’éléments est juste', () {
      // Un tri quadratique sur un million d'éléments, à un milliard
      // d'opérations par seconde.
      final double secondes = ComplexityFigure.secondes(
        Complexite.quadratique.operations(1e6) / 2,
      );
      expect(
        secondes,
        closeTo(reponseNum('defi-tri-recherche', 'q5'), 100),
      );
      // Le tri fusion, lui, répond en quelques dizaines de millisecondes.
      expect(
        ComplexityFigure.secondes(Complexite.quasiLineaire.operations(1e6)),
        lessThan(0.05),
      );
    });

    test('le nombre de niveaux du tri fusion est celui annoncé', () {
      int niveaux(int n) {
        int morceaux = n;
        int compte = 0;
        while (morceaux > 1) {
          morceaux = (morceaux / 2).ceil();
          compte++;
        }
        return compte;
      }

      expect(niveaux(1024), reponseNum('pourquoi-n-log-n', 'q1'));
      expect(niveaux(1024), 10);
    });
  });


  group('Chapitre complet : les fonctions de référence', () {
    late Chapter fonctions;

    setUpAll(() {
      fonctions = catalog.chapterById('maths-lycee-fonctions-de-reference')!;
    });

    double reponseNum(String lessonId, String questionId) {
      final Question q = fonctions.lessonById(lessonId)!.questions.firstWhere(
            (Question x) => x.id == questionId,
          );
      return q is EstimateQuestion
          ? q.expected
          : (q as NumericQuestion).expected;
    }

    /// Les abscisses que le curseur de la figure peut atteindre.
    List<double> abscisses() => <double>[
      for (
        double x = -ReferenceFunctionsFigure.portee;
        x <= ReferenceFunctionsFigure.portee + 1e-9;
        x += ReferenceFunctionsFigure.pas
      )
        (x * 100).roundToDouble() / 100,
    ];

    test('est jouable de bout en bout', () {
      expect(fonctions.isPlayable, isTrue);
      expect(fonctions.lessons.length, 4);
    });

    test('les images annoncées sont celles de la figure', () {
      expect(FonctionReference.carre.image(3), reponseNum('lire-une-courbe', 'q1'));
      expect(
        FonctionReference.inverse.image(0.5),
        reponseNum('lire-une-courbe', 'q2'),
      );
      expect(
        FonctionReference.cube.image(-2),
        reponseNum('paire-ou-impaire', 'q2'),
      );
      expect(
        FonctionReference.carre.image(0.5),
        closeTo(reponseNum('comparer-les-croissances', 'q1'), 1e-9),
      );
      expect(
        FonctionReference.absolue.image(-3),
        reponseNum('defi-fonctions-reference', 'q1'),
      );
      expect(
        FonctionReference.inverse.image(-4),
        closeTo(reponseNum('defi-fonctions-reference', 'q2'), 1e-9),
      );
    });

    test('les domaines de définition sont ceux qu’annonce le cours', () {
      for (final double x in abscisses()) {
        expect(
          ReferenceFunctionsFigure.definieEn(FonctionReference.racine, x),
          x >= 0,
          reason: 'racine en $x',
        );
        expect(
          ReferenceFunctionsFigure.definieEn(FonctionReference.inverse, x),
          x != 0,
          reason: 'inverse en $x',
        );
        for (final FonctionReference f in <FonctionReference>[
          FonctionReference.carre,
          FonctionReference.cube,
          FonctionReference.absolue,
        ]) {
          expect(
            ReferenceFunctionsFigure.definieEn(f, x),
            isTrue,
            reason: '${f.nom} en $x',
          );
        }
      }
    });

    test('le tri des parités se recalcule sur la figure', () {
      const Map<String, FonctionReference> parNom = <String, FonctionReference>{
        'le carré': FonctionReference.carre,
        'la valeur absolue': FonctionReference.absolue,
        'le cube': FonctionReference.cube,
        'l\'inverse': FonctionReference.inverse,
      };
      final ClassifyQuestion q =
          fonctions.lessonById('paire-ou-impaire')!.questions.firstWhere(
                (Question x) => x.id == 'q1',
              )
              as ClassifyQuestion;
      for (final ClassifyItem item in q.items) {
        final FonctionReference f = parNom[item.text]!;
        bool paire = true;
        bool impaire = true;
        for (final double x in abscisses()) {
          final double? a = f.image(x);
          final double? b = f.image(-x);
          if (a == null || b == null) continue;
          if ((a - b).abs() > 1e-9) paire = false;
          if ((a + b).abs() > 1e-9) impaire = false;
        }
        expect(item.category == 0, paire, reason: '${item.text} : paire');
        expect(item.category == 1, impaire, reason: '${item.text} : impaire');
      }
    });

    test('la racine carrée n’est ni paire ni impaire, faute de domaine', () {
      // L'argument du cours tient au domaine, pas au calcul : il existe
      // des x où la fonction est définie et son opposé non.
      final List<double> asymetriques = <double>[
        for (final double x in abscisses())
          if (ReferenceFunctionsFigure.definieEn(FonctionReference.racine, x) &&
              !ReferenceFunctionsFigure.definieEn(
                FonctionReference.racine,
                -x,
              ))
            x,
      ];
      expect(asymetriques, isNotEmpty);
    });

    test('les croissances s’inversent bien de part et d’autre de 1', () {
      for (final double x in <double>[0.25, 0.5, 0.75]) {
        expect(
          FonctionReference.racine.image(x)!,
          greaterThan(x),
          reason: 'racine en $x',
        );
        expect(FonctionReference.carre.image(x)!, lessThan(x));
        expect(
          FonctionReference.cube.image(x)!,
          lessThan(FonctionReference.carre.image(x)!),
        );
      }
      for (final double x in <double>[1.5, 2, 3, 4]) {
        expect(FonctionReference.racine.image(x)!, lessThan(x));
        expect(FonctionReference.carre.image(x)!, greaterThan(x));
        expect(
          FonctionReference.cube.image(x)!,
          greaterThan(FonctionReference.carre.image(x)!),
        );
      }
      // Le point de bascule annoncé : toutes valent 1 en 1.
      final double bascule = reponseNum('comparer-les-croissances', 'q3');
      for (final FonctionReference f in <FonctionReference>[
        FonctionReference.carre,
        FonctionReference.cube,
        FonctionReference.racine,
        FonctionReference.inverse,
        FonctionReference.absolue,
      ]) {
        expect(f.image(bascule), closeTo(1, 1e-9), reason: f.nom);
      }
    });

    test('le cube croît partout, le carré non', () {
      double? precedentCube;
      double? precedentCarre;
      bool carreToujoursCroissant = true;
      for (final double x in abscisses()) {
        final double cube = FonctionReference.cube.image(x)!;
        final double carre = FonctionReference.carre.image(x)!;
        if (precedentCube != null) expect(cube, greaterThan(precedentCube));
        if (precedentCarre != null && carre < precedentCarre) {
          carreToujoursCroissant = false;
        }
        precedentCube = cube;
        precedentCarre = carre;
      }
      expect(carreToujoursCroissant, isFalse);
    });

    test('l’inverse tend vers zéro sans l’atteindre', () {
      double precedent = double.infinity;
      for (final double x in <double>[1, 2, 5, 10, 100, 1000]) {
        final double y = FonctionReference.inverse.image(x)!;
        expect(y, greaterThan(0));
        expect(y, lessThan(precedent));
        precedent = y;
      }
    });
  });

}
