/// Un circuit électrique à deux lampes, en série ou en dérivation.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Deux façons de brancher deux lampes, et ce qui les distingue.
///
/// La différence entre série et dérivation ne s'apprend pas en
/// regardant deux schémas : elle se voit en dévissant une lampe. En
/// série, l'autre s'éteint — le courant n'a qu'un chemin, et il est
/// coupé. En dérivation, l'autre reste allumée, puisqu'elle a le sien.
///
/// La figure permet donc trois gestes : ouvrir l'interrupteur, changer
/// de montage, dévisser une lampe. Le troisième est celui qui enseigne.
class CircuitFigure extends StatefulWidget {
  const CircuitFigure({required this.accent, super.key});

  final Color accent;

  /// Une lampe est-elle allumée ?
  ///
  /// En série, il faut que tout soit en place : un seul manque, et le
  /// circuit est ouvert. En dérivation, chaque lampe ne dépend que
  /// d'elle-même et de l'interrupteur.
  static bool allumee({
    required bool ferme,
    required bool serie,
    required bool presenteIci,
    required bool presenteAilleurs,
  }) {
    if (!ferme || !presenteIci) return false;
    return serie ? presenteAilleurs : true;
  }

  @override
  State<CircuitFigure> createState() => _CircuitFigureState();
}

class _CircuitFigureState extends State<CircuitFigure> {
  bool _ferme = true;
  bool _serie = true;
  bool _lampe1 = true;
  bool _lampe2 = true;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool allumee1 = CircuitFigure.allumee(
      ferme: _ferme,
      serie: _serie,
      presenteIci: _lampe1,
      presenteAilleurs: _lampe2,
    );
    final bool allumee2 = CircuitFigure.allumee(
      ferme: _ferme,
      serie: _serie,
      presenteIci: _lampe2,
      presenteAilleurs: _lampe1,
    );

    final String commentaire;
    if (!_ferme) {
      commentaire = 'Interrupteur ouvert : le courant ne passe nulle part.';
    } else if (_lampe1 && _lampe2) {
      commentaire = _serie
          ? 'En série, les deux lampes brillent faiblement : elles se '
                'partagent la tension.'
          : 'En dérivation, chaque lampe reçoit toute la tension du '
                'générateur.';
    } else {
      commentaire = _serie
          ? 'En série, dévisser une lampe coupe le seul chemin : l\'autre '
                's\'éteint aussi.'
          : 'En dérivation, l\'autre lampe garde son propre chemin et '
                'reste allumée.';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.5,
          child: CustomPaint(
            painter: _CircuitPainter(
              ferme: _ferme,
              serie: _serie,
              lampe1: _lampe1,
              lampe2: _lampe2,
              allumee1: allumee1,
              allumee2: allumee2,
              accent: widget.accent,
              ink: context.colors.onSurface,
              trait: tokens.border,
              muted: tokens.inkMuted,
              surface: context.colors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _serie ? 'Montage en série' : 'Montage en dérivation',
          style: AppTypography.formula(size: 17, color: widget.accent),
        ),
        Text(
          commentaire,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            _Bouton(
              texte: _ferme ? 'Ouvrir l\'interrupteur' : 'Fermer',
              actif: _ferme,
              accent: widget.accent,
              onTap: () => setState(() => _ferme = !_ferme),
            ),
            _Bouton(
              texte: _serie ? 'Passer en dérivation' : 'Passer en série',
              actif: true,
              accent: widget.accent,
              onTap: () => setState(() => _serie = !_serie),
            ),
            _Bouton(
              texte: _lampe1 ? 'Dévisser la lampe 1' : 'Revisser la lampe 1',
              actif: _lampe1,
              accent: widget.accent,
              onTap: () => setState(() => _lampe1 = !_lampe1),
            ),
            _Bouton(
              texte: _lampe2 ? 'Dévisser la lampe 2' : 'Revisser la lampe 2',
              actif: _lampe2,
              accent: widget.accent,
              onTap: () => setState(() => _lampe2 = !_lampe2),
            ),
          ],
        ),
      ],
    );
  }
}

class _Bouton extends StatelessWidget {
  const _Bouton({
    required this.texte,
    required this.actif,
    required this.accent,
    required this.onTap,
  });

  final String texte;
  final bool actif;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () {
        context.tapFeedback();
        onTap();
      },
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(texte, style: context.text.labelMedium),
    );
  }
}

class _CircuitPainter extends CustomPainter {
  const _CircuitPainter({
    required this.ferme,
    required this.serie,
    required this.lampe1,
    required this.lampe2,
    required this.allumee1,
    required this.allumee2,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final bool ferme;
  final bool serie;
  final bool lampe1;
  final bool lampe2;
  final bool allumee1;
  final bool allumee2;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color surface;

  static const Color _lumiere = Color(0xFFF5A524);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect cadre = Rect.fromLTRB(
      size.width * 0.12,
      size.height * 0.16,
      size.width * 0.88,
      size.height * 0.84,
    );
    final Paint fil = Paint()
      ..color = ink.withValues(alpha: 0.75)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Le rail du haut porte l'interrupteur, celui du bas est continu.
    final double milieuHaut = cadre.center.dx;
    canvas.drawLine(cadre.topLeft, Offset(milieuHaut - 16, cadre.top), fil);
    canvas.drawLine(Offset(milieuHaut + 16, cadre.top), cadre.topRight, fil);
    canvas.drawLine(cadre.bottomLeft, cadre.bottomRight, fil);
    canvas.drawLine(cadre.topLeft, Offset(cadre.left, cadre.center.dy - 14), fil);
    canvas.drawLine(
      Offset(cadre.left, cadre.center.dy + 14),
      cadre.bottomLeft,
      fil,
    );

    _interrupteur(canvas, Offset(milieuHaut, cadre.top));
    _pile(canvas, Offset(cadre.left, cadre.center.dy));

    if (serie) {
      // Un seul chemin : le côté droit porte les deux lampes.
      canvas.drawLine(
        cadre.topRight,
        Offset(cadre.right, cadre.top + cadre.height * 0.24),
        fil,
      );
      canvas.drawLine(
        Offset(cadre.right, cadre.top + cadre.height * 0.42),
        Offset(cadre.right, cadre.top + cadre.height * 0.58),
        fil,
      );
      canvas.drawLine(
        Offset(cadre.right, cadre.top + cadre.height * 0.76),
        cadre.bottomRight,
        fil,
      );
      _lampe(
        canvas,
        Offset(cadre.right, cadre.top + cadre.height * 0.33),
        lampe1,
        allumee1,
        '1',
      );
      _lampe(
        canvas,
        Offset(cadre.right, cadre.top + cadre.height * 0.67),
        lampe2,
        allumee2,
        '2',
      );
    } else {
      // Deux branches entre les deux rails : chacune a son chemin.
      final double x1 = cadre.left + cadre.width * 0.58;
      final double x2 = cadre.right;
      for (final (double x, bool presente, bool allumee, String nom)
          in <(double, bool, bool, String)>[
        (x1, lampe1, allumee1, '1'),
        (x2, lampe2, allumee2, '2'),
      ]) {
        canvas.drawLine(
          Offset(x, cadre.top),
          Offset(x, cadre.center.dy - 16),
          fil,
        );
        canvas.drawLine(
          Offset(x, cadre.center.dy + 16),
          Offset(x, cadre.bottom),
          fil,
        );
        _lampe(canvas, Offset(x, cadre.center.dy), presente, allumee, nom);
      }
    }
  }

  /// La pile, deux traits de longueurs inégales.
  void _pile(Canvas canvas, Offset centre) {
    final Paint epais = Paint()
      ..color = ink
      ..strokeWidth = 3.5;
    final Paint mince = Paint()
      ..color = ink
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(centre.dx - 11, centre.dy - 14),
      Offset(centre.dx + 11, centre.dy - 14),
      epais,
    );
    canvas.drawLine(
      Offset(centre.dx - 6, centre.dy + 14),
      Offset(centre.dx + 6, centre.dy + 14),
      mince,
    );
    _texte(canvas, 'pile', Offset(centre.dx - 26, centre.dy), muted);
  }

  /// L'interrupteur : une lame qui se relève quand on l'ouvre.
  void _interrupteur(Canvas canvas, Offset centre) {
    final Paint peinture = Paint()
      ..color = ink
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final Offset gauche = Offset(centre.dx - 16, centre.dy);
    final Offset droite = Offset(centre.dx + 16, centre.dy);
    canvas.drawCircle(gauche, 3, Paint()..color = ink);
    canvas.drawCircle(droite, 3, Paint()..color = ink);
    canvas.drawLine(
      gauche,
      ferme ? droite : Offset(centre.dx + 10, centre.dy - 16),
      peinture,
    );
    _texte(
      canvas,
      ferme ? 'fermé' : 'ouvert',
      Offset(centre.dx, centre.dy - 18),
      ferme ? muted : accent,
    );
  }

  /// Une lampe : un rond barré d'une croix, qui rayonne si elle brille.
  void _lampe(
    Canvas canvas,
    Offset centre,
    bool presente,
    bool allumee,
    String nom,
  ) {
    const double rayon = 15;
    if (allumee) {
      canvas.drawCircle(
        centre,
        rayon + 9,
        Paint()..color = _lumiere.withValues(alpha: 0.28),
      );
      for (int i = 0; i < 8; i++) {
        final double angle = i * math.pi / 4;
        canvas.drawLine(
          centre + Offset(math.cos(angle), math.sin(angle)) * (rayon + 5),
          centre + Offset(math.cos(angle), math.sin(angle)) * (rayon + 12),
          Paint()
            ..color = _lumiere
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    canvas.drawCircle(
      centre,
      rayon,
      Paint()..color = allumee ? _lumiere : surface,
    );
    canvas.drawCircle(
      centre,
      rayon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = presente ? ink : trait,
    );
    if (presente) {
      const double c = rayon * 0.62;
      final Paint croix = Paint()
        ..color = ink
        ..strokeWidth = 2;
      canvas.drawLine(
        centre + const Offset(-c, -c),
        centre + const Offset(c, c),
        croix,
      );
      canvas.drawLine(
        centre + const Offset(c, -c),
        centre + const Offset(-c, c),
        croix,
      );
    }
    _texte(
      canvas,
      presente ? nom : 'dévissée',
      Offset(centre.dx - (presente ? 38 : 52), centre.dy),
      presente ? muted : accent,
    );
  }

  void _texte(Canvas canvas, String texte, Offset centre, Color couleur) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          color: couleur,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
  bool shouldRepaint(_CircuitPainter old) =>
      old.ferme != ferme ||
      old.serie != serie ||
      old.lampe1 != lampe1 ||
      old.lampe2 != lampe2 ||
      old.accent != accent;
}
