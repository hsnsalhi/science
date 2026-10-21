import 'package:eureka/design_system/figures/network_figure.dart';
import 'package:eureka/design_system/figures/pigeonhole_figure.dart';
import 'package:eureka/design_system/figures/spreadsheet_figure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les figures ajoutées pour les chapitres du collège.
///
/// Chaque test refait le calcul par un chemin qui n'emprunte pas celui de
/// la figure : le routage est comparé à une énumération exhaustive des
/// chemins, et les totaux du tableur à une somme écrite à part.
void main() {
  group('Le réseau : couper un câble ne coupe pas la liaison', () {
    /// Tous les chemins simples, énumérés sans la moindre idée de ce qui
    /// est court. C'est le témoin du parcours en largeur.
    List<List<int>> tousLesChemins(Set<int> coupes) {
      final Map<int, List<int>> voisins = <int, List<int>>{};
      for (int i = 0; i < NetworkFigure.liens.length; i++) {
        if (coupes.contains(i)) continue;
        final (int a, int b) = NetworkFigure.liens[i];
        voisins.putIfAbsent(a, () => <int>[]).add(b);
        voisins.putIfAbsent(b, () => <int>[]).add(a);
      }
      final List<List<int>> trouves = <List<int>>[];
      void explorer(List<int> courant) {
        if (courant.last == 6) {
          trouves.add(List<int>.of(courant));
          return;
        }
        for (final int suivant in voisins[courant.last] ?? const <int>[]) {
          if (courant.contains(suivant)) continue;
          explorer(<int>[...courant, suivant]);
        }
      }

      explorer(<int>[0]);
      return trouves;
    }

    test('le chemin trouvé est bien le plus court', () {
      // On essaie toutes les combinaisons de zéro à deux câbles coupés.
      final int n = NetworkFigure.liens.length;
      for (int a = -1; a < n; a++) {
        for (int b = a; b < n; b++) {
          final Set<int> coupes = <int>{if (a >= 0) a, if (b >= 0) b};
          final List<List<int>> tous = tousLesChemins(coupes);
          final List<int> trouve = NetworkFigure.chemin(coupes);
          if (tous.isEmpty) {
            expect(trouve, isEmpty, reason: 'coupes $coupes');
            continue;
          }
          final int mini = tous
              .map((List<int> c) => c.length)
              .reduce((int x, int y) => x < y ? x : y);
          expect(trouve.length, mini, reason: 'coupes $coupes');
        }
      }
    });

    test('le chemin n’emprunte jamais un câble coupé', () {
      for (int i = 0; i < NetworkFigure.liens.length; i++) {
        final Set<int> coupes = <int>{i};
        final List<int> route = NetworkFigure.chemin(coupes);
        for (int k = 0; k + 1 < route.length; k++) {
          final int x = route[k];
          final int y = route[k + 1];
          final int lien = NetworkFigure.liens.indexWhere(
            ((int, int) l) => (l.$1 == x && l.$2 == y) || (l.$1 == y && l.$2 == x),
          );
          expect(lien, isNot(-1), reason: 'saut $x vers $y sans câble');
          expect(coupes.contains(lien), isFalse);
        }
      }
    });

    test('couper un seul câble ne coupe jamais la liaison', () {
      // C'est le propos du chapitre : la redondance tient à un câble près.
      for (int i = 0; i < NetworkFigure.liens.length; i++) {
        expect(NetworkFigure.chemin(<int>{i}), isNotEmpty, reason: 'câble $i');
      }
    });

    test('isoler le serveur demande de couper ses trois câbles', () {
      final List<int> versServeur = <int>[
        for (int i = 0; i < NetworkFigure.liens.length; i++)
          if (NetworkFigure.liens[i].$1 == 6 || NetworkFigure.liens[i].$2 == 6) i,
      ];
      expect(versServeur.length, 3);
      // Deux sur trois ne suffisent pas.
      for (int exclu = 0; exclu < 3; exclu++) {
        final Set<int> deux = <int>{
          for (int k = 0; k < 3; k++)
            if (k != exclu) versServeur[k],
        };
        expect(NetworkFigure.chemin(deux), isNotEmpty);
      }
      expect(NetworkFigure.chemin(versServeur.toSet()), isEmpty);
    });

    test('le nombre de sauts compte les câbles, pas les machines', () {
      final List<int> route = NetworkFigure.chemin(<int>{});
      expect(NetworkFigure.sauts(route), route.length - 1);
      expect(NetworkFigure.sauts(const <int>[]), 0);
    });
  });

  group('Le tableur : changer une case refait le reste', () {
    test('le total général est bien la somme des lignes', () {
      const List<double> prix = SpreadsheetFigure.prixDepart;
      const List<int> quantites = SpreadsheetFigure.quantitesDepart;
      double somme = 0;
      for (int i = 0; i < prix.length; i++) {
        somme += prix[i] * quantites[i];
      }
      expect(
        SpreadsheetFigure.totalGeneral(prix, quantites),
        closeTo(somme, 1e-9),
      );
      // 2,5×6 + 1,2×10 + 4×3 + 3,5×2 = 15 + 12 + 12 + 7 = 46
      expect(somme, closeTo(46, 1e-9));
    });

    test('ajouter un article change le total du prix de cet article', () {
      final List<double> prix = List<double>.of(SpreadsheetFigure.prixDepart);
      final List<int> avant =
          List<int>.of(SpreadsheetFigure.quantitesDepart);
      final double total = SpreadsheetFigure.totalGeneral(prix, avant);
      for (int i = 0; i < avant.length; i++) {
        final List<int> apres = List<int>.of(avant);
        apres[i] += 1;
        expect(
          SpreadsheetFigure.totalGeneral(prix, apres) - total,
          closeTo(prix[i], 1e-9),
          reason: 'ligne $i',
        );
      }
    });

    test('la première dépense est en ligne 2, pas en ligne 1', () {
      // L'en-tête occupe la ligne 1, et c'est l'erreur de référence la
      // plus banale quand on écrit sa première formule.
      expect(SpreadsheetFigure.nomCase(1, 0), 'B2');
      expect(SpreadsheetFigure.nomCase(2, 0), 'C2');
      expect(SpreadsheetFigure.nomCase(3, 3), 'D5');
    });
  });

  group('Les tiroirs', () {
    test('le minimum garanti est le quotient arrondi au-dessus', () {
      for (int objets = 1; objets <= 40; objets++) {
        for (int tiroirs = 1; tiroirs <= 12; tiroirs++) {
          final int garanti =
              PigeonholeFigure.minimumGaranti(objets, tiroirs);
          // Aucune répartition, si égale soit-elle, ne descend sous ce
          // nombre : on le vérifie sur la meilleure possible.
          final List<int> egale =
              PigeonholeFigure.repartitionLaPlusEgale(objets, tiroirs);
          expect(egale.reduce((int a, int b) => a > b ? a : b), garanti,
              reason: '$objets objets, $tiroirs tiroirs');
          expect(egale.fold<int>(0, (int a, int b) => a + b), objets);
        }
      }
    });

    test('aucune répartition au hasard ne bat la plus égale', () {
      for (int graine = 1; graine <= 200; graine++) {
        final List<int> tas =
            PigeonholeFigure.repartitionAuHasard(13, 12, graine);
        expect(tas.fold<int>(0, (int a, int b) => a + b), 13);
        expect(tas.reduce((int a, int b) => a > b ? a : b),
            greaterThanOrEqualTo(2));
      }
    });
  });

  group('La manipulation', () {
    testWidgets('couper assez de câbles isole le serveur', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NetworkFigure(accent: Colors.blue),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('sauts'), findsOneWidget);
      expect(find.text('Tout réparer'), findsNothing);
    });

    testWidgets('le tableur recalcule quand on règle une case', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpreadsheetFigure(accent: Colors.blue),
            ),
          ),
        ),
      );
      expect(find.textContaining('46'), findsOneWidget);
      await tester.drag(find.byType(Slider), const Offset(-500, 0));
      await tester.pumpAndSettle();
      // La quantité de cahiers tombe à zéro : 46 − 15 = 31.
      expect(find.textContaining('31'), findsOneWidget);
    });

    testWidgets('le tableur montre les formules à la demande', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpreadsheetFigure(accent: Colors.blue),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Formules'));
      await tester.pumpAndSettle();
      expect(find.text('Formules'), findsOneWidget);
    });

    testWidgets('les tiroirs annoncent le débordement', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PigeonholeFigure(accent: Colors.blue),
            ),
          ),
        ),
      );
      expect(find.textContaining('au moins 2'), findsOneWidget);
      // Moins d'objets que de tiroirs : plus de débordement garanti.
      await tester.drag(find.byType(Slider).first, const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('assez de tiroirs'), findsOneWidget);
    });
  });
}
