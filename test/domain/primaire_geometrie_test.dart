import 'package:flutter_test/flutter_test.dart';

/// La géométrie du primaire et le repérage par le ciel, recalculés.
///
/// Ces quatre chapitres reposent sur des propriétés qui se vérifient par
/// énumération : l'inégalité triangulaire, la hiérarchie des quadrilatères,
/// la relation d'Euler, et le fait qu'à périmètre fixé le carré gagne. Les
/// tests les établissent plutôt que de les recopier — c'est la différence
/// entre un corrigé relu et un corrigé vérifié.
void main() {
  group('Inégalité triangulaire', () {
    bool possible(int a, int b, int c) {
      final List<int> t = <int>[a, b, c]..sort();
      return t[0] + t[1] > t[2];
    }

    test('les triplets du chapitre sont correctement classés', () {
      expect(possible(4, 5, 6), isTrue);
      expect(possible(3, 3, 5), isTrue);
      expect(possible(2, 2, 3), isTrue);
      expect(possible(3, 4, 10), isFalse);
      expect(possible(1, 2, 3), isFalse, reason: '1 + 2 = 3, points alignés');
      expect(possible(2, 3, 9), isFalse);
    });

    test('le cas limite donne trois points alignés, pas un triangle', () {
      // Quand la somme des deux petits égale le grand, les arcs se touchent
      // en un point unique posé sur le segment.
      expect(possible(1, 2, 3), isFalse);
      expect(possible(5, 5, 10), isFalse);
      expect(possible(5, 5, 9), isTrue, reason: 'un millimètre de plus suffit');
    });

    test('vérifier le plus grand côté suffit', () {
      // La carte « à retenir » l'affirme : si le plus grand passe, les deux
      // autres passent forcément. On l'établit sur tous les triplets.
      for (int a = 1; a <= 12; a++) {
        for (int b = 1; b <= 12; b++) {
          for (int c = 1; c <= 12; c++) {
            final List<int> t = <int>[a, b, c]..sort();
            final bool plusGrand = t[0] + t[1] > t[2];
            final bool tous = t[0] + t[1] > t[2] &&
                t[0] + t[2] > t[1] &&
                t[1] + t[2] > t[0];
            expect(plusGrand, tous, reason: '$a, $b, $c');
          }
        }
      }
    });

    test('avec 5 et 8, le troisième côté va de 4 à 12', () {
      final List<int> valides = <int>[];
      for (int x = 1; x <= 20; x++) {
        if (possible(5, 8, x)) valides.add(x);
      }
      expect(valides.first, 4);
      expect(valides.last, 12);
      expect(valides.length, 9);
      expect(valides, List<int>.generate(9, (int i) => i + 4));
    });

    test('les bornes se calculent et ne se devinent pas', () {
      // Borne haute : strictement moins que la somme. Borne basse :
      // strictement plus que la différence.
      for (int a = 2; a <= 15; a++) {
        for (int b = a; b <= 15; b++) {
          final List<int> valides = <int>[];
          for (int x = 1; x <= 40; x++) {
            if (possible(a, b, x)) valides.add(x);
          }
          expect(valides.first, b - a + 1, reason: 'borne basse pour $a et $b');
          expect(valides.last, a + b - 1, reason: 'borne haute pour $a et $b');
          expect(valides.length, 2 * a - 1, reason: 'compte pour $a et $b');
        }
      }
    });

    test('le chemin direct est le plus court', () {
      // AC + CB >= AB pour tout point C : c'est l'inégalité, lue dans
      // l'autre sens. On l'éprouve sur une grille de points.
      double distance(double ax, double ay, double bx, double by) {
        final double dx = bx - ax;
        final double dy = by - ay;
        return (dx * dx + dy * dy) <= 0 ? 0 : _racine(dx * dx + dy * dy);
      }

      const double ax = 0, ay = 0, bx = 10, by = 0;
      final double direct = distance(ax, ay, bx, by);
      expect(direct, 10);
      for (double cx = -5; cx <= 15; cx += 2.5) {
        for (double cy = -5; cy <= 5; cy += 2.5) {
          final double detour =
              distance(ax, ay, cx, cy) + distance(cx, cy, bx, by);
          expect(detour, greaterThanOrEqualTo(direct - 1e-9),
              reason: 'par ($cx, $cy)');
        }
      }
    });
  });

  group('Angles d’un triangle', () {
    test('les trois angles font cent quatre-vingts degrés', () {
      expect(180 - 70 - 50, 60);
      expect(180 - 90 - 35, 55);
      expect(180 ~/ 3, 60, reason: 'l’équilatéral');
    });

    test('deux angles droits sont impossibles', () {
      expect(180 - 90 - 90, 0);
      // Il ne resterait rien pour le troisième, qui doit être strictement
      // positif : le triangle n'existe pas.
      expect(180 - 90 - 90, lessThanOrEqualTo(0));
    });

    test('un équilatéral ne peut pas être rectangle', () {
      const int angleEquilateral = 60;
      expect(angleEquilateral, isNot(90));
      expect(angleEquilateral * 3, 180, reason: 'la somme est bien respectée');
    });

    test('dans un rectangle, les deux autres angles font ensemble un droit', () {
      for (int a = 1; a <= 89; a++) {
        final int b = 180 - 90 - a;
        expect(a + b, 90, reason: 'angle de $a°');
        expect(b, greaterThan(0));
      }
    });

    test('le rectangle isocèle est unique à la taille près', () {
      // Un angle droit et deux côtés égaux forcent 45° et 45°.
      const int reste = 180 - 90;
      expect(reste ~/ 2, 45);
      expect(reste % 2, 0, reason: 'les deux angles égaux se partagent 90°');
    });
  });

  group('Familles de quadrilatères', () {
    /// Un quadrilatère décrit par ce qui est vrai de lui. Les inclusions du
    /// chapitre sont alors des implications entre ensembles, qu'on éprouve
    /// sur des cas concrets au lieu de les affirmer.
    bool estParallelogramme(Set<String> p) => p.contains('côtés parallèles');
    bool estRectangle(Set<String> p) =>
        estParallelogramme(p) && p.contains('angles droits');
    bool estLosange(Set<String> p) =>
        estParallelogramme(p) && p.contains('côtés égaux');
    bool estCarre(Set<String> p) => estRectangle(p) && estLosange(p);

    const Set<String> carre = {
      'côtés parallèles',
      'angles droits',
      'côtés égaux',
    };
    const Set<String> rectangleAllonge = {
      'côtés parallèles',
      'angles droits',
    };
    const Set<String> losangePenche = {
      'côtés parallèles',
      'côtés égaux',
    };

    test('un carré est rectangle, losange et parallélogramme', () {
      expect(estCarre(carre), isTrue);
      expect(estRectangle(carre), isTrue);
      expect(estLosange(carre), isTrue);
      expect(estParallelogramme(carre), isTrue);
    });

    test('un rectangle allongé n’est pas un carré', () {
      expect(estRectangle(rectangleAllonge), isTrue);
      expect(estCarre(rectangleAllonge), isFalse);
      expect(estLosange(rectangleAllonge), isFalse);
    });

    test('un losange penché n’est pas un carré', () {
      expect(estLosange(losangePenche), isTrue);
      expect(estCarre(losangePenche), isFalse);
      expect(estRectangle(losangePenche), isFalse);
    });

    test('le carré est exactement l’intersection des deux familles', () {
      // Pour les huit combinaisons possibles des trois propriétés.
      const List<String> proprietes = [
        'côtés parallèles',
        'angles droits',
        'côtés égaux',
      ];
      for (int masque = 0; masque < 8; masque++) {
        final Set<String> p = <String>{};
        for (int i = 0; i < 3; i++) {
          if (masque & (1 << i) != 0) p.add(proprietes[i]);
        }
        expect(estCarre(p), estRectangle(p) && estLosange(p),
            reason: 'combinaison $p');
      }
    });

    test('un rectangle de trois sur cinq réfute la réciproque', () {
      // Le contre-exemple que l'explication cite : il a bien quatre angles
      // droits, et ses côtés ne sont pas égaux.
      const int longueur = 5;
      const int largeur = 3;
      expect(longueur == largeur, isFalse);
      expect(estRectangle(rectangleAllonge), isTrue);
      expect(estCarre(rectangleAllonge), isFalse);
    });
  });

  group('Relation d’Euler', () {
    /// faces, sommets, arêtes pour les polyèdres cités.
    const Map<String, List<int>> polyedres = {
      'tétraèdre': [4, 4, 6],
      'cube': [6, 8, 12],
      'pyramide à base carrée': [5, 5, 8],
      'prisme à base triangulaire': [5, 6, 9],
      'prisme à base hexagonale': [8, 12, 18],
      'octaèdre': [8, 6, 12],
      'dodécaèdre': [12, 20, 30],
      'icosaèdre': [20, 12, 30],
    };

    test('elle vaut deux pour tous les polyèdres de la table', () {
      polyedres.forEach((String nom, List<int> fsa) {
        expect(fsa[0] + fsa[1] - fsa[2], 2, reason: nom);
      });
    });

    test('le cube : six, huit, douze', () {
      expect(polyedres['cube'], <int>[6, 8, 12]);
    });

    test('les arêtes de la pyramide se déduisent de la relation', () {
      // 5 + 5 − A = 2 donne A = 8.
      const int faces = 5;
      const int sommets = 5;
      expect(faces + sommets - 2, 8);
      expect(polyedres['pyramide à base carrée']![2], 8);
    });

    test('les sommets du prisme triangulaire se déduisent aussi', () {
      // 5 + S − 9 = 2 donne S = 6.
      const int faces = 5;
      const int aretes = 9;
      expect(2 - faces + aretes, 6);
      expect(polyedres['prisme à base triangulaire']![1], 6);
    });

    test('les nombres de faces du jeu d’appariement', () {
      expect(polyedres['tétraèdre']![0], 4);
      expect(polyedres['pyramide à base carrée']![0], 5);
      expect(polyedres['cube']![0], 6);
      expect(polyedres['prisme à base hexagonale']![0], 8);
    });

    test('un prisme à base n côtés suit la relation pour tout n', () {
      for (int n = 3; n <= 20; n++) {
        final int faces = n + 2; // n rectangles et deux bases
        final int sommets = 2 * n;
        final int aretes = 3 * n;
        expect(faces + sommets - aretes, 2, reason: 'prisme à $n côtés');
      }
    });

    test('une pyramide à base n côtés aussi', () {
      for (int n = 3; n <= 20; n++) {
        final int faces = n + 1;
        final int sommets = n + 1;
        final int aretes = 2 * n;
        expect(faces + sommets - aretes, 2, reason: 'pyramide à $n côtés');
      }
    });
  });

  group('Le cube et le dé', () {
    test('les faces opposées d’un dé font sept', () {
      for (int face = 1; face <= 6; face++) {
        expect(7 - face, inInclusiveRange(1, 6));
      }
      expect(7 - 2, 5);
      expect(7 - 1, 6);
      expect(7 - 3, 4);
    });

    test('la somme des six faces vaut vingt-et-un', () {
      int somme = 0;
      for (int face = 1; face <= 6; face++) {
        somme += face;
      }
      expect(somme, 21);
      expect(somme, 3 * 7, reason: 'trois paires opposées valant sept');
    });

    test('un cube d’arête trois a cinquante-quatre centimètres carrés', () {
      const int arete = 3;
      expect(arete * arete, 9);
      expect(6 * arete * arete, 54);
    });

    test('la surface d’un cube croît comme le carré de l’arête', () {
      for (int a = 1; a <= 10; a++) {
        // Doubler l'arête quadruple la surface : c'est pourquoi un gros
        // paquet demande proportionnellement moins de carton.
        expect(6 * (2 * a) * (2 * a), 4 * (6 * a * a), reason: 'arête $a');
        // Et le volume, lui, est multiplié par huit.
        expect((2 * a) * (2 * a) * (2 * a), 8 * a * a * a, reason: 'arête $a');
      }
    });
  });

  group('Périmètres et aires', () {
    int perimetre(int l, int L) => 2 * (l + L);
    int aire(int l, int L) => l * L;

    test('les valeurs du chapitre', () {
      expect(perimetre(9, 4), 26);
      expect(perimetre(7, 7), 28);
      expect(aire(8, 5), 40);
      expect(aire(9, 9), 81);
      expect((10 * 6) ~/ 2, 30, reason: 'le triangle, moitié du rectangle');
      expect(aire(4, 3), 12);
    });

    test('la largeur se retrouve depuis le périmètre', () {
      expect(30 ~/ 2 - 10, 5);
      for (int L = 1; L <= 14; L++) {
        final int l = 30 ~/ 2 - L;
        if (l <= 0) continue;
        expect(perimetre(l, L), 30, reason: 'longueur $L');
      }
    });

    test('à périmètre vingt, le carré gagne', () {
      final Map<int, int> aires = <int, int>{};
      for (int l = 1; l <= 9; l++) {
        final int L = 10 - l;
        if (L < l) continue;
        aires[l] = aire(l, L);
      }
      expect(aires, <int, int>{1: 9, 2: 16, 3: 21, 4: 24, 5: 25});
      final int maximum = aires.values.reduce((a, b) => a > b ? a : b);
      expect(maximum, 25);
      expect(aires[5], maximum, reason: 'le carré de côté 5');
    });

    test('le carré gagne même parmi les rectangles non entiers', () {
      // On balaie finement la demi-largeur : l'aire est maximale au carré.
      const double demiPerimetre = 10;
      double meilleure = -1;
      double meilleurCote = -1;
      for (double l = 0.05; l < demiPerimetre; l += 0.05) {
        final double a = l * (demiPerimetre - l);
        if (a > meilleure) {
          meilleure = a;
          meilleurCote = l;
        }
      }
      expect(meilleurCote, closeTo(5, 0.06));
      expect(meilleure, closeTo(25, 0.01));
    });

    test('à aire fixée, le carré demande le moins de grillage', () {
      final Map<int, int> perimetres = <int, int>{};
      for (int l = 1; l <= 36; l++) {
        if (36 % l != 0) continue;
        final int L = 36 ~/ l;
        if (L < l) continue;
        perimetres[l] = perimetre(l, L);
      }
      expect(perimetres[1], 74);
      expect(perimetres[6], 24);
      final int minimum = perimetres.values.reduce((a, b) => a < b ? a : b);
      expect(minimum, 24);
      expect(perimetres[6], minimum, reason: 'le carré de côté 6');
      // Trois fois plus de grillage pour la même place.
      expect(perimetres[1]! / perimetres[6]!, closeTo(74 / 24, 1e-9));
      expect(perimetres[1]! > 3 * perimetres[6]!, isTrue);
    });

    test('périmètre égal n’entraîne pas aire égale', () {
      expect(perimetre(1, 9), perimetre(5, 5));
      expect(aire(1, 9), isNot(aire(5, 5)));
    });

    test('aire égale n’entraîne pas périmètre égal', () {
      expect(aire(1, 36), aire(6, 6));
      expect(perimetre(1, 36), isNot(perimetre(6, 6)));
    });
  });

  group('Conversions d’aires', () {
    test('un mètre carré fait dix mille centimètres carrés', () {
      expect(100 * 100, 10000);
    });

    test('le facteur des aires est le carré de celui des longueurs', () {
      const Map<String, int> versMm = {
        'mm': 1,
        'cm': 10,
        'm': 1000,
        'km': 1000000,
      };
      expect(versMm['cm']! * versMm['cm']!, 100, reason: '1 cm² = 100 mm²');
      expect(versMm['m']! * versMm['m']!, 1000000, reason: '1 m² = 10⁶ mm²');
      // Et le rapport m²/cm² est bien 10 000, non 100.
      final int rapport =
          (versMm['m']! * versMm['m']!) ~/ (versMm['cm']! * versMm['cm']!);
      expect(rapport, 10000);
      expect(rapport, isNot(100), reason: 'l’erreur que la carte dénonce');
    });
  });

  group('Angles et compléments', () {
    test('tour, plat, droit', () {
      expect(360 ~/ 2, 180);
      expect(360 ~/ 4, 90);
    });

    test('complémentaire et supplémentaire', () {
      expect(90 - 55, 35);
      expect(180 - 115, 65);
      for (int a = 1; a <= 89; a++) {
        expect(a + (90 - a), 90, reason: 'complémentaire de $a');
      }
      for (int a = 1; a <= 179; a++) {
        expect(a + (180 - a), 180, reason: 'supplémentaire de $a');
      }
    });

    test('le classement aigu, droit, obtus, plat', () {
      String sorte(int a) {
        if (a < 90) return 'aigu';
        if (a == 90) return 'droit';
        if (a < 180) return 'obtus';
        return 'plat';
      }

      expect(sorte(30), 'aigu');
      expect(sorte(75), 'aigu');
      expect(sorte(90), 'droit');
      expect(sorte(120), 'obtus');
      expect(sorte(160), 'obtus');
      expect(sorte(180), 'plat');
    });

    test('trois cent soixante se divise par beaucoup d’entiers', () {
      // La carte l'avance comme la raison du choix babylonien : on compte.
      int diviseurs(int n) {
        int d = 0;
        for (int i = 1; i <= n; i++) {
          if (n % i == 0) d++;
        }
        return d;
      }

      expect(diviseurs(360), 24);
      for (final int voisin in <int>[358, 359, 361, 362]) {
        expect(diviseurs(voisin), lessThan(diviseurs(360)), reason: '$voisin');
      }
    });
  });

  group('Le cercle', () {
    test('diamètre et rayon', () {
      expect(2 * 7, 14);
      expect(18 ~/ 2, 9);
      expect(2 * 6, 12, reason: 'la zone broutée par la chèvre');
    });

    test('dedans, dessus, dehors se décide par comparaison', () {
      String position(double distance, double rayon) {
        if (distance < rayon) return 'dedans';
        if (distance == rayon) return 'dessus';
        return 'dehors';
      }

      expect(position(2, 5), 'dedans');
      expect(position(4.9, 5), 'dedans');
      expect(position(5, 5), 'dessus');
      expect(position(5.1, 5), 'dehors');
      expect(position(12, 5), 'dehors');
    });
  });

  group('Rotation du ciel', () {
    const double parHeure = 360 / 24;

    test('quinze degrés par heure', () {
      expect(parHeure, 15);
    });

    test('six heures font un quart de tour', () {
      expect(parHeure * 6, 90);
      expect(parHeure * 6, 360 / 4);
    });

    test('quarante-cinq degrés font trois heures', () {
      expect(45 / parHeure, 3);
    });

    test('vingt-quatre heures font le tour complet', () {
      expect(parHeure * 24, 360);
    });

    test('la Grande Ourse à vingt-deux heures, un quart de tour à quatre heures', () {
      const int depart = 22;
      final int arrivee = (depart + (90 / parHeure).round()) % 24;
      expect(arrivee, 4);
    });

    test('le Soleil aussi : trois heures après midi, quarante-cinq degrés', () {
      expect(parHeure * 3, 45);
    });
  });

  group('Latitude et étoile Polaire', () {
    test('un degré de latitude vaut environ cent onze kilomètres', () {
      const double tourDeTerre = 40000; // km
      expect(tourDeTerre / 360, closeTo(111, 0.2));
    });

    test('trois degrés font trois cent trente-trois kilomètres', () {
      expect(3 * 111, 333);
      expect(52 - 49, 3);
    });

    test('la hauteur de la Polaire est la latitude', () {
      const Map<String, int> latitudes = {
        'équateur': 0,
        'Marseille': 43,
        'Paris': 49,
        'pôle Nord': 90,
      };
      latitudes.forEach((String lieu, int lat) {
        expect(lat, inInclusiveRange(0, 90), reason: lieu);
      });
      expect(latitudes['pôle Nord'], 90);
      expect(latitudes['équateur'], 0, reason: 'elle rase l’horizon');
      expect(latitudes['Paris']! - latitudes['Marseille']!, 6);
    });

    test('la distance Paris-Marseille du nord au sud se retrouve', () {
      // Six degrés de latitude, cent onze kilomètres chacun.
      const double km = 6 * (40000 / 360);
      expect(km, closeTo(667, 1));
      // L'ordre de grandeur de la distance réelle, qui vaut environ 660 km
      // à vol d'oiseau : le calcul par la latitude seule tient debout.
      expect(km, greaterThan(600));
      expect(km, lessThan(720));
    });
  });
}

/// Racine carrée par la méthode de Héron, pour garder ce fichier sans
/// dépendance et montrer que le calcul n'est pas emprunté.
double _racine(double x) {
  if (x <= 0) return 0;
  double r = x;
  for (int i = 0; i < 60; i++) {
    r = (r + x / r) / 2;
  }
  return r;
}
