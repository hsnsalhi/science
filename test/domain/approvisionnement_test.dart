import 'package:eureka/design_system/figures/supply_figure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les nombres du corps sont recalculés, et la cohérence de la figure est
/// vérifiée contre ce que le chapitre affirme.
///
/// Un chapitre de SVT ne se trompe pas sur des équations mais sur des
/// ordres de grandeur et sur des définitions — « artère » veut dire « part
/// du cœur », pas « transporte du sang oxygéné », et c'est l'erreur que le
/// chapitre existe pour corriger. Ces tests refont les calculs du défi et
/// s'assurent que la figure raconte bien la continuité que le cours promet :
/// deux portes différentes, une seule destination.
void main() {
  group('Les nombres du cœur', () {
    const int battementsParMinute = 70;
    const int millilitresParBattement = 70;

    test('4,9 litres par minute', () {
      const int millilitres =
          battementsParMinute * millilitresParBattement;
      expect(millilitres, 4900);
      expect(millilitres / 1000, closeTo(4.9, 1e-9));
    });

    test('tout le sang du corps passe par le cœur chaque minute', () {
      // L'affirmation de q4. Le corps contient environ 5 litres ; le débit
      // au repos est de 4,9. Le rapport doit être proche de 1.
      const double litresDeSang = 5;
      const double debit = 4.9;
      expect(debit / litresDeSang, closeTo(0.98, 0.05));
      expect(debit / litresDeSang, greaterThan(0.9));
    });

    test('environ 7 000 litres par jour', () {
      const int minutesParJour = 24 * 60;
      expect(minutesParJour, 1440);
      const double litres = 4.9 * minutesParJour;
      expect(litres, closeTo(7056, 1));
      // La réponse attendue à q2, en milliers de litres.
      expect(litres / 1000, closeTo(7, 0.5));
    });

    test('environ 2,9 milliards de battements en 80 ans', () {
      // 365,25 jours par an, soit 525 960 minutes — la valeur de l'indice
      // arrondie à 525 600 donne le même résultat au dixième de milliard.
      const int minutesParAn = 525600;
      const double battements =
          battementsParMinute * minutesParAn * 80 / 1e9;
      expect(battements, closeTo(2.94, 0.01));
      expect(battements, closeTo(2.9, 0.2));
      // Et avec l'année réelle, le résultat ne bouge pas à ce niveau.
      const double avecAnneeReelle =
          battementsParMinute * 365.25 * 24 * 60 * 80 / 1e9;
      expect(avecAnneeReelle, closeTo(2.94, 0.01));
    });

    test('plus de 200 millions de litres sur une vie', () {
      const double millionsDeLitres = 4.9 * 525600 * 80 / 1e6;
      expect(millionsDeLitres, closeTo(206, 1));
      expect(millionsDeLitres, greaterThan(200));
    });
  });

  group('Les deux trajets de la figure', () {
    test('ils ont le même nombre d\'étapes et finissent sur la cellule', () {
      final List<Etape> o2 = SupplyFigure.trajet(Cargaison.dioxygene);
      final List<Etape> glucose = SupplyFigure.trajet(Cargaison.glucose);
      expect(o2.length, glucose.length);
      expect(o2.last.lieu, 'cellule');
      expect(glucose.last.lieu, 'cellule');
    });

    test('ils entrent par des portes différentes', () {
      // L'idée du chapitre : deux portes, une route, une destination.
      final List<Etape> o2 = SupplyFigure.trajet(Cargaison.dioxygene);
      final List<Etape> glucose = SupplyFigure.trajet(Cargaison.glucose);
      expect(o2.first.lieu, isNot(glucose.first.lieu));
      expect(o2.first.lieu, 'air inspiré');
      expect(glucose.first.lieu, 'aliment');
      // Et leurs surfaces d'échange ne sont pas les mêmes.
      expect(o2.map((Etape e) => e.lieu), contains('alvéole'));
      expect(glucose.map((Etape e) => e.lieu), contains('villosité'));
      expect(o2.map((Etape e) => e.lieu), isNot(contains('villosité')));
      expect(glucose.map((Etape e) => e.lieu), isNot(contains('alvéole')));
    });

    test('mais se rejoignent sur le sang, le capillaire et la cellule', () {
      // La continuité que le cours promet. Si la figure décrivait deux
      // trajets disjoints, elle enseignerait les trois appareils séparés
      // — exactement ce que le chapitre veut défaire.
      expect(
        SupplyFigure.lieuxCommuns(),
        <String>['sang', 'capillaire', 'cellule'],
      );
    });

    test('l\'échange passe par le capillaire dans les deux cas', () {
      // La carte « où se font les échanges » : jamais ailleurs.
      for (final Cargaison c in Cargaison.values) {
        final List<Etape> t = SupplyFigure.trajet(c);
        final int iCapillaire =
            t.indexWhere((Etape e) => e.lieu == 'capillaire');
        final int iCellule = t.indexWhere((Etape e) => e.lieu == 'cellule');
        expect(iCapillaire, greaterThan(-1), reason: c.nom);
        // Et il vient juste avant la cellule : c'est le dernier passage.
        expect(iCapillaire, iCellule - 1);
      }
    });

    test('chaque étape porte un détail non vide', () {
      for (final Cargaison c in Cargaison.values) {
        for (final Etape e in SupplyFigure.trajet(c)) {
          expect(e.lieu, isNotEmpty);
          expect(e.detail.length, greaterThan(15), reason: e.lieu);
          // Les détails sont des phrases : la figure les affiche seuls.
          expect(e.detail.endsWith('.'), isTrue, reason: e.detail);
        }
      }
    });

    test('aucune étape n\'est répétée dans un trajet', () {
      for (final Cargaison c in Cargaison.values) {
        final List<String> lieux = SupplyFigure.trajet(c)
            .map((Etape e) => e.lieu)
            .toList(growable: false);
        expect(lieux.toSet().length, lieux.length, reason: c.nom);
      }
    });
  });

  group('Les ordres de grandeur du cours', () {
    test('le tube digestif fait environ neuf mètres', () {
      // Somme des longueurs usuelles, en centimètres : œsophage 25,
      // estomac 25, intestin grêle 650, gros intestin 150.
      const List<int> segments = <int>[25, 25, 650, 150];
      final int total = segments.reduce((int a, int b) => a + b);
      expect(total / 100, closeTo(8.5, 0.6));
      expect(total / 100, greaterThan(8));
      expect(total / 100, lessThan(10));
    });

    test('la surface alvéolaire fait bien la moitié d\'un court', () {
      // 300 millions d'alvéoles d'environ 0,25 mm² chacune donnent 75 m².
      // Un court de tennis en simple mesure 23,77 × 8,23 m, soit 196 m² :
      // « comparable à un court », que j'avais écrit d'abord, exagère d'un
      // facteur 2,6. « La moitié d'un court » est la formulation juste, et
      // c'est celle que le chapitre porte maintenant.
      const double alveoles = 300e6;
      const double surfaceUneMm2 = 0.25;
      const double totalM2 = alveoles * surfaceUneMm2 / 1e6;
      const double court = 23.77 * 8.23;
      expect(totalM2, closeTo(75, 5));
      expect(court, closeTo(196, 1));
      expect(totalM2, closeTo(70, 10), reason: 'la valeur annoncée');
      // La moitié du court, à 30 % près : c'est ce que « la moitié »
      // autorise. Le court entier, non.
      expect((totalM2 - court / 2).abs() / (court / 2), lessThan(0.3));
      expect((totalM2 - court).abs() / court, greaterThan(0.5));
    });

    test('un intestin lisse offrirait une surface bien plus petite', () {
      // L'argument de la carte « l'intestin grêle, l'organe clé » : un
      // tuyau lisse de 6,5 m sur 3 cm de diamètre n'offre qu'un demi-mètre
      // carré, contre des dizaines avec les villosités.
      const double longueur = 6.5;
      const double diametre = 0.03;
      const double surfaceLisse = 3.14159 * diametre * longueur;
      expect(surfaceLisse, closeTo(0.61, 0.05));
      expect(surfaceLisse, lessThan(1));
      // Le rapport avec la surface réelle, de l'ordre de 30 m².
      expect(30 / surfaceLisse, greaterThan(40));
    });
  });
}
