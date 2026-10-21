import 'package:eureka/design_system/figures/breaking_thread_figure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La figure du fil qui casse, éprouvée comme un mécanisme.
///
/// Une figure interactive n'est pas une illustration : c'est un petit
/// modèle que l'élève manipule, et dont il tirera des conclusions. Si le
/// seuil de rupture ne tombe pas où le cours le dit, l'élève apprend un
/// fait faux — et il l'apprend d'autant mieux qu'il l'a découvert lui-même.
void main() {
  group('La physique du fil', () {
    test('le poids est proportionnel à la masse', () {
      expect(BreakingThreadFigure.poids(1), closeTo(9.8, 1e-9));
      expect(BreakingThreadFigure.poids(5), closeTo(49, 1e-9));
      for (double m = 0.5; m <= 10; m += 0.5) {
        expect(BreakingThreadFigure.poids(2 * m) / BreakingThreadFigure.poids(m),
            closeTo(2, 1e-9),
            reason: 'masse $m');
      }
    });

    test('le fil cède exactement à cinq virgule un kilos', () {
      expect(BreakingThreadFigure.masseDeRupture(), closeTo(5.102, 0.001));
      expect(BreakingThreadFigure.casse(5.0), isFalse);
      expect(BreakingThreadFigure.casse(5.2), isTrue);
    });

    test('le seuil est le même que celui annoncé par la charge', () {
      // On le retrouve par balayage, sans réutiliser la formule : le seuil
      // observé doit coïncider avec la charge de rupture divisée par g.
      double? premierQuiCasse;
      for (double m = 0.1; m <= 10; m += 0.001) {
        if (BreakingThreadFigure.casse(m)) {
          premierQuiCasse = m;
          break;
        }
      }
      expect(premierQuiCasse, isNotNull);
      expect(premierQuiCasse!, closeTo(BreakingThreadFigure.masseDeRupture(), 0.002));
      expect(
        BreakingThreadFigure.poids(premierQuiCasse),
        greaterThan(BreakingThreadFigure.chargeDeRupture),
      );
    });

    test('le seuil tombe au milieu de la course du curseur', () {
      // C'est une exigence pédagogique, pas physique : l'élève doit pouvoir
      // l'approcher des deux côtés. Un seuil à 9,8 kg sur une course de 10
      // ne se laisserait pas encadrer.
      final double seuil = BreakingThreadFigure.masseDeRupture();
      expect(seuil, greaterThan(BreakingThreadFigure.masseMax * 0.3));
      expect(seuil, lessThan(BreakingThreadFigure.masseMax * 0.7));
    });

    test('l’allongement croît avec la masse et sature à la rupture', () {
      expect(BreakingThreadFigure.allongement(0.5), lessThan(0.15));
      expect(BreakingThreadFigure.allongement(5.0), greaterThan(0.95));
      expect(BreakingThreadFigure.allongement(8.0), 1.0);
      // Strictement croissant tant que le fil tient.
      double precedent = -1;
      for (double m = 0.5; m <= 5.0; m += 0.1) {
        final double a = BreakingThreadFigure.allongement(m);
        expect(a, greaterThan(precedent), reason: 'masse $m');
        precedent = a;
      }
    });
  });

  group('La manipulation', () {
    Widget monter() => const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BreakingThreadFigure(accent: Colors.blue),
            ),
          ),
        );

    testWidgets('le fil tient tant qu’on reste sous le seuil', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(monter());
      expect(find.textContaining('Le fil tient'), findsOneWidget);
      expect(find.text('Renouer le fil'), findsNothing);
    });

    testWidgets('pousser le curseur à fond rompt le fil', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(monter());
      final Finder curseur = find.byType(Slider);
      // On attrape le curseur et on le pousse jusqu'au bout.
      await tester.drag(curseur, const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.textContaining('a cédé'), findsOneWidget);
      expect(find.text('Renouer le fil'), findsOneWidget);
      // Le curseur est désactivé : on ne remonte pas un fil rompu.
      expect(tester.widget<Slider>(curseur).onChanged, isNull);
    });

    testWidgets('renouer remet tout à l’état de départ', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(monter());
      await tester.drag(find.byType(Slider), const Offset(500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Renouer le fil'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Le fil tient'), findsOneWidget);
      expect(find.text('Renouer le fil'), findsNothing);
      expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNotNull);
    });

    testWidgets('la formule affichée suit la masse', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(monter());
      // À l'ouverture, deux kilogrammes.
      expect(find.textContaining('P = 2 × 9,8'), findsOneWidget);
    });
  });
}
