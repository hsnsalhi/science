import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// Les maths du collège de ce lot, recalculées.
///
/// Quatre chapitres bâtis sur des pièges, et un piège se vérifie mieux qu'il
/// ne se relit : la racine qui ne se distribue pas, Euclide déroulé pas à
/// pas, la somme de deux dés dénombrée sur les 36 lancers, et la vitesse
/// moyenne qui n'est pas la moyenne des vitesses. Chaque affirmation est
/// établie sur une plage de cas, pas sur l'exemple du cours.
void main() {
  group('Puissances', () {
    int puissance(int base, int exposant) {
      int r = 1;
      for (int i = 0; i < exposant; i++) {
        r *= base;
      }
      return r;
    }

    test('les valeurs du chapitre', () {
      expect(puissance(2, 5), 32);
      expect(puissance(2, 3) * puissance(2, 2), 32);
      expect(puissance(puissance(2, 3), 2), 64);
      expect(puissance(7, 0), 1);
    });

    test('la règle du produit tient sur toute une plage', () {
      for (int base = 2; base <= 5; base++) {
        for (int m = 0; m <= 6; m++) {
          for (int n = 0; n <= 6; n++) {
            expect(puissance(base, m) * puissance(base, n),
                puissance(base, m + n),
                reason: '$base^$m × $base^$n');
          }
        }
      }
    });

    test('la règle de la puissance de puissance aussi', () {
      for (int base = 2; base <= 4; base++) {
        for (int m = 0; m <= 4; m++) {
          for (int n = 0; n <= 4; n++) {
            expect(puissance(puissance(base, m), n), puissance(base, m * n),
                reason: '($base^$m)^$n');
          }
        }
      }
    });

    test('a⁰ vaut 1 parce que c’est la seule valeur cohérente', () {
      // a^n ÷ a^n vaut 1, et la règle du quotient l'écrit a^0.
      for (int base = 2; base <= 9; base++) {
        for (int n = 1; n <= 5; n++) {
          expect(puissance(base, n) / puissance(base, n), 1,
              reason: 'base $base, exposant $n');
          expect(puissance(base, n - n), 1);
        }
      }
    });

    test('une puissance se distribue sur un produit, jamais sur une somme', () {
      expect((2 + 3) * (2 + 3), 25);
      expect(2 * 2 + 3 * 3, 13);
      expect((2 + 3) * (2 + 3), isNot(2 * 2 + 3 * 3));
      // Sur un produit, l'égalité tient partout.
      for (int a = 1; a <= 10; a++) {
        for (int b = 1; b <= 10; b++) {
          expect(puissance(a * b, 2), puissance(a, 2) * puissance(b, 2),
              reason: 'produit $a × $b');
        }
      }
      // Sur une somme, elle échoue dès qu'aucun des deux n'est nul :
      // l'écart vaut exactement le double produit.
      for (int a = 1; a <= 10; a++) {
        for (int b = 1; b <= 10; b++) {
          final int gauche = puissance(a + b, 2);
          final int droite = puissance(a, 2) + puissance(b, 2);
          expect(gauche - droite, 2 * a * b, reason: 'somme $a + $b');
          expect(gauche, isNot(droite));
        }
      }
    });
  });

  group('Écriture scientifique', () {
    /// (mantisse, exposant) pour un nombre donné.
    (double, int) scientifique(double x) {
      if (x == 0) return (0, 0);
      int e = 0;
      double a = x.abs();
      while (a >= 10) {
        a /= 10;
        e++;
      }
      while (a < 1) {
        a *= 10;
        e--;
      }
      return (a * (x < 0 ? -1 : 1), e);
    }

    test('les conversions du chapitre', () {
      final (double a1, int e1) = scientifique(42000);
      expect(a1, closeTo(4.2, 1e-9));
      expect(e1, 4);
      final (double a2, int e2) = scientifique(0.00057);
      expect(a2, closeTo(5.7, 1e-9));
      expect(e2, -4);
      expect(3 * math.pow(10, 4), 30000);
    });

    test('la mantisse reste toujours entre 1 et 10', () {
      for (final double x in <double>[
        1, 9.99, 10, 42000, 0.00057, 123456789, 0.000000123, 7
      ]) {
        final (double a, int e) = scientifique(x);
        expect(a, greaterThanOrEqualTo(1), reason: '$x');
        expect(a, lessThan(10), reason: '$x');
        expect(a * math.pow(10, e), closeTo(x, x * 1e-12 + 1e-15),
            reason: 'reconstruction de $x');
      }
    });

    test('comparer par les exposants donne le bon ordre', () {
      // 4,2 × 10⁻⁵ contre 9,1 × 10⁻⁶ : l'exposant tranche avant la mantisse.
      final double gauche = 4.2 * math.pow(10, -5);
      final double droite = 9.1 * math.pow(10, -6);
      expect(gauche, greaterThan(droite));
      expect(-5, greaterThan(-6));
      // La mantisse plus grande ne suffit donc pas : contre-exemple établi.
      expect(9.1, greaterThan(4.2));
      expect(droite, lessThan(gauche));
    });

    test('multiplier additionne les exposants, et la rectification en ajoute un', () {
      expect(3 * 2, 6);
      expect(8 + 5, 13);
      // 5 × 4 = 20, qui dépasse 10 : la mantisse se ramène et l'exposant monte.
      final (double a, int e) = scientifique(20 * math.pow(10, 13).toDouble());
      expect(a, closeTo(2, 1e-9));
      expect(e, 14);
    });

    test('42 × 10³ n’est pas en écriture scientifique, 4,2 × 10⁴ l’est', () {
      expect(42, greaterThanOrEqualTo(10));
      final (double a, int e) = scientifique(42 * 1000);
      expect(a, closeTo(4.2, 1e-9));
      expect(e, 4);
      expect(42 * 1000, (4.2 * math.pow(10, 4)).round());
    });
  });

  group('Racine carrée', () {
    test('les carrés parfaits', () {
      expect(math.sqrt(144), 12);
      expect(math.sqrt(25), 5);
    });

    test('la racine ne se distribue pas sur une somme', () {
      expect(math.sqrt(9 + 16), 5);
      expect(math.sqrt(9) + math.sqrt(16), 7);
      expect(math.sqrt(9 + 16), lessThan(math.sqrt(9) + math.sqrt(16)));
      // Et c'est systématique : la racine d'une somme est toujours
      // strictement inférieure à la somme des racines, sauf si l'un est nul.
      for (int a = 1; a <= 20; a++) {
        for (int b = 1; b <= 20; b++) {
          expect(math.sqrt(a + b), lessThan(math.sqrt(a) + math.sqrt(b)),
              reason: '√($a + $b)');
        }
      }
      expect(math.sqrt(9 + 0), closeTo(math.sqrt(9) + math.sqrt(0), 1e-12),
          reason: 'le cas d’égalité : un terme nul');
    });

    test('mais elle se distribue sur un produit', () {
      expect(math.sqrt(4) * math.sqrt(25), 10);
      expect(math.sqrt(100), 10);
      for (int a = 1; a <= 20; a++) {
        for (int b = 1; b <= 20; b++) {
          expect(math.sqrt(a * b), closeTo(math.sqrt(a) * math.sqrt(b), 1e-12),
              reason: '√($a × $b)');
        }
      }
    });

    test('x² = 9 a deux solutions, √9 en désigne une', () {
      expect(3 * 3, 9);
      expect(-3 * -3, 9);
      expect(math.sqrt(9), 3, reason: 'la racine est la solution positive');
      expect(math.sqrt(9), isNot(-3));
    });

    test('√72 vaut 6√2', () {
      // On cherche le plus grand carré parfait qui divise 72.
      int plusGrandCarre(int n) {
        int meilleur = 1;
        for (int k = 1; k * k <= n; k++) {
          if (n % (k * k) == 0) meilleur = k * k;
        }
        return meilleur;
      }

      expect(plusGrandCarre(72), 36);
      expect(math.sqrt(plusGrandCarre(72)), 6);
      expect(72 ~/ plusGrandCarre(72), 2);
      expect(6 * math.sqrt(2), closeTo(math.sqrt(72), 1e-12));
    });

    test('1,414 n’est pas la valeur exacte de √2', () {
      expect(1.414 * 1.414, closeTo(1.999396, 1e-9));
      expect(1.414 * 1.414, lessThan(2));
      expect(math.sqrt(2), greaterThan(1.414));
      // Et aucune fraction de dénominateur raisonnable ne la donne non plus.
      for (int d = 1; d <= 1000; d++) {
        final int n = (math.sqrt(2) * d).round();
        expect(n * n, isNot(2 * d * d), reason: 'fraction $n/$d');
      }
    });
  });

  group('Ordres de grandeur', () {
    test('les exposants du défi', () {
      expect(21 - (-15), 36);
      expect(0 - (-15), 15);
      expect(21 - 0, 21);
      expect(15 + 21, 36, reason: 'les rapports se composent');
    });

    test('une vie compte quelques milliards de secondes', () {
      const int secondes = 80 * 365 * 24 * 3600;
      expect(secondes, 2522880000);
      expect((math.log(secondes) / math.ln10).floor(), 9);
    });
  });

  group('Divisibilité', () {
    int sommeDesChiffres(int n) {
      int s = 0;
      int reste = n.abs();
      while (reste > 0) {
        s += reste % 10;
        reste ~/= 10;
      }
      return s;
    }

    test('le critère de 3 est exact sur dix mille nombres', () {
      for (int n = 1; n <= 10000; n++) {
        expect(sommeDesChiffres(n) % 3 == 0, n % 3 == 0, reason: '$n');
      }
    });

    test('le critère de 9 aussi', () {
      for (int n = 1; n <= 10000; n++) {
        expect(sommeDesChiffres(n) % 9 == 0, n % 9 == 0, reason: '$n');
      }
    });

    test('le critère de 4 ne regarde que les deux derniers chiffres', () {
      for (int n = 1; n <= 10000; n++) {
        expect(n % 100 % 4 == 0, n % 4 == 0, reason: '$n');
      }
      expect(716 % 4, 0);
      expect(16 % 4, 0);
    });

    test('le critère de 3 ne marche pas pour 7', () {
      // La raison avancée par le chapitre : on cherche un contre-exemple.
      int contreExemples = 0;
      for (int n = 1; n <= 1000; n++) {
        if ((sommeDesChiffres(n) % 7 == 0) != (n % 7 == 0)) contreExemples++;
      }
      expect(contreExemples, greaterThan(0));
      // 70 par exemple : somme des chiffres 7, divisible par 7, et 70 l'est
      // aussi — le critère semble marcher. Mais 16 a pour somme 7 sans être
      // divisible par 7.
      expect(sommeDesChiffres(16), 7);
      expect(16 % 7, isNot(0));
    });

    test('divisible par 6 revient à divisible par 2 et par 3', () {
      for (int n = 1; n <= 5000; n++) {
        expect(n % 6 == 0, n % 2 == 0 && n % 3 == 0, reason: '$n');
      }
    });

    test('mais divisible par 2 et par 6 ne donne pas divisible par 12', () {
      // Le contre-exemple du chapitre, et tous les autres.
      expect(18 % 2, 0);
      expect(18 % 6, 0);
      expect(18 % 12, isNot(0));
      int contreExemples = 0;
      for (int n = 1; n <= 1000; n++) {
        if (n % 2 == 0 && n % 6 == 0 && n % 12 != 0) contreExemples++;
      }
      expect(contreExemples, greaterThan(0));
      // Alors que par 4 et par 3, l'équivalence tient.
      for (int n = 1; n <= 5000; n++) {
        expect(n % 12 == 0, n % 4 == 0 && n % 3 == 0, reason: '$n');
      }
    });
  });

  group('Euclide', () {
    int pgcd(int a, int b) {
      int x = a;
      int y = b;
      while (y != 0) {
        final int r = x % y;
        x = y;
        y = r;
      }
      return x;
    }

    int ppcm(int a, int b) => a ~/ pgcd(a, b) * b;

    test('les PGCD du chapitre', () {
      expect(pgcd(60, 36), 12);
      expect(pgcd(48, 18), 6);
      expect(pgcd(12, 18), 6);
      expect(pgcd(7, 12), 1);
      expect(pgcd(24, 18), 6);
      expect(pgcd(180, 144), 36);
    });

    test('le déroulé des restes pour 60 et 36', () {
      final List<int> restes = <int>[];
      int x = 60;
      int y = 36;
      while (y != 0) {
        restes.add(x % y);
        final int r = x % y;
        x = y;
        y = r;
      }
      expect(restes, <int>[24, 12, 0]);
      expect(restes[restes.length - 2], 12, reason: 'le dernier reste non nul');
    });

    test('simplifier par le PGCD donne une fraction irréductible', () {
      for (int n = 1; n <= 60; n++) {
        for (int d = 1; d <= 60; d++) {
          final int g = pgcd(n, d);
          expect(pgcd(n ~/ g, d ~/ g), 1, reason: '$n/$d');
        }
      }
      expect(36 ~/ pgcd(36, 60), 3);
      expect(60 ~/ pgcd(36, 60), 5);
    });

    test('la relation PGCD × PPCM = produit', () {
      for (int a = 1; a <= 50; a++) {
        for (int b = 1; b <= 50; b++) {
          expect(pgcd(a, b) * ppcm(a, b), a * b, reason: '$a et $b');
        }
      }
      expect(12 * 18, 216);
      expect(pgcd(12, 18) * ppcm(12, 18), 216);
    });

    test('les PPCM du chapitre', () {
      expect(ppcm(12, 18), 36);
      expect(ppcm(4, 6), 12);
      expect(ppcm(7, 12), 84);
      expect(ppcm(24, 18), 72);
    });

    test('deux nombres premiers entre eux ont pour PPCM leur produit', () {
      for (int a = 1; a <= 40; a++) {
        for (int b = 1; b <= 40; b++) {
          if (pgcd(a, b) == 1) {
            expect(ppcm(a, b), a * b, reason: '$a et $b');
          }
        }
      }
    });

    test('les engrenages et le carrelage', () {
      expect(ppcm(24, 18), 72);
      expect(72 ~/ 24, 3);
      expect(72 ~/ 18, 4);
      expect(pgcd(180, 144), 36);
      expect(180 ~/ 36, 5);
      expect(144 ~/ 36, 4);
      expect((180 ~/ 36) * (144 ~/ 36), 20);
    });

    test('1/12 + 1/18 au dénominateur PPCM', () {
      final int d = ppcm(12, 18);
      expect(d, 36);
      expect(d ~/ 12, 3);
      expect(d ~/ 18, 2);
      expect(3 + 2, 5);
      expect(pgcd(5, 36), 1, reason: 'déjà irréductible');
    });
  });

  group('Statistiques', () {
    const List<int> salaires = [1500, 1600, 1700, 1800, 10000];

    double moyenne(List<int> s) =>
        s.reduce((int a, int b) => a + b) / s.length;

    double mediane(List<int> s) {
      final List<int> t = List<int>.from(s)..sort();
      final int n = t.length;
      return n.isOdd ? t[n ~/ 2].toDouble() : (t[n ~/ 2 - 1] + t[n ~/ 2]) / 2;
    }

    test('moyenne, médiane et étendue des cinq salaires', () {
      expect(moyenne(salaires), 3320);
      expect(mediane(salaires), 1700);
      expect(salaires.reduce(math.max) - salaires.reduce(math.min), 8500);
    });

    test('quatre personnes sur cinq gagnent moins que la moyenne', () {
      final double m = moyenne(salaires);
      expect(salaires.where((int s) => s < m).length, 4);
    });

    test('la médiane ne bouge pas quand l’extrême explose', () {
      const List<int> pousse = [1500, 1600, 1700, 1800, 100000];
      expect(mediane(pousse), mediane(salaires));
      expect(moyenne(pousse), 21320);
      expect(moyenne(pousse), greaterThan(moyenne(salaires) * 6));
      // Quel que soit l'extrême, la médiane reste à 1 700.
      for (final int extreme in <int>[2000, 10000, 100000, 1000000]) {
        expect(mediane(<int>[1500, 1600, 1700, 1800, extreme]), 1700,
            reason: 'extrême $extreme');
      }
    });

    test('la médiane d’un effectif pair peut ne pas figurer dans la série', () {
      expect(mediane(<int>[1, 2, 8, 9]), 5);
      expect(<int>[1, 2, 8, 9].contains(5), isFalse);
    });

    test('les fréquences du chapitre', () {
      expect(12 / 30 * 100, 40);
      expect(18 / 45 * 100, 40);
      expect(100 - 25 - 30 - 40, 5);
      expect(240 * 0.15, 36);
    });
  });

  group('Deux dés', () {
    /// Le nombre de lancers donnant chaque somme, dénombré et non récité.
    Map<int, int> distribution() {
      final Map<int, int> compte = <int, int>{};
      for (int a = 1; a <= 6; a++) {
        for (int b = 1; b <= 6; b++) {
          compte[a + b] = (compte[a + b] ?? 0) + 1;
        }
      }
      return compte;
    }

    test('trente-six lancers au total', () {
      final Map<int, int> d = distribution();
      expect(d.values.reduce((int a, int b) => a + b), 36);
      expect(6 * 6, 36);
    });

    test('la distribution complète', () {
      expect(distribution(), <int, int>{
        2: 1, 3: 2, 4: 3, 5: 4, 6: 5, 7: 6,
        8: 5, 9: 4, 10: 3, 11: 2, 12: 1,
      });
    });

    test('le 7 est la somme la plus probable', () {
      final Map<int, int> d = distribution();
      final int maximum = d.values.reduce(math.max);
      expect(d[7], maximum);
      expect(d[7], 6);
      // Et il est le seul à l'atteindre.
      expect(d.entries.where((MapEntry<int, int> e) => e.value == maximum).length, 1);
    });

    test('le 7 est six fois plus probable que le 2', () {
      final Map<int, int> d = distribution();
      expect(d[7]! / d[2]!, 6);
    });

    test('la distribution est symétrique autour de 7', () {
      final Map<int, int> d = distribution();
      for (int s = 2; s <= 12; s++) {
        expect(d[s], d[14 - s], reason: 'somme $s contre ${14 - s}');
      }
    });

    test('les sommes ne sont pas équiprobables, contrairement aux lancers', () {
      final Map<int, int> d = distribution();
      expect(d.values.toSet().length, greaterThan(1),
          reason: 'les onze sommes n’ont pas la même chance');
      // Un onzième ferait 9 %, la vraie probabilité du 7 en fait 17.
      expect(d[7]! / 36 * 100, closeTo(16.7, 0.1));
      expect(100 / 11, closeTo(9.1, 0.1));
    });

    test('pour chaque premier dé, un seul second complète à sept', () {
      // C'est l'argument de la carte « pourquoi le 7 précisément ».
      for (int premier = 1; premier <= 6; premier++) {
        final int second = 7 - premier;
        expect(second, inInclusiveRange(1, 6), reason: 'premier dé $premier');
      }
      // Pour 12, un seul premier dé convient.
      int possibles = 0;
      for (int premier = 1; premier <= 6; premier++) {
        if (12 - premier >= 1 && 12 - premier <= 6) possibles++;
      }
      expect(possibles, 1);
    });
  });

  group('Pourcentages', () {
    test('plus vingt puis moins vingt perd quatre pour cent', () {
      expect(100 * 1.20, 120);
      expect(120 * 0.80, closeTo(96, 1e-9));
      expect(100 * 0.80 * 1.20, closeTo(96, 1e-9),
          reason: 'l’ordre n’y change rien');
    });

    test('la perte est le produit des deux variations, pour tout taux', () {
      for (double t = 0.05; t <= 0.9; t += 0.05) {
        final double apres = 100 * (1 + t) * (1 - t);
        // (1+t)(1−t) = 1 − t², donc la perte vaut toujours t² en relatif.
        expect(apres, closeTo(100 * (1 - t * t), 1e-9), reason: 'taux $t');
        expect(apres, lessThan(100));
      }
    });

    test('annuler une hausse demande une baisse plus faible', () {
      // Pour annuler +20 %, il faut −16,67 %, pas −20 %.
      const double baisse = 1 - 1 / 1.20;
      expect(baisse, closeTo(0.1667, 1e-4));
      expect(baisse, lessThan(0.20));
      expect(100 * 1.20 * (1 - baisse), closeTo(100, 1e-9));
      // Annuler +100 % demande −50 %.
      expect(1 - 1 / 2.0, 0.5);
      expect(100 * 2.0 * 0.5, 100);
    });

    test('point de pourcentage et pourcentage', () {
      expect(6 - 4, 2, reason: 'points de pourcentage');
      expect(6 / 4, 1.5, reason: 'soit +50 %');
      expect((6 / 4 - 1) * 100, closeTo(50, 1e-9));
    });

    test('trois hausses de dix pour cent ne font pas trente', () {
      expect(100 * 1.10 * 1.10 * 1.10, closeTo(133.1, 1e-9));
      expect(100 * 1.10 * 1.10 * 1.10, greaterThan(130));
      // L'écart croît avec le nombre de hausses.
      double compose(int n) => 100 * math.pow(1.10, n).toDouble();
      for (int n = 1; n <= 10; n++) {
        expect(compose(n), greaterThanOrEqualTo(100 + 10.0 * n),
            reason: '$n hausses');
      }
    });
  });

  group('Proportionnalité et vitesse moyenne', () {
    test('le coefficient et la linéarité', () {
      expect(6 / 3, 2);
      expect(8 * 2, 16);
      // La linéarité : le prix de 5 + 3 kg est la somme des deux prix.
      expect(5 * 2 + 3 * 2, 8 * 2);
    });

    test('l’abonnement n’est pas proportionnel', () {
      double prix(int mois) => 20 + 5.0 * mois;
      expect(prix(3), 35);
      expect(prix(6), 50);
      expect(prix(6), isNot(2 * prix(3)),
          reason: 'doubler la durée ne double pas le prix');
      // Et le quotient prix/mois n'est pas constant.
      final Set<double> quotients = <double>{};
      for (int m = 1; m <= 10; m++) {
        quotients.add(prix(m) / m);
      }
      expect(quotients.length, greaterThan(1));
    });

    test('la vitesse moyenne n’est pas la moyenne des vitesses', () {
      double vitesseMoyenne(double d1, double v1, double d2, double v2) =>
          (d1 + d2) / (d1 / v1 + d2 / v2);

      expect(vitesseMoyenne(60, 30, 60, 60), 40);
      expect((30 + 60) / 2, 45);
      expect(vitesseMoyenne(60, 30, 60, 60), lessThan((30 + 60) / 2));
      expect(45 - 40, 5);
    });

    test('à durées égales, la moyenne simple est juste', () {
      // Une heure à 30 puis une heure à 60 : 90 km en 2 h.
      expect((30 + 60) / 2, 45);
      expect((30 * 1 + 60 * 1) / 2, 45);
    });

    test('à distances égales, la moyenne est toujours inférieure', () {
      double aDistancesEgales(double v1, double v2) => 2 / (1 / v1 + 1 / v2);
      for (double v1 = 10; v1 <= 120; v1 += 10) {
        for (double v2 = 10; v2 <= 120; v2 += 10) {
          final double harmonique = aDistancesEgales(v1, v2);
          final double arithmetique = (v1 + v2) / 2;
          if (v1 == v2) {
            expect(harmonique, closeTo(arithmetique, 1e-9),
                reason: 'égalité quand les vitesses sont identiques');
          } else {
            expect(harmonique, lessThan(arithmetique),
                reason: '$v1 et $v2');
          }
        }
      }
      expect(aDistancesEgales(20, 60), 30);
      expect(aDistancesEgales(30, 60), 40);
    });

    test('les fonctions du chapitre', () {
      double f(double x) => 20 + 5 * x;
      expect(f(6), 50);
      // L'antécédent de 65.
      expect((65 - 20) / 5, 9);
      expect(f(9), 65);
      // Neuf a deux antécédents par le carré, moins un n'en a aucun.
      expect(<int>[3, -3].where((int x) => x * x == 9).length, 2);
      expect(List<int>.generate(201, (int i) => i - 100)
          .where((int x) => x * x == -1).length, 0);
    });

    test('l’échelle d’une carte', () {
      expect(4 * 25000 / 100, 1000, reason: 'quatre centimètres font un kilomètre');
      expect(80 * 3, 240);
      expect(300 / 4, 75);
    });
  });
}
