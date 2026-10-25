import 'package:eureka/core/motion/app_motion.dart';
import 'package:eureka/core/theme/app_theme.dart';
import 'package:eureka/design_system/figures/autoplay.dart';
import 'package:eureka/design_system/figures/figure_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mesure combien de figures bougent toutes seules dans le fil.
///
/// Le format en fil tient une promesse : aucun écran immobile. Elle se
/// tient de deux façons — une figure peut porter sa propre animation
/// (une orbite qui tourne, une onde qui avance), ou se laisser piloter
/// par l'horloge de la scène (un curseur qui balaie).
///
/// Ce test compte les secondes, celles qui réagissent à l'horloge, et
/// nomme les figures qui n'y réagissent pas encore. Le seuil ne peut que
/// monter : il rend le travail restant visible dans le code au lieu de le
/// laisser dans une tête.
void main() {
  /// Les figures qui portent leur propre animation, vérifiée à la main.
  ///
  /// Elles tournent, avancent ou se désintègrent sans qu'on les touche,
  /// donc l'horloge de la scène n'a rien à leur apporter. Elles sont
  /// listées ici parce qu'un test ne peut pas distinguer un dessin animé
  /// d'un dessin fixe sans comparer des pixels, ce qui coûterait plus
  /// qu'il ne rapporte.
  const Set<String> animeesSeules = <String>{
    'orbites',
    'phases-lune',
    'retrogradation',
    'rutherford',
    'modeles-atome',
    'vitesse',
    'boucle-robot',
    'reseau-paquet',
    'pythagore-preuve',
    'fil-qui-casse',
    'approvisionnement',
  };

  /// Rend une figure à une phase donnée et renvoie son état visible.
  ///
  /// On concatène les étiquettes et les valeurs de curseur : c'est ce qui
  /// change quand une figure est pilotée, et cela suffit à distinguer
  /// « elle a bougé » de « elle n'a pas bougé ».
  Future<String> rendre(
    WidgetTester tester,
    String id,
    double phase,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AppMotion(
          reduceMotionPreference: false,
          hapticsEnabled: false,
          child: Scaffold(
            body: SingleChildScrollView(
              child: Builder(
                builder: (BuildContext context) => FigureStage(
                  phase: phase,
                  actif: true,
                  child: SizedBox(
                    width: 360,
                    child: FigureRegistry.build(
                      context,
                      id,
                      const Color(0xFF5B5BD6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // On ratisse large : beaucoup de figures ne changent aucun texte en
    // bougeant — elles rallument une puce, soulignent un nœud, déplacent
    // un trait. Les étiquettes d'accessibilité et l'état des puces de
    // choix rattrapent une partie de ces cas ; un dessin qui ne change
    // que ses pixels reste indétectable ainsi, et c'est pourquoi la
    // liste « animées d'elles-mêmes » existe.
    final String textes = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text t) => t.data ?? '')
        .join('|');
    final String curseurs = tester
        .widgetList<Slider>(find.byType(Slider))
        .map((Slider s) => s.value.toStringAsFixed(3))
        .join(',');
    final String puces = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .map((ChoiceChip c) => c.selected ? '1' : '0')
        .join();
    final String actions = tester
        .widgetList<ActionChip>(find.byType(ActionChip))
        .map((ActionChip c) => '${c.backgroundColor}')
        .join(',');
    final String semantiques = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .map((Semantics w) => w.properties.label ?? '')
        .where((String l) => l.isNotEmpty)
        .join('|');
    return '$textes##$curseurs##$puces##$actions##$semantiques';
  }

  testWidgets('le compte des figures qui bougent seules', (
    WidgetTester tester,
  ) async {
    final List<String> pilotees = <String>[];
    final List<String> fixes = <String>[];

    for (final String id in FigureRegistry.ids) {
      // Trois instants du cycle : une figure peut être au même point au
      // début et au milieu si son balayage fait deux allers-retours.
      final String a = await rendre(tester, id, 0);
      final String b = await rendre(tester, id, 0.33);
      final String c = await rendre(tester, id, 0.66);
      if (a != b || b != c || a != c) {
        pilotees.add(id);
      } else if (!animeesSeules.contains(id)) {
        fixes.add(id);
      }
    }

    final int total = FigureRegistry.ids.length;
    final int mouvantes = pilotees.length + animeesSeules.length;
    fixes.sort();

    // Le compte rendu part dans la sortie du test : c'est la liste de ce
    // qui reste à faire, tenue à jour par la machine et non par un
    // document qui vieillit.
    debugPrint(
      'Figures : $total au total, $mouvantes qui bougent seules '
      '(${pilotees.length} pilotées par l’horloge, '
      '${animeesSeules.length} animées d’elles-mêmes).\n'
      'Encore fixes (${fixes.length}) : ${fixes.join(', ')}',
    );

    // Les figures déclarées « animées d'elles-mêmes » doivent exister :
    // une faute de frappe dans la liste gonflerait le compte sans rien
    // animer.
    for (final String id in animeesSeules) {
      expect(
        FigureRegistry.ids,
        contains(id),
        reason: '« $id » est listée comme animée mais n’existe pas',
      );
    }

    // Seuil : il monte à chaque figure câblée, et ne redescend jamais
    // sans qu'un test échoue.
    //
    // Soixante-huit sur soixante-neuf. La dernière, « suite-motifs »,
    // est volontairement fixe : elle pose une question et attend une
    // réponse, et faire défiler le motif retirerait l'exercice des
    // mains de l'élève. Le seuil tient compte de cette exception, et
    // d'elle seule.
    expect(
      mouvantes,
      greaterThanOrEqualTo(68),
      reason: 'figures encore fixes : ${fixes.join(', ')}',
    );
    expect(
      fixes,
      <String>['suite-motifs'],
      reason: 'la seule figure fixe acceptée est l’exercice de motifs',
    );
  });

  testWidgets('aucune figure ne casse sous le pilotage', (
    WidgetTester tester,
  ) async {
    // L'horloge fait prendre aux figures des valeurs qu'un élève
    // n'atteindrait qu'en poussant les curseurs à fond. Ce test les y
    // pousse toutes, à plusieurs instants, et vérifie qu'aucune ne lève
    // d'exception : division par zéro, racine d'un négatif, index hors
    // bornes.
    for (final String id in FigureRegistry.ids) {
      for (final double phase in <double>[0, 0.17, 0.5, 0.83, 0.99]) {
        await rendre(tester, id, phase);
        expect(
          tester.takeException(),
          isNull,
          reason: '« $id » a échoué à la phase $phase',
        );
      }
    }
  });
}
