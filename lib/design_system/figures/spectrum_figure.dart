/// Le spectre d'une étoile, et les raies qui trahissent sa composition.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Un élément chimique, et les longueurs d'onde qu'il prélève.
///
/// Les valeurs sont en nanomètres, prises dans les tables usuelles. Ce
/// sont des mesures, pas des choix de dessin : une raie déplacée de
/// quelques nanomètres désignerait un autre élément, et la figure
/// mentirait sur le seul point qu'elle doit enseigner.
enum ElementSpectral {
  hydrogene('hydrogène', <double>[656.3, 486.1, 434.0, 410.2]),
  helium('hélium', <double>[667.8, 587.6, 501.6, 447.1]),
  sodium('sodium', <double>[589.3]),
  calcium('calcium', <double>[422.7, 396.8, 393.4]),
  fer('fer', <double>[527.0, 495.8, 466.8, 438.4, 430.8, 404.6]);

  const ElementSpectral(this.nom, this.raies);

  final String nom;

  /// Les longueurs d'onde absorbées, en nanomètres.
  final List<double> raies;
}

/// Un spectre continu barré de raies sombres, et un curseur de
/// température.
///
/// Deux choses se lisent ici, et elles sont indépendantes. La couleur
/// d'ensemble donne la température : une étoile bleue est plus chaude
/// qu'une rouge, ce qui surprend toujours. Les raies sombres donnent la
/// composition : leur position ne dépend que de l'élément, et pas du
/// tout de la température.
///
/// C'est cette indépendance qui fait l'intérêt de la spectroscopie, et
/// c'est pourquoi la figure laisse régler l'une sans toucher à l'autre.
class SpectrumFigure extends StatefulWidget {
  const SpectrumFigure({required this.accent, super.key});

  final Color accent;

  /// Les bornes du visible, en nanomètres.
  static const double visibleMin = 380;
  static const double visibleMax = 750;

  /// Les bornes du curseur de température, en kelvins.
  static const double tMin = 3000;
  static const double tMax = 30000;

  /// La constante de la loi de Wien, en nanomètres-kelvins.
  static const double constanteWien = 2.898e6;

  /// La longueur d'onde du maximum d'émission, en nanomètres.
  ///
  /// Loi de Wien : le pic se déplace vers le bleu quand la température
  /// monte. À 5 778 K, la surface du Soleil, il tombe vers 500 nm,
  /// c'est-à-dire en plein milieu du visible — ce qui n'est pas une
  /// coïncidence, l'œil ayant évolué sous cette lumière.
  static double longueurDOndePic(double kelvins) => constanteWien / kelvins;

  /// La luminance spectrale de Planck, en unités arbitraires.
  ///
  /// Seuls les rapports comptent ici : la figure normalise ensuite. La
  /// formule est écrite avec la longueur d'onde en mètres, puis le
  /// résultat sert tel quel.
  static double planck(double nanometres, double kelvins) {
    const double h = 6.62607015e-34;
    const double c = 2.99792458e8;
    const double k = 1.380649e-23;
    final double lambda = nanometres * 1e-9;
    final double exposant = h * c / (lambda * k * kelvins);
    // Au-delà de 700, exp déborde en double et la valeur est de toute
    // façon indiscernable de zéro.
    if (exposant > 700) return 0;
    return 2 * h * c * c / (math.pow(lambda, 5) * (math.exp(exposant) - 1));
  }

  /// L'intensité ramenée à 1 sur son maximum dans le visible.
  static double intensiteRelative(double nanometres, double kelvins) {
    double maxi = 0;
    for (double l = visibleMin; l <= visibleMax; l += 2) {
      maxi = math.max(maxi, planck(l, kelvins));
    }
    if (maxi == 0) return 0;
    return planck(nanometres, kelvins) / maxi;
  }

  /// La couleur approchée d'une longueur d'onde visible.
  ///
  /// Approximation classique, suffisante pour un dessin : elle place le
  /// violet vers 400, le vert vers 550 et le rouge vers 700, et éteint
  /// les deux bords où l'œil ne voit presque plus rien.
  static Color couleurDe(double nm) {
    double r = 0;
    double v = 0;
    double b = 0;
    if (nm < 440) {
      r = -(nm - 440) / 60;
      b = 1;
    } else if (nm < 490) {
      v = (nm - 440) / 50;
      b = 1;
    } else if (nm < 510) {
      v = 1;
      b = -(nm - 510) / 20;
    } else if (nm < 580) {
      r = (nm - 510) / 70;
      v = 1;
    } else if (nm < 645) {
      r = 1;
      v = -(nm - 645) / 65;
    } else {
      r = 1;
    }
    // L'œil perd en sensibilité aux deux extrémités du visible.
    double attenuation = 1;
    if (nm < 420) {
      attenuation = 0.3 + 0.7 * (nm - 380) / 40;
    } else if (nm > 700) {
      attenuation = 0.3 + 0.7 * (750 - nm) / 50;
    }
    attenuation = attenuation.clamp(0, 1);
    return Color.fromARGB(
      255,
      (r * attenuation * 255).round().clamp(0, 255),
      (v * attenuation * 255).round().clamp(0, 255),
      (b * attenuation * 255).round().clamp(0, 255),
    );
  }

  /// Le nom courant de la couleur d'une étoile à cette température.
  ///
  /// Les seuils suivent la classification spectrale usuelle, arrondis :
  /// c'est ce qu'un observateur dirait en regardant, pas une mesure.
  static String teinte(double kelvins) {
    if (kelvins < 3700) return 'rouge';
    if (kelvins < 5200) return 'orange';
    if (kelvins < 6000) return 'jaune';
    if (kelvins < 7500) return 'blanc jaune';
    if (kelvins < 10000) return 'blanche';
    return 'bleue';
  }

  @override
  State<SpectrumFigure> createState() => _SpectrumFigureState();
}

class _SpectrumFigureState extends State<SpectrumFigure> {
  ElementSpectral _element = ElementSpectral.hydrogene;
  double _temperature = 5800;

  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // La température balaie du rouge au bleu ; l'élément ne change pas,
    // puisque la leçon porte précisément sur le fait que les raies ne
    // suivent pas la température.
    final double temperature = _tenue
        ? _temperature
        : Autoplay.sweepPas(
                context,
                min: SpectrumFigure.tMin,
                max: SpectrumFigure.tMax,
                pas: 500,
              ) ??
              _temperature;
    final double pic = SpectrumFigure.longueurDOndePic(temperature);
    final bool picVisible = pic >= SpectrumFigure.visibleMin &&
        pic <= SpectrumFigure.visibleMax;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (final ElementSpectral e in ElementSpectral.values)
              ChoiceChip(
                selected: e == _element,
                label: Text(
                  e.nom,
                  style: context.text.labelMedium?.copyWith(
                    color: e == _element
                        ? widget.accent
                        : context.colors.onSurface,
                  ),
                ),
                onSelected: (bool _) {
                  context.tapFeedback();
                  setState(() {
                    _tenue = true;
                    _element = e;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: 1.18,
          child: CustomPaint(
            painter: _SpectrePainter(
              element: _element,
              temperature: temperature,
              accent: widget.accent,
              ink: context.colors.onSurface,
              trait: tokens.border,
              muted: tokens.inkMuted,
              surface: context.colors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'T = ${NumericQuestion.formatNumber(
            (temperature / 100).roundToDouble() * 100,
          )} K   ·   étoile ${SpectrumFigure.teinte(temperature)}',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 16, color: widget.accent),
        ),
        Text(
          picVisible
              ? 'Maximum d’émission à '
                    '${NumericQuestion.formatNumber(pic.roundToDouble())} nm'
              : 'Maximum d’émission à '
                    '${NumericQuestion.formatNumber(pic.roundToDouble())} nm, '
                    'hors du visible',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        Text(
          'Les raies de ${_element.nom} ne bougent pas quand la '
          'température change : seule la couleur de fond change.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        Slider(
          value: temperature,
          min: SpectrumFigure.tMin,
          max: SpectrumFigure.tMax,
          divisions: 54,
          onChanged: (double v) {
            context.tapFeedback();
            setState(() {
              _tenue = true;
              _temperature = (v / 500).roundToDouble() * 500;
            });
          },
        ),
        Text(
          'Change l’élément, puis la température de l’étoile',
          textAlign: TextAlign.center,
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

class _SpectrePainter extends CustomPainter {
  const _SpectrePainter({
    required this.element,
    required this.temperature,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final ElementSpectral element;
  final double temperature;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    const double margeGauche = 10;
    const double margeDroite = 10;
    final double largeur = size.width - margeGauche - margeDroite;
    double x(double nm) =>
        margeGauche +
        largeur *
            (nm - SpectrumFigure.visibleMin) /
            (SpectrumFigure.visibleMax - SpectrumFigure.visibleMin);

    const double hautCourbe = 10;
    final double basCourbe = hautCourbe + (size.height - 40) * 0.38;
    // L'écart entre la courbe et la bande loge deux rangées
    // d'étiquettes : les raies voisines s'y décalent au lieu de se
    // superposer, et aucune ne doit déborder sur la courbe.
    final double hautBande = basCourbe + 28;
    final double basBande = size.height - 26;

    _courbeDePlanck(canvas, x, largeur, hautCourbe, basCourbe, margeGauche);
    _bandeSpectrale(canvas, x, largeur, hautBande, basBande, margeGauche);
    _reglette(canvas, x, basBande, size);
  }

  /// La courbe d'émission sur la portion visible.
  ///
  /// Elle est normalisée à chaque température : ce n'est donc pas la
  /// puissance totale qui se lit ici, c'est la répartition entre les
  /// couleurs. C'est bien ce dont on a besoin — une étoile chaude n'est
  /// pas seulement plus lumineuse, elle est différemment colorée.
  void _courbeDePlanck(
    Canvas canvas,
    double Function(double) x,
    double largeur,
    double haut,
    double bas,
    double margeGauche,
  ) {
    canvas.drawRect(
      Rect.fromLTRB(margeGauche, haut, margeGauche + largeur, bas),
      Paint()..color = surface,
    );

    final Path courbe = Path()..moveTo(margeGauche, bas);
    for (double nm = SpectrumFigure.visibleMin;
        nm <= SpectrumFigure.visibleMax;
        nm += 2) {
      final double i = SpectrumFigure.intensiteRelative(nm, temperature);
      courbe.lineTo(x(nm), bas - (bas - haut - 4) * i);
    }
    courbe
      ..lineTo(margeGauche + largeur, bas)
      ..close();
    canvas.drawPath(courbe, Paint()..color = accent.withValues(alpha: 0.22));
    canvas.drawPath(
      courbe,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Le pic, quand il tombe dans le visible. Hors du visible, le tracer
    // sur un bord laisserait croire qu'il s'y trouve.
    final double pic = SpectrumFigure.longueurDOndePic(temperature);
    if (pic > SpectrumFigure.visibleMin && pic < SpectrumFigure.visibleMax) {
      canvas.drawLine(
        Offset(x(pic), haut),
        Offset(x(pic), bas),
        Paint()
          ..color = ink.withValues(alpha: 0.5)
          ..strokeWidth = 1.2,
      );
      _texte(canvas, 'max', Offset(x(pic), haut + 2), muted, 10,
          centre: true);
    }
  }

  /// La bande colorée, et les raies que l'élément y prélève.
  void _bandeSpectrale(
    Canvas canvas,
    double Function(double) x,
    double largeur,
    double haut,
    double bas,
    double margeGauche,
  ) {
    // Colonne par colonne : la teinte vient de la longueur d'onde, la
    // clarté de l'intensité émise à cette température. Une étoile froide
    // a donc un bleu éteint et un rouge vif, et l'inverse pour une
    // chaude — sans qu'aucune couleur ne soit choisie à la main.
    for (double px = 0; px <= largeur; px += 1) {
      final double nm = SpectrumFigure.visibleMin +
          (SpectrumFigure.visibleMax - SpectrumFigure.visibleMin) *
              px /
              largeur;
      final double i = SpectrumFigure.intensiteRelative(nm, temperature);
      final Color teinte = SpectrumFigure.couleurDe(nm);
      canvas.drawRect(
        Rect.fromLTRB(margeGauche + px, haut, margeGauche + px + 1.2, bas),
        Paint()
          ..color = Color.fromARGB(
            255,
            (teinte.r * 255 * (0.25 + 0.75 * i)).round().clamp(0, 255),
            (teinte.g * 255 * (0.25 + 0.75 * i)).round().clamp(0, 255),
            (teinte.b * 255 * (0.25 + 0.75 * i)).round().clamp(0, 255),
          ),
      );
    }

    // Les raies d'absorption : le gaz de l'atmosphère stellaire prélève
    // exactement ces longueurs d'onde, et laisse du noir.
    //
    // Les étiquettes se décalent d'une ligne quand deux raies sont trop
    // proches — le fer en a six, dont quatre dans le bleu. Les
    // superposer rendrait illisible précisément l'élément qui demande le
    // plus d'attention.
    final List<double> visibles = <double>[
      for (final double raie in element.raies)
        if (raie >= SpectrumFigure.visibleMin &&
            raie <= SpectrumFigure.visibleMax)
          raie,
    ]..sort();
    double dernierX = double.negativeInfinity;
    bool basse = false;
    for (final double raie in visibles) {
      canvas.drawRect(
        Rect.fromLTRB(x(raie) - 1.6, haut, x(raie) + 1.6, bas),
        Paint()..color = const Color(0xFF101014),
      );
      basse = (x(raie) - dernierX) < 42 ? !basse : false;
      dernierX = x(raie);
      _texte(
        canvas,
        NumericQuestion.formatNumber(raie),
        Offset(x(raie), haut - (basse ? 12 : 23)),
        ink,
        9.5,
        centre: true,
      );
    }

    canvas.drawRect(
      Rect.fromLTRB(margeGauche, haut, margeGauche + largeur, bas),
      Paint()
        ..color = trait
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  /// La graduation en nanomètres.
  void _reglette(
    Canvas canvas,
    double Function(double) x,
    double bas,
    Size size,
  ) {
    final Paint crayon = Paint()
      ..color = trait
      ..strokeWidth = 1;
    for (int nm = 400; nm <= 700; nm += 100) {
      canvas.drawLine(
        Offset(x(nm.toDouble()), bas),
        Offset(x(nm.toDouble()), bas + 5),
        crayon,
      );
      _texte(
        canvas,
        '$nm nm',
        Offset(x(nm.toDouble()), bas + 7),
        muted,
        10,
        centre: true,
      );
    }
  }

  void _texte(
    Canvas canvas,
    String contenu,
    Offset ou,
    Color couleur,
    double taille, {
    bool centre = false,
  }) {
    final TextPainter peintre = TextPainter(
      text: TextSpan(
        text: contenu,
        style: AppTypography.formula(size: taille, color: couleur),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    peintre.paint(canvas, centre ? ou - Offset(peintre.width / 2, 0) : ou);
  }

  @override
  bool shouldRepaint(_SpectrePainter ancien) =>
      ancien.element != element ||
      ancien.temperature != temperature ||
      ancien.accent != accent;
}
