/// Catalogue de contenu chargé en mémoire.
library;

import '../../domain/models/chapter.dart';
import '../../domain/models/education_level.dart';
import '../../domain/models/lesson.dart';
import '../../domain/models/subject.dart';

/// Tout le contenu pédagogique de l'application, déjà chargé.
///
/// Le contenu est entièrement embarqué et tient en mémoire : quelques
/// centaines de kilo-octets de JSON. Cela permet une navigation synchrone,
/// sans indicateur de chargement nulle part, et un fonctionnement identique
/// en avion ou dans une salle de classe sans réseau.
class ContentCatalog {
  ContentCatalog({required this.subjects, required List<Chapter> chapters})
    : _chapters = List<Chapter>.unmodifiable(_ranger(subjects, chapters));

  /// Range les chapitres par matière, puis par niveau, puis par rang.
  ///
  /// Le rang d'un chapitre n'a de sens qu'au sein d'une matière et d'un
  /// niveau : c'est sa place dans la progression de l'année. Trier
  /// l'ensemble du catalogue sur ce seul rang mêlait les matières — avec
  /// une seule matière pourvue de contenu cela ne se voyait pas, mais dès
  /// la deuxième « Reprendre » envoyait vers le chapitre de plus petit
  /// rang, quelle que soit la matière.
  static List<Chapter> _ranger(List<Subject> subjects, List<Chapter> chapters) {
    final Map<String, int> rangMatiere = <String, int>{
      for (int i = 0; i < subjects.length; i++) subjects[i].id: i,
    };
    final List<Chapter> ranges = List<Chapter>.of(chapters);
    ranges.sort((Chapter a, Chapter b) {
      final int matiere = (rangMatiere[a.subjectId] ?? 1 << 20).compareTo(
        rangMatiere[b.subjectId] ?? 1 << 20,
      );
      if (matiere != 0) return matiere;
      final int niveau = a.level.index.compareTo(b.level.index);
      if (niveau != 0) return niveau;
      return a.order.compareTo(b.order);
    });
    return ranges;
  }

  /// Catalogue vide, utile en test et comme valeur de repli.
  static final ContentCatalog empty = ContentCatalog(
    subjects: const <Subject>[],
    chapters: const <Chapter>[],
  );

  /// Matières, dans l'ordre du catalogue.
  final List<Subject> subjects;

  final List<Chapter> _chapters;

  /// Tous les chapitres, tous niveaux confondus.
  List<Chapter> get chapters => _chapters;

  /// Matière par identifiant, ou `null`.
  Subject? subjectById(String id) {
    for (final Subject subject in subjects) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  /// Chapitre par identifiant, ou `null`.
  Chapter? chapterById(String id) {
    for (final Chapter chapter in _chapters) {
      if (chapter.id == id) return chapter;
    }
    return null;
  }

  /// Chapitres d'une matière pour un niveau, dans l'ordre de progression.
  List<Chapter> chaptersOf(String subjectId, EducationLevel level) => _chapters
      .where((Chapter c) => c.subjectId == subjectId && c.level == level)
      .toList(growable: false);

  /// Chapitres jouables d'un niveau, toutes matières confondues.
  List<Chapter> playableChapters(EducationLevel level) => _chapters
      .where((Chapter c) => c.level == level && c.isPlayable)
      .toList(growable: false);

  /// Leçon désignée par un chapitre et un identifiant, ou `null`.
  Lesson? lesson(String chapterId, String lessonId) =>
      chapterById(chapterId)?.lessonById(lessonId);

  /// Nombre de chapitres jouables d'une matière, tous niveaux confondus.
  int playableCountOf(String subjectId) => _chapters
      .where((Chapter c) => c.subjectId == subjectId && c.isPlayable)
      .length;
}
