/// Un triangle rectangle qu'on agrandit : les longueurs changent, pas les
/// rapports.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';

/// Le rapport qu'on lit sur la figure.
enum RapportTrigo {
  /// Opposé sur hypoténuse.
  sinus('sinus', 'opposé ÷ hypoténuse'),

  /// Adjacent sur hypoténuse.
  cosinus('cosinus', 'adjacent ÷ hypoténuse'),

  /// Opposé sur adjacent.
  tangente('tangente', 'opposé ÷ adjacent');

  const RapportTrigo(this.nom, this.definition);

  /// Le nom affiché sur le bouton.
  final String nom;

  /// Ce que le rapport divise par quoi.
  final String definition;

  /// La valeur du rapport pour un angle donné, en degrés.
  double valeur(double angleDegres) {
    final double a = angleDegres * math.pi / 180;
    return switch (this) {
      RapportTrigo.sinus => math.sin(a),
      RapportTrigo.cosinus => math.cos(a),
      RapportTrigo.tangente => math.tan(a),
    };
  }
}

/// La trigonométrie, montrée par l'agrandissement.
///
/// Un élève à qui l'on dit que le sinus « ne dépend que de l'angle »
/// l'accepte sans y croire : rien dans la formule ne le montre. Ici il
/// agrandit le triangle au curseur, voit les trois longueurs grandir
/// ensemble, et voit le rapport affiché ne pas bouger d'un millième. C'est
/// le seul fait dont la trigonométrie a besoin, et il se constate.
///
/// Le second curseur change l'angle. Les longueurs changent alors elles
/// aussi, mais cette fois le rapport change avec elles — ce qui achève de
/// dire de quoi il dépend.
class TrigonometryFigure extends StatefulWidget {
  const TrigonometryFigure({required this.accent, super.key});

  /// Couleur d'accent de la matière.
  final Color accent;

  /// Longueur de l'hypoténuse, en unités arbitraires, pour une taille
  /// donnée de 0 à 1.
  static double hypotenuse(double taille) => 4 + taille * 4;

  /// Le côté opposé à l'angle.
  static double oppose(double angleDegres, double taille) =>
      hypotenuse(taille) * math.sin(angleDegres * math.pi / 180);

  /// Le côté adjacent à l'angle.
  static double adjacent(double angleDegres, double taille) =>
      hypotenuse(taille) * math.cos(angleDegres * math.pi / 180);

  @override
  State<TrigonometryFigure> createState() => _TrigonometryFigureState();
}

class _TrigonometryFigureState extends State<TrigonometryFigure> {
  double _angle = 35;
  double _taille = 0.5;
  RapportTrigo _rapport = RapportTrigo.sinus;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  String _n(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // C'est la taille qui balaie, et l'angle qui reste : le triangle
    // grandit, les trois longueurs grandissent, et le rapport affiché ne
    // bouge pas d'un centième. C'est précisément ce que la figure existe
    // pour montrer, et le balayage le démontre tout seul.
    final double taille = _tenue
        ? _taille
        : Autoplay.sweep(context, min: 0, max: 1) ?? _taille;
    final double h = TrigonometryFigure.hypotenuse(taille);
    final double o = TrigonometryFigure.oppose(_angle, taille);
    final double a = TrigonometryFigure.adjacent(_angle, taille);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          children: <Widget>[
            for (final RapportTrigo r in RapportTrigo.values)
              ChoiceChip(
                label: Text(r.nom),
                selected: _rapport == r,
                onSelected: (_) {
                  setState(() {
                    _tenue = true;
                    _rapport = r;
                  });
                  context.tapFeedback();
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return CustomPaint(
                  size: Size(contraintes.maxWidth, 200),
                  painter: _TrigoPainter(
                    angle: _angle,
                    taille: taille,
                    rapport: _rapport,
                    accent: widget.accent,
                    tokens: tokens,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${_rapport.nom} ${_angle.round()}° = ${_n(_rapport.valeur(_angle))}',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          _rapport == RapportTrigo.tangente
              ? '${_n(o)} ÷ ${_n(a)} = ${_n(_rapport.valeur(_angle))}'
              : _rapport == RapportTrigo.sinus
                  ? '${_n(o)} ÷ ${_n(h)} = ${_n(_rapport.valeur(_angle))}'
                  : '${_n(a)} ÷ ${_n(h)} = ${_n(_rapport.valeur(_angle))}',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        Text(
          'Agrandis le triangle : les longueurs changent, ce rapport non.',
          textAlign: TextAlign.center,
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
        _curseur(context, 'angle', _angle, 10, 80, '${_angle.round()}°',
            (double v) => setState(() {
              _tenue = true;
              _angle = v;
            })),
        _curseur(context, 'taille', taille, 0, 1, '× ${_n(h / 2)}',
            (double v) => setState(() {
              _tenue = true;
              _taille = v;
            })),
      ],
    );
  }

  Widget _curseur(
    BuildContext context,
    String nom,
    double valeur,
    double mini,
    double maxi,
    String affichage,
    ValueChanged<double> quand,
  ) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 50,
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
            min: mini,
            max: maxi,
            onChanged: (double v) {
              quand(v);
              context.tapFeedback();
            },
          ),
        ),
        SizedBox(
          width: 46,
          child: Text(
            affichage,
            textAlign: TextAlign.right,
            style: AppTypography.formula(size: 13, color: widget.accent),
          ),
        ),
      ],
    );
  }
}

/// Le triangle rectangle, ses trois côtés nommés et l'angle marqué.
class _TrigoPainter extends CustomPainter {
  const _TrigoPainter({
    required this.angle,
    required this.taille,
    required this.rapport,
    required this.accent,
    required this.tokens,
  });

  final double angle;
  final double taille;
  final RapportTrigo rapport;
  final Color accent;
  final AppTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tokens.surfaceAlt);

    final double o = TrigonometryFigure.oppose(angle, taille);
    final double a = TrigonometryFigure.adjacent(angle, taille);

    // L'échelle est fixe : c'est tout l'intérêt de la figure. Agrandir le
    // triangle doit se voir, pas être recadré. On la cale sur le plus
    // grand triangle que les curseurs peuvent produire, pour qu'il tienne
    // encore dans le cadre.
    final double maxi = TrigonometryFigure.hypotenuse(1);
    final double unite = math.min(
      (size.width - 112) / maxi,
      (size.height - 44) / maxi,
    );

    // Le triangle est posé sur une base fixe et centré sur la largeur du
    // plus grand : il grandit vers le haut et vers la droite, sans sauter
    // d'un bord à l'autre quand on bouge le curseur.
    final Offset sommet = Offset(
      (size.width - maxi * unite) / 2 + 14,
      size.height - 26,
    );
    final Offset coin = sommet + Offset(a * unite, 0);
    final Offset haut = coin - Offset(0, o * unite);

    // Les côtés, celui qui intervient dans le rapport en évidence.
    final bool oppUtile = rapport != RapportTrigo.cosinus;
    final bool adjUtile = rapport != RapportTrigo.sinus;
    final bool hypUtile = rapport != RapportTrigo.tangente;

    void cote(Offset p1, Offset p2, bool utile, String nom, Offset decale) {
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = utile ? accent : tokens.inkSubtle.withValues(alpha: 0.45)
          ..strokeWidth = utile ? 3.4 : 2
          ..strokeCap = StrokeCap.round,
      );
      _etiquette(
        canvas,
        nom,
        (p1 + p2) / 2 + decale,
        utile ? accent : tokens.inkSubtle,
      );
    }

    cote(sommet, coin, adjUtile, 'adjacent', const Offset(-24, 8));
    cote(coin, haut, oppUtile, 'opposé', const Offset(10, -6));
    cote(sommet, haut, hypUtile, 'hypoténuse', const Offset(-62, -14));

    // L'angle droit, au carré, et l'angle de travail, en arc.
    const double marque = 9;
    canvas.drawRect(
      Rect.fromLTWH(coin.dx - marque, coin.dy - marque, marque, marque),
      Paint()
        ..color = tokens.inkMuted
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: sommet, radius: 24),
      -angle * math.pi / 180,
      angle * math.pi / 180,
      false,
      Paint()
        ..color = tokens.warning
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke,
    );
    _etiquette(
      canvas,
      '${angle.round()}°',
      sommet + const Offset(26, -16),
      tokens.warning,
    );

    // Le triangle de référence, en gris : il montre d'où l'on est parti
    // quand on agrandit, sans quoi « les longueurs changent » se juge de
    // mémoire.
    if (taille > 0.02) {
      final double h0 = TrigonometryFigure.hypotenuse(0);
      final double o0 = h0 * math.sin(angle * math.pi / 180);
      final double a0 = h0 * math.cos(angle * math.pi / 180);
      final Offset coin0 = sommet + Offset(a0 * unite, 0);
      final Offset haut0 = coin0 - Offset(0, o0 * unite);
      final Paint fantome = Paint()
        ..color = tokens.inkSubtle.withValues(alpha: 0.3)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      final Path contour = Path()
        ..moveTo(sommet.dx, sommet.dy)
        ..lineTo(coin0.dx, coin0.dy)
        ..lineTo(haut0.dx, haut0.dy)
        ..close();
      canvas.drawPath(contour, fantome);
    }
  }

  void _etiquette(Canvas canvas, String texte, Offset ou, Color couleur) {
    TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontFamilyFallback: AppTypography.replis,
          color: couleur,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, ou);
  }

  @override
  bool shouldRepaint(_TrigoPainter ancien) =>
      ancien.angle != angle ||
      ancien.taille != taille ||
      ancien.rapport != rapport ||
      ancien.accent != accent ||
      ancien.tokens != tokens;
}
