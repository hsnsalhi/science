import 'dart:math' as math;

import 'package:eureka/design_system/figures/atom_models_figure.dart';
import 'package:eureka/design_system/figures/root_two_figure.dart';
import 'package:eureka/design_system/figures/rutherford_figure.dart';
import 'package:eureka/design_system/figures/swan_neck_figure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les figures des chapitres d'histoire des sciences.
///
/// Elles promettent de montrer de la physique, pas une jolie courbe. Les
/// tests recalculent donc ce que la figure affiche, par un chemin qui
/// n'emprunte pas le sien.
void main() {
  group('Rutherford : la diffusion par un noyau', () {
    test('la formule et l’hyperbole tracée donnent le même angle', () {
      for (final double b in <double>[0.1, 0.25, 0.5, 1, 1.6, 2, 3]) {
        expect(
          RutherfordFigure.deviationTracee(b),
          closeTo(RutherfordFigure.deviationDegres(b), 0.5),
          reason: 'visée $b',
        );
      }
    });

    test('une intégration indépendante du mouvement les confirme', () {
      // Ce témoin n'utilise ni la formule ni l'orbite : il lâche la
      // particule loin du noyau et la laisse être repoussée en 1/r². Si
      // les trois convergent, la figure montre de la physique.
      for (final double b in <double>[0.25, 0.5, 1, 1.6, 3]) {
        expect(
          RutherfordFigure.deviationIntegree(b),
          closeTo(RutherfordFigure.deviationDegres(b), 1.5),
          reason: 'visée $b',
        );
      }
    });

    test('viser le noyau renvoie la particule en arrière', () {
      expect(RutherfordFigure.deviationDegres(0.01), greaterThan(170));
      expect(RutherfordFigure.deviationDegres(0.5), closeTo(90, 0.01));
      // Et viser loin ne la dévie presque pas : c'est le cas de la
      // quasi-totalité des tirs, et ce que Thomson prévoyait pour tous.
      expect(RutherfordFigure.deviationDegres(20), lessThan(3));
      expect(RutherfordFigure.deviationDegres(200), lessThan(0.3));
    });

    test('la déviation décroît sans exception quand on vise plus loin', () {
      double precedent = 181;
      for (double b = 0.05; b <= 3.0001; b += 0.05) {
        final double angle = RutherfordFigure.deviationDegres(b);
        expect(angle, lessThan(precedent), reason: 'visée $b');
        precedent = angle;
      }
    });

    test('la rareté du rebond suit le carré de la visée', () {
      // Diviser la visée par deux rend le tir quatre fois plus rare.
      final int large = RutherfordFigure.tirsPourUnRebond(2);
      final int serre = RutherfordFigure.tirsPourUnRebond(1);
      expect(serre, closeTo(large * 4, 1));
    });

    test('la trajectoire arrive à l’horizontale, à la hauteur visée', () {
      for (final double b in <double>[0.5, 1.5, 2.5]) {
        final List<Offset> points = RutherfordFigure.trajectoire(b);
        final Offset arrivee = points[1] - points[0];
        expect(
          math.atan2(arrivee.dy, arrivee.dx).abs() * 180 / math.pi,
          lessThan(4),
          reason: 'la branche d’arrivée doit être presque horizontale',
        );
        expect(points.first.dy, closeTo(b, b * 0.08),
            reason: 'elle arrive à la hauteur de la visée');
        expect(points.first.dx, lessThan(0),
            reason: 'elle arrive par la gauche');
      }
    });
  });

  group('Pasteur : le ballon à col de cygne', () {
    test('seul le col de cygne intact garde le bouillon limpide', () {
      expect(MontagePasteur.ouvert.seTrouble, isTrue);
      expect(MontagePasteur.colDeCygne.seTrouble, isFalse);
      expect(MontagePasteur.penche.seTrouble, isTrue);
    });

    test('rien ne se voit au premier jour, dans aucun montage', () {
      // C'est le piège de l'expérience : conclure le lendemain.
      for (final MontagePasteur montage in MontagePasteur.values) {
        expect(SwanNeckFigure.trouble(montage, 0.5), lessThan(0.05),
            reason: montage.name);
      }
    });

    test('le col de cygne reste limpide jusqu’au bout', () {
      for (double j = 0; j <= SwanNeckFigure.joursMax; j += 0.25) {
        expect(SwanNeckFigure.trouble(MontagePasteur.colDeCygne, j), 0);
      }
    });

    test('le trouble ne recule jamais et finit opaque', () {
      double precedent = -1;
      for (double j = 0; j <= SwanNeckFigure.joursMax; j += 0.25) {
        final double t = SwanNeckFigure.trouble(MontagePasteur.ouvert, j);
        expect(t, greaterThanOrEqualTo(precedent), reason: 'jour $j');
        precedent = t;
      }
      expect(precedent, closeTo(1, 0.001));
    });

    test('la pousse s’emballe : le milieu de la courbe est le plus raide',
        () {
      // Une culture double à chaque division ; sa courbe est en S, pas une
      // rampe. On le vérifie en comparant les pentes, sans relire la
      // formule : la plus forte doit tomber au milieu, pas au début.
      double penteMax = -1;
      double jourDeLaPenteMax = -1;
      for (double j = 0; j < SwanNeckFigure.joursMax; j += 0.05) {
        final double pente =
            SwanNeckFigure.trouble(MontagePasteur.ouvert, j + 0.05) -
                SwanNeckFigure.trouble(MontagePasteur.ouvert, j);
        if (pente > penteMax) {
          penteMax = pente;
          jourDeLaPenteMax = j;
        }
      }
      expect(jourDeLaPenteMax, greaterThan(1.2));
      expect(jourDeLaPenteMax, lessThan(3.2));
    });
  });

  group('L’atome : quatre modèles et une échelle', () {
    test('chaque modèle porte la mesure qui l’a mis en défaut', () {
      for (final ModeleAtome modele in ModeleAtome.values) {
        expect(modele.faille.length, greaterThan(20), reason: modele.name);
        expect(modele.idee.length, greaterThan(40), reason: modele.name);
      }
    });

    test('à l’échelle réelle, le noyau devient cent mille fois plus petit',
        () {
      const double rayonAtome = 100;
      expect(
        AtomModelsFigure.rayonNoyau(rayonAtome, 1),
        closeTo(rayonAtome / AtomModelsFigure.rapportAtomeNoyau, 1e-9),
      );
      // Et sur un schéma de manuel il est dix fois plus petit que l'atome,
      // soit dix mille fois trop gros.
      expect(AtomModelsFigure.rayonNoyau(rayonAtome, 0), rayonAtome * 0.1);
    });

    test('le noyau ne fait que rétrécir quand on va vers l’honnêteté', () {
      double precedent = double.infinity;
      for (double f = 0; f <= 1.0001; f += 0.02) {
        final double r = AtomModelsFigure.rayonNoyau(100, f);
        expect(r, lessThan(precedent), reason: 'fidélité $f');
        precedent = r;
      }
    });

    test('l’agrandissement affiché va de 1 au rapport réel', () {
      expect(AtomModelsFigure.agrandissement(0), 1);
      expect(
        AtomModelsFigure.agrandissement(1),
        closeTo(AtomModelsFigure.rapportAtomeNoyau / 10, 1),
      );
    });
  });

  group('Racine de deux : la fraction qui n’arrive jamais', () {
    test('aucun dénominateur ne donne un écart nul', () {
      // La démonstration dit « jamais » ; le test ne peut dire que
      // « jamais sur dix mille », mais il le dit sans relire la preuve.
      for (int q = 1; q <= 10000; q++) {
        expect(RootTwoFigure.ecart(q), isNot(0), reason: 'q = $q');
      }
    });

    test('les réduites sont les meilleures approximations de leur taille',
        () {
      for (final (int p, int q) in RootTwoFigure.reduites()) {
        final double erreur = (p / q - math.sqrt2).abs();
        for (int autre = 1; autre < q; autre++) {
          final int meilleur = RootTwoFigure.meilleurNumerateur(autre);
          expect(
            (meilleur / autre - math.sqrt2).abs(),
            greaterThan(erreur),
            reason: '$meilleur/$autre bat $p/$q',
          );
        }
      }
    });

    test('les réduites suivent bien la récurrence de Pell', () {
      final List<(int, int)> suite = RootTwoFigure.reduites(combien: 6);
      expect(suite.first, (1, 1));
      expect(suite[1], (3, 2));
      expect(suite[2], (7, 5));
      expect(suite[3], (17, 12));
      // Et l'écart de ces fractions vaut toujours exactement plus ou
      // moins un : c'est l'équation de Pell, et c'est ce que la figure
      // montre à l'élève sans la nommer.
      for (final (int _, int q) in suite) {
        expect(RootTwoFigure.ecart(q).abs(), 1, reason: 'q = $q');
      }
    });

    test('l’erreur diminue sans jamais s’annuler', () {
      double precedent = 1;
      for (final (int p, int q) in RootTwoFigure.reduites()) {
        final double erreur = (p / q - math.sqrt2).abs();
        expect(erreur, lessThan(precedent));
        expect(erreur, greaterThan(0));
        precedent = erreur;
      }
      // Huit réduites suffisent à descendre sous le millionième : la
      // huitième est 577/408, et son erreur vaut environ deux
      // millionièmes.
      expect(precedent, lessThan(1e-5));
    });
  });

  group('La manipulation', () {
    testWidgets('le ballon se trouble quand on avance les jours', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SwanNeckFigure(accent: Colors.blue),
            ),
          ),
        ),
      );
      expect(find.textContaining('stérile'), findsOneWidget);

      final Finder curseur = find.byType(Slider);
      await tester.drag(curseur, const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('poussière'), findsWidgets);
    });

    testWidgets('changer de montage refait l’expérience à zéro', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SwanNeckFigure(accent: Colors.blue),
            ),
          ),
        ),
      );
      await tester.drag(find.byType(Slider), const Offset(500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Col de cygne'));
      await tester.pumpAndSettle();
      expect(find.textContaining('stérile'), findsOneWidget);
    });

    testWidgets('l’échelle n’apparaît que pour les modèles à noyau', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AtomModelsFigure(accent: Colors.blue),
            ),
          ),
        ),
      );
      expect(find.byType(Slider), findsNothing);
      await tester.tap(find.text('Rutherford'));
      // Les électrons tournent sans fin : `pumpAndSettle` attendrait une
      // immobilité qui ne vient jamais.
      await tester.pump();
      expect(find.byType(Slider), findsOneWidget);
      await tester.tap(find.text('Thomson'));
      await tester.pump();
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('le bouton mène à la réduite suivante', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RootTwoFigure(accent: Colors.blue),
            ),
          ),
        ),
      );
      expect(find.textContaining('1 / 1'), findsOneWidget);
      await tester.tap(find.text('Sauter à la meilleure suivante'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 / 2'), findsOneWidget);
      await tester.tap(find.text('Sauter à la meilleure suivante'));
      await tester.pumpAndSettle();
      expect(find.textContaining('7 / 5'), findsOneWidget);
    });
  });
}
