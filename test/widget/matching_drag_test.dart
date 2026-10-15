import 'package:eureka/core/theme/app_theme.dart';
import 'package:eureka/domain/models/question.dart';
import 'package:eureka/domain/services/quiz_session.dart';
import 'package:eureka/features/quiz/question_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'appariement se joue au doigt : on fait glisser une étiquette sur sa
/// définition. Le geste à deux touches reste disponible, mais c'est le
/// glisser qui doit marcher.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MatchingQuestion question = MatchingQuestion(
    id: 'q',
    prompt: 'Associe chaque mot à ce qu\'il décrit.',
    explanation: 'Explication.',
    pairs: <MatchPair>[
      MatchPair(left: 'Rotation', right: 'Le jour'),
      MatchPair(left: 'Révolution', right: 'L\'année'),
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
              session: QuizSession.start(const <Question>[question]),
              accent: const Color(0xFF5B5BD6),
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

  testWidgets('glisser une étiquette sur sa définition la rattache', (
    WidgetTester tester,
  ) async {
    final Answer? reponse = await jouer(tester, (WidgetTester t) async {
      await t.drag(find.text('Rotation'), _vers(t, 'Le jour'));
      await t.pump();
      await t.drag(find.text('Révolution'), _vers(t, 'L\'année'));
      await t.pump();
    });

    expect(reponse, isA<MatchingAnswer>());
    expect(question.isSatisfiedBy(reponse!), isTrue);
  });

  testWidgets('la réponse reste nulle tant que tout n\'est pas placé', (
    WidgetTester tester,
  ) async {
    final Answer? reponse = await jouer(tester, (WidgetTester t) async {
      await t.drag(find.text('Rotation'), _vers(t, 'Le jour'));
      await t.pump();
    });
    expect(reponse, isNull);
  });

  testWidgets('les deux touches restent possibles', (
    WidgetTester tester,
  ) async {
    final Answer? reponse = await jouer(tester, (WidgetTester t) async {
      await t.tap(find.text('Rotation'));
      await t.pump();
      await t.tap(find.text('Le jour'));
      await t.pump();
      await t.tap(find.text('Révolution'));
      await t.pump();
      await t.tap(find.text('L\'année'));
      await t.pump();
    });
    expect(reponse, isA<MatchingAnswer>());
    expect(question.isSatisfiedBy(reponse!), isTrue);
  });
}

/// Déplacement du centre de l'étiquette vers le centre de la cible.
Offset _vers(WidgetTester tester, String cible) {
  final Offset arrivee = tester.getCenter(find.text(cible));
  return arrivee - tester.getCenter(find.byType(Draggable<int>).first);
}
