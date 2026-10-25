import 'package:eureka/data/content/content_catalog.dart';
import 'package:eureka/data/content/content_loader.dart';
import 'package:eureka/domain/models/chapter.dart';
import 'package:eureka/domain/models/lesson.dart';
import 'package:eureka/domain/services/lesson_reel.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie le découpage d'une leçon en plans.
///
/// Le format du fil repose entièrement sur deux promesses : aucun plan ne
/// porte un pavé de texte, et aucun plan n'est muet — il y a toujours une
/// figure à l'affiche. Les deux se vérifient sur le corpus entier, et non
/// sur un exemple fabriqué : c'est le seul moyen de savoir qu'un chapitre
/// écrit dans six mois n'a pas cassé la mise en scène.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Le découpage en paragraphes', () {
    test('une ligne vide sépare deux plans', () {
      expect(
        LessonReel.paragraphes('Première idée.\n\nSeconde idée.'),
        <String>['Première idée.', 'Seconde idée.'],
      );
    });

    test('un retour à la ligne simple ne coupe pas', () {
      // Les corps du corpus sont écrits en lignes de quatre-vingts
      // colonnes : un retour simple est une commodité d'écriture, pas une
      // frontière d'idée.
      expect(
        LessonReel.paragraphes('Une phrase\ncoupée en deux lignes.'),
        <String>['Une phrase coupée en deux lignes.'],
      );
    });

    test('un corps nul ne donne aucun plan', () {
      expect(LessonReel.paragraphes(null), isEmpty);
    });

    test('un paragraphe trop long est recoupé par phrases', () {
      final String long =
          '${'Première phrase assez longue pour peser. ' * 4}'
          '${'Seconde phrase également longue à lire. ' * 4}';
      final List<String> plans = LessonReel.paragraphes(long);
      expect(plans.length, greaterThan(1));
      for (final String p in plans) {
        expect(p.length, lessThanOrEqualTo(LessonReel.tailleMax));
      }
    });

    test('un pavé sans ponctuation reste entier', () {
      // Mieux vaut un plan long qu'une coupure au milieu d'une phrase :
      // on ne découpe que là où l'auteur a mis un point.
      final String sansPoint = 'mot ' * 100;
      expect(LessonReel.paragraphes(sansPoint).length, 1);
    });

    test('le recoupage ne perd aucun mot', () {
      const String texte =
          'Les charges créent un champ électrique qui part d’elles ou y '
          'aboutit, du positif vers le négatif, et les lignes ont des '
          'extrémités. Il n’existe aucune charge magnétique, de sorte que '
          'les lignes du champ magnétique se referment toujours sur '
          'elles-mêmes sans début ni fin.';
      final List<String> plans = LessonReel.paragraphes(texte);
      final int motsAvant = texte.split(RegExp(r'\s+')).length;
      final int motsApres = plans
          .expand((String p) => p.split(RegExp(r'\s+')))
          .length;
      expect(motsApres, motsAvant);
    });
  });

  group('La mise en scène d’une leçon', () {
    Lesson lire(Map<String, Object?> json) => Lesson.fromJson(json, 'ch');

    test('le titre d’une carte ouvre ses plans', () {
      final Lesson lesson = lire(<String, Object?>{
        'id': 'l1',
        'title': 'Leçon',
        'kind': 'cours',
        'cards': <Map<String, Object?>>[
          <String, Object?>{
            'kind': 'figure',
            'id': 'c1',
            'title': 'Un titre',
            'body': 'Un propos qui fait plus de vingt caractères.',
            'figureId': 'onde',
          },
        ],
        'questions': <Object?>[],
      });
      final List<ReelBeat> beats = LessonReel.of(lesson);
      expect(beats.first.kind, BeatKind.ouverture);
      expect(beats.first.text, 'Un titre');
      expect(beats[1].kind, BeatKind.propos);
      expect(beats.last.kind, BeatKind.sortie);
    });

    test('une carte sans figure reprend la dernière à l’affiche', () {
      // C'est la règle qui garantit qu'aucun plan n'est un écran de texte
      // sur fond vide.
      final Lesson lesson = lire(<String, Object?>{
        'id': 'l1',
        'title': 'Leçon',
        'kind': 'cours',
        'cards': <Map<String, Object?>>[
          <String, Object?>{
            'kind': 'figure',
            'id': 'c1',
            'body': 'La légende de la figure, assez longue pour passer.',
            'figureId': 'onde',
          },
          <String, Object?>{
            'kind': 'texte',
            'id': 'c2',
            'body': 'Un paragraphe sans figure, assez long pour passer.',
          },
        ],
        'questions': <Object?>[],
      });
      for (final ReelBeat beat in LessonReel.of(lesson)) {
        expect(beat.figureId, 'onde', reason: beat.id);
      }
    });

    test('une formule a son plan à elle', () {
      final Lesson lesson = lire(<String, Object?>{
        'id': 'l1',
        'title': 'Leçon',
        'kind': 'cours',
        'cards': <Map<String, Object?>>[
          <String, Object?>{
            'kind': 'formule',
            'id': 'c1',
            'body': 'Le propos qui précède la formule, bien assez long.',
            'formula': 'a² + b² = c²',
          },
        ],
        'questions': <Object?>[],
      });
      final List<ReelBeat> beats = LessonReel.of(lesson);
      final ReelBeat f = beats.firstWhere(
        (ReelBeat b) => b.kind == BeatKind.formule,
      );
      expect(f.formula, 'a² + b² = c²');
      // Elle ne partage son plan avec aucun texte.
      expect(f.text, isNull);
    });

    test('les identifiants de plan sont uniques', () {
      final Lesson lesson = lire(<String, Object?>{
        'id': 'l1',
        'title': 'Leçon',
        'kind': 'cours',
        'cards': <Map<String, Object?>>[
          for (int i = 1; i <= 3; i++)
            <String, Object?>{
              'kind': 'texte',
              'id': 'c$i',
              'title': 'Titre $i',
              'body': 'Premier propos de la carte $i, assez long.\n\n'
                  'Second propos de la carte $i, assez long aussi.',
            },
        ],
        'questions': <Object?>[],
      });
      final List<ReelBeat> beats = LessonReel.of(lesson);
      final Set<String> ids = beats.map((ReelBeat b) => b.id).toSet();
      expect(ids.length, beats.length);
    });

    test('le dernier plan annonce les exercices quand il y en a', () {
      Lesson avec(bool questions) => lire(<String, Object?>{
        'id': 'l1',
        'title': 'Leçon',
        'kind': 'cours',
        'cards': <Map<String, Object?>>[
          <String, Object?>{
            'kind': 'figure',
            'id': 'c1',
            'body': 'La légende de la figure, assez longue pour passer.',
            'figureId': 'onde',
          },
        ],
        'questions': questions
            ? <Map<String, Object?>>[
                <String, Object?>{
                  'id': 'q1',
                  'kind': 'vraiFaux',
                  'prompt': 'Vrai ou faux ?',
                  'answer': true,
                  'explanation': 'Parce que c’est ainsi, et voici pourquoi.',
                },
              ]
            : <Object?>[],
      });
      expect(LessonReel.of(avec(true)).last.text, contains('À toi'));
      expect(LessonReel.of(avec(false)).last.text, contains('terminée'));
    });
  });

  group('Le corpus entier passe au format fil', () {
    late List<Lesson> lecons;

    setUpAll(() async {
      // On passe par le chargeur de l'application, et non par une
      // lecture de fichiers : le test porte ainsi sur ce que l'élève
      // reçoit vraiment, identifiants engendrés compris.
      final ContentCatalog catalog = await ContentLoader().load();
      lecons = <Lesson>[
        for (final Chapter chapter in catalog.chapters) ...chapter.lessons,
      ];
      expect(lecons.length, greaterThan(800));
    });

    test('aucun plan ne devient un pavé', () {
      // La promesse du format. Le découpeur coupe aux frontières que
      // l'auteur a écrites, donc une phrase unique sans aucune
      // ponctuation interne reste entière : on garantit un plafond dur
      // plutôt que la taille idéale, et on vérifie que les dépassements
      // restent l'exception.
      int trop = 0;
      int total = 0;
      String pire = '';
      for (final Lesson lesson in lecons) {
        for (final ReelBeat beat in LessonReel.of(lesson)) {
          final int n = beat.text?.length ?? 0;
          total++;
          if (n > LessonReel.tailleMax) trop++;
          if (n > pire.length) pire = beat.text!;
        }
      }
      expect(pire.length, lessThanOrEqualTo(320), reason: 'le plus long : $pire');
      // Moins d'un plan sur cent dépasse la taille visée.
      expect(trop * 100, lessThan(total), reason: '$trop plans sur $total');
    });

    test('chaque plan a une figure à l’affiche', () {
      for (final Lesson lesson in lecons) {
        if (lesson.cards.isEmpty) continue;
        for (final ReelBeat beat in LessonReel.of(lesson)) {
          expect(
            beat.figureId,
            isNotNull,
            reason: '${lesson.id} : le plan ${beat.id} n’a rien à montrer',
          );
        }
      }
    });

    test('une leçon tient en un nombre raisonnable de gestes', () {
      // Trop de plans, et le pouce se lasse avant la fin. On vérifie la
      // borne haute sur tout le corpus, pour que le format reste tenable.
      int pire = 0;
      String ou = '';
      for (final Lesson lesson in lecons) {
        final int n = LessonReel.of(lesson).length;
        if (n > pire) {
          pire = n;
          ou = lesson.id;
        }
      }
      expect(pire, lessThanOrEqualTo(40), reason: 'la plus longue : $ou');
    });
  });
}
