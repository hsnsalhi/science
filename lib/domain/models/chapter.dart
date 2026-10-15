/// Chapitres du catalogue.
library;

import 'education_level.dart';
import 'json_read.dart';
import 'lesson.dart';

/// État de publication d'un chapitre.
enum ChapterStatus {
  /// Contenu disponible et jouable.
  disponible('disponible'),

  /// Annoncé au catalogue, contenu en cours d'écriture.
  bientot('bientot');

  const ChapterStatus(this.id);

  final String id;

  static ChapterStatus parse(String? id) {
    for (final ChapterStatus status in values) {
      if (status.id == id) return status;
    }
    return ChapterStatus.bientot;
  }
}

/// Un chapitre : l'unité que l'élève choisit depuis l'écran d'une matière.
///
/// Les chapitres annoncés mais non écrits sont volontairement présents au
/// catalogue avec [ChapterStatus.bientot] : l'élève voit la carte complète du
/// programme et sait ce qui arrive, au lieu de découvrir une matière qui a
/// l'air vide.
class Chapter {
  const Chapter({
    required this.id,
    required this.subjectId,
    required this.level,
    required this.title,
    required this.summary,
    required this.order,
    required this.status,
    required this.lessons,
    this.contentPath,
    this.objectives = const <String>[],
    this.grades = const <String>[],
  });

  final String id;
  final String subjectId;
  final EducationLevel level;
  final String title;

  /// Résumé d'une phrase, affiché sur la carte du chapitre.
  final String summary;

  /// Position dans la progression de la matière pour ce niveau.
  final int order;

  final ChapterStatus status;

  /// Classes concernées par le chapitre, dans l'ordre du programme
  /// (« 5e », « 4e »…). Vide si le programme ne l'attache à aucune année.
  final List<String> grades;

  /// Objectifs pédagogiques, affichés avant de commencer.
  final List<String> objectives;

  /// Chemin du fichier de contenu, relatif à `assets/content/`.
  final String? contentPath;

  /// Leçons du chapitre ; vide tant que le contenu n'est pas chargé.
  final List<Lesson> lessons;

  /// Durée totale indicative du chapitre.
  int get estimatedMinutes =>
      lessons.fold(0, (int sum, Lesson l) => sum + l.estimatedMinutes);

  /// Somme des XP disponibles dans le chapitre.
  int get totalXp => lessons.fold(0, (int sum, Lesson l) => sum + l.xpReward);

  /// `true` si le chapitre est réellement jouable.
  bool get isPlayable =>
      status == ChapterStatus.disponible && lessons.isNotEmpty;

  /// Retrouve une leçon par identifiant.
  Lesson? lessonById(String lessonId) {
    for (final Lesson lesson in lessons) {
      if (lesson.id == lessonId) return lesson;
    }
    return null;
  }

  /// Copie du chapitre avec ses leçons chargées.
  Chapter withLessons(List<Lesson> loaded) => Chapter(
    id: id,
    subjectId: subjectId,
    level: level,
    title: title,
    summary: summary,
    order: order,
    status: status,
    grades: grades,
    objectives: objectives,
    contentPath: contentPath,
    lessons: loaded,
  );

  /// Lit une entrée de chapitre du catalogue (sans ses leçons).
  factory Chapter.fromCatalogJson(Map<String, Object?> json) {
    final String id = json.str('id', context: 'Chapitre');
    final String ctx = 'Chapitre "$id"';
    final String levelId = json.str('level', context: ctx);
    final EducationLevel? level = EducationLevel.tryParse(levelId);
    if (level == null) {
      throw FormatException('$ctx : niveau inconnu "$levelId".');
    }
    final ChapterStatus status = ChapterStatus.parse(json.strOrNull('status'));
    final String? contentPath = json.strOrNull('content');
    if (status == ChapterStatus.disponible && contentPath == null) {
      throw FormatException(
        '$ctx : un chapitre "disponible" exige un champ "content".',
      );
    }
    return Chapter(
      id: id,
      subjectId: json.str('subject', context: ctx),
      level: level,
      title: json.str('title', context: ctx),
      summary: json.str('summary', context: ctx),
      order: json.integerOr('order', 0),
      status: status,
      grades: json.strings('grades', context: ctx),
      objectives: json.strings('objectives', context: ctx),
      contentPath: contentPath,
      lessons: const <Lesson>[],
    );
  }

  /// Lit le fichier de contenu d'un chapitre et renvoie ses leçons.
  static List<Lesson> lessonsFromJson(
    Map<String, Object?> json,
    String chapterId,
  ) {
    final String declaredId = json.str('chapter', context: 'Contenu');
    if (declaredId != chapterId) {
      throw FormatException(
        'Contenu de "$chapterId" : le fichier déclare "$declaredId". '
        'Le champ "chapter" doit reprendre l\'identifiant du catalogue.',
      );
    }
    final List<Lesson> lessons = json
        .objects('lessons', context: 'Contenu de "$chapterId"')
        .map((Map<String, Object?> l) => Lesson.fromJson(l, chapterId))
        .toList(growable: false);
    if (lessons.isEmpty) {
      throw FormatException('Contenu de "$chapterId" : aucune leçon.');
    }
    return lessons;
  }
}
