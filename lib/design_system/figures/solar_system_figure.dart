/// Le Système solaire à l'échelle des distances.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';

/// Une planète du Système solaire, avec les données utiles à la figure.
class Planete {
  const Planete({
    required this.nom,
    required this.distance,
    required this.diametre,
    required this.couleur,
  });

  final String nom;

  /// Demi-grand axe, en millions de kilomètres.
  final double distance;

  /// Diamètre équatorial, en kilomètres.
  final double diametre;

  final Color couleur;
}

/// Les huit planètes, dans l'ordre.
///
/// Valeurs usuelles arrondies : demi-grand axe en millions de kilomètres,
/// diamètre équatorial en kilomètres.
const List<Planete> planetes = <Planete>[
  Planete(nom: 'Mercure', distance: 58, diametre: 4879,
      couleur: Color(0xFF9E8B7D)),
  Planete(nom: 'Vénus', distance: 108, diametre: 12104,
      couleur: Color(0xFFE0B16A)),
  Planete(nom: 'Terre', distance: 150, diametre: 12756,
      couleur: Color(0xFF3B82F6)),
  Planete(nom: 'Mars', distance: 228, diametre: 6792,
      couleur: Color(0xFFC1440E)),
  Planete(nom: 'Jupiter', distance: 778, diametre: 142984,
      couleur: Color(0xFFD9A066)),
  Planete(nom: 'Saturne', distance: 1434, diametre: 120536,
      couleur: Color(0xFFE3D5A8)),
  Planete(nom: 'Uranus', distance: 2871, diametre: 51118,
      couleur: Color(0xFF8FD4D9)),
  Planete(nom: 'Neptune', distance: 4495, diametre: 49528,
      couleur: Color(0xFF4A6FD4)),
];

/// Les huit planètes placées à l'échelle de leurs distances au Soleil.
///
/// La leçon que la figure doit faire passer est que le Système solaire est
/// surtout du vide, et que ce vide n'est pas réparti également : les quatre
/// planètes rocheuses tiennent dans les trois premiers pour cent de la
/// largeur, et Neptune occupe le reste. Toute représentation « jolie », où
/// les planètes sont régulièrement espacées, détruit précisément ce
/// qu'il y a à comprendre.
///
/// Les tailles, elles, ne peuvent pas être à la même échelle : à l'échelle
/// des distances, la Terre ferait un centième de pixel. Elles suivent donc
/// une racine cubique, et la légende le dit plutôt que de laisser croire
/// à une double échelle.
class SolarSystemFigure extends StatefulWidget {
  const SolarSystemFigure({required this.accent, super.key});

  final Color accent;

  /// Vitesse de la lumière, en kilomètres par seconde.
  static const double vitesseLumiere = 299792.458;

  /// Minutes que met la lumière du Soleil pour parcourir [distance],
  /// exprimée en millions de kilomètres.
  static double minutesLumiere(double distance) =>
      distance * 1e6 / vitesseLumiere / 60;

  @override
  State<SolarSystemFigure> createState() => _SolarSystemFigureState();
}

class _SolarSystemFigureState extends State<SolarSystemFigure> {
  int _choisie = 2;

  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;

  /// Hauteur du dessin : deux axes et leurs graduations.
  static const double _hauteur = 196;

  /// Marge latérale, partagée avec le peintre.
  static const double _marge = 16;

  /// Durée du trajet de la lumière, du Soleil à la planète.
  String _tempsLumiere(int choisie) {
    final double minutes =
        SolarSystemFigure.minutesLumiere(planetes[choisie].distance);
    if (minutes < 60) return '${minutes.round()} min';
    final double heures = minutes / 60;
    return '${heures.toStringAsFixed(1).replaceAll('.', ',')} h';
  }

  /// Distance maximale portée par l'axe d'agrandissement.
  static const double _zoomMax = 250;

  void _choisirDepuis(Offset position, Size taille) {
    // Deux axes superposés : celui du haut porte tout le Système solaire,
    // celui du bas agrandit les quatre planètes rocheuses. On choisit
    // l'axe le plus proche du doigt, puis la planète la plus proche sur
    // cet axe — viser Mercure au doigt sur l'axe complet est impossible,
    // c'est précisément ce que l'agrandissement répare.
    final bool basAxe = position.dy > taille.height * 0.55;
    final double max = basAxe ? _zoomMax : planetes.last.distance;
    final double fraction =
        ((position.dx - _marge) / (taille.width - _marge * 2)).clamp(0.0, 1.0);

    double meilleure = double.infinity;
    int index = _choisie;
    for (int i = 0; i < planetes.length; i++) {
      if (basAxe && planetes[i].distance > max) continue;
      final double ecart = (planetes[i].distance / max - fraction).abs();
      if (ecart < meilleure) {
        meilleure = ecart;
        index = i;
      }
    }
    if (index != _choisie || !_tenue) {
      context.tapFeedback();
      setState(() {
        _tenue = true;
        _choisie = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // Les planètes sont désignées à tour de rôle, de Mercure à Neptune :
    // l'échelle des distances se parcourt d'elle-même, et c'est le vide
    // entre les géantes qui finit par sauter aux yeux.
    final int? defile = Autoplay.index(context, planetes.length);
    final int choisie = _tenue || defile == null ? _choisie : defile;
    final Planete planete = planetes[choisie];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double largeur = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (TapDownDetails d) =>
                  _choisirDepuis(d.localPosition, Size(largeur, _hauteur)),
              onPanUpdate: (DragUpdateDetails d) =>
                  _choisirDepuis(d.localPosition, Size(largeur, _hauteur)),
              child: Semantics(
                label:
                    'Système solaire à l\'échelle des distances. '
                    'Planète choisie : ${planete.nom}, '
                    '${planete.distance.round()} millions de kilomètres '
                    'du Soleil.',
                child: SizedBox(
                  width: largeur,
                  height: _hauteur,
                  child: CustomPaint(
                    painter: _SystemePainter(
                      choisie: choisie,
                      zoomMax: _zoomMax,
                      marge: _marge,
                      accent: widget.accent,
                      ink: context.colors.onSurface,
                      muted: tokens.inkMuted,
                      trait: tokens.border,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Text(planete.nom, style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_format(planete.distance)} millions de km du Soleil',
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        Text(
          'La lumière du Soleil met ${_tempsLumiere(choisie)} pour y arriver',
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.pan_tool_alt_rounded, size: 15, color: tokens.inkSubtle),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                'Glisse sur un axe — distances à l\'échelle, tailles non',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkSubtle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _format(double value) =>
      value.round().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (Match m) => '${m[1]} ',
      );
}

class _SystemePainter extends CustomPainter {
  const _SystemePainter({
    required this.choisie,
    required this.zoomMax,
    required this.marge,
    required this.accent,
    required this.ink,
    required this.muted,
    required this.trait,
  });

  final int choisie;
  final double zoomMax;
  final double marge;
  final Color accent;
  final Color ink;
  final Color muted;
  final Color trait;

  /// Rayon dessiné d'une planète.
  ///
  /// Les tailles ne peuvent pas suivre l'échelle des distances : la Terre
  /// y ferait un centième de pixel. Une racine cubique ramène le rapport
  /// de trente entre Mercure et Jupiter à un rapport de trois — lisible,
  /// et fidèle à l'ordre des grandeurs. La légende le dit.
  double _rayon(double diametre) =>
      3 + math.pow(diametre / 4879, 1 / 3) * 2.6;

  @override
  void paint(Canvas canvas, Size size) {
    final double utile = size.width - marge * 2;
    const double yComplet = 46;
    const double yZoom = 134;

    double x(double distance, double max) => marge + utile * (distance / max);

    // ---- Axe du haut : tout le Système solaire ------------------------
    _axe(canvas, yComplet, size);
    // Le Soleil, en bout d'axe. Il n'est pas une planète, et sa taille
    // réelle écraserait tout le reste.
    canvas.drawCircle(
      Offset(marge, yComplet),
      8,
      Paint()..color = const Color(0xFFFFB020),
    );

    final double maxComplet = planetes.last.distance;
    for (int i = 0; i < planetes.length; i++) {
      // Sur l'axe complet, on ne nomme que les géantes : les quatre
      // rocheuses y sont entassées contre le Soleil, et leur étiquette
      // se chevaucherait. Elles sont nommées sur l'axe du bas.
      _planete(canvas, i, Offset(x(planetes[i].distance, maxComplet), yComplet),
          etiquette: planetes[i].distance > zoomMax);
    }
    for (int milliers = 1; milliers <= 4; milliers++) {
      _graduation(canvas, x(milliers * 1000.0, maxComplet), yComplet,
          '$milliers 000');
    }
    _texte(canvas, 'millions de km', Offset(size.width / 2, yComplet + 36),
        muted, 10, false);

    // ---- Lien entre les deux axes -------------------------------------
    // La portion agrandie, marquée sur l'axe du haut puis élargie à toute
    // la largeur en dessous : sans ce repère, le second axe passerait pour
    // un autre système.
    final double finZoom = x(zoomMax, maxComplet);
    final Paint voile = Paint()..color = accent.withValues(alpha: 0.12);
    canvas.drawRect(
      Rect.fromLTRB(marge - 4, yComplet - 16, finZoom + 4, yComplet + 16),
      voile,
    );
    final Path entonnoir = Path()
      ..moveTo(marge - 4, yComplet + 16)
      ..lineTo(finZoom + 4, yComplet + 16)
      ..lineTo(size.width - marge, yZoom - 20)
      ..lineTo(marge, yZoom - 20)
      ..close();
    canvas.drawPath(entonnoir, voile);

    // ---- Axe du bas : les quatre planètes rocheuses -------------------
    _axe(canvas, yZoom, size);
    canvas.drawCircle(
      Offset(marge, yZoom),
      11,
      Paint()..color = const Color(0xFFFFB020),
    );
    for (int i = 0; i < planetes.length; i++) {
      if (planetes[i].distance > zoomMax) continue;
      _planete(canvas, i, Offset(x(planetes[i].distance, zoomMax), yZoom),
          etiquette: true);
    }
    for (final double repere in <double>[100, 200]) {
      _graduation(canvas, x(repere, zoomMax), yZoom, repere.round().toString());
    }
    _texte(
      canvas,
      'agrandissement des quatre premières',
      Offset(size.width / 2, yZoom + 36),
      muted,
      10,
      false,
    );
  }

  void _axe(Canvas canvas, double y, Size size) {
    canvas.drawLine(
      Offset(marge, y),
      Offset(size.width - marge, y),
      Paint()
        ..color = trait
        ..strokeWidth = 2,
    );
  }

  void _graduation(Canvas canvas, double cx, double y, String etiquette) {
    canvas.drawLine(
      Offset(cx, y + 9),
      Offset(cx, y + 14),
      Paint()
        ..color = trait
        ..strokeWidth = 1,
    );
    _texte(canvas, etiquette, Offset(cx, y + 24), muted, 10, false);
  }

  void _planete(
    Canvas canvas,
    int index,
    Offset centre, {
    required bool etiquette,
  }) {
    final Planete p = planetes[index];
    final double r = _rayon(p.diametre);
    final bool active = index == choisie;

    if (active) {
      canvas.drawCircle(
        centre,
        r + 7,
        Paint()..color = accent.withValues(alpha: 0.28),
      );
    }
    canvas.drawCircle(centre, r, Paint()..color = p.couleur);
    if (active) {
      canvas.drawCircle(
        centre,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent,
      );
    }
    if (etiquette) {
      _texte(
        canvas,
        p.nom,
        centre - Offset(0, r + 13),
        active ? ink : muted,
        11,
        active,
      );
    }
  }

  void _texte(
    Canvas canvas,
    String texte,
    Offset centre,
    Color couleur,
    double taille,
    bool gras,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          // Sans famille explicite, le texte peint hors de l'arbre des
          // widgets retombe sur la police par défaut — des rectangles
          // pleins dans les captures de référence.
          fontFamily: AppTypography.body,
          fontFamilyFallback: AppTypography.replis,
          color: couleur,
          fontSize: taille,
          fontWeight: gras ? FontWeight.w700 : FontWeight.w500,
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
  bool shouldRepaint(_SystemePainter old) =>
      old.choisie != choisie || old.accent != accent;
}
