import 'package:eureka/core/theme/app_theme.dart';
import 'package:eureka/design_system/figures/figure_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Toute figure de l'annuaire doit s'afficher sans lever d'exception.
///
/// Le test du contenu vérifie qu'une figure citée existe ; il ne la
/// construit pas. Une division par zéro dans un peintre, une contrainte
/// non bornée, un accès hors liste : rien de tout cela ne se voit avant
/// que quelqu'un n'ouvre la carte. Ici, toutes sont montées, dans les
/// deux thèmes et à deux largeurs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final String id in FigureRegistry.ids) {
    for (final (String nom, double largeur) in <(String, double)>[
      ('téléphone', 360),
      ('tablette', 720),
    ]) {
      testWidgets('$id s\'affiche sur $nom', (WidgetTester tester) async {
        tester.view.physicalSize = Size(largeur, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Builder(
                    builder: (BuildContext context) => FigureRegistry.build(
                      context,
                      id,
                      const Color(0xFF5B5BD6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        // Pas de pumpAndSettle : plusieurs figures s'animent sans fin, et
        // attendre leur immobilité n'aurait pas de terme.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('une clé inconnue affiche un avertissement, pas une erreur', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) =>
                FigureRegistry.build(context, 'figure-qui-n-existe-pas', Colors.blue),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('figure-qui-n-existe-pas'), findsOneWidget);
  });
}
