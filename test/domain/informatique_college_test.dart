import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// L'informatique du collège, recalculée.
///
/// Ces quatre chapitres sont entièrement faits d'affirmations exécutables :
/// un programme se déroule, une recopie de formule se simule, un parcours
/// de personnage se calcule, une durée de téléchargement se divise. Rien
/// n'est relu — tout est rejoué.
void main() {
  group('Affectation', () {
    test('x = x + 1 incrémente', () {
      int x = 7;
      x = x + 1;
      expect(x, 8);
    });

    test('l’échange naïf perd une valeur', () {
      int x = 5;
      int y = 3;
      x = y;
      y = x;
      expect(x, 3);
      expect(y, 3);
      // Le 5 n'existe plus nulle part : c'est exactement ce que le
      // chapitre annonce, et il vaut mieux le voir que le lire.
      expect(x == 5 || y == 5, isFalse);
    });

    test('l’échange avec variable temporaire réussit', () {
      int x = 5;
      int y = 3;
      final int t = x;
      x = y;
      y = t;
      expect(x, 3);
      expect(y, 5);
    });

    test('l’échange temporaire marche sur toutes les paires', () {
      for (int a = -5; a <= 5; a++) {
        for (int b = -5; b <= 5; b++) {
          int x = a;
          int y = b;
          final int t = x;
          x = y;
          y = t;
          expect(x, b, reason: '($a, $b)');
          expect(y, a, reason: '($a, $b)');
        }
      }
    });

    test('l’échange arithmétique du défi marche aussi', () {
      // a = a + b ; b = a − b ; a = a − b
      for (int d = -20; d <= 20; d += 7) {
        for (int e = -20; e <= 20; e += 7) {
          int a = d;
          int b = e;
          a = a + b;
          b = a - b;
          a = a - b;
          expect(a, e, reason: '($d, $e)');
          expect(b, d, reason: '($d, $e)');
        }
      }
    });

    test('les valeurs du déroulé du chapitre', () {
      int a = 2;
      int b = 5;
      a = a + b;
      expect(a, 7);
      b = a - b;
      expect(b, 2);
      a = a - b;
      expect(a, 5);
    });

    test('un accumulateur de somme', () {
      int total = 20;
      const int prix = 8;
      total = total + prix;
      expect(total, 28);
    });
  });

  group('Expressions', () {
    test('la priorité des opérations', () {
      expect(2 + 3 * 4, 14);
      expect((2 + 3) * 4, 20);
      expect(2 + 3 * 4, isNot(20), reason: 'ce n’est pas une lecture de gauche à droite');
    });

    test('division entière et modulo', () {
      expect(17 ~/ 5, 3);
      expect(17 % 5, 2);
      // Et l'identité de la division euclidienne tient partout.
      for (int n = 0; n <= 50; n++) {
        for (int d = 1; d <= 9; d++) {
          expect((n ~/ d) * d + n % d, n, reason: '$n ÷ $d');
        }
      }
    });

    test('le modulo teste la parité', () {
      for (int n = 0; n <= 40; n++) {
        expect(n % 2 == 0, n.isEven, reason: '$n');
      }
    });

    test('la formule de moyenne, avec et sans parenthèses', () {
      const double n1 = 12;
      const double n2 = 15;
      const double n3 = 9;
      expect((n1 + n2 + n3) / 3, 12);
      // Sans parenthèses, seule la troisième note est divisée.
      expect(n1 + n2 + n3 / 3, 30);
      expect(n1 + n2 + n3 / 3, isNot((n1 + n2 + n3) / 3));
    });

    test('le plus des textes colle au lieu d’additionner', () {
      const String a = '2';
      const String b = '3';
      expect(a + b, '23');
      expect(int.parse(a) + int.parse(b), 5);
      expect(a + b, isNot('5'));
    });
  });

  group('Boucles et accumulateurs', () {
    test('une somme initialisée avant la boucle', () {
      int somme = 0;
      for (int i = 1; i <= 4; i++) {
        somme = somme + i;
      }
      expect(somme, 10);
    });

    test('une somme initialisée dedans ne garde que le dernier terme', () {
      int somme = 0;
      for (int i = 1; i <= 4; i++) {
        somme = 0; // le bug du chapitre
        somme = somme + i;
      }
      expect(somme, 4);
      // Et il produit un résultat plausible, ce qui le rend difficile à voir.
      expect(somme, lessThan(10));
      expect(somme, greaterThan(0));
    });

    test('un produit s’initialise à un', () {
      int produit = 1;
      for (int i = 1; i <= 5; i++) {
        produit = produit * i;
      }
      expect(produit, 120);
    });

    test('un produit initialisé à zéro reste à zéro', () {
      int produit = 0;
      for (int i = 1; i <= 5; i++) {
        produit = produit * i;
      }
      expect(produit, 0);
    });

    test('l’élément neutre dépend de l’opération', () {
      // Zéro pour l'addition, un pour la multiplication : on le vérifie
      // sur une plage, plutôt que de l'affirmer.
      for (int n = 1; n <= 10; n++) {
        expect(0 + n, n, reason: 'neutre additif');
        expect(1 * n, n, reason: 'neutre multiplicatif');
      }
    });
  });

  group('La caisse du défi', () {
    test('le programme correct donne neuf euros', () {
      double total = 5 + 3 + 2;
      expect(total, 10);
      final double remise = total * 10 / 100;
      expect(remise, 1);
      total = total - remise;
      expect(total, 9);
    });

    test('le bug de la double division donne 9,99', () {
      double total = 5 + 3 + 2;
      final double remise = total * 10 / 100;
      total = total - remise / 100; // la division passe avant la soustraction
      expect(total, closeTo(9.99, 1e-9));
    });

    test('le bug du cent manquant donne un total négatif', () {
      const double total = 10;
      const double remise = total * 10; // le /100 oublié
      expect(total - remise, -90);
    });

    test('le bug plausible est bien le plus dangereux', () {
      // Un écart de 11 % passe inaperçu ; un total négatif non.
      const double juste = 9;
      const double plausible = 9.99;
      const double absurde = -90;
      expect((plausible - juste).abs() / juste, lessThan(0.2));
      expect(absurde, lessThan(0), reason: 'un montant négatif se remarque');
    });
  });

  group('Recopie de formules du tableur', () {
    /// Une référence à recopier : la colonne et la ligne, chacune figée ou
    /// non. On simule le décalage que fait le tableur.
    String recopier(
      String colonne,
      int ligne, {
      required bool colonneFigee,
      required bool ligneFigee,
      required int deColonnes,
      required int deLignes,
    }) {
      final String nouvelleColonne = colonneFigee
          ? colonne
          : String.fromCharCode(colonne.codeUnitAt(0) + deColonnes);
      final int nouvelleLigne = ligneFigee ? ligne : ligne + deLignes;
      return '${colonneFigee ? '\$' : ''}$nouvelleColonne'
          '${ligneFigee ? '\$' : ''}$nouvelleLigne';
    }

    test('une référence relative suit la recopie vers le bas', () {
      expect(
        recopier('A', 2,
            colonneFigee: false, ligneFigee: false, deColonnes: 0, deLignes: 3),
        'A5',
      );
    });

    test('deux dollars ne bougent pas', () {
      expect(
        recopier('A', 2,
            colonneFigee: true, ligneFigee: true, deColonnes: 0, deLignes: 3),
        r'$A$2',
      );
    });

    test('une ligne figée laisse la colonne avancer', () {
      expect(
        recopier('A', 2,
            colonneFigee: false, ligneFigee: true, deColonnes: 1, deLignes: 0),
        r'B$2',
      );
    });

    test('une colonne figée laisse la ligne descendre', () {
      expect(
        recopier('A', 2,
            colonneFigee: true, ligneFigee: false, deColonnes: 2, deLignes: 4),
        r'$A6',
      );
    });

    test('le bug du taux non figé glisse vers des lignes vides', () {
      // =B2*D1 recopiée de trois lignes vers le bas.
      final String prix = recopier('B', 2,
          colonneFigee: false, ligneFigee: false, deColonnes: 0, deLignes: 3);
      final String taux = recopier('D', 1,
          colonneFigee: false, ligneFigee: false, deColonnes: 0, deLignes: 3);
      expect(prix, 'B5');
      expect(taux, 'D4', reason: 'le taux a glissé, la cellule est vide');
      // Avec les dollars, le taux reste en place.
      final String tauxFige = recopier('D', 1,
          colonneFigee: true, ligneFigee: true, deColonnes: 0, deLignes: 3);
      expect(tauxFige, r'$D$1');
    });

    test('la table de multiplication se remplit d’un geste', () {
      // =$A2*B$1 : la colonne A figée fournit un facteur par ligne, la
      // ligne 1 figée fournit l'autre par colonne.
      for (int dl = 0; dl < 5; dl++) {
        for (int dc = 0; dc < 5; dc++) {
          final String gauche = recopier('A', 2,
              colonneFigee: true,
              ligneFigee: false,
              deColonnes: dc,
              deLignes: dl);
          final String haut = recopier('B', 1,
              colonneFigee: false,
              ligneFigee: true,
              deColonnes: dc,
              deLignes: dl);
          expect(gauche, '\$A${2 + dl}', reason: 'décalage $dc,$dl');
          expect(haut, '${String.fromCharCode(66 + dc)}\$1',
              reason: 'décalage $dc,$dl');
        }
      }
    });
  });

  group('Fonctions du tableur', () {
    const List<num> plage = [4, 8, 6, 10, 2];

    test('somme, moyenne, étendue', () {
      final num somme = plage.reduce((a, b) => a + b);
      expect(somme, 30);
      expect(somme / plage.length, 6);
      expect(plage.reduce(math.max) - plage.reduce(math.min), 8);
    });

    test('NB.SI compte les valeurs qui passent le test', () {
      expect(plage.where((num v) => v > 5).length, 3);
      expect(plage.where((num v) => v > 10).length, 0);
      expect(plage.where((num v) => v >= 10).length, 1);
    });

    test('un vide et un zéro ne donnent pas la même moyenne', () {
      // MOYENNE ignore les vides : quatre valeurs au lieu de cinq.
      const List<num> avecVide = [4, 8, 10, 2];
      const List<num> avecZero = [4, 8, 0, 10, 2];
      final num mv = avecVide.reduce((a, b) => a + b) / avecVide.length;
      final num mz = avecZero.reduce((a, b) => a + b) / avecZero.length;
      expect(mv, 6);
      expect(mz, closeTo(4.8, 1e-9));
      expect(mv, isNot(mz), reason: 'et aucune erreur n’est signalée');
    });

    test('le SI est inclusif sur le supérieur ou égal', () {
      String verdict(num note) => note >= 10 ? 'admis' : 'recalé';
      expect(verdict(10), 'admis');
      expect(verdict(9.99), 'recalé');
      // Avec un strict supérieur, le 10 basculerait.
      String strict(num note) => note > 10 ? 'admis' : 'recalé';
      expect(strict(10), 'recalé');
      expect(verdict(10), isNot(strict(10)));
    });
  });

  group('La moyenne des moyennes', () {
    double ponderee(List<int> effectifs, List<double> moyennes) {
      double points = 0;
      int total = 0;
      for (int i = 0; i < effectifs.length; i++) {
        points += effectifs[i] * moyennes[i];
        total += effectifs[i];
      }
      return points / total;
    }

    double naive(List<double> moyennes) =>
        moyennes.reduce((a, b) => a + b) / moyennes.length;

    test('deux classes : quinze et non quatorze', () {
      expect(ponderee(<int>[10, 30], <double>[12, 16]), 15);
      expect(naive(<double>[12, 16]), 14);
      expect(ponderee(<int>[10, 30], <double>[12, 16]) - naive(<double>[12, 16]),
          1);
    });

    test('les totaux de points', () {
      expect(10 * 12, 120);
      expect(30 * 16, 480);
      expect((120 + 480) / 40, 15);
    });

    test('trois classes : quatorze virgule soixante-sept', () {
      expect(ponderee(<int>[10, 20, 30], <double>[12, 14, 16]),
          closeTo(14.6667, 1e-4));
      expect(naive(<double>[12, 14, 16]), 14);
    });

    test('les deux coïncident exactement quand les effectifs sont égaux', () {
      for (int n = 1; n <= 30; n++) {
        expect(ponderee(<int>[n, n, n], <double>[12, 14, 16]),
            closeTo(naive(<double>[12, 14, 16]), 1e-9),
            reason: 'effectif $n');
      }
    });

    test('et diffèrent dès que les effectifs diffèrent', () {
      for (int n = 1; n <= 20; n++) {
        if (n == 10) continue; // égalité avec le second effectif
        final double p = ponderee(<int>[n, 10], <double>[12, 16]);
        expect(p, isNot(closeTo(14, 1e-9)), reason: 'effectifs $n et 10');
      }
      // Et le résultat penche toujours vers le groupe le plus nombreux.
      expect(ponderee(<int>[1, 100], <double>[12, 16]), greaterThan(15.9));
      expect(ponderee(<int>[100, 1], <double>[12, 16]), lessThan(12.1));
    });

    test('les pourcentages ne se moyennent pas davantage', () {
      // 50 % sur 10 cas et 90 % sur 1000 cas.
      const double vrai = (0.5 * 10 + 0.9 * 1000) / 1010 * 100;
      expect(vrai, closeTo(89.6, 0.05));
      expect(naive(<double>[50, 90]), 70);
      expect(vrai, isNot(closeTo(70, 1)));
    });
  });

  group('Le parcours du personnage', () {
    /// La convention des langages à blocs : direction 0 vers le haut, sens
    /// horaire. On convertit vers le repère mathématique pour avancer.
    (double, double) avancer(double x, double y, int direction, double pas) {
      final double rad = (90 - direction) * math.pi / 180;
      return (x + pas * math.cos(rad), y + pas * math.sin(rad));
    }

    test('la direction 90 avance vers la droite', () {
      final (double x, double y) = avancer(0, 0, 90, 60);
      expect(x, closeTo(60, 1e-9));
      expect(y, closeTo(0, 1e-9));
    });

    test('la direction 180 avance vers le bas', () {
      final (double x, double y) = avancer(0, 0, 180, 60);
      expect(x, closeTo(0, 1e-9));
      expect(y, closeTo(-60, 1e-9));
    });

    test('la direction 0 avance vers le haut', () {
      final (double x, double y) = avancer(0, 0, 0, 60);
      expect(y, closeTo(60, 1e-9));
    });

    test('quatre fois soixante pas et quatre quarts de tour referment le carré', () {
      double x = 0;
      double y = 0;
      int direction = 90;
      final List<String> etapes = <String>[];
      for (int tour = 0; tour < 4; tour++) {
        final (double nx, double ny) = avancer(x, y, direction, 60);
        x = nx;
        y = ny;
        direction = (direction + 90) % 360;
        etapes.add('(${x.round()} ; ${y.round()}) dir $direction');
      }
      expect(etapes, <String>[
        '(60 ; 0) dir 180',
        '(60 ; -60) dir 270',
        '(0 ; -60) dir 0',
        '(0 ; 0) dir 90',
      ]);
      expect(x, closeTo(0, 1e-9));
      expect(y, closeTo(0, 1e-9));
      expect(direction, 90);
    });

    test('trois fois cent vingt degrés referment un triangle', () {
      double x = 0;
      double y = 0;
      int direction = 90;
      for (int tour = 0; tour < 3; tour++) {
        final (double nx, double ny) = avancer(x, y, direction, 60);
        x = nx;
        y = ny;
        direction = (direction + 120) % 360;
      }
      expect(x, closeTo(0, 1e-9));
      expect(y, closeTo(0, 1e-9));
      expect(direction, 90);
    });

    test('tout polygone régulier se referme avec 360 divisé par n', () {
      for (int n = 3; n <= 12; n++) {
        double x = 0;
        double y = 0;
        double direction = 90;
        final double angle = 360 / n;
        for (int c = 0; c < n; c++) {
          final double rad = (90 - direction) * math.pi / 180;
          x += 60 * math.cos(rad);
          y += 60 * math.sin(rad);
          direction += angle;
        }
        expect(x, closeTo(0, 1e-9), reason: 'polygone à $n côtés');
        expect(y, closeTo(0, 1e-9), reason: 'polygone à $n côtés');
      }
      expect(360 / 5, 72);
    });

    test('la scène et ses bornes', () {
      const int largeur = 480;
      const int hauteur = 360;
      expect(largeur ~/ 2, 240);
      expect(-(hauteur ~/ 2), -180);
      // Le périmètre du carré de 60 vaut la moitié de la largeur.
      expect(4 * 60, 240);
      expect(4 * 60, largeur ~/ 2);
    });

    test('ajouter dix à x quatre fois depuis 200 atteint le bord', () {
      int x = 200;
      for (int i = 0; i < 4; i++) {
        x += 10;
      }
      expect(x, 240);
      expect(x, 480 ~/ 2, reason: 'exactement le bord droit');
    });
  });

  group('Débits et durées', () {
    const int bitsParOctet = 8;

    double secondes({required double megaOctets, required double megaBitsParSeconde}) =>
        megaOctets * bitsParOctet / megaBitsParSeconde;

    test('cent mégaoctets font huit cents mégabits', () {
      expect(100 * bitsParOctet, 800);
    });

    test('quatre-vingts secondes pour cent mégaoctets à dix mégabits', () {
      expect(secondes(megaOctets: 100, megaBitsParSeconde: 10), 80);
    });

    test('oublier le facteur huit donne une durée huit fois trop courte', () {
      final double juste = secondes(megaOctets: 100, megaBitsParSeconde: 10);
      const double faux = 100 / 10;
      expect(juste / faux, 8);
      expect(faux, 10);
    });

    test('un gigaoctet à dix puis cent mégabits', () {
      expect(secondes(megaOctets: 1000, megaBitsParSeconde: 10), 800);
      expect(secondes(megaOctets: 1000, megaBitsParSeconde: 100), 80);
      // Huit cents secondes font treize minutes vingt.
      expect(800 ~/ 60, 13);
      expect(800 % 60, 20);
    });

    test('cent mégabits par seconde font douze virgule cinq mégaoctets', () {
      expect(100 / bitsParOctet, 12.5);
    });

    test('la durée est inversement proportionnelle au débit', () {
      for (final double debit in <double>[1, 2, 5, 10, 50, 100, 1000]) {
        expect(secondes(megaOctets: 1000, megaBitsParSeconde: debit) * debit,
            closeTo(8000, 1e-9),
            reason: '$debit Mbit/s');
      }
    });
  });

  group('Adresses IP', () {
    test('quatre nombres de deux cent cinquante-six valeurs', () {
      const int valeursParOctet = 256;
      expect(valeursParOctet, 255 - 0 + 1, reason: 'le zéro compte');
      int total = 1;
      for (int i = 0; i < 4; i++) {
        total *= valeursParOctet;
      }
      expect(total, 4294967296);
      expect(total / 1e9, closeTo(4.29, 0.01));
    });

    test('c’est deux puissance trente-deux', () {
      expect(math.pow(2, 32), 4294967296);
      expect(math.pow(256, 4), math.pow(2, 32));
    });

    test('moins que le nombre d’objets connectés aujourd’hui', () {
      const double adresses = 4294967296;
      const double objetsConnectes = 15e9; // ordre de grandeur courant
      expect(adresses, lessThan(objetsConnectes));
    });

    test('la latence aller-retour de six mille kilomètres', () {
      // La vitesse dans une fibre, verre compris : environ 200 000 km/s.
      double allerRetourMs(double km) => 2 * km / 200000 * 1000;
      expect(allerRetourMs(6000), closeTo(60, 1));
      expect(allerRetourMs(6000) / 2, closeTo(30, 0.5),
          reason: 'trente millisecondes à l’aller, la valeur du chapitre');
      // C'est bien la vitesse dans le verre, et non celle du vide : le
      // trajet simple à 300 000 km/s ne prendrait que vingt millisecondes.
      expect(6000 / 300000 * 1000, closeTo(20, 0.1));
      expect(allerRetourMs(6000) / 2, greaterThan(6000 / 300000 * 1000));
    });

    test('trente cookies de deux cents octets', () {
      expect(30 * 200, 6000);
      expect(6000 / 1000, 6, reason: 'six kilooctets');
    });
  });
}
