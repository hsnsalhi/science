/// Machine à états d'une session de questions.
library;

import 'dart:math';

import '../models/progress.dart';
import '../models/question.dart';
import 'xp_engine.dart';

/// Étape courante d'une session.
enum QuizPhase {
  /// L'élève compose sa réponse.
  answering,

  /// La réponse vient d'être validée, le retour est affiché.
  feedback,

  /// Toutes les questions ont été traitées.
  finished,
}

/// Issue de la validation qui vient d'avoir lieu.
enum QuizVerdict {
  /// Bonne réponse.
  correct,

  /// Réponse fausse, un nouvel essai est proposé.
  retry,

  /// Réponse fausse, la solution est révélée.
  revealed,
}

/// Historique d'une question dans la session.
class QuestionAttempt {
  const QuestionAttempt({
    this.tries = 0,
    this.solved = false,
    this.solvedFirstTry = false,
    this.xpEarned = 0,
  });

  /// Nombre de validations effectuées.
  final int tries;

  /// `true` si la question a fini par être résolue.
  final bool solved;

  /// `true` si elle a été résolue dès la première validation.
  final bool solvedFirstTry;

  /// XP accordés pour cette question.
  final int xpEarned;
}

/// Session de questions, immuable.
///
/// Chaque interaction renvoie une nouvelle session : l'état est reproductible,
/// ce qui rend le parcours complet testable sans construire un seul widget, et
/// permet au retour arrière de ne jamais laisser l'écran dans un état bancal.
///
/// Le déroulé d'une question est volontairement en trois temps :
/// réponse → **retour expliqué** → suite. Le retour est obligatoire, y compris
/// quand la réponse est juste : c'est là que se fait l'apprentissage.
class QuizSession {
  const QuizSession({
    required this.questions,
    required this.displayOrder,
    required this.matchOrder,
    required this.index,
    required this.phase,
    required this.attempts,
    this.draft,
    this.verdict,
    this.hintRevealed = false,
  });

  /// Nombre d'essais avant révélation de la solution.
  static const int maxTries = 2;

  /// Questions de la session, dans l'ordre.
  final List<Question> questions;

  /// Permutation d'affichage par question : indices d'origine, dans l'ordre
  /// présenté. Mélanger à l'affichage et non dans le contenu permet de garder
  /// un JSON lisible, où la bonne réponse est écrite là où c'est naturel.
  final Map<String, List<int>> displayOrder;

  /// Permutation de la colonne de droite des questions d'appariement.
  final Map<String, List<int>> matchOrder;

  /// Index de la question courante.
  final int index;

  final QuizPhase phase;

  /// Réponse en cours de composition.
  final Answer? draft;

  /// Issue de la dernière validation, pendant [QuizPhase.feedback].
  final QuizVerdict? verdict;

  /// `true` si l'indice de la question courante est affiché.
  final bool hintRevealed;

  /// Historique par identifiant de question.
  final Map<String, QuestionAttempt> attempts;

  /// Démarre une session.
  ///
  /// [random] est injectable pour rendre les tests déterministes.
  factory QuizSession.start(List<Question> questions, {Random? random}) {
    final Random rng = random ?? Random();
    final Map<String, List<int>> display = <String, List<int>>{};
    final Map<String, List<int>> match = <String, List<int>>{};
    for (final Question question in questions) {
      switch (question) {
        case SingleChoiceQuestion(
          :final List<AnswerOption> options,
          :final bool shuffle,
        ):
          display[question.id] = _permutation(options.length, rng, shuffle);
        case MultipleChoiceQuestion(
          :final List<AnswerOption> options,
          :final bool shuffle,
        ):
          display[question.id] = _permutation(options.length, rng, shuffle);
        case OrderingQuestion(:final List<String> items):
          display[question.id] = _shuffledNonIdentity(items.length, rng);
        case MatchingQuestion(:final List<MatchPair> pairs):
          display[question.id] = _permutation(pairs.length, rng, false);
          match[question.id] = _shuffledNonIdentity(pairs.length, rng);
        case ClassifyQuestion(:final List<ClassifyItem> items):
          // Les éléments arrivent mélangés : rangés dans l'ordre des
          // catégories, le premier de chaque groupe donnerait la réponse.
          display[question.id] = _shuffledNonIdentity(items.length, rng);
        case EstimateQuestion():
        case TrueFalseQuestion():
        case NumericQuestion():
        case FillBlanksQuestion():
          break;
      }
    }
    return QuizSession(
      questions: questions,
      displayOrder: Map<String, List<int>>.unmodifiable(display),
      matchOrder: Map<String, List<int>>.unmodifiable(match),
      index: 0,
      phase: questions.isEmpty ? QuizPhase.finished : QuizPhase.answering,
      attempts: const <String, QuestionAttempt>{},
    );
  }

  /// Question courante, ou `null` si la session est terminée.
  Question? get current =>
      index >= 0 && index < questions.length ? questions[index] : null;

  /// Nombre total de questions.
  int get total => questions.length;

  /// Progression dans la session, de 0 à 1.
  double get progress {
    if (questions.isEmpty) return 1;
    final int done = phase == QuizPhase.finished ? total : index;
    return (done / total).clamp(0.0, 1.0);
  }

  /// Historique de la question courante.
  QuestionAttempt get currentAttempt =>
      attempts[current?.id] ?? const QuestionAttempt();

  /// Questions résolues du premier coup.
  int get solvedFirstTry =>
      attempts.values.where((QuestionAttempt a) => a.solvedFirstTry).length;

  /// Questions finalement résolues.
  int get solved =>
      attempts.values.where((QuestionAttempt a) => a.solved).length;

  /// XP cumulés, bonus de sans-faute compris.
  int get xpEarned {
    final int base = attempts.values.fold<int>(
      0,
      (int sum, QuestionAttempt a) => sum + a.xpEarned,
    );
    return base + (isPerfect ? XpEngine.perfectBonus : 0);
  }

  /// Réussites d'affilée du premier coup, en remontant depuis la question
  /// courante.
  ///
  /// Sert au compteur de série affiché pendant le quiz : enchaîner trois
  /// bonnes réponses doit se voir, sinon la troisième ne vaut pas plus que
  /// la première. Une erreur, même rattrapée au second essai, remet le
  /// compteur à zéro — c'est ce qui fait la valeur de la série.
  int get combo {
    int serie = 0;
    for (int i = index; i >= 0 && i < questions.length; i--) {
      final QuestionAttempt? attempt = attempts[questions[i].id];
      if (attempt == null || !attempt.solvedFirstTry) break;
      serie++;
    }
    return serie;
  }

  /// `true` si toutes les questions ont été réussies du premier coup.
  bool get isPerfect => total > 0 && solvedFirstTry == total;

  /// `true` si la réponse en cours peut être validée.
  bool get canValidate {
    final Question? question = current;
    if (question == null || phase != QuizPhase.answering) return false;
    return _isComplete(question, draft);
  }

  /// Met à jour la réponse en cours.
  QuizSession withDraft(Answer? answer) => phase == QuizPhase.answering
      ? _copyWith(draft: answer, clearDraft: answer == null)
      : this;

  /// Affiche l'indice de la question courante. Sans pénalité d'XP : demander
  /// de l'aide avant de se tromper est un bon réflexe, pas une triche.
  QuizSession revealHint() => _copyWith(hintRevealed: true);

  /// Valide la réponse en cours et passe au retour.
  /// Valide la réponse en cours.
  ///
  /// [rapide] indique que le chronomètre du défi n'était pas écoulé : la
  /// bonne réponse du premier coup vaut alors un bonus.
  QuizSession validate({bool rapide = false}) {
    final Question? question = current;
    if (question == null || !canValidate) return this;

    final bool correct = question.isSatisfiedBy(draft!);
    final QuestionAttempt previous = currentAttempt;
    final int tries = previous.tries + 1;
    final bool firstTry = correct && tries == 1;

    final QuizVerdict result = correct
        ? QuizVerdict.correct
        : (tries < maxTries ? QuizVerdict.retry : QuizVerdict.revealed);

    final Map<String, QuestionAttempt> next = Map<String, QuestionAttempt>.of(
      attempts,
    );
    next[question.id] = QuestionAttempt(
      tries: tries,
      solved: correct,
      solvedFirstTry: firstTry,
      xpEarned: correct
          ? XpEngine.xpForAnswer(firstTry: firstTry, rapide: rapide)
          : 0,
    );

    return _copyWith(
      phase: QuizPhase.feedback,
      verdict: result,
      attempts: next,
    );
  }

  /// Quitte le retour : nouvel essai, ou question suivante.
  QuizSession advance() {
    if (phase != QuizPhase.feedback) return this;
    if (verdict == QuizVerdict.retry) {
      // Nouvel essai sur la même question : on efface la réponse fautive mais
      // on garde l'indice visible s'il a été demandé.
      return _copyWith(
        phase: QuizPhase.answering,
        clearDraft: true,
        clearVerdict: true,
      );
    }
    final int nextIndex = index + 1;
    if (nextIndex >= questions.length) {
      return _copyWith(
        phase: QuizPhase.finished,
        index: questions.length,
        clearDraft: true,
        clearVerdict: true,
      );
    }
    return _copyWith(
      phase: QuizPhase.answering,
      index: nextIndex,
      clearDraft: true,
      clearVerdict: true,
      hintRevealed: false,
    );
  }

  /// Construit le résultat à enregistrer dans la progression.
  LessonOutcome toOutcome({
    required String chapterId,
    required String lessonId,
    required bool firstTimeCompleted,
  }) {
    return LessonOutcome(
      chapterId: chapterId,
      lessonId: lessonId,
      correct: solvedFirstTry,
      total: total,
      xpEarned: xpEarned,
      firstTimeCompleted: firstTimeCompleted,
    );
  }

  /// `true` si [answer] est suffisamment renseignée pour être validée.
  ///
  /// Évite qu'un bouton « Valider » actif ne compte un essai perdu alors que
  /// l'élève n'a encore rien choisi.
  static bool _isComplete(Question question, Answer? answer) {
    if (answer == null) return false;
    return switch (question) {
      SingleChoiceQuestion() =>
        answer is ChoiceAnswer && answer.selected.length == 1,
      MultipleChoiceQuestion() =>
        answer is ChoiceAnswer && answer.selected.isNotEmpty,
      TrueFalseQuestion() => answer is BooleanAnswer,
      NumericQuestion() => answer is NumericAnswer,
      FillBlanksQuestion(:final int blankCount) =>
        answer is BlanksAnswer &&
            answer.entries.length == blankCount &&
            answer.entries.every((String e) => e.trim().isNotEmpty),
      OrderingQuestion(:final List<String> items) =>
        answer is OrderingAnswer && answer.order.length == items.length,
      MatchingQuestion(:final List<MatchPair> pairs) =>
        answer is MatchingAnswer && answer.pairing.length == pairs.length,
      ClassifyQuestion(:final List<ClassifyItem> items) =>
        answer is ClassifyAnswer && answer.placement.length == items.length,
      // Le curseur porte toujours une valeur : dès qu'on y a touché, la
      // réponse est complète.
      EstimateQuestion() => answer is NumericAnswer,
    };
  }

  /// Permutation de [length] éléments, mélangée si [shuffle].
  static List<int> _permutation(int length, Random rng, bool shuffle) {
    final List<int> indices = List<int>.generate(length, (int i) => i);
    if (shuffle) indices.shuffle(rng);
    return List<int>.unmodifiable(indices);
  }

  /// Permutation mélangée, différente de l'ordre d'origine quand c'est
  /// possible : une remise en ordre déjà dans le bon ordre n'est pas un
  /// exercice.
  static List<int> _shuffledNonIdentity(int length, Random rng) {
    if (length < 2) return List<int>.unmodifiable(<int>[0]);
    List<int> candidate = List<int>.generate(length, (int i) => i);
    for (int attempt = 0; attempt < 8; attempt++) {
      candidate.shuffle(rng);
      final bool identity = () {
        for (int i = 0; i < length; i++) {
          if (candidate[i] != i) return false;
        }
        return true;
      }();
      if (!identity) return List<int>.unmodifiable(candidate);
    }
    // Repli déterministe : une simple rotation n'est jamais l'identité.
    candidate = <int>[for (int i = 0; i < length; i++) (i + 1) % length];
    return List<int>.unmodifiable(candidate);
  }

  QuizSession _copyWith({
    int? index,
    QuizPhase? phase,
    Answer? draft,
    QuizVerdict? verdict,
    bool? hintRevealed,
    Map<String, QuestionAttempt>? attempts,
    bool clearDraft = false,
    bool clearVerdict = false,
  }) {
    return QuizSession(
      questions: questions,
      displayOrder: displayOrder,
      matchOrder: matchOrder,
      index: index ?? this.index,
      phase: phase ?? this.phase,
      draft: clearDraft ? null : (draft ?? this.draft),
      verdict: clearVerdict ? null : (verdict ?? this.verdict),
      hintRevealed: hintRevealed ?? this.hintRevealed,
      attempts: attempts ?? this.attempts,
    );
  }
}
