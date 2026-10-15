import 'dart:math';

import 'package:eureka/domain/models/progress.dart';
import 'package:eureka/domain/models/question.dart';
import 'package:eureka/domain/services/quiz_session.dart';
import 'package:eureka/domain/services/xp_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Question choice(String id) => Question.fromJson(<String, Object?>{
  'id': id,
  'kind': 'choixUnique',
  'prompt': 'Question $id',
  'explanation': 'Parce que.',
  'shuffle': false,
  'options': <Object?>[
    <String, Object?>{'text': 'Juste', 'correct': true},
    <String, Object?>{'text': 'Faux'},
  ],
});

/// Session déterministe : le mélange ne doit pas rendre les tests instables.
QuizSession start(int count) => QuizSession.start(<Question>[
  for (int i = 0; i < count; i++) choice('q$i'),
], random: Random(7));

const ChoiceAnswer right = ChoiceAnswer(<int>{0});
const ChoiceAnswer wrong = ChoiceAnswer(<int>{1});

void main() {
  group('Déroulé', () {
    test('démarre sur la première question, sans réponse', () {
      final QuizSession session = start(3);
      expect(session.phase, QuizPhase.answering);
      expect(session.index, 0);
      expect(session.canValidate, isFalse);
      expect(session.progress, 0);
    });

    test('ne valide pas une réponse vide', () {
      expect(start(1).validate().phase, QuizPhase.answering);
    });

    test('une bonne réponse donne le retour puis la question suivante', () {
      QuizSession s = start(2).withDraft(right);
      expect(s.canValidate, isTrue);

      s = s.validate();
      expect(s.phase, QuizPhase.feedback);
      expect(s.verdict, QuizVerdict.correct);

      s = s.advance();
      expect(s.phase, QuizPhase.answering);
      expect(s.index, 1);
      expect(s.draft, isNull, reason: 'la réponse précédente est effacée');
    });

    test('une erreur propose un second essai avant de révéler', () {
      QuizSession s = start(1).withDraft(wrong).validate();
      expect(s.verdict, QuizVerdict.retry);

      s = s.advance();
      expect(s.phase, QuizPhase.answering, reason: 'on rejoue la question');
      expect(s.index, 0);

      s = s.withDraft(wrong).validate();
      expect(s.verdict, QuizVerdict.revealed);

      s = s.advance();
      expect(s.phase, QuizPhase.finished);
    });

    test('se termine après la dernière question', () {
      QuizSession s = start(2);
      for (int i = 0; i < 2; i++) {
        s = s.withDraft(right).validate().advance();
      }
      expect(s.phase, QuizPhase.finished);
      expect(s.progress, 1);
      expect(s.current, isNull);
    });

    test('une session sans question est déjà terminée', () {
      expect(QuizSession.start(const <Question>[]).phase, QuizPhase.finished);
    });
  });

  group('Score et XP', () {
    test('sans faute : bonus accordé', () {
      QuizSession s = start(3);
      for (int i = 0; i < 3; i++) {
        s = s.withDraft(right).validate().advance();
      }
      expect(s.isPerfect, isTrue);
      expect(s.solvedFirstTry, 3);
      expect(s.xpEarned, 3 * XpEngine.xpFirstTry + XpEngine.perfectBonus);
    });

    test('réussir au second essai rapporte moins et annule le bonus', () {
      final QuizSession s = start(1)
          .withDraft(wrong)
          .validate()
          .advance()
          .withDraft(right)
          .validate()
          .advance();
      expect(s.isPerfect, isFalse);
      expect(s.solved, 1);
      expect(s.solvedFirstTry, 0);
      expect(s.xpEarned, XpEngine.xpAfterRetry);
    });

    test('une question jamais résolue ne rapporte rien', () {
      final QuizSession s = start(1)
          .withDraft(wrong)
          .validate()
          .advance()
          .withDraft(wrong)
          .validate()
          .advance();
      expect(s.xpEarned, 0);
      expect(s.solved, 0);
    });

    test('le résultat transmis à la progression reflète la session', () {
      QuizSession s = start(2);
      s = s.withDraft(right).validate().advance();
      s = s
          .withDraft(wrong)
          .validate()
          .advance()
          .withDraft(right)
          .validate()
          .advance();

      final LessonOutcome outcome = s.toOutcome(
        chapterId: 'ch',
        lessonId: 'le',
        firstTimeCompleted: true,
      );
      expect(outcome.total, 2);
      expect(outcome.correct, 1, reason: 'une seule réussite du premier coup');
      expect(outcome.accuracy, 0.5);
      expect(outcome.xpEarned, s.xpEarned);
    });
  });

  group('Indice', () {
    test('s\'affiche sans coûter d\'XP', () {
      final QuizSession s = start(1).revealHint().withDraft(right).validate();
      expect(s.hintRevealed, isTrue);
      expect(s.attempts['q0']!.xpEarned, XpEngine.xpFirstTry);
    });
  });

  group('Mélange', () {
    test('une remise en ordre n\'est jamais proposée déjà résolue', () {
      final Question ordering = Question.fromJson(<String, Object?>{
        'id': 'ord',
        'kind': 'remiseEnOrdre',
        'prompt': 'Ordonne',
        'explanation': '…',
        'items': <String>['un', 'deux', 'trois', 'quatre'],
      });
      for (int seed = 0; seed < 40; seed++) {
        final QuizSession s = QuizSession.start(<Question>[
          ordering,
        ], random: Random(seed));
        expect(
          s.displayOrder['ord'],
          isNot(<int>[0, 1, 2, 3]),
          reason: 'graine $seed',
        );
      }
    });

    test('shuffle: false conserve l\'ordre du contenu', () {
      final QuizSession s = start(1);
      expect(s.displayOrder['q0'], <int>[0, 1]);
    });
  });
}
