import 'package:flutter_test/flutter_test.dart';

/// Les onze patrons du cube, énumérés.
///
/// Le chapitre « Figures planes et solides » affirme qu'il existe
/// exactement onze patrons du cube. C'est le genre d'affirmation qu'on
/// recopie, et il se trouve qu'elle se démontre : on énumère les
/// trente-cinq hexaminos, puis on plie chacun pour de bon.
///
/// Le pliage se simule en faisant **rouler un dé** sur le patron. On part
/// d'une case, on roule de case en case, et on note à chaque fois quelle
/// face du dé se trouve dessous. Le patron est valable si, et seulement si,
/// les six cases reçoivent six faces distinctes : si deux cases reçoivent
/// la même face, c'est exactement le pliage où deux carrés se superposent,
/// celui que la carte « le test du pliage mental » décrit.

/// L'orientation d'un dé posé sur une case : quelle face regarde où.
class De {
  const De(this.dessous, this.dessus, this.nord, this.sud, this.est, this.ouest);

  final int dessous;
  final int dessus;
  final int nord;
  final int sud;
  final int est;
  final int ouest;

  /// Le dé de départ, faces numérotées de 1 à 6.
  static const De initial = De(1, 6, 2, 5, 3, 4);

  /// Basculer vers l'est : la face est descend, le dessous part à l'ouest.
  De versEst() => De(est, ouest, nord, sud, dessus, dessous);

  /// Basculer vers l'ouest, l'opération inverse.
  De versOuest() => De(ouest, est, nord, sud, dessous, dessus);

  /// Basculer vers le nord : la face nord descend.
  De versNord() => De(nord, sud, dessus, dessous, est, ouest);

  De versSud() => De(sud, nord, dessous, dessus, est, ouest);

  /// La face qui se retrouve dessous après un pas dans une direction.
  De apres(int dx, int dy) {
    if (dx == 1) return versEst();
    if (dx == -1) return versOuest();
    if (dy == -1) return versNord();
    if (dy == 1) return versSud();
    throw ArgumentError('pas de ($dx, $dy)');
  }
}

/// Un polyomino : un ensemble de cases, normalisé pour pouvoir être comparé.
typedef Cases = Set<(int, int)>;

Cases _translate(Cases cases) {
  final int minX = cases.map(((int, int) c) => c.$1).reduce((a, b) => a < b ? a : b);
  final int minY = cases.map(((int, int) c) => c.$2).reduce((a, b) => a < b ? a : b);
  return cases.map(((int, int) c) => (c.$1 - minX, c.$2 - minY)).toSet();
}

/// Les huit images d'un polyomino par les rotations et les retournements.
List<Cases> _symetries(Cases cases) {
  final List<Cases> images = <Cases>[];
  for (int miroir = 0; miroir < 2; miroir++) {
    Cases c = miroir == 0
        ? cases
        : cases.map(((int, int) p) => (-p.$1, p.$2)).toSet();
    for (int rotation = 0; rotation < 4; rotation++) {
      images.add(_translate(c));
      c = c.map(((int, int) p) => (-p.$2, p.$1)).toSet();
    }
  }
  return images;
}

/// La représentation canonique : la plus petite des huit images, pour un
/// ordre arbitraire mais fixe. Deux polyominos identiques à rotation ou
/// retournement près ont la même clé.
String _canonique(Cases cases) {
  final List<String> cles = _symetries(cases).map((Cases image) {
    final List<(int, int)> triees = image.toList()
      ..sort(((int, int) a, (int, int) b) =>
          a.$2 != b.$2 ? a.$2.compareTo(b.$2) : a.$1.compareTo(b.$1));
    return triees.map(((int, int) c) => '${c.$1},${c.$2}').join(';');
  }).toList()
    ..sort();
  return cles.first;
}

/// Tous les polyominos libres de n cases.
List<Cases> polyominos(int n) {
  Map<String, Cases> courants = <String, Cases>{
    _canonique(<(int, int)>{(0, 0)}): <(int, int)>{(0, 0)},
  };
  for (int taille = 1; taille < n; taille++) {
    final Map<String, Cases> suivants = <String, Cases>{};
    for (final Cases forme in courants.values) {
      for (final (int, int) c in forme) {
        for (final (int, int) pas in const <(int, int)>[
          (1, 0),
          (-1, 0),
          (0, 1),
          (0, -1),
        ]) {
          final (int, int) voisine = (c.$1 + pas.$1, c.$2 + pas.$2);
          if (forme.contains(voisine)) continue;
          final Cases agrandie = <(int, int)>{...forme, voisine};
          suivants[_canonique(agrandie)] = _translate(agrandie);
        }
      }
    }
    courants = suivants;
  }
  return courants.values.toList();
}

/// Le patron se replie-t-il en cube ? On fait rouler le dé sur ses cases.
bool estPatronDeCube(Cases cases) {
  if (cases.length != 6) return false;
  final (int, int) depart = cases.first;
  final Map<(int, int), De> des = <(int, int), De>{depart: De.initial};
  final List<(int, int)> aVisiter = <(int, int)>[depart];
  while (aVisiter.isNotEmpty) {
    final (int, int) ici = aVisiter.removeLast();
    for (final (int, int) pas in const <(int, int)>[
      (1, 0),
      (-1, 0),
      (0, 1),
      (0, -1),
    ]) {
      final (int, int) voisine = (ici.$1 + pas.$1, ici.$2 + pas.$2);
      if (!cases.contains(voisine) || des.containsKey(voisine)) continue;
      des[voisine] = des[ici]!.apres(pas.$1, pas.$2);
      aVisiter.add(voisine);
    }
  }
  // Toutes les cases doivent être atteintes : un patron est d'un seul morceau.
  if (des.length != cases.length) return false;
  // Et les six faces du dessous doivent être distinctes.
  final Set<int> facesPosees = des.values.map((De d) => d.dessous).toSet();
  return facesPosees.length == 6;
}

void main() {
  group('Le dé roule correctement', () {
    test('un aller-retour revient à l’état de départ', () {
      final De d = De.initial.versEst().versOuest();
      expect(d.dessous, De.initial.dessous);
      expect(d.dessus, De.initial.dessus);
      expect(d.est, De.initial.est);
      expect(d.nord, De.initial.nord);
    });

    test('quatre basculements dans le même sens font un tour', () {
      De d = De.initial;
      for (int i = 0; i < 4; i++) {
        d = d.versEst();
      }
      expect(d.dessous, De.initial.dessous);
      expect(d.dessus, De.initial.dessus);
      expect(d.ouest, De.initial.ouest);
    });

    test('les faces opposées restent opposées', () {
      De d = De.initial;
      for (int i = 0; i < 17; i++) {
        d = i % 3 == 0 ? d.versEst() : (i % 3 == 1 ? d.versNord() : d.versSud());
        // Le dé initial a 1 face 6, 2 face 5, 3 face 4 : la somme des
        // opposées vaut sept, et un roulement ne peut pas défaire cela.
        expect(d.dessous + d.dessus, 7, reason: 'après $i basculements');
        expect(d.nord + d.sud, 7);
        expect(d.est + d.ouest, 7);
      }
    });

    test('un basculement change bien la face du dessous', () {
      expect(De.initial.versEst().dessous, isNot(De.initial.dessous));
      expect(De.initial.versNord().dessous, isNot(De.initial.dessous));
    });
  });

  group('Énumération des polyominos', () {
    test('les comptes connus sont retrouvés', () {
      // Suite classique des polyominos libres : 1, 1, 2, 5, 12, 35.
      expect(polyominos(1).length, 1);
      expect(polyominos(2).length, 1);
      expect(polyominos(3).length, 2);
      expect(polyominos(4).length, 5, reason: 'les cinq tétraminos libres');
      expect(polyominos(5).length, 12, reason: 'les douze pentaminos');
      expect(polyominos(6).length, 35, reason: 'les trente-cinq hexaminos');
    });

    test('chaque hexamino a bien six cases et tient d’un seul morceau', () {
      for (final Cases forme in polyominos(6)) {
        expect(forme.length, 6);
        // Connexité : une marche depuis une case atteint les six.
        final Set<(int, int)> vues = <(int, int)>{forme.first};
        final List<(int, int)> pile = <(int, int)>[forme.first];
        while (pile.isNotEmpty) {
          final (int, int) ici = pile.removeLast();
          for (final (int, int) pas in const <(int, int)>[
            (1, 0),
            (-1, 0),
            (0, 1),
            (0, -1),
          ]) {
            final (int, int) v = (ici.$1 + pas.$1, ici.$2 + pas.$2);
            if (forme.contains(v) && vues.add(v)) pile.add(v);
          }
        }
        expect(vues.length, 6);
      }
    });
  });

  group('Les patrons du cube', () {
    test('il y en a exactement onze', () {
      final List<Cases> patrons =
          polyominos(6).where(estPatronDeCube).toList();
      expect(patrons.length, 11);
    });

    test('la bande de six en ligne n’est pas un patron', () {
      final Cases ligne = <(int, int)>{
        for (int x = 0; x < 6; x++) (x, 0),
      };
      // Six basculements vers l'est font un tour et demi : deux cases
      // reçoivent la même face du dessous.
      expect(estPatronDeCube(ligne), isFalse);
    });

    test('la croix latine classique en est un', () {
      // Une colonne de quatre, avec deux ailes de part et d'autre de la
      // deuxième case : le patron de boîte le plus courant.
      final Cases croix = <(int, int)>{
        (1, 0),
        (1, 1),
        (1, 2),
        (1, 3),
        (0, 1),
        (2, 1),
      };
      expect(estPatronDeCube(croix), isTrue);
    });

    test('le bloc deux sur trois n’est pas un patron', () {
      final Cases bloc = <(int, int)>{
        (0, 0),
        (1, 0),
        (2, 0),
        (0, 1),
        (1, 1),
        (2, 1),
      };
      expect(estPatronDeCube(bloc), isFalse);
    });

    test('tout carré deux sur deux condamne le patron', () {
      // C'est ce que l'astuce du chapitre annonce : au pliage, deux carrés
      // se superposent. On le vérifie sur tous les hexaminos qui en
      // contiennent un.
      bool contientCarre(Cases forme) {
        for (final (int, int) c in forme) {
          if (forme.contains((c.$1 + 1, c.$2)) &&
              forme.contains((c.$1, c.$2 + 1)) &&
              forme.contains((c.$1 + 1, c.$2 + 1))) {
            return true;
          }
        }
        return false;
      }

      final List<Cases> avecCarre =
          polyominos(6).where(contientCarre).toList();
      expect(avecCarre, isNotEmpty, reason: 'il en existe bien');
      for (final Cases forme in avecCarre) {
        expect(estPatronDeCube(forme), isFalse,
            reason: 'hexamino contenant un bloc 2 × 2 : ${_canonique(forme)}');
      }
    });

    test('aucun patron ne contient de carré deux sur deux', () {
      // La réciproque de l'énoncé précédent, dans l'autre sens.
      for (final Cases patron in polyominos(6).where(estPatronDeCube)) {
        for (final (int, int) c in patron) {
          final bool carre = patron.contains((c.$1 + 1, c.$2)) &&
              patron.contains((c.$1, c.$2 + 1)) &&
              patron.contains((c.$1 + 1, c.$2 + 1));
          expect(carre, isFalse, reason: _canonique(patron));
        }
      }
    });

    test('un patron couvre les six faces, une fois chacune', () {
      for (final Cases patron in polyominos(6).where(estPatronDeCube)) {
        final (int, int) depart = patron.first;
        final Map<(int, int), De> des = <(int, int), De>{depart: De.initial};
        final List<(int, int)> pile = <(int, int)>[depart];
        while (pile.isNotEmpty) {
          final (int, int) ici = pile.removeLast();
          for (final (int, int) pas in const <(int, int)>[
            (1, 0),
            (-1, 0),
            (0, 1),
            (0, -1),
          ]) {
            final (int, int) v = (ici.$1 + pas.$1, ici.$2 + pas.$2);
            if (!patron.contains(v) || des.containsKey(v)) continue;
            des[v] = des[ici]!.apres(pas.$1, pas.$2);
            pile.add(v);
          }
        }
        final List<int> faces = des.values.map((De d) => d.dessous).toList()
          ..sort();
        expect(faces, <int>[1, 2, 3, 4, 5, 6], reason: _canonique(patron));
      }
    });

    test('les vingt-quatre autres hexaminos échouent', () {
      final int total = polyominos(6).length;
      final int patrons = polyominos(6).where(estPatronDeCube).length;
      expect(total, 35);
      expect(patrons, 11);
      expect(total - patrons, 24);
    });
  });
}
