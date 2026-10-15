/// Grille de tuiles à hauteur libre.
library;

import 'package:flutter/widgets.dart';

import '../core/theme/app_spacing.dart';

/// Grille en colonnes où chaque tuile prend la hauteur de son contenu.
///
/// Préférée à [GridView] avec un `childAspectRatio` : un rapport fixe suppose
/// qu'on connaît d'avance la hauteur du texte, ce qui est faux dès qu'un
/// utilisateur agrandit la police ou qu'un intitulé passe sur deux lignes. Ici
/// la ligne s'aligne sur la tuile la plus haute et rien ne déborde jamais.
class TileGrid extends StatelessWidget {
  const TileGrid({
    required this.children,
    required this.columns,
    this.spacing = AppSpacing.md,
    super.key,
  });

  final List<Widget> children;

  /// Nombre de colonnes.
  final int columns;

  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int count = columns < 1 ? 1 : columns;
        final double width =
            (constraints.maxWidth - spacing * (count - 1)) / count;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final Widget child in children)
              SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
