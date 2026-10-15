/// Barème d'expérience.
library;

import '../models/rank.dart';

/// Règles d'attribution des XP.
///
/// Le barème est délibérément peu punitif. Une mauvaise réponse ne retire
/// jamais d'XP et ne ferme jamais l'accès au contenu : se tromper puis
/// comprendre rapporte moins que réussir du premier coup, mais rapporte
/// quand même. C'est ce qui distingue un outil d'apprentissage d'un jeu de
/// score.
abstract final class XpEngine {
  /// Bonne réponse du premier coup.
  static const int xpFirstTry = 10;

  /// Bonne réponse après une ou plusieurs erreurs.
  static const int xpAfterRetry = 4;

  /// Bonus pour une leçon terminée sans aucune faute.
  static const int perfectBonus = 15;

  /// XP d'une question selon le nombre d'essais utilisés.
  static int xpForAnswer({required bool firstTry}) =>
      firstTry ? xpFirstTry : xpAfterRetry;

  /// Avancement vers le rang suivant, de 0 à 1.
  ///
  /// Renvoie 1 quand le dernier rang est atteint.
  static double rankProgress(int totalXp) {
    final Rank current = Rank.forXp(totalXp);
    final Rank? next = current.next;
    if (next == null) return 1;
    final int span = next.requiredXp - current.requiredXp;
    if (span <= 0) return 1;
    final double ratio = (totalXp - current.requiredXp) / span;
    return ratio.clamp(0.0, 1.0);
  }

  /// XP restants pour atteindre le rang suivant, ou `null` si c'est le dernier.
  static int? xpToNextRank(int totalXp) {
    final Rank? next = Rank.forXp(totalXp).next;
    if (next == null) return null;
    return (next.requiredXp - totalXp).clamp(0, next.requiredXp);
  }
}
