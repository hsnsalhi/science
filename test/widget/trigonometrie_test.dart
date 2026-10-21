import 'dart:math' as math;

import 'package:eureka/design_system/figures/trigonometry_figure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La figure de trigonométrie.
///
/// Elle promet une chose et une seule : les longueurs dépendent de la
/// taille, les rapports non. Les tests le vérifient en recalculant les
/// côtés à plusieurs tailles et en comparant les quotients, sans passer
/// par les fonctions trigonométriques de la figure.
void main() {
  group('Le triangle', () {
    test('il est bien rectangle, à toute taille et tout angle', () {
      for (double angle = 10; angle <= 80; angle += 5) {
        for (double taille = 0; taille <= 1.0001; taille += 0.2) {
          final double h = TrigonometryFigure.hypotenuse(taille);
          final double o = TrigonometryFigure.oppose(angle, taille);
          final double a = TrigonometryFigure.adjacent(angle, taille);
          // Pythagore sert ici de témoin : si les trois côtés le
          // vérifient, le triangle est rectangle.
          expect(o * o + a * a, closeTo(h * h, 1e-9),
              reason: 'angle $angle, taille $taille');
        }
      }
    });

    test('agrandir multiplie les trois côtés par le même facteur', () {
      const double angle = 35;
      final double h0 = TrigonometryFigure.hypotenuse(0);
      final double o0 = TrigonometryFigure.oppose(angle, 0);
      final double a0 = TrigonometryFigure.adjacent(angle, 0);
      for (double taille = 0.1; taille <= 1.0001; taille += 0.1) {
        final double facteur =
            TrigonometryFigure.hypotenuse(taille) / h0;
        expect(TrigonometryFigure.oppose(angle, taille),
            closeTo(o0 * facteur, 1e-9));
        expect(TrigonometryFigure.adjacent(angle, taille),
            closeTo(a0 * facteur, 1e-9));
      }
    });
  });

  group('Les rapports', () {
    test('ils ne dépendent pas de la taille — le cœur du chapitre', () {
      for (double angle = 10; angle <= 80; angle += 10) {
        final List<double> sinus = <double>[];
        final List<double> cosinus = <double>[];
        final List<double> tangentes = <double>[];
        for (double taille = 0; taille <= 1.0001; taille += 0.125) {
          final double h = TrigonometryFigure.hypotenuse(taille);
          final double o = TrigonometryFigure.oppose(angle, taille);
          final double a = TrigonometryFigure.adjacent(angle, taille);
          sinus.add(o / h);
          cosinus.add(a / h);
          tangentes.add(o / a);
        }
        for (final List<double> suite in <List<double>>[
          sinus,
          cosinus,
          tangentes,
        ]) {
          for (final double v in suite) {
            expect(v, closeTo(suite.first, 1e-9), reason: 'angle $angle');
          }
        }
      }
    });

    test('les valeurs annoncées sont bien ces quotients', () {
      for (double angle = 10; angle <= 80; angle += 5) {
        final double h = TrigonometryFigure.hypotenuse(0.4);
        final double o = TrigonometryFigure.oppose(angle, 0.4);
        final double a = TrigonometryFigure.adjacent(angle, 0.4);
        expect(RapportTrigo.sinus.valeur(angle), closeTo(o / h, 1e-9));
        expect(RapportTrigo.cosinus.valeur(angle), closeTo(a / h, 1e-9));
        expect(RapportTrigo.tangente.valeur(angle), closeTo(o / a, 1e-9));
      }
    });

    test('les valeurs remarquables tombent juste', () {
      expect(RapportTrigo.sinus.valeur(30), closeTo(0.5, 1e-9));
      expect(RapportTrigo.cosinus.valeur(60), closeTo(0.5, 1e-9));
      expect(RapportTrigo.tangente.valeur(45), closeTo(1, 1e-9));
      expect(RapportTrigo.sinus.valeur(45),
          closeTo(RapportTrigo.cosinus.valeur(45), 1e-9));
      expect(RapportTrigo.sinus.valeur(45), closeTo(math.sqrt1_2, 1e-9));
    });

    test('sinus et cosinus croissent en sens contraire', () {
      double sinusAvant = -1;
      double cosinusAvant = 2;
      for (double angle = 10; angle <= 80; angle += 1) {
        final double s = RapportTrigo.sinus.valeur(angle);
        final double c = RapportTrigo.cosinus.valeur(angle);
        expect(s, greaterThan(sinusAvant), reason: 'angle $angle');
        expect(c, lessThan(cosinusAvant), reason: 'angle $angle');
        sinusAvant = s;
        cosinusAvant = c;
      }
    });
  });

  group('La manipulation', () {
    testWidgets('agrandir ne change pas la valeur affichée', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrigonometryFigure(accent: Colors.blue),
            ),
          ),
        ),
      );
      expect(find.textContaining('sinus 35°'), findsOneWidget);
      // Le second curseur est celui de la taille.
      await tester.drag(find.byType(Slider).last, const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('sinus 35°'), findsOneWidget);
    });

    testWidgets('changer de rapport change la ligne affichée', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrigonometryFigure(accent: Colors.blue),
            ),
          ),
        ),
      );
      await tester.tap(find.text('tangente'));
      await tester.pumpAndSettle();
      expect(find.textContaining('tangente 35°'), findsOneWidget);
    });
  });
}
