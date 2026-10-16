import 'dart:math' as math;

import 'package:eureka/design_system/figures/pythagore_proof_figure.dart';
import 'package:flutter_test/flutter_test.dart';

/// La preuve par réarrangement ne vaut que si les pièces tombent juste.
///
/// Les huit poses ont été établies à la main. Une seule erreur de signe ou
/// de quart de tour, et la figure montrerait des triangles qui débordent
/// ou se chevauchent — tout en ayant l'air plausible sur une capture. Ces
/// tests mesurent ce que l'œil ne vérifie pas.
void main() {
  const double a = PythagoreProofFigure.a;
  const double b = PythagoreProofFigure.b;
  const double cote = a + b;

  /// Les trois sommets d'un triangle posé.
  List<({double x, double y})> sommets(ProofPose pose) {
    final double angle = pose.quarts * math.pi / 2;
    final double cos = math.cos(angle).roundToDouble();
    final double sin = math.sin(angle).roundToDouble();
    return <({double x, double y})>[
      (x: pose.x, y: pose.y),
      (x: pose.x + cos * b, y: pose.y + sin * b),
      (x: pose.x - sin * a, y: pose.y + cos * a),
    ];
  }

  bool dansLeTriangle(ProofPose pose, double px, double py) {
    final List<({double x, double y})> s = sommets(pose);
    double cote3(int i, int j) =>
        (s[j].x - s[i].x) * (py - s[i].y) - (s[j].y - s[i].y) * (px - s[i].x);
    final double d1 = cote3(0, 1);
    final double d2 = cote3(1, 2);
    final double d3 = cote3(2, 0);
    final bool negatif = d1 < 0 || d2 < 0 || d3 < 0;
    final bool positif = d1 > 0 || d2 > 0 || d3 > 0;
    return !(negatif && positif);
  }

  void verifier(String nom, List<ProofPose> poses) {
    test('$nom : les quatre triangles tiennent dans le carré', () {
      expect(poses.length, 4);
      for (final ProofPose pose in poses) {
        for (final ({double x, double y}) p in sommets(pose)) {
          expect(p.x, inInclusiveRange(0, cote), reason: '$nom déborde en x');
          expect(p.y, inInclusiveRange(0, cote), reason: '$nom déborde en y');
        }
      }
    });

    test('$nom : ils ne se chevauchent pas et couvrent 2ab', () {
      // Échantillonnage régulier : chaque point du carré doit appartenir à
      // un triangle au plus, et la part couverte doit valoir 2ab sur
      // (a + b)² — l'aire des quatre triangles.
      const int pas = 140;
      int couverts = 0;
      for (int i = 0; i < pas; i++) {
        for (int j = 0; j < pas; j++) {
          final double px = (i + 0.5) * cote / pas;
          final double py = (j + 0.5) * cote / pas;
          int dans = 0;
          for (final ProofPose pose in poses) {
            if (dansLeTriangle(pose, px, py)) dans++;
          }
          expect(dans, lessThanOrEqualTo(1), reason: '$nom : chevauchement');
          if (dans == 1) couverts++;
        }
      }
      final double part = couverts / (pas * pas);
      expect(part, closeTo(2 * a * b / (cote * cote), 0.01));
    });
  }

  group('Preuve de Pythagore', () {
    verifier('départ', PythagoreProofFigure.posesDepart);
    verifier('arrivée', PythagoreProofFigure.posesArrivee);

    test('l\'aire libre est la même des deux côtés', () {
      // Le grand carré et les quatre triangles sont identiques d'une
      // disposition à l'autre : ce qui reste libre vaut donc autant.
      const double libreDepart = cote * cote - 2 * a * b;
      final double c = math.sqrt(a * a + b * b);
      expect(libreDepart, a * a + b * b);
      expect(libreDepart, closeTo(c * c, 1e-9));
      expect(c, 5, reason: 'le triangle 3-4-5');
    });
  });
}
