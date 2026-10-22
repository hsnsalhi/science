/// Le ballon à col de cygne de Pasteur : trois montages, quatre jours.
library;

import 'dart:math' as math;
import 'dart:ui' show PathMetric, Tangent;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Le montage choisi par l'élève.
enum MontagePasteur {
  /// Col ouvert, droit : l'air entre et la poussière avec lui.
  ouvert('Col ouvert', 'Le col est droit et ouvert sur la pièce.'),

  /// Col de cygne : l'air entre, la poussière reste au creux.
  colDeCygne('Col de cygne', 'Le col descend puis remonte. L’air passe.'),

  /// Col de cygne penché : le bouillon va chercher la poussière.
  penche('Col penché', 'On incline le ballon jusqu’au creux du col.');

  const MontagePasteur(this.etiquette, this.description);

  /// Nom court, pour le bouton.
  final String etiquette;

  /// Ce que l'élève doit comprendre du montage.
  final String description;

  /// `true` si le bouillon se trouble.
  ///
  /// C'est tout le résultat de l'expérience de 1861, et il tient en une
  /// ligne : ce n'est pas l'air qui gâte le bouillon, c'est ce que l'air
  /// transporte. Le col de cygne laisse passer le premier et retient le
  /// second ; l'incliner suffit à ramener le trouble, ce qui interdit
  /// d'accuser un « air vicié » par le coude.
  bool get seTrouble => this != MontagePasteur.colDeCygne;
}

/// L'expérience de Pasteur, que l'élève monte et laisse reposer.
///
/// L'intérêt du montage n'est pas qu'il donne la bonne réponse : c'est
/// qu'il interdit la mauvaise. Un bouillon bouilli dans un ballon fermé
/// reste clair, et les partisans de la génération spontanée répondaient
/// — raisonnablement — qu'on avait étouffé la vie en coupant l'air. Le col
/// de cygne enlève cette échappatoire : l'air entre librement, et le
/// bouillon reste clair quand même. Reste la poussière, et le troisième
/// montage le prouve en inclinant le ballon.
///
/// L'élève a donc deux commandes, et l'ordre importe : il choisit un
/// montage, puis il fait passer les jours. Un seul montage lui apprendrait
/// un fait ; les trois lui apprennent une expérience.
class SwanNeckFigure extends StatefulWidget {
  const SwanNeckFigure({required this.accent, super.key});

  /// Couleur d'accent de la matière, pour les repères et les commandes.
  final Color accent;

  /// Durée simulée, en jours.
  static const int joursMax = 4;

  /// Trouble du bouillon, de 0 (limpide) à 1 (opaque).
  ///
  /// La culture démarre lentement puis s'emballe : quelques bactéries ne
  /// se voient pas, et chaque division double leur nombre. On modélise
  /// donc une courbe en S, et pas une rampe — une rampe enseignerait que
  /// la vie apparaît un peu partout un peu tout le temps.
  static double trouble(MontagePasteur montage, double jours) {
    if (!montage.seTrouble) return 0;
    final double t = (jours / joursMax).clamp(0.0, 1.0);
    // Décalage d'un demi-jour : le premier jour ne montre rien, ce qui est
    // le piège de l'expérience — on conclut trop tôt.
    final double avance = ((t - 0.18) / 0.82).clamp(0.0, 1.0);
    return avance * avance * (3 - 2 * avance);
  }

  @override
  State<SwanNeckFigure> createState() => _SwanNeckFigureState();
}

class _SwanNeckFigureState extends State<SwanNeckFigure> {
  MontagePasteur _montage = MontagePasteur.ouvert;
  double _jours = 0;

  void _choisirMontage(MontagePasteur montage) {
    if (montage == _montage) return;
    setState(() {
      _montage = montage;
      // Changer de montage, c'est refaire l'expérience : on repart à zéro,
      // sinon l'élève croit que le bouillon se décante.
      _jours = 0;
    });
    context.tapFeedback();
  }

  void _reglerJours(double valeur) {
    final double jours = (valeur * 2).roundToDouble() / 2;
    if (jours == _jours) return;
    final bool troubleAvant = SwanNeckFigure.trouble(_montage, _jours) > 0.5;
    setState(() => _jours = jours);
    if (SwanNeckFigure.trouble(_montage, jours) > 0.5 && !troubleAvant) {
      context.errorFeedback();
    } else {
      context.tapFeedback();
    }
  }

  String get _verdict {
    final double trouble = SwanNeckFigure.trouble(_montage, _jours);
    if (_jours == 0) return 'Le bouillon vient d’être bouilli : il est stérile.';
    if (trouble == 0) {
      return 'Quatre jours d’air libre, et toujours limpide. '
          'Ce n’est donc pas l’air.';
    }
    if (trouble < 0.25) return 'Rien à l’œil nu… pour l’instant.';
    if (trouble < 0.7) return 'Le bouillon se voile : quelque chose y pousse.';
    return 'Trouble, et il sent mauvais. La poussière portait du vivant.';
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double trouble = SwanNeckFigure.trouble(_montage, _jours);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          children: <Widget>[
            for (final MontagePasteur montage in MontagePasteur.values)
              ChoiceChip(
                label: Text(montage.etiquette),
                selected: _montage == montage,
                onSelected: (_) => _choisirMontage(montage),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 212,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return CustomPaint(
                  size: Size(contraintes.maxWidth, 212),
                  painter: _BallonPainter(
                    montage: _montage,
                    trouble: trouble,
                    jours: _jours,
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
          _montage.description,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        Row(
          children: <Widget>[
            SizedBox(
              width: 46,
              child: Text(
                'jours',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkSubtle,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _jours,
                max: SwanNeckFigure.joursMax.toDouble(),
                divisions: SwanNeckFigure.joursMax * 2,
                label: _jours == _jours.roundToDouble()
                    ? '${_jours.round()} j'
                    : '${_jours.toStringAsFixed(1).replaceAll('.', ',')} j',
                onChanged: _reglerJours,
              ),
            ),
            SizedBox(
              width: 34,
              child: Text(
                '${_jours.round()} j',
                textAlign: TextAlign.right,
                style: AppTypography.formula(size: 14, color: widget.accent),
              ),
            ),
          ],
        ),
        Text(
          _verdict,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(
            color: trouble > 0.25 ? tokens.error : tokens.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Le ballon de verre, son col, son bouillon et sa poussière.
class _BallonPainter extends CustomPainter {
  const _BallonPainter({
    required this.montage,
    required this.trouble,
    required this.jours,
    required this.accent,
    required this.tokens,
  });

  final MontagePasteur montage;
  final double trouble;
  final double jours;
  final Color accent;
  final AppTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = tokens.surfaceAlt,
    );

    // Le ballon penché l'est pour de bon : on tourne la scène, comme la
    // main de l'expérimentateur incline le verre.
    final double inclinaison =
        montage == MontagePasteur.penche ? -0.22 : 0.0;
    final Offset centre = Offset(size.width * 0.42, size.height * 0.66);

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(inclinaison);
    canvas.translate(-centre.dx, -centre.dy);

    final double rayon = math.min(size.width * 0.19, size.height * 0.26);
    _dessinerSupport(canvas, centre, rayon);
    final Path col = _cheminDuCol(centre, rayon, size);
    _dessinerBouillon(canvas, centre, rayon);
    _dessinerVerre(canvas, centre, rayon, col);
    _dessinerPoussiere(canvas, centre, rayon, size, col);

    canvas.restore();

    _dessinerLegende(canvas, size);
  }

  /// Le trépied : un ballon de laboratoire ne flotte pas.
  void _dessinerSupport(Canvas canvas, Offset centre, double rayon) {
    final Paint metal = Paint()
      ..color = tokens.inkSubtle.withValues(alpha: 0.55)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final double base = centre.dy + rayon * 1.04;
    canvas.drawLine(
      Offset(centre.dx - rayon * 0.9, base),
      Offset(centre.dx + rayon * 0.9, base),
      metal,
    );
    // Deux pieds obliques sous le plateau, à l'écart du verre.
    for (final double cote in <double>[-1, 1]) {
      canvas.drawLine(
        Offset(centre.dx + cote * rayon * 0.74, base),
        Offset(centre.dx + cote * rayon * 0.95, base + rayon * 0.2),
        metal,
      );
    }
  }

  /// Le col : droit, ou descendu puis remonté comme un cou de cygne.
  Path _cheminDuCol(Offset centre, double rayon, Size size) {
    final Offset depart = Offset(centre.dx, centre.dy - rayon * 0.97);
    final Path chemin = Path()..moveTo(depart.dx, depart.dy);
    if (montage == MontagePasteur.ouvert) {
      chemin.lineTo(depart.dx, depart.dy - rayon * 1.5);
      return chemin;
    }
    // Le vrai col de cygne de 1861 : il monte un peu, plonge vers le bas
    // en un U franc, puis remonte s'ouvrir à l'air. Le creux du U est le
    // piège à poussière, et c'est la seule pièce qui compte.
    final double hautCol = depart.dy - rayon * 0.72;
    final double creux = depart.dy - rayon * 0.05;
    final double droite = centre.dx + rayon * 1.72;
    chemin
      ..lineTo(depart.dx, hautCol)
      ..cubicTo(
        depart.dx + rayon * 0.28,
        hautCol - rayon * 0.26,
        depart.dx + rayon * 0.72,
        creux - rayon * 0.42,
        depart.dx + rayon * 0.8,
        creux,
      )
      ..cubicTo(
        depart.dx + rayon * 0.88,
        creux + rayon * 0.34,
        droite - rayon * 0.12,
        creux + rayon * 0.26,
        droite,
        creux - rayon * 0.24,
      )
      ..lineTo(droite + rayon * 0.14, depart.dy - rayon * 1.1);
    return chemin;
  }

  /// Le bouillon : ambré et limpide, ou voilé jusqu'à l'opacité.
  void _dessinerBouillon(Canvas canvas, Offset centre, double rayon) {
    final double niveau = centre.dy - rayon * 0.12;
    final Path liquide = Path()
      ..addArc(
        Rect.fromCircle(center: centre, radius: rayon * 0.94),
        0,
        math.pi,
      )
      ..close();
    final Path cuve = Path.combine(
      PathOperation.intersect,
      liquide,
      Path()
        ..addRect(
          Rect.fromLTRB(
            centre.dx - rayon,
            niveau,
            centre.dx + rayon,
            centre.dy + rayon,
          ),
        ),
    );

    // Un bouillon de levure de bière est ambré. Il se voile en virant au
    // gris-beige, il ne devient pas noir : le trouble est une diffusion de
    // la lumière, pas une teinture.
    const Color clair = Color(0xFFD9A14A);
    const Color voile = Color(0xFFB9AE96);
    canvas.drawPath(
      cuve,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.lerp(clair, voile, trouble)!.withValues(alpha: 0.78),
            Color.lerp(clair, voile, trouble)!.withValues(alpha: 0.95),
          ],
        ).createShader(
          Rect.fromLTRB(
            centre.dx - rayon,
            niveau,
            centre.dx + rayon,
            centre.dy + rayon,
          ),
        ),
    );

    // La surface : un ménisque, et son reflet. Sans lui, le liquide est un
    // aplat de couleur et le verre disparaît.
    canvas.drawLine(
      Offset(centre.dx - rayon * 0.9, niveau),
      Offset(centre.dx + rayon * 0.9, niveau),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1.6,
    );

    if (trouble > 0.2) {
      // Les flocons en suspension : ce qu'on voit vraiment dans un bouillon
      // contaminé, avant de parler de bactéries.
      final math.Random alea = math.Random(7);
      final Paint flocon = Paint()
        ..color = Colors.white.withValues(alpha: 0.26 * trouble);
      final int nombre = (34 * trouble).round();
      for (int i = 0; i < nombre; i++) {
        final double a = alea.nextDouble() * math.pi * 2;
        final double r = rayon * 0.88 * math.sqrt(alea.nextDouble());
        final Offset p = centre + Offset(math.cos(a) * r, math.sin(a) * r);
        if (p.dy < niveau) continue;
        canvas.drawCircle(p, 1.2 + alea.nextDouble() * 1.5, flocon);
      }
    }
  }

  /// Le verre : une paroi fine, un reflet net, pas un cercle au trait.
  void _dessinerVerre(Canvas canvas, Offset centre, double rayon, Path col) {
    final Paint paroi = Paint()
      ..color = tokens.inkMuted.withValues(alpha: 0.72)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(centre, rayon, paroi);
    canvas.drawPath(
      col,
      Paint()
        ..color = tokens.inkMuted.withValues(alpha: 0.72)
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    // L'intérieur du col, plus clair : c'est ce creux qui piège, il doit
    // se voir comme un volume et non comme un trait.
    canvas.drawPath(
      col,
      Paint()
        ..color = tokens.surfaceAlt.withValues(alpha: 0.95)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    // Le reflet en croissant, en haut à gauche.
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: rayon * 0.78),
      math.pi * 1.1,
      0.8,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  /// La poussière : dans l'air, et retenue au creux du col.
  void _dessinerPoussiere(
    Canvas canvas,
    Offset centre,
    double rayon,
    Size size,
    Path col,
  ) {
    final math.Random alea = math.Random(3);
    final Paint grain = Paint()..color = tokens.inkSubtle.withValues(alpha: 0.5);
    // L'air de la pièce en porte partout. On la montre, sinon le chapitre
    // parle d'un acteur invisible.
    for (int i = 0; i < 26; i++) {
      final Offset p = Offset(
        alea.nextDouble() * size.width,
        alea.nextDouble() * size.height * 0.5,
      );
      canvas.drawCircle(p, 0.9 + alea.nextDouble(), grain);
    }

    if (montage == MontagePasteur.ouvert) return;

    // Le tas au fond du U. On cherche le point le plus bas sur le tracé du
    // col plutôt que de le recalculer : les points de contrôle d'une
    // courbe de Bézier ne sont pas sur la courbe, et le tas finirait à
    // côté du creux qu'il est censé montrer.
    final Offset creux = _pointLePlusBas(col);
    final Paint tas = Paint()..color = tokens.warning.withValues(alpha: 0.85);
    for (int i = 0; i < 14; i++) {
      canvas.drawCircle(
        creux + Offset((alea.nextDouble() - 0.5) * 16, alea.nextDouble() * 4),
        1.9,
        tas,
      );
    }
    if (montage == MontagePasteur.penche && trouble > 0.05) {
      // Le bouillon est allé toucher le tas : on trace le trajet.
      canvas.drawLine(
        creux,
        Offset(centre.dx, centre.dy - rayon * 0.4),
        Paint()
          ..color = tokens.warning.withValues(alpha: 0.6)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Le point le plus bas d'un tracé, échantillonné le long de la courbe.
  Offset _pointLePlusBas(Path chemin) {
    Offset bas = Offset.zero;
    for (final PathMetric metrique in chemin.computeMetrics()) {
      const int echantillons = 80;
      for (int i = 0; i <= echantillons; i++) {
        final Tangent? t = metrique.getTangentForOffset(
          metrique.length * i / echantillons,
        );
        if (t == null) continue;
        if (bas == Offset.zero || t.position.dy > bas.dy) bas = t.position;
      }
    }
    return bas;
  }

  /// Deux repères écrits : l'air passe, la poussière reste.
  void _dessinerLegende(Canvas canvas, Size size) {
    final List<(String, Color)> lignes = switch (montage) {
      MontagePasteur.ouvert => <(String, Color)>[
          ('air + poussière', tokens.error),
        ],
      MontagePasteur.colDeCygne => <(String, Color)>[
          ('air : passe', tokens.success),
          ('poussière : piégée', tokens.warning),
        ],
      MontagePasteur.penche => <(String, Color)>[
          ('le bouillon touche le piège', tokens.error),
        ],
    };
    double y = size.height * 0.08;
    for (final (String texte, Color couleur) in lignes) {
      final TextPainter peintre = TextPainter(
        text: TextSpan(
          text: texte,
          style: TextStyle(
            fontFamily: AppTypography.body,
            fontFamilyFallback: AppTypography.replis,
            color: couleur,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width * 0.44);
      peintre.paint(canvas, Offset(10, y));
      y += peintre.height + 4;
    }
  }

  @override
  bool shouldRepaint(_BallonPainter ancien) =>
      ancien.montage != montage ||
      ancien.trouble != trouble ||
      ancien.jours != jours ||
      ancien.accent != accent ||
      ancien.tokens != tokens;
}
