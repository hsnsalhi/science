/// Leçons et cartes d'apprentissage.
library;

import 'json_read.dart';
import 'question.dart';

/// Nature d'une leçon.
enum LessonKind {
  /// Apprentissage guidé : on découvre une notion.
  cours('cours', 'Cours'),

  /// Répétition : on consolide par la pratique.
  entrainement('entrainement', 'Entraînement'),

  /// Mise en situation : on applique à un problème complet.
  defi('defi', 'Défi');

  const LessonKind(this.id, this.label);

  final String id;
  final String label;

  static LessonKind parse(String id) {
    for (final LessonKind kind in values) {
      if (kind.id == id) return kind;
    }
    throw FormatException('Type de leçon inconnu : "$id".');
  }
}

/// Nature d'une carte d'apprentissage.
///
/// Une leçon est une suite de cartes que l'élève fait défiler une par une.
/// Découper le cours en cartes typées, plutôt qu'en un long texte, impose de
/// n'avoir qu'une idée par écran — c'est la contrainte qui rend le contenu
/// lisible sur un téléphone.
enum LessonCardKind {
  /// Paragraphe d'explication.
  texte('texte'),

  /// Formule mise en valeur.
  formule('formule'),

  /// Exemple résolu.
  exemple('exemple'),

  /// Astuce ou piège fréquent.
  astuce('astuce'),

  /// Figure interactive à manipuler.
  figure('figure'),

  /// Étape numérotée d'une méthode.
  etape('etape'),

  /// Encadré de synthèse en fin de leçon.
  aRetenir('aRetenir');

  const LessonCardKind(this.id);

  final String id;

  static LessonCardKind parse(String id) {
    for (final LessonCardKind kind in values) {
      if (kind.id == id) return kind;
    }
    throw FormatException('Type de carte inconnu : "$id".');
  }
}

/// Une carte d'apprentissage.
class LessonCard {
  const LessonCard({
    required this.id,
    required this.kind,
    this.title,
    this.body,
    this.formula,
    this.figureId,
    this.bullets = const <String>[],
  });

  final String id;
  final LessonCardKind kind;

  /// Titre de la carte.
  final String? title;

  /// Corps de texte.
  final String? body;

  /// Formule affichée en grand, en notation Unicode (`a² + b² = c²`).
  final String? formula;

  /// Figure interactive à afficher, résolue par `FigureRegistry`.
  final String? figureId;

  /// Points de liste, affichés avec une puce.
  final List<String> bullets;

  factory LessonCard.fromJson(Map<String, Object?> json, String lessonId) {
    final String id = json.str('id', context: 'Carte de "$lessonId"');
    final String ctx = 'Carte "$lessonId/$id"';
    final LessonCardKind kind = LessonCardKind.parse(
      json.str('kind', context: ctx),
    );
    final LessonCard card = LessonCard(
      id: id,
      kind: kind,
      title: json.strOrNull('title'),
      body: json.strOrNull('body'),
      formula: json.strOrNull('formula'),
      figureId: json.strOrNull('figureId'),
      bullets: json.strings('bullets', context: ctx),
    );
    // Garde-fou de contenu : une carte vide passerait inaperçue à la
    // relecture du JSON mais afficherait un écran blanc à l'élève.
    final bool hasSomething =
        card.body != null ||
        card.formula != null ||
        card.figureId != null ||
        card.bullets.isNotEmpty;
    if (!hasSomething) {
      throw FormatException('$ctx : la carte n\'a aucun contenu.');
    }
    if (kind == LessonCardKind.figure && card.figureId == null) {
      throw FormatException('$ctx : une carte "figure" exige "figureId".');
    }
    if (kind == LessonCardKind.formule && card.formula == null) {
      throw FormatException('$ctx : une carte "formule" exige "formula".');
    }
    return card;
  }
}

/// Une leçon : des cartes d'apprentissage puis des questions.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.kind,
    required this.xpReward,
    required this.estimatedMinutes,
    required this.cards,
    required this.questions,
    this.subtitle,
  });

  final String id;
  final String title;

  /// Phrase d'objectif (« À la fin, tu sauras… »).
  final String? subtitle;

  final LessonKind kind;

  /// XP accordés à la première réussite de la leçon.
  final int xpReward;

  /// Durée indicative, affichée avant de commencer.
  final int estimatedMinutes;

  /// Cartes d'apprentissage, dans l'ordre. Vide pour un entraînement pur.
  final List<LessonCard> cards;

  /// Questions d'évaluation, dans l'ordre.
  final List<Question> questions;

  /// `true` si la leçon comporte une évaluation.
  bool get hasQuiz => questions.isNotEmpty;

  factory Lesson.fromJson(Map<String, Object?> json, String chapterId) {
    final String id = json.str('id', context: 'Leçon de "$chapterId"');
    final String ctx = 'Leçon "$chapterId/$id"';
    final List<LessonCard> cards = json
        .objects('cards', context: ctx)
        .map((Map<String, Object?> c) => LessonCard.fromJson(c, id))
        .toList(growable: false);
    final List<Question> questions = json
        .objects('questions', context: ctx)
        .map(Question.fromJson)
        .toList(growable: false);
    if (cards.isEmpty && questions.isEmpty) {
      throw FormatException('$ctx : ni carte ni question.');
    }
    return Lesson(
      id: id,
      title: json.str('title', context: ctx),
      subtitle: json.strOrNull('subtitle'),
      kind: LessonKind.parse(json.str('kind', context: ctx)),
      xpReward: json.integerOr('xp', 20),
      estimatedMinutes: json.integerOr('minutes', 5),
      cards: cards,
      questions: questions,
    );
  }
}
