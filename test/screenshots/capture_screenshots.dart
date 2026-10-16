import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:eureka/app/app.dart';
import 'package:eureka/app/providers.dart';
import 'package:eureka/data/content/content_catalog.dart';
import 'package:eureka/data/content/content_loader.dart';
import 'package:eureka/data/local/key_value_store.dart';
import 'package:eureka/data/repositories/progress_repository.dart';
import 'package:eureka/data/repositories/settings_repository.dart';
import 'package:eureka/domain/models/app_settings.dart';
import 'package:eureka/domain/models/education_level.dart';
import 'package:eureka/domain/models/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Produit les captures d'écran de l'application.
///
/// Les images sont rendues par l'application elle-même, à partir du vrai
/// code et du vrai contenu : aucune maquette, aucun montage. Une capture ne
/// peut donc pas montrer un écran qui n'existe pas, et elle se périme avec
/// le code plutôt que de rester fidèle à une version ancienne.
///
///     flutter test test/screenshots/capture_screenshots.dart --update-goldens
///
/// Le fichier ne se termine volontairement pas par `_test.dart` : il est
/// donc ignoré par un `flutter test` ordinaire. C'est délibéré — une
/// comparaison de pixels dépend de la plateforme de rendu, et ces tests
/// échoueraient sur le runner macOS de l'intégration continue, bloquant la
/// publication pour une différence d'anticrénelage.
///
/// Les tailles correspondent à ce qu'exige App Store Connect : 1320 × 2868
/// pour l'iPhone 6,9 pouces, 2064 × 2752 pour l'iPad 13 pouces.

/// Monte la police des icônes Material dans l'environnement de test.
///
/// Sans elle, chaque icône est rendue comme un carré vide — ce qui ne se
/// voit pas dans un test de comportement, mais ruine une capture d'écran.
/// La police n'est pas dans les assets du projet : elle vient du SDK, dont
/// on retrouve la racine à partir de l'exécutable Dart en cours.
Future<void> _loadMaterialIcons() async {
  Future<ByteData>? bytes;
  try {
    bytes = rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await bytes;
  } on FlutterError {
    bytes = null;
  }

  if (bytes == null) {
    // .../flutter/bin/cache/dart-sdk/bin/dart → .../flutter
    final Directory sdk = File(Platform.resolvedExecutable)
        .parent
        .parent
        .parent
        .parent
        .parent;
    final File file = File(
      '${sdk.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (!file.existsSync()) {
      fail('Police des icônes introuvable : ${file.path}');
    }
    bytes = Future<ByteData>.value(
      ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync())),
    );
  }

  await (FontLoader('MaterialIcons')..addFont(bytes)).load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;

  setUpAll(() async {
    catalog = await ContentLoader().load();
    // Sans chargement explicite, le moteur de test dessine le texte en
    // rectangles : les polices déclarées dans pubspec ne sont pas montées
    // d'office.
    for (final String family in <String>['Nunito', 'Baloo2']) {
      final FontLoader loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
      await loader.load();
    }
    await _loadMaterialIcons();
  });

  /// Date figée : la série affichée et le graphique d'activité doivent être
  /// identiques d'une exécution à l'autre.
  final DateTime today = DateTime(2026, 3, 15, 10, 30);

  /// Un élève déjà engagé : sans progression, l'accueil est vide et ne
  /// montre rien de ce que fait l'application.
  InMemoryStore seededStore({bool withHistory = true}) {
    DayKey ago(int days) => dayKeyOf(today.subtract(Duration(days: days)));
    const String chapter = 'maths-college-le-theoreme-de-pythagore';
    LessonRecord record(int correct, int total, int days) => LessonRecord(
      attempts: 1,
      bestCorrect: correct,
      bestTotal: total,
      firstDay: ago(days),
      lastDay: ago(0),
      distinctDays: 2,
    );

    final ProgressState progress = ProgressState(
      profile: const LearnerProfile(
        firstName: 'Inès',
        level: EducationLevel.college,
        dailyGoalXp: 20,
        onboarded: true,
      ),
      totalXp: 460,
      bestStreak: 9,
      // Sans historique de leçon, l'accueil propose la toute première
      // leçon du chapitre : c'est ce qu'il faut pour capturer le cours et
      // l'exercice d'introduction, qui portent la figure manipulable.
      lessons: withHistory
          ? <String, LessonRecord>{
              lessonKey(chapter, 'vocabulaire'): record(4, 4, 6),
              lessonKey(chapter, 'theoreme'): record(4, 5, 3),
            }
          : const <String, LessonRecord>{},
      dailyXp: <DayKey, int>{
        ago(0): 15,
        ago(1): 35,
        ago(2): 20,
        ago(3): 45,
        ago(4): 25,
        ago(5): 20,
        ago(6): 30,
        ago(8): 25,
        ago(9): 40,
        ago(10): 20,
      },
    );

    return InMemoryStore(<String, String>{
      ProgressRepository.storageKey: jsonEncode(progress.toJson()),
      SettingsRepository.storageKey: jsonEncode(
        // Animations coupées : une capture doit être reproductible au pixel.
        const AppSettings(reduceMotion: true, haptics: false).toJson(),
      ),
    });
  }

  Future<void> boot(
    WidgetTester tester,
    Size logical,
    double ratio, {
    bool withHistory = true,
  }) async {
    tester.view.physicalSize = Size(
      logical.width * ratio,
      logical.height * ratio,
    );
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(
            seededStore(withHistory: withHistory),
          ),
          contentCatalogProvider.overrideWithValue(catalog),
          clockProvider.overrideWithValue(() => today),
          // Graine fixe : sans elle, l'ordre des propositions change à
          // chaque exécution et la capture du quiz n'est jamais la même.
          quizRandomProvider.overrideWithValue(() => Random(7)),
        ],
        child: const EurekaApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String label) async {
    final Finder finder = find.text(label).first;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  /// Un parcours, décliné sur chaque format demandé par App Store Connect.
  void captureSuite(String device, Size logical, double ratio) {
    group(device, () {
      testWidgets('accueil', (WidgetTester tester) async {
        await boot(tester, logical, ratio);
        await shoot(tester, '$device-1-accueil');
      });

      testWidgets('parcours du chapitre', (WidgetTester tester) async {
        await boot(tester, logical, ratio);
        await tapText(tester, 'Mathématiques');
        await tapText(tester, 'Le théorème de Pythagore');
        await shoot(tester, '$device-2-chapitre');
      });

      testWidgets('leçon et figure manipulable', (WidgetTester tester) async {
        await boot(tester, logical, ratio, withHistory: false);
        await tapText(tester, 'Matières');
        await tapText(tester, 'Mathématiques');
        await tapText(tester, 'Le théorème de Pythagore');
        await tapText(tester, 'Commencer');
        // La deuxième carte porte la figure interactive.
        await tapText(tester, 'Suivant');
        await shoot(tester, '$device-3-lecon');
      });

      testWidgets('exercice corrigé', (WidgetTester tester) async {
        await boot(tester, logical, ratio, withHistory: false);
        // Plusieurs chapitres sont jouables : « Commencer » ne désigne
        // plus celui-ci de façon certaine, on y va par la matière.
        await tapText(tester, 'Matières');
        await tapText(tester, 'Mathématiques');
        await tapText(tester, 'Le théorème de Pythagore');
        await tapText(tester, 'Commencer');
        for (int i = 0; i < 12; i++) {
          if (find.text('Passer aux exercices').evaluate().isNotEmpty) {
            await tapText(tester, 'Passer aux exercices');
            break;
          }
          await tapText(tester, 'Suivant');
        }
        await tapText(tester, 'L\'hypoténuse');
        await tapText(tester, 'Valider');
        await shoot(tester, '$device-4-exercice');
      });

      // L'appariement se joue au glisser-déposer : sa capture montre la
      // réserve d'étiquettes et les définitions qui les accueillent.
      testWidgets('appariement à glisser', (WidgetTester tester) async {
        await boot(tester, logical, ratio, withHistory: false);
        await tapText(tester, 'Matières');
        await tapText(tester, 'Mathématiques');
        await tapText(tester, 'Le théorème de Pythagore');
        await tapText(tester, 'Commencer');
        for (int i = 0; i < 12; i++) {
          if (find.text('Passer aux exercices').evaluate().isNotEmpty) {
            await tapText(tester, 'Passer aux exercices');
            break;
          }
          await tapText(tester, 'Suivant');
        }
        // Deux questions avant l'appariement.
        await tapText(tester, 'L\'hypoténuse');
        await tapText(tester, 'Valider');
        await tapText(tester, 'Continuer');
        await tapText(tester, 'Faux');
        await tapText(tester, 'Valider');
        await tapText(tester, 'Continuer');
        await shoot(tester, '$device-7-appariement');
      });

      // La figure du Système solaire a sa propre capture : c'est la seule
      // qui porte une échelle, et une erreur de placement y serait
      // invisible dans un test de géométrie.
      testWidgets('astronomie : figure du Système solaire', (
        WidgetTester tester,
      ) async {
        await boot(tester, logical, ratio);
        await tapText(tester, 'Matières');
        await tapText(tester, 'Astronomie');
        await tapText(tester, 'Le Système solaire');
        await tapText(tester, 'Commencer');
        await tapText(tester, 'Suivant');
        await shoot(tester, '$device-6-astronomie');
      });

      // Le croisement : deux parents Jv, et le quart de vert qui apparaît.
      testWidgets('svt : croisement génétique', (WidgetTester tester) async {
        await boot(tester, logical, ratio);
        await tapText(tester, 'Matières');
        await tapText(tester, 'SVT');
        await tapText(tester, 'Génétique et hérédité');
        await tapText(tester, 'Dominant, récessif');
        await tester.tap(find.text('Suivant').first);
        await tester.pumpAndSettle();
        await shoot(tester, '$device-16-croisement');
      });

      // La piste de vitesse s'anime : la capture fige le mobile en route,
      // avec ses positions passées également espacées.
      testWidgets('physique : vitesse sur une piste', (
        WidgetTester tester,
      ) async {
        await boot(tester, logical, ratio);
        await tapText(tester, 'Matières');
        await tapText(tester, 'Physique-chimie');
        await tapText(tester, 'Mouvements et vitesse');
        await tapText(tester, 'La vitesse');
        await tester.tap(find.text('Suivant').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        // Sous « réduire les animations » le mobile reste au départ :
        // on le lance à la main.
        await tester.tap(find.byIcon(Icons.replay_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 2600));
        await shoot(tester, '$device-15-vitesse');
      });

      // La table de vérité : c'est en basculant A et B qu'on voit « ou »
      // rester vrai quand les deux le sont.
      testWidgets('logique : table de vérité', (WidgetTester tester) async {
        await boot(tester, logical, ratio);
        await tapText(tester, 'Matières');
        await tapText(tester, 'Logique et énigmes');
        await tapText(tester, 'Et, ou, non');
        await tapText(tester, 'Ou');
        await tapText(tester, 'Suivant');
        // Tap direct : la carte d'une figure n'est pas dans une zone
        // défilante, et ensureVisible y cherche un Scrollable en vain.
        await tester.tap(find.text('Le nombre dépasse 10'));
        await tester.pumpAndSettle();
        await shoot(tester, '$device-14-logique');
      });

      // La figure de Thalès : les trois rapports doivent afficher la même
      // valeur, c'est tout l'enseignement du chapitre.
      testWidgets('maths : configuration de Thalès', (
        WidgetTester tester,
      ) async {
        await boot(tester, logical, ratio);
        await tapText(tester, 'Matières');
        await tapText(tester, 'Mathématiques');
        await tapText(tester, 'Le théorème de Thalès');
        await tapText(tester, 'La configuration');
        await tapText(tester, 'Suivant');
        await shoot(tester, '$device-13-thales');
      });

      // Les deux formes d'exercice ajoutées : un tri dans des bacs, et
      // une estimation au curseur. Elles n'existaient pas quand les
      // captures ont été écrites, et rien d'autre ne les montre.
      testWidgets('exercice : tri en catégories', (WidgetTester tester) async {
        await boot(tester, logical, ratio, withHistory: false);
        await tapText(tester, 'Matières');
        await tapText(tester, 'Astronomie');
        await tapText(tester, 'Le Système solaire');
        await tapText(tester, 'Huit planètes');
        for (int i = 0; i < 12; i++) {
          if (find.text('Passer aux exercices').evaluate().isNotEmpty) {
            await tapText(tester, 'Passer aux exercices');
            break;
          }
          await tapText(tester, 'Suivant');
        }
        // Le tri est la deuxième question.
        await tapText(tester, 'Mercure');
        await tapText(tester, 'Valider');
        await tapText(tester, 'Continuer');
        await shoot(tester, '$device-11-tri');
      });

      // L'estimation : un curseur, pas un clavier. La capture le montre
      // après un premier réglage, sans quoi la valeur affichée reste un
      // tiret et on ne verrait rien de l'exercice.
      testWidgets('exercice : estimation au curseur', (
        WidgetTester tester,
      ) async {
        await boot(tester, logical, ratio, withHistory: false);
        await tapText(tester, 'Matières');
        await tapText(tester, 'Astronomie');
        await tapText(tester, 'Le Système solaire');
        await tapText(tester, 'Les distances');
        for (int i = 0; i < 12; i++) {
          if (find.text('Passer aux exercices').evaluate().isNotEmpty) {
            await tapText(tester, 'Passer aux exercices');
            break;
          }
          await tapText(tester, 'Suivant');
        }
        await tester.enterText(find.byType(TextField).first, '150');
        await tester.pumpAndSettle();
        await tapText(tester, 'Valider');
        await tapText(tester, 'Continuer');
        final Rect piste = tester.getRect(find.byType(Slider));
        await tester.tapAt(
          Offset(piste.left + piste.width * 0.72, piste.center.dy),
        );
        await tester.pumpAndSettle();
        await shoot(tester, '$device-12-estimation');
      });

      // La preuve de Pythagore se joue en glissant : deux captures, au
      // départ et à l'arrivée, pour vérifier que les triangles tombent
      // bien aux bons endroits dans les deux dispositions.
      testWidgets('maths : preuve par réarrangement', (
        WidgetTester tester,
      ) async {
        await boot(tester, logical, ratio);
        await tapText(tester, 'Matières');
        await tapText(tester, 'Mathématiques');
        await tapText(tester, 'Le théorème de Pythagore');
        await tapText(tester, 'Le théorème');
        await tapText(tester, 'Suivant');
        await tester.tap(find.text('Suivant').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await shoot(tester, '$device-10-preuve-depart');

        final Rect piste = tester.getRect(find.byType(Slider));
        await tester.tapAt(Offset(piste.center.dx, piste.center.dy));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await shoot(tester, '$device-10-preuve-milieu');
        await tester.tapAt(Offset(piste.right - 2, piste.center.dy));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await shoot(tester, '$device-10-preuve-arrivee');
      });

      // Les orbites s'animent : la capture fige un instant précis, un an
      // après le départ, où les quatre compteurs ont déjà divergé.
      testWidgets('astronomie : orbites animées', (
        WidgetTester tester,
      ) async {
        await boot(tester, logical, ratio);
        await tapText(tester, 'Matières');
        await tapText(tester, 'Astronomie');
        await tapText(tester, 'Le Système solaire');
        // Le titre d'une leçon l'ouvre directement : pas de « Commencer »
        // à passer.
        await tapText(tester, 'Tourner sans tomber');
        await tapText(tester, 'Suivant');
        // Dernier pas sans pumpAndSettle : la figure qui suit tourne en
        // continu, et attendre la fin des animations n'aurait pas de fin.
        await tester.tap(find.text('Suivant').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        // Les captures tournent avec « réduire les animations » : la
        // figure démarre donc à l'arrêt, et c'est le curseur qui fait
        // avancer le temps. On le pousse à une année terrestre — là où
        // les quatre compteurs ont visiblement divergé.
        final Finder curseur = find.byType(Slider);
        final Rect piste = tester.getRect(curseur);
        await tester.tapAt(
          Offset(piste.left + piste.width * 0.53, piste.center.dy),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await shoot(tester, '$device-9-orbites');
      });

      // Le robot de la boucle : la capture le prend après exécution,
      // quand le carré est tracé. Figé avant, on ne verrait qu'une
      // grille vide et la figure ne dirait rien.
      testWidgets('informatique : robot et boucle', (
        WidgetTester tester,
      ) async {
        await boot(tester, logical, ratio);
        await tapText(tester, 'Matières');
        await tapText(tester, 'Informatique');
        await tapText(tester, 'Boucles et conditions');
        await tapText(tester, 'La boucle');
        // La figure est sur la deuxième carte.
        await tester.tap(find.text('Suivant').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        // Captures en mode « animations réduites » : le tracé ne part pas
        // tout seul, on appuie sur Exécuter puis on laisse courir
        // l'animation jusqu'au bout.
        await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
        await shoot(tester, '$device-17-boucle');
      });

      // L'engrenage : deux roues en prise, la menée réglée au plus
      // petit nombre de dents — c'est là que l'écart de vitesse entre
      // les deux compteurs saute aux yeux.
      testWidgets('technologie : engrenage', (WidgetTester tester) async {
        await boot(tester, logical, ratio);
        await tapText(tester, 'Matières');
        await tapText(tester, 'Technologie');
        await tapText(tester, 'Transmettre et transformer le mouvement');
        await tapText(tester, 'Transmettre le mouvement');
        await tester.tap(find.text('Suivant').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final Rect piste = tester.getRect(find.byType(Slider));
        final TestGesture reglage = await tester.startGesture(piste.center);
        await reglage.moveTo(Offset(piste.left + 2, piste.center.dy));
        await tester.pump();
        await reglage.up();
        await tester.pump(const Duration(milliseconds: 600));
        // Puis on lance la rotation : l'infobulle du curseur, qui
        // recouvrait la phrase de résultat, disparaît du même coup, et
        // les deux compteurs affichent enfin des valeurs différentes —
        // ce que la figure a justement à montrer.
        await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));
        await shoot(tester, '$device-18-engrenage');
      });

      // La mesure d'Ératosthène : la capture la prend telle quelle, à
      // l'angle historique de 7,2°.
      testWidgets('histoire : la Terre mesurée', (WidgetTester tester) async {
        await boot(tester, logical, ratio);
        await tapText(tester, 'Matières');
        await tapText(tester, 'Histoire des sciences');
        await tapText(tester, 'De la Terre plate au Système solaire');
        await tapText(tester, 'Mesurer la Terre');
        await tapText(tester, 'Suivant');
        await tapText(tester, 'Suivant');
        await tester.tap(find.text('Suivant').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await shoot(tester, '$device-19-eratosthene');
      });

      // Le recul de Mars : l'instant choisi est celui du dépassement,
      // là où la trace repart en arrière. Pris trop tôt, le graphique
      // ne montrerait qu'une ligne montante.
      testWidgets('histoire : le recul de Mars', (WidgetTester tester) async {
        await boot(tester, logical, ratio);
        await tapText(tester, 'Matières');
        await tapText(tester, 'Histoire des sciences');
        await tapText(tester, 'De la Terre plate au Système solaire');
        await tapText(tester, 'La Terre au centre');
        await tapText(tester, 'Suivant');
        await tapText(tester, 'Suivant');
        await tester.tap(find.text('Suivant').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final Rect piste = tester.getRect(find.byType(Slider));
        await tester.tapAt(
          Offset(piste.left + piste.width * 0.49, piste.center.dy),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await shoot(tester, '$device-20-retrogradation');
      });

      testWidgets('profil', (WidgetTester tester) async {
        await boot(tester, logical, ratio);
        await tapText(tester, 'Profil');
        await shoot(tester, '$device-5-profil');
      });
    });
  }

  // iPhone 6,9 pouces → 1320 × 2868 px.
  captureSuite('iphone', const Size(440, 956), 3.0);
  // iPad 13 pouces → 2064 × 2752 px.
  captureSuite('ipad', const Size(1032, 1376), 2.0);
}
