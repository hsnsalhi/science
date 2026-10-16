import 'dart:math' as math;

import 'package:eureka/design_system/figures/newton_cannon_figure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les deux vitesses cosmiques sont recalculées, pas recopiées.
///
/// Une figure qui place le seuil de satellisation au mauvais endroit
/// enseigne une erreur que personne ne vérifiera jamais à l'œil : la courbe
/// aura l'air juste dans les deux cas. Ces tests repartent donc de la masse
/// et du rayon de la Terre, et confrontent le résultat aux seuils que la
/// figure utilise.
///
/// La forme de la trajectoire est vérifiée aussi, parce qu'elle porte le
/// cœur du chapitre : trop lente, l'ellipse recoupe la Terre et le boulet
/// retombe ; assez rapide, elle ne la recoupe plus. Ce n'est pas la nature
/// de la courbe qui change, c'est qu'elle rencontre le sol ou non.
void main() {
  // Valeurs de référence, en unités du Système international.
  const double g = 6.674e-11;
  const double masseTerre = 5.972e24;
  const double rayonTerre = 6371e3;

  double vitesseCirculaire(double rayon) =>
      math.sqrt(g * masseTerre / rayon) / 1000;

  group('Les deux vitesses cosmiques', () {
    test('la satellisation au ras du sol vaut bien 7,9 km/s', () {
      expect(vitesseCirculaire(rayonTerre), closeTo(7.91, 0.02));
      expect(
        NewtonCannonFigure.vitesseOrbitale,
        closeTo(vitesseCirculaire(rayonTerre), 0.05),
      );
    });

    test('la libération est la précédente multipliée par racine de deux', () {
      final double liberation = vitesseCirculaire(rayonTerre) * math.sqrt2;
      expect(liberation, closeTo(11.19, 0.03));
      expect(
        NewtonCannonFigure.vitesseLiberation,
        closeTo(liberation, 0.05),
      );
      // Le rapport est une propriété exacte, pas une coïncidence de
      // chiffres : il vaut racine de deux quelle que soit la planète.
      expect(
        NewtonCannonFigure.vitesseLiberation /
            NewtonCannonFigure.vitesseOrbitale,
        closeTo(math.sqrt2, 0.01),
      );
    });

    test('à 400 km il en faut un peu moins, comme le dit le cours', () {
      expect(vitesseCirculaire(rayonTerre + 400e3), closeTo(7.67, 0.02));
      expect(
        vitesseCirculaire(rayonTerre + 400e3),
        lessThan(vitesseCirculaire(rayonTerre)),
      );
    });

    test('la Station boucle son tour en 92 minutes', () {
      const double r = rayonTerre + 400e3;
      final double periode =
          2 * math.pi * math.sqrt(r * r * r / (g * masseTerre));
      expect(periode / 60, closeTo(92.4, 0.5));
      // L'estimation demandée à l'élève, 90 minutes, tient dans sa marge.
      expect((periode / 60 - 90).abs(), lessThan(20));
      // Et la circonférence annoncée par le cours.
      expect(2 * math.pi * r / 1000, closeTo(42543, 50));
    });
  });

  group('La Lune', () {
    const double distanceLune = 384400e3;

    test('est à 60 rayons terrestres, donc 3 600 fois moins attirée', () {
      const double rapport = distanceLune / rayonTerre;
      expect(rapport, closeTo(60.3, 0.1));
      // La réponse attendue à la question : 60² = 3 600.
      expect(60 * 60, 3600);
      expect(rapport * rapport, closeTo(3640, 20));
    });

    test('et met 27 jours à faire son tour', () {
      final double periode = 2 *
          math.pi *
          math.sqrt(
            distanceLune * distanceLune * distanceLune / (g * masseTerre),
          );
      expect(periode / 86400, closeTo(27.4, 0.3));
      expect(vitesseCirculaire(distanceLune), closeTo(1.02, 0.02));
    });

    test('plus c\'est loin, plus c\'est lent', () {
      // L'affirmation de la dernière question du défi. On la vérifie sur
      // toute la gamme plutôt que sur deux cas choisis.
      double precedente = double.infinity;
      for (double r = rayonTerre; r < distanceLune; r *= 1.3) {
        final double v = vitesseCirculaire(r);
        expect(v, lessThan(precedente), reason: 'rayon $r');
        precedente = v;
      }
    });
  });

  group('La loi en carré inverse', () {
    double force(double distance) => g * masseTerre * 1 / (distance * distance);

    test('doubler la distance divise la force par quatre', () {
      for (double r = rayonTerre; r < 1e10; r *= 2.7) {
        expect(force(r) / force(2 * r), closeTo(4, 1e-9));
        expect(force(r) / force(3 * r), closeTo(9, 1e-9));
      }
    });

    test('elle ne s\'annule jamais tout à fait', () {
      // L'affirmation de la carte d'avertissement.
      for (double r = rayonTerre; r < 1e18; r *= 100) {
        expect(force(r), greaterThan(0));
      }
    });
  });

  group('Le verdict de la figure', () {
    test('les trois issues suivent les deux seuils', () {
      expect(NewtonCannonFigure.issue(2), Issue.retombe);
      expect(NewtonCannonFigure.issue(7.8), Issue.retombe);
      expect(NewtonCannonFigure.issue(7.9), Issue.orbite);
      expect(NewtonCannonFigure.issue(9.5), Issue.orbite);
      expect(NewtonCannonFigure.issue(11.1), Issue.orbite);
      expect(NewtonCannonFigure.issue(11.2), Issue.echappe);
      expect(NewtonCannonFigure.issue(13), Issue.echappe);
    });

    test('le verdict ne recule jamais quand la vitesse monte', () {
      // Une inversion quelque part dans la plage serait invisible à
      // l'usage, parce qu'on ne pousse pas le curseur pas à pas.
      int rang(Issue i) => Issue.values.indexOf(i);
      int precedent = -1;
      for (double v = 2; v <= 13; v += 0.05) {
        final int r = rang(NewtonCannonFigure.issue(v));
        expect(r, greaterThanOrEqualTo(precedent), reason: 'à $v km/s');
        precedent = r;
      }
    });
  });

  group('La forme de la trajectoire', () {
    test('trop lent, l\'ellipse est rentrante et recoupe la Terre', () {
      // Le demi-grand axe est inférieur au rayon terrestre : l'ellipse
      // passe donc sous la surface, ce qui est exactement ce que veut
      // dire « le boulet retombe ».
      for (final double v in <double>[3, 5, 7, 7.8]) {
        final double a = NewtonCannonFigure.demiGrandAxe(v);
        expect(a, lessThan(1), reason: 'à $v km/s');
        expect(a, greaterThan(0));
      }
    });

    test('à la vitesse orbitale exacte, la trajectoire est un cercle', () {
      expect(
        NewtonCannonFigure.demiGrandAxe(NewtonCannonFigure.vitesseOrbitale),
        closeTo(1, 1e-9),
      );
      expect(
        NewtonCannonFigure.excentricite(NewtonCannonFigure.vitesseOrbitale),
        closeTo(0, 1e-9),
      );
    });

    test('au-delà, l\'ellipse s\'ouvre puis cesse d\'être fermée', () {
      // Entre les deux seuils, le demi-grand axe croît : l'orbite monte
      // de plus en plus haut de l'autre côté.
      double precedent = 1;
      for (double v = 8; v < 11.2; v += 0.2) {
        final double a = NewtonCannonFigure.demiGrandAxe(v);
        expect(a, greaterThan(precedent), reason: 'à $v km/s');
        precedent = a;
      }
      // À la libération exacte, elle part à l'infini : c'est une parabole.
      expect(
        NewtonCannonFigure.demiGrandAxe(NewtonCannonFigure.vitesseLiberation),
        anyOf(
          equals(double.infinity),
          lessThan(0),
          greaterThan(1e6),
        ),
      );
    });

    test('l\'excentricité est nulle au cercle et croît des deux côtés', () {
      expect(NewtonCannonFigure.excentricite(7.9), closeTo(0, 1e-9));
      expect(
        NewtonCannonFigure.excentricite(5),
        greaterThan(NewtonCannonFigure.excentricite(7)),
      );
      expect(
        NewtonCannonFigure.excentricite(11),
        greaterThan(NewtonCannonFigure.excentricite(9)),
      );
    });
  });
}
