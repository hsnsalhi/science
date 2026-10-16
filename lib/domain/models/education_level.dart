/// Les quatre niveaux scolaires couverts par Eurêka.
library;

/// Niveau scolaire d'un chapitre et de l'élève.
///
/// L'identifiant [id] est la valeur écrite dans les fichiers de contenu JSON ;
/// il ne doit jamais changer sans migration du contenu.
enum EducationLevel {
  primaire(
    id: 'primaire',
    label: 'Primaire',
    grades: 'CP à CM2',
    description: 'Découvrir en manipulant, en observant et en jouant.',
    order: 0,
  ),
  college(
    id: 'college',
    label: 'Collège',
    grades: 'de la 6e à la 3e',
    description: 'Comprendre les règles et apprendre à raisonner.',
    order: 1,
  ),
  lycee(
    id: 'lycee',
    label: 'Lycée',
    grades: 'de la 2de à la Terminale',
    description: 'Démontrer, modéliser et préparer le supérieur.',
    order: 2,
  ),
  universite(
    id: 'universite',
    label: 'Université',
    grades: 'Licence et plus',
    description: 'Formaliser, généraliser et explorer en profondeur.',
    order: 3,
  );

  const EducationLevel({
    required this.id,
    required this.label,
    required this.grades,
    required this.description,
    required this.order,
  });

  /// Identifiant stable utilisé dans le JSON et le stockage local.
  final String id;

  /// Nom affiché ailleurs que dans une phrase.
  final String label;

  /// Classes concernées, affichées en sous-titre.
  final String grades;

  /// Promesse pédagogique du niveau, affichée à l'onboarding.
  final String description;

  /// Ordre de progression scolaire.
  final int order;

  /// Niveaux du plus jeune au plus avancé.
  static List<EducationLevel> get ordered => List<EducationLevel>.unmodifiable(
    values.toList()..sort((a, b) => a.order.compareTo(b.order)),
  );

  /// Retrouve un niveau par son [id], ou `null` si inconnu.
  static EducationLevel? tryParse(String? id) {
    for (final EducationLevel level in values) {
      if (level.id == id) return level;
    }
    return null;
  }
}
