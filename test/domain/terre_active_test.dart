import 'package:eureka/design_system/figures/volcano_figure.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les nombres du chapitre sont refaits, et la figure doit raconter
/// la même chose que le texte.
///
/// Un chapitre de primaire se trompe surtout sur des ordres de grandeur :
/// « quelques centimètres par an » devient vite « quelques mètres » dans
/// une conversion, et personne ne le vérifie. Ces tests refont les
/// conversions, et contrôlent surtout que la figure du volcan ne contredit
/// pas le cours — une chambre pleine après l'éruption enseignerait
/// l'inverse de ce que le texte explique.
void main() {
  group('Les plaques et le temps long', () {
    test('2 cm par an font 2 mètres par siècle', () {
      expect(2 * 100, 200, reason: 'en centimètres');
      expect(2 * 100 / 100, 2, reason: 'en mètres');
    });

    test('et 2 000 km en cent millions d\'années', () {
      // La question du défi. On passe par les centimètres puis les
      // kilomètres, comme l'élève est invité à le faire.
      const double centimetres = 2 * 100000000;
      expect(centimetres, 200000000);
      expect(centimetres / 100 / 1000, 2000);
    });

    test('l\'Atlantique s\'est ouvert de l\'ordre de sa largeur actuelle', () {
      // Contrôle de vraisemblance : à 2 cm/an depuis 200 millions
      // d'années, on obtient 4 000 km. L'Atlantique en fait environ
      // 5 000 au niveau de l'équateur. Le compte est du bon ordre, ce qui
      // est ce que le chapitre affirme.
      const double km = 2 * 200000000 / 100 / 1000;
      expect(km, 4000);
      expect(km, greaterThan(2000));
      expect(km, lessThan(8000));
    });
  });

  group('Les vitesses qui tuent', () {
    test('une nuée à 300 km/h parcourt 10 km en deux minutes', () {
      expect(300 * 2 / 60, 10);
      // Et un humain qui court à 15 km/h en fait 0,5 : d'où
      // l'impossibilité de fuir, que le chapitre énonce.
      expect(15 * 2 / 60, 0.5);
      expect(300 / 15, 20, reason: 'vingt fois plus vite qu\'un coureur');
    });

    test('une coulée de lave laisse le temps de partir', () {
      // Les coulées hawaïennes avancent de l'ordre de quelques km/h au
      // plus. La différence d'ordre de grandeur avec la nuée est le fait
      // que le chapitre met en avant.
      const double coulee = 5;
      expect(300 / coulee, 60);
      expect(coulee, lessThan(15), reason: 'plus lent qu\'un coureur');
    });
  });

  group('La figure du volcan', () {
    test('la chambre se remplit au repos et culmine sous pression', () {
      expect(
        VolcanoFigure.remplissage(EtatVolcan.pression),
        greaterThan(VolcanoFigure.remplissage(EtatVolcan.repos)),
      );
      expect(VolcanoFigure.remplissage(EtatVolcan.pression), 1);
    });

    test('et se vide après l\'éruption', () {
      // Le point qui compte : une figure montrant une chambre encore
      // pleine après l'éruption enseignerait le contraire du chapitre.
      for (final EtatVolcan apres in <EtatVolcan>[
        EtatVolcan.rouge,
        EtatVolcan.gris,
      ]) {
        expect(
          VolcanoFigure.remplissage(apres),
          lessThan(VolcanoFigure.remplissage(EtatVolcan.pression)),
          reason: apres.name,
        );
      }
    });

    test('l\'éruption grise vide davantage que la rouge', () {
      // Une explosion évacue la chambre plus brutalement qu'une coulée
      // continue. C'est cohérent avec ce que le texte dit des deux types.
      expect(
        VolcanoFigure.remplissage(EtatVolcan.gris),
        lessThan(VolcanoFigure.remplissage(EtatVolcan.rouge)),
      );
    });

    test('tous les remplissages sont des fractions valides', () {
      for (final EtatVolcan e in EtatVolcan.values) {
        expect(
          VolcanoFigure.remplissage(e),
          inInclusiveRange(0, 1),
          reason: e.name,
        );
      }
    });

    test('seule l\'éruption grise a une cheminée bouchée', () {
      // C'est la cause de la différence entre les deux types, et le
      // chapitre la présente ainsi : une lave épaisse bouche le conduit,
      // la pression monte, la sortie se fait d'un coup.
      for (final EtatVolcan e in EtatVolcan.values) {
        expect(
          VolcanoFigure.chemineeObstruee(e),
          e == EtatVolcan.gris,
          reason: e.name,
        );
      }
    });

    test('les deux éruptions sont les seuls états qui émettent', () {
      expect(VolcanoFigure.enEruption(EtatVolcan.repos), isFalse);
      expect(VolcanoFigure.enEruption(EtatVolcan.pression), isFalse);
      expect(VolcanoFigure.enEruption(EtatVolcan.rouge), isTrue);
      expect(VolcanoFigure.enEruption(EtatVolcan.gris), isTrue);
    });

    test('chaque état porte un titre et une explication', () {
      for (final EtatVolcan e in EtatVolcan.values) {
        expect(e.titre, isNotEmpty);
        expect(e.explication.length, greaterThan(20), reason: e.name);
      }
    });
  });
}
