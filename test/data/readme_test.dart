import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le README annonce des nombres ; ils doivent rester vrais.
///
/// Ces compteurs ont déjà vieilli une fois en silence : le README parlait de
/// 59 chapitres et 43 figures alors qu'il y en avait 66 et 50. Personne ne
/// relit un tableau de chiffres, et un chiffre faux dans un README est la
/// première chose qu'un visiteur peut vérifier. Ce test les recompte depuis
/// le contenu, de sorte que la prochaine dérive casse la suite au lieu de
/// passer inaperçue.
///
/// Il ne vérifie pas que les nombres sont beaux, seulement qu'ils sont
/// exacts : écrire un chapitre oblige donc à toucher au README, ce qui est
/// le but.
void main() {
  late String readme;
  late int chapitres;
  late int figures;
  // Ces trois-là s'accumulent dans la boucle, donc elles partent de zéro
  // plutôt que d'être `late` : un `late int` ne se laisse pas incrémenter.
  int lecons = 0;
  int cartes = 0;
  int questions = 0;

  setUpAll(() {
    readme = File('README.md').readAsStringSync();

    final List<File> fichiers =
        Directory('assets/content/chapters')
            .listSync()
            .whereType<File>()
            .where((File f) => f.path.endsWith('.json'))
            .toList(growable: false);
    chapitres = fichiers.length;
    for (final File f in fichiers) {
      final Map<String, Object?> json =
          jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      for (final Object? brut in json['lessons']! as List<Object?>) {
        final Map<String, Object?> lecon = brut! as Map<String, Object?>;
        lecons++;
        cartes += (lecon['cards'] as List<Object?>? ?? const <Object?>[])
            .length;
        questions +=
            (lecon['questions'] as List<Object?>? ?? const <Object?>[])
                .length;
      }
    }

    // Les clés du registre, qui sont ce que le contenu peut citer — et donc
    // le nombre de figures réellement disponibles.
    final String registre =
        File('lib/design_system/figures/figure_registry.dart')
            .readAsStringSync();
    figures = RegExp(r"^    '[a-z0-9-]+':", multiLine: true)
        .allMatches(registre)
        .length;
  });

  /// Le README contient-il ce nombre, écrit à la française ?
  ///
  /// Les milliers y sont séparés par une espace insécable fine ou normale
  /// selon les lignes ; on accepte les deux plutôt que d'imposer une forme.
  bool mentionne(int valeur) {
    final String brut = valeur.toString();
    final List<String> formes = <String>[brut];
    if (brut.length > 3) {
      final String milliers = brut.substring(0, brut.length - 3);
      final String reste = brut.substring(brut.length - 3);
      for (final String espace in <String>[' ', ' ', ' ', '']) {
        formes.add('$milliers$espace$reste');
      }
    }
    return formes.any(readme.contains);
  }

  test('le compte de chapitres est exact', () {
    expect(chapitres, greaterThan(0));
    expect(
      mentionne(chapitres),
      isTrue,
      reason: 'le README doit annoncer $chapitres chapitres',
    );
  });

  test('les comptes de leçons, cartes et questions sont exacts', () {
    for (final (String nom, int valeur) in <(String, int)>[
      ('leçons', lecons),
      ('cartes', cartes),
      ('questions', questions),
    ]) {
      expect(
        mentionne(valeur),
        isTrue,
        reason: 'le README doit annoncer $valeur $nom',
      );
    }
  });

  test('le compte de figures est exact', () {
    expect(figures, greaterThan(0));
    expect(
      mentionne(figures),
      isTrue,
      reason: 'le README doit annoncer $figures figures',
    );
  });

  test('le catalogue annonce bien 230 chapitres', () {
    final Map<String, Object?> catalogue = jsonDecode(
      File('assets/content/catalog.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final int total = (catalogue['chapters']! as List<Object?>).length;
    expect(
      mentionne(total),
      isTrue,
      reason: 'le README doit annoncer $total chapitres au catalogue',
    );
  });

  test('le nombre de chapitres « disponible » égale le nombre de fichiers',
      () {
    // Un chapitre rédigé mais oublié au catalogue serait invisible dans
    // l'application ; un chapitre « disponible » sans fichier la ferait
    // échouer au chargement. Les deux comptes doivent coïncider.
    final Map<String, Object?> catalogue = jsonDecode(
      File('assets/content/catalog.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final int disponibles = (catalogue['chapters']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .where((Map<String, Object?> c) => c['status'] == 'disponible')
        .length;
    expect(disponibles, chapitres);
  });
}
