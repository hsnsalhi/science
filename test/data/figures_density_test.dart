import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les cours doivent montrer avant d'expliquer.
///
/// Un retour d'usage l'a dit sans détour : « il y a encore trop de lecture
/// et peu de dessins ». La mesure lui donnait raison — 8,8 % des cartes
/// étaient des figures, et 37 chapitres n'en avaient aucune.
///
/// Ce fichier empêche la dérive inverse de celle qu'on corrige. Il ne juge
/// pas la beauté d'un dessin : il compte, et il refuse qu'on recule.
void main() {
  /// Les chapitres repris au standard « figure d'abord ». Chaque leçon y
  /// ouvre sur une figure pilotable. La liste s'allonge à chaque lot ; elle
  /// ne se raccourcit jamais.
  const Set<String> repris = <String>{
    'physique-chimie-college-gravitation-et-systeme-solaire',
    'histoire-sciences-college-les-nombres-qui-ont-fait-peur',
    'histoire-sciences-college-l-atome-2500-ans-d-hypotheses',
    'histoire-sciences-college-pasteur-darwin-et-le-vivant',
    'logique-college-raisonnement-par-l-absurde',
    'logique-college-enigmes-de-logique-pure',
    'logique-college-denombrer-sans-se-tromper',
    'maths-college-puissances-et-racine-carree',
    'maths-college-statistiques-et-probabilites',
    'physique-chimie-college-atomes-molecules-et-reactions',
    'informatique-college-variables-et-expressions',
    'informatique-college-programmer-par-blocs',
    'informatique-college-le-tableur',
    'informatique-college-reseaux-et-internet',
    'svt-college-meteo-climat-et-changement-climatique',
    'technologie-college-besoin-fonction-cahier-des-charges',
    'technologie-college-materiaux-choisir-et-justifier',
    'technologie-college-ecoconception-et-cycle-de-vie',
    'maths-primaire-les-nombres-jusqu-a-10-000',
    'maths-primaire-additionner-et-soustraire',
    'maths-primaire-la-proportionnalite',
    'maths-primaire-geometrie-droites-cercles-polygones',
    'maths-primaire-perimetres-aires-et-angles',
    'maths-primaire-longueurs-masses-et-contenances',
    'maths-primaire-tableaux-graphiques-et-hasard',
    'svt-primaire-naitre-grandir-se-reproduire',
    'svt-primaire-alimentation-et-sante',
    'svt-primaire-le-cerveau-et-la-puberte',
    'physique-chimie-primaire-melanges-et-solutions',
    'physique-chimie-primaire-masses-volumes-et-temperatures',
    'histoire-sciences-primaire-compter-avant-les-chiffres',
    'histoire-sciences-primaire-les-grandes-inventions',
    'histoire-sciences-primaire-des-savants-et-des-savantes',
    'informatique-primaire-les-objets-techniques',
    'informatique-primaire-concevoir-un-objet',
    'technologie-primaire-imaginer-et-fabriquer',
    'technologie-primaire-de-quoi-est-il-fait',
    'technologie-primaire-programmer-un-objet-technique',
  };


  /// Part minimale de cartes « figure » sur l'ensemble du contenu.
  ///
  /// On la relève à chaque lot converti. Elle ne descend pas : un chapitre
  /// qu'on ajoute sans figure fait tomber la moyenne, et le test le dit.
  const double partMinimale = 0.24;

  late List<Map<String, dynamic>> chapitres;
  late Map<String, Map<String, dynamic>> contenus;

  setUpAll(() {
    final Map<String, dynamic> catalogue = jsonDecode(
      File('assets/content/catalog.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    chapitres = (catalogue['chapters'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((Map<String, dynamic> c) => c['status'] == 'disponible')
        .toList();
    contenus = <String, Map<String, dynamic>>{
      for (final Map<String, dynamic> c in chapitres)
        c['id'] as String: jsonDecode(
          File('assets/content/${c['content']}').readAsStringSync(),
        ) as Map<String, dynamic>,
    };
  });

  test('aucune leçon jouable n’est sans figure', () {
    // La garantie porte sur la leçon, pas sur le chapitre : un chapitre
    // peut avoir une belle figure en première leçon et trois leçons de
    // texte derrière. C’est précisément ce qui était arrivé, et c’est ce
    // que ce test rend impossible.
    final List<String> sansFigure = <String>[];
    for (final Map<String, dynamic> c in chapitres) {
      final String id = c['id'] as String;
      for (final dynamic brute in contenus[id]!['lessons'] as List<dynamic>) {
        final Map<String, dynamic> lecon = brute as Map<String, dynamic>;
        final Iterable<String> genres = (lecon['cards'] as List<dynamic>)
            .map((dynamic x) => (x as Map<String, dynamic>)['kind'] as String);
        if (!genres.contains('figure')) {
          sansFigure.add('$id/${lecon['id']}');
        }
      }
    }
    expect(sansFigure, isEmpty,
        reason: 'ces leçons n’ont aucune figure : $sansFigure');
  });

  test('chaque leçon d’un chapitre repris ouvre sur une figure', () {
    for (final String id in repris) {
      final Map<String, dynamic>? contenu = contenus[id];
      expect(contenu, isNotNull, reason: '$id est introuvable ou non jouable');
      for (final dynamic brute in contenu!['lessons'] as List<dynamic>) {
        final Map<String, dynamic> lecon = brute as Map<String, dynamic>;
        final List<dynamic> cartes = lecon['cards'] as List<dynamic>;
        final Iterable<String> genres = cartes.map(
          (dynamic c) => (c as Map<String, dynamic>)['kind'] as String,
        );
        expect(genres, contains('figure'),
            reason: '$id / ${lecon['id']} n’a aucune figure');
        expect(genres.first, 'figure',
            reason: '$id / ${lecon['id']} commence par du texte');
      }
    }
  });

  test('la part de cartes figure ne recule pas', () {
    int figures = 0;
    int total = 0;
    for (final Map<String, dynamic> contenu in contenus.values) {
      for (final dynamic brute in contenu['lessons'] as List<dynamic>) {
        for (final dynamic c in (brute as Map<String, dynamic>)['cards']
            as List<dynamic>) {
          total++;
          if ((c as Map<String, dynamic>)['kind'] == 'figure') figures++;
        }
      }
    }
    expect(total, greaterThan(0));
    expect(figures / total, greaterThanOrEqualTo(partMinimale),
        reason: 'part actuelle : ${(figures / total * 100).toStringAsFixed(1)} %, '
            'plancher : ${(partMinimale * 100).toStringAsFixed(0)} %');
  });

  test('toute figure citée est pilotable par l’élève', () {
    // Une figure que l'élève regarde sans pouvoir agir dessus vaut mieux
    // qu'un paragraphe, et moins qu'une figure qu'il manipule. On vérifie
    // que le code de chaque figure expose au moins une commande.
    final RegExp commande = RegExp(
      r'\bSlider\b|\bChoiceChip\b|GestureDetector|onPressed:|onTap:',
    );
    final Directory dossier = Directory('lib/design_system/figures');
    final List<File> sources = dossier
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('_figure.dart'))
        .toList();
    expect(sources, isNotEmpty);
    for (final File f in sources) {
      expect(commande.hasMatch(f.readAsStringSync()), isTrue,
          reason: '${f.uri.pathSegments.last} n’offre aucune commande');
    }
  });
}
