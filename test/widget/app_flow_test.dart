import 'dart:convert';

import 'package:eureka/app/app.dart';
import 'package:eureka/app/providers.dart';
import 'package:eureka/data/content/content_catalog.dart';
import 'package:eureka/data/content/content_loader.dart';
import 'package:eureka/data/local/key_value_store.dart';
import 'package:eureka/data/repositories/progress_repository.dart';
import 'package:eureka/data/repositories/settings_repository.dart';
import 'package:eureka/design_system/lesson_path.dart';
import 'package:eureka/domain/models/app_settings.dart';
import 'package:eureka/domain/models/education_level.dart';
import 'package:eureka/domain/models/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parcours d'utilisation, de l'onboarding à la fin d'une leçon.
///
/// Les réglages de départ désactivent les animations : c'est le réglage réel
/// de l'application pour un utilisateur qui le demande, et cela rend les
/// tests déterministes (aucune boucle infinie à attendre).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;

  setUpAll(() async {
    catalog = await ContentLoader().load();
  });

  /// Magasin préchargé avec des réglages sobres et, éventuellement, un profil
  /// ayant déjà terminé l'onboarding.
  InMemoryStore storeWith({bool onboarded = false}) {
    final Map<String, String> values = <String, String>{
      SettingsRepository.storageKey: jsonEncode(
        const AppSettings(reduceMotion: true, haptics: false).toJson(),
      ),
    };
    if (onboarded) {
      values[ProgressRepository.storageKey] = jsonEncode(
        const ProgressState(
          profile: LearnerProfile(
            firstName: 'Inès',
            level: EducationLevel.college,
            onboarded: true,
          ),
        ).toJson(),
      );
    }
    return InMemoryStore(values);
  }

  Future<InMemoryStore> boot(
    WidgetTester tester, {
    bool onboarded = false,
    Size size = const Size(420, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final InMemoryStore store = storeWith(onboarded: onboarded);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          contentCatalogProvider.overrideWithValue(catalog),
        ],
        child: const EurekaApp(),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  /// Tape sur un texte après l'avoir amené à l'écran.
  ///
  /// Les énoncés accompagnés d'une figure interactive peuvent repousser les
  /// propositions sous la ligne de flottaison : sans ce défilement, le test
  /// échouerait pour une raison sans rapport avec ce qu'il vérifie.
  Future<void> tapText(WidgetTester tester, String label) async {
    final Finder finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('l\'onboarding mène à l\'accueil personnalisé', (
    WidgetTester tester,
  ) async {
    await boot(tester);

    expect(find.text('Bienvenue dans Eurêka'), findsOneWidget);
    expect(find.text('Gratuit'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Où en es-tu ?'), findsOneWidget);
    await tester.tap(find.text('Collège'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Ton objectif du jour'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Inès');
    await tester.tap(find.text('C\'est parti !'));
    await tester.pumpAndSettle();

    expect(find.text('Bonjour Inès'), findsOneWidget);
    expect(find.text('Objectif du jour'), findsOneWidget);
  });

  testWidgets('tant que l\'onboarding n\'est pas fait, l\'accueil est '
      'inaccessible', (WidgetTester tester) async {
    await boot(tester);
    expect(find.text('Objectif du jour'), findsNothing);
  });

  testWidgets('l\'accueil propose de reprendre et ouvre la leçon', (
    WidgetTester tester,
  ) async {
    await boot(tester, onboarded: true);

    expect(find.text('Reprendre'), findsOneWidget);
    expect(find.text('Le triangle rectangle'), findsOneWidget);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(find.text('Un triangle pas comme les autres'), findsOneWidget);
  });

  testWidgets('le parcours du chapitre affiche toutes ses leçons', (
    WidgetTester tester,
  ) async {
    await boot(tester, onboarded: true);

    await tester.tap(find.text('Mathématiques'));
    await tester.pumpAndSettle();
    // Le catalogue suit l'ordre du programme officiel : Pythagore arrive en
    // milieu de quatrième et n'est pas visible sans défiler.
    final Finder pythagore = find.text('Le théorème de Pythagore');
    await tester.scrollUntilVisible(
      pythagore,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(pythagore);
    await tester.pumpAndSettle();

    expect(find.byType(LessonPath), findsOneWidget);
    expect(find.text('Le triangle rectangle'), findsWidgets);
    expect(find.text('La réciproque et des problèmes'), findsWidgets);
    expect(find.textContaining('hypoténuse'), findsWidgets);
  });

  testWidgets('une mauvaise réponse laisse un second essai, la bonne fait '
      'avancer', (WidgetTester tester) async {
    await boot(tester, onboarded: true);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    // On fait défiler les cartes jusqu'aux exercices.
    for (int i = 0; i < 12; i++) {
      final Finder quiz = find.text('Passer aux exercices');
      if (quiz.evaluate().isNotEmpty) {
        await tester.tap(quiz);
        await tester.pumpAndSettle();
        break;
      }
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }

    expect(
      find.text(
        'Dans un triangle rectangle, comment appelle-t-on le côté '
        'le plus long ?',
      ),
      findsOneWidget,
    );

    // Valider est impossible tant que rien n'est choisi.
    await tapText(tester, 'Valider');
    expect(find.text('Bien vu !'), findsNothing);

    await tapText(tester, 'La base');
    await tapText(tester, 'Valider');

    expect(find.text('Pas tout à fait…'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    await tapText(tester, 'Réessayer');
    await tapText(tester, 'L\'hypoténuse');
    await tapText(tester, 'Valider');

    expect(find.text('Bien vu !'), findsOneWidget);
    expect(find.textContaining('opposé à l\'angle droit'), findsWidgets);
  });

  testWidgets('sur tablette, la navigation passe en rail latéral', (
    WidgetTester tester,
  ) async {
    await boot(tester, onboarded: true, size: const Size(1280, 900));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('sur téléphone, la navigation reste en barre basse', (
    WidgetTester tester,
  ) async {
    await boot(tester, onboarded: true);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
