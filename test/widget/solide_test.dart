import 'dart:math' as math;

import 'package:eureka/design_system/figures/solid_figure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le solide en perspective cavalière.
///
/// Les tests refont la géométrie plutôt que de relire la figure : la
/// projection est vérifiée sur ses deux promesses — la face avant intacte,
/// le parallélisme conservé — et les comptes de faces, arêtes et sommets
/// sont recomptés à partir des listes de points et de segments.
void main() {
  group('La projection cavalière', () {
    test('la face avant n’est jamais déplacée', () {
      // Tout point de profondeur nulle doit se projeter sur lui-même,
      // quels que soient l’angle et la réduction. C’est la définition.
      for (double angle = 15; angle <= 75; angle += 5) {
        for (double fuite = 0.25; fuite <= 1.0001; fuite += 0.25) {
          for (final (double, double, double) p
              in <(double, double, double)>[
            (0, 0, 0),
            (1, 0, 0),
            (0.5, 0.75, 0),
          ]) {
            final (double x, double y) = SolidFigure.projeter(
              p,
              angleDegres: angle,
              fuite: fuite,
            );
            expect(x, closeTo(p.$1, 1e-12), reason: 'angle $angle');
            expect(y, closeTo(p.$2, 1e-12), reason: 'fuite $fuite');
          }
        }
      }
    });

    test('la profondeur part toujours dans la même direction', () {
      // Deux arêtes fuyantes du cube doivent rester parallèles sur le
      // dessin : c’est ce qui distingue une perspective cavalière d’une
      // perspective à point de fuite.
      const double angle = 40;
      const double fuite = 0.6;
      final List<Offset> deplacements = <Offset>[];
      for (final (double, double, double) base
          in <(double, double, double)>[(0, 0, 0), (1, 0, 0), (1, 1, 0)]) {
        final (double x0, double y0) =
            SolidFigure.projeter(base, angleDegres: angle, fuite: fuite);
        final (double x1, double y1) = SolidFigure.projeter(
          (base.$1, base.$2, 1),
          angleDegres: angle,
          fuite: fuite,
        );
        deplacements.add(Offset(x1 - x0, y1 - y0));
      }
      for (final Offset d in deplacements) {
        expect(d.dx, closeTo(deplacements.first.dx, 1e-12));
        expect(d.dy, closeTo(deplacements.first.dy, 1e-12));
      }
    });

    test('la réduction agit bien sur la seule profondeur', () {
      const (double, double, double) p = (0.2, 0.3, 1);
      final (double, double) pleine =
          SolidFigure.projeter(p, angleDegres: 45, fuite: 1);
      final (double, double) moitie =
          SolidFigure.projeter(p, angleDegres: 45, fuite: 0.5);
      // L’écart à la face avant est divisé par deux, dans les deux
      // directions à la fois.
      expect(moitie.$1 - p.$1, closeTo((pleine.$1 - p.$1) / 2, 1e-12));
      expect(moitie.$2 - p.$2, closeTo((pleine.$2 - p.$2) / 2, 1e-12));
    });

    test('un angle de 45 degrés répartit également la fuyante', () {
      final (double x, double y) = SolidFigure.projeter(
        (0, 0, 1),
        angleDegres: 45,
        fuite: 1,
      );
      expect(x, closeTo(y, 1e-12));
      expect(x, closeTo(math.sqrt1_2, 1e-12));
    });
  });

  group('Les solides', () {
    test('les comptes annoncés sont ceux des listes de points et d’arêtes',
        () {
      for (final SolideUsuel s in SolideUsuel.values) {
        expect(s.points.length, s.sommets, reason: '${s.nom} : sommets');
        expect(s.segments.length, s.aretes, reason: '${s.nom} : arêtes');
      }
    });

    test('la relation d’Euler vaut 2 sur les quatre', () {
      for (final SolideUsuel s in SolideUsuel.values) {
        expect(s.euler, 2, reason: s.nom);
      }
    });

    test('aucune arête ne relie un sommet à lui-même, ni n’est répétée', () {
      for (final SolideUsuel s in SolideUsuel.values) {
        final Set<String> vues = <String>{};
        for (final (int a, int b) in s.segments) {
          expect(a, isNot(b), reason: '${s.nom} : arête dégénérée');
          expect(a, lessThan(s.points.length), reason: s.nom);
          expect(b, lessThan(s.points.length), reason: s.nom);
          final String cle = '${math.min(a, b)}-${math.max(a, b)}';
          expect(vues.add(cle), isTrue, reason: '${s.nom} : arête en double');
        }
      }
    });

    test('chaque sommet porte au moins trois arêtes', () {
      // Un sommet de solide est la rencontre d’au moins trois faces, donc
      // d’au moins trois arêtes. Un sommet moins relié signalerait une
      // liste incomplète.
      for (final SolideUsuel s in SolideUsuel.values) {
        final List<int> degres = List<int>.filled(s.points.length, 0);
        for (final (int a, int b) in s.segments) {
          degres[a]++;
          degres[b]++;
        }
        for (int i = 0; i < degres.length; i++) {
          expect(degres[i], greaterThanOrEqualTo(3),
              reason: '${s.nom} : sommet $i');
        }
      }
    });

    test('les arêtes cachées désignent des arêtes qui existent', () {
      for (final SolideUsuel s in SolideUsuel.values) {
        expect(s.cachees.toSet().length, s.cachees.length,
            reason: '${s.nom} : doublon');
        for (final int i in s.cachees) {
          expect(i, lessThan(s.segments.length), reason: s.nom);
        }
        expect(s.cachees.length, lessThan(s.segments.length),
            reason: '${s.nom} : tout serait caché');
      }
    });
  });

  group('La manipulation', () {
    testWidgets('changer de solide change les comptes affichés', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SolidFigure(accent: Colors.blue),
            ),
          ),
        ),
      );
      expect(find.textContaining('6 faces'), findsOneWidget);
      await tester.tap(find.text('Pyramide'));
      await tester.pumpAndSettle();
      expect(find.textContaining('5 faces'), findsOneWidget);
      expect(find.textContaining('8 arêtes'), findsOneWidget);
    });

    testWidgets('la relation d’Euler s’affiche et vaut 2', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SolidFigure(accent: Colors.blue),
            ),
          ),
        ),
      );
      for (final String nom in <String>['Pavé droit', 'Pyramide', 'Prisme']) {
        await tester.tap(find.text(nom));
        await tester.pumpAndSettle();
        expect(find.textContaining('= 2'), findsOneWidget, reason: nom);
      }
    });

    testWidgets('on peut masquer les arêtes cachées', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SolidFigure(accent: Colors.blue),
            ),
          ),
        ),
      );
      final Finder bascule = find.byType(SwitchListTile);
      expect(tester.widget<SwitchListTile>(bascule).value, isTrue);
      await tester.tap(bascule);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(bascule).value, isFalse);
    });
  });
}
