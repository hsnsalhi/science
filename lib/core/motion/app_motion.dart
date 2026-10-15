/// Préférences d'animation et de retour haptique, diffusées dans l'arbre.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Préférences de confort, posées une fois à la racine de l'application.
///
/// Les widgets du design system ne connaissent ni Riverpod ni l'écran de
/// réglages : ils lisent simplement `context.motion`. Cela garde le design
/// system réutilisable et testable en isolation.
///
/// `reduceMotion` est vrai si **l'utilisateur l'a demandé dans l'application**
/// ou si le **système** l'a demandé (iOS « Réduire les animations », Android
/// « Supprimer les animations ») : on respecte le réglage système sans que
/// l'utilisateur ait à le répéter ici.
@immutable
class AppMotion extends InheritedWidget {
  const AppMotion({
    required this.reduceMotionPreference,
    required this.hapticsEnabled,
    required super.child,
    super.key,
  });

  /// Réglage choisi dans l'écran de réglages de l'application.
  final bool reduceMotionPreference;

  /// Retour haptique autorisé.
  final bool hapticsEnabled;

  static AppMotion? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppMotion>();

  @override
  bool updateShouldNotify(AppMotion oldWidget) =>
      oldWidget.reduceMotionPreference != reduceMotionPreference ||
      oldWidget.hapticsEnabled != hapticsEnabled;
}

/// Accès aux préférences de confort et aux retours haptiques.
extension MotionContext on BuildContext {
  /// `true` si les animations non essentielles doivent être supprimées.
  bool get reduceMotion {
    final AppMotion? config = AppMotion.maybeOf(this);
    final bool system = MediaQuery.maybeDisableAnimationsOf(this) ?? false;
    return system || (config?.reduceMotionPreference ?? false);
  }

  /// Durée à utiliser pour une animation : nulle si le confort l'exige.
  Duration motionDuration(Duration duration) =>
      reduceMotion ? Duration.zero : duration;

  /// Vibration légère : sélection d'une réponse, appui sur un bouton.
  void tapFeedback() {
    if (AppMotion.maybeOf(this)?.hapticsEnabled ?? true) {
      HapticFeedback.selectionClick();
    }
  }

  /// Vibration de réussite : bonne réponse, leçon terminée.
  void successFeedback() {
    if (AppMotion.maybeOf(this)?.hapticsEnabled ?? true) {
      HapticFeedback.lightImpact();
    }
  }

  /// Vibration d'erreur : mauvaise réponse. Volontairement discrète — se
  /// tromper fait partie de l'apprentissage, ce n'est pas une alarme.
  void errorFeedback() {
    if (AppMotion.maybeOf(this)?.hapticsEnabled ?? true) {
      HapticFeedback.mediumImpact();
    }
  }
}
