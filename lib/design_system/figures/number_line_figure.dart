/// Une droite graduée, pour additionner des nombres relatifs.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Un point de départ, un déplacement, et le point d'arrivée.
///
/// Additionner un nombre négatif est une opération que l'écriture rend
/// obscure — (−3) + (−4) ressemble à deux soustractions et donne
/// pourtant une addition de dettes. Sur une droite graduée, il n'y a
/// plus de signes à interpréter : on part d'un point, on se déplace vers
/// la gauche ou vers la droite, et on lit où l'on arrive.
///
/// La soustraction y devient un simple changement de sens, ce qui est la
/// seule justification honnête de « moins par moins donne plus » à ce
/// niveau : reculer d'un recul, c'est avancer.
class NumberLineFigure extends StatefulWidget {
  const NumberLineFigure({required this.accent, super.key});

  final Color accent;

  /// Bornes de la droite affichée.
  static const int minimum = -12;
  static const int maximum = 12;

  /// Point d'arrivée après un déplacement.
  static int arrivee(int depart, int deplacement) => depart + deplacement;

  /// L'opération écrite comme on l'écrit au tableau.
  ///
  /// Un nombre négatif s'entoure de parenthèses dès qu'il suit un
  /// signe : « 3 + (−4) », jamais « 3 + −4 ».
  static String ecriture(int depart, int deplacement) {
    final String gauche = depart < 0 ? '($depart)' : '$depart';
    final String droite =
        deplacement < 0 ? '(${deplacement.abs() * -1})' : '$deplacement';
    return '$gauche + $droite = ${arrivee(depart, deplacement)}';
  }

  @override
  State<NumberLineFigure> createState() => _NumberLineFigureState();
}

class _NumberLineFigureState extends State<NumberLineFigure> {
  int _depart = 3;
  int _deplacement = -7;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final int arrivee = NumberLineFigure.arrivee(_depart, _deplacement);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 112,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints contraintes) {
              return CustomPaint(
                size: Size(contraintes.maxWidth, 112),
                painter: _DroitePainter(
                  depart: _depart,
                  deplacement: _deplacement,
                  accent: widget.accent,
                  ink: context.colors.onSurface,
                  trait: tokens.border,
                  muted: tokens.inkMuted,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          NumberLineFigure.ecriture(_depart, _deplacement),
          style: AppTypography.formula(size: 19, color: widget.accent),
        ),
        Text(
          _deplacement < 0
              ? 'Ajouter un nombre négatif, c\'est reculer de '
                    '${NumericQuestion.formatNumber(
                      _deplacement.abs().toDouble(),
                    )}.'
              : 'Ajouter un nombre positif, c\'est avancer de '
                    '${NumericQuestion.formatNumber(
                      _deplacement.toDouble(),
                    )}.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        _Reglage(
          nom: 'départ',
          valeur: _depart,
          accent: widget.accent,
          onChanged: (int v) => setState(() => _depart = v),
        ),
        _Reglage(
          nom: 'déplacement',
          valeur: _deplacement,
          accent: widget.accent,
          onChanged: (int v) => setState(() => _deplacement = v),
        ),
        Text(
          'Arrivée : $arrivee',
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

class _Reglage extends StatelessWidget {
  const _Reglage({
    required this.nom,
    required this.valeur,
    required this.accent,
    required this.onChanged,
  });

  final String nom;
  final int valeur;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 86,
          child: Text(
            nom,
            style: context.text.labelSmall?.copyWith(
              color: context.tokens.inkSubtle,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: valeur.toDouble(),
            min: -10,
            max: 10,
            divisions: 20,
            onChanged: (double v) {
              context.tapFeedback();
              onChanged(v.round());
            },
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$valeur',
            textAlign: TextAlign.right,
            style: AppTypography.formula(size: 15, color: accent),
          ),
        ),
      ],
    );
  }
}

class _DroitePainter extends CustomPainter {
  const _DroitePainter({
    required this.depart,
    required this.deplacement,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
  });

  final int depart;
  final int deplacement;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    const double marge = 12;
    const int etendue = NumberLineFigure.maximum - NumberLineFigure.minimum;
    final double pas = (size.width - marge * 2) / etendue;
    final double y = size.height * 0.68;

    double x(int valeur) => marge + (valeur - NumberLineFigure.minimum) * pas;

    canvas.drawLine(
      Offset(marge, y),
      Offset(size.width - marge, y),
      Paint()
        ..color = ink.withValues(alpha: 0.65)
        ..strokeWidth = 2,
    );

    for (int v = NumberLineFigure.minimum; v <= NumberLineFigure.maximum; v++) {
      final bool marque = v % 2 == 0;
      canvas.drawLine(
        Offset(x(v), y - (marque ? 6 : 3)),
        Offset(x(v), y + (marque ? 6 : 3)),
        Paint()
          ..color = v == 0 ? ink : trait
          ..strokeWidth = v == 0 ? 2 : 1,
      );
      if (marque) {
        _texte(canvas, '$v', Offset(x(v), y + 18), v == 0 ? ink : muted);
      }
    }

    // La flèche du déplacement, posée au-dessus de la droite pour ne pas
    // cacher les graduations qu'il faut lire.
    final int arrivee = NumberLineFigure.arrivee(depart, deplacement);
    final double hauteur = y - 26;
    if (deplacement != 0) {
      final Path arc = Path()
        ..moveTo(x(depart), y - 9)
        ..quadraticBezierTo(
          (x(depart) + x(arrivee)) / 2,
          hauteur - 14,
          x(arrivee),
          y - 9,
        );
      canvas.drawPath(
        arc,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = accent,
      );
      final double sens = deplacement > 0 ? 1 : -1;
      for (final double ecart in <double>[2.4, -2.4]) {
        final double angle = sens > 0 ? 0.9 : math.pi - 0.9;
        canvas.drawLine(
          Offset(x(arrivee), y - 9),
          Offset(x(arrivee), y - 9) +
              Offset(math.cos(angle + ecart), math.sin(angle + ecart)) * 9,
          Paint()
            ..color = accent
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
      _texte(
        canvas,
        deplacement > 0 ? '+$deplacement' : '$deplacement',
        Offset((x(depart) + x(arrivee)) / 2, hauteur - 14),
        accent,
        gras: true,
      );
    }

    // Les deux points, départ creux et arrivée pleine.
    canvas.drawCircle(
      Offset(x(depart), y),
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = muted,
    );
    canvas.drawCircle(Offset(x(arrivee), y), 6, Paint()..color = accent);
  }

  void _texte(
    Canvas canvas,
    String texte,
    Offset centre,
    Color couleur, {
    bool gras = false,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontFamilyFallback: AppTypography.replis,
          color: couleur,
          fontSize: gras ? 14 : 10,
          fontWeight: gras ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      centre - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_DroitePainter old) =>
      old.depart != depart ||
      old.deplacement != deplacement ||
      old.accent != accent;
}
