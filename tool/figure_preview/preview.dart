/// Rend une figure seule en PNG, pour la regarder pendant qu'on l'écrit.
///
/// Les captures de référence passent par l'application entière, ce qui est
/// juste pour une capture de boutique mais trop lent pour mettre au point un
/// dessin : il faut naviguer jusqu'au bon chapitre à chaque essai. Ce banc
/// monte la figure seule, sur fond de thème réel, et écrit le fichier.
///
///     flutter test tool/figure_preview/preview.dart --update-goldens
///
/// Les images sortent dans `tool/figure_preview/out/`, qui n'est pas
/// versionné : ce sont des brouillons de travail, pas des références.
library;

import 'dart:io';

import 'package:eureka/core/theme/app_theme.dart';
import 'package:eureka/core/theme/app_typography.dart';
import 'package:eureka/design_system/figures/figure_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les figures à rendre, et sous quel thème.
const List<String> _figures = <String>[
  'fil-qui-casse',
  'attraction-distance',
  'col-de-cygne',
  'rutherford',
  'modeles-atome',
  'racine-de-deux',
  'frise-nombres',
  'tiroirs',
  'reseau-paquet',
  'tableur',
  'solides-perspective',
  'trigonometrie',
  'onde',
  'spectre-etoile',
  'selection',
  'droite-graduee',
  'horloge',
  'demi-vie',
  'ombre-lumiere',
  'volcan',
  'canon-newton',
  'poids-astres',
  'eclipses',
  'approvisionnement',
  'phases-lune',
  'balance-equation',
  'pile-file',
  'distributivite',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Sans chargement explicite, le moteur de test dessine chaque mot en
  // rectangle gris : les polices déclarées dans pubspec ne sont pas
  // montées d'office. On regarde ce banc pour juger un dessin, et un
  // dessin se juge avec ses étiquettes — d'autant qu'un caractère
  // absent des polices se voit ici exactement comme chez l'élève.
  setUpAll(() async {
    for (final String famille in <String>[
      AppTypography.body,
      AppTypography.display,
      ...AppTypography.replis,
    ]) {
      await (FontLoader(famille)
            ..addFont(rootBundle.load('assets/fonts/$famille.ttf')))
          .load();
    }
  });

  for (final String id in _figures) {
    for (final (String nom, Brightness clarte) in <(String, Brightness)>[
      ('clair', Brightness.light),
      ('sombre', Brightness.dark),
    ]) {
      testWidgets('$id — $nom', (WidgetTester tester) async {
        // Haut : certaines figures dépassent 500 points de haut, et dans
        // l'application elles vivent dans une carte défilante. Un banc
        // trop court les ferait déborder sans que ce soit leur faute.
        tester.view
          ..physicalSize = const Size(840, 1500)
          ..devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: clarte == Brightness.light
                ? AppTheme.light()
                : AppTheme.dark(),
            home: Builder(
              builder: (BuildContext context) => Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: FigureRegistry.build(
                      context,
                      id,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        // Certaines figures tournent en boucle — une Lune qui orbite ne
        // s'arrête jamais — donc pumpAndSettle n'y converge pas. On avance
        // d'un nombre fixe d'images : c'est reproductible, et cela suffit
        // à laisser les animations d'entrée se poser.
        for (int i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 60));
        }
        // Les figures animées sont avancées plus loin pour sortir de leur
        // état initial, qui est souvent le moins parlant — la figure des
        // phases s'ouvre sur la nouvelle lune, c'est-à-dire un disque noir.
        for (int i = 0; i < 90; i++) {
          await tester.pump(const Duration(milliseconds: 60));
        }

        Directory('tool/figure_preview/out').createSync(recursive: true);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('out/$id-$nom.png'),
        );
      });
    }
  }
}
