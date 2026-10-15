/// Rangs d'expérience.
library;

/// Rang de l'élève, dérivé de son total d'XP.
///
/// Les rangs remplacent les « niveaux 1, 2, 3 » habituels : un nom valorisant
/// marque mieux la progression qu'un numéro, et évite la comparaison directe
/// entre un élève de primaire et un étudiant.
enum Rank {
  curieux('Curieux', 0),
  explorateur('Explorateur', 150),
  apprenti('Apprenti', 500),
  chercheur('Chercheur', 1200),
  savant('Savant', 2500),
  genie('Génie', 5000);

  const Rank(this.label, this.requiredXp);

  /// Nom affiché.
  final String label;

  /// Total d'XP à partir duquel le rang est atteint.
  final int requiredXp;

  /// Rang suivant, ou `null` si c'est le dernier.
  Rank? get next {
    final int i = index + 1;
    return i < values.length ? values[i] : null;
  }

  /// Rang correspondant à [totalXp].
  static Rank forXp(int totalXp) {
    Rank current = Rank.curieux;
    for (final Rank rank in values) {
      if (totalXp >= rank.requiredXp) current = rank;
    }
    return current;
  }
}
