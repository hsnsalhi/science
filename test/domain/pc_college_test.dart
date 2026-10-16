import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// La physique-chimie du collège, recalculée.
///
/// Trois affirmations de ce lot portent tout le reste, et aucune n'est
/// évidente : la masse se conserve dans une réaction (donc un bilan qui ne
/// se referme pas dénonce une équation fausse), l'énergie cinétique suit le
/// carré de la vitesse (donc la distance d'arrêt aussi), et g ne faiblit
/// presque pas à 400 km (donc les astronautes ne flottent pas par absence
/// de gravité). Les trois se vérifient par le calcul.
void main() {
  group('Solutions', () {
    double concentration(double masseG, double volumeL) => masseG / volumeL;

    test('les valeurs du chapitre', () {
      expect(concentration(30, 0.5), 60);
      expect(concentration(12, 0.2), closeTo(60, 1e-9));
      expect(60 * 2, 120);
      expect(15 / 60, 0.25);
      expect(60 * 1.5, 90);
    });

    test('la concentration ne dépend pas du volume prélevé', () {
      // Prélever n'importe quel volume d'une même solution donne la même
      // concentration : c'est ce qui en fait une grandeur utile.
      const double c = 60;
      for (double v = 0.1; v <= 3.0; v += 0.1) {
        expect(concentration(c * v, v), closeTo(c, 1e-9), reason: '$v L');
      }
    });

    test('la masse se conserve à la dissolution', () {
      expect(20 + 100, 120);
      expect(200 - 12, 188);
      // Et le soluté se retrouve entièrement à l'évaporation.
      expect(concentration(12, 0.2) * 0.2, closeTo(12, 1e-9));
    });

    test('la masse volumique de 1 g/mL donne 200 g pour 200 mL', () {
      expect(200 * 1.0, 200);
    });
  });

  group('Formules chimiques', () {
    /// Le nombre d'atomes de chaque sorte dans un terme comme « 2 CO2 ».
    Map<String, int> atomes(int coefficient, Map<String, int> molecule) =>
        molecule.map((String e, int n) => MapEntry<String, int>(e, n * coefficient));

    test('H2O compte trois atomes', () {
      const Map<String, int> eau = {'H': 2, 'O': 1};
      expect(eau.values.reduce((int a, int b) => a + b), 3);
    });

    test('le coefficient multiplie tout l’intérieur', () {
      const Map<String, int> eau = {'H': 2, 'O': 1};
      expect(atomes(3, eau)['H'], 6);
      expect(atomes(3, eau)['O'], 3);
      const Map<String, int> dioxyde = {'C': 1, 'O': 2};
      expect(atomes(2, dioxyde)['O'], 4);
    });

    test('le glucose compte vingt-quatre atomes', () {
      const Map<String, int> glucose = {'C': 6, 'H': 12, 'O': 6};
      expect(glucose.values.reduce((int a, int b) => a + b), 24);
    });

    test('indice et coefficient ne sont pas interchangeables', () {
      // 2 H2 donne quatre hydrogènes répartis en deux molécules ;
      // H4 n'existe pas, et désignerait une molécule de quatre atomes liés.
      const Map<String, int> dihydrogene = {'H': 2};
      expect(atomes(2, dihydrogene)['H'], 4);
      const Map<String, int> inexistant = {'H': 4};
      expect(atomes(1, inexistant)['H'], 4);
      // Même compte d'atomes, structures différentes : le compte ne suffit
      // donc pas à identifier une substance.
      expect(atomes(2, dihydrogene)['H'], atomes(1, inexistant)['H']);
    });
  });

  group('Équations équilibrées', () {
    /// Une équation : liste de (coefficient, molécule) de chaque côté.
    bool equilibree(
      List<(int, Map<String, int>)> gauche,
      List<(int, Map<String, int>)> droite,
    ) {
      Map<String, int> total(List<(int, Map<String, int>)> cote) {
        final Map<String, int> t = <String, int>{};
        for (final (int coefficient, Map<String, int> molecule) in cote) {
          molecule.forEach((String e, int n) {
            t[e] = (t[e] ?? 0) + n * coefficient;
          });
        }
        return t;
      }

      final Map<String, int> g = total(gauche);
      final Map<String, int> d = total(droite);
      if (g.length != d.length) return false;
      for (final String e in g.keys) {
        if (g[e] != d[e]) return false;
      }
      return true;
    }

    const Map<String, int> ch4 = {'C': 1, 'H': 4};
    const Map<String, int> o2 = {'O': 2};
    const Map<String, int> co2 = {'C': 1, 'O': 2};
    const Map<String, int> h2o = {'H': 2, 'O': 1};
    const Map<String, int> h2 = {'H': 2};
    const Map<String, int> c3h8 = {'C': 3, 'H': 8};
    const Map<String, int> c2h6 = {'C': 2, 'H': 6};
    const Map<String, int> fe = {'Fe': 1};
    const Map<String, int> s = {'S': 1};
    const Map<String, int> fes = {'Fe': 1, 'S': 1};

    test('la combustion du méthane est équilibrée', () {
      expect(
        equilibree(<(int, Map<String, int>)>[(1, ch4), (2, o2)],
            <(int, Map<String, int>)>[(1, co2), (2, h2o)]),
        isTrue,
      );
    });

    test('et elle ne l’est pas avec d’autres coefficients', () {
      expect(
        equilibree(<(int, Map<String, int>)>[(1, ch4), (1, o2)],
            <(int, Map<String, int>)>[(1, co2), (2, h2o)]),
        isFalse,
      );
      expect(
        equilibree(<(int, Map<String, int>)>[(1, ch4), (2, o2)],
            <(int, Map<String, int>)>[(1, co2), (1, h2o)]),
        isFalse,
      );
    });

    test('2 H2 + O2 donne 2 H2O, et non H2O2', () {
      expect(
        equilibree(<(int, Map<String, int>)>[(2, h2), (1, o2)],
            <(int, Map<String, int>)>[(2, h2o)]),
        isTrue,
      );
      // H2O2 équilibre aussi les comptes — et change la substance.
      const Map<String, int> eauOxygenee = {'H': 2, 'O': 2};
      expect(
        equilibree(<(int, Map<String, int>)>[(1, h2), (1, o2)],
            <(int, Map<String, int>)>[(1, eauOxygenee)]),
        isTrue,
        reason: 'les comptes tombent juste, ce qui rend le piège crédible',
      );
      // Mais ce n'est pas la même molécule : un oxygène de plus par molécule.
      expect(eauOxygenee['O'], isNot(h2o['O']));
    });

    test('le propane : cinq O2 et pas un autre nombre', () {
      for (int k = 1; k <= 10; k++) {
        final bool ok = equilibree(
          <(int, Map<String, int>)>[(1, c3h8), (k, o2)],
          <(int, Map<String, int>)>[(3, co2), (4, h2o)],
        );
        expect(ok, k == 5, reason: '$k O₂');
      }
    });

    test('l’éthane doublé : sept O2', () {
      for (int k = 1; k <= 12; k++) {
        final bool ok = equilibree(
          <(int, Map<String, int>)>[(2, c2h6), (k, o2)],
          <(int, Map<String, int>)>[(4, co2), (6, h2o)],
        );
        expect(ok, k == 7, reason: '$k O₂');
      }
    });

    test('doubler toute l’équation la laisse équilibrée', () {
      expect(
        equilibree(<(int, Map<String, int>)>[(2, ch4), (4, o2)],
            <(int, Map<String, int>)>[(2, co2), (4, h2o)]),
        isTrue,
      );
      // Et tripler aussi : une équation décrit des proportions.
      expect(
        equilibree(<(int, Map<String, int>)>[(3, ch4), (6, o2)],
            <(int, Map<String, int>)>[(3, co2), (6, h2o)]),
        isTrue,
      );
    });

    test('Fe + S donne FeS est déjà équilibrée', () {
      expect(
        equilibree(<(int, Map<String, int>)>[(1, fe), (1, s)],
            <(int, Map<String, int>)>[(1, fes)]),
        isTrue,
      );
    });
  });

  group('Bilans de masse', () {
    /// Masses molaires, en grammes par mole.
    const Map<String, double> masses = {
      'CH4': 16,
      'O2': 32,
      'CO2': 44,
      'H2O': 18,
      'Fe': 56,
      'S': 32,
      'FeS': 88,
    };

    test('la combustion du méthane : quatre-vingts de chaque côté', () {
      final double gauche = masses['CH4']! + 2 * masses['O2']!;
      final double droite = masses['CO2']! + 2 * masses['H2O']!;
      expect(gauche, 80);
      expect(droite, 80);
      expect(gauche, droite, reason: 'le bilan confirme l’équilibrage');
    });

    test('un bilan qui ne se referme pas dénonce une équation fausse', () {
      // Avec un seul O2, l'équation n'est pas équilibrée et les masses
      // ne coïncident plus : le bilan de masse est un détecteur d'erreur.
      final double fauxGauche = masses['CH4']! + 1 * masses['O2']!;
      final double droite = masses['CO2']! + 2 * masses['H2O']!;
      expect(fauxGauche, 48);
      expect(fauxGauche, isNot(droite));
    });

    test('le rapport CO2 par méthane vaut deux virgule soixante-quinze', () {
      expect(masses['CO2']! / masses['CH4']!, 2.75);
      expect(4 * 2.75, 11);
    });

    test('quatre kilos de méthane : seize d’oxygène, onze de CO2, neuf d’eau', () {
      const double methane = 4;
      final double facteur = methane / masses['CH4']!;
      expect(facteur * 2 * masses['O2']!, 16);
      expect(facteur * masses['CO2']!, 11);
      expect(facteur * 2 * masses['H2O']!, 9);
      // Et le bilan se referme : 4 + 16 = 11 + 9.
      expect(methane + 16, 20);
      expect(11 + 9, 20);
    });

    test('le fer et le soufre', () {
      expect(masses['Fe']! + masses['S']!, masses['FeS']);
      expect(masses['FeS'], 88);
    });

    test('la laine de fer gagne la masse de l’oxygène, pas plus', () {
      // Fe + S est l'exemple du chapitre ; le principe est le même pour
      // l'oxydation : la masse gagnée est exactement celle du gaz capté.
      const double laine = 56;
      const double oxygeneCapte = 32;
      expect(laine + oxygeneCapte, 88);
      expect(laine + oxygeneCapte - laine, oxygeneCapte,
          reason: 'le gain vaut la masse captée, ni plus ni moins');
    });
  });

  group('Énergie cinétique', () {
    double ec(double masse, double vitesse) => 0.5 * masse * vitesse * vitesse;

    test('les valeurs du chapitre', () {
      expect(ec(1000, 14), 98000);
      expect(ec(1000, 28), 392000);
    });

    test('doubler la vitesse quadruple l’énergie, pour toute masse', () {
      for (double m = 500; m <= 3000; m += 500) {
        for (double v = 5; v <= 40; v += 5) {
          expect(ec(m, 2 * v) / ec(m, v), closeTo(4, 1e-9),
              reason: 'm = $m, v = $v');
        }
      }
    });

    test('doubler la masse ne fait que doubler l’énergie', () {
      for (double m = 500; m <= 3000; m += 500) {
        for (double v = 5; v <= 40; v += 5) {
          expect(ec(2 * m, v) / ec(m, v), closeTo(2, 1e-9),
              reason: 'm = $m, v = $v');
        }
      }
    });

    test('de cinquante à soixante-dix, l’énergie double presque', () {
      final double rapport = ec(1000, 70) / ec(1000, 50);
      expect(rapport, closeTo(1.96, 1e-9));
      expect(rapport, closeTo(2, 0.05));
    });

    test('la règle du carré des dizaines', () {
      int distanceArret(int kmh) => (kmh ~/ 10) * (kmh ~/ 10);
      expect(distanceArret(50), 25);
      expect(distanceArret(90), 81);
      expect(distanceArret(130), 169);
      // De 90 à 130, la vitesse croît de 44 % et la distance de 109 %.
      expect((130 - 90) / 90, closeTo(0.444, 0.001));
      expect((169 - 81) / 81, closeTo(1.086, 0.001));
      expect(distanceArret(130) / distanceArret(90), greaterThan(2));
    });
  });

  group('Distance d’arrêt, terme par terme', () {
    double reaction(double vitesseMs, double tempsS) => vitesseMs * tempsS;
    double freinage(double vitesseMs, double reference, double freinageRef) =>
        freinageRef * (vitesseMs / reference) * (vitesseMs / reference);

    test('à quatorze mètres par seconde', () {
      expect(reaction(14, 1), 14);
      expect(freinage(14, 14, 14), 14);
      expect(reaction(14, 1) + freinage(14, 14, 14), 28);
    });

    test('à vingt-huit : la réaction double, le freinage quadruple', () {
      expect(reaction(28, 1), 28);
      expect(freinage(28, 14, 14), 56);
      expect(reaction(28, 1) / reaction(14, 1), 2);
      expect(freinage(28, 14, 14) / freinage(14, 14, 14), 4);
    });

    test('et le total triple, entre les deux', () {
      final double court = reaction(14, 1) + freinage(14, 14, 14);
      final double long = reaction(28, 1) + freinage(28, 14, 14);
      expect(long, 84);
      expect(long / court, 3);
      expect(long / court, greaterThan(2), reason: 'plus que la réaction');
      expect(long / court, lessThan(4), reason: 'moins que le freinage');
    });

    test('le freinage finit par dominer la réaction', () {
      // À basse vitesse la réaction pèse autant ; à haute vitesse le
      // freinage l'écrase. On cherche où il la dépasse d'un facteur trois.
      double? seuil;
      for (double v = 5; v <= 60; v += 0.5) {
        if (freinage(v, 14, 14) > 3 * reaction(v, 1)) {
          seuil = v;
          break;
        }
      }
      expect(seuil, isNotNull);
      expect(seuil!, closeTo(42, 1));
      // Soit environ 150 km/h.
      expect(seuil * 3.6, closeTo(151, 4));
    });

    test('le piéton à quarante mètres', () {
      final double court = reaction(14, 1) + freinage(14, 14, 14);
      final double long = reaction(28, 1) + freinage(28, 14, 14);
      expect(40 - court, 12, reason: 'arrêt douze mètres avant lui');
      expect(long - 40, 44, reason: 'dépassé de quarante-quatre mètres');
    });
  });

  group('Puissance et énergie', () {
    test('la puissance est un débit', () {
      expect(6000 / 30, 200);
    });

    test('un kilowattheure vaut trois millions six cent mille joules', () {
      expect(1000 * 3600, 3600000);
    });

    test('les consommations du chapitre', () {
      expect(1.5 * 2, 3);
      expect(8 * 5 * 30 / 1000, 1.2);
      expect(3 * 0.20, closeTo(0.6, 1e-9));
      expect(100 * 24 / 1000, 2.4);
    });

    test('même énergie, puissances très différentes', () {
      // Une LED pendant cent heures et un radiateur pendant une demi-heure
      // consomment le même kilowattheure.
      expect(10 * 100, 1000);
      expect(2000 * 0.5, 1000);
      expect(10 * 100, 2000 * 0.5);
    });
  });

  group('Masse et poids', () {
    const Map<String, double> g = {
      'Terre': 9.8,
      'Lune': 1.6,
      'Mars': 3.7,
      'Jupiter': 24.8,
      'Soleil': 274,
    };

    double poids(double masse, String astre) => masse * g[astre]!;

    test('un corps de soixante kilos', () {
      expect(poids(60, 'Terre'), closeTo(588, 0.1));
      expect(poids(60, 'Lune'), closeTo(96, 0.1));
      expect(poids(60, 'Jupiter'), closeTo(1488, 0.1));
    });

    test('un sac de vingt kilos', () {
      expect(poids(20, 'Terre'), closeTo(196, 0.1));
      expect(poids(20, 'Lune'), 32);
      expect(poids(20, 'Jupiter'), closeTo(496, 0.1));
    });

    test('la masse ne change jamais, le poids toujours', () {
      const double masse = 20;
      final Set<double> poidsDistincts =
          g.keys.map((String a) => poids(masse, a)).toSet();
      expect(poidsDistincts.length, g.length,
          reason: 'cinq astres, cinq poids différents');
      // Alors que la masse est unique.
      expect(<double>{masse}.length, 1);
    });

    test('la Terre pèse environ six fois la Lune', () {
      expect(g['Terre']! / g['Lune']!, closeTo(6.125, 0.001));
      expect((g['Terre']! / g['Lune']!).round(), 6);
    });

    test('le poids est proportionnel à la masse, sur chaque astre', () {
      for (final String astre in g.keys) {
        for (double m = 1; m <= 100; m += 7) {
          expect(poids(2 * m, astre) / poids(m, astre), closeTo(2, 1e-9),
              reason: '$astre, masse $m');
        }
      }
    });
  });

  group('Attraction et altitude', () {
    const double rayonTerre = 6371000;

    double gAltitude(double hauteurM) =>
        9.81 * math.pow(rayonTerre / (rayonTerre + hauteurM), 2).toDouble();

    test('doubler la distance divise la force par quatre', () {
      for (double d = 1; d <= 10; d++) {
        final double proche = 1 / (d * d);
        final double loin = 1 / (4 * d * d);
        expect(proche / loin, closeTo(4, 1e-9), reason: 'distance $d');
      }
    });

    test('tripler la divise par neuf', () {
      expect(1 / 1 / (1 / 9), closeTo(9, 1e-9));
    });

    test('à quatre cents kilomètres, g vaut encore huit virgule sept', () {
      expect(gAltitude(400000), closeTo(8.7, 0.05));
    });

    test('soit près de quatre-vingt-dix pour cent de sa valeur au sol', () {
      final double part = gAltitude(400000) / 9.81;
      expect(part, closeTo(0.886, 0.01));
      expect((part * 100).round(), inInclusiveRange(88, 90));
      expect(part, greaterThan(0.85),
          reason: 'l’expression « absence de gravité » est donc fausse');
    });

    test('le poids du sac à cette altitude', () {
      expect(20 * 8.7, closeTo(174, 0.1));
      expect(8.7 / 9.8 * 100, closeTo(88.8, 0.1));
    });

    test('il faut s’éloigner beaucoup pour que g s’effondre vraiment', () {
      // Une altitude d'un rayon terrestre divise g par quatre.
      expect(gAltitude(rayonTerre) / 9.81, closeTo(0.25, 0.001));
      // Et à la distance de la Lune, g terrestre est négligeable.
      expect(gAltitude(384400000), lessThan(0.003));
    });
  });

  group('Système solaire', () {
    test('Saturne flotterait, la Terre non', () {
      const double saturne = 0.7;
      const double terre = 5.5;
      const double eau = 1.0;
      expect(saturne, lessThan(eau));
      expect(terre, greaterThan(eau));
      expect(terre / saturne, closeTo(7.857, 0.001));
      expect((terre / saturne).round(), 8);
    });

    test('les périodes orbitales croissent avec la distance', () {
      const Map<String, double> periodes = {
        'Terre': 1,
        'Jupiter': 12,
        'Saturne': 29,
        'Neptune': 165,
      };
      double precedente = 0;
      for (final double p in periodes.values) {
        expect(p, greaterThan(precedente));
        precedente = p;
      }
      expect(periodes['Jupiter']! * 3, 36);
    });

    test('Neptune n’a bouclé qu’un tour depuis sa découverte', () {
      expect(2011 - 1846, 165);
      expect((2011 - 1846) ~/ 165, 1);
      // Et le tour suivant s'achèvera en 2176.
      expect(2011 + 165, 2176);
    });

    test('une année neptunienne dépasse deux vies humaines', () {
      expect(165 / 80, greaterThan(2));
    });
  });
}
