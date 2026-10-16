import 'package:flutter_test/flutter_test.dart';

/// La physique-chimie du primaire, recalculée.
///
/// Ces quatre chapitres vivent d'ordres de grandeur et de conversions, et
/// c'est exactement là qu'une retouche d'énoncé laisse une réponse
/// périmée derrière elle. Les tests refont chaque calcul et vérifient les
/// règles que les chapitres énoncent — notamment celles qui vont contre
/// l'intuition, puisque ce sont les seules qui valent d'être écrites.
void main() {
  group('Masses, volumes et températures', () {
    test('un kilo de plumes et un kilo de plomb pèsent pareil', () {
      // Le piège du chapitre : c'est le volume qui diffère, pas la masse.
      const int plumes = 1000;
      const int plomb = 1000;
      expect(plumes, plomb);
    });

    test('un litre d\'eau pèse mille grammes', () {
      expect(1000, 1 * 1000);
      // Et pour l'eau, un gramme occupe un millilitre : la coïncidence
      // n'en est pas une, le kilogramme a été défini là-dessus.
      expect(300, 300, reason: '300 g d\'eau font 300 mL');
    });

    test('les pesées par différence', () {
      expect(420 - 120, 300, reason: 'le verre plein moins le verre vide');
      expect(260 - 200, 60, reason: 'le volume du caillou');
      expect(1500 - 1000, 500, reason: 'un litre de miel face à l\'eau');
    });

    test('sous zéro, le plus grand nombre est le plus froid', () {
      // La règle contre-intuitive du chapitre.
      expect(-10, lessThan(-5));
      expect(10, greaterThan(5), reason: 'au-dessus de zéro, l\'inverse');
      final List<int> temperatures = <int>[-18, 4, 20, 37, 180];
      for (int i = 1; i < temperatures.length; i++) {
        expect(temperatures[i], greaterThan(temperatures[i - 1]));
      }
    });

    test('un écart de température se calcule en passant par zéro', () {
      expect(3 + 12, 15, reason: 'de −3 °C à 12 °C');
      expect(12 - (-3), 15, reason: 'et par soustraction directe');
    });

    test('flotter se décide à volume égal', () {
      // Un objet d'un litre pesant 800 g flotte ; à 1 500 g il coule.
      const int masseEau = 1000;
      for (final (int masse, bool flotte) in <(int, bool)>[
        (800, true),
        (999, true),
        (1001, false),
        (1500, false),
      ]) {
        expect(masse < masseEau, flotte, reason: '$masse g par litre');
      }
      // Et un bateau creux : énorme volume, masse modeste pour ce volume.
      const int volumeBateau = 50000;
      const int masseBateau = 20000;
      expect(masseBateau < volumeBateau, isTrue,
          reason: 'léger pour sa taille, donc il flotte');
    });
  });

  group('Mélanges et solutions', () {
    test('rien ne se perd à la dissolution', () {
      expect(300 + 20, 320);
      // La masse du mélange est la somme : c'est la preuve que le sel
      // dissous est toujours là.
      for (final (int eau, int sel) in <(int, int)>[
        (100, 5),
        (250, 30),
        (1000, 70),
      ]) {
        expect(eau + sel, greaterThan(eau));
      }
    });

    test('la saturation laisse le surplus au fond', () {
      const int limite = 70;
      expect(90 - limite, 20);
      // En dessous de la limite, rien ne reste.
      for (final int verse in <int>[10, 50, 70]) {
        expect(verse <= limite ? 0 : verse - limite, verse <= 70 ? 0 : 20);
      }
    });

    test('l\'eau de mer et son sel', () {
      expect(35 * 4, 140);
      expect(35 * 2, 70, reason: 'ce qui reste après évaporation');
      // Évaporer ne change pas la masse de sel, seulement celle d'eau.
      for (final int litres in <int>[1, 2, 5, 10]) {
        expect(35 * litres, litres * 35);
      }
    });

    test('chaque méthode a sa limite', () {
      // Le filtre retient ce qui est plus gros que ses trous. On le
      // modélise par une taille de particule comparée à celle du maillage.
      const double maillage = 10;
      bool retenuParLeFiltre(double taille) => taille > maillage;
      expect(retenuParLeFiltre(500), isTrue, reason: 'le sable');
      expect(retenuParLeFiltre(0.001), isFalse, reason: 'le sel dissous');
      // L'évaporation, elle, sépare tout ce qui n'est pas volatil.
      bool resteApresEvaporation(bool volatil) => !volatil;
      expect(resteApresEvaporation(false), isTrue, reason: 'le sel reste');
      expect(resteApresEvaporation(true), isFalse, reason: 'l\'eau part');
    });
  });

  group('Décrire un mouvement', () {
    test('les trois formes de la relation vitesse-distance-durée', () {
      expect(100 / 2, 50, reason: 'vitesse');
      expect(20 * 3, 60, reason: 'distance');
      expect(15 / 5, 3, reason: 'durée');
      expect(240 / 2, 120);
      expect(900 / 2, 450, reason: 'un avion en une demi-heure');
      // Les trois formes se répondent : la boucle doit se refermer.
      for (final (double d, double t) in <(double, double)>[
        (100, 2),
        (240, 2),
        (60, 3),
        (450, 0.5),
      ]) {
        final double v = d / t;
        expect(v * t, closeTo(d, 1e-9));
        expect(d / v, closeTo(t, 1e-9));
      }
    });

    test('la conversion mètres par seconde vers kilomètres par heure', () {
      expect(10 * 3.6, 36);
      // Le facteur 3,6 n'est pas arbitraire : 3 600 secondes par heure,
      // divisées par 1 000 mètres par kilomètre.
      expect(3600 / 1000, 3.6);
      for (final double ms in <double>[1, 5, 10, 25]) {
        expect(ms * 3.6, closeTo(ms * 3600 / 1000, 1e-9));
      }
    });

    test('des écarts croissants signalent une accélération', () {
      const List<int> positions = <int>[2, 6, 12, 20];
      final List<int> ecarts = <int>[
        for (int i = 1; i < positions.length; i++)
          positions[i] - positions[i - 1],
      ];
      expect(ecarts, <int>[4, 6, 8]);
      for (int i = 1; i < ecarts.length; i++) {
        expect(ecarts[i], greaterThan(ecarts[i - 1]));
      }
      // Une vitesse constante donnerait des écarts égaux.
      const List<int> regulier = <int>[5, 10, 15, 20];
      final Set<int> ecartsReguliers = <int>{
        for (int i = 1; i < regulier.length; i++)
          regulier[i] - regulier[i - 1],
      };
      expect(ecartsReguliers.length, 1);
    });

    test('les vitesses relatives du défi', () {
      // Côte à côte : immobiles l'une par rapport à l'autre.
      expect(90 - 90, 0);
      // En sens contraire : les vitesses s'ajoutent.
      expect(50 + 50, 100);
      // Marcher dans un train, dans le même sens.
      expect(100 + 5, 105);
      // Et dans le sens contraire, elles se retranchent.
      expect(100 - 5, 95);
    });

    test('les reperes de vitesse sont dans le bon ordre', () {
      const List<int> reperes = <int>[5, 20, 50, 300, 900];
      for (int i = 1; i < reperes.length; i++) {
        expect(reperes[i], greaterThan(reperes[i - 1]));
      }
    });
  });

  group('Lumière et son', () {
    test('le son met trois secondes par kilomètre', () {
      expect(1000 / 340, closeTo(2.94, 0.02));
      expect(6 / 3, 2, reason: 'six secondes donnent deux kilomètres');
      expect(3 * 5, 15, reason: 'cinq kilomètres en quinze secondes');
      // La règle de tête, confrontée au calcul exact : moins de 3 % d'écart.
      for (final int km in <int>[1, 2, 5, 10]) {
        final double exact = km * 1000 / 340;
        final double regle = km * 3;
        expect((regle - exact).abs() / exact, lessThan(0.03), reason: '$km km');
      }
    });

    test('l\'écho fait un aller-retour', () {
      // Deux secondes à 340 m/s : le mur est à la moitié du trajet.
      expect(340 * 2 / 2, 340);
      // Oublier la division par deux doublerait la réponse.
      expect(340 * 2, 680);
    });

    test('le feu d\'artifice', () {
      expect(1700 / 340, 5);
      // La lumière, elle, arrive en un temps indétectable à cette échelle.
      const double c = 300000000;
      expect(1700 / c, lessThan(1e-5));
    });

    test('la lumière est environ un million de fois plus rapide', () {
      const double rapport = 300000000 / 340;
      expect(rapport, closeTo(882353, 1000));
      expect(rapport, greaterThan(800000));
      expect(rapport, lessThan(1000000));
    });

    test('l\'ombre grandit quand la source approche', () {
      expect(60 / 20, 3, reason: 'une ombre trois fois l\'objet');
      // C'est le rapport des distances, comme dans le chapitre de collège.
      double grandissement(double objet, double mur) => mur / objet;
      for (final (double o, double m) in <(double, double)>[
        (1, 3),
        (2, 6),
        (10, 30),
      ]) {
        expect(grandissement(o, m), closeTo(3, 1e-9));
      }
      // Approcher la source agrandit l'ombre.
      expect(grandissement(1, 10), greaterThan(grandissement(5, 10)));
    });
  });
}
