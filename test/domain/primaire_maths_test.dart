import 'package:eureka/design_system/figures/clock_figure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les quatre chapitres de maths du primaire, recalculés.
///
/// Au primaire l'erreur ne vient jamais d'une théorie fausse mais d'un
/// calcul recopié de travers, ou d'un énoncé dont la réponse a changé
/// après qu'on a retouché un nombre. Ces tests refont chaque opération
/// annoncée, et vérifient que l'horloge place ses aiguilles là où une
/// vraie horloge les placerait.
void main() {
  group('Les nombres jusqu\'à 100', () {
    test('la valeur d\'un chiffre dépend de sa place', () {
      for (int n = 10; n <= 99; n++) {
        final int dizaines = n ~/ 10;
        final int unites = n % 10;
        expect(dizaines * 10 + unites, n);
        // 47 et 74 : mêmes chiffres, nombres différents dès que les deux
        // chiffres diffèrent. C'est le point de la carte d'avertissement.
        final int renverse = unites * 10 + dizaines;
        if (dizaines != unites) {
          expect(renverse, isNot(n), reason: '$n renversé');
        }
      }
      expect(47, isNot(74));
      expect(4 * 10, 40, reason: 'le 4 de 47 vaut quarante');
    });

    test('les décompositions du cours', () {
      expect(4 * 10 + 7, 47);
      expect(6 * 10 + 3, 63);
      expect(50 + 8, 58);
      expect(40 + 18, 58, reason: 'une autre coupe, tout aussi juste');
      expect(2 * 10 + 9, 29);
      expect(80 + 17, 97, reason: 'quatre-vingt-dix-sept');
    });

    test('les voisins, y compris aux passages de dizaine', () {
      expect(39 + 1, 40);
      expect(70 - 1, 69);
      expect(80 - 1, 79);
      expect(99 + 1, 100);
      expect(100 ~/ 10, 10, reason: 'dix paquets de dix');
    });

    test('compter de dix en dix ne change que les dizaines', () {
      int n = 7;
      final List<int> suite = <int>[];
      for (int i = 0; i < 6; i++) {
        suite.add(n);
        n += 10;
      }
      expect(suite, <int>[7, 17, 27, 37, 47, 57]);
      for (final int x in suite) {
        expect(x % 10, 7, reason: 'le chiffre des unités ne bouge pas');
      }
    });

    test('les devinettes du défi ont une seule réponse', () {
      // Entre 40 et 50 avec 7 unités.
      final List<int> a = <int>[
        for (int n = 41; n < 50; n++)
          if (n % 10 == 7) n,
      ];
      expect(a, <int>[47]);
      // Deux chiffres identiques entre 60 et 70 : c'est la correction que
      // la première version de l'énoncé appelait, car 55 et 66 convenaient
      // tous deux à « entre 50 et 70 ».
      final List<int> b = <int>[
        for (int n = 61; n < 70; n++)
          if (n ~/ 10 == n % 10) n,
      ];
      expect(b, <int>[66]);
      final List<int> large = <int>[
        for (int n = 51; n < 70; n++)
          if (n ~/ 10 == n % 10) n,
      ];
      expect(large.length, 2, reason: 'l\'énoncé large était ambigu');
    });
  });

  group('Additionner et soustraire', () {
    test('les calculs posés du chapitre', () {
      expect(47 + 38, 85);
      expect(85 - 38, 47, reason: 'la vérification par l\'addition');
      expect(63 + 29, 92);
      expect(47 + 8, 55, reason: 'les unités sous les unités');
    });

    test('les chemins de calcul mental donnent le même résultat', () {
      // Passer par dix.
      expect(8 + 5, 13);
      expect((8 + 2) + 3, 8 + 5);
      // Ajouter presque dix.
      expect(27 + 9, 36);
      expect(27 + 10 - 1, 27 + 9);
      expect(45 + 19, 64);
      expect(45 + 20 - 1, 45 + 19);
      // Le double, plus un.
      expect(7 + 8, 15);
      expect(7 + 7 + 1, 7 + 8);
      // Soustraire en avançant.
      expect(52 - 48, 4);
      expect(48 + 4, 52);
    });

    test('les trois sens de la soustraction mènent au même calcul', () {
      const int enlever = 13 - 5;
      const int comparer = 13 - 5;
      const int manquer = 13 - 5;
      expect(enlever, 8);
      expect(comparer, 8);
      expect(manquer, 8);
      expect(8 + 5, 13, reason: 'les deux opérations se défont');
    });

    test('les problèmes du défi, dans l\'ordre', () {
      // L'ordre compte : le bus.
      expect(23 - 7 + 12, 28);
      expect(23 + 7 - 12, 18, reason: 'le mauvais ordre, pour mémoire');
      expect(23 - 7 + 12, isNot(23 + 7 - 12));
      // Les autres.
      expect(50 - (12 + 3), 35);
      expect(24 - 6 + 24, 42);
      expect(34 - 8, 26, reason: '« 8 de plus » pour Paul');
      expect(42 - 15, 27);
    });

    test('l\'addition se renverse, pas la soustraction', () {
      for (int a = 0; a <= 30; a++) {
        for (int b = 0; b <= 30; b++) {
          expect(a + b, b + a);
          if (a != b) expect(a - b, isNot(b - a));
        }
      }
    });
  });

  group('Le temps et les durées', () {
    test('les conversions', () {
      expect(2 * 60, 120);
      expect(60 * 60, 3600);
      expect(7 * 24, 168);
      expect(24 * 60, 1440);
      expect(24 * 60 * 60, 86400);
      expect(366 - 365, 1, reason: 'le 29 février');
    });

    test('les durées calculées en passant par les heures rondes', () {
      // 9 h 40 -> 11 h 15
      expect(20 + 60 + 15, 95);
      // 8 h 25 -> 10 h 10
      expect(35 + 60 + 10, 105);
      // 23 h 40 -> 1 h 20, en passant par minuit
      expect(20 + 80, 100);
      // 10 h 15 -> 10 h 35
      expect(35 - 15, 20);
      // 21 h 30 -> 7 h
      expect(2.5 + 7, 9.5);
    });

    test('une heure fait soixante minutes, pas cent', () {
      // Le piège central du chapitre : 1 h 45 + 30 min.
      const int minutes = 45 + 30;
      expect(minutes, 75);
      expect(minutes ~/ 60, 1, reason: 'une heure de plus');
      expect(minutes % 60, 15, reason: 'et quinze minutes');
      // Donc 2 h 15, et surtout pas 1 h 75.
      expect(1 * 60 + 45 + 30, 2 * 60 + 15);
    });

    test('après-midi : on ajoute douze', () {
      expect(2 + 12, 14);
      expect(5 + 12, 17);
      expect(8 + 12, 20);
      // 16 h 20 moins 1 h 50 donne 14 h 30.
      const int finMinutes = 16 * 60 + 20;
      const int duree = 1 * 60 + 50;
      expect((finMinutes - duree) ~/ 60, 14);
      expect((finMinutes - duree) % 60, 30);
    });
  });

  group('L\'horloge place ses aiguilles comme une vraie', () {
    test('les minutes font six degrés chacune', () {
      for (int m = 0; m < 60; m++) {
        expect(ClockFigure.angleMinutes(m), m * 6);
      }
      expect(ClockFigure.angleMinutes(0), 0);
      expect(ClockFigure.angleMinutes(15), 90);
      expect(ClockFigure.angleMinutes(30), 180);
      expect(ClockFigure.angleMinutes(45), 270);
    });

    test('la grande aiguille va douze fois plus vite que la petite', () {
      // Sur une heure pleine, l'une fait 360 degrés et l'autre 30.
      final double grande =
          ClockFigure.angleMinutes(59) - ClockFigure.angleMinutes(0);
      final double petite =
          ClockFigure.angleHeures(3, 59) - ClockFigure.angleHeures(3, 0);
      expect(grande / petite, closeTo(12, 0.001));
    });

    test('la petite aiguille avance entre les chiffres', () {
      // Le point que la figure doit respecter : à 3 h 30, elle est à
      // mi-chemin entre le 3 et le 4, pas sur le 3. Une horloge qui la
      // collerait au chiffre enseignerait une lecture fausse.
      expect(ClockFigure.angleHeures(3, 0), 90);
      expect(ClockFigure.angleHeures(3, 30), 105);
      expect(ClockFigure.angleHeures(4, 0), 120);
      expect(
        ClockFigure.angleHeures(3, 30),
        (ClockFigure.angleHeures(3, 0) + ClockFigure.angleHeures(4, 0)) / 2,
      );
    });

    test('midi et minuit mettent les deux aiguilles sur le douze', () {
      for (final int h in <int>[0, 12, 24]) {
        expect(ClockFigure.angleHeures(h, 0) % 360, 0);
      }
      expect(ClockFigure.angleMinutes(0), 0);
    });

    test('les heures de l\'après-midi retombent sur le bon chiffre', () {
      for (int h = 0; h < 24; h++) {
        expect(
          ClockFigure.angleHeures(h, 0),
          ClockFigure.angleHeures(h % 12, 0),
          reason: '$h h',
        );
      }
      expect(ClockFigure.angleHeures(14, 0), ClockFigure.angleHeures(2, 0));
    });

    test('les angles restent dans un tour', () {
      for (int h = 0; h < 24; h++) {
        for (int m = 0; m < 60; m++) {
          expect(ClockFigure.angleHeures(h, m), inInclusiveRange(0, 360));
          expect(ClockFigure.angleMinutes(m), inInclusiveRange(0, 360));
        }
      }
    });

    test('les formulations françaises', () {
      expect(ClockFigure.enToutesLettres(3, 0), '3 heures pile');
      expect(ClockFigure.enToutesLettres(3, 15), '3 heures et quart');
      expect(ClockFigure.enToutesLettres(3, 30), '3 heures et demie');
      // Moins le quart renvoie à l'heure SUIVANTE, ce que le chapitre dit.
      expect(ClockFigure.enToutesLettres(14, 45), '15 heures moins le quart');
      expect(ClockFigure.enToutesLettres(23, 45), '0 heures moins le quart');
      expect(ClockFigure.enToutesLettres(9, 7), '9 h 07');
    });
  });

  group('La proportionnalité', () {
    test('la recette et le prix des croissants', () {
      expect(200 * 2, 400);
      expect(200 ~/ 2, 100);
      expect(9 / 6, 1.5);
      expect(1.5 * 10, 15);
      expect(6 * 1.5, 9, reason: 'le coefficient tient aux deux bouts');
      expect(10 / 4 * 6, 15, reason: 'les cahiers');
      expect(120 / 2 * 5, 300, reason: 'la voiture');
    });

    test('le coefficient est le même pour toutes les lignes', () {
      const double coefficient = 1.5;
      for (final int n in <int>[1, 2, 6, 10, 24]) {
        expect(n * coefficient / n, closeTo(coefficient, 1e-12));
      }
    });

    test('les pourcentages du chapitre', () {
      expect(80 * 25 / 100, 20);
      expect(350 * 0.1, closeTo(35, 1e-9));
      expect(40 - 40 * 0.3, closeTo(28, 1e-9));
      expect(25000 / 100, 250, reason: 'l\'échelle, en mètres');
    });

    test('hausse puis baisse de 10 % ne ramène pas au départ', () {
      const double apres = 100 * 1.1 * 0.9;
      expect(apres, closeTo(99, 1e-9));
      expect(apres, lessThan(100));
      // Et l'écart vaut toujours 1 % du départ, quel que soit le prix.
      for (final double prix in <double>[50, 200, 1234]) {
        expect(prix * 1.1 * 0.9, closeTo(prix * 0.99, 1e-9));
      }
    });

    test('les proportions inverses du défi', () {
      // Trois ouvriers en six jours : le travail total vaut 18 jours-homme.
      const int travail = 3 * 6;
      expect(travail, 18);
      expect(travail ~/ 6, 3, reason: 'six ouvriers');
      expect(travail ~/ 1, 18, reason: 'un seul ouvrier');
      // La règle de trois directe donnerait 12, ce qui est absurde.
      expect(6 * 6 / 3, 12);
      expect(12, greaterThan(6), reason: 'plus d\'ouvriers, plus de temps ?');
      // Les robinets suivent la même loi.
      expect(12 ~/ 2, 6);
    });

    test('les œufs s\'arrondissent au-dessus', () {
      const double exact = 3 / 4 * 10;
      expect(exact, 7.5);
      expect(exact.ceil(), 8, reason: 'on ne casse pas un demi-œuf');
    });

    test('le test du zéro distingue les deux familles', () {
      // Proportionnel : zéro va avec zéro.
      double prixEssence(double litres) => litres * 1.8;
      expect(prixEssence(0), 0);
      // Pas proportionnel : le taxi part de trois euros.
      double prixTaxi(double km) => 3 + 2 * km;
      expect(prixTaxi(0), 3);
      expect(prixTaxi(0), isNot(0));
      // Et doubler la distance ne double pas le prix du taxi.
      expect(prixTaxi(10), 23);
      expect(prixTaxi(20), 43);
      expect(prixTaxi(20), isNot(2 * prixTaxi(10)));
      expect(prixEssence(20), 2 * prixEssence(10));
    });
  });
}
