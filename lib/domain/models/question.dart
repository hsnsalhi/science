/// Questions d'évaluation et correction des réponses.
library;

import 'json_read.dart';

/// Famille d'une question, pour l'affichage et les statistiques.
enum QuestionKind {
  /// Une seule bonne réponse parmi plusieurs propositions.
  choixUnique('choixUnique'),

  /// Plusieurs bonnes réponses à cocher.
  choixMultiple('choixMultiple'),

  /// Affirmation à valider ou à rejeter.
  vraiFaux('vraiFaux'),

  /// Résultat numérique à saisir, avec unité et tolérance.
  saisieNumerique('saisieNumerique'),

  /// Texte à trous à compléter.
  texteATrous('texteATrous'),

  /// Étapes à remettre dans l'ordre.
  remiseEnOrdre('remiseEnOrdre'),

  /// Paires à associer.
  appariement('appariement'),

  /// Éléments à ranger dans des catégories.
  tri('tri'),

  /// Ordre de grandeur à estimer avec un curseur.
  estimation('estimation');

  const QuestionKind(this.id);

  /// Valeur du champ `kind` dans le JSON.
  final String id;

  static QuestionKind parse(String id) {
    for (final QuestionKind kind in values) {
      if (kind.id == id) return kind;
    }
    throw FormatException('Type de question inconnu : "$id".');
  }
}

/// Réponse saisie par l'élève, avant correction.
///
/// Chaque type de question n'accepte que la forme de réponse qui lui
/// correspond ; une forme inattendue est simplement comptée comme fausse,
/// jamais comme une exception — l'application ne doit pas planter au milieu
/// d'un exercice.
sealed class Answer {
  const Answer();
}

/// Indices des propositions cochées.
final class ChoiceAnswer extends Answer {
  const ChoiceAnswer(this.selected);

  final Set<int> selected;
}

/// Réponse à une affirmation.
final class BooleanAnswer extends Answer {
  const BooleanAnswer(this.value);

  final bool value;
}

/// Valeur numérique saisie.
final class NumericAnswer extends Answer {
  const NumericAnswer(this.value);

  final double value;
}

/// Contenu de chaque trou, dans l'ordre d'apparition.
final class BlanksAnswer extends Answer {
  const BlanksAnswer(this.entries);

  final List<String> entries;
}

/// Ordre proposé, exprimé en indices des éléments d'origine.
final class OrderingAnswer extends Answer {
  const OrderingAnswer(this.order);

  final List<int> order;
}

/// Associations proposées : indice de gauche vers indice de droite.
final class MatchingAnswer extends Answer {
  const MatchingAnswer(this.pairing);

  final Map<int, int> pairing;
}

/// Rangements proposés : indice de l'élément vers indice de la catégorie.
final class ClassifyAnswer extends Answer {
  const ClassifyAnswer(this.placement);

  final Map<int, int> placement;
}

/// Une proposition de réponse.
class AnswerOption {
  const AnswerOption({required this.text, this.isCorrect = false});

  final String text;
  final bool isCorrect;

  factory AnswerOption.fromJson(Map<String, Object?> json, String context) =>
      AnswerOption(
        text: json.str('text', context: context),
        isCorrect: json.boolOr('correct', false),
      );
}

/// Une paire à associer.
class MatchPair {
  const MatchPair({required this.left, required this.right});

  final String left;
  final String right;

  factory MatchPair.fromJson(Map<String, Object?> json, String context) =>
      MatchPair(
        left: json.str('left', context: context),
        right: json.str('right', context: context),
      );
}

/// Un élément à ranger, et la catégorie qui lui revient.
class ClassifyItem {
  const ClassifyItem({required this.text, required this.category});

  final String text;

  /// Indice de la catégorie attendue.
  final int category;

  factory ClassifyItem.fromJson(Map<String, Object?> json, String context) =>
      ClassifyItem(
        text: json.str('text', context: context),
        category: json.integer('category', context: context),
      );
}

/// Question posée à l'élève.
///
/// Classe scellée : ajouter un type d'exercice force le compilateur à signaler
/// tous les endroits (affichage, correction, statistiques) qui doivent être
/// complétés. C'est voulu — un exercice à moitié implémenté ne doit pas
/// pouvoir arriver en production.
sealed class Question {
  const Question({
    required this.id,
    required this.prompt,
    required this.explanation,
    this.hint,
    this.figureId,
  });

  /// Identifiant unique dans la leçon.
  final String id;

  /// Énoncé.
  final String prompt;

  /// Explication affichée après la réponse, juste **ou** fausse.
  ///
  /// Toujours obligatoire : une application d'apprentissage qui se contente
  /// de dire « faux » n'apprend rien. C'est le champ le plus important du
  /// modèle de contenu.
  final String explanation;

  /// Indice facultatif, consultable avant de répondre (sans pénalité).
  final String? hint;

  /// Figure interactive associée, résolue par `FigureRegistry`.
  final String? figureId;

  /// Famille de la question.
  QuestionKind get kind;

  /// `true` si [answer] est juste.
  bool isSatisfiedBy(Answer answer);

  /// Bonne réponse en clair, affichée quand l'élève s'est trompé.
  String get solutionLabel;

  /// Construit la question correspondant au champ `kind`.
  factory Question.fromJson(Map<String, Object?> json) {
    final String id = json.str('id', context: 'Question');
    final String ctx = 'Question "$id"';
    final QuestionKind kind = QuestionKind.parse(
      json.str('kind', context: ctx),
    );
    final String prompt = json.str('prompt', context: ctx);
    final String explanation = json.str('explanation', context: ctx);
    final String? hint = json.strOrNull('hint');
    final String? figureId = json.strOrNull('figureId');

    switch (kind) {
      case QuestionKind.choixUnique:
      case QuestionKind.choixMultiple:
        final List<AnswerOption> options = json
            .objects('options', context: ctx)
            .map((Map<String, Object?> o) => AnswerOption.fromJson(o, ctx))
            .toList(growable: false);
        if (options.length < 2) {
          throw FormatException('$ctx : au moins deux propositions requises.');
        }
        final int correctCount = options
            .where((AnswerOption o) => o.isCorrect)
            .length;
        if (correctCount == 0) {
          throw FormatException('$ctx : aucune proposition marquée correcte.');
        }
        if (kind == QuestionKind.choixUnique && correctCount != 1) {
          throw FormatException(
            '$ctx : "choixUnique" attend exactement une bonne réponse '
            '(trouvé $correctCount).',
          );
        }
        final bool shuffle = json.boolOr('shuffle', true);
        return kind == QuestionKind.choixUnique
            ? SingleChoiceQuestion(
                id: id,
                prompt: prompt,
                explanation: explanation,
                hint: hint,
                figureId: figureId,
                options: options,
                shuffle: shuffle,
              )
            : MultipleChoiceQuestion(
                id: id,
                prompt: prompt,
                explanation: explanation,
                hint: hint,
                figureId: figureId,
                options: options,
                shuffle: shuffle,
              );

      case QuestionKind.vraiFaux:
        final Object? expected = json['answer'];
        if (expected is! bool) {
          throw FormatException('$ctx : champ booléen "answer" manquant.');
        }
        return TrueFalseQuestion(
          id: id,
          prompt: prompt,
          explanation: explanation,
          hint: hint,
          figureId: figureId,
          expected: expected,
        );

      case QuestionKind.saisieNumerique:
        return NumericQuestion(
          id: id,
          prompt: prompt,
          explanation: explanation,
          hint: hint,
          figureId: figureId,
          expected: json.number('answer', context: ctx),
          tolerance: json.numberOr('tolerance', 0.001),
          unit: json.strOrNull('unit'),
        );

      case QuestionKind.texteATrous:
        final String template = json.str('template', context: ctx);
        final List<List<String>> accepted = json
            .objects('blanks', context: ctx)
            .map(
              (Map<String, Object?> b) => b.strings('accepted', context: ctx),
            )
            .toList(growable: false);
        final int blankCount = RegExp(FillBlanksQuestion.blankMarker)
            .allMatches(template)
            .length;
        if (blankCount == 0) {
          throw FormatException(
            '$ctx : le modèle ne contient aucun trou "___".',
          );
        }
        if (accepted.length != blankCount) {
          throw FormatException(
            '$ctx : $blankCount trou(s) dans le modèle mais '
            '${accepted.length} liste(s) de réponses.',
          );
        }
        for (final List<String> entry in accepted) {
          if (entry.isEmpty) {
            throw FormatException('$ctx : un trou n\'a aucune réponse admise.');
          }
        }
        return FillBlanksQuestion(
          id: id,
          prompt: prompt,
          explanation: explanation,
          hint: hint,
          figureId: figureId,
          template: template,
          accepted: accepted,
        );

      case QuestionKind.remiseEnOrdre:
        final List<String> items = json.strings('items', context: ctx);
        if (items.length < 2) {
          throw FormatException('$ctx : au moins deux éléments requis.');
        }
        return OrderingQuestion(
          id: id,
          prompt: prompt,
          explanation: explanation,
          hint: hint,
          figureId: figureId,
          items: items,
        );

      case QuestionKind.appariement:
        final List<MatchPair> pairs = json
            .objects('pairs', context: ctx)
            .map((Map<String, Object?> p) => MatchPair.fromJson(p, ctx))
            .toList(growable: false);
        if (pairs.length < 2) {
          throw FormatException('$ctx : au moins deux paires requises.');
        }
        return MatchingQuestion(
          id: id,
          prompt: prompt,
          explanation: explanation,
          hint: hint,
          figureId: figureId,
          pairs: pairs,
        );

      case QuestionKind.tri:
        final List<String> categories = json.strings(
          'categories',
          context: ctx,
        );
        if (categories.length < 2) {
          throw FormatException('$ctx : au moins deux catégories requises.');
        }
        final List<ClassifyItem> items = json
            .objects('items', context: ctx)
            .map((Map<String, Object?> i) {
              final ClassifyItem item = ClassifyItem.fromJson(i, ctx);
              if (item.category < 0 || item.category >= categories.length) {
                throw FormatException(
                  '$ctx : « ${item.text} » vise la catégorie '
                  '${item.category}, hors des ${categories.length} '
                  'déclarées.',
                );
              }
              return item;
            })
            .toList(growable: false);
        if (items.length < 2) {
          throw FormatException('$ctx : au moins deux éléments requis.');
        }
        // Une catégorie vide est presque toujours une faute de saisie, et
        // elle fausse l'exercice : l'élève la laisse de côté sans risque.
        for (int c = 0; c < categories.length; c++) {
          if (!items.any((ClassifyItem i) => i.category == c)) {
            throw FormatException(
              '$ctx : la catégorie « ${categories[c]} » n\'a aucun élément.',
            );
          }
        }
        return ClassifyQuestion(
          id: id,
          prompt: prompt,
          explanation: explanation,
          hint: hint,
          figureId: figureId,
          categories: categories,
          items: items,
        );

      case QuestionKind.estimation:
        final double min = json.number('min', context: ctx);
        final double max = json.number('max', context: ctx);
        final double attendu = json.number('answer', context: ctx);
        if (max <= min) {
          throw FormatException('$ctx : « max » doit dépasser « min ».');
        }
        if (attendu < min || attendu > max) {
          throw FormatException(
            '$ctx : la réponse $attendu sort de l\'intervalle [$min, $max].',
          );
        }
        final bool logarithmique = json['logarithmic'] == true;
        if (logarithmique && min <= 0) {
          throw FormatException(
            '$ctx : une échelle logarithmique exige un minimum positif.',
          );
        }
        return EstimateQuestion(
          id: id,
          prompt: prompt,
          explanation: explanation,
          hint: hint,
          figureId: figureId,
          min: min,
          max: max,
          expected: attendu,
          tolerance: json.numberOr('tolerance', (max - min) / 10),
          unit: json.strOrNull('unit'),
          logarithmic: logarithmique,
        );
    }
  }
}

/// Question à choix unique.
final class SingleChoiceQuestion extends Question {
  const SingleChoiceQuestion({
    required super.id,
    required super.prompt,
    required super.explanation,
    required this.options,
    required this.shuffle,
    super.hint,
    super.figureId,
  });

  final List<AnswerOption> options;

  /// Mélanger les propositions à l'affichage (défaut : oui).
  final bool shuffle;

  /// Indice de la bonne proposition.
  int get correctIndex => options.indexWhere((AnswerOption o) => o.isCorrect);

  @override
  QuestionKind get kind => QuestionKind.choixUnique;

  @override
  bool isSatisfiedBy(Answer answer) =>
      answer is ChoiceAnswer &&
      answer.selected.length == 1 &&
      answer.selected.single == correctIndex;

  @override
  String get solutionLabel => options[correctIndex].text;
}

/// Question à choix multiple : toutes les bonnes réponses, et elles seules.
final class MultipleChoiceQuestion extends Question {
  const MultipleChoiceQuestion({
    required super.id,
    required super.prompt,
    required super.explanation,
    required this.options,
    required this.shuffle,
    super.hint,
    super.figureId,
  });

  final List<AnswerOption> options;
  final bool shuffle;

  Set<int> get correctIndices => <int>{
    for (int i = 0; i < options.length; i++)
      if (options[i].isCorrect) i,
  };

  @override
  QuestionKind get kind => QuestionKind.choixMultiple;

  @override
  bool isSatisfiedBy(Answer answer) {
    if (answer is! ChoiceAnswer) return false;
    final Set<int> expected = correctIndices;
    return answer.selected.length == expected.length &&
        answer.selected.containsAll(expected);
  }

  @override
  String get solutionLabel =>
      correctIndices.map((int i) => options[i].text).join(' · ');
}

/// Affirmation vraie ou fausse.
final class TrueFalseQuestion extends Question {
  const TrueFalseQuestion({
    required super.id,
    required super.prompt,
    required super.explanation,
    required this.expected,
    super.hint,
    super.figureId,
  });

  final bool expected;

  @override
  QuestionKind get kind => QuestionKind.vraiFaux;

  @override
  bool isSatisfiedBy(Answer answer) =>
      answer is BooleanAnswer && answer.value == expected;

  @override
  String get solutionLabel => expected ? 'Vrai' : 'Faux';
}

/// Résultat numérique à calculer.
final class NumericQuestion extends Question {
  const NumericQuestion({
    required super.id,
    required super.prompt,
    required super.explanation,
    required this.expected,
    required this.tolerance,
    this.unit,
    super.hint,
    super.figureId,
  });

  final double expected;

  /// Écart absolu toléré. Permet d'accepter une valeur arrondie — un élève
  /// qui écrit `7,07` pour `√50` a compris l'exercice.
  final double tolerance;

  /// Unité attendue, affichée en suffixe du champ (`cm`, `m/s`…).
  final String? unit;

  @override
  QuestionKind get kind => QuestionKind.saisieNumerique;

  @override
  bool isSatisfiedBy(Answer answer) =>
      answer is NumericAnswer && (answer.value - expected).abs() <= tolerance;

  @override
  String get solutionLabel {
    final String value = formatNumber(expected);
    return unit == null ? value : '$value $unit';
  }

  /// Formate un nombre à la française, sans décimales inutiles.
  static String formatNumber(double value) {
    final String raw = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
    final List<String> parties = raw.split('.');
    // Séparateur de milliers : « 20000 millions de km » se lit mal, et
    // l'usage français groupe par trois avec une espace insécable. Seule
    // la partie entière est groupée ; les décimales ne le sont pas.
    final bool negatif = parties[0].startsWith('-');
    final String entier = negatif ? parties[0].substring(1) : parties[0];
    final String groupe = entier.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (Match m) => '${m[1]}\u202f',
    );
    final String signe = negatif ? '-' : '';
    return parties.length > 1
        ? '$signe$groupe,${parties[1]}'
        : '$signe$groupe';
  }

  /// Lit une saisie d'élève : virgule décimale et espaces acceptés.
  static double? parseInput(String input) {
    final String cleaned = input
        .trim()
        .replaceAll(' ', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}

/// Texte à trous.
final class FillBlanksQuestion extends Question {
  const FillBlanksQuestion({
    required super.id,
    required super.prompt,
    required super.explanation,
    required this.template,
    required this.accepted,
    super.hint,
    super.figureId,
  });

  /// Marqueur de trou dans [template].
  static const String blankMarker = '___';

  /// Phrase ou formule, les trous étant notés `___`.
  final String template;

  /// Réponses admises pour chaque trou, dans l'ordre.
  final List<List<String>> accepted;

  /// Nombre de trous.
  int get blankCount => accepted.length;

  /// Morceaux de texte entre les trous (`blankCount + 1` éléments).
  List<String> get segments => template.split(blankMarker);

  /// `true` si le trou d'indice [index] n'admet que des nombres.
  ///
  /// Se déduit des réponses acceptées plutôt que d'un champ à renseigner :
  /// un trou dont toutes les réponses sont des nombres ne peut pas en
  /// attendre autre chose. Cela évite d'avoir à annoter chaque trou du
  /// contenu, et reste juste quand un même exercice mêle un calcul et une
  /// conclusion en toutes lettres — « 15² = ___ » et « le triangle est
  /// donc ___ » n'appellent pas le même clavier.
  bool isNumericBlank(int index) {
    final List<String> reponses = accepted[index];
    return reponses.isNotEmpty &&
        reponses.every(
          (String a) => NumericQuestion.parseInput(a) != null,
        );
  }

  @override
  QuestionKind get kind => QuestionKind.texteATrous;

  @override
  bool isSatisfiedBy(Answer answer) {
    if (answer is! BlanksAnswer) return false;
    if (answer.entries.length != blankCount) return false;
    for (int i = 0; i < blankCount; i++) {
      final String given = normalize(answer.entries[i]);
      final bool ok = accepted[i].any((String a) => normalize(a) == given);
      if (!ok) return false;
    }
    return true;
  }

  @override
  String get solutionLabel =>
      accepted.map((List<String> a) => a.first).join(' · ');

  /// Normalise une saisie pour la comparaison.
  ///
  /// On ignore la casse, les accents, les espaces superflus et la notation des
  /// exposants : « Hypoténuse », « hypotenuse » et « HYPOTÉNUSE » sont la même
  /// réponse, et `c²` vaut `c2`. L'orthographe exacte n'est pas l'objet de
  /// l'exercice de sciences.
  static String normalize(String input) {
    const String accented = 'àâäáãåçèéêëìíîïñòóôöõùúûüýÿœæ';
    const String plain = 'aaaaaaceeeeiiiinooooouuuuyyoa';
    final StringBuffer buffer = StringBuffer();
    for (final int rune in input.toLowerCase().trim().runes) {
      final String char = String.fromCharCode(rune);
      switch (char) {
        case '²':
          buffer.write('2');
        case '³':
          buffer.write('3');
        case ' ':
        case ' ':
        case '-':
        case "'":
        case '’':
          // Espaces, traits d'union et apostrophes ne discriminent pas.
          break;
        default:
          final int index = accented.indexOf(char);
          buffer.write(index >= 0 ? plain[index] : char);
      }
    }
    return buffer.toString();
  }
}

/// Étapes à remettre dans l'ordre.
///
/// [items] est stocké **dans le bon ordre** ; c'est l'affichage qui mélange.
final class OrderingQuestion extends Question {
  const OrderingQuestion({
    required super.id,
    required super.prompt,
    required super.explanation,
    required this.items,
    super.hint,
    super.figureId,
  });

  final List<String> items;

  @override
  QuestionKind get kind => QuestionKind.remiseEnOrdre;

  @override
  bool isSatisfiedBy(Answer answer) {
    if (answer is! OrderingAnswer) return false;
    if (answer.order.length != items.length) return false;
    for (int i = 0; i < items.length; i++) {
      if (answer.order[i] != i) return false;
    }
    return true;
  }

  @override
  String get solutionLabel => items.join(' → ');
}

/// Paires à associer.
final class MatchingQuestion extends Question {
  const MatchingQuestion({
    required super.id,
    required super.prompt,
    required super.explanation,
    required this.pairs,
    super.hint,
    super.figureId,
  });

  final List<MatchPair> pairs;

  @override
  QuestionKind get kind => QuestionKind.appariement;

  @override
  bool isSatisfiedBy(Answer answer) {
    if (answer is! MatchingAnswer) return false;
    if (answer.pairing.length != pairs.length) return false;
    for (int i = 0; i < pairs.length; i++) {
      if (answer.pairing[i] != i) return false;
    }
    return true;
  }

  @override
  String get solutionLabel =>
      pairs.map((MatchPair p) => '${p.left} → ${p.right}').join(' · ');
}

/// Éléments à ranger dans des catégories.
final class ClassifyQuestion extends Question {
  const ClassifyQuestion({
    required super.id,
    required super.prompt,
    required super.explanation,
    required this.categories,
    required this.items,
    super.hint,
    super.figureId,
  });

  /// Intitulés des catégories, dans l'ordre d'affichage.
  final List<String> categories;

  final List<ClassifyItem> items;

  @override
  QuestionKind get kind => QuestionKind.tri;

  @override
  bool isSatisfiedBy(Answer answer) {
    if (answer is! ClassifyAnswer) return false;
    if (answer.placement.length != items.length) return false;
    for (int i = 0; i < items.length; i++) {
      if (answer.placement[i] != items[i].category) return false;
    }
    return true;
  }

  @override
  String get solutionLabel => <String>[
    for (int c = 0; c < categories.length; c++)
      '${categories[c]} : '
          '${items.where((ClassifyItem i) => i.category == c).map((ClassifyItem i) => i.text).join(', ')}',
  ].join(' · ');
}

/// Ordre de grandeur à estimer au curseur.
///
/// Ce type ne demande pas un calcul mais un jugement : viser la bonne
/// dizaine de millions de kilomètres, la bonne poignée de minutes. La
/// tolérance est donc large par construction — l'exercice échoue s'il se
/// transforme en loterie du dixième près.
final class EstimateQuestion extends Question {
  const EstimateQuestion({
    required super.id,
    required super.prompt,
    required super.explanation,
    required this.min,
    required this.max,
    required this.expected,
    required this.tolerance,
    this.unit,
    this.logarithmic = false,
    super.hint,
    super.figureId,
  });

  final double min;
  final double max;
  final double expected;

  /// Écart absolu admis, dans l'unité de la question.
  final double tolerance;

  final String? unit;

  /// Échelle logarithmique du curseur.
  ///
  /// N'agit que sur la course du curseur, pas sur la correction : un
  /// intervalle qui va de l'année-lumière au kilomètre est inutilisable en
  /// échelle linéaire, mais la réponse reste jugée sur un écart absolu,
  /// annoncé dans le contenu.
  final bool logarithmic;

  @override
  QuestionKind get kind => QuestionKind.estimation;

  @override
  bool isSatisfiedBy(Answer answer) =>
      answer is NumericAnswer &&
      (answer.value - expected).abs() <= tolerance;

  @override
  String get solutionLabel {
    final String value = NumericQuestion.formatNumber(expected);
    return unit == null ? value : '$value $unit';
  }
}
