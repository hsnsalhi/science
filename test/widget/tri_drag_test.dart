import 'package:eureka/core/theme/app_theme.dart';
import 'package:eureka/domain/models/question.dart';
import 'package:eureka/domain/services/quiz_session.dart';
import 'package:eureka/features/quiz/question_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le tri en catégories se joue au glisser-déposer, comme l'appariement.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ClassifyQuestion question = ClassifyQuestion(
    id: 'q',
    prompt: 'Range.',
    explanation: 'Parce que.',
    categories: <String>['Rocheuses', 'Géantes'],
    items: <ClassifyItem>[
      ClassifyItem(text: 'Mars', category: 0),
      ClassifyItem(text: 'Jupiter', category: 1),
    ],
  );

  Future<Answer?> jouer(
    WidgetTester tester,
    Future<void> Function(WidgetTester tester) gestes,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Answer? derniere;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: QuestionAnswerArea(
              question: question,
              // Sans mélange, l'ordre d'affichage suit le contenu : le
              // test vise un élément par son texte, pas par sa place.
              session: QuizSession.start(const <Question>[question]),
              accent: const Color(0xFF9333EA),
              locked: false,
              onAnswer: (Answer? a) => derniere = a,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await gestes(tester);
    return derniere;
  }

  Offset vers(WidgetTester tester, String etiquette, String bac) =>
      tester.getCenter(find.text(bac)) - tester.getCenter(find.text(etiquette));

  testWidgets('ranger chaque élément dans sa catégorie répond juste', (
    WidgetTester tester,
  ) async {
    final Answer? reponse = await jouer(tester, (WidgetTester t) async {
      await t.drag(find.text('Mars'), vers(t, 'Mars', 'Rocheuses'));
      await t.pump();
      await t.drag(find.text('Jupiter'), vers(t, 'Jupiter', 'Géantes'));
      await t.pump();
    });
    expect(reponse, isA<ClassifyAnswer>());
    expect(question.isSatisfiedBy(reponse!), isTrue);
  });

  testWidgets('se tromper de bac donne une réponse complète mais fausse', (
    WidgetTester tester,
  ) async {
    final Answer? reponse = await jouer(tester, (WidgetTester t) async {
      await t.drag(find.text('Mars'), vers(t, 'Mars', 'Géantes'));
      await t.pump();
      await t.drag(find.text('Jupiter'), vers(t, 'Jupiter', 'Rocheuses'));
      await t.pump();
    });
    expect(reponse, isA<ClassifyAnswer>());
    expect(question.isSatisfiedBy(reponse!), isFalse);
  });

  testWidgets('tant qu\'un élément reste en réserve, rien n\'est validable', (
    WidgetTester tester,
  ) async {
    final Answer? reponse = await jouer(tester, (WidgetTester t) async {
      await t.drag(find.text('Mars'), vers(t, 'Mars', 'Rocheuses'));
      await t.pump();
    });
    expect(reponse, isNull);
  });
}
