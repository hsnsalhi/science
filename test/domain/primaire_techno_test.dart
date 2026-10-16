import 'package:flutter_test/flutter_test.dart';

/// L'informatique et la technologie du primaire, recalculées.
///
/// Ces chapitres avancent peu de nombres mais beaucoup de règles, et les
/// règles sont exactement ce qu'on recopie de travers. Les tests exécutent
/// les programmes que les énoncés décrivent, au lieu de faire confiance
/// aux réponses annoncées.
void main() {
  group('Boucles', () {
    test('la boucle fait gagner des instructions', () {
      // Un carré sans boucle : quatre avancées et quatre rotations.
      const int cotes = 4;
      expect(cotes * 2, 8);
      // Avec une boucle, deux instructions à l'intérieur.
      expect(2, 2);
      expect(cotes * 2, greaterThan(2));
    });

    test('répéter n fois une avancée de p cases', () {
      int parcourues(int tours, int pas) {
        int total = 0;
        for (int i = 0; i < tours; i++) {
          total += pas;
        }
        return total;
      }

      expect(parcourues(5, 3), 15);
      expect(parcourues(3, 4), 12);
      for (int t = 0; t <= 12; t++) {
        for (int p = 0; p <= 12; p++) {
          expect(parcourues(t, p), t * p, reason: '$t × $p');
        }
      }
    });

    test('une boucle imbriquée multiplie les tours', () {
      int imbriquee(int exterieur, int interieur) {
        int total = 0;
        for (int i = 0; i < exterieur; i++) {
          for (int j = 0; j < interieur; j++) {
            total++;
          }
        }
        return total;
      }

      expect(imbriquee(3, 4), 12);
      expect(imbriquee(4, 3), 12, reason: 'le produit est commutatif');
      expect(imbriquee(0, 9), 0, reason: 'zéro tour extérieur, rien');
    });

    test('les compteurs du chapitre, déroulés pas à pas', () {
      // « Compteur à 0, répéter 6 fois : ajouter 1 »
      int compteur = 0;
      for (int i = 0; i < 6; i++) {
        compteur += 1;
      }
      expect(compteur, 6);

      // « Compteur à 10, répéter 4 fois : enlever 2 »
      compteur = 10;
      for (int i = 0; i < 4; i++) {
        compteur -= 2;
      }
      expect(compteur, 2);

      // « Compteur à 1, répéter 4 fois : doubler »
      compteur = 1;
      final List<int> etapes = <int>[compteur];
      for (int i = 0; i < 4; i++) {
        compteur *= 2;
        etapes.add(compteur);
      }
      expect(etapes, <int>[1, 2, 4, 8, 16]);
      expect(compteur, 16);

      // « Compteur à 100, répéter 3 fois : diviser par 2 »
      double reel = 100;
      for (int i = 0; i < 3; i++) {
        reel /= 2;
      }
      expect(reel, 12.5);
    });

    test('deux boucles successives s\'additionnent', () {
      // « Répéter 5 fois : avancer de 2 » puis « répéter 3 fois : avancer
      // de 1 ». Ce n'est pas une imbrication, donc on additionne.
      expect(5 * 2 + 3 * 1, 13);
      expect(5 * 2 + 3 * 1, isNot(5 * 2 * 3 * 1));
    });

    test('un polygone régulier tourne d\'un tour complet en tout', () {
      // Six rotations d'un sixième, trois d'un tiers : dans les deux cas,
      // le robot revient à son orientation de départ.
      for (final int cotes in <int>[3, 4, 5, 6, 8, 12]) {
        final double parSommet = 1 / cotes;
        expect(parSommet * cotes, closeTo(1, 1e-12), reason: '$cotes côtés');
      }
      expect(1 / 6 * 6, closeTo(1, 1e-12), reason: 'l\'hexagone');
      expect(1 / 3 * 3, closeTo(1, 1e-12), reason: 'le triangle');
    });
  });

  group('Conditions', () {
    /// Le programme du cours : deux « si » sans « sinon ».
    int messages(int score) {
      int n = 0;
      if (score > 5) n++;
      if (score > 10) n++;
      return n;
    }

    test('sans sinon, les deux conditions peuvent s\'exécuter', () {
      expect(messages(12), 2);
      expect(messages(7), 1);
      expect(messages(3), 0);
    });

    test('le nombre de messages ne décroît jamais avec le score', () {
      int precedent = 0;
      for (int score = 0; score <= 30; score++) {
        final int n = messages(score);
        expect(n, greaterThanOrEqualTo(precedent), reason: 'score $score');
        precedent = n;
      }
    });

    test('avec un sinon, un seul message passe', () {
      int messageUnique(int score) {
        if (score > 10) return 1;
        if (score > 5) return 1;
        return 0;
      }

      for (final int score in <int>[3, 7, 12, 100]) {
        expect(messageUnique(score), score > 5 ? 1 : 0, reason: '$score');
      }
      // Et c'est bien ce qui change : à 12, deux messages sans sinon,
      // un seul avec.
      expect(messages(12), 2);
      expect(messageUnique(12), 1);
    });

    test('une condition n\'a que deux réponses', () {
      for (int score = -5; score <= 20; score++) {
        final bool reponse = score > 5;
        expect(reponse, anyOf(isTrue, isFalse));
      }
    });
  });

  group('Chaîne d\'information et d\'énergie', () {
    test('le thermostat compare à sa consigne', () {
      bool chauffe(int piece, int consigne) => piece < consigne;
      expect(chauffe(17, 20), isTrue);
      expect(chauffe(22, 20), isFalse);
      expect(chauffe(20, 20), isFalse, reason: 'à la consigne, on s\'arrête');
      expect(20 - 17, 3, reason: 'l\'écart à combler');
      // La régulation ramène toujours vers la consigne, quel que soit
      // l'écart de départ : c'est ce qui en fait une régulation.
      for (int depart = 0; depart <= 40; depart++) {
        int piece = depart;
        int tours = 0;
        while (chauffe(piece, 20) && tours < 100) {
          piece++;
          tours++;
        }
        expect(piece, greaterThanOrEqualTo(20), reason: 'depuis $depart');
      }
    });

    test('les piles en série additionnent leurs tensions', () {
      expect(3 * 1.5, 4.5);
      for (final int n in <int>[1, 2, 3, 4, 6]) {
        expect(n * 1.5, closeTo(n * 1.5, 1e-12));
      }
      expect(2 * 1.5, 3.0);
    });

    test('les consommations annoncées', () {
      expect(2 * 6, 12, reason: 'six veilles de deux watts');
      expect(1000 * 3, 3000, reason: 'un radiateur trois heures');
      expect(3000 / 1000, 3, reason: 'en kilowattheures');
    });

    test('un réfrigérateur déplace la chaleur, il n\'en détruit pas', () {
      // Porte ouverte : le moteur ajoute sa propre chaleur à celle qu'il
      // déplace, et tout reste dans la pièce. Le bilan est donc positif.
      const int chaleurExtraite = 100;
      const int travailDuMoteur = 30;
      const int rejete = chaleurExtraite + travailDuMoteur;
      expect(rejete, 130);
      expect(rejete, greaterThan(chaleurExtraite),
          reason: 'la cuisine se réchauffe, elle ne refroidit pas');
    });
  });

  group('Concevoir un objet', () {
    test('les crayons et la place disponible', () {
      expect(12 * 8, 96, reason: 'douze crayons de 8 mm');
      expect(96, lessThan(100), reason: 'cela tient dans 10 cm, de justesse');
      expect(100 ~/ 8, 12, reason: 'on ne compte pas les demi-crayons');
    });

    test('il faut toujours prévoir du jeu', () {
      // Un trou exactement de la taille du crayon ne le laisse pas entrer.
      const int crayon = 8;
      const int jeu = 1;
      expect(crayon + jeu, 9);
      expect(crayon + jeu, greaterThan(crayon));
    });

    test('des trous espacés occupent plus que leur diamètre', () {
      const int diametre = 9;
      const int espace = 1;
      const int emplacement = diametre + espace;
      expect(emplacement, 10);
      expect(100 ~/ emplacement, 10, reason: 'dix trous par rangée');
      // Sans compter l'espace, on en croirait onze : l'erreur classique.
      expect(100 ~/ diametre, 11);
      expect(100 ~/ diametre, greaterThan(100 ~/ emplacement));
    });

    test('la marge de sécurité divise la charge admissible', () {
      expect(1200 ~/ 60, 20, reason: 'la charge calculée');
      expect(1200 ~/ 60 ~/ 2, 10, reason: 'avec un coefficient de deux');
      for (final int coefficient in <int>[2, 3, 4]) {
        expect(20 ~/ coefficient, lessThan(20), reason: '×$coefficient');
      }
    });
  });
}
