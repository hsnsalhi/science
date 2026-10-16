import 'dart:math' as math;

import 'package:eureka/design_system/figures/half_life_figure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le chapitre affirme des valeurs ; on les recalcule. Et la simulation de
/// la figure est confrontée à la loi qu'elle est censée illustrer.
///
/// Une figure qui tire des instants de désintégration peut très bien suivre
/// une mauvaise loi sans que cela se voie : des points qui s'éteignent ont
/// toujours l'air crédibles. Ces tests vérifient que le tirage obéit
/// réellement à la décroissance exponentielle, demi-vie après demi-vie, et
/// que les nombres du cours tombent juste.
void main() {
  group('Les valeurs du cours', () {
    test('les ordres de grandeur de l\'exponentielle', () {
      expect(math.exp(10), closeTo(22026, 1));
      expect(math.exp(20) / 1e6, closeTo(485, 1));
      expect(math.exp(50), greaterThan(5e21));
    });

    test('l\'exponentielle ne s\'annule jamais', () {
      // L'affirmation de la carte d'avertissement, et la réponse « zéro
      // solution » de la question q3.
      for (double x = -700; x <= 0; x += 7) {
        expect(math.exp(x), greaterThan(0), reason: 'x = $x');
      }
      // Même très loin, elle reste strictement positive.
      expect(math.exp(-500), greaterThan(0));
    });

    test('elle l\'emporte sur toute puissance', () {
      // exp(x)/x^n tend vers l'infini : on le constate pour n = 100 en
      // passant au logarithme, qui évite le dépassement de capacité.
      for (final double x in <double>[1000, 5000, 20000]) {
        final double logRapport = x - 100 * math.log(x);
        expect(logRapport, greaterThan(0), reason: 'x = $x');
      }
    });

    test('2ˣ = 1000 donne environ 9,97', () {
      final double x = math.log(1000) / math.ln2;
      expect(x, closeTo(9.97, 0.01));
      // Cohérent avec 2¹⁰ = 1024, juste au-dessus de mille.
      expect(math.pow(2, 10), 1024);
      expect(x, lessThan(10));
    });

    test('les deux fonctions se défont l\'une l\'autre', () {
      for (double x = -20; x <= 20; x += 0.7) {
        expect(math.log(math.exp(x)), closeTo(x, 1e-9));
      }
      for (double y = 0.01; y <= 1000; y *= 1.9) {
        expect(math.exp(math.log(y)), closeTo(y, y * 1e-12));
      }
    });

    test('ln transforme les produits en sommes, pas les sommes', () {
      final math.Random alea = math.Random(7);
      for (int i = 0; i < 500; i++) {
        final double a = alea.nextDouble() * 100 + 0.01;
        final double b = alea.nextDouble() * 100 + 0.01;
        expect(math.log(a * b), closeTo(math.log(a) + math.log(b), 1e-9));
        // L'erreur de la question q5 : ln(a + b) n'est pas ln(a) + ln(b).
        if ((a - 1).abs() > 0.05 && (b - 1).abs() > 0.05) {
          expect(
            math.log(a + b),
            isNot(closeTo(math.log(a) + math.log(b), 1e-6)),
          );
        }
      }
    });
  });

  group('La demi-vie, en nombres', () {
    test('un quart restant fait deux demi-vies', () {
      expect(math.pow(0.5, 2), 0.25);
      expect(2 * 5730, 11460, reason: 'l\'âge de l\'os, en années');
    });

    test('sept demi-vies pour descendre sous 1 %', () {
      expect(math.pow(0.5, 6), greaterThan(0.01));
      expect(math.pow(0.5, 7), lessThan(0.01));
      // Le calcul exact, que l'explication donne.
      expect(math.log(100) / math.ln2, closeTo(6.64, 0.01));
    });

    test('après dix demi-vies il reste moins d\'un millième', () {
      expect(math.pow(0.5, 10), lessThan(0.001));
      expect(math.pow(0.5, 10), greaterThan(0));
      // « Environ 57 000 ans » pour le carbone 14.
      expect(10 * 5730, 57300);
    });

    test('diviser par deux n\'atteint jamais zéro', () {
      double reste = 1;
      for (int i = 0; i < 400; i++) {
        reste /= 2;
        if (reste == 0) break;
      }
      // Le zéro finit par arriver en flottant, mais pas avant la
      // 1 070ᵉ division : mathématiquement, jamais.
      expect(math.pow(0.5, 300), greaterThan(0));
    });
  });

  group('La simulation de la figure suit bien la loi', () {
    final List<double> instants = HalfLifeFigure.instants();

    test('le tirage a le bon effectif et des instants positifs', () {
      expect(instants.length, HalfLifeFigure.effectif);
      for (final double t in instants) {
        expect(t, greaterThan(0));
        expect(t.isFinite, isTrue);
      }
    });

    test('il est déterministe : même graine, même échantillon', () {
      // Sans quoi les captures de référence changeraient à chaque
      // exécution, et le test lui-même ne voudrait rien dire.
      expect(HalfLifeFigure.instants(), instants);
      expect(HalfLifeFigure.instants(graine: 99), isNot(instants));
    });

    test('la moitié survit à une demi-vie, à la marge statistique près',
        () {
      // Le fait central. Avec 144 noyaux, l'écart-type du nombre de
      // survivants vaut racine de n p (1 − p) ≈ 6 : on accepte trois
      // écarts-types, soit 18.
      final int survivants = HalfLifeFigure.restants(instants, 1);
      expect(survivants, closeTo(72, 18));
    });

    test('et le quart à deux demi-vies, le huitième à trois', () {
      for (final (int demiVies, double attendu) in <(int, double)>[
        (0, 144),
        (1, 72),
        (2, 36),
        (3, 18),
        (4, 9),
      ]) {
        final int survivants =
            HalfLifeFigure.restants(instants, demiVies.toDouble());
        final double ecartType =
            math.sqrt(144 * (attendu / 144) * (1 - attendu / 144));
        expect(
          survivants,
          closeTo(attendu, math.max(4, 3 * ecartType)),
          reason: '$demiVies demi-vies : $survivants survivants '
              'pour $attendu attendus',
        );
      }
    });

    test('le nombre de survivants ne remonte jamais', () {
      // Une désintégration est irréversible. Si le tirage ou le comptage
      // était fautif, cette propriété tomberait quelque part.
      int precedent = HalfLifeFigure.effectif;
      for (double t = 0; t <= HalfLifeFigure.dureeMax; t += 0.02) {
        final int n = HalfLifeFigure.restants(instants, t);
        expect(n, lessThanOrEqualTo(precedent), reason: 't = $t');
        precedent = n;
      }
    });

    test('sur un grand échantillon, la loi est serrée', () {
      // Avec 144 noyaux le hasard est visible, ce qui est voulu dans la
      // figure. Sur 200 000, l'écart relatif à la loi doit devenir
      // minuscule — c'est le passage du hasard individuel à la
      // régularité collective, et c'est vérifiable.
      final math.Random alea = math.Random(31);
      const int effectif = 200000;
      final List<double> grand = <double>[
        for (int i = 0; i < effectif; i++)
          -math.log(1 - alea.nextDouble()) / math.ln2,
      ];
      for (final double t in <double>[0.5, 1, 2, 3]) {
        final int survivants = HalfLifeFigure.restants(grand, t);
        final double attendu =
            effectif * HalfLifeFigure.proportionTheorique(t);
        expect(
          (survivants - attendu).abs() / attendu,
          lessThan(0.03),
          reason: 't = $t : $survivants pour $attendu',
        );
      }
    });

    test('la proportion théorique est bien une division par deux', () {
      for (int n = 0; n <= 10; n++) {
        expect(
          HalfLifeFigure.proportionTheorique(n.toDouble()),
          closeTo(1 / math.pow(2, n), 1e-12),
        );
      }
    });
  });

  group('Les pièges du défi', () {
    test('le nénuphar couvre la moitié la veille', () {
      // Trente jours pour tout couvrir en doublant : la moitié au 29ᵉ,
      // le quart au 28ᵉ. On le vérifie en remontant la suite.
      double surface = 1;
      final List<double> parJour = <double>[surface];
      for (int jour = 1; jour <= 30; jour++) {
        surface *= 2;
        parJour.add(surface);
      }
      expect(parJour[29] / parJour[30], closeTo(0.5, 1e-12));
      expect(parJour[28] / parJour[30], closeTo(0.25, 1e-12));
      // Et au quinzième jour, la réponse intuitive, il n'y a presque rien.
      expect(parJour[15] / parJour[30], lessThan(0.0001));
    });

    test('quarante-deux plis dépassent la distance Terre-Lune', () {
      final double mm = 0.1 * math.pow(2, 42);
      final double km = mm / 1e6;
      expect(km, closeTo(439805, 100));
      expect(km / 1000, closeTo(440, 1), reason: 'en milliers de km');
      expect(km, greaterThan(384400), reason: 'plus loin que la Lune');
    });

    test('la règle de 72 approche le temps de doublement', () {
      for (final double taux in <double>[2, 3, 5, 8, 10]) {
        final double exact = math.ln2 / math.log(1 + taux / 100);
        final double regle = 72 / taux;
        expect(
          (regle - exact).abs() / exact,
          lessThan(0.06),
          reason: 'taux $taux % : exact $exact, règle $regle',
        );
      }
      // Le cas du chapitre, à 5 %.
      expect(math.ln2 / math.log(1.05), closeTo(14.2, 0.05));
      expect(72 / 5, closeTo(14.4, 0.01));
    });

    test('d\'où vient le 72', () {
      // ln(2) × 100 ≈ 69,3, arrondi à 72 parce que 72 a beaucoup de
      // diviseurs entiers — ce que le chapitre affirme.
      expect(math.ln2 * 100, closeTo(69.31, 0.01));
      final List<int> diviseurs = <int>[
        for (int d = 1; d <= 72; d++)
          if (72 % d == 0) d,
      ];
      expect(diviseurs.length, 12);
      // 69 et 70 en ont nettement moins.
      for (final int n in <int>[69, 70, 71]) {
        final int combien = <int>[
          for (int d = 1; d <= n; d++)
            if (n % d == 0) d,
        ].length;
        expect(combien, lessThan(diviseurs.length), reason: '$n');
      }
    });
  });
}
