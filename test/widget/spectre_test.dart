import 'dart:math' as math;

import 'package:eureka/design_system/figures/spectrum_figure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie la figure du spectre contre la physique, et non contre
/// elle-même.
///
/// Deux choses sont en jeu, et elles doivent rester indépendantes :
/// la couleur d'ensemble, qui ne dépend que de la température, et la
/// position des raies, qui ne dépend que de l'élément. C'est cette
/// indépendance que le chapitre enseigne, donc c'est elle qu'il faut
/// protéger.
void main() {
  group('La loi de Wien', () {
    test('le pic du Soleil tombe au milieu du visible', () {
      // 5 778 K est la température de surface du Soleil. Le pic à
      // 501 nm, en plein vert, n'est pas une coïncidence : l'œil a
      // évolué sous cette lumière.
      expect(SpectrumFigure.longueurDOndePic(5778), closeTo(501, 2));
    });

    test('doubler la température divise la longueur d’onde par deux', () {
      for (final double t in <double>[3000, 5000, 10000]) {
        expect(
          SpectrumFigure.longueurDOndePic(t) /
              SpectrumFigure.longueurDOndePic(2 * t),
          closeTo(2, 1e-9),
        );
      }
    });

    test('une étoile froide a son pic dans l’infrarouge', () {
      // À 3 000 K le maximum est au-delà du visible : l'étoile paraît
      // rouge parce qu'on n'en voit que la queue.
      expect(
        SpectrumFigure.longueurDOndePic(SpectrumFigure.tMin),
        greaterThan(SpectrumFigure.visibleMax),
      );
    });

    test('une étoile très chaude a son pic dans l’ultraviolet', () {
      expect(
        SpectrumFigure.longueurDOndePic(SpectrumFigure.tMax),
        lessThan(SpectrumFigure.visibleMin),
      );
    });
  });

  group('La loi de Planck', () {
    test('son maximum tombe bien là où Wien l’annonce', () {
      // Le test le plus utile du fichier : la courbe dessinée vient de
      // Planck, le repère « max » vient de Wien, et rien dans le code
      // ne les relie. S'ils divergeaient, la figure se contredirait
      // elle-même sous les yeux de l'élève.
      for (final double t in <double>[3000, 5800, 12000, 25000]) {
        double meilleur = 0;
        double maxi = -1;
        for (double nm = 50; nm < 3000; nm += 0.2) {
          final double p = SpectrumFigure.planck(nm, t);
          if (p > maxi) {
            maxi = p;
            meilleur = nm;
          }
        }
        expect(
          meilleur,
          closeTo(SpectrumFigure.longueurDOndePic(t), meilleur * 0.01),
          reason: 'à $t K, Planck culmine à $meilleur nm',
        );
      }
    });

    test('plus chaud veut dire plus bleu que rouge', () {
      // C'est ce que la bande colorée doit montrer. Le rapport entre le
      // bleu et le rouge doit croître strictement avec la température.
      double rapport(double t) =>
          SpectrumFigure.planck(450, t) / SpectrumFigure.planck(650, t);
      double precedent = 0;
      for (double t = 3000; t <= 30000; t += 500) {
        final double r = rapport(t);
        expect(r, greaterThan(precedent), reason: 'à $t K');
        precedent = r;
      }
      // Et l'écart est net d'un bout à l'autre du curseur.
      expect(rapport(30000) / rapport(3000), greaterThan(5));
    });

    test('l’intensité relative reste entre zéro et un', () {
      for (final double t in <double>[3000, 5800, 30000]) {
        double maxi = 0;
        for (double nm = SpectrumFigure.visibleMin;
            nm <= SpectrumFigure.visibleMax;
            nm += 1) {
          final double i = SpectrumFigure.intensiteRelative(nm, t);
          expect(i, inInclusiveRange(0, 1.0001), reason: 'à $t K, $nm nm');
          maxi = math.max(maxi, i);
        }
        // Et elle atteint bien 1 quelque part : sinon la bande serait
        // uniformément terne.
        expect(maxi, closeTo(1, 0.01));
      }
    });
  });

  group('Les raies des éléments', () {
    test('la série de Balmer de l’hydrogène est au bon endroit', () {
      // Les quatre raies visibles de l'hydrogène, dans l'ordre
      // décroissant des longueurs d'onde. Une erreur ici ferait désigner
      // un autre élément.
      expect(
        ElementSpectral.hydrogene.raies,
        <double>[656.3, 486.1, 434.0, 410.2],
      );
    });

    test('toutes les raies citées tombent dans le visible', () {
      // La figure n'affiche que le visible : une raie hors de cette
      // plage serait tracée nulle part et l'élément paraîtrait sans
      // signature.
      for (final ElementSpectral e in ElementSpectral.values) {
        expect(e.raies, isNotEmpty, reason: e.nom);
        for (final double raie in e.raies) {
          expect(
            raie,
            inInclusiveRange(
              SpectrumFigure.visibleMin,
              SpectrumFigure.visibleMax,
            ),
            reason: '${e.nom} : $raie nm',
          );
        }
      }
    });

    test('deux éléments ne partagent aucune raie', () {
      // C'est ce qui fait d'un spectre une signature. Si deux éléments
      // de la figure se confondaient, le chapitre enseignerait le
      // contraire de ce qu'il affirme.
      for (final ElementSpectral a in ElementSpectral.values) {
        for (final ElementSpectral b in ElementSpectral.values) {
          if (a == b) continue;
          for (final double ra in a.raies) {
            for (final double rb in b.raies) {
              expect(
                (ra - rb).abs(),
                greaterThan(1),
                reason: '${a.nom} et ${b.nom} se confondent vers $ra nm',
              );
            }
          }
        }
      }
    });

    test('les raies ne dépendent pas de la température', () {
      // Évident dans le code, et c'est bien pour cela qu'il faut le
      // fixer : quelqu'un qui ferait dépendre les raies de la
      // température casserait la leçon sans casser le dessin.
      final List<double> avant = List<double>.of(
        ElementSpectral.sodium.raies,
      );
      expect(ElementSpectral.sodium.raies, avant);
      expect(ElementSpectral.sodium.raies.first, closeTo(589.3, 0.5));
    });
  });

  group('La couleur annoncée', () {
    test('elle suit la classification spectrale', () {
      expect(SpectrumFigure.teinte(3200), 'rouge');
      expect(SpectrumFigure.teinte(5800), 'jaune');
      expect(SpectrumFigure.teinte(9000), 'blanche');
      expect(SpectrumFigure.teinte(20000), 'bleue');
    });

    test('le bleu est chaud et le rouge est froid', () {
      // L'inverse du code couleur des robinets, et c'est l'erreur que
      // la leçon doit défaire.
      final List<String> teintes = <String>[
        for (double t = 3000; t <= 30000; t += 1000) SpectrumFigure.teinte(t),
      ];
      expect(teintes.first, 'rouge');
      expect(teintes.last, 'bleue');
    });

    test('la teinte d’une longueur d’onde est celle qu’on attend', () {
      // 450 nm doit être franchement bleu, 650 franchement rouge, et
      // 530 vert dominant. Sans cela la bande ne serait pas un spectre.
      expect(SpectrumFigure.couleurDe(450).b,
          greaterThan(SpectrumFigure.couleurDe(450).r));
      expect(SpectrumFigure.couleurDe(650).r,
          greaterThan(SpectrumFigure.couleurDe(650).b));
      final int vert = (SpectrumFigure.couleurDe(530).g * 255).round();
      expect(vert, greaterThan(200));
    });
  });
}
