import 'dart:math' as math;

import 'package:eureka/design_system/figures/eclipse_figure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les nombres du ciel sont recalculés, pas recopiés.
///
/// Un chapitre d'astronomie vit de coïncidences numériques — le Soleil
/// 400 fois plus large et 400 fois plus loin, les deux tailles apparentes
/// presque égales — et ces coïncidences sont exactement le genre de chose
/// qu'on retient de travers. Ici elles sont refaites à partir des diamètres
/// et des distances, pas affirmées.
///
/// La classification des alignements est vérifiée sur la grille complète
/// des positions, et surtout sur la propriété que le cours en tire : une
/// éclipse de Soleil n'arrive qu'à la nouvelle lune, une éclipse de Lune
/// qu'à la pleine lune.
void main() {
  // Valeurs de référence, en kilomètres.
  const double diametreSoleil = 1392000;
  const double distanceSoleil = 150000000;
  const double diametreLune = 3475;
  const double distanceLune = 384400;

  group('La coïncidence des tailles apparentes', () {
    test('le Soleil est environ 400 fois plus large que la Lune', () {
      const double rapport = diametreSoleil / diametreLune;
      expect(rapport, closeTo(400, 5));
    });

    test('et environ 400 fois plus loin', () {
      const double rapport = distanceSoleil / distanceLune;
      expect(rapport, closeTo(390, 10));
    });

    test('les deux rapports diamètre sur distance sont presque égaux', () {
      const double rs = diametreSoleil / distanceSoleil;
      const double rl = diametreLune / distanceLune;
      // Les valeurs que l'entraînement fait calculer, en millièmes.
      expect(rs * 1000, closeTo(9.3, 0.1));
      expect(rl * 1000, closeTo(9.0, 0.1));
      // « À 3 % près », dit le cours. On le vérifie au lieu de l'annoncer.
      expect((rs - rl).abs() / rs * 100, closeTo(2.6, 0.3));
      expect((rs - rl).abs() / rs, lessThan(0.03));
    });

    test('les deux font bien un demi-degré dans le ciel', () {
      double apparent(double d, double dist) =>
          2 * math.atan(d / 2 / dist) * 180 / math.pi;
      expect(apparent(diametreSoleil, distanceSoleil), closeTo(0.53, 0.01));
      expect(apparent(diametreLune, distanceLune), closeTo(0.52, 0.01));
    });

    test('le Soleil paraît un peu plus grand : d\'où les annulaires', () {
      // L'explication de la carte « et les éclipses annulaires ». À la
      // distance moyenne la Lune est déjà légèrement la plus petite, donc
      // à l'apogée elle ne couvre plus le Soleil.
      const double rs = diametreSoleil / distanceSoleil;
      const double rl = diametreLune / distanceLune;
      expect(rl, lessThan(rs));
      // À l'apogée, 405 500 km, l'écart se creuse.
      expect(diametreLune / 405500, lessThan(rl));
    });
  });

  group('Le rythme des marées', () {
    test('le cycle de 24 h 50 donne bien 12 h 25 et 6 h 12', () {
      const int cycleMinutes = 24 * 60 + 50;
      expect(cycleMinutes, 1490);
      // Entre deux pleines mers : la moitié du cycle. C'est la réponse de
      // la question q5.
      expect(cycleMinutes / 2, 745);
      expect((cycleMinutes / 2 / 60).floor(), 12);
      expect((cycleMinutes / 2) % 60, 25);
      // Entre une pleine mer et la basse mer suivante : le quart.
      expect(cycleMinutes / 4, closeTo(372.5, 0.01));
      expect((cycleMinutes / 4 / 60).floor(), 6);
      // 372,5 minutes font 6 h 12 min 30 s exactement. Le cours écrit
      // « 6 h 12 », qui est la valeur tronquée et la forme usuelle ; la
      // demi-minute est au-delà de ce que l'énoncé prétend.
      expect((cycleMinutes / 4) % 60, closeTo(12.5, 0.01));
      expect((((cycleMinutes / 4) % 60)).floor(), 12);
    });

    test('deux bosses donnent deux marées par tour', () {
      // L'argument du cours : la Terre tourne sous deux bosses opposées,
      // donc chaque point en traverse deux par rotation. On le compte.
      const List<double> bosses = <double>[0, 180];
      int traversees = 0;
      for (int angle = 0; angle < 360; angle++) {
        for (final double bosse in bosses) {
          if (angle == bosse) traversees++;
        }
      }
      expect(traversees, 2);
    });
  });

  group('La Lune s\'éloigne', () {
    const double cmParAn = 3.8;

    test('2,17 mètres depuis Apollo 11', () {
      // 1969 à 2026 : 57 ans.
      expect(cmParAn * 57 / 100, closeTo(2.17, 0.01));
    });

    test('un milliard d\'années pour 38 000 km', () {
      const double cibleCm = 38000 * 100000;
      expect(cibleCm, 3.8e9);
      expect(cibleCm / cmParAn / 1e6, closeTo(1000, 0.1));
    });

    test('l\'ombre file 85 km en trois minutes à 1 700 km/h', () {
      expect(1700 * 3 / 60, closeTo(85, 0.01));
    });
  });

  group('La classification des alignements', () {
    test('dans le plan, le Soleil s\'éclipse en nouvelle lune', () {
      expect(EclipseFigure.classer(0, 0), TypeEclipse.soleil);
      expect(EclipseFigure.classer(360, 0), TypeEclipse.soleil);
      expect(EclipseFigure.classer(-5, 0), TypeEclipse.soleil);
      expect(EclipseFigure.phase(0), 'nouvelle lune');
    });

    test('et la Lune s\'éclipse en pleine lune', () {
      expect(EclipseFigure.classer(180, 0), TypeEclipse.lune);
      expect(EclipseFigure.phase(180), 'pleine lune');
    });

    test('aux quartiers, aucune éclipse n\'est possible', () {
      for (final double l in <double>[90, 270]) {
        for (double lat = -EclipseFigure.inclinaison;
            lat <= EclipseFigure.inclinaison;
            lat += 0.5) {
          expect(EclipseFigure.classer(l, lat), TypeEclipse.aucune);
        }
      }
      expect(EclipseFigure.phase(90), 'premier quartier');
      expect(EclipseFigure.phase(270), 'dernier quartier');
    });

    test('hors du plan, l\'alignement ne suffit pas', () {
      // Le cœur du chapitre : aligné mais trop haut, donc rien.
      for (final double l in <double>[0, 180, 360]) {
        expect(EclipseFigure.classer(l, 5), TypeEclipse.manquee);
        expect(EclipseFigure.classer(l, -5), TypeEclipse.manquee);
        expect(EclipseFigure.classer(l, 2), TypeEclipse.manquee);
      }
    });

    test('une éclipse n\'arrive jamais hors nouvelle ou pleine lune', () {
      // La propriété que le cours affirme, balayée sur toute la grille.
      // Si la classification laissait passer une éclipse au premier
      // quartier, le chapitre et la figure se contrediraient.
      for (int l = 0; l < 360; l++) {
        for (double lat = -5; lat <= 5; lat += 0.25) {
          final TypeEclipse t = EclipseFigure.classer(l.toDouble(), lat);
          if (t != TypeEclipse.soleil && t != TypeEclipse.lune) continue;
          final String phase = EclipseFigure.phase(l.toDouble());
          expect(
            phase,
            anyOf(<String>['nouvelle lune', 'pleine lune']),
            reason: 'éclipse annoncée à $l° (phase $phase)',
          );
          // Et le type doit correspondre à la phase, pas l'inverse.
          expect(
            t == TypeEclipse.soleil,
            phase == 'nouvelle lune',
            reason: 'type $t incohérent avec la phase $phase à $l°',
          );
        }
      }
    });

    test('les éclipses restent rares sur la grille complète', () {
      // Le constat du cours : il faut un alignement presque parfait. On
      // mesure la proportion des configurations qui donnent une éclipse ;
      // si la figure en rendait la moitié, elle enseignerait le contraire.
      int eclipses = 0;
      int total = 0;
      for (int l = 0; l < 360; l++) {
        for (double lat = -5; lat <= 5; lat += 0.25) {
          total++;
          final TypeEclipse t = EclipseFigure.classer(l.toDouble(), lat);
          if (t == TypeEclipse.soleil || t == TypeEclipse.lune) eclipses++;
        }
      }
      final double proportion = eclipses / total;
      expect(proportion, lessThan(0.08));
      expect(proportion, greaterThan(0.0),
          reason: 'elles doivent tout de même être possibles');
    });

    test('la longitude se normalise, les tours ne changent rien', () {
      for (int tour = -3; tour <= 3; tour++) {
        expect(
          EclipseFigure.classer(180 + 360 * tour.toDouble(), 0),
          TypeEclipse.lune,
        );
        expect(EclipseFigure.phase(360 * tour.toDouble()), 'nouvelle lune');
      }
    });

    test('l\'inclinaison annoncée est celle du réel', () {
      // Le cours dit « environ 5 degrés ». La valeur mesurée est 5,145°.
      expect(EclipseFigure.inclinaison, closeTo(5.1, 0.1));
      expect(EclipseFigure.inclinaison.round(), 5);
    });
  });
}
