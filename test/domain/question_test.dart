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

  // Un trou qui n'attend qu'un nombre doit ouvrir le pavé numérique et
  // refuser les lettres. Le même exercice peut mêler les deux : « 15² =
  // ___ » et « le triangle est donc ___ » n'appellent pas le même clavier,
  // donc la distinction se fait trou par trou, pas question par question.
  group('Texte à trous : nature de chaque trou', () {
    FillBlanksQuestion build(List<List<String>> accepted) {
      return FillBlanksQuestion(
        id: 'q',
        prompt: 'Énoncé',
        explanation: 'Explication',
        template: List<String>.filled(accepted.length, '___').join(' = '),
        accepted: accepted,
      );
    }

    test('un trou aux réponses numériques est numérique', () {
      final FillBlanksQuestion question = build(<List<String>>[
        <String>['225'],
        <String>['12,5'],
        <String>['-3'],
      ]);
      expect(question.isNumericBlank(0), isTrue);
      expect(question.isNumericBlank(1), isTrue);
      expect(question.isNumericBlank(2), isTrue);
    });

    test('un trou attendant un mot ne l\'est pas', () {
      final FillBlanksQuestion question = build(<List<String>>[
        <String>['rectangle'],
        <String>['hypoténuse', 'hypotenuse'],
      ]);
      expect(question.isNumericBlank(0), isFalse);
      expect(question.isNumericBlank(1), isFalse);
    });

    test('une seule réponse non numérique suffit à ouvrir le clavier', () {
      final FillBlanksQuestion question = build(<List<String>>[
        <String>['225', 'deux cent vingt-cinq'],
      ]);
      expect(question.isNumericBlank(0), isFalse);
    });

    test('les deux natures cohabitent dans un même exercice', () {
      final FillBlanksQuestion question = build(<List<String>>[
        <String>['225'],
        <String>['225'],
        <String>['rectangle'],
      ]);
      expect(question.isNumericBlank(0), isTrue);
      expect(question.isNumericBlank(1), isTrue);
      expect(question.isNumericBlank(2), isFalse);
    });
  });

  // Les deux formes ajoutées après coup. Leur analyse refuse d'emblée les
  // fautes de contenu qui, sinon, ne se verraient qu'en jouant : une
  // catégorie sans élément, un indice qui vise une catégorie inexistante,
  // une réponse hors de la course du curseur.
  group('Tri en catégories', () {
    Map<String, Object?> tri(Map<String, Object?> extra) => <String, Object?>{
      'id': 'q',
      'kind': 'tri',
      'prompt': 'Range.',
      'explanation': 'Parce que.',
      'categories': <String>['Pairs', 'Impairs'],
      'items': <Object?>[
        <String, Object?>{'text': '2', 'category': 0},
        <String, Object?>{'text': '3', 'category': 1},
      ],
      ...extra,
    };

    test('accepte le rangement exact', () {
      final ClassifyQuestion q =
          Question.fromJson(tri(<String, Object?>{})) as ClassifyQuestion;
      expect(
        q.isSatisfiedBy(const ClassifyAnswer(<int, int>{0: 0, 1: 1})),
        isTrue,
      );
    });

    test('refuse un élément mal rangé', () {
      final ClassifyQuestion q =
          Question.fromJson(tri(<String, Object?>{})) as ClassifyQuestion;
      expect(
        q.isSatisfiedBy(const ClassifyAnswer(<int, int>{0: 1, 1: 0})),
        isFalse,
      );
    });

    test('refuse un rangement incomplet', () {
      final ClassifyQuestion q =
          Question.fromJson(tri(<String, Object?>{})) as ClassifyQuestion;
      expect(
        q.isSatisfiedBy(const ClassifyAnswer(<int, int>{0: 0})),
        isFalse,
      );
    });

    test('refuse une catégorie laissée vide', () {
      expect(
        () => Question.fromJson(
          tri(<String, Object?>{
            'items': <Object?>[
              <String, Object?>{'text': '2', 'category': 0},
              <String, Object?>{'text': '4', 'category': 0},
            ],
          }),
        ),
        throwsFormatException,
      );
    });

    test('refuse un indice de catégorie hors limites', () {
      expect(
        () => Question.fromJson(
          tri(<String, Object?>{
            'items': <Object?>[
              <String, Object?>{'text': '2', 'category': 0},
              <String, Object?>{'text': '3', 'category': 7},
            ],
          }),
        ),
        throwsFormatException,
      );
    });
  });

  group('Estimation', () {
    Map<String, Object?> estim(Map<String, Object?> extra) =>
        <String, Object?>{
          'id': 'q',
          'kind': 'estimation',
          'prompt': 'Estime.',
          'explanation': 'Parce que.',
          'min': 1,
          'max': 100,
          'answer': 50,
          'tolerance': 10,
          ...extra,
        };

    test('accepte une valeur dans la tolérance', () {
      final EstimateQuestion q =
          Question.fromJson(estim(<String, Object?>{})) as EstimateQuestion;
      expect(q.isSatisfiedBy(const NumericAnswer(58)), isTrue);
      expect(q.isSatisfiedBy(const NumericAnswer(40)), isTrue);
    });

    test('refuse une valeur hors tolérance', () {
      final EstimateQuestion q =
          Question.fromJson(estim(<String, Object?>{})) as EstimateQuestion;
      expect(q.isSatisfiedBy(const NumericAnswer(61)), isFalse);
    });

    test('refuse une réponse hors de la course du curseur', () {
      expect(
        () => Question.fromJson(estim(<String, Object?>{'answer': 500})),
        throwsFormatException,
      );
    });

    test('refuse un intervalle vide', () {
      expect(
        () => Question.fromJson(
          estim(<String, Object?>{'min': 10, 'max': 10, 'answer': 10}),
        ),
        throwsFormatException,
      );
    });

    test('refuse une échelle logarithmique partant de zéro', () {
      expect(
        () => Question.fromJson(
          estim(<String, Object?>{'min': 0, 'logarithmic': true}),
        ),
        throwsFormatException,
      );
    });
  });

  group('Écriture des nombres', () {
    test('groupe les milliers', () {
      expect(NumericQuestion.formatNumber(20000), '20\u202f000');
      expect(NumericQuestion.formatNumber(4495), '4\u202f495');
      expect(NumericQuestion.formatNumber(150), '150');
    });

    test('garde la virgule française et ne groupe pas les décimales', () {
      expect(NumericQuestion.formatNumber(12.5), '12,5');
      expect(NumericQuestion.formatNumber(1234.25), '1\u202f234,25');
    });

    test('préserve le signe', () {
      expect(NumericQuestion.formatNumber(-4495), '-4\u202f495');
    });
  });
}
