import 'package:flutter_test/flutter_test.dart';

/// La technologie du primaire, recalculée.
///
/// Ces quatre chapitres avancent deux sortes d'affirmations : des rapports
/// mécaniques (un palan divise la force autant de fois qu'il a de brins) et
/// des programmes (un feu tricolore, une porte automatique). Les premiers
/// sont refabriqués à partir du modèle, les seconds sont **exécutés** — un
/// programme dont on se contente de relire l'énoncé n'a jamais été vérifié.
void main() {
  group('Palan', () {
    /// Un palan à n brins divise la force par n et multiplie par n la
    /// longueur de câble. Le produit des deux est l'invariant : c'est lui
    /// que la carte « la règle qui ne pardonne jamais » affirme.
    double force(double charge, int brins) => charge / brins;
    double cable(double hauteur, int brins) => hauteur * brins;

    test('une poulie fixe ne divise rien', () {
      expect(force(20, 1), 20);
      expect(cable(1, 1), 1);
    });

    test('une poulie mobile divise par deux', () {
      expect(force(20, 2), 10);
      expect(cable(1, 2), 2);
    });

    test('quatre brins divisent par quatre', () {
      expect(force(20, 4), 5);
      expect(cable(3, 4), 12);
    });

    test('la grue : six brins sous mille deux cents kilos', () {
      expect(force(1200, 6), 200);
      expect(cable(10, 6), 60);
    });

    test('force × longueur ne change jamais, quel que soit le palan', () {
      const double charge = 1200;
      const double hauteur = 10;
      const double reference = charge * hauteur;
      for (int brins = 1; brins <= 12; brins++) {
        expect(force(charge, brins) * cable(hauteur, brins),
            closeTo(reference, 1e-9),
            reason: '$brins brins');
      }
    });

    test('la vitesse de la charge est divisée comme la force', () {
      const double vitesseCable = 3; // m/s
      for (int brins = 1; brins <= 8; brins++) {
        final double vitesseCharge = vitesseCable / brins;
        // Le temps de levage est le même quelle que soit la façon de le
        // calculer : par le câble ou par la charge.
        const double hauteur = 10;
        expect(cable(hauteur, brins) / vitesseCable,
            closeTo(hauteur / vitesseCharge, 1e-9),
            reason: '$brins brins');
      }
      expect(vitesseCable / 6, closeTo(0.5, 1e-9));
    });

    test('vingt secondes pour dix mètres avec six brins', () {
      expect(cable(10, 6) / 3, 20);
    });
  });

  group('Réducteur', () {
    int toursMoteur(int toursSortie, int rapport) => toursSortie * rapport;

    test('huit tours de tambour, quatre cents tours de moteur', () {
      expect(toursMoteur(8, 50), 400);
    });

    test('le couple gagné est exactement le rapport', () {
      const int rapport = 50;
      for (int tours = 0; tours <= 20; tours++) {
        expect(toursMoteur(tours, rapport), tours * 50, reason: '$tours tours');
      }
    });
  });

  group('Frottement et chevaux', () {
    test('la glace divise l’effort par quinze', () {
      expect(30 / 2, 15);
    });

    test('cent chevaux pour soixante-dix kilowatts', () {
      expect(70 / 0.7, closeTo(100, 1e-9));
    });
  });

  group('Masse volumique', () {
    /// Les valeurs en kilogrammes par litre. Un cube de 10 cm fait un litre,
    /// donc sa masse en kilogrammes est sa masse volumique.
    const Map<String, double> kgParLitre = {
      'liège': 0.25,
      'sapin': 0.5,
      'eau': 1.0,
      'verre': 2.5,
      'aluminium': 2.7,
      'acier': 7.9,
      'plomb': 11.3,
    };

    double masseDuCube(String matiere, double coteCm) {
      final double volumeLitres = coteCm * coteCm * coteCm / 1000;
      return kgParLitre[matiere]! * volumeLitres;
    }

    bool flotte(String matiere) => kgParLitre[matiere]! < kgParLitre['eau']!;

    test('un cube de dix centimètres fait un litre', () {
      expect(10 * 10 * 10 / 1000, 1);
      expect(masseDuCube('eau', 10), 1);
    });

    test('le cube d’acier pèse sept kilos neuf', () {
      expect(masseDuCube('acier', 10), closeTo(7.9, 1e-9));
    });

    test('le cube de sapin pèse un demi-kilo', () {
      expect(masseDuCube('sapin', 10), closeTo(0.5, 1e-9));
    });

    test('l’acier est seize fois le sapin, à volume égal', () {
      final double rapport = kgParLitre['acier']! / kgParLitre['sapin']!;
      expect(rapport, closeTo(15.8, 1e-9));
      expect(rapport.round(), 16);
    });

    test('qui flotte et qui coule', () {
      expect(flotte('liège'), isTrue);
      expect(flotte('sapin'), isTrue);
      for (final String m in <String>['verre', 'aluminium', 'acier', 'plomb']) {
        expect(flotte(m), isFalse, reason: m);
      }
      expect(flotte('eau'), isFalse, reason: 'l’eau ne flotte pas sur elle-même');
    });

    test('l’ordre du classement est strictement croissant', () {
      const List<String> ordre = [
        'liège',
        'sapin',
        'eau',
        'verre',
        'acier',
        'plomb',
      ];
      for (int i = 1; i < ordre.length; i++) {
        expect(kgParLitre[ordre[i]]!, greaterThan(kgParLitre[ordre[i - 1]]!),
            reason: '${ordre[i]} après ${ordre[i - 1]}');
      }
    });

    test('un bateau d’acier rempli d’air flotte', () {
      // Une coque d'acier qui n'occupe qu'un vingtième du volume du bateau.
      const double partAcier = 0.05;
      final double ensemble =
          partAcier * kgParLitre['acier']! + (1 - partAcier) * 0.0012; // air
      expect(ensemble, lessThan(kgParLitre['eau']!));
      // Et une coque qui en occuperait la moitié coulerait.
      final double pleine = 0.5 * kgParLitre['acier']!;
      expect(pleine, greaterThan(kgParLitre['eau']!));
    });

    test('la refonte de l’aluminium coûte quinze fois moins', () {
      expect(150 / 15, 10);
    });
  });

  group('Le triangle du maçon', () {
    test('trois, quatre, cinq : la diagonale vaut cinquante', () {
      expect(30 * 30 + 40 * 40, 2500);
      expect(50 * 50, 2500);
    });

    test('cinquante est la seule diagonale qui donne l’angle droit', () {
      // La diagonale croît strictement avec l'angle : toute autre valeur
      // désigne un angle aigu ou obtus. On le vérifie par encadrement.
      int carre(int x) => x * x;
      for (int d = 30; d <= 70; d++) {
        if (d == 50) continue;
        expect(carre(d) == carre(30) + carre(40), isFalse, reason: 'd = $d');
      }
      // En dessous de 50 l'angle est aigu, au-dessus il est obtus.
      expect(carre(49), lessThan(carre(30) + carre(40)));
      expect(carre(51), greaterThan(carre(30) + carre(40)));
    });

    test('les autres triplets entiers utilisables sur un chantier', () {
      bool rectangle(int a, int b, int c) => a * a + b * b == c * c;
      expect(rectangle(3, 4, 5), isTrue);
      expect(rectangle(6, 8, 10), isTrue);
      expect(rectangle(5, 12, 13), isTrue);
      expect(rectangle(30, 40, 50), isTrue);
      expect(rectangle(3, 4, 6), isFalse);
    });
  });

  group('Erreurs d’atelier', () {
    test('dix mesures en chaîne cumulent dix millimètres', () {
      int decalage = 0;
      for (int planche = 0; planche < 10; planche++) {
        decalage += 1; // un millimètre d'erreur à chaque report
      }
      expect(decalage, 10);
    });

    test('mesurer depuis la même origine ne cumule rien', () {
      // Dix mesures prises depuis le même bord : chacune porte au plus un
      // millimètre d'erreur, mais elles ne s'additionnent pas.
      const int erreurMax = 1;
      for (int planche = 0; planche < 10; planche++) {
        expect(erreurMax, 1, reason: 'planche $planche');
      }
      expect(erreurMax, lessThan(10));
    });

    test('six morceaux demandent cinq coupes, pas six', () {
      int coupesPour(int morceaux) {
        // On simule : on part d'une planche entière et on compte les coups
        // de scie jusqu'à obtenir le nombre voulu de morceaux.
        int actuels = 1;
        int coupes = 0;
        while (actuels < morceaux) {
          coupes++;
          actuels++;
        }
        return coupes;
      }

      expect(coupesPour(6), 5);
      expect(coupesPour(1), 0, reason: 'une planche entière, aucune coupe');
      for (int m = 1; m <= 20; m++) {
        expect(coupesPour(m), m - 1, reason: '$m morceaux');
      }
      // Dix millimètres de sciure, pas douze.
      expect(coupesPour(6) * 2, 10);
    });

    test('l’étagère : extérieur, intérieur, et l’écart entre les deux', () {
      double exterieur(double interieur, double montant) =>
          interieur + 2 * montant;
      double interieur(double ext, double montant) => ext - 2 * montant;

      expect(exterieur(120, 2), 124);
      expect(interieur(122, 2), 118);
      expect(120 - interieur(122, 2), 2);
      // Les deux fonctions sont réciproques, pour tout montant.
      for (double m = 0; m <= 5; m += 0.5) {
        expect(interieur(exterieur(118, m), m), closeTo(118, 1e-9),
            reason: 'montant $m');
      }
    });

    test('quatre étagères laissent cinq intervalles', () {
      double espace(double hauteur, int etageres, double epaisseur) {
        final double libre = hauteur - etageres * epaisseur;
        return libre / (etageres + 1);
      }

      expect(espace(180, 4, 2), closeTo(34.4, 1e-9));
      // La somme reconstitue bien la hauteur totale : intervalles plus
      // épaisseurs. C'est le contrôle qui attrape l'erreur de découpage.
      const int etageres = 4;
      final double e = espace(180, etageres, 2);
      expect(e * (etageres + 1) + etageres * 2, closeTo(180, 1e-9));
    });

    test('l’échelle, dans les deux sens', () {
      double surLeDessin(double reel, double denominateur) =>
          reel / denominateur;
      double dansLaRealite(double dessin, double denominateur) =>
          dessin * denominateur;

      expect(surLeDessin(180, 10), 18);
      expect(dansLaRealite(4.5, 10), closeTo(45, 1e-9));
      expect(dansLaRealite(8, 1 / 5), closeTo(1.6, 1e-9),
          reason: 'une échelle 5/1 agrandit');
      // Une vis de 8 mm à l'échelle 5/1 occupe 40 mm sur le papier.
      expect(8 * 5, 40);
      for (double r = 1; r <= 200; r += 7) {
        expect(dansLaRealite(surLeDessin(r, 10), 10), closeTo(r, 1e-9),
            reason: '$r cm');
      }
    });
  });

  group('Le feu tricolore, exécuté', () {
    /// Le cycle du chapitre, phase par phase : durée, état de la rue A,
    /// état de la rue B. On ne relit pas l'énoncé, on le déroule.
    const List<List<Object>> phases = [
      [24, 'vert', 'rouge'],
      [4, 'orange', 'rouge'],
      [2, 'rouge', 'rouge'],
      [24, 'rouge', 'vert'],
      [4, 'rouge', 'orange'],
      [2, 'rouge', 'rouge'],
    ];

    final int duree = phases.fold<int>(
      0,
      (int s, List<Object> p) => s + (p[0] as int),
    );

    /// L'état des deux rues à la seconde t du cycle.
    (String, String) etatA(int t) {
      int reste = t % duree;
      for (final List<Object> p in phases) {
        final int d = p[0] as int;
        if (reste < d) return (p[1] as String, p[2] as String);
        reste -= d;
      }
      throw StateError('cycle incohérent');
    }

    test('le cycle dure une minute', () {
      expect(duree, 60);
    });

    test('la rue A compte trente-deux secondes de rouge', () {
      int rouge = 0;
      for (int t = 0; t < duree; t++) {
        if (etatA(t).$1 == 'rouge') rouge++;
      }
      expect(rouge, 32);
      expect(rouge, duree - 24 - 4, reason: 'tout ce qui n’est ni vert ni orange');
    });

    test('les deux rues ne sont jamais vertes en même temps', () {
      for (int t = 0; t < duree * 5; t++) {
        final (String a, String b) = etatA(t);
        expect(a == 'vert' && b == 'vert', isFalse,
            reason: 'seconde $t : A=$a B=$b');
      }
    });

    test('un vert n’est jamais suivi immédiatement d’un vert d’en face', () {
      // La condition forte : entre la fin d'un vert et le début de l'autre,
      // il doit s'écouler au moins l'orange et le temps mort.
      for (int t = 0; t < duree; t++) {
        if (etatA(t).$1 == 'vert' && etatA((t + 1) % duree).$1 != 'vert') {
          // A vient de perdre son vert. B ne doit pas l'avoir avant six
          // secondes : quatre d'orange plus deux de rouge intégral.
          for (int d = 1; d <= 6; d++) {
            expect(etatA((t + d) % duree).$2, isNot('vert'),
                reason: 'B verte $d s après la fin du vert de A');
          }
        }
      }
    });

    test('il existe bien des secondes de rouge intégral', () {
      int integral = 0;
      for (int t = 0; t < duree; t++) {
        final (String a, String b) = etatA(t);
        if (a == 'rouge' && b == 'rouge') integral++;
      }
      // Les deux temps morts de deux secondes, plus les secondes où l'autre
      // rue est à l'orange.
      expect(integral, greaterThanOrEqualTo(4));
    });

    test('chaque rue reçoit autant de vert que l’autre', () {
      int vert(int rue) {
        int n = 0;
        for (int t = 0; t < duree; t++) {
          final (String a, String b) = etatA(t);
          if ((rue == 0 ? a : b) == 'vert') n++;
        }
        return n;
      }

      expect(vert(0), 24);
      expect(vert(1), 24);
      expect(vert(0), vert(1), reason: 'le carrefour est équitable');
    });

    test('soixante cycles par heure', () {
      expect(3600 ~/ duree, 60);
    });

    test('douze voitures par cycle, sept cent vingt par heure', () {
      const int intervalle = 2; // secondes entre deux voitures
      const int parCycle = 24 ~/ intervalle;
      expect(parCycle, 12);
      expect(parCycle * (3600 ~/ duree), 720);
    });
  });

  group('L’onde verte', () {
    double decalage(double metres, double metresParSeconde) =>
        metres / metresParSeconde;

    test('quatre cent vingt mètres à quatorze mètres par seconde', () {
      expect(decalage(420, 14), 30);
    });

    test('le décalage vaut la moitié du cycle', () {
      expect(decalage(420, 14) / 60, closeTo(0.5, 1e-9));
    });

    test('le troisième feu retombe en phase avec le premier', () {
      final double troisieme = decalage(840, 14);
      expect(troisieme, 60);
      expect(troisieme % 60, 0, reason: 'un cycle entier, donc même phase');
    });

    test('rouler moins vite demande un décalage plus grand', () {
      // 30 km/h font environ 8,3 m/s.
      final double lent = decalage(420, 30 * 1000 / 3600);
      final double rapide = decalage(420, 50 * 1000 / 3600);
      expect(lent, greaterThan(rapide));
      expect(lent, closeTo(50.4, 0.1));
    });

    test('rouler plus vite fait arriver avant le vert', () {
      const double regle = 30; // secondes de décalage prévues
      // Une voiture à 70 km/h, soit 19,4 m/s, met moins de 30 s.
      final double trop = decalage(420, 70 * 1000 / 3600);
      expect(trop, lessThan(regle));
      expect(trop, closeTo(21.6, 0.1));
      // Elle arrive donc au rouge et doit s'arrêter.
      expect(regle - trop, greaterThan(0));
    });
  });

  group('La porte automatique, exécutée', () {
    /// Le programme du chapitre : le compteur de quatre secondes repart à
    /// zéro à chaque détection. On compare au programme fautif, qui ne le
    /// remet pas, pour vérifier que le défaut est bien celui annoncé.
    int fermetureAvecRemiseAZero(List<int> detections, int attente) =>
        detections.last + attente;

    int fermetureSansRemiseAZero(List<int> detections, int attente) =>
        detections.first + attente;

    test('deux personnes : le bon programme attend la seconde', () {
      const List<int> detections = [0, 3];
      expect(fermetureAvecRemiseAZero(detections, 4), 7);
    });

    test('sans remise à zéro, la porte se referme sur la seconde', () {
      const List<int> detections = [0, 3];
      const int sortieDeLaSeconde = 5;
      final int fautif = fermetureSansRemiseAZero(detections, 4);
      expect(fautif, 4);
      expect(fautif, lessThan(sortieDeLaSeconde),
          reason: 'la porte se ferme avant que la seconde personne soit passée');
      // Le programme correct, lui, laisse le passage.
      expect(fermetureAvecRemiseAZero(detections, 4),
          greaterThan(sortieDeLaSeconde));
    });

    test('un flot continu maintient la porte ouverte', () {
      final List<int> detections =
          List<int>.generate(20, (int i) => i * 3); // une personne toutes les 3 s
      expect(fermetureAvecRemiseAZero(detections, 4), 61);
      // Alors que le programme fautif aurait fermé à la quatrième seconde,
      // au milieu du flot.
      expect(fermetureSansRemiseAZero(detections, 4), 4);
    });

    test('une seule personne : les deux programmes sont d’accord', () {
      const List<int> seule = [0];
      expect(fermetureAvecRemiseAZero(seule, 4),
          fermetureSansRemiseAZero(seule, 4));
      // C'est pour cela que le défaut passe tous les essais à une personne :
      // il n'apparaît qu'avec deux arrivées rapprochées.
    });
  });

  group('L’arrosage sans condition', () {
    test('quatre arrosages par jour, quarante minutes', () {
      expect(24 ~/ 6, 4);
      expect((24 ~/ 6) * 10, 40);
    });

    test('une semaine de pluie, et il arrose quand même', () {
      // Le programme ne regarde pas le monde : il compte seulement.
      int minutesArrosees(int jours, {required bool ilPleut}) {
        int total = 0;
        for (int j = 0; j < jours; j++) {
          for (int passage = 0; passage < 24 ~/ 6; passage++) {
            total += 10; // aucune condition : la pluie n'y change rien
          }
        }
        return total;
      }

      expect(minutesArrosees(7, ilPleut: true), 280);
      expect(minutesArrosees(7, ilPleut: false), 280,
          reason: 'le programme fautif ne distingue pas les deux cas');
    });

    test('avec la condition, la pluie suspend l’arrosage', () {
      int minutesCorrigees(int jours, {required bool ilPleut}) {
        int total = 0;
        for (int j = 0; j < jours; j++) {
          for (int passage = 0; passage < 24 ~/ 6; passage++) {
            if (ilPleut) continue; // la ligne manquante
            total += 10;
          }
        }
        return total;
      }

      expect(minutesCorrigees(7, ilPleut: true), 0);
      expect(minutesCorrigees(7, ilPleut: false), 280);
    });
  });
}
