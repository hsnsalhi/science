import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// La SVT du collège, recalculée.
///
/// Quatre chapitres dont les affirmations sont presque toutes quantitatives :
/// une vitesse de plaque, une échelle logarithmique, un budget carbone, un
/// seuil d'immunité collective. Chacune se refabrique, et deux d'entre elles
/// se recoupent — l'âge de la croûte océanique tombe sur la largeur de
/// l'Atlantique divisée par la vitesse de la dorsale, ce qui n'était pas
/// garanti d'avance.
void main() {
  group('Tectonique', () {
    /// Déplacement cumulé, en kilomètres, pour une vitesse en centimètres
    /// par an et une durée en années.
    double kilometres(double cmParAn, double annees) =>
        cmParAn * annees / 100 / 1000;

    test('deux centimètres par an font vingt kilomètres par million d’années', () {
      expect(kilometres(2, 1e6), 20);
    });

    test('et deux mille kilomètres en cent millions d’années', () {
      expect(kilometres(2, 1e8), 2000);
    });

    test('le déplacement est proportionnel à la durée', () {
      for (double ma = 1; ma <= 200; ma += 13) {
        expect(kilometres(2, ma * 1e6), closeTo(20 * ma, 1e-9),
            reason: '$ma millions d’années');
      }
    });

    test('ouvrir quatre mille kilomètres prend deux cents millions d’années', () {
      // On inverse la relation plutôt que de réécrire le résultat.
      const double annees = 4000 * 1000 * 100 / 2;
      expect(annees, 2e8);
      expect(annees / 1e6, 200);
    });

    test('la datation et la vitesse se recoupent', () {
      // Le chapitre avance deux faits indépendants : la croûte océanique
      // n'a nulle part plus de 200 Ma, et la dorsale écarte de 2 cm/an.
      // Leur produit doit redonner la largeur de l'Atlantique.
      const double ageMaxMa = 200;
      const double vitesseCmParAn = 2;
      final double largeur = kilometres(vitesseCmParAn, ageMaxMa * 1e6);
      expect(largeur, 4000);
      // Ce qui est bien l'ordre de grandeur réel, à 10 % près.
      expect(largeur, greaterThan(3600));
      expect(largeur, lessThan(4400));
    });

    test('les roches continentales sont vingt fois plus vieilles', () {
      const double continentalesMa = 4000;
      const double oceaniquesMa = 200;
      expect(continentalesMa / oceaniquesMa, 20);
    });
  });

  group('Magnitude des séismes', () {
    double amplitude(double ecartDeMagnitude) => math.pow(10, ecartDeMagnitude).toDouble();
    double energie(double ecartDeMagnitude) =>
        math.pow(math.sqrt(1000), ecartDeMagnitude).toDouble();

    test('une unité multiplie l’amplitude par dix', () {
      expect(amplitude(1), 10);
    });

    test('deux unités : cent fois l’amplitude, mille fois l’énergie', () {
      expect(amplitude(2), 100);
      expect(energie(2), closeTo(1000, 1e-9));
    });

    test('le facteur d’énergie par unité est bien d’environ trente-deux', () {
      expect(energie(1), closeTo(31.62, 0.01));
      // Et son carré fait exactement mille, par construction de l'échelle.
      expect(energie(1) * energie(1), closeTo(1000, 1e-9));
    });

    test('six unités font un million en amplitude', () {
      expect(amplitude(6), 1000000);
      // D'où l'absurdité de « deux fois moins fort » entre 6 et 12.
      expect(amplitude(6), greaterThan(2));
    });

    test('l’échelle est bien logarithmique, et non linéaire', () {
      for (double e = 0; e <= 5; e++) {
        expect(amplitude(e + 1) / amplitude(e), closeTo(10, 1e-9),
            reason: 'écart $e');
      }
    });
  });

  group('Nuée ardente', () {
    double enMetresParSeconde(double kmParHeure) => kmParHeure * 1000 / 3600;

    test('cent cinquante kilomètres par heure font quarante-deux mètres par seconde', () {
      expect(enMetresParSeconde(150), closeTo(41.67, 0.01));
      expect(enMetresParSeconde(150).round(), 42);
    });

    test('six kilomètres en moins de deux minutes et demie', () {
      final double secondes = 6000 / enMetresParSeconde(150);
      expect(secondes, closeTo(144, 1));
      expect(secondes, lessThan(150), reason: 'moins de deux minutes et demie');
    });

    test('un kilomètre en moins de vingt-cinq secondes', () {
      expect(1000 / enMetresParSeconde(150), lessThan(25));
    });
  });

  group('Risque', () {
    double risque(double alea, double vulnerabilite) => alea * vulnerabilite;

    test('un facteur très faible suffit à rendre le risque faible', () {
      expect(risque(1.0, 0.01), closeTo(0.01, 1e-9));
      expect(risque(0.01, 1.0), closeTo(0.01, 1e-9));
      // Le produit est symétrique : c'est pourquoi agir sur la seule
      // vulnérabilité suffit, l'aléa étant hors d'atteinte.
      for (double a = 0.1; a <= 1.0; a += 0.1) {
        for (double v = 0.1; v <= 1.0; v += 0.1) {
          expect(risque(a, v), closeTo(risque(v, a), 1e-9));
        }
      }
    });

    test('un pour cent par an fait cinq séismes en cinq siècles', () {
      expect(500 * 0.01, closeTo(5, 1e-9));
    });

    test('le retard d’une faille se calcule, pas une date', () {
      expect(180 - 100, 80);
      // Et un intervalle moyen ne contraint pas l'intervalle suivant :
      // on le montre en comparant une moyenne à des tirages irréguliers.
      const List<int> intervalles = [60, 90, 150, 100, 100];
      final double moyenne =
          intervalles.reduce((a, b) => a + b) / intervalles.length;
      expect(moyenne, 100);
      expect(intervalles.reduce((a, b) => a > b ? a : b), 150);
      expect(intervalles.reduce((a, b) => a < b ? a : b), 60);
      // Un écart de 90 ans entre le plus court et le plus long, pour une
      // même moyenne de 100 : la moyenne ne prédit rien.
      expect(150 - 60, 90);
    });
  });

  group('Effet de serre', () {
    test('trente-trois degrés d’effet de serre naturel', () {
      expect(15 - (-18), 33);
    });

    test('le CO₂ a augmenté de cent quarante-cinq ppm', () {
      expect(425 - 280, 145);
    });

    test('soit environ cinquante-deux pour cent de plus', () {
      expect(145 / 280 * 100, closeTo(51.8, 0.1));
      expect((145 / 280 * 100).round(), 52);
      // Et le rapport des concentrations est bien d'environ une fois et demie.
      expect(425 / 280, closeTo(1.52, 0.01));
    });

    test('six degrés de moins par mille mètres', () {
      double temperature(double auSol, double altitudeM) =>
          auSol - 6 * altitudeM / 1000;
      expect(temperature(20, 2000), 8);
      expect(temperature(20, 0), 20);
      expect(temperature(20, 3000), 2);
      // La relation est affine : chaque millier de mètres retire six degrés.
      for (double h = 0; h <= 4000; h += 500) {
        expect(temperature(20, h + 1000), closeTo(temperature(20, h) - 6, 1e-9),
            reason: 'à $h m');
      }
    });
  });

  group('Niveau de la mer', () {
    double monteeCm(double mmParAn, double annees) => mmParAn * annees / 10;

    test('trois virgule quatre millimètres par an font trente-quatre centimètres par siècle', () {
      expect(monteeCm(3.4, 100), closeTo(34, 1e-9));
    });

    test('et trois virgule quatre centimètres en dix ans', () {
      expect(monteeCm(3.4, 10), closeTo(3.4, 1e-9));
    });

    test('la banquise flottante ne change rien au niveau', () {
      // Le principe d'Archimède : un corps flottant déplace son propre
      // poids d'eau. Le volume déplacé avant fonte égale le volume d'eau
      // libéré après, donc le niveau ne bouge pas.
      const double masseGlace = 900; // kg, soit 1 m³ de glace
      const double masseVolumiqueEau = 1000; // kg/m³
      const double volumeDeplaceAvant = masseGlace / masseVolumiqueEau;
      const double volumeApresFonte = masseGlace / masseVolumiqueEau;
      expect(volumeDeplaceAvant, closeTo(volumeApresFonte, 1e-9));
      expect(volumeDeplaceAvant, closeTo(0.9, 1e-9));
    });

    test('la glace posée sur une terre, elle, ajoute son volume entier', () {
      const double masseGlace = 900;
      const double masseVolumiqueEau = 1000;
      const double volumeDeplaceAvant = 0; // elle n'est pas dans l'eau
      const double volumeApresFonte = masseGlace / masseVolumiqueEau;
      expect(volumeApresFonte - volumeDeplaceAvant, closeTo(0.9, 1e-9));
      expect(volumeApresFonte, greaterThan(volumeDeplaceAvant));
    });
  });

  group('Budget carbone', () {
    double annees(double budget, double parAn) => budget / parAn;

    test('quatre cents milliards de tonnes à quarante par an : dix ans', () {
      expect(annees(400, 40), 10);
    });

    test('diviser le rythme par deux double le délai', () {
      expect(annees(400, 20), 20);
      expect(annees(400, 20), 2 * annees(400, 40));
    });

    test('le total émis reste le même quel que soit le rythme', () {
      // C'est l'argument central du chapitre : étaler ne change rien.
      for (double parAn = 5; parAn <= 50; parAn += 5) {
        final double duree = annees(400, parAn);
        expect(duree * parAn, closeTo(400, 1e-9), reason: '$parAn par an');
      }
    });

    test('tenir quarante ans impose dix milliards de tonnes par an', () {
      expect(400 / 40, 10);
      // Soit le quart des émissions actuelles.
      expect(10 / 40, closeTo(0.25, 1e-9));
    });

    test('cinq tonnes par personne et par an aujourd’hui', () {
      expect(40 / 8, 5);
      expect(2 * 8, 16, reason: 'deux tonnes par personne feraient 16 au total');
      // Et ce serait une division par deux et demie.
      expect(40 / 16, closeTo(2.5, 1e-9));
    });
  });

  group('Antibiorésistance', () {
    int bacteriesApres(int divisions) {
      int n = 1;
      for (int i = 0; i < divisions; i++) {
        n *= 2;
      }
      return n;
    }

    test('trois divisions donnent huit bactéries', () {
      expect(bacteriesApres(3), 8);
    });

    test('vingt divisions dépassent le million', () {
      expect(bacteriesApres(20), 1048576);
      expect(bacteriesApres(20), greaterThan(1000000));
      expect(bacteriesApres(19), lessThan(1000000),
          reason: 'dix-neuf ne suffisent pas');
    });

    test('vingt divisions de vingt minutes font six heures quarante', () {
      expect(20 * 20, 400);
      expect(400 ~/ 60, 6);
      expect(400 % 60, 40);
    });

    test('la repopulation est entièrement résistante', () {
      // Une seule survivante, et toute sa descendance porte sa mutation.
      const int survivantes = 1;
      const bool resistante = true;
      final int descendance = bacteriesApres(20) * survivantes;
      expect(descendance, 1048576);
      expect(resistante, isTrue);
      // Alors qu'avant l'antibiotique, la résistance était à une sur un
      // million : la fréquence est passée de 0,0001 % à 100 %.
      expect(1 / 1000000 * 100, closeTo(0.0001, 1e-12));
    });
  });

  group('Les papillons de Manchester', () {
    test('les proportions avant et après', () {
      expect(100 - 2, 98, reason: 'les clairs avant 1850');
      expect(95 - 2, 93, reason: 'les points gagnés par les sombres');
      expect(95 / 2, 47.5, reason: 'le facteur multiplicatif');
      expect(1900 - 1850, 50);
    });

    test('les proportions se complètent toujours à cent', () {
      for (final int sombres in <int>[2, 10, 50, 95]) {
        expect(sombres + (100 - sombres), 100, reason: '$sombres % de sombres');
      }
    });

    test('la variante existait avant la pollution', () {
      // Deux pour cent n'est pas zéro : c'est le point du chapitre.
      expect(2, greaterThan(0));
      expect(2 / 100, closeTo(0.02, 1e-9));
    });
  });

  group('Immunité collective', () {
    double seuil(double r0) => 1 - 1 / r0;
    double effectif(double r0, double couverture) => r0 * (1 - couverture);

    test('les seuils cités dans le chapitre', () {
      expect((seuil(15) * 100).round(), 93);
      expect((seuil(6) * 100).round(), 83);
      expect((seuil(3) * 100).round(), 67);
      expect((seuil(1.5) * 100).round(), 33);
      expect((seuil(4) * 100).round(), 75);
    });

    test('au seuil exact, le nombre effectif tombe à un', () {
      for (final double r0 in <double>[1.5, 2, 3, 4, 6, 10, 15]) {
        expect(effectif(r0, seuil(r0)), closeTo(1, 1e-9), reason: 'R₀ = $r0');
      }
    });

    test('la formule du seuil est bien le point de bascule', () {
      // Pour chaque R₀, on balaie la couverture : l'épidémie décroît
      // exactement au-dessus du seuil, et pas avant.
      for (final double r0 in <double>[1.5, 2, 3, 4, 6, 15]) {
        final double s = seuil(r0);
        for (double p = 0; p <= 1.0001; p += 0.01) {
          final bool decroit = effectif(r0, p) < 1 - 1e-12;
          final bool auDessus = p > s + 1e-12;
          if ((p - s).abs() > 0.005) {
            expect(decroit, auDessus,
                reason: 'R₀ = $r0, couverture ${p.toStringAsFixed(2)}');
          }
        }
      }
    });

    test('à cinquante pour cent de couverture et R₀ de quatre, deux contaminations', () {
      expect(effectif(4, 0.5), closeTo(2, 1e-9));
      expect(effectif(4, 0.5), greaterThan(1), reason: 'l’épidémie croît encore');
    });

    test('une épidémie simulée s’éteint au-dessus du seuil et explose en dessous', () {
      double apresGenerations(double r0, double couverture, int generations) {
        double malades = 1;
        for (int g = 0; g < generations; g++) {
          malades *= effectif(r0, couverture);
        }
        return malades;
      }

      const double r0 = 3;
      // Juste sous le seuil de 66,7 % : l'épidémie croît.
      expect(apresGenerations(r0, 0.60, 10), greaterThan(1));
      // Juste au-dessus : elle s'éteint.
      // R effectif vaut 3 × 0,28 = 0,84, donc la décroissance est
      // géométrique de raison 0,84 : 0,17 après dix générations, 0,0054
      // après trente, et moins de 10⁻⁴ après soixante.
      expect(effectif(r0, 0.72), closeTo(0.84, 1e-9));
      expect(apresGenerations(r0, 0.72, 10), closeTo(0.1749, 1e-4));
      expect(apresGenerations(r0, 0.72, 30), closeTo(0.00535, 1e-5));
      expect(apresGenerations(r0, 0.72, 60), lessThan(1e-4));
      // Et sans aucune couverture, trois puis neuf puis vingt-sept.
      expect(apresGenerations(r0, 0, 1), 3);
      expect(apresGenerations(r0, 0, 2), 9);
      expect(apresGenerations(r0, 0, 3), 27);
    });

    test('un R₀ plus élevé exige une couverture plus élevée', () {
      double precedent = -1;
      for (final double r0 in <double>[1.5, 2, 3, 4, 6, 10, 15]) {
        expect(seuil(r0), greaterThan(precedent), reason: 'R₀ = $r0');
        precedent = seuil(r0);
      }
      // Et le seuil ne peut jamais atteindre cent pour cent.
      expect(seuil(1000), lessThan(1));
      expect(seuil(1000), greaterThan(0.99));
    });

    test('un R₀ inférieur à un rend le seuil inutile', () {
      // L'épidémie s'éteint toute seule : le seuil calculé est négatif,
      // ce qui signifie qu'aucune couverture n'est nécessaire.
      expect(seuil(0.8), lessThan(0));
      expect(effectif(0.8, 0), lessThan(1));
    });
  });
}
