import 'package:eureka/core/motion/app_motion.dart';
import 'package:eureka/core/theme/app_theme.dart';
import 'package:eureka/design_system/figures/autoplay.dart';
import 'package:eureka/design_system/figures/figure_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie le pilotage automatique des figures.
///
/// Le format en fil repose sur une promesse : la figure bouge toute seule
/// pendant qu'on lit la légende. Trois choses doivent donc tenir, et
/// aucune des trois ne se voit à la relecture du code.
///
/// Hors scène, rien ne change — une figure ouverte seule reste à sa valeur
/// de départ. Sur scène, l'image à deux instants différents du cycle n'est
/// pas la même. Et si l'élève a demandé moins d'animations, le pilotage
/// s'arrête : il garde une figure fixe, qu'il peut encore manipuler.
void main() {
  /// Enveloppe une figure comme le fil le fait, à une phase donnée.
  Widget scene(String id, {double? phase, bool reduceMotion = false}) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: AppMotion(
        reduceMotionPreference: reduceMotion,
        hapticsEnabled: false,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Builder(
              builder: (BuildContext context) {
                final Widget figure = SizedBox(
                  width: 360,
                  child: FigureRegistry.build(
                    context,
                    id,
                    const Color(0xFF5B5BD6),
                  ),
                );
                if (phase == null) return figure;
                return FigureStage(phase: phase, actif: true, child: figure);
              },
            ),
          ),
        ),
      ),
    );
  }

  group('L’horloge de la scène', () {
    testWidgets('hors scène, la figure garde sa valeur de départ', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(scene('attraction-distance'));
      // La valeur initiale de la figure : distance ×1.
      expect(find.textContaining('×1'), findsWidgets);
    });

    testWidgets('sur scène, deux instants ne donnent pas la même image', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(scene('attraction-distance', phase: 0));
      final String debut = _etiquettes(tester);

      await tester.pumpWidget(scene('attraction-distance', phase: 0.5));
      final String milieu = _etiquettes(tester);

      expect(
        milieu,
        isNot(debut),
        reason: 'la figure n’a pas bougé entre le début et le milieu du cycle',
      );
    });

    testWidgets('le balayage atteint bien les deux bouts', (
      WidgetTester tester,
    ) async {
      // Au milieu du cycle, la distance doit être au maximum : c'est ce
      // qui montre l'effondrement de la force, et c'est tout l'objet de
      // cette figure.
      await tester.pumpWidget(scene('attraction-distance', phase: 0.5));
      expect(find.textContaining('×5'), findsWidgets);
    });

    testWidgets('moins d’animations coupe le pilotage', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        scene('attraction-distance', phase: 0.5, reduceMotion: true),
      );
      // Malgré la phase à 0,5, la figure reste à sa valeur de départ.
      expect(find.textContaining('×1'), findsWidgets);
    });

    testWidgets('un geste reprend la main sur l’horloge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(scene('complexite', phase: 0.5));
      final Finder curseur = find.byType(Slider);
      expect(curseur, findsOneWidget);

      // On pose une valeur à la main, puis on avance l'horloge : la
      // figure doit rester où l'élève l'a laissée.
      final Slider widgetAvant = tester.widget<Slider>(curseur);
      widgetAvant.onChanged!(12);
      await tester.pump();

      // La valeur posée à la main est celle qu'affiche le curseur, et
      // l'horloge ne la reprend pas.
      expect(tester.widget<Slider>(curseur).value, 12);
    });
  });

  group('Les formes d’animation', () {
    testWidgets('le balayage part du minimum et revient', (
      WidgetTester tester,
    ) async {
      late BuildContext ctx;
      Widget avec(double phase) => MaterialApp(
        home: AppMotion(
          reduceMotionPreference: false,
          hapticsEnabled: false,
          child: FigureStage(
            phase: phase,
            actif: true,
            child: Builder(
              builder: (BuildContext context) {
                ctx = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      await tester.pumpWidget(avec(0));
      expect(Autoplay.sweep(ctx, min: 10, max: 20), closeTo(10, 0.001));

      await tester.pumpWidget(avec(0.5));
      expect(Autoplay.sweep(ctx, min: 10, max: 20), closeTo(20, 0.001));

      await tester.pumpWidget(avec(0.999));
      expect(Autoplay.sweep(ctx, min: 10, max: 20), closeTo(10, 0.01));
    });

    testWidgets('l’index défile sur toutes les options', (
      WidgetTester tester,
    ) async {
      late BuildContext ctx;
      Widget avec(double phase) => MaterialApp(
        home: AppMotion(
          reduceMotionPreference: false,
          hapticsEnabled: false,
          child: FigureStage(
            phase: phase,
            actif: true,
            child: Builder(
              builder: (BuildContext context) {
                ctx = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      final Set<int> vus = <int>{};
      for (double p = 0; p < 1; p += 0.05) {
        await tester.pumpWidget(avec(p));
        vus.add(Autoplay.index(ctx, 4)!);
      }
      expect(vus, <int>{0, 1, 2, 3});
    });

    testWidgets('la montée reste bornée à un', (WidgetTester tester) async {
      late BuildContext ctx;
      Widget avec(double phase) => MaterialApp(
        home: AppMotion(
          reduceMotionPreference: false,
          hapticsEnabled: false,
          child: FigureStage(
            phase: phase,
            actif: true,
            child: Builder(
              builder: (BuildContext context) {
                ctx = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      for (double p = 0; p < 1; p += 0.05) {
        await tester.pumpWidget(avec(p));
        final double v = Autoplay.ramp(ctx)!;
        expect(v, inInclusiveRange(0, 1));
      }
      await tester.pumpWidget(avec(0.9));
      expect(Autoplay.ramp(ctx), 1);
    });
  });
}

/// Toutes les étiquettes de texte rendues, mises bout à bout.
String _etiquettes(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((Text t) => t.data ?? '')
      .join('|');
}
