/// Soleil, Terre, Lune : où tombe l'ombre, et pourquoi si rarement.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Ce qu'un alignement donné produit.
enum TypeEclipse {
  /// La Lune est entre le Soleil et la Terre, et assez bien alignée.
  soleil('Éclipse de Soleil', 'La Lune masque le Soleil. Nouvelle lune.'),

  /// La Terre est entre le Soleil et la Lune, et assez bien alignée.
  lune('Éclipse de Lune', 'La Lune entre dans l\'ombre de la Terre. Pleine lune.'),

  /// Les trois astres sont alignés en longitude mais la Lune passe à côté.
  manquee(
    'Pas d\'éclipse',
    'Alignée, mais trop haut ou trop bas : l\'ombre rate sa cible.',
  ),

  /// La Lune n'est pas du tout dans l'axe.
  aucune('Pas d\'éclipse', 'La Lune n\'est pas dans l\'axe Soleil-Terre.');

  const TypeEclipse(this.titre, this.explication);

  final String titre;
  final String explication;
}

/// L'alignement des trois astres, réglable en position et en inclinaison.
///
/// Le chapitre pose une question que les schémas de manuel n'aident pas à
/// résoudre : la Lune repasse devant le Soleil chaque mois, alors pourquoi
/// les éclipses sont-elles rares ? Un schéma plat suggère qu'il en faudrait
/// une par mois, et laisse l'élève avec une contradiction.
///
/// La réponse est que l'orbite lunaire est inclinée d'environ 5 degrés : le
/// plus souvent la Lune passe au-dessus ou au-dessous de l'axe, et l'ombre
/// manque sa cible. La figure donne donc deux réglages — la position sur
/// l'orbite et la hauteur hors du plan — parce qu'un seul ne pourrait pas
/// faire comprendre la rareté.
class EclipseFigure extends StatefulWidget {
  const EclipseFigure({required this.accent, super.key});

  final Color accent;

  /// Demi-ouverture tolérée, en degrés, pour que l'alignement compte.
  ///
  /// Au-delà, le cône d'ombre passe à côté. L'ordre de grandeur est celui
  /// de la réalité : les éclipses ne se produisent que dans une fenêtre
  /// étroite autour des nœuds de l'orbite lunaire.
  static const double toleranceLongitude = 15;

  /// Écart hors du plan toléré, en degrés.
  static const double toleranceLatitude = 1.5;

  /// Inclinaison réelle de l'orbite lunaire, en degrés.
  static const double inclinaison = 5.1;

  /// Ce que produit la Lune à [longitude] degrés, décalée de [latitude].
  ///
  /// La longitude est comptée depuis la direction du Soleil : 0 place la
  /// Lune entre le Soleil et la Terre (nouvelle lune), 180 la place
  /// derrière la Terre (pleine lune).
  static TypeEclipse classer(double longitude, double latitude) {
    final double l = _normaliser(longitude);
    final bool horsDuPlan = latitude.abs() > toleranceLatitude;
    final bool versLeSoleil = l <= toleranceLongitude ||
        l >= 360 - toleranceLongitude;
    final bool derriere = (l - 180).abs() <= toleranceLongitude;

    if (!versLeSoleil && !derriere) return TypeEclipse.aucune;
    if (horsDuPlan) return TypeEclipse.manquee;
    return versLeSoleil ? TypeEclipse.soleil : TypeEclipse.lune;
  }

  /// Phase de la Lune vue de la Terre, à [longitude] degrés.
  ///
  /// Sert à vérifier l'affirmation du cours : une éclipse de Soleil ne peut
  /// arriver qu'à la nouvelle lune, une éclipse de Lune qu'à la pleine lune.
  static String phase(double longitude) {
    final double l = _normaliser(longitude);
    if (l <= 22.5 || l >= 337.5) return 'nouvelle lune';
    if ((l - 180).abs() <= 22.5) return 'pleine lune';
    if ((l - 90).abs() <= 22.5) return 'premier quartier';
    if ((l - 270).abs() <= 22.5) return 'dernier quartier';
    return l < 180 ? 'croissante' : 'décroissante';
  }

  static double _normaliser(double degres) {
    double d = degres % 360;
    if (d < 0) d += 360;
    return d;
  }

  @override
  State<EclipseFigure> createState() => _EclipseFigureState();
}

class _EclipseFigureState extends State<EclipseFigure> {
  double _longitude = 0;
  double _latitude = 0;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final TypeEclipse type = EclipseFigure.classer(_longitude, _latitude);
    final bool eclipse =
        type == TypeEclipse.soleil || type == TypeEclipse.lune;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 160,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, 160),
                painter: _EclipsePainter(
                  longitude: _longitude,
                  latitude: _latitude,
                  type: type,
                  accent: widget.accent,
                  trait: tokens.border,
                  muted: tokens.inkMuted,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          type.titre,
          textAlign: TextAlign.center,
          style: AppTypography.formula(
            size: 18,
            color: eclipse ? widget.accent : tokens.inkMuted,
          ),
        ),
        Text(
          type.explication,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        Text(
          'Phase : ${EclipseFigure.phase(_longitude)}.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        _Curseur(
          nom: 'position',
          valeur: _longitude,
          min: 0,
          max: 360,
          suffixe: '°',
          accent: widget.accent,
          onChanged: (double v) => setState(() => _longitude = v),
        ),
        _Curseur(
          nom: 'hauteur',
          valeur: _latitude,
          min: -EclipseFigure.inclinaison,
          max: EclipseFigure.inclinaison,
          suffixe: '°',
          accent: widget.accent,
          onChanged: (double v) => setState(() => _latitude = v),
        ),
      ],
    );
  }
}

/// Un curseur réel, avec son nom et sa valeur.
class _Curseur extends StatelessWidget {
  const _Curseur({
    required this.nom,
    required this.valeur,
    required this.min,
    required this.max,
    required this.suffixe,
    required this.accent,
    required this.onChanged,
  });

  final String nom;
  final double valeur;
  final double min;
  final double max;
  final String suffixe;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 64,
          child: Text(
            nom,
            style: context.text.labelSmall?.copyWith(
              color: context.tokens.inkSubtle,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: valeur.clamp(min, max),
            min: min,
            max: max,
            onChanged: (double v) {
              context.tapFeedback();
              onChanged(v);
            },
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            '${valeur.round()}$suffixe',
            textAlign: TextAlign.right,
            style: AppTypography.formula(size: 14, color: accent),
          ),
        ),
      ],
    );
  }
}

class _EclipsePainter extends CustomPainter {
  const _EclipsePainter({
    required this.longitude,
    required this.latitude,
    required this.type,
    required this.accent,
    required this.trait,
    required this.muted,
  });

  final double longitude;
  final double latitude;
  final TypeEclipse type;
  final Color accent;
  final Color trait;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    const double axeY = 78;
    const double xSoleil = 26;
    final double xTerre = size.width * 0.58;
    final double rayonOrbite = math.min(size.width * 0.3, 62);

    // L'axe Soleil-Terre, prolongé derrière la Terre : c'est la ligne sur
    // laquelle une éclipse devient possible, et la seule.
    canvas.drawLine(
      const Offset(xSoleil, axeY),
      Offset(size.width - 6, axeY),
      Paint()
        ..color = trait.withValues(alpha: 0.4)
        ..strokeWidth = 1.2,
    );

    // L'orbite, vue par la tranche : une ellipse très aplatie, inclinée.
    // La vue de profil est le seul point de vue depuis lequel la rareté des
    // éclipses se voit ; vue de dessus, l'inclinaison disparaît.
    canvas.save();
    canvas.translate(xTerre, axeY);
    canvas.rotate(-0.16);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: rayonOrbite * 2,
        height: rayonOrbite * 0.5,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = muted.withValues(alpha: 0.5),
    );
    canvas.restore();

    _astre(canvas, const Offset(xSoleil, axeY), 17, const Color(0xFFF2B01E), 'Soleil');
    _astre(canvas, Offset(xTerre, axeY), 11, accent, 'Terre');

    // La Lune : la longitude la place sur l'orbite, la hauteur la décale
    // hors du plan. Les deux réglages sont indépendants, comme dans le ciel.
    final double rad = longitude * math.pi / 180;
    final double lx = xTerre - math.cos(rad) * rayonOrbite;
    final double ly = axeY +
        math.sin(rad) * rayonOrbite * 0.25 -
        latitude * 4.2;
    _astre(canvas, Offset(lx, ly), 6, muted, 'Lune');

    // Le cône d'ombre, dessiné seulement quand il tombe juste : le montrer
    // en permanence laisserait croire qu'une éclipse a lieu chaque mois,
    // ce qui est précisément l'erreur à défaire.
    if (type == TypeEclipse.soleil || type == TypeEclipse.lune) {
      final Offset depuis = type == TypeEclipse.soleil
          ? Offset(lx, ly)
          : Offset(xTerre, axeY);
      final Offset vers = type == TypeEclipse.soleil
          ? Offset(xTerre, axeY)
          : Offset(lx, ly);
      canvas.drawLine(
        depuis,
        vers,
        Paint()
          ..color = accent.withValues(alpha: 0.65)
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _astre(
    Canvas canvas,
    Offset centre,
    double rayon,
    Color couleur,
    String nom,
  ) {
    canvas.drawCircle(centre, rayon, Paint()..color = couleur);
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: nom,
        style: TextStyle(
          fontFamily: AppTypography.body,
          color: couleur,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      centre.translate(-painter.width / 2, rayon + 3),
    );
  }

  @override
  bool shouldRepaint(_EclipsePainter old) =>
      old.longitude != longitude ||
      old.latitude != latitude ||
      old.type != type ||
      old.accent != accent;
}
