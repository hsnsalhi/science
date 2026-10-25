/// Des particules qui se répartissent, et l'irréversibilité.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';

/// Un gaz qui envahit la seconde moitié d'une boîte, et n'en revient pas.
///
/// Le second principe s'énonce d'ordinaire comme une interdiction, et
/// l'élève en retient que « la chaleur ne remonte pas ». Rien, pourtant,
/// n'interdit aux particules de revenir toutes à gauche : les lois du
/// mouvement sont réversibles, et chaque configuration est aussi probable
/// qu'une autre.
///
/// Ce qui change, c'est le nombre de configurations. Une seule les met
/// toutes à gauche ; il y en a des centaines de millions qui les
/// répartissent à peu près également. L'irréversibilité n'est pas une
/// interdiction, c'est un écart de dénombrement — et la figure le montre
/// en affichant la probabilité du retour, qui s'effondre dès quelques
/// dizaines de particules.
///
/// Le modèle est celui d'Ehrenfest : à chaque instant, une particule tirée
/// au hasard change de côté. Il est volontairement réversible, pour qu'on
/// ne puisse pas attribuer l'irréversibilité observée à une règle cachée.
class EntropyFigure extends StatefulWidget {
  const EntropyFigure({required this.accent, super.key});

  final Color accent;

  /// Nombre de particules dans la boîte.
  static const int particules = 24;

  /// La graine du tirage : la figure doit se rejouer à l'identique.
  static const int graine = 7;

  /// La configuration après [etape] instants, `true` pour « à gauche ».
  ///
  /// Toutes les particules commencent à gauche. À chaque instant, une
  /// particule tirée au hasard change de côté.
  static List<bool> configuration(int etape) {
    final List<bool> cote = List<bool>.filled(particules, true);
    final math.Random tirage = math.Random(graine);
    for (int i = 0; i < etape; i++) {
      final int choisie = tirage.nextInt(particules);
      cote[choisie] = !cote[choisie];
    }
    return cote;
  }

  /// Le nombre de particules à gauche après [etape] instants.
  static int aGauche(int etape) =>
      configuration(etape).where((bool g) => g).length;

  /// La probabilité que [n] particules se retrouvent toutes à gauche.
  ///
  /// Chaque particule est d'un côté ou de l'autre, indépendamment : il y a
  /// deux puissance n configurations, et une seule les met toutes à
  /// gauche.
  static double probabiliteToutesAGauche(int n) => math.pow(0.5, n).toDouble();

  /// Le nombre de configurations possibles pour [n] particules.
  static double configurations(int n) => math.pow(2, n).toDouble();

  @override
  State<EntropyFigure> createState() => _EntropyFigureState();
}

class _EntropyFigureState extends State<EntropyFigure> {
  int _etape = 0;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  void _avancer(int pas) => setState(() {
    _tenue = true;
    _etape += pas;
  });

  /// Écrit un grand nombre avec des espaces tous les trois chiffres.
  ///
  /// « 16777216 » ne se lit pas ; « 16 777 216 » se lit d'un coup d'œil,
  /// et c'est précisément l'ordre de grandeur que la leçon veut faire
  /// sentir.
  String _espace(double valeur) {
    final String chiffres = valeur.toStringAsFixed(0);
    final StringBuffer sortie = StringBuffer();
    for (int i = 0; i < chiffres.length; i++) {
      // Espace insécable U+00A0, et non l'espace fine U+202F : cette
      // dernière manque aux polices du projet et s'afficherait en carré.
      if (i > 0 && (chiffres.length - i) % 3 == 0) sortie.write('\u00a0');
      sortie.write(chiffres[i]);
    }
    return sortie.toString();
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // Les instants défilent de zéro à quarante : les particules partent
    // groupées et se répartissent, et ne reviennent jamais. C'est le sens
    // unique de l'entropie, et il faut le voir se produire.
    final double? montee = Autoplay.ramp(context, maintien: 0.15);
    final int etape = _tenue || montee == null
        ? _etape
        : (montee * 40).round();
    final List<bool> cote = EntropyFigure.configuration(etape);
    final int gauche = cote.where((bool g) => g).length;
    final double retour = EntropyFigure.probabiliteToutesAGauche(
      EntropyFigure.particules,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 2.8,
          child: CustomPaint(
            painter: _BoitePainter(
              cote: cote,
              accent: widget.accent,
              trait: tokens.border,
              surface: context.colors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$gauche à gauche, ${EntropyFigure.particules - gauche} à droite   '
          '(instant $etape)',
          style: AppTypography.formula(size: 15, color: widget.accent),
        ),
        SizedBox(
          height: 36,
          child: Text(
            gauche == EntropyFigure.particules
                ? 'Toutes à gauche : une seule configuration sur '
                      '${_espace(EntropyFigure.configurations(EntropyFigure.particules))}.'
                : 'Probabilité de les retrouver toutes à gauche : '
                      '1 sur ${_espace(EntropyFigure.configurations(EntropyFigure.particules))}.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: () {
                context.tapFeedback();
                _avancer(1);
              },
              icon: const Icon(Icons.skip_next_rounded, size: 18),
              label: const Text('Un instant'),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                context.tapFeedback();
                _avancer(20);
              },
              icon: const Icon(Icons.fast_forward_rounded, size: 18),
              label: const Text('Vingt instants'),
            ),
            TextButton.icon(
              onPressed: () {
                context.tapFeedback();
                setState(() {
                  _tenue = true;
                  _etape = 0;
                });
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Tout à gauche'),
            ),
          ],
        ),
        Text(
          'Rien n’interdit le retour : il est seulement improbable '
          '(${(retour * 100).toStringAsFixed(6).replaceAll('.', ',')} %).',
          textAlign: TextAlign.center,
          style: context.text.labelSmall?.copyWith(color: tokens.inkMuted),
        ),
      ],
    );
  }
}

class _BoitePainter extends CustomPainter {
  const _BoitePainter({
    required this.cote,
    required this.accent,
    required this.trait,
    required this.surface,
  });

  final List<bool> cote;
  final Color accent;
  final Color trait;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = surface);
    final Rect boite = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boite, const Radius.circular(8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = trait,
    );
    // La cloison retirée, en pointillé : elle rappelle d'où l'on part.
    for (double y = boite.top + 6; y < boite.bottom - 4; y += 10) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + 5),
        Paint()
          ..color = trait
          ..strokeWidth = 1.5,
      );
    }

    // Les particules, posées sur une grille propre à chaque moitié : une
    // disposition au hasard donnerait des amas trompeurs, qu'on lirait
    // comme une structure alors qu'il n'y en a aucune.
    final int parMoitie = cote.length;
    int rangGauche = 0;
    int rangDroite = 0;
    for (int i = 0; i < parMoitie; i++) {
      final bool aGauche = cote[i];
      final int rang = aGauche ? rangGauche++ : rangDroite++;
      final int colonne = rang % 4;
      final int ligne = rang ~/ 4;
      final double x =
          (aGauche ? boite.left + 14 : size.width / 2 + 14) + colonne * 18.0;
      final double y = boite.top + 14 + ligne * 16.0;
      if (y > boite.bottom - 8) continue;
      canvas.drawCircle(Offset(x, y), 5.5, Paint()..color = accent);
    }
  }

  @override
  bool shouldRepaint(_BoitePainter old) =>
      !identical(old.cote, cote) &&
      old.cote.toString() != cote.toString();
}
