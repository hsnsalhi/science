import 'package:eureka/core/theme/app_theme.dart';
import 'package:eureka/design_system/lesson_path.dart';
import 'package:eureka/domain/models/lesson.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dans le parcours d'un chapitre, le titre d'une leçon l'ouvre.
///
/// Il était posé sous le rond dans un IgnorePointer : visuellement partie
/// du bouton, mais sourd aux touches. Or c'est le mot qu'on lit, donc
/// celui qu'on vise.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const List<LessonNodeData> noeuds = <LessonNodeData>[
    LessonNodeData(
      id: 'une',
      title: 'Le triangle rectangle',
      kind: LessonKind.cours,
      state: LessonNodeState.termine,
      perfect: true,
    ),
    LessonNodeData(
      id: 'deux',
      title: 'Tourner sans tomber',
      kind: LessonKind.cours,
      state: LessonNodeState.enCours,
    ),
    LessonNodeData(
      id: 'trois',
      title: 'Le grand défi',
      kind: LessonKind.defi,
      state: LessonNodeState.aVenir,
    ),
  ];

  Future<String?> taper(WidgetTester tester, String cible) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    String? ouvert;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonPath(
              nodes: noeuds,
              color: const Color(0xFF5B5BD6),
              onTap: (String id) => ouvert = id,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final Finder titre = find.text(cible);
    await tester.ensureVisible(titre);
    await tester.pump();
    await tester.tap(titre);
    await tester.pump();
    return ouvert;
  }

  testWidgets('toucher le titre ouvre la leçon', (WidgetTester tester) async {
    expect(await taper(tester, 'Tourner sans tomber'), 'deux');
  });

  testWidgets('chaque titre ouvre la sienne, pas celle d\'à côté', (
    WidgetTester tester,
  ) async {
    expect(await taper(tester, 'Le triangle rectangle'), 'une');
    expect(await taper(tester, 'Le grand défi'), 'trois');
  });
}
