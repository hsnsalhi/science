import 'package:eureka/core/theme/app_theme.dart';
import 'package:eureka/design_system/figures/figure_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie que toute figure inscrite au registre se dessine vraiment.
///
/// Le test du contenu garantit déjà qu'une `figureId` citée existe ; il reste
/// à garantir l'inverse, que la figure inscrite se construise sans exception.
/// Une figure qui lève en pleine leçon est pire qu'une figure absente.
void main() {
  for (final String id in FigureRegistry.ids) {
    testWidgets('la figure « $id » se construit et se repeint', (
      WidgetTester tester,
    ) async {
      for (final ThemeData theme in <ThemeData>[
        AppTheme.light(),
        AppTheme.dark(),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Builder(
                    builder: (BuildContext context) =>
                        FigureRegistry.build(context, id, Colors.indigo),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Les figures sont manipulables : on déplace le curseur pour forcer
        // un second rendu, celui que l'élève déclenche en premier.
        final Finder slider = find.byType(Slider);
        if (slider.evaluate().isNotEmpty) {
          await tester.drag(slider.first, const Offset(40, 0));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    });
  }
}
