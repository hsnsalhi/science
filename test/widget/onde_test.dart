import 'dart:math' as math;

import 'package:eureka/design_system/figures/wave_figure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie la figure d'onde contre la physique, et non contre elle-même.
///
/// Les célérités sont des mesures de la littérature ; la longueur d'onde
/// est recalculée ici à partir d'elles, et jamais relue depuis la figure.
void main() {
  group('La relation entre célérité, fréquence et longueur d’onde', () {
    test('la longueur d’onde multipliée par la fréquence redonne la célérité', () {
      for (final MilieuSonore milieu in MilieuSonore.values) {
        for (final double f in <double>[170, 440, 1000, 2000]) {
          final double lambda = WaveFigure.longueurDOnde(milieu, f);
          expect(
            lambda * f,
            closeTo(milieu.celerite, 1e-9),
            reason: 'dans ${milieu.nom} à $f Hz',
          );
        }
      }
    });

    test('le la du diapason mesure 78 centimètres dans l’air', () {
      // 343 / 440 = 0,7795…, soit la taille d'un bras. C'est l'ordre de
      // grandeur qui rend le chapitre concret, et il faut qu'il tombe.
      expect(
        WaveFigure.longueurDOnde(MilieuSonore.air, 440),
        closeTo(0.78, 0.005),
      );
    });

    test('à fréquence égale, un milieu plus rapide allonge l’onde', () {
      const double f = 440;
      final List<double> longueurs = <double>[
        for (final MilieuSonore m in <MilieuSonore>[
          MilieuSonore.air,
          MilieuSonore.helium,
          MilieuSonore.eau,
        ])
          WaveFigure.longueurDOnde(m, f),
      ];
      // L'ordre des célérités doit se retrouver dans l'ordre des
      // longueurs d'onde, et strictement.
      for (int i = 1; i < longueurs.length; i++) {
        expect(longueurs[i], greaterThan(longueurs[i - 1]));
      }
    });

    test('dans chaque milieu, monter la fréquence raccourcit l’onde', () {
      for (final MilieuSonore milieu in MilieuSonore.values) {
        double precedente = double.infinity;
        for (double f = WaveFigure.frequenceMin;
            f <= WaveFigure.frequenceMax;
            f += 10) {
          final double lambda = WaveFigure.longueurDOnde(milieu, f);
          expect(lambda, lessThan(precedente), reason: '${milieu.nom} à $f Hz');
          precedente = lambda;
        }
      }
    });

    test('le rapport des longueurs d’onde est celui des célérités', () {
      // Dans l'hélium le son va presque trois fois plus vite que dans
      // l'air : c'est la seule raison pour laquelle ce milieu figure
      // parmi les choix.
      const double f = 1000;
      expect(
        WaveFigure.longueurDOnde(MilieuSonore.helium, f) /
            WaveFigure.longueurDOnde(MilieuSonore.air, f),
        closeTo(MilieuSonore.helium.celerite / MilieuSonore.air.celerite, 1e-9),
      );
      expect(
        MilieuSonore.helium.celerite / MilieuSonore.air.celerite,
        closeTo(2.94, 0.01),
      );
    });

    test('la période est l’inverse de la fréquence', () {
      for (final double f in <double>[170, 440, 1000, 2000]) {
        expect(WaveFigure.periode(f) * f, closeTo(1, 1e-12));
      }
      // 440 Hz, c'est 2,27 millisecondes par aller-retour : aucune
      // animation ne peut le montrer en temps réel, et la figure le dit.
      expect(WaveFigure.periode(440) * 1000, closeTo(2.27, 0.01));
    });

    test('la longueur d’onde est bien la distance parcourue en une période', () {
      for (final MilieuSonore milieu in MilieuSonore.values) {
        for (final double f in <double>[170, 440, 2000]) {
          expect(
            milieu.celerite * WaveFigure.periode(f),
            closeTo(WaveFigure.longueurDOnde(milieu, f), 1e-9),
          );
        }
      }
    });
  });

  group('Ce que le dessin peut montrer', () {
    test('la fenêtre reste lisible sur tout le domaine réglable', () {
      // Garde-fou sur le dessin : en dessous d'un cinquième de période
      // l'onde n'est plus reconnaissable, au-dessus d'une douzaine elle
      // devient un peigne. Si quelqu'un élargit les bornes du curseur ou
      // ajoute un milieu, ce test le lui dira.
      double minimum = double.infinity;
      double maximum = 0;
      for (final MilieuSonore milieu in MilieuSonore.values) {
        for (double f = WaveFigure.frequenceMin;
            f <= WaveFigure.frequenceMax;
            f += 10) {
          final double visibles = WaveFigure.ondesVisibles(milieu, f);
          minimum = math.min(minimum, visibles);
          maximum = math.max(maximum, visibles);
        }
      }
      expect(minimum, greaterThan(0.2));
      expect(maximum, lessThan(12));
    });

    test('le crochet de mesure n’est posé que quand l’onde y tient', () {
      // Dans l'eau à basse fréquence, une longueur d'onde dépasse la
      // fenêtre : le crochet disparaît et la légende l'explique. Ce
      // n'est pas un défaut à corriger, c'est le fait à montrer.
      expect(
        WaveFigure.longueurDOnde(MilieuSonore.eau, 170),
        greaterThan(WaveFigure.fenetre),
      );
      expect(
        WaveFigure.longueurDOnde(MilieuSonore.air, 1000),
        lessThan(WaveFigure.fenetre),
      );
      // Et l'air au tout début du curseur est le cas limite : 343/170
      // dépasse 2 mètres de dix-huit millimètres.
      expect(
        WaveFigure.longueurDOnde(MilieuSonore.air, WaveFigure.frequenceMin),
        greaterThan(WaveFigure.fenetre),
      );
    });

    test('le point suivi est dans la fenêtre', () {
      expect(WaveFigure.pointSuivi, greaterThan(0));
      expect(WaveFigure.pointSuivi, lessThan(WaveFigure.fenetre));
    });
  });

  group('L’onde progressive', () {
    const double lambda = 0.8;

    test('l’onde se répète d’une longueur d’onde à la suivante', () {
      for (final double phase in <double>[0, 0.17, 0.5, 0.83]) {
        for (final double x in <double>[0, 0.1, 0.37, 0.75]) {
          expect(
            WaveFigure.elongation(
              metres: x + lambda,
              longueurDOnde: lambda,
              phase: phase,
            ),
            closeTo(
              WaveFigure.elongation(
                metres: x,
                longueurDOnde: lambda,
                phase: phase,
              ),
              1e-12,
            ),
          );
        }
      }
    });

    test('elle avance vers la droite', () {
      // La crête vaut +1. On la cherche par balayage, sans se servir de
      // la formule qui la donne, et on vérifie qu'elle s'est déplacée du
      // bon côté et de la bonne distance.
      double creteA(double phase) {
        double meilleure = 0;
        double maxi = -2;
        for (double x = 0; x < lambda; x += lambda / 20000) {
          final double y = WaveFigure.elongation(
            metres: x,
            longueurDOnde: lambda,
            phase: phase,
          );
          if (y > maxi) {
            maxi = y;
            meilleure = x;
          }
        }
        return meilleure;
      }

      const double avant = 0.1;
      final double depart = creteA(0);
      final double arrivee = creteA(avant);
      expect(arrivee, greaterThan(depart));
      // En un dixième de période, la crête avance d'un dixième de
      // longueur d'onde : c'est la définition de la célérité.
      expect(arrivee - depart, closeTo(avant * lambda, lambda / 1000));
    });

    test('un point du milieu revient à sa place après une période', () {
      for (final double x in <double>[0, WaveFigure.pointSuivi, 1.9]) {
        for (final double phase in <double>[0, 0.3, 0.64]) {
          expect(
            WaveFigure.elongation(
              metres: x,
              longueurDOnde: lambda,
              phase: phase + 1,
            ),
            closeTo(
              WaveFigure.elongation(
                metres: x,
                longueurDOnde: lambda,
                phase: phase,
              ),
              1e-12,
            ),
          );
        }
      }
    });

    test('un point du milieu balaie toute l’amplitude, et rien de plus', () {
      double bas = double.infinity;
      double haut = -double.infinity;
      for (double phase = 0; phase < 1; phase += 0.0001) {
        final double y = WaveFigure.elongation(
          metres: WaveFigure.pointSuivi,
          longueurDOnde: lambda,
          phase: phase,
        );
        bas = math.min(bas, y);
        haut = math.max(haut, y);
      }
      // Le point monte et descend d'un bout à l'autre du rail, et il ne
      // sort jamais de l'intervalle : une onde ne déplace pas la matière.
      expect(haut, closeTo(1, 1e-6));
      expect(bas, closeTo(-1, 1e-6));
    });

    test('la membrane de la source et le milieu ont la même période', () {
      // La source est le point d'abscisse zéro. Elle doit osciller
      // exactement au même rythme que le point suivi plus loin, et
      // seulement avec un retard : c'est ce retard qui est la
      // propagation.
      const double retard = WaveFigure.pointSuivi / lambda;
      for (final double phase in <double>[0.05, 0.4, 0.9]) {
        expect(
          WaveFigure.elongation(
            metres: WaveFigure.pointSuivi,
            longueurDOnde: lambda,
            phase: phase,
          ),
          closeTo(
            WaveFigure.elongation(
              metres: 0,
              longueurDOnde: lambda,
              phase: phase - retard,
            ),
            1e-12,
          ),
        );
      }
    });
  });

  group('Les célérités employées', () {
    test('elles sont celles de la littérature à 20 degrés', () {
      expect(MilieuSonore.air.celerite, 343);
      expect(MilieuSonore.helium.celerite, 1007);
      expect(MilieuSonore.eau.celerite, 1480);
    });

    test('elles sont rangées dans l’ordre croissant', () {
      // L'ordre des puces n'est pas cosmétique : il fait lire la
      // progression des célérités de gauche à droite.
      for (int i = 1; i < MilieuSonore.values.length; i++) {
        expect(
          MilieuSonore.values[i].celerite,
          greaterThan(MilieuSonore.values[i - 1].celerite),
        );
      }
    });
  });
}
