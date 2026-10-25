/// Découpage d'une leçon en plans, pour la lecture en fil vertical.
library;

import '../models/lesson.dart';

/// Nature d'un plan, qui décide de sa mise en scène.
enum BeatKind {
  /// Titre de carte, seul sur l'écran, par-dessus la figure.
  ouverture,

  /// Une phrase d'explication — un paragraphe du corps, jamais plus.
  propos,

  /// Une formule, en grand.
  formule,

  /// Un point de liste.
  point,

  /// L'appel à passer aux exercices, en fin de leçon.
  sortie,
}

/// Un plan : un visuel qui bouge, et au plus quelques lignes par-dessus.
///
/// C'est l'unité du fil. Un plan n'a jamais plus d'une idée, parce qu'un
/// plan n'occupe l'écran que le temps d'un geste du pouce.
class ReelBeat {
  const ReelBeat({
    required this.id,
    required this.kind,
    required this.cardIndex,
    this.figureId,
    this.kicker,
    this.text,
    this.formula,
    this.cardKind,
    this.stepNumber,
  });

  /// Clé stable : survit à un changement d'ordre, sert aux animations.
  final String id;

  final BeatKind kind;

  /// Rang de la carte d'origine. Deux plans de même rang partagent la
  /// même figure, qui n'est donc pas remontée entre eux : elle continue
  /// de jouer pendant que les légendes défilent.
  final int cardIndex;

  /// Figure à l'affiche. Jamais nulle en pratique : un plan dont la carte
  /// ne porte pas de figure hérite de la dernière vue dans la leçon.
  final String? figureId;

  /// Titre de la carte, rappelé en surtitre.
  final String? kicker;

  /// Le texte du plan. Au plus un paragraphe.
  final String? text;

  /// Formule en notation Unicode, pour un plan de type formule.
  final String? formula;

  /// Type de la carte d'origine, pour l'étiquette et la couleur d'alerte.
  final LessonCardKind? cardKind;

  /// Rang de l'étape, quand la carte d'origine en est une.
  final int? stepNumber;
}

/// Découpe une leçon en plans.
///
/// Trois règles, et elles portent tout le format :
///
/// 1. **Un paragraphe, un plan.** Les corps de carte sont écrits en
///    paragraphes séparés par une ligne vide, et chaque paragraphe porte
///    déjà une seule idée. Les présenter l'un après l'autre ne demande
///    donc aucune réécriture du contenu : le découpage existait, c'est
///    l'affichage qui l'ignorait.
/// 2. **La figure ne s'arrête jamais.** Une carte sans figure reprend la
///    dernière à l'affiche. Comme la première carte de chaque leçon est
///    une figure, le fil n'a aucun écran sans mouvement.
/// 3. **Une formule mérite son plan.** Noyée sous un paragraphe, elle se
///    lit comme une illustration ; seule à l'écran, elle se lit comme un
///    résultat.
abstract final class LessonReel {
  /// Longueur au-delà de laquelle un paragraphe est recoupé par phrases.
  ///
  /// Quelques paragraphes du corpus tiennent une idée en deux phrases
  /// longues. Au-delà de cette taille, le plan redevient un pavé : on
  /// recoupe à la frontière de phrase la plus proche du milieu.
  static const int tailleMax = 260;

  static List<ReelBeat> of(Lesson lesson) {
    final List<ReelBeat> beats = <ReelBeat>[];
    String? figureEnCours;
    int etapes = 0;

    for (int i = 0; i < lesson.cards.length; i++) {
      final LessonCard card = lesson.cards[i];
      if (card.figureId != null) figureEnCours = card.figureId;
      if (card.kind == LessonCardKind.etape) etapes++;

      final String prefixe = '${lesson.id}/${card.id}';
      int n = 0;
      ReelBeat beat(BeatKind kind, {String? text, String? formula}) {
        return ReelBeat(
          id: '$prefixe#${n++}',
          kind: kind,
          cardIndex: i,
          figureId: figureEnCours,
          kicker: card.title,
          text: text,
          formula: formula,
          cardKind: card.kind,
          stepNumber: card.kind == LessonCardKind.etape ? etapes : null,
        );
      }

      // Le titre ouvre la carte, seul à l'écran. C'est le battement qui
      // dit « nouvelle idée » sans qu'on ait à l'écrire.
      if (card.title != null) {
        beats.add(beat(BeatKind.ouverture, text: card.title));
      }
      for (final String p in paragraphes(card.body)) {
        beats.add(beat(BeatKind.propos, text: p));
      }
      if (card.formula != null) {
        beats.add(beat(BeatKind.formule, formula: card.formula));
      }
      for (final String b in card.bullets) {
        beats.add(beat(BeatKind.point, text: b));
      }
    }

    beats.add(
      ReelBeat(
        id: '${lesson.id}#fin',
        kind: BeatKind.sortie,
        cardIndex: lesson.cards.length,
        figureId: figureEnCours,
        text: lesson.hasQuiz
            ? 'À toi de jouer.'
            : 'Leçon terminée. Beau travail.',
      ),
    );
    return beats;
  }

  /// Les paragraphes d'un corps, recoupés si l'un dépasse [tailleMax].
  static List<String> paragraphes(String? body) {
    if (body == null) return const <String>[];
    final List<String> brut = body
        .split(RegExp(r'\n\s*\n'))
        .map((String p) => p.trim().replaceAll(RegExp(r'\s*\n\s*'), ' '))
        .where((String p) => p.isNotEmpty)
        .toList();
    final List<String> sortie = <String>[];
    for (final String p in brut) {
      sortie.addAll(_recouper(p));
    }
    return sortie;
  }

  /// Frontières de coupe, par ordre de préférence.
  ///
  /// La fin de phrase d'abord : couper là ne change rien à la lecture. À
  /// défaut, une frontière de proposition — point-virgule, tiret cadratin,
  /// deux-points. Une seule phrase très longue se lit alors en deux plans
  /// au lieu d'un pavé, et la coupure tombe là où la voix s'arrêterait.
  static final List<RegExp> _frontieres = <RegExp>[
    RegExp(r'[.!?…]["»”]?\s+'),
    RegExp(r';\s+'),
    RegExp(r'\s—\s'),
    RegExp(r':\s+'),
  ];

  /// Recoupe un paragraphe trop long à la frontière la plus proche du
  /// milieu, et récursivement si les moitiés restent longues.
  static List<String> _recouper(String p) {
    if (p.length <= tailleMax) return <String>[p];
    List<int> coupes = const <int>[];
    for (final RegExp frontiere in _frontieres) {
      final List<int> trouvees = <int>[
        for (final RegExpMatch m in frontiere.allMatches(p))
          if (m.end >= 40 && m.end <= p.length - 40) m.end,
      ];
      if (trouvees.isNotEmpty) {
        coupes = trouvees;
        break;
      }
    }
    if (coupes.isEmpty) return <String>[p];
    final int milieu = p.length ~/ 2;
    int meilleure = coupes.first;
    for (final int c in coupes) {
      if ((c - milieu).abs() < (meilleure - milieu).abs()) meilleure = c;
    }
    return <String>[
      ..._recouper(p.substring(0, meilleure).trim()),
      ..._recouper(p.substring(meilleure).trim()),
    ];
  }
}
