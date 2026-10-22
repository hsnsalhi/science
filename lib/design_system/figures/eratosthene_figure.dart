/// La mesure de la Terre par Ératosthène, à refaire soi-même.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Deux villes, deux ombres, et la Terre mesurée.
///
/// On déplace la ville du nord le long du méridien : l'angle de l'ombre
/// change, la distance au puits change, et le quotient des deux ne change
/// pas. C'est tout l'argument d'Ératosthène, et c'est ce que la figure a
/// à montrer — non pas qu'il ait trouvé 40 000 km, mais que la méthode
/// donne le même résultat où qu'on se place.
///
/// À Syène, le jour du solstice, le Soleil est au zénith : un puits y est
/// éclairé jusqu'au fond, un bâton n'y fait aucune ombre. Ailleurs, le
/// même bâton en fait une, et l'angle qu'elle révèle est exactement
/// l'angle au centre de la Terre entre les deux villes.
class EratostheneFigure extends StatefulWidget {
  const EratostheneFigure({required this.accent, super.key});

  final Color accent;

  /// Rayon moyen de la Terre, en kilomètres.
  static const double rayonTerre = 6371;

  /// Circonférence déduite d'un angle d'ombre et d'une distance.
  ///
  /// L'angle mesuré est la fraction de tour qui sépare les deux villes :
  /// la distance qui les sépare est donc la même fraction du tour complet.
  static double circonference(double angleDegres, double distanceKm) =>
      distanceKm * 360 / angleDegres;

  /// Distance réelle, le long du méridien, pour un angle au centre donné.
  static double distancePourAngle(double angleDegres) =>
      2 * math.pi * rayonTerre * angleDegres / 360;

  @override
  State<EratostheneFigure> createState() => _EratostheneFigureState();
}

class _EratostheneFigureState extends State<EratostheneFigure> {
  /// Angle au centre entre les deux villes, en degrés.
  ///
  /// La valeur d'origine est celle d'Ératosthène : un cinquantième de
  /// tour entre Alexandrie et Syène.
  double _angle = 7.2;

  String _n(double v) => NumericQuestion.formatNumber(v.roundToDouble());

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double distance = EratostheneFigure.distancePourAngle(_angle);
    final double circonference = EratostheneFigure.circonference(
      _angle,
      distance,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 0.95,
          child: CustomPaint(
            painter: _TerrePainter(
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
            _Mesure(
              nom: 'angle de l\'ombre',
              valeur: '${NumericQuestion.formatNumber(
                (_angle * 10).roundToDouble() / 10,
              )}°',
              couleur: context.colors.onSurface,
            ),
            _Mesure(
              nom: 'distance entre les villes',
              valeur: '${_n(distance)} km',
              couleur: context.colors.onSurface,
            ),
            _Mesure(
              nom: 'tour de la Terre',
              valeur: '${_n(circonference)} km',
              couleur: widget.accent,
              fort: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Déplace la ville : les deux premières mesures changent, '
          'la troisième non.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        Slider(
          value: _angle,
          min: 3,
          max: 40,
          onChanged: (double v) => setState(() => _angle = v),
        ),
      ],
    );
  }
}

class _Mesure extends StatelessWidget {
  const _Mesure({
    required this.nom,
    required this.valeur,
    required this.couleur,
    this.fort = false,
  });

  final String nom;
  final String valeur;
  final Color couleur;
  final bool fort;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          valeur,
          style: AppTypography.formula(size: fort ? 20 : 16, color: couleur),
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
}

class _TerrePainter extends CustomPainter {
  const _TerrePainter({
    required this.angle,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final double angle;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    // Deux dessins, l'un sous l'autre : ce qu'on mesure au pied du
    // bâton, puis ce qu'on en déduit sur la Terre entière. Séparés,
    // parce qu'un angle de sept degrés est lisible de près et
    // minuscule à l'échelle du globe — c'est d'ailleurs pour cela que
    // la rotondité de la Terre ne saute pas aux yeux.
    final double hautBande = size.height * 0.40;
    // Chaque dessin reste dans sa bande : le globe est volontairement
    // plus grand que la place disponible, et c'est le découpage qui lui
    // donne son allure de portion de planète.
    for (final (Rect zone, void Function(Canvas, Rect) dessin)
        in <(Rect, void Function(Canvas, Rect))>[
      (Rect.fromLTWH(0, 0, size.width, hautBande), _loupe),
      (
        Rect.fromLTWH(0, hautBande, size.width, size.height - hautBande),
        _globe,
      ),
    ]) {
      canvas.save();
      canvas.clipRect(zone);
      dessin(canvas, zone);
      canvas.restore();
    }
  }

  /// Le bâton d'Alexandrie, vu de près : le Soleil penché, l'ombre, et
  /// l'angle entre les deux.
  void _loupe(Canvas canvas, Rect zone) {
    final double radians = angle * math.pi / 180;
    final double sol = zone.bottom - 26;
    final double hauteur = math.min(zone.height * 0.62, 104);
    final Offset pied = Offset(zone.center.dx - 34, sol);
    final Offset sommet = pied + Offset(0, -hauteur);

    canvas.drawLine(
      Offset(zone.left + 18, sol),
      Offset(zone.right - 18, sol),
      Paint()
        ..color = trait
        ..strokeWidth = 2,
    );

    // Le rayon de Soleil qui rase le sommet du bâton et dessine le bout
    // de l'ombre.
    final double ombre = hauteur * math.tan(radians);
    final Offset boutOmbre = pied + Offset(ombre, 0);
    // Le rayon est prolongé en arrière le long de sa propre direction :
    // il doit raser le sommet du bâton, sinon le dessin montrerait une
    // ombre qui ne vient pas de là.
    final Offset depart = sommet - Offset(ombre, hauteur) * 0.75;
    canvas.drawLine(
      depart,
      boutOmbre,
      Paint()
        ..color = accent.withValues(alpha: 0.75)
        ..strokeWidth = 1.5,
    );

    canvas.drawLine(
      pied,
      boutOmbre,
      Paint()
        ..color = accent
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      pied,
      sommet,
      Paint()
        ..color = ink
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // Prolongement en pointillés : la direction du zénith, le second
    // côté de l'angle. Sans elle, on ne voit qu'un bâton et un rayon
    // presque confondus.
    final Paint pointilles = Paint()
      ..color = ink.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (double y = 0; y < hauteur * 0.7; y += 8) {
      canvas.drawLine(
        sommet + Offset(0, -y),
        sommet + Offset(0, -math.min(y + 4, hauteur * 0.7)),
        pointilles,
      );
    }

    // L'angle au sommet du bâton, entre la verticale et le rayon : c'est
    // la seule chose qu'Ératosthène ait eu à mesurer. Le secteur est
    // rempli, parce qu'un angle de sept degrés tracé au trait fin ne se
    // distingue pas du bâton lui-même.
    _secteur(canvas, sommet, hauteur * 0.62, math.pi / 2, radians);
    _texte(
      canvas,
      '${NumericQuestion.formatNumber((angle * 10).roundToDouble() / 10)}°',
      sommet + Offset(hauteur * 0.30, hauteur * 0.58),
      accent,
      gras: true,
    );

    _texte(canvas, 'ombre', boutOmbre + const Offset(36, -11), muted);
    _peintre('à Alexandrie, le bâton a une ombre', muted)
        .paint(canvas, Offset(zone.left + 18, zone.bottom - 18));
  }

  /// La Terre, les rayons parallèles, et l'angle au centre.
  void _globe(Canvas canvas, Rect zone) {
    final double rayon = math.min(zone.width * 0.46, zone.height * 0.86);
    final Offset centre = Offset(zone.center.dx, zone.bottom + rayon * 0.30);
    final double radians = angle * math.pi / 180;

    // Les rayons du Soleil, verticaux et parallèles : l'hypothèse qui
    // fait tenir tout le raisonnement, et qui tient parce que le Soleil
    // est très loin.
    final Paint rayonSoleil = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..strokeWidth = 1.5;
    for (int i = -2; i <= 2; i++) {
      final double x = centre.dx + i * rayon * 0.42;
      final double bas = centre.dy - rayon - 10;
      canvas.drawLine(Offset(x, zone.top + 6), Offset(x, bas), rayonSoleil);
      canvas.drawLine(Offset(x, bas), Offset(x - 3, bas - 7), rayonSoleil);
      canvas.drawLine(Offset(x, bas), Offset(x + 3, bas - 7), rayonSoleil);
    }

    canvas.drawCircle(centre, rayon, Paint()..color = surface);
    // Une teinte très légère : sur fond clair, un disque blanc cerclé
    // disparaît.
    canvas.drawCircle(
      centre,
      rayon,
      Paint()..color = accent.withValues(alpha: 0.06),
    );
    canvas.drawCircle(
      centre,
      rayon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = trait,
    );

    final Offset syene = centre + const Offset(0, -1) * rayon;
    final Offset ville =
        centre + Offset(-math.sin(radians), -math.cos(radians)) * rayon;

    // Les deux rayons terrestres, et l'angle qu'ils forment au centre :
    // le même que celui mesuré au pied du bâton.
    final Paint fil = Paint()
      ..color = accent.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    canvas.drawLine(centre, syene, fil);
    canvas.drawLine(centre, ville, fil);
    _secteur(canvas, centre, rayon * 0.62, -math.pi / 2 - radians, radians);
    _texte(
      canvas,
      '${NumericQuestion.formatNumber((angle * 10).roundToDouble() / 10)}°',
      centre + Offset(-rayon * 0.34, -rayon * 0.46),
      accent,
      gras: true,
    );

    // Les deux villes, et l'arc qui les sépare : c'est cette longueur-là
    // qu'on mesure à pied, et qui donne l'échelle.
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: rayon),
      -math.pi / 2 - radians,
      radians,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = accent,
    );

    for (final (Offset point, String nom, bool droite) in <(
      Offset,
      String,
      bool,
    )>[(syene, 'Syène', true), (ville, 'Alexandrie', false)]) {
      canvas.drawCircle(point, 5, Paint()..color = ink);
      final TextPainter p = _peintre(nom, muted);
      final Offset ancre = droite
          ? point + Offset(14, -8 - p.height)
          : point + Offset(-14 - p.width, -8 - p.height);
      p.paint(canvas, ancre);
    }
  }

  /// Un secteur angulaire rempli, bordé de son arc.
  void _secteur(
    Canvas canvas,
    Offset sommet,
    double rayon,
    double depart,
    double ouverture,
  ) {
    final Rect boite = Rect.fromCircle(center: sommet, radius: rayon);
    canvas.drawPath(
      Path()
        ..moveTo(sommet.dx, sommet.dy)
        ..arcTo(boite, depart, ouverture, false)
        ..close(),
      Paint()..color = accent.withValues(alpha: 0.28),
    );
    canvas.drawArc(
      boite,
      depart,
      ouverture,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent,
    );
  }

  TextPainter _peintre(String texte, Color couleur, {bool gras = false}) =>
      TextPainter(
        text: TextSpan(
          text: texte,
          style: TextStyle(
            fontFamily: AppTypography.body,
            fontFamilyFallback: AppTypography.replis,
            color: couleur,
            fontSize: gras ? 14 : 11,
            fontWeight: gras ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  void _texte(
    Canvas canvas,
    String texte,
    Offset centre,
    Color couleur, {
    bool gras = false,
  }) {
    final TextPainter painter = _peintre(texte, couleur, gras: gras);
    painter.paint(
      canvas,
      centre - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_TerrePainter old) =>
      old.angle != angle || old.accent != accent;
}
