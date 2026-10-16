import 'package:eureka/design_system/figures/shadow_figure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les nombres du chapitre sont refaits, et l'ombre doit obéir à Thalès.
///
/// Une figure d'optique peut être fausse sans que cela se voie : une ombre
/// un peu trop grande reste une ombre plausible. Or ici la géométrie est
/// exactement celle du chapitre de maths sur Thalès, et les deux chapitres
/// se contrediraient si la figure s'en écartait. Ces tests confrontent donc
/// le grandissement de la figure au rapport des distances, et refont les
/// trajets de lumière et de son que le texte annonce.
void main() {
  const double c = 300000; // km/s, dans le vide
  const double son = 340; // m/s, dans l'air

  group('L\'ombre obéit à Thalès', () {
    test('le grandissement est le rapport des distances', () {
      for (double objet = 10; objet <= 200; objet += 7) {
        for (double mur = objet; mur <= 400; mur += 11) {
          expect(
            ShadowFigure.grandissement(
              distanceObjet: objet,
              distanceMur: mur,
            ),
            closeTo(mur / objet, 1e-9),
            reason: 'objet à $objet, mur à $mur',
          );
        }
      }
    });

    test('et la hauteur de l\'ombre suit', () {
      for (double h = 1; h <= 50; h += 3) {
        expect(
          ShadowFigure.hauteurOmbre(
            hauteurObjet: h,
            distanceObjet: 40,
            distanceMur: 160,
          ),
          closeTo(h * 4, 1e-9),
        );
      }
    });

    test('approcher la lampe agrandit l\'ombre', () {
      // L'explication de la question q4 du cours. On la vérifie sur toute
      // la course du curseur plutôt que sur deux positions choisies.
      const double positionObjet = 100;
      const double positionMur = 160;
      double precedent = 0;
      for (double recul = 1; recul >= 0; recul -= 0.02) {
        final double lampe = positionObjet - (12 + recul * 78);
        final double g = ShadowFigure.grandissement(
          distanceObjet: positionObjet - lampe,
          distanceMur: positionMur - lampe,
        );
        expect(g, greaterThan(precedent), reason: 'recul $recul');
        precedent = g;
      }
    });

    test('l\'ombre est toujours plus grande que l\'objet', () {
      // Tant que le mur est derrière l'objet, le rapport dépasse 1.
      for (double objet = 5; objet <= 150; objet += 5) {
        for (double mur = objet + 1; mur <= 300; mur += 13) {
          expect(
            ShadowFigure.grandissement(
              distanceObjet: objet,
              distanceMur: mur,
            ),
            greaterThan(1),
          );
        }
      }
    });

    test('une lampe sur l\'objet donne une ombre infinie', () {
      // Cas limite : la figure ne doit pas rendre un nombre absurde mais
      // l'infini, qui est la réponse juste.
      expect(
        ShadowFigure.grandissement(distanceObjet: 0, distanceMur: 100),
        double.infinity,
      );
      expect(
        ShadowFigure.hauteurOmbre(
          hauteurObjet: 10,
          distanceObjet: 0,
          distanceMur: 100,
        ),
        double.infinity,
      );
    });
  });

  group('Les temps de trajet de la lumière', () {
    test('du Soleil : 8 minutes et 20 secondes', () {
      const double distance = 150000000; // km
      expect(distance / c, closeTo(500, 1));
      expect(distance / c / 60, closeTo(8.33, 0.05));
    });

    test('de la Lune : 1,3 seconde', () {
      expect(384000 / c, closeTo(1.28, 0.01));
      // La réponse attendue, arrondie au dixième.
      expect((384000 / c * 10).round() / 10, closeTo(1.3, 0.001));
    });

    test('la lumière fait dix-huit millions de kilomètres par minute', () {
      expect(c * 60, 18000000);
    });

    test('une année-lumière vaut environ 9 500 milliards de kilomètres', () {
      const double km = c * 365.25 * 24 * 3600;
      expect(km / 1e9, closeTo(9467, 5));
      // « Environ 9 500 » : l'écart reste sous 1 %.
      expect((km / 1e9 - 9500).abs() / 9500, lessThan(0.01));
    });

    test('et sept fois et demie le tour de la Terre par seconde', () {
      const double circonference = 40075; // km
      expect(c / circonference, closeTo(7.49, 0.05));
    });
  });

  group('Le son, et son retard', () {
    test('trois secondes par kilomètre', () {
      expect(1000 / son, closeTo(2.94, 0.02));
      // L'approximation du cours, « divise par trois », tombe juste à
      // 2 % près — ce qui est largement assez pour un orage.
      expect((1000 / son - 3).abs() / 3, lessThan(0.03));
    });

    test('neuf secondes donnent trois kilomètres', () {
      expect(9 * son, closeTo(3060, 1));
      expect(9 / 3, 3, reason: 'la règle de tête du cours');
      // L'écart entre la règle et le calcul exact reste sous 100 mètres.
      expect((9 * son - 3000).abs(), lessThan(100));
    });

    test('la lumière est près d\'un million de fois plus rapide', () {
      const double rapport = c * 1000 / son;
      expect(rapport, closeTo(882353, 1000));
      expect(rapport, greaterThan(800000));
      expect(rapport, lessThan(1000000));
    });

    test('le sonar : quatre secondes donnent trois mille mètres', () {
      // L'aller-retour, que la question demande de ne pas oublier.
      const double vitesseEau = 1500;
      expect(vitesseEau * 4 / 2, 3000);
      // Oublier la division par deux doublerait la réponse.
      expect(vitesseEau * 4, 6000);
    });
  });

  group('La fibre optique', () {
    test('la lumière y va moins vite que dans le vide', () {
      const double dansLaFibre = 200000;
      expect(dansLaFibre, lessThan(c));
      expect(dansLaFibre / c, closeTo(0.667, 0.005));
    });

    test('soixante millisecondes font douze mille kilomètres', () {
      expect(200000 * 0.06, 12000);
      // Soit six mille dans chaque sens : l'ordre de grandeur d'une
      // traversée de l'Atlantique, ce que le chapitre affirme.
      expect(200000 * 0.06 / 2, 6000);
      expect(200000 * 0.06 / 2, greaterThan(5000));
      expect(200000 * 0.06 / 2, lessThan(7000));
    });
  });
}
