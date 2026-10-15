import 'dart:convert';

import 'package:eureka/core/theme/app_theme.dart';
import 'package:eureka/app/providers.dart';
import 'package:eureka/data/content/content_catalog.dart';
import 'package:eureka/data/content/content_loader.dart';
import 'package:eureka/data/local/key_value_store.dart';
import 'package:eureka/data/repositories/settings_repository.dart';
import 'package:eureka/domain/models/app_settings.dart';
import 'package:eureka/domain/services/xp_engine.dart';
import 'package:eureka/features/quiz/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le chronomètre des défis.
///
/// Il ne s'affiche que sur une leçon « défi », et seulement si l'élève l'a
/// laissé actif. Il n'enlève jamais d'XP : à zéro, la question reste
/// ouverte et le libellé le dit.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;
  setUpAll(() async => catalog = await ContentLoader().load());

  Future<void> ouvrir(
    WidgetTester tester, {
    required String lessonId,
    required bool chrono,
  }) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final InMemoryStore store = InMemoryStore(<String, String>{
      SettingsRepository.storageKey: jsonEncode(
        AppSettings(
          reduceMotion: true,
          haptics: false,
          timedChallenges: chrono,
        ).toJson(),
      ),
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          contentCatalogProvider.overrideWithValue(catalog),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: QuizScreen(
            chapterId: 'maths-college-le-theoreme-de-pythagore',
            lessonId: lessonId,
            onExit: () {},
            onOpenNextLesson: (String _, String _) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('le défi affiche le compte à rebours et le bonus', (
    WidgetTester tester,
  ) async {
    await ouvrir(tester, lessonId: 'reciproque', chrono: true);
    expect(
      find.textContaining('s pour +${XpEngine.speedBonus} XP'),
      findsOneWidget,
    );
  });

  testWidgets('réglage coupé, aucun chronomètre', (WidgetTester tester) async {
    await ouvrir(tester, lessonId: 'reciproque', chrono: false);
    expect(find.textContaining('pour +'), findsNothing);
    expect(find.textContaining('Temps écoulé'), findsNothing);
  });

  testWidgets('une leçon ordinaire n\'est jamais chronométrée', (
    WidgetTester tester,
  ) async {
    await ouvrir(tester, lessonId: 'vocabulaire', chrono: true);
    expect(find.textContaining('pour +'), findsNothing);
  });
}
