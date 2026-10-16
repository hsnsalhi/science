import 'dart:math' as math;

import 'package:eureka/design_system/figures/distributivity_figure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le chapitre de calcul littéral affirme des égalités ; on les recalcule.
///
/// Une relecture du JSON ne prouverait rien : elle confirmerait seulement
/// que j'ai écrit ce que j'ai écrit. Ces tests refont les calculs du
/// chapitre sur des milliers de valeurs, y compris celles qu'on n'aurait pas
/// pensé à essayer — négatives, nulles, grandes. Une règle qui ne tient que
/// sur les exemples du cours est exactement le piège que le chapitre
/// dénonce ; il serait fâcheux d'y tomber en l'écrivant.
void main() {
  final math.Random alea = math.Random(31415);
  int entier({int borne = 40}) => alea.nextInt(2 * borne + 1) - borne;

  group('La distributivité de la figure', () {
    test('les deux lectures de l\'aire concordent sur tout le réglage', () {
      // Les bornes sont celles des trois curseurs.
      for (int k = 1; k <= 6; k++) {
        for (int a = 1; a <= 8; a++) {
          for (int b = 1; b <= 8; b++) {
            expect(
              DistributivityFigure.concordent(k, a, b),
              isTrue,
              reason: 'k=$k a=$a b=$b',
            );
          }
        }
      }
    });

    test('et aussi hors de ces bornes, y compris en négatif', () {
      for (int i = 0; i < 2000; i++) {
        final int k = entier();
        final int a = entier();
        final int b = entier();
        expect(
          DistributivityFigure.aireEntiere(k, a, b),
          DistributivityFigure.aireDecoupee(k, a, b),
          reason: 'k=$k a=$a b=$b',
        );
      }
    });

    test('les deux morceaux valent bien k×a et k×b', () {
      // Le point que la figure annote sous chaque moitié : si ces deux
      // nombres n'étaient pas les aires des deux parts, l'image mentirait
      // tout en restant cohérente avec son total.
      for (int i = 0; i < 500; i++) {
        final int k = 1 + alea.nextInt(6);
        final int a = 1 + alea.nextInt(8);
        final int b = 1 + alea.nextInt(8);
        expect(k * a + k * b, DistributivityFigure.aireEntiere(k, a, b));
      }
    });
  });

  group('Les énoncés du chapitre', () {
    test('−2(x + 5) vaut −2x − 10, et non −2x + 10', () {
      // L'erreur que la carte « avertissement » annonce comme la plus
      // fréquente du chapitre : oublier que le signe moins appartient au
      // facteur. Les deux écritures diffèrent de 20 quel que soit x — ce
      // sont deux droites parallèles —, donc la faute se voit sur
      // n'importe quelle valeur d'essai.
      for (int x = -40; x <= 40; x++) {
        expect(-2 * (x + 5), -2 * x - 10);
        expect((-2 * x + 10) - (-2 * (x + 5)), 20);
      }

      // Les trois distracteurs de q2, et ce qu'ils valent. Deux ne tombent
      // jamais juste ; le troisième coïncide en x = 0, ce qui est
      // précisément pourquoi un seul essai ne départage pas.
      for (int x = -40; x <= 40; x++) {
        expect(-2 * x + 10, isNot(-2 * (x + 5)));
        expect(-2 * x + 5, isNot(-2 * (x + 5)));
        if (x != 0) {
          expect(2 * x - 10, isNot(-2 * (x + 5)));
        }
      }
      expect(2 * 0 - 10, -2 * (0 + 5));
    });

    test('(x + 3)(x + 5) donne x² + 8x + 15', () {
      for (int x = -50; x <= 50; x++) {
        expect((x + 3) * (x + 5), x * x + 8 * x + 15);
      }
    });

    test('2x + 5x² ne se réduit pas en 7x²', () {
      // La question q5 l'affirme fausse. Une seule valeur de x où les deux
      // diffèrent le démontre ; on vérifie qu'il y en a beaucoup.
      int divergences = 0;
      for (int x = -20; x <= 20; x++) {
        if (2 * x + 5 * x * x != 7 * x * x) divergences++;
      }
      expect(divergences, greaterThan(35));
      // Les seules valeurs où l'écriture fautive tombe juste.
      expect(2 * 0 + 5 * 0 * 0, 7 * 0 * 0);
      expect(2 * 1 + 5 * 1 * 1, 7 * 1 * 1);
    });

    test('4x + 8 se factorise en 4(x + 2), et 2(2x + 4) est incomplet', () {
      for (int x = -30; x <= 30; x++) {
        expect(4 * (x + 2), 4 * x + 8);
        // 2(2x + 4) est juste numériquement, mais pas factorisé à fond :
        // son intérieur a encore 2 en facteur commun.
        expect(2 * (2 * x + 4), 4 * x + 8);
      }
      expect(pgcd(4, 8), 4);
      expect(pgcd(2, 4), 2, reason: '2x + 4 se factorise encore');
      expect(pgcd(12, 18), 6, reason: 'la réponse attendue en q4');
    });

    test('la somme de deux impairs est paire, pour tout n et m', () {
      for (int i = 0; i < 1000; i++) {
        final int n = entier(borne: 1000);
        final int m = entier(borne: 1000);
        final int somme = (2 * n + 1) + (2 * m + 1);
        expect(somme.isEven, isTrue);
        expect(somme, 2 * (n + m + 1));
      }
    });

    test('la somme de trois entiers consécutifs est un multiple de 3', () {
      for (int i = 0; i < 1000; i++) {
        final int n = entier(borne: 10000);
        final int somme = n + (n + 1) + (n + 2);
        expect(somme, 3 * n + 3);
        expect(somme % 3, 0);
      }
    });

    test('un nombre à deux chiffres vaut 10d + u', () {
      for (int nombre = 10; nombre <= 99; nombre++) {
        final int d = nombre ~/ 10;
        final int u = nombre % 10;
        expect(10 * d + u, nombre);
        // L'écriture d + u, proposée comme distracteur, ne retombe jamais
        // sur le nombre dès que les dizaines comptent.
        expect(d + u, isNot(nombre));
      }
    });

    test('le tour de magie rend toujours le nombre de départ', () {
      // ((n + 3) × 2 − 6) ÷ 2 = n. La question l'applique à 29 ; on vérifie
      // que le résultat ne dépend pas du nombre choisi, ce qui est tout
      // l'intérêt du tour.
      for (int n = -500; n <= 500; n++) {
        expect(((n + 3) * 2 - 6) ~/ 2, n);
      }
      expect(((29 + 3) * 2 - 6) ~/ 2, 29);
    });

    test('3a + 5 et 5x − 2 aux valeurs des questions', () {
      expect(3 * 4 + 5, 17);
      expect(5 * 3 - 2, 13);
      expect(4 * 12.5, 50);
    });
  });
}

/// Plus grand diviseur commun, par l'algorithme d'Euclide.
int pgcd(int a, int b) {
  int x = a.abs();
  int y = b.abs();
  while (y != 0) {
    final int reste = x % y;
    x = y;
    y = reste;
  }
  return x;
}
