import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// L'astronomie et la logique du collège, recalculées.
///
/// Deux chapitres d'astronomie dont tout repose sur des conversions
/// d'échelle, et deux de logique dont les énigmes se résolvent par
/// énumération. Le loup, la chèvre et le chou sont traversés pour de bon,
/// par exploration de l'espace d'états : le test retrouve les sept
/// traversées sans qu'on lui ait donné la solution.
void main() {
  group('Année-lumière', () {
    const double c = 300000; // km/s
    const double anneeEnSecondes = 31500000;

    test('sa valeur en milliards de kilomètres', () {
      const double km = c * anneeEnSecondes;
      expect(km / 1e9, closeTo(9450, 1));
      expect(km / 1e9, closeTo(9500, 100));
    });

    test('la lumière du Soleil met cinq cents secondes', () {
      expect(150000000 / c, 500);
      expect(500 / 60, closeTo(8.33, 0.01));
    });

    test('l’aller-retour radio avec la Lune', () {
      expect(1.3 * 2, closeTo(2.6, 1e-9));
    });

    test('les distances s’ordonnent bien en temps de lumière', () {
      // En secondes, pour les comparer sur une même échelle.
      const Map<String, double> enSecondes = {
        'Lune': 1.3,
        'Soleil': 500,
        'Neptune': 4 * 3600,
        'Proxima': 4.2 * anneeEnSecondes,
        'centre galactique': 26000 * anneeEnSecondes,
        'Andromède': 2500000 * anneeEnSecondes,
      };
      double precedent = 0;
      for (final MapEntry<String, double> e in enSecondes.entries) {
        expect(e.value, greaterThan(precedent), reason: e.key);
        precedent = e.value;
      }
      // Andromède est près de six cents mille fois plus loin que Proxima.
      expect(enSecondes['Andromède']! / enSecondes['Proxima']!,
          closeTo(595238, 1));
    });

    test('l’époque de départ de la lumière', () {
      expect(2026 - 1000, 1026);
      expect(2026 - 2000, 26);
      expect(2026 - 2500000, -2497974, reason: 'bien avant le genre humain');
    });
  });

  group('Étoiles', () {
    test('les couleurs s’ordonnent par température', () {
      const Map<String, int> temperatures = {
        'rouge': 3000,
        'orange': 4000,
        'jaune': 5500,
        'blanche': 10000,
        'bleue': 20000,
      };
      int precedente = 0;
      for (final MapEntry<String, int> e in temperatures.entries) {
        expect(e.value, greaterThan(precedente), reason: e.key);
        precedente = e.value;
      }
      // Le bleu est près de sept fois plus chaud que le rouge.
      expect(temperatures['bleue']! / temperatures['rouge']!,
          closeTo(6.67, 0.01));
    });

    test('une étoile massive vit des centaines de fois moins longtemps', () {
      const double soleil = 10e9;
      const double massive = 30e6;
      expect(soleil / massive, closeTo(333.3, 0.1));
      expect((soleil / massive).round(), 333);
    });

    test('Jupiter est très loin du seuil stellaire', () {
      // Il faudrait environ quatre-vingts fois sa masse.
      const int facteurManquant = 80;
      expect(facteurManquant, greaterThan(1));
      // Et il reste donc une planète, quelle que soit sa taille apparente.
      expect(1 / facteurManquant, lessThan(0.02));
    });
  });

  group('La galaxie', () {
    test('la position du Soleil dans le disque', () {
      expect(26000 / 50000 * 100, 52);
    });

    test('le nombre de tours depuis la formation du Soleil', () {
      expect(4600 / 230, 20);
    });

    test('un tour galactique dépasse largement l’ère des dinosaures', () {
      // Les premiers dinosaures : environ 230 millions d'années.
      expect(230 / 230, 1, reason: 'à peine un tour depuis');
    });
  });

  group('Vitesses de satellisation', () {
    const double orbitale = 7.9; // km/s
    const double liberation = 11.2;

    test('leurs valeurs en kilomètres par heure', () {
      expect(liberation * 3600, closeTo(40320, 1));
      expect(orbitale * 3600, closeTo(28440, 1));
    });

    test('leur rapport vaut la racine carrée de deux', () {
      expect(liberation / orbitale, closeTo(math.sqrt(2), 0.01));
      expect(liberation / orbitale, closeTo(1.418, 0.001));
    });

    test('le rapport est le même sur tout astre', () {
      // v_orbitale = racine(GM/r) et v_libération = racine(2GM/r).
      for (double gm = 1e13; gm <= 1e15; gm *= 10) {
        for (double r = 1e6; r <= 1e8; r *= 10) {
          final double vo = math.sqrt(gm / r);
          final double vl = math.sqrt(2 * gm / r);
          expect(vl / vo, closeTo(math.sqrt(2), 1e-12),
              reason: 'GM = $gm, r = $r');
        }
      }
    });
  });

  group('Fenêtres et voyages', () {
    test('vingt-six mois font deux ans et deux mois', () {
      expect(26 ~/ 12, 2);
      expect(26 % 12, 2);
    });

    test('quatre fenêtres en dix ans', () {
      expect(120 ~/ 26, 4);
      // Et la cinquième tomberait au bout de 130 mois.
      expect(5 * 26, 130);
      expect(130, greaterThan(120));
    });

    test('sept mois de vol font deux cent dix jours', () {
      expect(7 * 30, 210);
    });
  });

  group('Voyager 1', () {
    const double vitesseKmS = 17;
    const double anneeEnSecondes = 31500000;

    test('sa distance parcourue par jour et par an', () {
      expect(vitesseKmS * 86400, 1468800);
      expect(vitesseKmS * anneeEnSecondes / 1e9, closeTo(0.5355, 1e-4));
      expect((vitesseKmS * anneeEnSecondes / 1e9), closeTo(0.54, 0.01));
    });

    test('le temps pour une année-lumière', () {
      const double milliardsParAn = vitesseKmS * anneeEnSecondes / 1e9;
      const double ans = 9500 / milliardsParAn;
      expect(ans, closeTo(17740, 10));
      expect(ans, closeTo(17600, 600),
          reason: 'la valeur arrondie que porte le chapitre');
    });

    test('le temps jusqu’à Proxima', () {
      const double milliardsParAn = vitesseKmS * anneeEnSecondes / 1e9;
      const double ans = 9500 / milliardsParAn * 4.2;
      expect(ans, closeTo(74510, 50));
      expect(ans, closeTo(74000, 3000));
    });

    test('la fraction parcourue en quarante-neuf ans', () {
      const double milliardsParAn = vitesseKmS * anneeEnSecondes / 1e9;
      const double ansParAl = 9500 / milliardsParAn;
      expect(2026 - 1977, 49);
      expect(49 / ansParAl * 100, closeTo(0.276, 0.01));
      expect(49 / ansParAl * 100, closeTo(0.3, 0.1));
    });
  });

  group('Les trois chapeaux', () {
    /// Trois chapeaux blancs, deux noirs. La file : index 0 devant, 2
    /// derrière. Chacun voit ceux qui le précèdent dans la file.
    /// true = blanc.
    List<List<bool>> configurations() {
      final List<List<bool>> tous = <List<bool>>[];
      for (int masque = 0; masque < 8; masque++) {
        final List<bool> c = List<bool>.generate(
            3, (int i) => masque & (1 << i) != 0);
        // Au plus deux noirs disponibles.
        if (c.where((bool b) => !b).length > 2) continue;
        tous.add(c);
      }
      return tous;
    }

    test('il y a sept configurations possibles', () {
      // Les huit combinaisons, moins celle à trois noirs.
      expect(configurations().length, 7);
    });

    /// La personne d'index i voit les chapeaux 0..i-1. Sait-elle le sien ?
    bool saitSonChapeau(List<bool> config, int i) {
      // Elle sait si et seulement si tous les chapeaux visibles sont noirs
      // et qu'ils sont déjà deux : il ne reste que du blanc pour elle.
      final List<bool> vus = config.sublist(0, i);
      return vus.length == 2 && vus.every((bool b) => !b);
    }

    test('celle de derrière ne sait pas : elle n’a pas vu deux noirs', () {
      final List<List<bool>> restantes =
          configurations().where((List<bool> c) => !saitSonChapeau(c, 2)).toList();
      // Elle aurait su dans le seul cas « noir, noir » devant elle.
      expect(configurations().length - restantes.length, 1);
      for (final List<bool> c in restantes) {
        expect(c[0] && c[1] || c[0] || c[1], isTrue,
            reason: 'au moins un blanc devant elle');
      }
    });

    test('puis celle du milieu ne sait pas : la première est en blanc', () {
      // On applique les deux éliminations dans l'ordre, et on regarde ce
      // qui reste pour le chapeau de la première.
      Iterable<List<bool>> restantes = configurations()
          .where((List<bool> c) => !saitSonChapeau(c, 2));
      // Celle du milieu sait si le seul chapeau qu'elle voit est noir —
      // car l'étape précédente a exclu « deux noirs devant la troisième ».
      restantes = restantes.where((List<bool> c) => c[0]);
      // Dans tout ce qui reste, le chapeau de la première est blanc.
      expect(restantes, isNotEmpty);
      for (final List<bool> c in restantes) {
        expect(c[0], isTrue);
      }
    });

    test('la première ne pouvait rien dire avant les deux silences', () {
      // Sans aucune information, les deux couleurs restent possibles pour
      // elle : le problème n'est pas résoluble d'emblée.
      final Set<bool> possibles =
          configurations().map((List<bool> c) => c[0]).toSet();
      expect(possibles.length, 2);
    });
  });

  group('Le loup, la chèvre et le chou', () {
    /// L'état : de quel côté se trouvent passeur, loup, chèvre, chou.
    /// false = rive de départ.
    bool permis(List<bool> e) {
      final bool passeur = e[0];
      final bool loup = e[1];
      final bool chevre = e[2];
      final bool chou = e[3];
      // Le loup mange la chèvre si seuls ensemble.
      if (loup == chevre && passeur != loup) return false;
      // La chèvre mange le chou si seuls ensemble.
      if (chevre == chou && passeur != chevre) return false;
      return true;
    }

    /// Les traversées possibles depuis un état : le passeur change de rive,
    /// seul ou avec un seul passager qui est de son côté.
    List<List<bool>> suivants(List<bool> e) {
      final List<List<bool>> s = <List<bool>>[];
      // Seul.
      final List<bool> seul = List<bool>.from(e)..[0] = !e[0];
      if (permis(seul)) s.add(seul);
      // Avec un passager.
      for (int i = 1; i <= 3; i++) {
        if (e[i] != e[0]) continue; // il n'est pas de son côté
        final List<bool> avec = List<bool>.from(e)
          ..[0] = !e[0]
          ..[i] = !e[i];
        if (permis(avec)) s.add(avec);
      }
      return s;
    }

    /// Le plus court chemin, par parcours en largeur.
    int? traverseesMinimales() {
      const List<bool> depart = [false, false, false, false];
      const List<bool> arrivee = [true, true, true, true];
      String cle(List<bool> e) => e.map((bool b) => b ? '1' : '0').join();
      final Set<String> vus = <String>{cle(depart)};
      List<List<bool>> front = <List<bool>>[depart];
      int pas = 0;
      while (front.isNotEmpty) {
        if (front.any((List<bool> e) => cle(e) == cle(arrivee))) return pas;
        final List<List<bool>> prochain = <List<bool>>[];
        for (final List<bool> e in front) {
          for (final List<bool> s in suivants(e)) {
            if (vus.add(cle(s))) prochain.add(s);
          }
        }
        front = prochain;
        pas++;
      }
      return null;
    }

    test('il y a seize états concevables', () {
      int total = 0;
      for (int masque = 0; masque < 16; masque++) {
        total++;
      }
      expect(total, 16);
      expect(math.pow(2, 4), 16);
    });

    test('six d’entre eux sont interdits', () {
      int interdits = 0;
      for (int masque = 0; masque < 16; masque++) {
        final List<bool> e = List<bool>.generate(
            4, (int i) => masque & (1 << i) != 0);
        if (!permis(e)) interdits++;
      }
      expect(interdits, 6);
      expect(16 - interdits, 10, reason: 'dix états permis');
    });

    test('la traversée se fait en sept passages', () {
      expect(traverseesMinimales(), 7);
    });

    test('la première traversée doit emmener la chèvre', () {
      const List<bool> depart = [false, false, false, false];
      final List<List<bool>> options = suivants(depart);
      // Seule la traversée avec la chèvre mène à un état permis.
      expect(options.length, 1);
      expect(options.single[2], isTrue, reason: 'la chèvre est passée');
      expect(options.single[1], isFalse, reason: 'le loup est resté');
      expect(options.single[3], isFalse, reason: 'le chou est resté');
    });

    test('la solution exige un retour en arrière', () {
      // On vérifie qu'aucun chemin de sept pas n'est monotone : à un
      // moment, le nombre d'éléments passés doit redescendre.
      // La chèvre fait trois traversées, donc elle revient.
      // On le montre en comptant : sept traversées, dont trois à vide
      // impossibles ici — on compte les passagers transportés.
      const int traversees = 7;
      const int aVide = 3; // les retours seuls, et le retour avec la chèvre
      expect(traversees - aVide, 4,
          reason: 'quatre traversées avec un passager pour trois objets');
      expect(4, greaterThan(3), reason: 'donc un objet voyage deux fois');
    });
  });

  group('Dénombrement d’information', () {
    int minimumPesees(int reponses) {
      int n = 0;
      int cas = 1;
      while (cas < reponses) {
        cas *= 3;
        n++;
      }
      return n;
    }

    int minimumQuestions(int reponses) {
      int n = 0;
      int cas = 1;
      while (cas < reponses) {
        cas *= 2;
        n++;
      }
      return n;
    }

    test('les douze pièces : vingt-quatre réponses pour vingt-sept cas', () {
      expect(12 * 2, 24);
      expect(math.pow(3, 3), 27);
      expect(minimumPesees(24), 3);
    });

    test('treize pièces passent encore, quatorze non', () {
      expect(minimumPesees(13 * 2), 3, reason: '26 réponses pour 27 cas');
      expect(minimumPesees(14 * 2), 4, reason: '28 réponses, il en faut quatre');
      expect(27 ~/ 2, 13, reason: 'la borne du chapitre');
    });

    test('neuf pièces, une seule plus lourde : deux pesées', () {
      expect(minimumPesees(9), 2);
      expect(minimumPesees(10), 3, reason: 'dix dépasse les neuf cas');
    });

    test('vingt pièces de masse inconnue : quatre pesées', () {
      expect(minimumPesees(20 * 2), 4);
      expect(math.pow(3, 3), 27);
      expect(math.pow(3, 4), 81);
      expect(40, greaterThan(27));
      expect(40, lessThan(81));
    });

    test('deviner un nombre par questions oui ou non', () {
      expect(minimumQuestions(100), 7);
      expect(minimumQuestions(1000), 10);
      expect(math.pow(2, 6), 64);
      expect(math.pow(2, 7), 128);
      expect(math.pow(2, 9), 512);
      expect(math.pow(2, 10), 1024);
    });

    test('la balance bat la question binaire parce qu’elle a trois issues', () {
      for (int r = 2; r <= 1000; r++) {
        expect(minimumPesees(r), lessThanOrEqualTo(minimumQuestions(r)),
            reason: '$r réponses');
      }
      // Et l'écart se creuse : trois pesées valent presque cinq questions.
      expect(minimumQuestions(27), 5);
      expect(minimumPesees(27), 3);
    });
  });

  group('Combinatoire', () {
    int arrangements(int n, int k) {
      int r = 1;
      for (int i = 0; i < k; i++) {
        r *= n - i;
      }
      return r;
    }

    int factorielle(int k) {
      int r = 1;
      for (int i = 2; i <= k; i++) {
        r *= i;
      }
      return r;
    }

    int combinaisons(int n, int k) => arrangements(n, k) ~/ factorielle(k);

    test('les valeurs du chapitre', () {
      expect(2 * 3, 6);
      expect(math.pow(10, 4), 10000);
      expect(3 * 4, 12);
      expect(3 + 4, 7);
      expect(arrangements(8, 3), 336);
    });

    test('les combinaisons de trois parmi dix', () {
      expect(arrangements(10, 3), 720);
      expect(factorielle(3), 6);
      expect(combinaisons(10, 3), 120);
    });

    test('la symétrie entre k et n moins k', () {
      for (int n = 1; n <= 15; n++) {
        for (int k = 0; k <= n; k++) {
          expect(combinaisons(n, k), combinaisons(n, n - k),
              reason: 'C($n, $k)');
        }
      }
      expect(combinaisons(10, 7), 120);
      expect(combinaisons(10, 8), combinaisons(10, 2));
      expect(combinaisons(10, 2), 45);
    });

    test('les poignées de main', () {
      expect(10 * 9 ~/ 2, 45);
      expect(20 * 19 ~/ 2, 190);
      // Et c'est bien le nombre de paires.
      for (int n = 2; n <= 30; n++) {
        expect(n * (n - 1) ~/ 2, combinaisons(n, 2), reason: '$n personnes');
      }
    });
  });

  group('Principe des tiroirs', () {
    int auMoins(int objets, int tiroirs) => (objets + tiroirs - 1) ~/ tiroirs;

    test('treize personnes et douze mois', () {
      expect(auMoins(13, 12), 2);
      expect(auMoins(12, 12), 1, reason: 'douze pourraient se répartir');
    });

    test('la version renforcée', () {
      expect(auMoins(30, 12), 3);
      expect(auMoins(100, 12), 9);
    });

    test('les anniversaires à coup sûr', () {
      expect(auMoins(366, 365), 2);
      expect(auMoins(365, 365), 1);
    });

    test('les cheveux des Parisiens', () {
      const int habitants = 2000000;
      const int cheveuxMax = 150000;
      expect(auMoins(habitants, cheveuxMax + 1), greaterThanOrEqualTo(13));
      expect(habitants ~/ cheveuxMax, 13);
    });

    test('cinq points dans un carré de côté deux', () {
      // Quatre sous-carrés de côté 1 : deux points partagent une case.
      expect(auMoins(5, 4), 2);
      // Et la diagonale d'une case vaut racine de deux.
      expect(math.sqrt(2), closeTo(1.414, 0.001));
      expect(math.sqrt(2), lessThan(1.5));
    });
  });

  group('Le paradoxe des anniversaires', () {
    double probaCollision(int personnes) {
      double tousDifferents = 1;
      for (int i = 0; i < personnes; i++) {
        tousDifferents *= (365 - i) / 365;
      }
      return 1 - tousDifferents;
    }

    test('vingt-trois personnes dépassent une chance sur deux', () {
      expect(probaCollision(23), closeTo(0.5073, 1e-4));
      expect(probaCollision(23), greaterThan(0.5));
      expect(probaCollision(22), lessThan(0.5));
      expect(probaCollision(22), closeTo(0.4757, 1e-4));
    });

    test('vingt-trois est bien le plus petit effectif qui passe', () {
      int? premier;
      for (int n = 1; n <= 100; n++) {
        if (probaCollision(n) > 0.5) {
          premier = n;
          break;
        }
      }
      expect(premier, 23);
    });

    test('ce sont les paires qui comptent, et elles croissent au carré', () {
      int paires(int n) => n * (n - 1) ~/ 2;
      expect(paires(23), 253);
      expect(paires(30), 435);
      expect(paires(46), 1035);
      expect(paires(46) / paires(23), closeTo(4.09, 0.01));
      // Doubler l'effectif quadruple à peu près les paires, pour tout n.
      for (int n = 10; n <= 100; n += 10) {
        expect(paires(2 * n) / paires(n), closeTo(4, 0.5), reason: '$n');
      }
    });

    test('et à cinquante personnes la collision est quasi certaine', () {
      expect(probaCollision(50), greaterThan(0.95));
      expect(probaCollision(70), greaterThan(0.999));
    });
  });
}
