/// Une lampe, un objet, un mur : d'où vient une ombre.
library;


import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';
import 'realism.dart';

/// La scène d'une ombre portée, avec la lampe réglable.
///
/// « La lumière va droit » est la phrase la plus rentable de toute la
/// physique de collège : ombres, éclipses, chambre noire, tout en découle.
/// Mais énoncée seule, elle ne se vérifie pas — et une figure qui dessine
/// l'ombre sans montrer les rayons demande de la croire sur parole.
///
/// Ici les rayons sont tracés depuis la source, et l'ombre est simplement
/// l'endroit où ils ne parviennent pas. On peut déplacer la lampe et voir
/// l'ombre grandir sans que l'objet ait changé de taille : c'est la
/// géométrie qui travaille, et elle est visible.
///
/// La lampe a une taille, comme toutes les vraies sources. C'est pour cela
/// qu'il y a une pénombre au bord de l'ombre — un détail qu'un schéma à
/// source ponctuelle escamote, et qui est pourtant ce qu'on observe.
class ShadowFigure extends StatefulWidget {
  const ShadowFigure({required this.accent, super.key});

  final Color accent;

  /// Hauteur de l'ombre sur le mur, par le théorème de Thalès.
  ///
  /// L'objet de hauteur [hauteurObjet] est à [distanceObjet] de la source,
  /// le mur à [distanceMur]. Les triangles sont semblables, donc l'ombre
  /// vaut la hauteur de l'objet multipliée par le rapport des distances.
  ///
  /// Exposée pour que le test confronte la figure à Thalès plutôt qu'à
  /// elle-même : c'est la même géométrie que le chapitre de maths, et une
  /// figure qui s'en écarterait enseignerait deux choses contradictoires.
  static double hauteurOmbre({
    required double hauteurObjet,
    required double distanceObjet,
    required double distanceMur,
  }) {
    if (distanceObjet <= 0) return double.infinity;
    return hauteurObjet * distanceMur / distanceObjet;
  }

  /// Grandissement de l'ombre par rapport à l'objet.
  static double grandissement({
    required double distanceObjet,
    required double distanceMur,
  }) {
    if (distanceObjet <= 0) return double.infinity;
    return distanceMur / distanceObjet;
  }

  @override
  State<ShadowFigure> createState() => _ShadowFigureState();
}

class _ShadowFigureState extends State<ShadowFigure> {
  /// Position de la lampe, de 0 (collée à l'objet) à 1 (au plus loin).
  double _recul = 0.55;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;

    // Repères en unités arbitraires, cohérents avec le dessin.
    const double positionObjet = 100;
    const double positionMur = 160;
    // La lampe recule et revient : l'ombre se resserre puis s'étale,
    // et le grandissement suit le rapport des distances.
    final double recul = _tenue
        ? _recul
        : Autoplay.sweep(context, min: 0, max: 1) ?? _recul;
    final double positionLampe = positionObjet - (12 + recul * 78);
    final double distanceObjet = positionObjet - positionLampe;
    final double distanceMur = positionMur - positionLampe;
    final double grandissement = ShadowFigure.grandissement(
      distanceObjet: distanceObjet,
      distanceMur: distanceMur,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 210,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return CustomPaint(
                  size: Size(contraintes.maxWidth, 210),
                  painter: _OmbrePainter(
                    recul: recul,
                    accent: widget.accent,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'L\'ombre est ${grandissement.toStringAsFixed(1).replaceAll('.', ',')} '
          'fois plus haute que l\'objet.',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 16, color: widget.accent),
        ),
        Text(
          'L\'objet n\'a pas changé de taille : seule la géométrie a bougé.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            SizedBox(
              width: 74,
              child: Text(
                'recul de la lampe',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkSubtle,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: recul,
                onChanged: (double v) {
                  context.tapFeedback();
                  setState(() {
                    _tenue = true;
                    _recul = v;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OmbrePainter extends CustomPainter {
  const _OmbrePainter({required this.recul, required this.accent});

  final double recul;
  final Color accent;

  static const Color _lumiere = Color(0xFFFFD98A);

  @override
  void paint(Canvas canvas, Size size) {
    final double murX = size.width * 0.86;
    final double objetX = size.width * 0.52;
    final double lampeX = objetX - (22 + recul * 0.30 * size.width);
    final double solY = size.height * 0.84;
    final double axeY = size.height * 0.46;
    const double demiObjet = 24;
    const double rayonLampe = 7;

    _piece(canvas, size, murX, solY);

    // Les rayons qui frôlent l'objet. Ils partent des deux bords de la
    // lampe, parce qu'une vraie source a une taille : c'est ce qui crée
    // la pénombre, et c'est ce qu'on observe réellement au mur.
    for (final double bordLampe in <double>[-rayonLampe, rayonLampe]) {
      for (final double bordObjet in <double>[-demiObjet, demiObjet]) {
        final Offset depart = Offset(lampeX, axeY + bordLampe);
        final Offset frole = Offset(objetX, axeY + bordObjet);
        // Prolongement jusqu'au mur.
        final double t = (murX - depart.dx) / (frole.dx - depart.dx);
        final Offset arrivee = Offset(
          murX,
          depart.dy + (frole.dy - depart.dy) * t,
        );
        canvas.drawLine(
          depart,
          arrivee,
          Paint()
            ..strokeWidth = 1
            ..color = _lumiere.withValues(alpha: 0.5),
        );
      }
    }

    _ombreAuMur(canvas, murX, objetX, lampeX, axeY, demiObjet, rayonLampe);
    _objet(canvas, objetX, axeY, demiObjet, solY);
    _lampe(canvas, lampeX, axeY, rayonLampe);
  }

  /// La pièce : un mur au fond, un sol, une ambiance sombre.
  void _piece(Canvas canvas, Size size, double murX, double solY) {
    final Rect cadre = Offset.zero & size;
    canvas.drawRect(
      cadre,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.5, -0.1),
          radius: 1.2,
          colors: <Color>[Color(0xFF3A3328), Color(0xFF1A1813)],
        ).createShader(cadre),
    );
    // Le mur qui reçoit l'ombre, légèrement plus clair.
    canvas.drawRect(
      Rect.fromLTWH(murX, 0, size.width - murX, size.height),
      Paint()..color = const Color(0xFFD8C9AE),
    );
    canvas.drawLine(
      Offset(murX, 0),
      Offset(murX, size.height),
      Paint()
        ..strokeWidth = 1.4
        ..color = Colors.black.withValues(alpha: 0.3),
    );
    // Le sol, qui donne une profondeur à la scène.
    canvas.drawRect(
      Rect.fromLTWH(0, solY, murX, size.height - solY),
      Paint()..color = const Color(0xFF2A241B),
    );
  }

  /// L'ombre et sa pénombre, projetées sur le mur.
  void _ombreAuMur(
    Canvas canvas,
    double murX,
    double objetX,
    double lampeX,
    double axeY,
    double demiObjet,
    double rayonLampe,
  ) {
    double projeter(double yLampe, double yObjet) {
      final double t = (murX - lampeX) / (objetX - lampeX);
      return yLampe + (yObjet - yLampe) * t;
    }

    // L'ombre vraie : là où aucun point de la lampe n'atteint le mur.
    // Elle est bornée par les rayons croisés — bord opposé de la lampe
    // vers bord opposé de l'objet.
    final double ombreHaut =
        projeter(axeY + rayonLampe, axeY - demiObjet);
    final double ombreBas = projeter(axeY - rayonLampe, axeY + demiObjet);
    // La pénombre : jusqu'où un seul bord de la lampe éclaire encore.
    final double penombreHaut =
        projeter(axeY - rayonLampe, axeY - demiObjet);
    final double penombreBas =
        projeter(axeY + rayonLampe, axeY + demiObjet);

    canvas.drawRect(
      Rect.fromLTRB(murX, penombreHaut, murX + 400, penombreBas),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRect(
      Rect.fromLTRB(murX, ombreHaut, murX + 400, ombreBas),
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );
  }

  /// L'objet : une quille de bois posée au sol.
  void _objet(
    Canvas canvas,
    double x,
    double axeY,
    double demi,
    double solY,
  ) {
    // Un objet qu'on peut poser, pas un rectangle flottant : il a un
    // pied, un corps renflé et une tête, et il touche le sol.
    final Path quille = Path()
      ..moveTo(x - 11, solY)
      ..lineTo(x - 7, solY - 10)
      ..cubicTo(
        x - 14, axeY + demi * 0.4,
        x - 13, axeY - demi * 0.3,
        x - 5, axeY - demi * 0.62,
      )
      ..cubicTo(
        x - 9, axeY - demi,
        x + 9, axeY - demi,
        x + 5, axeY - demi * 0.62,
      )
      ..cubicTo(
        x + 13, axeY - demi * 0.3,
        x + 14, axeY + demi * 0.4,
        x + 7, solY - 10,
      )
      ..lineTo(x + 11, solY)
      ..close();
    canvas.drawPath(
      quille,
      Realisme.chair(quille.getBounds(), const Color(0xFF9A6B3E)),
    );
    // La face éclairée, côté lampe.
    canvas.save();
    canvas.clipPath(quille);
    canvas.drawRect(
      Rect.fromLTRB(x - 20, axeY - 40, x - 2, solY + 2),
      Paint()
        ..color = _lumiere.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();

    // L'ombre au sol, allongée loin de la lampe.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x + 16, solY + 2),
        width: 56,
        height: 9,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  /// La lampe : une ampoule avec son filament et son halo.
  void _lampe(Canvas canvas, double x, double y, double rayon) {
    Realisme.couronne(
      canvas,
      Offset(x, y),
      rayon,
      couleur: _lumiere,
      portee: 4.5,
    );
    // Le culot et le verre.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x - 11, y), width: 9, height: 11),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF9A9188),
    );
    canvas.drawCircle(
      Offset(x, y),
      rayon,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Colors.white, _lumiere, Color(0xFFE09A1E)],
          stops: <double>[0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: rayon)),
    );
    // Le filament, qui dit que c'est une ampoule et non un point.
    final Path filament = Path()..moveTo(x - 3, y + 2);
    for (int i = 0; i < 5; i++) {
      filament.lineTo(x - 3 + i * 1.5, y + (i.isEven ? -2.5 : 2));
    }
    canvas.drawPath(
      filament,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_OmbrePainter old) =>
      old.recul != recul || old.accent != accent;
}
