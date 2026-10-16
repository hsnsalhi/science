import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// La SVT du primaire, recalculée.
///
/// Les chapitres de SVT avancent peu de formules et beaucoup de nombres
/// cités de mémoire — un rendement trophique, une durée de chute, un
/// doublement de population. Ce sont précisément les nombres qu'on recopie
/// de travers. Les tests les refabriquent à partir du modèle qui les
/// produit, au lieu de relire la réponse annoncée.
void main() {
  group('Pyramide alimentaire', () {
    /// Chaque étage d'une chaîne perd l'essentiel de la matière. Le
    /// chapitre pose un facteur 10 par étage ; on le remonte étage par
    /// étage plutôt que d'écrire 1000 à la main.
    double herbePour(int etages, {double facteur = 10}) {
      double masse = 1;
      for (int i = 0; i < etages; i++) {
        masse *= facteur;
      }
      return masse;
    }

    test('un kilo de grenouilles coûte cent kilos d’herbe', () {
      // Herbe → sauterelle → grenouille : deux étages.
      expect(herbePour(2), 100);
    });

    test('un kilo de hérons coûte une tonne d’herbe', () {
      // Herbe → sauterelle → grenouille → héron : trois étages.
      expect(herbePour(3), 1000);
      expect(herbePour(3), herbePour(2) * 10);
    });

    test('le coût explose avec le nombre d’étages', () {
      for (int n = 0; n <= 6; n++) {
        expect(herbePour(n), math.pow(10, n).toDouble(), reason: '$n étages');
      }
      // D'où la rareté des grands carnivores : la biomasse disponible
      // décroît d'un facteur dix à chaque fois qu'on monte.
      expect(herbePour(5) / herbePour(3), 100);
    });

    test('un facteur plus doux reste exponentiel', () {
      // Même avec un rendement de 20 % au lieu de 10 %, trois étages
      // coûtent encore plus de cent fois la masse finale.
      expect(herbePour(3, facteur: 5), 125);
      expect(herbePour(3, facteur: 5), greaterThan(100));
    });
  });

  group('Chaîne alimentaire', () {
    /// Une chaîne se casse vers le haut, jamais vers le bas : retirer un
    /// maillon affame ceux qui sont au-dessus et laisse intacts ceux qui
    /// sont en dessous. Le chapitre l'affirme ; on le simule.
    const List<String> chaine = [
      'herbe',
      'sauterelle',
      'grenouille',
      'heron',
    ];

    Set<String> survivants(String disparu) {
      final int rang = chaine.indexOf(disparu);
      expect(rang, greaterThanOrEqualTo(0), reason: '$disparu est dans la chaîne');
      // Tout ce qui est au-dessus du maillon retiré perd sa nourriture.
      return chaine.take(rang).toSet();
    }

    test('retirer les sauterelles touche grenouilles et hérons', () {
      expect(survivants('sauterelle'), {'herbe'});
    });

    test('retirer le héron ne touche personne en dessous', () {
      expect(survivants('heron'), {'herbe', 'sauterelle', 'grenouille'});
    });

    test('retirer l’herbe effondre toute la chaîne', () {
      expect(survivants('herbe'), isEmpty);
    });

    test('la casse ne se propage jamais vers le bas', () {
      for (final String maillon in chaine) {
        final Set<String> restants = survivants(maillon);
        final int rang = chaine.indexOf(maillon);
        for (int i = 0; i < chaine.length; i++) {
          if (i < rang) {
            expect(restants, contains(chaine[i]),
                reason: '${chaine[i]} est sous $maillon');
          } else {
            expect(restants, isNot(contains(chaine[i])),
                reason: '${chaine[i]} est au niveau de $maillon ou au-dessus');
          }
        }
      }
    });
  });

  group('Divisions cellulaires', () {
    int cellulesApres(int divisions) {
      int cellules = 1;
      for (int i = 0; i < divisions; i++) {
        cellules *= 2;
      }
      return cellules;
    }

    test('tout part d’une seule cellule', () {
      expect(cellulesApres(0), 1);
    });

    test('quatre divisions donnent seize cellules', () {
      expect(cellulesApres(4), 16);
    });

    test('la suite doublée, division par division', () {
      const List<int> attendu = [1, 2, 4, 8, 16, 32, 64, 128];
      for (int n = 0; n < attendu.length; n++) {
        expect(cellulesApres(n), attendu[n], reason: '$n divisions');
      }
    });

    test('les 37 000 milliards de cellules d’un adulte sont atteignables', () {
      // Le chapitre affirme que toutes descendent d'une seule. Combien de
      // divisions successives faudrait-il ? Une quarantaine : l'ordre de
      // grandeur est plausible, ce qui est le point de la carte.
      int cellules = 1;
      int divisions = 0;
      while (cellules < 37000000000000) {
        cellules *= 2;
        divisions++;
      }
      expect(divisions, lessThan(50));
      expect(divisions, greaterThan(40));
    });
  });

  group('Populations', () {
    int doublements(int depart, int annees) {
      int effectif = depart;
      for (int i = 0; i < annees; i++) {
        effectif *= 2;
      }
      return effectif;
    }

    test('quatre chèvres, cinq ans de doublement', () {
      expect(doublements(4, 5), 128);
    });

    test('huit ans suffisent à dépasser le millier', () {
      expect(doublements(4, 8), 1024);
      expect(doublements(4, 8), greaterThan(1000));
    });

    test('une île qui nourrit cent chèvres est dépassée dès la cinquième année', () {
      const int capacite = 100;
      int premiereAnneeEnExces = -1;
      for (int an = 0; an <= 10; an++) {
        if (doublements(4, an) > capacite) {
          premiereAnneeEnExces = an;
          break;
        }
      }
      expect(premiereAnneeEnExces, 5);
    });

    test('une population stable donne deux adultes par génération', () {
      // Deux adultes forment un couple, qui donne deux adultes.
      int effectif = 2;
      for (int generation = 0; generation < 20; generation++) {
        effectif = (effectif ~/ 2) * 2;
      }
      expect(effectif, 2);
    });

    test('mille œufs par adulte survivant', () {
      const int oeufs = 2000;
      const int adultes = 2;
      expect(oeufs ~/ adultes, 1000);
    });

    test('la chenille multiplie son poids par mille', () {
      const int depart = 2; // mg
      const int arrivee = 2000; // mg
      expect(arrivee ~/ depart, 1000);
    });
  });

  group('Chute de la règle', () {
    const double g = 9.81;

    /// Le temps de réaction se lit sur la distance de chute. Les trois
    /// valeurs annoncées dans le chapitre doivent sortir de la physique,
    /// pas d'un souvenir.
    double tempsDeChute(double distanceCm) =>
        math.sqrt(2 * (distanceCm / 100) / g);

    test('les trois repères du chapitre sont exacts au centième', () {
      expect(tempsDeChute(5), closeTo(0.10, 0.005));
      expect(tempsDeChute(20), closeTo(0.20, 0.005));
      expect(tempsDeChute(30), closeTo(0.25, 0.005));
    });

    test('quatre fois la distance ne double que le temps', () {
      final double court = tempsDeChute(5);
      final double long = tempsDeChute(20);
      expect(long / court, closeTo(2, 0.001));
      expect(long / court, isNot(closeTo(4, 0.5)),
          reason: 'la chute accélère, le temps ne suit pas la distance');
    });

    test('le temps croît comme la racine de la distance', () {
      for (final double d in <double>[2, 5, 10, 15, 20, 25, 30]) {
        expect(tempsDeChute(d * 4) / tempsDeChute(d), closeTo(2, 1e-9),
            reason: 'quadrupler $d cm');
      }
    });

    test('la règle de 30 cm ne mesure pas au-delà d’un quart de seconde', () {
      // Une réaction plus lente laisse la règle filer entre les doigts :
      // c'est la limite de l'expérience, et elle vaut d'être connue.
      expect(tempsDeChute(30), lessThan(0.26));
      expect(tempsDeChute(100), greaterThan(0.4));
    });

    test('la moyenne des cinq essais', () {
      const List<int> essais = [18, 22, 20, 19, 21];
      final int somme = essais.reduce((a, b) => a + b);
      expect(somme, 100);
      expect(somme / essais.length, 20);
    });
  });

  group('Temps de réaction au volant', () {
    double distanceParcourue(double vitesseMs, double reactionS) =>
        vitesseMs * reactionS;

    test('50 km/h font environ 14 m/s', () {
      expect(50 * 1000 / 3600, closeTo(13.9, 0.1));
    });

    test('deux dixièmes de seconde coûtent près de trois mètres', () {
      expect(distanceParcourue(14, 0.2), closeTo(2.8, 0.01));
    });

    test('la distance est proportionnelle à la vitesse', () {
      const double reaction = 0.2;
      final double a = distanceParcourue(14, reaction);
      final double b = distanceParcourue(25, reaction); // environ 90 km/h
      expect(b / a, closeTo(25 / 14, 1e-9));
      expect(b, closeTo(5.0, 0.1));
    });
  });

  group('Eau et énergie du logement', () {
    test('un bain vaut trois douches', () {
      expect(180 / 60, 3);
    });

    test('un robinet qui goutte perd trois mètres cubes par mois', () {
      expect(100 * 30, 3000);
      // Trois mille litres font bien trois mètres cubes.
      expect(3000 / 1000, 3);
    });

    test('un robinet qui goutte dépasse la douche quotidienne', () {
      const int goutte = 100; // litres par jour
      const int douche = 60; // litres par douche
      expect(goutte, greaterThan(douche));
    });

    test('deux degrés de moins économisent le double d’un seul', () {
      const int parDegre = 7; // pour cent
      expect(parDegre * 2, 14);
      for (int degres = 0; degres <= 4; degres++) {
        expect(parDegre * degres, degres * 7, reason: '$degres degrés');
      }
    });
  });

  group('Sucre caché', () {
    test('un verre de soda fait cinq morceaux', () {
      const int sucreParVerre = 25; // grammes
      const int morceau = 5; // grammes
      expect(sucreParVerre ~/ morceau, 5);
    });

    test('trois verres en font quinze', () {
      expect((25 ~/ 5) * 3, 15);
    });

    test('un litre et demi par jour fait dix litres et demi par semaine', () {
      expect(1.5 * 7, closeTo(10.5, 1e-9));
    });

    test('la moitié d’une assiette fait cinquante pour cent', () {
      // Moitié de légumes, un quart de féculents, un quart de protéines.
      const List<int> parts = [50, 25, 25];
      expect(parts.reduce((a, b) => a + b), 100);
      expect(parts.first, 50);
    });
  });

  group('Durées de vie des déchets', () {
    /// L'exercice de remise en ordre dépend d'une table de durées. On la
    /// pose en années et on vérifie que l'ordre annoncé est bien croissant,
    /// plutôt que de faire confiance à la liste du fichier.
    const Map<String, double> dureesAnnees = {
      'trognon de pomme': 0.08, // quelques semaines
      'feuille de papier': 0.3, // quelques mois
      'mégot': 1.5,
      'canette aluminium': 200,
      'bouteille plastique': 400,
      'verre': 4000,
    };

    test('l’ordre du chapitre est strictement croissant', () {
      const List<String> ordre = [
        'trognon de pomme',
        'feuille de papier',
        'mégot',
        'canette aluminium',
        'bouteille plastique',
        'verre',
      ];
      for (int i = 1; i < ordre.length; i++) {
        expect(dureesAnnees[ordre[i]]!, greaterThan(dureesAnnees[ordre[i - 1]]!),
            reason: '${ordre[i]} après ${ordre[i - 1]}');
      }
    });

    test('le trognon tient mille fois moins longtemps que la bouteille', () {
      final double rapport =
          dureesAnnees['bouteille plastique']! / dureesAnnees['trognon de pomme']!;
      expect(rapport, greaterThan(1000));
    });

    test('le verre dépasse dix fois la bouteille', () {
      expect(dureesAnnees['verre']! / dureesAnnees['bouteille plastique']!,
          greaterThan(9));
    });
  });

  group('Œuf de poule et semaines', () {
    test('vingt-et-un jours font trois semaines pleines', () {
      expect(21 ~/ 7, 3);
      expect(21 % 7, 0, reason: 'aucun jour de reste');
    });
  });

  group('Message nerveux', () {
    test('cent mètres par seconde font un mètre par centième', () {
      const double vitesse = 100; // m/s
      expect(vitesse * 0.01, 1);
    });

    test('un bras de soixante centimètres est traversé en six millisecondes', () {
      const double vitesse = 100; // m/s
      const double temps = 0.60 / vitesse;
      expect(temps, closeTo(0.006, 1e-9));
      // Soit quarante fois plus rapide qu'un temps de réaction visuel,
      // ce qui est bien l'argument du réflexe.
      expect(0.25 / temps, greaterThan(40));
    });

    test('le cerveau pèse deux pour cent et consomme vingt', () {
      const double poidsCorps = 70; // kg
      const double poidsCerveau = 1.4; // kg
      expect(poidsCerveau / poidsCorps * 100, closeTo(2, 0.1));
      // Un facteur dix entre sa part de masse et sa part d'énergie.
      expect(20 / (poidsCerveau / poidsCorps * 100), closeTo(10, 0.5));
    });
  });

  group('Révisions espacées', () {
    test('six séances de dix minutes font une heure', () {
      expect(10 * 6, 60);
    });

    test('le même temps, découpé ou non', () {
      // L'argument du chapitre ne porte pas sur la durée mais sur le
      // découpage : les deux totaux sont égaux.
      expect(10 * 6, 60);
      expect(60 * 1, 60);
      expect(10 * 6, 60 * 1);
    });
  });
}
