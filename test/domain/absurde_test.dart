import 'package:flutter_test/flutter_test.dart';

/// Le chapitre sur l'absurde raconte des preuves ; on les exécute.
///
/// Une preuve recopiée de mémoire se dégrade sans bruit : un facteur
/// oublié, une borne décalée d'un rang, et le texte reste plausible. Ces
/// tests refont les constructions au lieu de les relire. La construction
/// d'Euclide est jouée sur les trente premiers préfixes de la liste des
/// nombres premiers, et les bornes du principe des tiroirs sont établies
/// dans les deux sens : qu'une répétition est forcée, et qu'avec un objet
/// de moins elle ne l'est pas.
void main() {
  group('L\'infinité des nombres premiers', () {
    test('la construction d\'Euclide livre toujours un premier nouveau', () {
      // Le cœur de la preuve : le produit des premiers d'une liste, plus 1,
      // n'est divisible par aucun d'eux, donc ses facteurs premiers sont
      // tous hors de la liste. On le vérifie sur trente préfixes.
      final List<int> liste = <int>[];
      BigInt produit = BigInt.one;
      for (int n = 2; liste.length < 30; n++) {
        if (!estPremier(n)) continue;
        liste.add(n);
        produit *= BigInt.from(n);
        final BigInt candidat = produit + BigInt.one;

        for (final int p in liste) {
          expect(
            candidat % BigInt.from(p),
            BigInt.one,
            reason: 'le reste doit valoir 1 pour chaque premier de la liste',
          );
        }
        // Et le candidat a bien un facteur premier, nécessairement neuf.
        final int plusPetit = plusPetitFacteurPremier(candidat);
        expect(plusPetit, greaterThan(1));
        expect(
          liste.contains(plusPetit),
          isFalse,
          reason: 'le facteur trouvé serait dans une liste dite complète',
        );
      }
    });

    test('les trois exemples cités dans le cours', () {
      // 2 × 3 × 5 + 1 = 31, premier.
      expect(2 * 3 * 5 + 1, 31);
      expect(estPremier(31), isTrue);
      // 2 × 3 × 5 × 7 + 1 = 211, premier.
      expect(2 * 3 * 5 * 7 + 1, 211);
      expect(estPremier(211), isTrue);
      // 2 × 3 × 5 × 7 × 11 × 13 + 1 = 30 031, qui n'est PAS premier.
      // Le cours insiste là-dessus : la construction ne produit pas un
      // nombre premier, elle produit un nombre dont les facteurs sont
      // nouveaux. 30 031 = 59 × 509, et 59 n'était pas dans la liste.
      const int produit = 2 * 3 * 5 * 7 * 11 * 13;
      expect(produit, 30030);
      expect(produit + 1, 30031);
      expect(estPremier(30031), isFalse);
      expect(59 * 509, 30031);
      expect(estPremier(59), isTrue);
      expect(estPremier(509), isTrue);
      expect(<int>[2, 3, 5, 7, 11, 13].contains(59), isFalse);
    });
  });

  group('Racine de 2', () {
    test('un carré pair ne vient que d\'un nombre pair', () {
      // Le lemme de la carte « à retenir ». Sans lui la preuve s'arrête.
      for (int a = 0; a <= 3000; a++) {
        expect((a * a).isEven, a.isEven, reason: 'a = $a');
      }
    });

    test('aucune fraction de dénominateur raisonnable ne vaut √2', () {
      // La preuve dit qu'il n'en existe aucune. On ne peut pas tester
      // l'infini, mais on peut vérifier qu'aucun couple (a, b) jusqu'à
      // 2 000 ne satisfait a² = 2b² — l'égalité exacte que la preuve
      // déclare impossible, et qui ne dépend d'aucun arrondi.
      int trouves = 0;
      for (int b = 1; b <= 2000; b++) {
        final int cible = 2 * b * b;
        final int a = sqrtEntier(cible);
        if (a * a == cible) trouves++;
      }
      expect(trouves, 0);
    });

    test('et la contradiction se manifeste bien sur les meilleurs essais', () {
      // Les approximations successives de √2 par des fractions réduites :
      // 1/1, 3/2, 7/5, 17/12, 41/29 … Chacune approche, aucune n'atteint,
      // et a² − 2b² ne vaut jamais 0 — il oscille entre +1 et −1.
      int a = 1;
      int b = 1;
      for (int i = 0; i < 20; i++) {
        final int ecart = a * a - 2 * b * b;
        expect(ecart.abs(), 1, reason: 'a=$a b=$b');
        expect(ecart, isNot(0));
        final int na = a + 2 * b;
        final int nb = a + b;
        a = na;
        b = nb;
      }
    });
  });

  group('Le principe des tiroirs', () {
    /// Nombre d'objets garanti dans le tiroir le plus rempli.
    ///
    /// C'est la division entière arrondie vers le haut, mais on la calcule
    /// par la répartition réelle plutôt que par la formule : si les deux
    /// divergeaient, c'est la formule qui aurait tort.
    int garantiParRepartition(int objets, int tiroirs) {
      final List<int> tiroirsRemplis = List<int>.filled(tiroirs, 0);
      for (int i = 0; i < objets; i++) {
        tiroirsRemplis[i % tiroirs]++;
      }
      return tiroirsRemplis.reduce((int a, int b) => a > b ? a : b);
    }

    test('la répartition la plus plate donne bien la formule', () {
      for (int tiroirs = 1; tiroirs <= 40; tiroirs++) {
        for (int objets = 0; objets <= 200; objets++) {
          expect(
            garantiParRepartition(objets, tiroirs),
            (objets + tiroirs - 1) ~/ tiroirs,
            reason: '$objets objets, $tiroirs tiroirs',
          );
        }
      }
    });

    test('les chaussettes : 3 couleurs donnent 4, 5 couleurs donnent 6', () {
      // Les questions du cours et du défi. On vérifie les deux sens : à
      // n + 1 tirages la répétition est forcée, à n elle ne l'est pas.
      for (final int couleurs in <int>[3, 5]) {
        expect(garantiParRepartition(couleurs + 1, couleurs), 2);
        expect(garantiParRepartition(couleurs, couleurs), 1);
      }
    });

    test('les mois : 13 personnes forcent une répétition, 12 non', () {
      expect(garantiParRepartition(13, 12), 2);
      expect(garantiParRepartition(12, 12), 1);
    });

    test('30 élèves sur 12 mois : trois, et pas quatre', () {
      // La question délicate de l'entraînement. Trois est garanti ; quatre
      // ne l'est pas, puisqu'une répartition existe où aucun mois n'en a
      // quatre. On exhibe cette répartition plutôt que de l'affirmer.
      expect(garantiParRepartition(30, 12), 3);
      final List<int> plate = <int>[3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2];
      expect(plate.reduce((int a, int b) => a + b), 30);
      expect(plate.reduce((int a, int b) => a > b ? a : b), 3);
      expect(2 * 12, lessThan(30), reason: 'deux par mois ne logent que 24');
    });

    test('400 personnes et 366 jours', () {
      expect(garantiParRepartition(400, 366), 2);
      expect(garantiParRepartition(366, 366), 1);
    });

    test('six nombres parmi dix forcent une paire de somme 11', () {
      // Les cinq paires de somme 11 forment les tiroirs. Six nombres dans
      // cinq tiroirs : un tiroir en reçoit deux, c'est-à-dire une paire
      // complète. On le vérifie par énumération exhaustive des 210 choix.
      final List<Set<int>> tiroirs = <Set<int>>[
        for (int i = 1; i <= 5; i++) <int>{i, 11 - i},
      ];
      expect(tiroirs.length, 5);
      for (final Set<int> t in tiroirs) {
        expect(t.reduce((int a, int b) => a + b), 11);
      }

      int sansPaire = 0;
      int total = 0;
      for (final List<int> choix in combinaisons(
        List<int>.generate(10, (int i) => i + 1),
        6,
      )) {
        total++;
        final bool aUnePaire = tiroirs.any(
          (Set<int> t) => t.every(choix.contains),
        );
        if (!aUnePaire) sansPaire++;
      }
      expect(total, 210);
      expect(sansPaire, 0, reason: 'aucun choix de six n\'évite les paires');

      // Avec cinq nombres, on peut l'éviter : un par tiroir.
      final List<int> cinq = <int>[1, 2, 3, 4, 5];
      expect(
        tiroirs.any((Set<int> t) => t.every(cinq.contains)),
        isFalse,
      );
    });
  });

  group('L\'île des chevaliers et des fripons', () {
    // Un habitant est chevalier (dit toujours vrai) ou fripon (dit toujours
    // faux). On énumère les attributions possibles et on garde celles où
    // chaque déclaration est cohérente avec le statut de qui la prononce.
    // Rien n'est supposé des réponses : elles tombent de l'énumération.

    /// Les attributions cohérentes, pour une déclaration de A portant sur
    /// les statuts de A et B. `true` = chevalier.
    List<(bool, bool)> coherentes(bool Function(bool a, bool b) enonce) {
      final List<(bool, bool)> gardees = <(bool, bool)>[];
      for (final bool a in <bool>[true, false]) {
        for (final bool b in <bool>[true, false]) {
          // Un chevalier énonce du vrai, un fripon du faux.
          if (enonce(a, b) == a) gardees.add((a, b));
        }
      }
      return gardees;
    }

    test('« je suis un fripon » n\'a aucune solution', () {
      final List<(bool, bool)> s = coherentes((bool a, bool _) => !a);
      expect(s, isEmpty, reason: 'les deux hypothèses se contredisent');
    });

    test('« je suis un chevalier » n\'apprend rien', () {
      final List<(bool, bool)> s = coherentes((bool a, bool _) => a);
      // Les deux statuts de A restent possibles : la phrase est vide
      // d'information, ce qui n'est pas la même chose qu'impossible.
      expect(s.map(((bool, bool) e) => e.$1).toSet(), <bool>{true, false});
    });

    test('« nous sommes tous les deux des fripons » : A fripon, B chevalier',
        () {
      final List<(bool, bool)> s = coherentes(
        (bool a, bool b) => !a && !b,
      );
      expect(s.length, 1);
      expect(s.single.$1, isFalse, reason: 'A est fripon');
      expect(s.single.$2, isTrue, reason: 'B est chevalier');
    });
  });

  group('Les contre-exemples du cours', () {
    test('91 n\'est pas premier, et se règle sans l\'absurde', () {
      expect(7 * 13, 91);
      expect(estPremier(91), isFalse);
    });

    test('il n\'existe pas d\'entier strictement entre 3 et 4', () {
      for (int n = -100; n <= 100; n++) {
        expect(n > 3 && n < 4, isFalse);
      }
    });

    test('7 n\'est pas pair', () => expect(7.isEven, isFalse));
  });
}

/// Primalité par essais de division, suffisante à ces tailles.
bool estPremier(int n) {
  if (n < 2) return false;
  if (n.isEven) return n == 2;
  for (int d = 3; d * d <= n; d += 2) {
    if (n % d == 0) return false;
  }
  return true;
}

/// Plus petit facteur premier d'un entier, ou 1 pour 1.
///
/// Les candidats d'Euclide grandissent vite ; d'où le [BigInt] et la
/// recherche bornée, qui suffit parce qu'on ne demande que le plus petit.
int plusPetitFacteurPremier(BigInt n) {
  if (n <= BigInt.one) return 1;
  for (int d = 2; d < 200000; d++) {
    if (n % BigInt.from(d) == BigInt.zero) return d;
  }
  // Pas de facteur sous la borne : n est premier, ou son plus petit
  // facteur la dépasse. Dans les deux cas il est hors de toute liste de
  // premiers que ce test construit, ce qui est ce qu'on affirme.
  return 200001;
}

/// Racine carrée entière, par recherche dichotomique.
int sqrtEntier(int n) {
  int bas = 0;
  int haut = n;
  while (bas < haut) {
    final int milieu = bas + (haut - bas + 1) ~/ 2;
    if (milieu * milieu <= n) {
      bas = milieu;
    } else {
      haut = milieu - 1;
    }
  }
  return bas;
}

/// Toutes les combinaisons de [k] éléments de [source].
Iterable<List<int>> combinaisons(List<int> source, int k) sync* {
  if (k == 0) {
    yield <int>[];
    return;
  }
  for (int i = 0; i <= source.length - k; i++) {
    for (final List<int> reste in combinaisons(source.sublist(i + 1), k - 1)) {
      yield <int>[source[i], ...reste];
    }
  }
}
