import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// La technologie du collège, recalculée.
///
/// Trois affirmations de ces chapitres méritaient d'être établies plutôt
/// qu'avancées : que le bois batte l'acier à masse égale, que les
/// rendements d'une chaîne se multiplient au point de s'effondrer, et que
/// la même méthode de remboursement conclue qu'il faut remplacer un
/// réfrigérateur et garder un téléphone. Les trois se calculent.
void main() {
  group('Résistance spécifique', () {
    /// Résistance en mégapascals, masse volumique en g/cm³.
    const Map<String, (double, double)> materiaux = {
      'acier': (400, 7.9),
      'aluminium': (300, 2.7),
      'pin': (50, 0.5),
      'fonte': (150, 7.2),
      'titane': (900, 4.5),
    };

    double specifique(String m) =>
        materiaux[m]!.$1 / materiaux[m]!.$2;

    test('les trois valeurs du chapitre', () {
      expect(specifique('acier'), closeTo(50.6, 0.1));
      expect(specifique('pin'), 100);
      expect(specifique('aluminium'), closeTo(111.1, 0.1));
    });

    test('le pin bat l’acier à masse égale', () {
      expect(specifique('pin'), greaterThan(specifique('acier')));
      // Presque le double, ce que la carte affirme.
      expect(specifique('pin') / specifique('acier'), closeTo(1.98, 0.02));
    });

    test('mais l’acier bat le pin en résistance brute', () {
      // Les deux classements sont opposés, et c'est tout l'intérêt de la
      // grandeur spécifique.
      expect(materiaux['acier']!.$1, greaterThan(materiaux['pin']!.$1));
      expect(specifique('acier'), lessThan(specifique('pin')));
    });

    test('le classement spécifique du chapitre est exact', () {
      final List<String> parSpecifique = <String>['acier', 'pin', 'aluminium'];
      for (int i = 1; i < parSpecifique.length; i++) {
        expect(specifique(parSpecifique[i]),
            greaterThan(specifique(parSpecifique[i - 1])),
            reason: '${parSpecifique[i]} après ${parSpecifique[i - 1]}');
      }
    });

    test('le titane dépasse tout le monde, et la fonte personne', () {
      expect(specifique('titane'), closeTo(200, 0.1));
      expect(specifique('fonte'), closeTo(20.8, 0.1));
      final List<String> tous = materiaux.keys.toList()
        ..sort((a, b) => specifique(a).compareTo(specifique(b)));
      expect(tous.first, 'fonte');
      expect(tous.last, 'titane');
    });

    test('la découpe en travers du fil divise par plus de huit', () {
      const double parallele = 50;
      const double travers = 6;
      expect(parallele / travers, closeTo(8.33, 0.01));
      // Et la section de 200 mm² donne les deux charges du défi.
      const double section = 200;
      expect(section * parallele, 10000);
      expect(section * travers, 1200);
      expect(section * parallele / (section * travers), closeTo(8.33, 0.01));
    });

    test('la section du défi se calcule bien', () {
      expect(20 * 10, 200, reason: '2 cm × 1 cm en millimètres');
      expect(50 / 8, 6.25, reason: 'huit fois moins en travers');
      expect(25 / 30 * 100, closeTo(83.3, 0.1));
    });

    test('les masses des trois cadres de vélo', () {
      expect(2.5 - 1.4, closeTo(1.1, 1e-9));
      expect(1.1 / 2.5 * 100, closeTo(44, 1e-9));
      expect(1.4 - 0.9, closeTo(0.5, 1e-9));
      // Le second gain est deux fois plus petit que le premier.
      expect((2.5 - 1.4) / (1.4 - 0.9), closeTo(2.2, 0.01));
    });
  });

  group('Chaîne d’énergie', () {
    double total(List<double> rendements) =>
        rendements.fold<double>(1, (double p, double r) => p * r);

    test('trois maillons à zéro virgule neuf', () {
      expect(total(<double>[0.9, 0.9, 0.9]), closeTo(0.729, 1e-9));
      expect((total(<double>[0.9, 0.9, 0.9]) * 100).round(), 73);
    });

    test('cinq maillons à zéro virgule neuf perdent plus de quarante pour cent', () {
      final double r = total(<double>[0.9, 0.9, 0.9, 0.9, 0.9]);
      expect(r, closeTo(0.59049, 1e-9));
      expect((r * 100).round(), 59);
      expect(1 - r, greaterThan(0.4));
    });

    test('les rendements ne se moyennent pas', () {
      final double produit = total(<double>[0.8, 0.5]);
      const double moyenne = (0.8 + 0.5) / 2;
      expect(produit, closeTo(0.4, 1e-9));
      expect(moyenne, closeTo(0.65, 1e-9));
      expect(produit, lessThan(moyenne), reason: 'la moyenne est optimiste');
    });

    test('la chaîne charbon-roue donne vingt-neuf pour cent', () {
      final double r = total(<double>[0.40, 0.95, 0.90, 0.95, 0.90]);
      expect(r, closeTo(0.2924, 1e-4));
      expect((r * 100).round(), 29);
    });

    test('la marge d’un maillon est bornée par un sur son rendement', () {
      // C'est la seule affirmation vraie sans condition, et elle se calcule
      // avant d'avoir engagé le moindre travail : un maillon ne peut pas
      // dépasser 1, donc il ne peut pas rapporter plus qu'un facteur 1/r.
      double margeMaximale(double r) => 1 / r - 1;
      expect(margeMaximale(0.40), closeTo(1.50, 0.01), reason: '+150 %');
      expect(margeMaximale(0.90), closeTo(0.111, 0.001), reason: '+11 %');
      expect(margeMaximale(0.95), closeTo(0.053, 0.001), reason: '+5 %');
      expect(margeMaximale(0.99), closeTo(0.010, 0.001), reason: '+1 %');
      // La marge décroît strictement quand le rendement monte.
      double precedent = double.infinity;
      for (double r = 0.1; r <= 0.99; r += 0.05) {
        expect(margeMaximale(r), lessThan(precedent), reason: 'r = $r');
        precedent = margeMaximale(r);
      }
    });

    test('la centrale retire à elle seule plus que les quatre autres réunis', () {
      const double centrale = 0.40;
      final double quatreAutres = total(<double>[0.95, 0.90, 0.95, 0.90]);
      expect(1 - centrale, closeTo(0.60, 1e-9));
      expect(1 - quatreAutres, closeTo(0.269, 1e-3));
      expect(1 - centrale, greaterThan(1 - quatreAutres));
    });

    test('mais améliorer quatre maillons peut battre dix points sur un seul', () {
      // L'inverse de ce qu'on croit, et ce que je croyais : le produit de
      // quatre petits gains relatifs dépasse un gain de dix points sur le
      // maillon faible. C'est le calcul qui tranche, pas l'intuition.
      final double base = total(<double>[0.40, 0.95, 0.90, 0.95, 0.90]);
      final double dixPointsSurLaCentrale =
          total(<double>[0.50, 0.95, 0.90, 0.95, 0.90]);
      final double quatreAutresAuMaximum =
          total(<double>[0.40, 0.99, 0.99, 0.99, 0.99]);
      expect(dixPointsSurLaCentrale - base, closeTo(0.073, 0.001));
      expect(quatreAutresAuMaximum - base, closeTo(0.092, 0.001));
      expect(quatreAutresAuMaximum, greaterThan(dixPointsSurLaCentrale));
      // Il faut vingt points sur la centrale pour reprendre l'avantage.
      final double vingtPoints = total(<double>[0.60, 0.95, 0.90, 0.95, 0.90]);
      expect(vingtPoints, greaterThan(quatreAutresAuMaximum));
    });

    test('dix maillons excellents perdent encore quarante pour cent', () {
      final double r = total(List<double>.filled(10, 0.95));
      expect(r, closeTo(0.5987, 1e-4));
      expect(1 - r, greaterThan(0.4));
    });

    test('un rendement total ne peut pas dépasser le plus faible maillon', () {
      final math.Random alea = math.Random(7);
      for (int essai = 0; essai < 200; essai++) {
        final int n = 2 + alea.nextInt(6);
        final List<double> r = List<double>.generate(
            n, (int i) => 0.3 + alea.nextDouble() * 0.69);
        final double plusFaible = r.reduce(math.min);
        expect(total(r), lessThanOrEqualTo(plusFaible + 1e-12),
            reason: 'essai $essai avec $r');
      }
    });
  });

  group('Watt et wattheure', () {
    double wattheures(double watts, double heures) => watts * heures;

    test('le radiateur et l’ampoule arrivent au même kilowattheure', () {
      expect(wattheures(2000, 3), 6000);
      expect(wattheures(10, 100), 1000);
      expect(wattheures(2000, 0.5), 1000);
      // Deux appareils très différents, même énergie consommée.
      expect(wattheures(10, 100), wattheures(2000, 0.5));
    });

    test('trente minutes de radiateur font mille wattheures', () {
      expect(1000 / 2000 * 60, 30);
    });

    test('la batterie en wattheures', () {
      const double ampereHeures = 4;
      const double volts = 3.7;
      expect(ampereHeures * volts, closeTo(14.8, 1e-9));
      expect(14.8 / 2, closeTo(7.4, 1e-9));
    });

    test('deux batteries de même mAh et tension différente ne sont pas égales', () {
      // 4000 mAh à 3,7 V contre 4000 mAh à 11,1 V.
      expect(4 * 3.7, closeTo(14.8, 1e-9));
      expect(4 * 11.1, closeTo(44.4, 1e-9));
      expect(4 * 11.1 / (4 * 3.7), closeTo(3, 1e-9));
    });

    test('le coût du kilowattheure', () {
      expect(6 * 0.20, closeTo(1.2, 1e-9));
    });
  });

  group('Ampoule à filament et LED', () {
    double lumens(double watts, double rendement) => watts * rendement;

    test('soixante watts de filament donnent trois watts de lumière', () {
      expect(lumens(60, 0.05), closeTo(3, 1e-9));
      expect(60 - 3, 57);
    });

    test('une LED donne les mêmes trois watts avec sept virgule cinq', () {
      expect(3 / 0.40, closeTo(7.5, 1e-9));
      expect(60 / 7.5, 8);
      // Le rapport de consommation est exactement celui des rendements.
      expect(0.40 / 0.05, 8);
      expect(60 / 7.5, 0.40 / 0.05);
    });

    test('dix lampes, quatre heures par jour, trente jours', () {
      double kWh(double watts) => watts * 10 * 4 * 30 / 1000;
      expect(kWh(60), 72);
      expect(kWh(7.5), 9);
      expect(kWh(60) / kWh(7.5), 8);
    });
  });

  group('Matrice de choix', () {
    int score(List<int> notes, List<int> poids) {
      int s = 0;
      for (int i = 0; i < notes.length; i++) {
        s += notes[i] * poids[i];
      }
      return s;
    }

    const List<int> a = [5, 2, 3]; // résistance, coût, masse
    const List<int> b = [3, 5, 4];

    test('avec les poids d’origine, B gagne d’un point', () {
      const List<int> poids = [3, 2, 1];
      expect(score(a, poids), 22);
      expect(score(b, poids), 23);
      expect(score(b, poids) - score(a, poids), 1);
    });

    test('baisser le poids du coût inverse le classement', () {
      const List<int> poids = [3, 1, 1];
      expect(score(a, poids), 20);
      expect(score(b, poids), 18);
      expect(score(a, poids), greaterThan(score(b, poids)));
    });

    test('le classement bascule à un poids du coût précis', () {
      // On balaie le poids du coût : A gagne en dessous d'un seuil.
      int? bascule;
      for (int pc = 0; pc <= 5; pc++) {
        final List<int> poids = <int>[3, pc, 1];
        if (score(b, poids) > score(a, poids)) {
          bascule = pc;
          break;
        }
      }
      expect(bascule, 2, reason: 'B ne passe devant qu’à partir d’un poids de 2');
    });

    test('un écart d’un point sur trente ne tranche rien', () {
      const List<int> poids = [3, 2, 1];
      final int ecart = (score(b, poids) - score(a, poids)).abs();
      const int maximum = 5 * (3 + 2 + 1);
      expect(maximum, 30);
      expect(ecart / maximum, lessThan(0.05));
    });
  });

  group('Le cartable', () {
    test('dix pour cent du poids de l’élève', () {
      expect(40 * 0.10, closeTo(4, 1e-9));
      expect(55 * 0.10, closeTo(5.5, 1e-9));
    });

    test('ce qui reste pour le cartable vide', () {
      expect(4 - 3.2, closeTo(0.8, 1e-9));
      // Et la limite dépend bien de l'élève : un seul chiffre ne marche pas.
      for (final double masse in <double>[30, 40, 50, 60]) {
        expect(masse * 0.10, closeTo(masse / 10, 1e-9), reason: '$masse kg');
      }
      expect(30 * 0.10, isNot(closeTo(60 * 0.10, 0.1)));
    });

    test('le coefficient de sécurité de deux', () {
      expect(8 / 4, 2);
    });
  });

  group('Cycle de vie et remboursement', () {
    double anneesDeRemboursement({
      required double dette,
      required double economieAnnuelle,
    }) =>
        dette / economieAnnuelle;

    test('le réfrigérateur se rembourse en un peu plus d’un an', () {
      expect(500 - 150, 350);
      expect(anneesDeRemboursement(dette: 400, economieAnnuelle: 350),
          closeTo(1.14, 0.01));
      expect(anneesDeRemboursement(dette: 400, economieAnnuelle: 350),
          lessThan(2));
    });

    test('et dégage trois mille cent kilowattheures sur dix ans', () {
      expect(350 * 10 - 400, 3100);
    });

    test('le téléphone ne se rembourse jamais', () {
      expect(anneesDeRemboursement(dette: 50, economieAnnuelle: 0.5), 100);
      expect(anneesDeRemboursement(dette: 50, economieAnnuelle: 0.5),
          greaterThan(20), reason: 'bien au-delà de toute durée de vie');
    });

    test('le test rapide sépare les deux régimes', () {
      // Comparer la fabrication à une seule année d'usage.
      const double frigo = 400 / 500; // dette / usage annuel de l'ancien
      const double telephone = 50 / 2;
      expect(frigo, lessThan(1), reason: 'remplacer est rentable');
      expect(telephone, greaterThan(1), reason: 'remplacer est une perte');
      expect(telephone / frigo, greaterThan(25));
    });

    test('doubler la durée de vie divise l’empreinte annuelle par deux', () {
      double parAn(double total, double annees) => total / annees;
      expect(parAn(60, 2), 30);
      expect(parAn(60, 4), 15);
      expect(parAn(60, 6), 10);
      expect(parAn(60, 2) / parAn(60, 4), 2);
      // La relation est exacte pour toute durée.
      for (double d = 1; d <= 10; d++) {
        expect(parAn(60, d) / parAn(60, 2 * d), 2, reason: '$d ans');
      }
    });

    test('la fabrication pèse plus de quatre cinquièmes d’un téléphone', () {
      expect(50 / 60 * 100, closeTo(83.3, 0.1));
      expect(50 / 60, greaterThan(0.8));
    });
  });

  group('Vêtements', () {
    test('le jean coûte trois fois l’eau d’un tee-shirt', () {
      expect(8000 / 2500, closeTo(3.2, 1e-9));
    });

    test('dix tee-shirts par an font vingt-cinq mètres cubes', () {
      expect(10 * 2500, 25000);
      expect(25000 / 1000, 25, reason: 'mètres cubes');
      expect((25000 / 60).round(), 417, reason: 'en douches de soixante litres');
    });

    test('porter davantage divise le coût par port', () {
      double parPort(int ports) => 2500 / ports;
      expect(parPort(30).round(), 83);
      expect(parPort(100), 25);
      expect(parPort(30) / parPort(100), closeTo(100 / 30, 1e-9));
      // Et c'est le seul levier qui agit sur ce chiffre : le lavage
      // s'ajoute, il ne divise pas la fabrication.
      for (int p = 10; p <= 200; p += 10) {
        expect(parPort(p) * p, closeTo(2500, 1e-9), reason: '$p ports');
      }
    });
  });
}
