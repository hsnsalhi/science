/// Un projectile lancé, et la portée qui en résulte.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Une trajectoire parabolique dont on règle l'angle et la vitesse.
///
/// Le mouvement d'un projectile se décompose en deux mouvements
/// indépendants : horizontalement il avance à vitesse constante,
/// verticalement il tombe comme n'importe quel objet lâché. Rien ne les
/// couple, et c'est ce qui surprend — deux billes, l'une lâchée et
/// l'autre lancée horizontalement depuis la même hauteur, touchent le
/// sol en même temps.
///
/// La figure sépare les deux composantes sous la courbe pour que cette
/// indépendance se voie, et affiche la portée. Le réglage de l'angle
/// fait apparaître sans calcul que 45° porte le plus loin, et que deux
/// angles complémentaires donnent la même portée.
class ProjectileFigure extends StatefulWidget {
  const ProjectileFigure({required this.accent, super.key});

  final Color accent;

  /// Intensité de la pesanteur, en mètres par seconde carrée.
  static const double g = 9.81;

  /// Durée du vol, en secondes, pour un lancer depuis le sol.
  static double duree(double vitesse, double angleDegres) =>
      2 * vitesse * math.sin(angleDegres * math.pi / 180) / g;

  /// Portée horizontale, en mètres.
  static double portee(double vitesse, double angleDegres) =>
      vitesse * math.cos(angleDegres * math.pi / 180) *
      duree(vitesse, angleDegres);

  /// Hauteur maximale atteinte, en mètres.
  static double hauteurMax(double vitesse, double angleDegres) {
    final double vy = vitesse * math.sin(angleDegres * math.pi / 180);
    return vy * vy / (2 * g);
  }

  /// Angle qui porte le plus loin, en degrés.
  static const double angleOptimal = 45;

  @override
  State<ProjectileFigure> createState() => _ProjectileFigureState();
}

class _ProjectileFigureState extends State<ProjectileFigure> {
  double _vitesse = 20;
  double _angle = 45;

  String _n(double v) =>
      NumericQuestion.formatNumber((v * 10).roundToDouble() / 10);

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double portee = ProjectileFigure.portee(_vitesse, _angle);
    final double hauteur = ProjectileFigure.hauteurMax(_vitesse, _angle);
    final double duree = ProjectileFigure.duree(_vitesse, _angle);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.5,
          child: CustomPaint(
            painter: _TrajectoirePainter(
              vitesse: _vitesse,
              angle: _angle,
              accent: widget.accent,
              ink: context.colors.onSurface,
              trait: tokens.border,
              muted: tokens.inkMuted,
              surface: context.colors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            _Mesure(nom: 'portée', valeur: '${_n(portee)} m', fort: true,
                accent: widget.accent),
            _Mesure(nom: 'hauteur max', valeur: '${_n(hauteur)} m',
                accent: context.colors.onSurface),
            _Mesure(nom: 'durée du vol', valeur: '${_n(duree)} s',
                accent: context.colors.onSurface),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _angle == ProjectileFigure.angleOptimal
              ? 'À 45°, la portée est maximale.'
              : 'Essaie ${_n(90 - _angle)}° : la portée sera la même.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        _Reglage(
          nom: 'angle',
          valeur: _angle,
          min: 10,
          max: 80,
          affichage: '${_angle.round()}°',
          accent: widget.accent,
          onChanged: (double v) => setState(() => _angle = v.roundToDouble()),
        ),
        _Reglage(
          nom: 'vitesse',
          valeur: _vitesse,
          min: 5,
          max: 35,
          affichage: '${_vitesse.round()} m/s',
          accent: widget.accent,
          onChanged: (double v) => setState(() => _vitesse = v.roundToDouble()),
        ),
      ],
    );
  }
}

class _Mesure extends StatelessWidget {
  const _Mesure({
    required this.nom,
    required this.valeur,
    required this.accent,
    this.fort = false,
  });

  final String nom;
  final String valeur;
  final Color accent;
  final bool fort;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        valeur,
        style: AppTypography.formula(size: fort ? 19 : 16, color: accent),
      ),
      Text(
        nom,
        style: context.text.labelSmall?.copyWith(
          color: context.tokens.inkSubtle,
        ),
      ),
    ],
  );
}

class _Reglage extends StatelessWidget {
  const _Reglage({
    required this.nom,
    required this.valeur,
    required this.min,
    required this.max,
    required this.affichage,
    required this.accent,
    required this.onChanged,
  });

  final String nom;
  final double valeur;
  final double min;
  final double max;
  final String affichage;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      SizedBox(
        width: 62,
        child: Text(
          nom,
          style: context.text.labelSmall?.copyWith(
            color: context.tokens.inkSubtle,
          ),
        ),
      ),
      Expanded(
        child: Slider(
          value: valeur,
          min: min,
          max: max,
          onChanged: (double v) {
            context.tapFeedback();
            onChanged(v);
          },
        ),
      ),
      SizedBox(
        width: 58,
        child: Text(
          affichage,
          textAlign: TextAlign.right,
          style: AppTypography.formula(size: 14, color: accent),
        ),
      ),
    ],
  );
}

class _TrajectoirePainter extends CustomPainter {
  const _TrajectoirePainter({
    required this.vitesse,
    required this.angle,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final double vitesse;
  final double angle;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    const double marge = 22;
    final double sol = size.height - marge;
    // L'échelle suit le tir en cours : à échelle fixe, un lancer de
    // quarante mètres tiendrait dans un tiers du cadre et la courbe
    // serait illisible. Les distances se lisent sur les mesures
    // affichées sous le dessin, qui ne mentent pas, elles.
    final double porteeCourante = math.max(
      ProjectileFigure.portee(vitesse, angle),
      1,
    );
    final double hauteurCourante = math.max(
      ProjectileFigure.hauteurMax(vitesse, angle),
      1,
    );
    final double echelle = math.min(
      (size.width - marge * 2) / (porteeCourante * 1.04),
      (sol - marge * 1.6) / hauteurCourante,
    );

    canvas.drawRect(Offset.zero & size, Paint()..color = surface);
    canvas.drawLine(
      Offset(marge, sol),
      Offset(size.width - marge, sol),
      Paint()
        ..color = ink.withValues(alpha: 0.6)
        ..strokeWidth = 2,
    );

    Offset p(double x, double y) =>
        Offset(marge + x * echelle, sol - y * echelle);

    // La trajectoire, échantillonnée dans le temps.
    final double duree = ProjectileFigure.duree(vitesse, angle);
    final double vx = vitesse * math.cos(angle * math.pi / 180);
    final double vy = vitesse * math.sin(angle * math.pi / 180);
    final Path courbe = Path()..moveTo(p(0, 0).dx, p(0, 0).dy);
    for (int i = 1; i <= 120; i++) {
      final double t = duree * i / 120;
      final Offset point = p(vx * t, vy * t - ProjectileFigure.g * t * t / 2);
      courbe.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      courbe,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = accent,
    );

    // Des positions à intervalles de temps égaux : elles se resserrent
    // en haut, où le projectile ralentit verticalement, et gardent le
    // même écart horizontal. L'indépendance des deux mouvements se lit
    // là, et nulle part ailleurs.
    for (int i = 0; i <= 8; i++) {
      final double t = duree * i / 8;
      final Offset point = p(vx * t, vy * t - ProjectileFigure.g * t * t / 2);
      canvas.drawCircle(point, 3.5, Paint()..color = accent);
      canvas.drawLine(
        Offset(point.dx, sol),
        Offset(point.dx, sol + 5),
        Paint()
          ..color = trait
          ..strokeWidth = 1.5,
      );
    }

    // La portée, mesurée au sol.
    final double portee = ProjectileFigure.portee(vitesse, angle);
    canvas.drawLine(
      Offset(marge, sol + 12),
      Offset(marge + portee * echelle, sol + 12),
      Paint()
        ..color = accent
        ..strokeWidth = 2,
    );
    _texte(
      canvas,
      'portée',
      Offset(marge + portee * echelle / 2, sol + 20),
      muted,
    );

    // Le vecteur vitesse initial, qui porte l'angle.
    final Offset depart = p(0, 0);
    final Offset fleche = depart +
        Offset(math.cos(angle * math.pi / 180), -math.sin(angle * math.pi / 180)) *
            46;
    canvas.drawLine(
      depart,
      fleche,
      Paint()
        ..color = ink
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    _texte(canvas, '${angle.round()}°', depart + const Offset(32, -9), ink);
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
  bool shouldRepaint(_TrajectoirePainter old) =>
      old.vitesse != vitesse || old.angle != angle || old.accent != accent;
}
