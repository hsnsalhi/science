import 'package:eureka/design_system/figures/weight_figure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le chapitre sur les forces avance des nombres ; on les refait.
///
/// Un chapitre de physique se trompe plus discrètement qu'un chapitre de
/// maths : « environ 9,8 » laisse passer beaucoup de choses, et une erreur
/// de facteur six sur la Lune a l'air d'une approximation. Ces tests
/// recalculent chaque valeur annoncée et vérifient les rapports entre
/// astres, qui sont ce que l'élève retiendra vraiment.
void main() {
  group('La relation P = m × g', () {
    test('les valeurs de g sont celles que le chapitre annonce', () {
      expect(WeightFigure.pesanteur['Terre'], closeTo(9.8, 0.001));
      expect(WeightFigure.pesanteur['Lune'], closeTo(1.6, 0.001));
      expect(WeightFigure.pesanteur['Mars'], closeTo(3.7, 0.001));
      expect(WeightFigure.pesanteur['Jupiter'], closeTo(24.8, 0.001));
    });

    test('les poids calculés dans les questions', () {
      // Lesson « le poids », q1 et q2 : le même sac de 4 kg.
      expect(WeightFigure.poids(4, 'Terre'), closeTo(39.2, 0.001));
      expect(WeightFigure.poids(4, 'Lune'), closeTo(6.4, 0.001));
      // Défi q1 : 70 kg sur Mars, et la comparaison avec la Terre.
      expect(WeightFigure.poids(70, 'Mars'), closeTo(259, 0.001));
      expect(WeightFigure.poids(70, 'Terre'), closeTo(686, 0.001));
      // Défi q5 : l'estimation pour 50 kg.
      expect(WeightFigure.poids(50, 'Terre'), closeTo(490, 0.001));
    });

    test('et les masses retrouvées à partir d\'un poids', () {
      // Défi q3 : 24 N sur la Lune donnent 15 kg, donc 150 N sur Terre
      // avec g arrondi à 10.
      expect(WeightFigure.masse(24, 'Lune'), closeTo(15, 0.001));
      expect(WeightFigure.masse(24, 'Lune')! * 10, closeTo(150, 0.001));
      // Entraînement q2 : un livre de 0,5 kg, g = 10.
      expect(0.5 * 10, closeTo(5, 0.001));
    });

    test('poids et masse sont réciproques sur chaque astre', () {
      for (final String astre in WeightFigure.pesanteur.keys) {
        for (double m = 0.5; m <= 100; m += 0.5) {
          final double p = WeightFigure.poids(m, astre)!;
          expect(WeightFigure.masse(p, astre), closeTo(m, 1e-9));
        }
      }
    });

    test('le poids est proportionnel à la masse', () {
      // L'affirmation de la carte « pourquoi c'est une proportionnalité »
      // et de la question q4 : doubler la masse double le poids, et le
      // rapport P/m vaut g quelle que soit la masse.
      for (final MapEntry<String, double> e
          in WeightFigure.pesanteur.entries) {
        for (double m = 1; m <= 50; m++) {
          expect(
            WeightFigure.poids(2 * m, e.key),
            closeTo(2 * WeightFigure.poids(m, e.key)!, 1e-9),
          );
          expect(WeightFigure.poids(m, e.key)! / m, closeTo(e.value, 1e-9));
        }
      }
    });

    test('un astre inconnu ne se transforme pas en Terre', () {
      expect(WeightFigure.poids(4, 'Pluton'), isNull);
      expect(WeightFigure.masse(40, 'Vénus'), isNull);
      expect(WeightFigure.facteurFaceALaTerre('Titan'), isNull);
    });
  });

  group('Les comparaisons entre astres', () {
    test('la Lune : « six fois plus faible » tient à cet arrondi près', () {
      // Le chapitre l'écrit deux fois. 9,8 ÷ 1,6 = 6,125 : « six fois »
      // est juste, « cinq » ou « sept » ne l'auraient pas été.
      final double facteur = WeightFigure.facteurFaceALaTerre('Lune')!;
      expect(facteur, closeTo(6.125, 0.001));
      expect(facteur.round(), 6);
    });

    test('Jupiter écrase, Mars allège', () {
      expect(
        WeightFigure.pesanteur['Jupiter']! /
            WeightFigure.pesanteur['Terre']!,
        closeTo(2.53, 0.01),
      );
      expect(WeightFigure.facteurFaceALaTerre('Mars'), closeTo(2.65, 0.01));
    });

    test('l\'ordre des quatre astres est bien celui de la figure', () {
      final List<double> valeurs =
          WeightFigure.pesanteur.values.toList(growable: false);
      for (int i = 1; i < valeurs.length; i++) {
        expect(
          valeurs[i],
          greaterThan(valeurs[i - 1]),
          reason: 'les puces de la figure doivent rester croissantes',
        );
      }
    });

    test('à 400 km, la Terre attire encore près de 90 % du sol', () {
      // Le défi l'affirme et en tire la bonne explication de l'impesanteur.
      // On le recalcule par la loi en 1/r², sans la supposer.
      const double rayonTerre = 6371; // km
      const double altitude = 400;
      const double rapport =
          (rayonTerre / (rayonTerre + altitude)) *
          (rayonTerre / (rayonTerre + altitude));
      final double gOrbite = WeightFigure.pesanteur['Terre']! * rapport;
      expect(gOrbite, closeTo(8.7, 0.1));
      expect(rapport, greaterThan(0.88));
      expect(
        gOrbite,
        greaterThan(5 * WeightFigure.pesanteur['Lune']!),
        reason: 'la gravité en orbite basse est loin d\'avoir disparu',
      );
    });

    test('la chute libre ne dépend pas de la masse', () {
      // La dernière question du défi. L'accélération d'un corps en chute
      // est P/m = g : la masse se simplifie, et c'est pour cela que le
      // marteau et la plume d'Apollo 15 touchent le sol ensemble.
      for (final String astre in WeightFigure.pesanteur.keys) {
        final double g = WeightFigure.pesanteur[astre]!;
        for (double m = 0.01; m <= 1000; m *= 3) {
          expect(WeightFigure.poids(m, astre)! / m, closeTo(g, 1e-9));
        }
      }
    });
  });
}
