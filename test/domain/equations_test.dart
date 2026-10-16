import 'dart:math' as math;

import 'package:eureka/design_system/figures/balance_figure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chaque équation du chapitre est résolue ici, pas relue.
///
/// Un énoncé de problème se corrompt vite : on change un nombre pour que le
/// compte tombe rond et on oublie de refaire la réponse. Ces tests partent
/// de l'énoncé tel que le chapitre le formule, posent l'équation, et
/// comparent à la réponse annoncée. Les gestes de la balance sont vérifiés
/// sur ce qui compte : qu'ils ne déplacent pas la solution.
void main() {
  /// Raccourci de lecture pour l'état de la balance.
  ({int coefficient, int constante, int total}) eq(int a, int b, int c) =>
      (coefficient: a, constante: b, total: c);

  group('Les gestes de la balance', () {
    test('retirer une constante ne déplace pas la solution', () {
      for (int a = 1; a <= 12; a++) {
        for (int b = -20; b <= 20; b++) {
          for (int c = -20; c <= 20; c++) {
            final ({int coefficient, int constante, int total}) avant =
                eq(a, b, c);
            for (final int combien in <int>[b, 1, -3, 7]) {
              final ({int coefficient, int constante, int total}) apres =
                  BalanceFigure.retirer(avant, combien);
              expect(
                BalanceFigure.solution(apres),
                closeTo(BalanceFigure.solution(avant)!, 1e-9),
                reason: '${a}x + $b = $c, retrait de $combien',
              );
            }
          }
        }
      }
    });

    test('diviser les deux membres ne déplace pas la solution', () {
      for (int d = 1; d <= 9; d++) {
        for (int a = 1; a <= 12; a++) {
          for (int b = -18; b <= 18; b++) {
            for (int c = -18; c <= 18; c++) {
              final ({int coefficient, int constante, int total}) avant =
                  eq(a, b, c);
              final ({int coefficient, int constante, int total})? apres =
                  BalanceFigure.diviser(avant, d);
              if (apres == null) continue;
              expect(
                BalanceFigure.solution(apres),
                closeTo(BalanceFigure.solution(avant)!, 1e-9),
              );
            }
          }
        }
      }
    });

    test('la division refuse zéro et les restes non nuls', () {
      // Le point de la carte « multiplier par zéro n'est pas permis »,
      // côté division : l'étape doit être refusée, pas approchée.
      expect(BalanceFigure.diviser(eq(3, 0, 20), 0), isNull);
      expect(BalanceFigure.diviser(eq(3, 0, 20), 3), isNull,
          reason: '20 n\'est pas divisible par 3');
      expect(BalanceFigure.diviser(eq(3, 0, 15), 3), eq(1, 0, 5));
    });

    test('un coefficient nul n\'a pas de solution unique', () {
      expect(BalanceFigure.solution(eq(0, 5, 7)), isNull);
      expect(BalanceFigure.solution(eq(0, 0, 0)), isNull);
    });

    test('la suite de gestes de la figure résout bien 3x + 5 = 20', () {
      // Le parcours exact que les deux boutons proposent, dans l'ordre.
      var etat = eq(3, 5, 20);
      expect(BalanceFigure.resolue(etat), isFalse);
      etat = BalanceFigure.retirer(etat, etat.constante);
      expect(etat, eq(3, 0, 15));
      final ({int coefficient, int constante, int total})? fin =
          BalanceFigure.diviser(etat, etat.coefficient);
      expect(fin, isNotNull);
      expect(fin, eq(1, 0, 5));
      expect(BalanceFigure.resolue(fin!), isTrue);
      expect(BalanceFigure.solution(fin), closeTo(5, 1e-9));
    });
  });

  group('Les équations du cours et de l\'entraînement', () {
    /// Résout ax + b = c en flottant, sans passer par la figure.
    double resoudre(num a, num b, num c) => (c - b) / a;

    test('les équations directes', () {
      expect(resoudre(3, 5, 20), 5); // 3x + 5 = 20
      expect(resoudre(4, -7, 13), 5); // 4x − 7 = 13
      expect(resoudre(1, 1, 9), 8); // 2x + 1 = x + 9, soit x + 1 = 9
      expect(resoudre(-2, 7, 1), 3); // 7 − 2x = 1
    });

    test('5(x − 2) = 3x + 4 donne x = 7, vérification comprise', () {
      const int x = 7;
      expect(5 * (x - 2), 3 * x + 4);
      expect(5 * (x - 2), 25);
      // Et aucune autre valeur entière proche ne marche.
      for (int autre = -20; autre <= 20; autre++) {
        if (autre == x) continue;
        expect(5 * (autre - 2), isNot(3 * autre + 4));
      }
    });

    test('x/3 + 2 = 5 donne x = 9, par les deux chemins du cours', () {
      // Chemin 1 : retirer 2, puis multiplier par 3.
      expect((5 - 2) * 3, 9);
      // Chemin 2 : multiplier tout par 3 d'abord, puis retirer 6.
      expect(15 - 6, 9);
      expect(9 / 3 + 2, 5);
    });

    test('2(x + 3) = 2x + 6 est vraie pour tout x', () {
      // La question q3, devenue un choix : « une infinité ».
      for (int x = -100; x <= 100; x++) {
        expect(2 * (x + 3), 2 * x + 6);
      }
    });
  });

  group('Les problèmes traduits', () {
    test('les âges : x + 5 = 2(x − 4) donne 13 ans', () {
      const int x = 13;
      expect(x + 5, 2 * (x - 4));
      expect(x + 5, 18);
      expect(x - 4, 9);
      expect(18, 2 * 9);
    });

    test('le rectangle : périmètre 34, longueur = largeur + 5', () {
      const int largeur = 6;
      const int longueur = largeur + 5;
      expect(2 * (largeur + longueur), 34);
      expect(longueur, 11);
      // L'avertissement du chapitre : la question demande la longueur,
      // et la solution de l'équation est la largeur. Les deux diffèrent.
      expect(longueur, isNot(largeur));
    });

    test('trois stylos et un cahier : 3x + (x + 3) = 11 donne 2 euros', () {
      const int stylo = 2;
      const int cahier = stylo + 3;
      expect(3 * stylo + cahier, 11);
      expect(cahier, 5);
    });

    test('la bouteille et le bouchon : 0,50 et non 1', () {
      const double bouchon = 0.5;
      const double bouteille = bouchon + 10;
      expect(bouchon + bouteille, closeTo(11, 1e-9));
      expect(bouteille - bouchon, closeTo(10, 1e-9));
      // La réponse intuitive, et pourquoi elle est fausse : la différence
      // ne ferait que 9. C'est l'argument exact du chapitre.
      const double intuitif = 1;
      expect(11 - intuitif - intuitif, closeTo(9, 1e-9));
      expect(11 - intuitif - intuitif, isNot(closeTo(10, 1e-9)));
    });

    test('trois entiers consécutifs de somme 108', () {
      const int n = 35;
      expect(n + (n + 1) + (n + 2), 108);
      expect(3 * n + 3, 108);
      // Et c'est le seul triplet possible.
      int trouves = 0;
      for (int k = -1000; k <= 1000; k++) {
        if (k + (k + 1) + (k + 2) == 108) trouves++;
      }
      expect(trouves, 1);
    });

    test('le père et le fils : dans 18 ans', () {
      const int x = 18;
      expect(38 + x, 2 * (10 + x));
      expect(38 + x, 56);
      expect(10 + x, 28);
      // Vérification qu'aucune autre année ne convient : les deux droites
      // 38 + x et 20 + 2x ne se croisent qu'une fois.
      int trouves = 0;
      for (int k = 0; k <= 200; k++) {
        if (38 + k == 2 * (10 + k)) trouves++;
      }
      expect(trouves, 1);
    });

    test('un nombre augmenté de son tiers vaut 48', () {
      const int x = 36;
      expect(x + x / 3, closeTo(48, 1e-9));
      expect(x / 3, closeTo(12, 1e-9));
    });

    test('23 pièces de 1 et 2 euros pour 37 euros', () {
      const int deuxEuros = 14;
      const int unEuro = 23 - deuxEuros;
      expect(unEuro, 9);
      expect(2 * deuxEuros + unEuro, 37);
      expect(deuxEuros + unEuro, 23);
      // Unicité, par recherche exhaustive sur les 24 répartitions.
      int solutions = 0;
      for (int d = 0; d <= 23; d++) {
        if (2 * d + (23 - d) == 37) solutions++;
      }
      expect(solutions, 1);
    });
  });

  group('ax + b = c selon a', () {
    test('la solution unique suppose a non nul', () {
      // La dernière question du défi. On l'établit plutôt que de la citer.
      final math.Random alea = math.Random(2718);
      for (int i = 0; i < 2000; i++) {
        final int a = alea.nextInt(21) - 10;
        final int b = alea.nextInt(41) - 20;
        final int c = alea.nextInt(41) - 20;
        final double? s = BalanceFigure.solution(eq(a, b, c));
        if (a == 0) {
          expect(s, isNull);
          // Et le nombre de solutions est 0 ou l'infini, jamais 1 : on le
          // constate en essayant des x, puisque x a disparu de l'équation.
          final List<bool> verdicts = <bool>[
            for (int x = -50; x <= 50; x++) a * x + b == c,
          ];
          expect(
            verdicts.every((bool v) => v) || verdicts.every((bool v) => !v),
            isTrue,
            reason: 'avec a = 0, tous les x se valent',
          );
          expect(verdicts.every((bool v) => v), b == c);
        } else {
          expect(s, isNotNull);
          expect(a * s! + b, closeTo(c, 1e-9));
        }
      }
    });
  });
}
