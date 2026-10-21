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



  /// Part minimale de cartes « figure » sur l'ensemble du contenu.
  ///
  /// On la relève à chaque lot converti. Elle ne descend pas : un chapitre
  /// qu'on ajoute sans figure fait tomber la moyenne, et le test le dit.
  const double partMinimale = 0.235;

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

  test('chaque leçon ouvre sur une figure', () {
    // La règle du chapitre 3 de CONTENT_AUTHORING : montrer, puis dire.
    // Une leçon qui commence par un paragraphe demande à l’élève de lire
    // avant d’avoir rien vu, et c’est exactement ce qu’on a corrigé.
    final List<String> parDuTexte = <String>[];
    for (final Map<String, dynamic> c in chapitres) {
      final String id = c['id'] as String;
      for (final dynamic brute in contenus[id]!['lessons'] as List<dynamic>) {
        final Map<String, dynamic> lecon = brute as Map<String, dynamic>;
        final List<dynamic> cartes = lecon['cards'] as List<dynamic>;
        if (cartes.isEmpty) continue;
        final String premier =
            (cartes.first as Map<String, dynamic>)['kind'] as String;
        if (premier != 'figure') parDuTexte.add('$id/${lecon['id']}');
      }
    }
    expect(parDuTexte, isEmpty,
        reason: 'ces leçons commencent par du texte : $parDuTexte');
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
