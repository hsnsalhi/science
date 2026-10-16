import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie que tout le texte embarqué peut réellement s'afficher.
///
/// Les polices du projet ne couvrent pas tout Unicode. Un caractère absent
/// ne provoque aucune erreur : il est dessiné comme un rectangle vide, chez
/// l'élève, et nulle part ailleurs. Ni l'analyseur, ni les tests de
/// contenu, ni une relecture attentive ne l'attrapent — la flèche « → »
/// est parfaitement lisible dans l'éditeur.
///
/// Ce test lit la table de correspondance des polices elles-mêmes et
/// confronte chaque caractère du contenu à ce qu'elles savent dessiner.
/// C'est la seule façon de rendre le défaut visible avant publication.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Les points de code qu'une police sait dessiner, lus dans sa table
  /// `cmap`. Les formats 4 (plan de base) et 12 (plans étendus) suffisent
  /// aux polices du projet.
  Set<int> pointsDeCode(ByteData police) {
    final ByteData d = police;
    final int tables = d.getUint16(4);
    int? cmap;
    for (int i = 0; i < tables; i++) {
      final int entree = 12 + 16 * i;
      final String tag = String.fromCharCodes(
        Uint8List.view(d.buffer, d.offsetInBytes + entree, 4),
      );
      if (tag == 'cmap') cmap = d.getUint32(entree + 8);
    }
    expect(cmap, isNotNull, reason: 'police sans table cmap');

    final Set<int> couverts = <int>{};
    final int sousTables = d.getUint16(cmap! + 2);
    for (int i = 0; i < sousTables; i++) {
      final int depart = cmap + 4 + 8 * i;
      final int debut = cmap + d.getUint32(depart + 4);
      final int format = d.getUint16(debut);
      if (format == 4) {
        final int segments = d.getUint16(debut + 6) ~/ 2;
        for (int s = 0; s < segments; s++) {
          final int fin = d.getUint16(debut + 14 + 2 * s);
          final int premier = d.getUint16(debut + 16 + 2 * segments + 2 * s);
          if (fin == 0xFFFF) continue;
          for (int c = premier; c <= fin; c++) {
            couverts.add(c);
          }
        }
      } else if (format == 12) {
        final int groupes = d.getUint32(debut + 12);
        for (int g = 0; g < groupes; g++) {
          final int entree = debut + 16 + 12 * g;
          final int premier = d.getUint32(entree);
          final int fin = d.getUint32(entree + 4);
          for (int c = premier; c <= fin && c - premier < 5000; c++) {
            couverts.add(c);
          }
        }
      }
    }
    return couverts;
  }

  late Set<int> nunito;

  setUpAll(() async {
    nunito = pointsDeCode(await rootBundle.load('assets/fonts/Nunito.ttf'));
  });

  test('la police du corps de texte couvre un alphabet crédible', () {
    // Garde-fou sur la lecture elle-même : si l'analyse de la table
    // échouait, l'ensemble serait vide et le test suivant passerait sans
    // rien vérifier.
    for (final String c in <String>['a', 'É', 'ç', '²', '×', '−', '≤', '√']) {
      expect(
        nunito,
        contains(c.runes.first),
        reason: 'le caractère « $c » devrait être couvert',
      );
    }
    expect(nunito.length, greaterThan(300));
  });

  test('tout le contenu s’affiche avec la police du corps de texte', () async {
    // La liste des fichiers vient du catalogue lui-même : c'est
    // exactement ce qui est embarqué et lu par l'application.
    const String catalogue = 'assets/content/catalog.json';
    final Map<String, dynamic> racine =
        json.decode(await rootBundle.loadString(catalogue))
            as Map<String, dynamic>;
    final List<String> fichiers = <String>[
      catalogue,
      for (final dynamic chapitre in racine['chapters'] as List<dynamic>)
        if ((chapitre as Map<String, dynamic>)['content'] is String)
          'assets/content/${chapitre['content']}',
    ]..sort();
    expect(
      fichiers.length,
      greaterThan(10),
      reason: 'le catalogue ne pointe sur presque aucun contenu',
    );

    final Map<String, Set<String>> absents = <String, Set<String>>{};
    for (final String chemin in fichiers) {
      final String texte = await rootBundle.loadString(chemin);
      for (final int point in texte.runes) {
        if (point < 128 || nunito.contains(point)) continue;
        absents
            .putIfAbsent(chemin.split('/').last, () => <String>{})
            .add(
              '${String.fromCharCode(point)} '
              '(U+${point.toRadixString(16).toUpperCase().padLeft(4, '0')})',
            );
      }
    }

    expect(
      absents,
      isEmpty,
      reason:
          'ces caractères seront dessinés en rectangles vides :\n'
          '${absents.entries.map((MapEntry<String, Set<String>> e) => '  ${e.key} : ${e.value.join(', ')}').join('\n')}',
    );
  });

  test('les textes écrits en Dart s’affichent aussi', () {
    // Le contenu n'est pas la seule source de texte : les libellés de
    // l'interface et les légendes des figures sont écrits en Dart. Les
    // lignes de commentaire sont écartées — elles ne s'affichent nulle
    // part, et c'est là que les caractères manquants sont justement
    // documentés.
    final Map<String, Set<String>> absents = <String, Set<String>>{};
    for (final FileSystemEntity entite
        in Directory('lib').listSync(recursive: true)) {
      if (entite is! File || !entite.path.endsWith('.dart')) continue;
      final List<String> lignes = entite.readAsLinesSync();
      for (int i = 0; i < lignes.length; i++) {
        final String ligne = lignes[i];
        if (ligne.trimLeft().startsWith('//')) continue;
        for (final int point in ligne.runes) {
          if (point < 128 || nunito.contains(point)) continue;
          absents
              .putIfAbsent('${entite.path}:${i + 1}', () => <String>{})
              .add(
                '${String.fromCharCode(point)} '
                '(U+${point.toRadixString(16).toUpperCase().padLeft(4, '0')})',
              );
        }
      }
    }

    expect(
      absents,
      isEmpty,
      reason:
          'ces caractères seront dessinés en rectangles vides :\n'
          '${absents.entries.map((MapEntry<String, Set<String>> e) => '  ${e.key} : ${e.value.join(', ')}').join('\n')}',
    );
  });
}
