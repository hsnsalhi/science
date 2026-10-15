/// Correspondance entre les clés du contenu et les éléments visuels.
library;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../domain/models/education_level.dart';
import '../domain/models/lesson.dart';

/// Icônes des matières.
///
/// Le contenu JSON ne nomme jamais une icône Flutter : il nomme une *clé*
/// stable (`icon: "functions"`), traduite ici. Le contenu reste ainsi
/// indépendant de la bibliothèque d'icônes.
abstract final class SubjectVisuals {
  static const Map<String, IconData> _icons = <String, IconData>{
    'functions': Icons.functions_rounded,
    'calculate': Icons.calculate_rounded,
    'science': Icons.science_rounded,
    'bolt': Icons.bolt_rounded,
    'code': Icons.code_rounded,
    'terminal': Icons.terminal_rounded,
    'memory': Icons.memory_rounded,
    'eco': Icons.eco_rounded,
    'biotech': Icons.biotech_rounded,
    'public': Icons.public_rounded,
    'psychology': Icons.psychology_rounded,
    'build': Icons.build_rounded,
    'rocket': Icons.rocket_launch_rounded,
    'extension': Icons.extension_rounded,
    'history': Icons.history_edu_rounded,
  };

  /// Icône d'une clé de contenu, avec un repli neutre.
  static IconData icon(String key) => _icons[key] ?? Icons.auto_awesome_rounded;

  /// Palette d'une matière.
  static SubjectPalette palette(String subjectId) =>
      SubjectPalettes.of(subjectId);
}

/// Couleurs et icônes des niveaux scolaires.
abstract final class LevelVisuals {
  static Color color(EducationLevel level) => switch (level) {
    EducationLevel.primaire => LevelColors.primaire,
    EducationLevel.college => LevelColors.college,
    EducationLevel.lycee => LevelColors.lycee,
    EducationLevel.universite => LevelColors.universite,
  };

  static IconData icon(EducationLevel level) => switch (level) {
    EducationLevel.primaire => Icons.emoji_nature_rounded,
    EducationLevel.college => Icons.explore_rounded,
    EducationLevel.lycee => Icons.science_rounded,
    EducationLevel.universite => Icons.school_rounded,
  };
}

/// Icônes des types de leçon.
abstract final class LessonVisuals {
  static IconData icon(LessonKind kind) => switch (kind) {
    LessonKind.cours => Icons.menu_book_rounded,
    LessonKind.entrainement => Icons.fitness_center_rounded,
    LessonKind.defi => Icons.emoji_events_rounded,
  };
}

/// Icônes des types de carte d'apprentissage.
abstract final class CardVisuals {
  static IconData? icon(LessonCardKind kind) => switch (kind) {
    LessonCardKind.texte => null,
    LessonCardKind.formule => Icons.functions_rounded,
    LessonCardKind.exemple => Icons.lightbulb_outline_rounded,
    LessonCardKind.astuce => Icons.tips_and_updates_rounded,
    LessonCardKind.figure => Icons.touch_app_rounded,
    LessonCardKind.etape => Icons.flag_rounded,
    LessonCardKind.aRetenir => Icons.bookmark_rounded,
  };

  /// Intitulé affiché en tête d'une carte typée.
  static String? label(LessonCardKind kind) => switch (kind) {
    LessonCardKind.texte => null,
    LessonCardKind.formule => 'Formule',
    LessonCardKind.exemple => 'Exemple',
    LessonCardKind.astuce => 'Astuce',
    LessonCardKind.figure => 'À manipuler',
    LessonCardKind.etape => 'Étape',
    LessonCardKind.aRetenir => 'À retenir',
  };
}
