import 'package:flutter_test/flutter_test.dart';

/// La logique et l'histoire des sciences du primaire, recalculées.
///
/// Trois sortes d'affirmations à vérifier ici. Les énigmes se **résolvent**
/// par énumération, pour établir qu'elles ont bien une solution unique. Les
/// problèmes de pesée se vérifient en construisant l'ensemble de ce qu'on
/// peut peser. Et les dates s'additionnent — ce qui a l'air trivial jusqu'à
/// ce qu'on compte un siècle ou qu'on franchisse l'an 1.
void main() {
  group('L’énigme des quatre maisons', () {
    const List<String> couleurs = ['bleue', 'jaune', 'rouge', 'verte'];

    /// Toutes les façons de placer les quatre couleurs dans les quatre
    /// maisons, construites une fois pour toutes.
    List<List<String>> arrangements() {
      final List<List<String>> tous = <List<String>>[];
      void placer(List<String> courant, List<String> restantes) {
        if (restantes.isEmpty) {
          tous.add(List<String>.from(courant));
          return;
        }
        for (int i = 0; i < restantes.length; i++) {
          final List<String> suite = List<String>.from(restantes)..removeAt(i);
          placer(<String>[...courant, restantes[i]], suite);
        }
      }

      placer(<String>[], couleurs);
      return tous;
    }

    bool verteADroite(List<String> a) => a[3] == 'verte';
    bool bleueAvantRouge(List<String> a) =>
        a.indexOf('rouge') - a.indexOf('bleue') == 1;
    bool jauneEnUn(List<String> a) => a[0] == 'jaune';

    test('il y a vingt-quatre arrangements au départ', () {
      expect(arrangements().length, 24);
      expect(arrangements().length, 4 * 3 * 2 * 1);
    });

    test('l’indice de la verte en laisse six', () {
      expect(arrangements().where(verteADroite).length, 6);
      expect(arrangements().where(verteADroite).length, 3 * 2 * 1);
    });

    test('les trois indices donnent une solution unique', () {
      final List<List<String>> solutions = arrangements()
          .where(verteADroite)
          .where(bleueAvantRouge)
          .where(jauneEnUn)
          .toList();
      expect(solutions.length, 1);
      expect(solutions.single, <String>['jaune', 'bleue', 'rouge', 'verte']);
    });

    test('retirer l’indice de la jaune laisse exactement deux solutions', () {
      final List<List<String>> solutions = arrangements()
          .where(verteADroite)
          .where(bleueAvantRouge)
          .toList();
      expect(solutions.length, 2);
      // Deux listes ne se comparent pas par ==, on les joint pour comparer.
      final Set<String> vues =
          solutions.map((List<String> s) => s.join('-')).toSet();
      expect(vues, <String>{
        'bleue-rouge-jaune-verte',
        'jaune-bleue-rouge-verte',
      });
    });

    test('chaque indice est nécessaire : aucun n’est redondant', () {
      // En retirant chaque indice tour à tour, la solution cesse d'être
      // unique. C'est la définition d'une énigme bien posée.
      final List<bool Function(List<String>)> indices =
          <bool Function(List<String>)>[
        verteADroite,
        bleueAvantRouge,
        jauneEnUn,
      ];
      for (int retire = 0; retire < indices.length; retire++) {
        Iterable<List<String>> restantes = arrangements();
        for (int i = 0; i < indices.length; i++) {
          if (i == retire) continue;
          restantes = restantes.where(indices[i]);
        }
        expect(restantes.length, greaterThan(1),
            reason: 'sans l’indice $retire, la solution n’est plus unique');
      }
    });
  });

  group('L’énigme des animaux', () {
    test('Bruno a le lapin et Alice n’a pas le chien : tout se déduit', () {
      const List<String> enfants = ['Alice', 'Bruno', 'Chloé'];
      const List<String> animaux = ['chat', 'chien', 'lapin'];
      final List<Map<String, String>> solutions = <Map<String, String>>[];
      for (int a = 0; a < 3; a++) {
        for (int b = 0; b < 3; b++) {
          for (int c = 0; c < 3; c++) {
            if (a == b || b == c || a == c) continue;
            final Map<String, String> essai = <String, String>{
              enfants[0]: animaux[a],
              enfants[1]: animaux[b],
              enfants[2]: animaux[c],
            };
            if (essai['Bruno'] != 'lapin') continue;
            if (essai['Alice'] == 'chien') continue;
            solutions.add(essai);
          }
        }
      }
      expect(solutions.length, 1);
      expect(solutions.single['Alice'], 'chat');
      expect(solutions.single['Bruno'], 'lapin');
      expect(solutions.single['Chloé'], 'chien');
    });

    test('sans l’information négative, deux solutions restent', () {
      int compte = 0;
      const List<String> animaux = ['chat', 'chien', 'lapin'];
      for (int a = 0; a < 3; a++) {
        for (int b = 0; b < 3; b++) {
          for (int c = 0; c < 3; c++) {
            if (a == b || b == c || a == c) continue;
            if (animaux[b] != 'lapin') continue;
            compte++;
          }
        }
      }
      expect(compte, 2, reason: '« Alice n’a pas le chien » tranche vraiment');
    });
  });

  group('Menteurs et sincères', () {
    /// Une personne est sincère ou menteuse. Une déclaration est acceptable
    /// si elle est vraie quand la personne est sincère, fausse sinon.
    bool coherent(bool sincere, bool contenuVrai) => sincere == contenuVrai;

    test('« je suis un menteur » est impossible dans les deux cas', () {
      for (final bool sincere in <bool>[true, false]) {
        // Le contenu de la phrase est « je mens », soit « non sincère ».
        final bool contenu = !sincere;
        expect(coherent(sincere, contenu), isFalse,
            reason: sincere ? 'un sincère' : 'un menteur');
      }
    });

    test('« nous sommes tous deux menteurs » identifie les deux', () {
      final List<(bool, bool)> possibles = <(bool, bool)>[];
      for (final bool aSincere in <bool>[true, false]) {
        for (final bool bSincere in <bool>[true, false]) {
          // Contenu : A menteur ET B menteur.
          final bool contenu = !aSincere && !bSincere;
          if (coherent(aSincere, contenu)) possibles.add((aSincere, bSincere));
        }
      }
      expect(possibles.length, 1);
      expect(possibles.single.$1, isFalse, reason: 'A mentait');
      expect(possibles.single.$2, isTrue, reason: 'B est sincère');
    });

    test('la question croisée donne la même réponse des deux côtés', () {
      // « Que répondrait l'autre village ? » Pour une vérité du monde v :
      // un sincère rapporte le mensonge, un menteur déforme la vérité.
      for (final bool v in <bool>[true, false]) {
        final bool parUnSincere = !v; // il rapporte fidèlement le mensonge
        final bool parUnMenteur = !v; // il déforme la vérité
        expect(parUnSincere, parUnMenteur, reason: 'vérité $v');
        // Et dans les deux cas, le contraire de la réponse est la vérité.
        expect(!parUnSincere, v);
      }
    });
  });

  group('Les quatre cartes de Wason', () {
    const Set<String> voyelles = {'A', 'E', 'I', 'O', 'U'};

    /// Une carte vue : soit une lettre, soit un nombre.
    /// Faut-il la retourner pour tester « voyelle implique pair » ?
    bool utilePourVoyelleImpliquePair(String? lettre, int? nombre) {
      // Une lettre visible : seule une voyelle peut déclencher la règle.
      if (lettre != null) return voyelles.contains(lettre);
      // Un nombre visible : seul un impair peut révéler une violation.
      return nombre! % 2 == 1;
    }

    /// Et pour la règle retournée, « pair implique voyelle » ?
    bool utilePourPairImpliqueVoyelle(String? lettre, int? nombre) {
      if (lettre != null) return !voyelles.contains(lettre);
      return nombre! % 2 == 0;
    }

    test('il faut retourner A et 7, pas B ni 4', () {
      expect(utilePourVoyelleImpliquePair('A', null), isTrue);
      expect(utilePourVoyelleImpliquePair(null, 7), isTrue);
      expect(utilePourVoyelleImpliquePair('B', null), isFalse);
      expect(utilePourVoyelleImpliquePair(null, 4), isFalse);
    });

    test('exactement deux cartes sur quatre', () {
      int n = 0;
      if (utilePourVoyelleImpliquePair('A', null)) n++;
      if (utilePourVoyelleImpliquePair('B', null)) n++;
      if (utilePourVoyelleImpliquePair(null, 4)) n++;
      if (utilePourVoyelleImpliquePair(null, 7)) n++;
      expect(n, 2);
    });

    test('retourner la règle retourne les cartes', () {
      expect(utilePourPairImpliqueVoyelle('B', null), isTrue);
      expect(utilePourPairImpliqueVoyelle(null, 4), isTrue);
      expect(utilePourPairImpliqueVoyelle('A', null), isFalse);
      expect(utilePourPairImpliqueVoyelle(null, 7), isFalse);
      // Les deux ensembles sont exactement complémentaires.
      for (final (String?, int?) carte in <(String?, int?)>[
        ('A', null),
        ('B', null),
        (null, 4),
        (null, 7),
      ]) {
        expect(utilePourVoyelleImpliquePair(carte.$1, carte.$2),
            !utilePourPairImpliqueVoyelle(carte.$1, carte.$2),
            reason: '$carte');
      }
    });
  });

  group('Et, ou, non', () {
    test('« et » n’est vraie que dans un cas sur quatre', () {
      int vrais = 0;
      for (final bool a in <bool>[false, true]) {
        for (final bool b in <bool>[false, true]) {
          if (a && b) vrais++;
        }
      }
      expect(vrais, 1);
    });

    test('« ou » est vraie dans trois cas sur quatre', () {
      int vrais = 0;
      for (final bool a in <bool>[false, true]) {
        for (final bool b in <bool>[false, true]) {
          if (a || b) vrais++;
        }
      }
      expect(vrais, 3);
    });

    test('le contraire de « A et B » est « non A ou non B »', () {
      // La loi de De Morgan, vérifiée sur les quatre cas : c'est ce que la
      // question sur le contraire de « grand et blond » demande.
      for (final bool a in <bool>[false, true]) {
        for (final bool b in <bool>[false, true]) {
          expect(!(a && b), !a || !b, reason: 'a=$a b=$b');
          // Et surtout, ce n'est PAS « non A et non B », le piège.
          if (a != b) {
            expect(!(a && b) == (!a && !b), isFalse,
                reason: 'le piège se voit quand a et b diffèrent');
          }
        }
      }
    });

    test('nier « tous » donne « au moins un ne… », pas « aucun »', () {
      // Trois chats gris et un roux : les deux affirmations fortes tombent.
      const List<bool> gris = [true, true, true, false];
      final bool tousGris = gris.every((bool g) => g);
      final bool aucunGris = gris.every((bool g) => !g);
      final bool auMoinsUnNonGris = gris.any((bool g) => !g);
      expect(tousGris, isFalse);
      expect(aucunGris, isFalse, reason: 'les deux sont faux en même temps');
      expect(auMoinsUnNonGris, isTrue);
      expect(auMoinsUnNonGris, !tousGris, reason: 'voilà la vraie négation');
    });

    test('un seul contre-exemple suffit, sur tous les groupes possibles', () {
      // Pour tous les groupes de quatre chats gris ou non.
      for (int masque = 0; masque < 16; masque++) {
        final List<bool> gris = List<bool>.generate(
            4, (int i) => masque & (1 << i) != 0);
        final bool tous = gris.every((bool g) => g);
        final int contreExemples = gris.where((bool g) => !g).length;
        expect(tous, contreExemples == 0, reason: 'masque $masque');
        if (!tous) expect(contreExemples, greaterThanOrEqualTo(1));
      }
    });
  });

  group('Pesées', () {
    int pesees(int pieces) {
      int n = 0;
      int pouvoir = 1;
      while (pouvoir < pieces) {
        pouvoir *= 3;
        n++;
      }
      return n;
    }

    test('le pouvoir d’une pesée est trois', () {
      expect(pesees(3), 1);
      expect(pesees(1), 0, reason: 'une seule pièce, rien à chercher');
    });

    test('neuf pièces en deux pesées, vingt-sept en trois', () {
      expect(pesees(9), 2);
      expect(pesees(27), 3);
      expect(pesees(81), 4);
    });

    test('dix pièces en demandent trois', () {
      expect(pesees(10), 3, reason: 'deux pesées ne distinguent que neuf cas');
      expect(pesees(28), 4);
    });

    test('le nombre de pesées croît par paliers aux puissances de trois', () {
      for (int pieces = 2; pieces <= 100; pieces++) {
        final int n = pesees(pieces);
        int pouvoir = 1;
        for (int i = 0; i < n; i++) {
          pouvoir *= 3;
        }
        expect(pouvoir, greaterThanOrEqualTo(pieces));
        int moins = 1;
        for (int i = 0; i < n - 1; i++) {
          moins *= 3;
        }
        expect(moins, lessThan(pieces),
            reason: '$pieces pièces : $n pesées est bien le minimum');
      }
    });
  });

  group('Les poids du marchand', () {
    /// Tout ce qu'on peut peser, selon que chaque poids va avec le sac,
    /// contre le sac, ou reste dans la poche.
    Set<int> pesables(List<int> poids, {required bool desDeuxCotes}) {
      final List<int> etats = desDeuxCotes ? <int>[-1, 0, 1] : <int>[0, 1];
      Set<int> sommes = <int>{0};
      for (final int p in poids) {
        final Set<int> suivantes = <int>{};
        for (final int s in sommes) {
          for (final int e in etats) {
            suivantes.add(s + e * p);
          }
        }
        sommes = suivantes;
      }
      return sommes.where((int v) => v > 0).toSet();
    }

    test('1, 3, 9 et 27 couvrent exactement 1 à 40', () {
      final Set<int> atteignables =
          pesables(<int>[1, 3, 9, 27], desDeuxCotes: true);
      expect(atteignables.length, 40);
      expect(atteignables, Set<int>.from(List<int>.generate(40, (int i) => i + 1)));
      expect(atteignables.reduce((a, b) => a > b ? a : b), 40);
    });

    test('la somme des poids est la plus grande masse pesable', () {
      const List<int> poids = [1, 3, 9, 27];
      expect(poids.reduce((a, b) => a + b), 40);
      expect(pesables(poids, desDeuxCotes: true).reduce((a, b) => a > b ? a : b),
          poids.reduce((a, b) => a + b));
    });

    test('d’un seul côté, les mêmes quatre poids ne font que quinze valeurs', () {
      final Set<int> unCote = pesables(<int>[1, 3, 9, 27], desDeuxCotes: false);
      expect(unCote.length, 15);
      // Et il y a des trous : on ne peut pas peser 2 kg.
      expect(unCote.contains(2), isFalse);
      expect(unCote.contains(5), isFalse);
    });

    test('1, 2, 4 et 8 couvrent 1 à 15 d’un seul côté, sans trou', () {
      final Set<int> binaire = pesables(<int>[1, 2, 4, 8], desDeuxCotes: false);
      expect(binaire.length, 15);
      expect(binaire,
          Set<int>.from(List<int>.generate(15, (int i) => i + 1)));
      expect(<int>[1, 2, 4, 8].reduce((a, b) => a + b), 15);
    });

    test('un cinquième poids de 81 porte jusqu’à 121', () {
      const List<int> poids = [1, 3, 9, 27, 81];
      expect(poids.reduce((a, b) => a + b), 121);
      final Set<int> atteignables = pesables(poids, desDeuxCotes: true);
      expect(atteignables.length, 121);
      expect(atteignables,
          Set<int>.from(List<int>.generate(121, (int i) => i + 1)));
    });

    test('quatre poids à trois états font quatre-vingt-une combinaisons', () {
      int combinaisons = 1;
      for (int i = 0; i < 4; i++) {
        combinaisons *= 3;
      }
      expect(combinaisons, 81);
      // Une ne pèse rien, les autres se partagent en positives et opposées.
      expect((combinaisons - 1) ~/ 2, 40);
    });
  });

  group('Partages', () {
    test('vingt-quatre billes entre trois', () {
      expect(24 ~/ 3, 8);
      expect(24 % 3, 0);
    });

    test('vingt-cinq billes laissent un reste', () {
      expect(25 ~/ 3, 8);
      expect(25 % 3, 1);
      expect(3 * (25 ~/ 3) + (25 % 3), 25, reason: 'la division euclidienne');
    });

    test('celui qui choisit reçoit au moins la moitié', () {
      // Pour toute découpe en deux parts d'un gâteau valant 100.
      for (int part = 0; part <= 100; part++) {
        final int autre = 100 - part;
        final int meilleure = part > autre ? part : autre;
        expect(meilleure, greaterThanOrEqualTo(50), reason: 'découpe $part/$autre');
      }
    });

    test('celui qui coupe maximise en coupant égal', () {
      // Il reçoit la part dont l'autre ne veut pas : la plus petite.
      int cePuilRecoit(int part) {
        final int autre = 100 - part;
        return part < autre ? part : autre;
      }

      int meilleur = -1;
      int meilleureCoupe = -1;
      for (int part = 0; part <= 100; part++) {
        if (cePuilRecoit(part) > meilleur) {
          meilleur = cePuilRecoit(part);
          meilleureCoupe = part;
        }
      }
      expect(meilleureCoupe, 50);
      expect(meilleur, 50);
    });
  });

  group('Chiffres romains', () {
    const Map<String, int> valeurs = {
      'I': 1,
      'V': 5,
      'X': 10,
      'L': 50,
      'C': 100,
      'D': 500,
      'M': 1000,
    };

    int lire(String romain) {
      int total = 0;
      for (int i = 0; i < romain.length; i++) {
        final int v = valeurs[romain[i]]!;
        final bool soustrait =
            i + 1 < romain.length && valeurs[romain[i + 1]]! > v;
        total += soustrait ? -v : v;
      }
      return total;
    }

    test('les nombres cités dans le chapitre', () {
      expect(lire('XVI'), 16);
      expect(lire('XL'), 40);
      expect(lire('MCMXLIV'), 1944);
      expect(lire('MMXXVI'), 2026);
      expect(lire('MDCCCXLVII'), 1847);
      expect(lire('MMCDLIX'), 2459);
    });

    test('l’addition du défi', () {
      expect(lire('MDCCCXLVII') + lire('MMCDLIX'), 4306);
      expect(1847 + 2459, 4306);
    });

    test('dix lettres contre quatre chiffres', () {
      expect('MDCCCXLVII'.length, 10);
      expect('1847'.length, 4);
      expect('MDCCCXLVII'.length / '1847'.length, 2.5);
    });

    test('aucune lettre ne vaut zéro', () {
      expect(valeurs.values.where((int v) => v == 0), isEmpty);
      expect(valeurs.length, 7);
    });

    test('la position ne change rien dans MM, et tout dans 22', () {
      // Les deux M valent pareil.
      expect(lire('MM'), 2 * valeurs['M']!);
      // Les deux 2 ne valent pas pareil.
      const int nombre = 22;
      expect(nombre ~/ 10 * 10, 20);
      expect(nombre % 10, 2);
      expect(20, isNot(2));
    });

    test('retirer le zéro de 305 divise par presque dix', () {
      expect(305 - 300 + 30, 35);
      expect(305 / 35, closeTo(8.71, 0.01));
    });
  });

  group('Bases de numération', () {
    int nombreDeDiviseurs(int n) {
      int d = 0;
      for (int i = 1; i <= n; i++) {
        if (n % i == 0) d++;
      }
      return d;
    }

    test('douze a plus de diviseurs que dix', () {
      expect(nombreDeDiviseurs(12), 6, reason: '1, 2, 3, 4, 6, 12');
      expect(nombreDeDiviseurs(10), 4, reason: '1, 2, 5, 10');
      // En excluant 1 et le nombre lui-même : quatre contre deux, ce que
      // la question du chapitre demande.
      expect(nombreDeDiviseurs(12) - 2, 4);
      expect(nombreDeDiviseurs(10) - 2, 2);
    });

    test('soixante est encore plus divisible', () {
      expect(nombreDeDiviseurs(60), 12);
      expect(nombreDeDiviseurs(60), greaterThan(nombreDeDiviseurs(12)));
      // Ce qui explique les minutes et les degrés.
      for (final int d in <int>[2, 3, 4, 5, 6, 10, 12, 15, 20, 30]) {
        expect(60 % d, 0, reason: '60 se divise par $d');
      }
    });

    test('quatre-vingts est bien quatre fois vingt', () {
      expect(4 * 20, 80);
    });
  });

  group('Dates et siècles', () {
    int siecle(int annee) => annee % 100 == 0 ? annee ~/ 100 : annee ~/ 100 + 1;

    test('les siècles du chapitre', () {
      expect(siecle(1450), 15);
      expect(siecle(1903), 20);
      expect(siecle(1900), 19, reason: 'une année en 00 clôt son siècle');
      expect(siecle(2026), 21);
    });

    test('le premier siècle va de 1 à 100', () {
      expect(siecle(1), 1);
      expect(siecle(100), 1);
      expect(siecle(101), 2);
    });

    test('chaque siècle compte exactement cent années', () {
      for (int s = 1; s <= 21; s++) {
        int compte = 0;
        for (int a = (s - 1) * 100 + 1; a <= s * 100; a++) {
          if (siecle(a) == s) compte++;
        }
        expect(compte, 100, reason: 'siècle $s');
      }
    });

    test('les durées entre inventions', () {
      expect(2026 - 1450, 576);
      expect(1969 - 1903, 66);
      expect(1928 - 1796, 132);
      expect(5500 - 5300, 200);
      expect(10000 ~/ 200, 50);
    });

    test('une durée qui franchit l’an 1 s’additionne', () {
      // De 500 avant notre ère à 200 après : il n'y a pas d'année 0 dans
      // l'usage courant, mais l'addition reste la bonne opération ici.
      expect(500 + 200, 700);
      // Et une durée qui ne franchit rien se soustrait normalement.
      expect(500 - 200, 300);
    });

    test('la vie de 1890 à 1980', () {
      expect(1980 - 1890, 90);
      expect(1903 - 1890, 13);
      expect(1969 - 1890, 79);
      expect(1928 - 1890, 38);
      expect((1969 - 1890) - (1903 - 1890), 1969 - 1903);
      expect((1969 - 1890) - (1903 - 1890), 66);
    });

    test('les dates des savants', () {
      expect(1911 - 1903, 8, reason: 'les deux Nobel de Marie Curie');
      expect(1934 - 1867, 67);
      expect(1903 - 1867, 36);
      expect(1943 - 1843, 100, reason: 'Lovelace avant tout ordinateur');
      expect(1962 - 1952, 10, reason: 'la photo 51 et le Nobel');
      expect(1000 - 820, 180);
      expect(1952 - 1843, 109);
      expect(1935 - 1903, 32, reason: 'Marie puis Irène');
    });

    test('la différence des années n’est pas toujours l’âge', () {
      // Katherine Johnson, née en août 1918, morte en février 2020.
      const int differenceDesAnnees = 2020 - 1918;
      expect(differenceDesAnnees, 102);
      // L'anniversaire de 2020 n'avait pas eu lieu : un an de moins.
      const int moisNaissance = 8;
      const int moisDeces = 2;
      const int age =
          differenceDesAnnees - (moisDeces < moisNaissance ? 1 : 0);
      expect(age, 101);
      expect(age, lessThan(differenceDesAnnees));
    });

    test('l’âge vaut la différence quand l’anniversaire est passé', () {
      const int differenceDesAnnees = 2020 - 1918;
      const int moisNaissance = 1;
      const int moisDeces = 12;
      const int age =
          differenceDesAnnees - (moisDeces < moisNaissance ? 1 : 0);
      expect(age, differenceDesAnnees);
      expect(age, 102);
    });
  });

  group('La cuisson et le temps gagné', () {
    test('sept heures libérées par jour, au moins', () {
      expect(8 - 1, 7);
      // Sur une année, cela fait de quoi faire autre chose.
      expect(7 * 365, 2555);
    });
  });
}
