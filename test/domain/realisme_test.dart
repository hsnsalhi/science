import 'dart:math' as math;

import 'package:eureka/design_system/figures/realism.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'ombrage d'une sphère est de l'information, donc il se vérifie.
///
/// Un dessin qui a l'air juste peut être faux : un croissant dont le bord
/// intérieur est droit décrit un disque découpé, pas une boule éclairée, et
/// personne ne le remarque sur une capture. Ces tests mesurent la surface
/// réellement couverte par le chemin d'ombre, en comptant des points, et la
/// confrontent à la fraction éclairée théorique d'une sphère.
///
/// C'est la même méthode que pour le reste du dépôt : on recalcule au lieu
/// de relire.
void main() {
  const double rayon = 100;

  /// Part du disque couverte par [chemin], par échantillonnage régulier.
  ///
  /// On compte sur une grille fine plutôt que par une formule d'aire :
  /// l'intérêt est précisément de mesurer ce que le chemin contient, pas
  /// ce qu'on croit qu'il contient.
  double partCouverte(Path chemin) {
    const int pas = 220;
    int dansDisque = 0;
    int dansChemin = 0;
    for (int i = 0; i <= pas; i++) {
      for (int j = 0; j <= pas; j++) {
        final double x = -rayon + 2 * rayon * i / pas;
        final double y = -rayon + 2 * rayon * j / pas;
        if (x * x + y * y > rayon * rayon) continue;
        dansDisque++;
        if (chemin.contains(Offset(x, y))) dansChemin++;
      }
    }
    expect(dansDisque, greaterThan(30000), reason: 'grille assez fine');
    return dansChemin / dansDisque;
  }

  group('La fraction éclairée', () {
    test('vaut 1 en pleine lumière et 0 à contre-jour', () {
      expect(Realisme.fractionEclairee(0), closeTo(1, 1e-12));
      expect(Realisme.fractionEclairee(180), closeTo(0, 1e-12));
    });

    test('vaut une moitié au quartier', () {
      expect(Realisme.fractionEclairee(90), closeTo(0.5, 1e-12));
      expect(Realisme.fractionEclairee(270), closeTo(0.5, 1e-12));
    });

    test('décroît sans palier de 0 à 180 degrés', () {
      double precedent = 2;
      for (double a = 0; a <= 180; a += 1) {
        final double f = Realisme.fractionEclairee(a);
        expect(f, lessThan(precedent), reason: 'angle $a');
        expect(f, inInclusiveRange(0, 1));
        precedent = f;
      }
    });

    test('est symétrique : croissant et décroissant se valent', () {
      for (double a = 0; a <= 180; a += 5) {
        expect(
          Realisme.fractionEclairee(a),
          closeTo(Realisme.fractionEclairee(360 - a), 1e-12),
        );
      }
    });
  });

  group('Le contour de la nuit', () {
    test('est vide en pleine lumière, entier à contre-jour', () {
      expect(Realisme.contourNuit(rayon, 0).getBounds().isEmpty, isTrue);
      expect(partCouverte(Realisme.contourNuit(rayon, 180)), closeTo(1, 0.01));
    });

    test('couvre exactement la part non éclairée, à chaque phase', () {
      // Le test central. Si le terminateur était tracé droit au lieu
      // d'être une demi-ellipse, les croissants seraient trop larges et
      // les gibbeuses trop étroites — l'écart se verrait ici avant de se
      // voir à l'œil.
      for (final double angle in <double>[
        15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165,
      ]) {
        final double attendue = 1 - Realisme.fractionEclairee(angle);
        expect(
          partCouverte(Realisme.contourNuit(rayon, angle)),
          closeTo(attendue, 0.02),
          reason: 'angle de phase $angle°',
        );
      }
    });

    test('et aussi dans la seconde moitié du cycle', () {
      for (final double angle in <double>[195, 240, 270, 300, 345]) {
        final double attendue = 1 - Realisme.fractionEclairee(angle);
        expect(
          partCouverte(Realisme.contourNuit(rayon, angle)),
          closeTo(attendue, 0.02),
          reason: 'angle de phase $angle°',
        );
      }
    });

    test('l\'ombre change de côté entre croissant et décroissant', () {
      // Avant le plein, l'ombre est à droite ; après, à gauche. C'est ce
      // qui distingue un premier quartier d'un dernier dans le ciel, et
      // une figure qui l'inverse enseigne une erreur vérifiable.
      final Rect avant = Realisme.contourNuit(rayon, 90).getBounds();
      final Rect apres = Realisme.contourNuit(rayon, 270).getBounds();
      expect(avant.center.dx, greaterThan(0));
      expect(apres.center.dx, lessThan(0));
    });

    test('le terminateur coupe l\'équateur là où l\'ellipse le veut', () {
      // Mesure directe du demi-axe : sur la ligne y = 0, on cherche par
      // dichotomie l'abscisse où le chemin cesse de contenir le point.
      // Elle doit valoir rayon × |cos(angle)| — c'est la définition de la
      // demi-ellipse, et un terminateur tracé droit la raterait partout
      // sauf au quartier.
      //
      // La boîte englobante ne servirait à rien ici : le contour passe par
      // les deux pôles, donc elle vaut le demi-disque à toute phase.
      double frontiere(Path chemin, {required bool versLaDroite}) {
        final double signe = versLaDroite ? 1 : -1;
        // L'ombre touche le limbe et s'arrête avant le centre : le point
        // « dedans » est donc du côté du bord, le point « dehors » vers
        // l'autre limbe. L'encadrement part dans ce sens-là.
        if (!chemin.contains(Offset(signe * (rayon - 0.5), 0))) {
          return double.nan;
        }
        double dedans = rayon - 0.5;
        double dehors = -rayon + 0.5;
        for (int i = 0; i < 40; i++) {
          final double milieu = (dedans + dehors) / 2;
          if (chemin.contains(Offset(signe * milieu, 0))) {
            dedans = milieu;
          } else {
            dehors = milieu;
          }
        }
        return (dedans + dehors) / 2;
      }

      for (final double angle in <double>[20, 40, 60, 80]) {
        // Phases presque pleines : l'ombre est un croissant, et sa
        // frontière intérieure est à rayon × cos(angle).
        final double attendu =
            rayon * math.cos(angle * math.pi / 180);
        final double mesure = frontiere(
          Realisme.contourNuit(rayon, angle),
          versLaDroite: true,
        );
        expect(mesure, closeTo(attendu, 1.5), reason: 'angle $angle°');
      }

      // Au quartier exact, la frontière est en zéro : le terminateur est
      // alors la seule fois où il est droit.
      expect(
        frontiere(Realisme.contourNuit(rayon, 90), versLaDroite: true),
        closeTo(0, 1.5),
      );

      // Après le quartier, l'ombre a franchi l'axe : le point (−r/4, 0)
      // est dans la nuit, ce qu'un terminateur droit interdirait.
      for (final double angle in <double>[110, 130, 160]) {
        expect(
          Realisme.contourNuit(rayon, angle)
              .contains(const Offset(-rayon / 4, 0)),
          isTrue,
          reason: 'angle $angle°',
        );
      }
    });

    test('la nuit reste dans le disque', () {
      for (double a = 5; a < 360; a += 5) {
        final Rect cadre = Realisme.contourNuit(rayon, a).getBounds();
        expect(cadre.left, greaterThanOrEqualTo(-rayon - 0.6));
        expect(cadre.right, lessThanOrEqualTo(rayon + 0.6));
        expect(cadre.top, greaterThanOrEqualTo(-rayon - 0.6));
        expect(cadre.bottom, lessThanOrEqualTo(rayon + 0.6));
      }
    });

    test('les angles hors de 0-360 se ramènent dans le cycle', () {
      for (final double tour in <double>[-720, -360, 360, 720]) {
        expect(
          partCouverte(Realisme.contourNuit(rayon, 90 + tour)),
          closeTo(partCouverte(Realisme.contourNuit(rayon, 90)), 0.005),
        );
      }
    });
  });

  group('La paroi organique', () {
    test('est fermée, stable et contenue dans son cadre', () {
      const Rect cadre = Rect.fromLTWH(0, 0, 120, 80);
      final Path a = Realisme.paroiOrganique(cadre, graine: 4);
      final Path b = Realisme.paroiOrganique(cadre, graine: 4);
      // Déterminisme : deux appels de même graine donnent la même forme,
      // sans quoi les captures de référence changeraient à chaque exécution.
      expect(a.getBounds(), b.getBounds());
      // Et une graine différente donne autre chose, sinon la fonction ne
      // sert à rien.
      expect(
        Realisme.paroiOrganique(cadre, graine: 9).getBounds(),
        isNot(a.getBounds()),
      );
      // Le débordement reste borné par l'irrégularité demandée.
      final Rect limites = Realisme
          .paroiOrganique(cadre, graine: 4, irregularite: 0.1)
          .getBounds();
      expect(limites.width, lessThan(cadre.width * 1.25));
      expect(limites.height, lessThan(cadre.height * 1.25));
    });

    test('n\'est pas un ovale : ses rayons varient', () {
      const Rect cadre = Rect.fromLTWH(0, 0, 100, 100);
      final Path forme = Realisme.paroiOrganique(cadre, graine: 2);
      final Offset centre = cadre.center;
      final List<double> distances = <double>[];
      for (int i = 0; i < 360; i += 10) {
        final double a = i * math.pi / 180;
        // On cherche le rayon où le chemin cesse de contenir le point.
        double r = 0;
        while (r < 80 &&
            forme.contains(
              centre + Offset(math.cos(a) * r, math.sin(a) * r),
            )) {
          r += 0.5;
        }
        distances.add(r);
      }
      final double moyenne =
          distances.reduce((double a, double b) => a + b) / distances.length;
      final double ecartMax = distances
          .map((double d) => (d - moyenne).abs())
          .reduce(math.max);
      expect(moyenne, greaterThan(30));
      expect(
        ecartMax / moyenne,
        greaterThan(0.04),
        reason: 'un contour parfaitement régulier serait un ovale',
      );
    });
  });
}
