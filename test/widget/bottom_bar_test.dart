import 'package:eureka/core/theme/app_theme.dart';
import 'package:eureka/design_system/app_button.dart';
import 'package:eureka/design_system/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La barre basse doit rester atteignable quand le clavier est ouvert.
///
/// Le `Scaffold` de Flutter ne remonte pas sa `bottomNavigationBar` à
/// l'ouverture du clavier : il redimensionne le corps et laisse la barre
/// collée au bas de l'écran, donc dessous. Sur une question à saisie
/// numérique, le bouton « Valider » devenait inatteignable — et le pavé
/// numérique d'iOS n'ayant pas de touche de retour, l'écran n'offrait plus
/// aucune sortie.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const double hauteurClavier = 336;

  Widget ecran({required double clavier}) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          viewInsets: EdgeInsets.only(bottom: clavier),
        ),
        child: AppScaffold(
          title: 'Exercice',
          body: const SizedBox(height: 2000),
          bottomBar: AppButton(label: 'Valider', onPressed: () {}),
        ),
      ),
    );
  }

  testWidgets('le bouton de la barre basse reste au-dessus du clavier', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ecran(clavier: hauteurClavier));
    await tester.pumpAndSettle();

    final Rect bouton = tester.getRect(find.text('Valider'));
    expect(
      bouton.bottom,
      lessThanOrEqualTo(844 - hauteurClavier),
      reason: 'le bouton passe sous le clavier : écran sans issue',
    );
  });

  testWidgets('sans clavier, la barre basse reste collée en bas', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ecran(clavier: 0));
    await tester.pumpAndSettle();

    // Aucun vide ajouté quand il n'y a pas de clavier : le bouton touche
    // le bas de l'écran, à la marge de la barre près.
    final Rect bouton = tester.getRect(find.text('Valider'));
    expect(bouton.bottom, greaterThan(844 - 120));
  });
}
