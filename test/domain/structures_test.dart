import 'dart:collection';
import 'dart:math' as math;

import 'package:eureka/design_system/figures/stack_queue_figure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les affirmations du chapitre sont exécutées, pas relues.
///
/// Un chapitre sur les structures de données est facile à écrire de travers
/// parce que tout y est évident une fois su : on intervertit LIFO et FIFO
/// dans une phrase et le texte reste lisible. Ces tests implémentent
/// réellement une pile, une file, le vérificateur de parenthèses et les
/// deux parcours, puis confrontent les résultats à ce que le chapitre
/// annonce. La propriété centrale — pile donne la profondeur, file donne la
/// largeur, le reste du code étant identique — est établie en faisant
/// tourner le même algorithme deux fois, avec la structure pour seule
/// différence.
void main() {
  group('Pile et file', () {
    test('les ordres de sortie annoncés par le cours', () {
      // q1 et q2 : 1, 2, 3 entrés dans l'une et l'autre.
      expect(StackQueueFigure.sortiePile(<int>[1, 2, 3]), <int>[3, 2, 1]);
      expect(StackQueueFigure.sortieFile(<int>[1, 2, 3]), <int>[1, 2, 3]);
    });

    test('confrontées à de vraies structures', () {
      // Les fonctions de la figure sont comparées à une pile et une file
      // réelles, nourries élément par élément. Si l'une des deux était
      // écrite à l'envers, la figure enseignerait le contraire du cours.
      final math.Random alea = math.Random(1789);
      for (int essai = 0; essai < 500; essai++) {
        final List<int> entrees = <int>[
          for (int i = 0; i < alea.nextInt(12); i++) alea.nextInt(100),
        ];

        final List<int> pile = <int>[];
        final Queue<int> file = Queue<int>();
        for (final int x in entrees) {
          pile.add(x);
          file.addLast(x);
        }
        final List<int> sortiePile = <int>[];
        final List<int> sortieFile = <int>[];
        while (pile.isNotEmpty) {
          sortiePile.add(pile.removeLast());
          sortieFile.add(file.removeFirst());
        }

        expect(sortiePile, StackQueueFigure.sortiePile(entrees));
        expect(sortieFile, StackQueueFigure.sortieFile(entrees));
      }
    });

    test('les deux ordres ne coïncident que sur les palindromes', () {
      // Le point que la figure doit éviter : montrer deux colonnes
      // identiques en croyant montrer une différence.
      expect(StackQueueFigure.memeOrdre(<int>[]), isTrue);
      expect(StackQueueFigure.memeOrdre(<int>[7]), isTrue);
      expect(StackQueueFigure.memeOrdre(<int>[1, 2]), isFalse);
      expect(StackQueueFigure.memeOrdre(<int>[1, 2, 1]), isTrue);
      expect(StackQueueFigure.memeOrdre(<int>[1, 2, 3]), isFalse);
      // Le contenu de départ de la figure diverge bien.
      expect(StackQueueFigure.memeOrdre(<int>[1, 2, 3]), isFalse);
    });

    test('la séquence de la question q5 laisse deux éléments', () {
      // empiler(5), empiler(8), dépiler(), empiler(2), empiler(9), dépiler()
      final List<int> pile = <int>[];
      pile.add(5);
      pile.add(8);
      expect(pile.removeLast(), 8);
      pile.add(2);
      pile.add(9);
      expect(pile.removeLast(), 9);
      expect(pile.length, 2);
      expect(pile, <int>[5, 2]);
    });

    test('une pile n\'expose que son sommet', () {
      // q4 : atteindre le troisième élément demande de retirer les deux
      // premiers. On le constate en comptant les retraits nécessaires.
      final List<int> pile = <int>[10, 20, 30, 40];
      int retraits = 0;
      while (pile.length > 2) {
        pile.removeLast();
        retraits++;
      }
      expect(retraits, 2);
      expect(pile.last, 20);
    });
  });

  group('Les arbres binaires', () {
    /// Nombre maximal de nœuds d'un arbre binaire de hauteur [h].
    ///
    /// Calculé en sommant les niveaux, pas par la formule : c'est la
    /// formule du cours qu'on veut vérifier.
    int maxNoeuds(int h) {
      int total = 0;
      for (int niveau = 0; niveau <= h; niveau++) {
        total += 1 << niveau;
      }
      return total;
    }

    test('la formule du cours est bien la somme des niveaux', () {
      for (int h = 0; h <= 25; h++) {
        expect(maxNoeuds(h), (1 << (h + 1)) - 1, reason: 'hauteur $h');
      }
    });

    test('les deux valeurs que les questions demandent', () {
      expect(maxNoeuds(3), 15); // q1
      expect(maxNoeuds(10), 2047); // q2
      // Et les ordres de grandeur annoncés par la carte « formule ».
      expect(maxNoeuds(10), greaterThan(2000));
      expect(maxNoeuds(20), greaterThan(1000000));
    });

    test('chaque niveau double', () {
      for (int niveau = 1; niveau <= 20; niveau++) {
        expect(1 << niveau, 2 * (1 << (niveau - 1)));
      }
    });
  });

  group('Le vérificateur de parenthèses', () {
    /// Vraie implémentation, avec une pile.
    bool equilibre(String expression) {
      const Map<String, String> paires = <String, String>{
        ')': '(',
        ']': '[',
        '}': '{',
      };
      final List<String> pile = <String>[];
      for (final String c in expression.split('')) {
        if (paires.containsValue(c)) {
          pile.add(c);
        } else if (paires.containsKey(c)) {
          if (pile.isEmpty || pile.removeLast() != paires[c]) return false;
        }
      }
      return pile.isEmpty;
    }

    /// Hauteur maximale atteinte par la pile.
    int hauteurMax(String expression) {
      int courant = 0;
      int max = 0;
      for (final String c in expression.split('')) {
        if (c == '(') {
          courant++;
          if (courant > max) max = courant;
        } else if (c == ')') {
          courant--;
        }
      }
      return max;
    }

    test('l\'expression du défi atteint une hauteur de 3', () {
      // q4 : ( ( ) ( ( ) ) )
      expect(hauteurMax('(()(())) '.trim()), 3);
      expect(equilibre('(()(()))'), isTrue);
    });

    test('équilibrées et déséquilibrées', () {
      for (final String bonne in <String>[
        '',
        '()',
        '(())',
        '()()',
        '(()(()))',
        '([]{})',
        '{[()]}',
      ]) {
        expect(equilibre(bonne), isTrue, reason: bonne);
      }
      for (final String mauvaise in <String>[
        '(',
        ')',
        '(()',
        '())',
        ')(',
        '([)]',
        '{[(])}',
      ]) {
        expect(equilibre(mauvaise), isFalse, reason: mauvaise);
      }
    });

    test('la pile vide à la fin est bien le critère', () {
      // L'algorithme du cours tient en « empiler, dépiler, pile vide ».
      // On vérifie que les deux conditions sont nécessaires : une
      // fermante en trop échoue au dépilement, une ouvrante en trop
      // échoue au test final.
      expect(equilibre('())'), isFalse, reason: 'dépilement sur pile vide');
      expect(equilibre('(()'), isFalse, reason: 'pile non vide à la fin');
    });
  });

  group('Les deux parcours', () {
    // Un petit graphe : 0 au centre, puis deux couches. Les distances en
    // nombre d'arêtes sont connues, ce qui permet de vérifier que la
    // largeur les respecte et que la profondeur ne les respecte pas.
    final Map<int, List<int>> voisins = <int, List<int>>{
      0: <int>[1, 2],
      1: <int>[0, 3],
      2: <int>[0, 4],
      3: <int>[1, 5],
      4: <int>[2, 5],
      5: <int>[3, 4],
    };

    /// Le même algorithme, deux structures. `enLargeur` choisit la file.
    ///
    /// C'est le fait que la carte « à retenir » annonce : seule la
    /// structure change. Le test l'établit en n'écrivant qu'une fonction.
    List<int> parcourir(int depart, {required bool enLargeur}) {
      final List<int> aVoir = <int>[depart];
      final Set<int> vus = <int>{depart};
      final List<int> ordre = <int>[];
      while (aVoir.isNotEmpty) {
        final int courant =
            enLargeur ? aVoir.removeAt(0) : aVoir.removeLast();
        ordre.add(courant);
        for (final int v in voisins[courant]!) {
          if (vus.add(v)) aVoir.add(v);
        }
      }
      return ordre;
    }

    test('les deux parcours visitent tous les sommets', () {
      for (final bool largeur in <bool>[true, false]) {
        final List<int> ordre = parcourir(0, enLargeur: largeur);
        expect(ordre.toSet(), voisins.keys.toSet());
        expect(ordre.length, voisins.length, reason: 'aucun doublon');
      }
    });

    test('mais pas dans le même ordre', () {
      expect(
        parcourir(0, enLargeur: true),
        isNot(parcourir(0, enLargeur: false)),
      );
    });

    test('la largeur respecte les distances, la profondeur non', () {
      // Les distances depuis 0, calculées indépendamment.
      final Map<int, int> distance = <int, int>{
        0: 0,
        1: 1,
        2: 1,
        3: 2,
        4: 2,
        5: 3,
      };

      final List<int> largeur = parcourir(0, enLargeur: true);
      for (int i = 1; i < largeur.length; i++) {
        expect(
          distance[largeur[i]]!,
          greaterThanOrEqualTo(distance[largeur[i - 1]]!),
          reason: 'la largeur doit visiter par distance croissante',
        );
      }

      // La profondeur, elle, ne respecte pas cet ordre : elle s'enfonce
      // jusqu'au bout puis revient sur ses pas, ce qui la fait repasser
      // par des sommets plus proches après en avoir visité de lointains.
      // On cherche cette redescente au lieu de parier sur un sommet
      // particulier — l'ordre exact dépend de celui des listes de voisins.
      final List<int> profondeur = parcourir(0, enLargeur: false);
      int redescentes = 0;
      for (int i = 1; i < profondeur.length; i++) {
        if (distance[profondeur[i]]! < distance[profondeur[i - 1]]!) {
          redescentes++;
        }
      }
      expect(
        redescentes,
        greaterThan(0),
        reason: 'parcours obtenu : $profondeur',
      );
      // Et la largeur, elle, n'en fait aucune : c'est tout l'écart.
      int redescentesLargeur = 0;
      for (int i = 1; i < largeur.length; i++) {
        if (distance[largeur[i]]! < distance[largeur[i - 1]]!) {
          redescentesLargeur++;
        }
      }
      expect(redescentesLargeur, 0);
    });

    test('la largeur trouve le plus court chemin en étapes', () {
      // q4 du cours et q2 du défi. On compare le premier chemin trouvé par
      // chaque parcours vers le sommet 5.
      int etapesLargeur(int cible) {
        final Queue<(int, int)> file = Queue<(int, int)>()..add((0, 0));
        final Set<int> vus = <int>{0};
        while (file.isNotEmpty) {
          final (int sommet, int pas) = file.removeFirst();
          if (sommet == cible) return pas;
          for (final int v in voisins[sommet]!) {
            if (vus.add(v)) file.addLast((v, pas + 1));
          }
        }
        return -1;
      }

      expect(etapesLargeur(5), 3);
      expect(etapesLargeur(3), 2);
      expect(etapesLargeur(1), 1);
      expect(etapesLargeur(0), 0);
    });
  });

  group('Les coûts comparés', () {
    test('chercher dans une liste coûte jusqu\'à n comparaisons', () {
      // q2 du cours sur les dictionnaires : 10 000 au pire.
      final List<int> liste = List<int>.generate(10000, (int i) => i);
      int comparaisons = 0;
      for (final int x in liste) {
        comparaisons++;
        if (x == 9999) break;
      }
      expect(comparaisons, 10000);

      // Et pour un absent, c'est le même parcours complet.
      comparaisons = 0;
      for (final int x in liste) {
        comparaisons++;
        if (x == -1) break;
      }
      expect(comparaisons, 10000);
    });

    test('compter des mots : la liste coûte le carré du vocabulaire', () {
      // L'affirmation de la carte « compter des mots » et de q4. On compte
      // les comparaisons réelles des deux approches sur le même texte.
      final List<String> texte = <String>[
        for (int i = 0; i < 400; i++) 'mot${i % 60}',
      ];

      int comparaisonsListe = 0;
      final List<String> vus = <String>[];
      for (final String mot in texte) {
        bool trouve = false;
        for (final String v in vus) {
          comparaisonsListe++;
          if (v == mot) {
            trouve = true;
            break;
          }
        }
        if (!trouve) vus.add(mot);
      }

      final Map<String, int> compteur = <String, int>{};
      for (final String mot in texte) {
        compteur[mot] = (compteur[mot] ?? 0) + 1;
      }

      expect(compteur.length, 60);
      expect(vus.length, 60);
      // Le dictionnaire fait un accès par mot : 400. La liste en fait
      // beaucoup plus, et l'écart se creuse avec le vocabulaire.
      expect(comparaisonsListe, greaterThan(10 * texte.length));
    });
  });
}
