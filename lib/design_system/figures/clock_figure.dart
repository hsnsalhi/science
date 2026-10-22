/// Une horloge à aiguilles, qu'on règle à la main.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'realism.dart';

/// Une horloge murale, avec son cadran, ses soixante traits et ses aiguilles.
///
/// Lire l'heure est la seule compétence de ce chapitre qui ne s'acquiert pas
/// sur le papier : il faut avoir vu les deux aiguilles tourner à des
/// vitesses différentes. Un cadran dessiné figé n'apprend rien, et un cadran
/// numérique encore moins — c'est justement le passage de l'un à l'autre qui
/// est en jeu.
///
/// La petite aiguille avance donc continûment, comme sur une vraie horloge :
/// à 3 h 30, elle est entre le 3 et le 4, pas sur le 3. C'est une source
/// d'erreur courante chez les élèves, et une horloge qui la placerait
/// pile sur le chiffre la leur enseignerait.
class ClockFigure extends StatefulWidget {
  const ClockFigure({required this.accent, super.key});

  final Color accent;

  /// Angle de l'aiguille des minutes, en degrés depuis midi.
  ///
  /// Un tour complet en soixante minutes : six degrés par minute.
  static double angleMinutes(int minute) => minute * 6;

  /// Angle de l'aiguille des heures, en degrés depuis midi.
  ///
  /// Un tour en douze heures, soit trente degrés par heure — plus la part
  /// déjà écoulée de l'heure en cours. C'est ce dernier terme qui fait la
  /// différence entre une horloge juste et un dessin d'horloge.
  static double angleHeures(int heure, int minute) =>
      (heure % 12) * 30 + minute * 0.5;

  /// L'heure écrite en toutes lettres, à la française.
  static String enToutesLettres(int heure, int minute) {
    final int h = heure % 24;
    if (minute == 0) return '$h heures pile';
    if (minute == 15) return '$h heures et quart';
    if (minute == 30) return '$h heures et demie';
    if (minute == 45) return '${(h + 1) % 24} heures moins le quart';
    return '$h h ${minute.toString().padLeft(2, '0')}';
  }

  @override
  State<ClockFigure> createState() => _ClockFigureState();
}

class _ClockFigureState extends State<ClockFigure> {
  int _heure = 10;
  int _minute = 10;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 210,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints contraintes) {
              return CustomPaint(
                size: Size(contraintes.maxWidth, 210),
                painter: _HorlogePainter(
                  heure: _heure,
                  minute: _minute,
                  accent: widget.accent,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${_heure.toString().padLeft(2, '0')} h '
          '${_minute.toString().padLeft(2, '0')}',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 20, color: widget.accent),
        ),
        Text(
          ClockFigure.enToutesLettres(_heure, _minute),
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        _Reglage(
          nom: 'heures',
          valeur: _heure,
          max: 23,
          accent: widget.accent,
          onChanged: (int v) => setState(() => _heure = v),
        ),
        _Reglage(
          nom: 'minutes',
          valeur: _minute,
          max: 59,
          accent: widget.accent,
          onChanged: (int v) => setState(() => _minute = v),
        ),
      ],
    );
  }
}

class _Reglage extends StatelessWidget {
  const _Reglage({
    required this.nom,
    required this.valeur,
    required this.max,
    required this.accent,
    required this.onChanged,
  });

  final String nom;
  final int valeur;
  final int max;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 58,
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
            max: max.toDouble(),
            divisions: max,
            onChanged: (double v) {
              context.tapFeedback();
              onChanged(v.round());
            },
          ),
        ),
        SizedBox(
          width: 28,
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

class _HorlogePainter extends CustomPainter {
  const _HorlogePainter({
    required this.heure,
    required this.minute,
    required this.accent,
  });

  final int heure;
  final int minute;
  final Color accent;

  static const Color _boitier = Color(0xFF6B4F3A);
  static const Color _cadran = Color(0xFFF6F0E2);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double rayon = math.min(size.width, size.height) / 2 - 10;

    _boitierEtCadran(canvas, centre, rayon);
    _graduations(canvas, centre, rayon);
    _chiffres(canvas, centre, rayon);
    _aiguilles(canvas, centre, rayon);
  }

  /// Le boîtier de bois et le cadran, avec leur épaisseur.
  void _boitierEtCadran(Canvas canvas, Offset centre, double rayon) {
    // L'ombre portée : une horloge est posée sur un mur, pas dans le vide.
    canvas.drawCircle(
      centre.translate(3, 5),
      rayon,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    // Le boîtier, bombé par son dégradé.
    Realisme.sphere(
      canvas,
      centre,
      rayon,
      couleur: _boitier,
      ambiant: 0.55,
    );
    // Le cadran, en retrait : c'est ce retrait qui donne l'épaisseur.
    canvas.drawCircle(
      centre,
      rayon * 0.88,
      Paint()..color = _cadran,
    );
    // Le reflet du verre, en haut à gauche.
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: centre, radius: rayon * 0.88)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: centre.translate(-rayon * 0.3, -rayon * 0.45),
        width: rayon * 1.1,
        height: rayon * 0.6,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.restore();
  }

  /// Les soixante traits : douze longs, quarante-huit courts.
  ///
  /// C'est le point que le chapitre souligne — le cadran porte douze
  /// chiffres mais soixante graduations — et il ne se voit que si on les
  /// dessine toutes.
  void _graduations(Canvas canvas, Offset centre, double rayon) {
    for (int i = 0; i < 60; i++) {
      final bool heure = i % 5 == 0;
      final double angle = i * 6 * math.pi / 180 - math.pi / 2;
      final double debut = rayon * (heure ? 0.74 : 0.79);
      final double fin = rayon * 0.84;
      canvas.drawLine(
        centre + Offset(math.cos(angle), math.sin(angle)) * debut,
        centre + Offset(math.cos(angle), math.sin(angle)) * fin,
        Paint()
          ..strokeWidth = heure ? 2.6 : 1
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF3B3129)
              .withValues(alpha: heure ? 0.9 : 0.45),
      );
    }
  }

  /// Les douze chiffres du cadran.
  void _chiffres(Canvas canvas, Offset centre, double rayon) {
    for (int i = 1; i <= 12; i++) {
      final double angle = i * 30 * math.pi / 180 - math.pi / 2;
      final Offset position =
          centre + Offset(math.cos(angle), math.sin(angle)) * rayon * 0.62;
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: '$i',
          style: const TextStyle(
            fontFamily: AppTypography.body,
            fontFamilyFallback: AppTypography.replis,
            color: Color(0xFF2E261F),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        position.translate(-painter.width / 2, -painter.height / 2),
      );
    }
  }

  /// Les deux aiguilles, et l'axe qui les tient.
  void _aiguilles(Canvas canvas, Offset centre, double rayon) {
    void aiguille(double angleDegres, double longueur, double epaisseur,
        Color couleur) {
      final double angle = angleDegres * math.pi / 180 - math.pi / 2;
      final Offset direction = Offset(math.cos(angle), math.sin(angle));
      // Un contrepoids derrière l'axe, comme sur une vraie aiguille.
      canvas.drawLine(
        centre - direction * rayon * 0.12,
        centre + direction * longueur,
        Paint()
          ..strokeWidth = epaisseur
          ..strokeCap = StrokeCap.round
          ..color = couleur,
      );
    }

    aiguille(
      ClockFigure.angleHeures(heure, minute),
      rayon * 0.48,
      5.5,
      const Color(0xFF2E261F),
    );
    aiguille(
      ClockFigure.angleMinutes(minute),
      rayon * 0.74,
      3.6,
      const Color(0xFF2E261F),
    );
    // L'axe central, par-dessus les deux.
    canvas.drawCircle(centre, 5, Paint()..color = accent);
    canvas.drawCircle(
      centre,
      2,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(_HorlogePainter old) =>
      old.heure != heure || old.minute != minute || old.accent != accent;
}
