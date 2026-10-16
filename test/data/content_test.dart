import 'dart:convert';

import 'package:eureka/data/content/content_catalog.dart';
import 'package:eureka/data/content/content_loader.dart';
import 'package:eureka/design_system/figures/figure_registry.dart';
import 'package:eureka/design_system/figures/cross_figure.dart';
import 'package:eureka/design_system/figures/gears_figure.dart';
import 'package:eureka/design_system/figures/loop_robot_figure.dart';
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
}
