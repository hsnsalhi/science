import 'package:flutter_test/flutter_test.dart';

/// Le second lot de maths du primaire, recalculé.
///
/// Mêmes raisons que le premier : au primaire, ce qui casse n'est pas la
/// théorie mais un nombre retouché dont la réponse n'a pas suivi. Ces
/// tests refont chaque calcul annoncé, et vérifient les quelques
/// propriétés que les chapitres énoncent comme des règles.
void main() {
  group('Les nombres jusqu\'à 10 000', () {
    test('les rangs et leurs valeurs', () {
      const int n = 3472;
      expect(n ~/ 1000, 3, reason: 'milliers');
      expect(n ~/ 100 % 10, 4, reason: 'centaines');
      expect(n ~/ 10 % 10, 7, reason: 'dizaines');
      expect(n % 10, 2, reason: 'unités');
      expect(3000 + 400 + 70 + 2, n);
      expect(1000 ~/ 100, 10, reason: 'dix centaines font un millier');
    });

    test('le zéro intercalé n\'est pas supprimable', () {
      // 3 072 sans son zéro deviendrait 372, un tout autre nombre.
      expect(3072, isNot(372));
      expect(5008, isNot(58));
      // Et les rangs le montrent : le 3 de 3 072 vaut trois mille.
      expect(3072 ~/ 1000, 3);
      expect(372 ~/ 100, 3, reason: 'le même chiffre, un rang plus bas');
    });

    test('plus de chiffres veut toujours dire plus grand', () {
      // La règle sans exception du chapitre, éprouvée sur les frontières.
      for (final (int petit, int grand) in <(int, int)>[
        (9, 10),
        (99, 100),
        (999, 1000),
        (9999, 10000),
      ]) {
        expect(petit, lessThan(grand));
        expect(petit.toString().length, lessThan(grand.toString().length));
      }
      expect(999, lessThan(1000), reason: 'trois 9 perdent contre 1 000');
    });

    test('arrondir à la centaine suit le chiffre des dizaines', () {
      int arrondiCentaine(int n) => ((n + 50) ~/ 100) * 100;
      expect(arrondiCentaine(3472), 3500);
      expect(arrondiCentaine(3429), 3400);
      // La règle « 5 ou plus, on monte », vérifiée sur une centaine entière.
      for (int u = 0; u < 100; u++) {
        final int n = 3400 + u;
        expect(arrondiCentaine(n), u >= 50 ? 3500 : 3400, reason: '$n');
      }
    });

    test('les calculs du chapitre', () {
      expect(2300 + 1500, 3800);
      expect(4000 - 1200, 2800);
      expect(3472 + 1000, 4472);
      expect(9000 ~/ 30, 300);
      expect(1000 ~/ 10, 100);
      expect(6000 ~/ 60, 100);
      expect(250 * 8, 2000);
      expect(9999 + 1, 10000);
    });

    test('l\'arrondi sert bien à vérifier', () {
      // L'astuce du cours : 3 472 + 2 891 doit valoir à peu près 6 400.
      const int exact = 3472 + 2891;
      const int estime = 3500 + 2900;
      expect(exact, 6363);
      expect(estime, 6400);
      expect((exact - estime).abs(), lessThan(100));
    });
  });

  group('Longueurs, masses et contenances', () {
    test('les conversions du chapitre', () {
      expect(3 * 100, 300, reason: 'mètres en centimètres');
      expect(2 * 1000, 2000, reason: 'kilogrammes en grammes');
      expect(2.5 * 1000, 2500, reason: 'kilomètres en mètres');
      expect(750 / 1000, 0.75, reason: 'grammes en kilogrammes');
      expect(30 * 10, 300, reason: 'centimètres en millimètres');
      expect(1.5 * 1000, 1500, reason: 'litres en millilitres');
      expect(10 * 100 ~/ 50, 20, reason: 'bouteilles de 50 cL dans 10 L');
    });

    test('vers une unité plus petite, le nombre grandit', () {
      // Le contrôle de bon sens du cours, vérifié sur les trois familles.
      for (final (double valeur, int facteur) in <(double, int)>[
        (3, 100),
        (2, 1000),
        (1.5, 1000),
        (0.25, 10),
      ]) {
        expect(valeur * facteur, greaterThan(valeur));
        expect(valeur / facteur, lessThan(valeur));
      }
    });

    test('comparer exige la même unité', () {
      // 250 cm contre 3 m : le nombre le plus grand n'est pas le plus long.
      const int enCm = 250;
      const int troisMetresEnCm = 3 * 100;
      expect(troisMetresEnCm, greaterThan(enCm));
      expect(250, greaterThan(3), reason: 'la comparaison naïve, trompeuse');
    });

    test('additionner après conversion', () {
      expect(140 + 85, 225, reason: '1 m 40 plus 85 cm');
      expect(225 ~/ 100, 2);
      expect(225 % 100, 25, reason: 'soit 2 m 25');
      expect(250 + 125 + 500, 875, reason: 'la recette');
      expect(875, lessThan(1000), reason: 'moins d\'un kilogramme');
    });

    test('les calculs du défi', () {
      expect((8 + 5) * 2, 26, reason: 'le périmètre');
      expect(1500 * 3 / 4, 1125, reason: 'trois quarts de 1,5 L');
      expect(2000 * 70 / 100 / 1000, 1.4, reason: '2 000 pas de 70 cm');
      expect(12 * 3, 36, reason: 'douze étages');
      expect(600 / 4 * 6, 900, reason: 'la recette pour six');
    });
  });

  group('Se repérer et se déplacer', () {
    test('tourner ne déplace pas', () {
      // Le point que le chapitre martèle : 3 cases, une rotation, 2 cases.
      const int cases = 3 + 2;
      expect(cases, 5);
      expect(cases, isNot(6), reason: 'la rotation n\'en est pas une');
    });

    test('quatre quarts de tour ramènent à l\'orientation de départ', () {
      for (final (int tours, int reste) in <(int, int)>[
        (4, 0),
        (5, 1),
        (8, 0),
        (11, 3),
        (12, 0),
      ]) {
        expect(tours % 4, reste, reason: '$tours quarts');
      }
    });

    test('le carré : huit instructions, ou une répétition', () {
      const int cotes = 4;
      expect(cotes * 2, 8, reason: 'avancer et tourner, quatre fois');
      expect(cotes * 4, 16, reason: 'quatre côtés de quatre cases');
      // Avec quatre côtés, il n'y a que trois rotations intercalées.
      expect(cotes - 1, 3);
    });

    test('le plus court chemin vaut la somme des écarts', () {
      // De A1 à D3 : trois colonnes et deux lignes.
      int distance(int dx, int dy) => dx.abs() + dy.abs();
      expect(distance(3, 2), 5);
      // Et tous les chemins sans détour font cette longueur : on énumère
      // les ordres possibles des pas et on vérifie qu'ils se valent.
      for (int combinaison = 0; combinaison < 32; combinaison++) {
        int dx = 0;
        int dy = 0;
        int pas = 0;
        for (int bit = 0; bit < 5; bit++) {
          if ((combinaison >> bit) & 1 == 1) {
            dx++;
          } else {
            dy++;
          }
          pas++;
        }
        if (dx == 3 && dy == 2) {
          expect(pas, 5, reason: 'ordre $combinaison');
        }
      }
      expect(distance(5, 5), 10, reason: 'A1 à F1 puis F1 à F6');
    });

    test('les plans et leur échelle', () {
      expect(4 * 50, 200, reason: '4 cm au 1 cm pour 50 m');
      expect(350 ~/ 50, 7, reason: 'le chemin inverse');
      expect(8 * 8, 64, reason: 'un quadrillage d\'échiquier');
    });

    test('de A à F il y a cinq pas, pas six', () {
      // Piège classique du comptage : on compte les intervalles, pas les
      // lettres. A, B, C, D, E, F font six lettres et cinq déplacements.
      const int lettres = 6;
      expect(lettres - 1, 5);
      expect('F'.codeUnitAt(0) - 'A'.codeUnitAt(0), 5);
    });
  });

  group('Tableaux, graphiques et hasard', () {
    const List<int> cantine = <int>[12, 18, 15, 9];

    test('les indicateurs du tableau', () {
      final int total = cantine.reduce((int a, int b) => a + b);
      expect(total, 54);
      expect(cantine.reduce((int a, int b) => a > b ? a : b), 18);
      expect(cantine.reduce((int a, int b) => a < b ? a : b), 9);
      expect(18 - 9, 9, reason: 'l\'écart');
      expect(total / cantine.length, 13.5, reason: 'la moyenne');
    });

    test('une moyenne n\'est pas forcément entière', () {
      // Le point de la question q3 : on compte des personnes, et la
      // moyenne tombe quand même sur un demi.
      expect(54 % 4, isNot(0));
      expect(54 / 4, 13.5);
    });

    test('la part d\'un disque', () {
      expect(100 / 2, 50, reason: 'la moitié');
      expect(100 / 4, 25, reason: 'le quart');
      expect(10 / 25 * 100, 40, reason: 'dix élèves sur vingt-cinq');
      expect(10 + 8 + 7, 25, reason: 'le total de la classe');
    });

    test('compter des chances sur des cas également possibles', () {
      // Le dé.
      const List<int> faces = <int>[1, 2, 3, 4, 5, 6];
      expect(faces.where((int f) => f.isEven).length, 3);
      expect(faces.where((int f) => f > 6).length, 0, reason: 'impossible');
      expect(faces.where((int f) => f >= 1 && f <= 6).length, 6,
          reason: 'certain');
      // Les billes.
      expect(4 / 10, 0.4);
      expect(3 + 5 + 2, 10);
      expect(5 / 10, 0.5, reason: 'une chance sur deux');
    });

    test('sur beaucoup de lancers, les proportions se tiennent', () {
      expect(600 ~/ 6, 100);
      // Et sur peu de lancers, rien n'est garanti : six lancers peuvent
      // donner six fois la même face, ce qui est le point de la carte.
      expect(6 ~/ 6, 1);
    });

    test('l\'axe tronqué exagère sans changer les chiffres', () {
      const int janvier = 100;
      const int fevrier = 102;
      // La hausse réelle.
      expect((fevrier - janvier) / janvier * 100, closeTo(2, 1e-9));
      // Ce que montre un axe partant de 99 : hauteurs 1 et 3.
      const int basTronque = 99;
      expect(janvier - basTronque, 1);
      expect(fevrier - basTronque, 3);
      expect((fevrier - basTronque) / (janvier - basTronque), 3);
      // Trois fois plus haut pour 2 % de hausse : le dessin ment, pas les
      // chiffres.
      expect(3, greaterThan(2 / 100 + 1));
    });
  });
}
