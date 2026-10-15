/// Points de rupture et aides de mise en page adaptative.
library;

import 'package:flutter/widgets.dart';

import '../theme/app_spacing.dart';

/// Classe de largeur de la fenêtre.
///
/// L'application ne se demande jamais « est-ce un iPad ? » mais « de combien
/// de largeur je dispose ? ». Un téléphone en paysage et une petite tablette
/// reçoivent ainsi la même mise en page, ce qui est le comportement attendu.
enum WidthClass {
  /// < 600 dp — téléphone en portrait.
  compact,

  /// 600–1023 dp — téléphone en paysage, petite tablette.
  medium,

  /// ≥ 1024 dp — tablette, grand écran.
  expanded;

  /// `true` dès qu'on dispose de la place d'une tablette.
  bool get isWide => this != WidthClass.compact;

  /// `true` pour la mise en page à deux panneaux.
  bool get isExpanded => this == WidthClass.expanded;
}

/// Seuils, exprimés en pixels logiques.
abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 1024;

  /// Classe de largeur correspondant à [width].
  static WidthClass classify(double width) {
    if (width >= expanded) return WidthClass.expanded;
    if (width >= medium) return WidthClass.medium;
    return WidthClass.compact;
  }
}

/// Lecture de la mise en page depuis l'arbre de widgets.
extension LayoutContext on BuildContext {
  /// Classe de largeur courante.
  WidthClass get widthClass =>
      Breakpoints.classify(MediaQuery.sizeOf(this).width);

  /// `true` si l'écran est au moins aussi large qu'une petite tablette.
  bool get isWideScreen => widthClass.isWide;

  /// Marge horizontale d'écran adaptée à la largeur courante.
  double get screenInset => switch (widthClass) {
    WidthClass.compact => AppSpacing.screenCompact,
    WidthClass.medium => AppSpacing.screenMedium,
    WidthClass.expanded => AppSpacing.screenExpanded,
  };

  /// Nombre de colonnes d'une grille de cartes.
  int get gridColumns => switch (widthClass) {
    WidthClass.compact => 2,
    WidthClass.medium => 3,
    WidthClass.expanded => 4,
  };
}
