/// Une matière scientifique du catalogue.
library;

import 'education_level.dart';
import 'json_read.dart';

/// Matière : mathématiques, physique-chimie, informatique, SVT…
///
/// Une matière est un conteneur de chapitres ; elle ne porte aucune
/// progression. Sa couleur n'est pas ici mais dans `SubjectPalettes`, côté
/// présentation.
class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.iconKey,
    required this.levels,
  });

  /// Identifiant stable (`maths`, `physique-chimie`, `informatique`, `svt`).
  final String id;

  /// Nom affiché.
  final String name;

  /// Accroche courte, affichée sous le nom sur la tuile d'accueil.
  final String tagline;

  /// Présentation longue, affichée en tête de l'écran de la matière.
  final String description;

  /// Clé d'icône, résolue côté présentation par `SubjectVisuals`.
  final String iconKey;

  /// Niveaux pour lesquels la matière propose du contenu.
  final List<EducationLevel> levels;

  /// Construit une matière depuis le catalogue JSON.
  ///
  /// Lève une [FormatException] si un champ obligatoire manque : un contenu
  /// invalide doit faire échouer les tests, pas s'afficher à moitié.
  factory Subject.fromJson(Map<String, Object?> json) {
    final String id = json.str('id', context: 'Matière');
    final String ctx = 'Matière "$id"';
    final List<EducationLevel> levels = <EducationLevel>[];
    for (final String raw in json.strings('levels', context: ctx)) {
      final EducationLevel? level = EducationLevel.tryParse(raw);
      if (level == null) {
        throw FormatException('$ctx : niveau inconnu "$raw".');
      }
      levels.add(level);
    }
    if (levels.isEmpty) {
      throw FormatException('$ctx : au moins un niveau est requis.');
    }
    return Subject(
      id: id,
      name: json.str('name', context: ctx),
      tagline: json.str('tagline', context: ctx),
      description: json.str('description', context: ctx),
      iconKey: json.str('icon', context: ctx),
      levels: List<EducationLevel>.unmodifiable(
        levels..sort((a, b) => a.order.compareTo(b.order)),
      ),
    );
  }
}
