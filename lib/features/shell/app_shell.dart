/// Coquille de navigation principale.
library;

import 'package:flutter/material.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/app_tokens.dart';

/// Un onglet de la navigation principale.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Navigation à trois onglets, barre basse ou rail selon la largeur.
///
/// Même arborescence sur téléphone et sur tablette : seul le *placement* du
/// sélecteur change. Un élève qui passe de son téléphone à la tablette
/// familiale retrouve exactement la même application.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.child,
    required this.currentIndex,
    required this.onSelect,
    super.key,
  });

  static const List<ShellDestination> destinations = <ShellDestination>[
    ShellDestination(
      label: 'Accueil',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    ShellDestination(
      label: 'Matières',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
    ),
    ShellDestination(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bool wide = context.isWideScreen;

    void select(int index) {
      context.tapFeedback();
      onSelect(index);
    }

    if (!wide) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: select,
          destinations: <Widget>[
            for (final ShellDestination d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: select,
            // Sur tablette, l'espace permet d'afficher les intitulés en
            // permanence : moins d'icônes à deviner.
            labelType: NavigationRailLabelType.all,
            destinations: <NavigationRailDestination>[
              for (final ShellDestination d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          VerticalDivider(width: 1, color: context.tokens.border),
          Expanded(child: child),
        ],
      ),
    );
  }
}
