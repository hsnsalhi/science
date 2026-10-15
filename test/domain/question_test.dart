import 'package:eureka/domain/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Normalisation des saisies', () {
    test('ignore casse, accents, espaces et apostrophes', () {
      expect(
        FillBlanksQuestion.normalize('  L\'HYPOTÉNUSE '),
        FillBlanksQuestion.normalize('lhypotenuse'),
      );
    });

    test('traite les exposants comme des chiffres', () {
      expect(
        FillBlanksQuestion.normalize('c²'),
        FillBlanksQuestion.normalize('c2'),
      );
    });
  });

  group('Lecture des nombres', () {
    test('accepte la virgule décimale française', () {
      expect(NumericQuestion.parseInput('1,41'), closeTo(1.41, 1e-9));
    });

    test('accepte les espaces de milliers', () {
      expect(NumericQuestion.parseInput('10 000'), 10000);
    });

    test('rejette une saisie non numérique', () {
      expect(NumericQuestion.parseInput('douze'), isNull);
      expect(NumericQuestion.parseInput(''), isNull);
    });

    test('formate à la française, sans décimale inutile', () {
      expect(NumericQuestion.formatNumber(5), '5');
      expect(NumericQuestion.formatNumber(1.41), '1,41');
    });
  });

  group('Correction par type de question', () {
    test('choix unique', () {
      final Question q = Question.fromJson(<String, Object?>{
        'id': 'q',
        'kind': 'choixUnique',
        'prompt': 'Le plus long côté ?',
        'explanation': 'L\'hypoténuse.',
        'options': <Object?>[
          <String, Object?>{'text': 'Hypoténuse', 'correct': true},
          <String, Object?>{'text': 'Base'},
        ],
      });
      expect(q.isSatisfiedBy(const ChoiceAnswer(<int>{0})), isTrue);
      expect(q.isSatisfiedBy(const ChoiceAnswer(<int>{1})), isFalse);
      expect(q.isSatisfiedBy(const ChoiceAnswer(<int>{0, 1})), isFalse);
      expect(q.solutionLabel, 'Hypoténuse');
    });

    test('choix multiple exige exactement le bon ensemble', () {
      final Question q = Question.fromJson(<String, Object?>{
        'id': 'q',
        'kind': 'choixMultiple',
        'prompt': 'Lesquelles ?',
        'explanation': '…',
        'options': <Object?>[
          <String, Object?>{'text': 'A', 'correct': true},
          <String, Object?>{'text': 'B', 'correct': true},
          <String, Object?>{'text': 'C'},
        ],
      });
      expect(q.isSatisfiedBy(const ChoiceAnswer(<int>{0, 1})), isTrue);
      expect(q.isSatisfiedBy(const ChoiceAnswer(<int>{0})), isFalse);
      expect(q.isSatisfiedBy(const ChoiceAnswer(<int>{0, 1, 2})), isFalse);
    });

    test('saisie numérique applique la tolérance', () {
      final Question q = Question.fromJson(<String, Object?>{
        'id': 'q',
        'kind': 'saisieNumerique',
        'prompt': '√2 ?',
        'explanation': '…',
        'answer': 1.41,
        'tolerance': 0.02,
        'unit': 'cm',
      });
      expect(q.isSatisfiedBy(const NumericAnswer(1.414)), isTrue);
      expect(q.isSatisfiedBy(const NumericAnswer(1.5)), isFalse);
      expect(q.solutionLabel, '1,41 cm');
    });

    test('texte à trous accepte les variantes déclarées', () {
      final Question q = Question.fromJson(<String, Object?>{
        'id': 'q',
        'kind': 'texteATrous',
        'prompt': 'Complète',
        'explanation': '…',
        'template': 'Le carré de l\'___ vaut ___.',
        'blanks': <Object?>[
          <String, Object?>{
            'accepted': <String>['hypoténuse'],
          },
          <String, Object?>{
            'accepted': <String>['225'],
          },
        ],
      });
      expect(
        q.isSatisfiedBy(const BlanksAnswer(<String>['Hypotenuse', '225'])),
        isTrue,
      );
      expect(
        q.isSatisfiedBy(const BlanksAnswer(<String>['base', '225'])),
        isFalse,
      );
      expect(
        q.isSatisfiedBy(const BlanksAnswer(<String>['hypoténuse'])),
        isFalse,
        reason: 'un trou non rempli ne peut pas être juste',
      );
    });

    test('remise en ordre : seul l\'ordre d\'origine est juste', () {
      final Question q = Question.fromJson(<String, Object?>{
        'id': 'q',
        'kind': 'remiseEnOrdre',
        'prompt': 'Ordonne',
        'explanation': '…',
        'items': <String>['un', 'deux', 'trois'],
      });
      expect(q.isSatisfiedBy(const OrderingAnswer(<int>[0, 1, 2])), isTrue);
      expect(q.isSatisfiedBy(const OrderingAnswer(<int>[1, 0, 2])), isFalse);
    });

    test('appariement : chaque gauche va vers sa droite', () {
      final Question q = Question.fromJson(<String, Object?>{
        'id': 'q',
        'kind': 'appariement',
        'prompt': 'Associe',
        'explanation': '…',
        'pairs': <Object?>[
          <String, Object?>{'left': 'A', 'right': '1'},
          <String, Object?>{'left': 'B', 'right': '2'},
        ],
      });
      expect(
        q.isSatisfiedBy(const MatchingAnswer(<int, int>{0: 0, 1: 1})),
        isTrue,
      );
      expect(
        q.isSatisfiedBy(const MatchingAnswer(<int, int>{0: 1, 1: 0})),
        isFalse,
      );
    });

    test('une réponse du mauvais type est fausse, pas une exception', () {
      final Question q = Question.fromJson(<String, Object?>{
        'id': 'q',
        'kind': 'vraiFaux',
        'prompt': 'Vrai ?',
        'explanation': '…',
        'answer': true,
      });
      expect(q.isSatisfiedBy(const NumericAnswer(1)), isFalse);
    });
  });

  group('Validation du contenu', () {
    Map<String, Object?> base(Map<String, Object?> extra) => <String, Object?>{
      'id': 'q',
      'prompt': 'Énoncé',
      'explanation': 'Parce que.',
      ...extra,
    };

    test('refuse un choix unique sans bonne réponse', () {
      expect(
        () => Question.fromJson(
          base(<String, Object?>{
            'kind': 'choixUnique',
            'options': <Object?>[
              <String, Object?>{'text': 'A'},
              <String, Object?>{'text': 'B'},
            ],
          }),
        ),
        throwsFormatException,
      );
    });

    test('refuse un choix unique avec deux bonnes réponses', () {
      expect(
        () => Question.fromJson(
          base(<String, Object?>{
            'kind': 'choixUnique',
            'options': <Object?>[
              <String, Object?>{'text': 'A', 'correct': true},
              <String, Object?>{'text': 'B', 'correct': true},
            ],
          }),
        ),
        throwsFormatException,
      );
    });

    test('refuse un texte à trous mal compté', () {
      expect(
        () => Question.fromJson(
          base(<String, Object?>{
            'kind': 'texteATrous',
            'template': 'Un seul ___ ici.',
            'blanks': <Object?>[
              <String, Object?>{
                'accepted': <String>['a'],
              },
              <String, Object?>{
                'accepted': <String>['b'],
              },
            ],
          }),
        ),
        throwsFormatException,
      );
    });

    test('refuse une explication manquante', () {
      expect(
        () => Question.fromJson(<String, Object?>{
          'id': 'q',
          'kind': 'vraiFaux',
          'prompt': 'Énoncé',
          'answer': true,
        }),
        throwsFormatException,
      );
    });

    test('refuse un type inconnu', () {
      expect(
        () => Question.fromJson(base(<String, Object?>{'kind': 'devinette'})),
        throwsFormatException,
      );
    });
  });
}
