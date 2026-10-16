/// Le boulet de Newton : tirer assez fort pour rater la Terre.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'realism.dart';

/// Ce que devient un boulet tiré à une vitesse donnée.
enum Issue {
  /// Il retombe sur la Terre.
  retombe('Il retombe', 'Trop lent : la Terre ne se dérobe pas assez vite.'),

  /// Il décrit une orbite fermée.
  orbite(
    'Il est en orbite',
    'Il tombe toujours, mais la Terre se courbe autant que lui.',
  ),

  /// Il s'échappe pour de bon.
  echappe(
    'Il s\'échappe',
    'Au-delà de 11,2 km/s, il ne revient jamais.',
  );

  const Issue(this.titre, this.explication);

  final String titre;
  final String explication;
}

/// Le canon de Newton, au sommet d'une montagne.
///
/// L'expérience de pensée de 1687 est restée la meilleure explication d'une
/// orbite jamais trouvée, et elle tient en une image : un canon, une
/// montagne, et des boulets tirés de plus en plus fort. Le dernier ne
/// retombe pas — non parce qu'il a échappé à la gravité, mais parce que la
/// Terre se dérobe sous lui aussi vite qu'il tombe.
///
/// C'est tout l'intérêt de la figure, et c'est pourquoi la Terre doit y
/// être ronde et visiblement ronde. Dessinée sur un sol plat, l'expérience
/// perd son sujet : il n'y a plus de courbure à rattraper, et « être en
/// orbite » redevient un mot.
class NewtonCannonFigure extends StatefulWidget {
  const NewtonCannonFigure({required this.accent, super.key});

  final Color accent;

  /// Vitesse de satellisation au ras du sol, en kilomètres par seconde.
  static const double vitesseOrbitale = 7.9;

  /// Vitesse de libération, en kilomètres par seconde.
  static const double vitesseLiberation = 11.2;

  /// Ce que devient un boulet tiré à [vitesse] km/s.
  ///
  /// Les deux seuils ne sont pas inventés pour la figure : ce sont les
  /// deux vitesses cosmiques, et le test les recalcule depuis la masse et
  /// le rayon de la Terre plutôt que de les croire.
  static Issue issue(double vitesse) {
    if (vitesse < vitesseOrbitale) return Issue.retombe;
    if (vitesse >= vitesseLiberation) return Issue.echappe;
    return Issue.orbite;
  }

  /// Demi-grand axe de la trajectoire, en rayons terrestres.
  ///
  /// Pour un tir horizontal depuis la surface, la conservation de l'énergie
  /// donne a = R ÷ (2 − v²/v₀²), où v₀ est la vitesse orbitale rasante.
  /// L'ellipse a son autre foyer au centre de la Terre tant que le tir est
  /// trop lent, ce qui est exactement pourquoi le boulet revient taper au
  /// sol — et la figure le dessine ainsi plutôt que par une parabole
  /// approchée.
  static double demiGrandAxe(double vitesse) {
    final double rapport = vitesse / vitesseOrbitale;
    final double denominateur = 2 - rapport * rapport;
    if (denominateur <= 0) return double.infinity;
    return 1 / denominateur;
  }

  /// Excentricité de la trajectoire.
  static double excentricite(double vitesse) {
    final double rapport = vitesse / vitesseOrbitale;
    return (rapport * rapport - 1).abs();
  }

  @override
  State<NewtonCannonFigure> createState() => _NewtonCannonFigureState();
}

class _NewtonCannonFigureState extends State<NewtonCannonFigure> {
  double _vitesse = 5;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Issue issue = NewtonCannonFigure.issue(_vitesse);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 240,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return CustomPaint(
                  size: Size(contraintes.maxWidth, 240),
                  painter: _CanonPainter(
                    vitesse: _vitesse,
                    accent: widget.accent,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          issue.titre,
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          issue.explication,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            SizedBox(
              width: 56,
              child: Text(
                'vitesse',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkSubtle,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _vitesse,
                min: 2,
                max: 13,
                divisions: 44,
                onChanged: (double v) {
                  context.tapFeedback();
                  setState(() => _vitesse = v);
                },
              ),
            ),
            SizedBox(
              width: 62,
              child: Text(
                '${_vitesse.toStringAsFixed(1).replaceAll('.', ',')} km/s',
                textAlign: TextAlign.right,
                style: AppTypography.formula(
                  size: 13,
                  color: widget.accent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CanonPainter extends CustomPainter {
  const _CanonPainter({required this.vitesse, required this.accent});

  final double vitesse;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    _espace(canvas, size);

    // La Terre occupe le bas de l'image, et sa courbure doit se voir : sur
    // un sol plat, l'expérience de Newton n'a plus de sujet.
    final double rayon = size.width * 0.62;
    final Offset centre = Offset(size.width / 2, size.height + rayon * 0.70);

    _terre(canvas, centre, rayon);
    final Offset bouche = _montagne(canvas, centre, rayon);
    _trajectoire(canvas, centre, rayon, bouche);
  }

  /// Le vide étoilé.
  void _espace(Canvas canvas, Size size) {
    final Rect cadre = Offset.zero & size;
    canvas.drawRect(
      cadre,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF05070F), Color(0xFF16233C)],
        ).createShader(cadre),
    );
    final math.Random alea = math.Random(91);
    for (int i = 0; i < 60; i++) {
      canvas.drawCircle(
        Offset(
          alea.nextDouble() * size.width,
          alea.nextDouble() * size.height * 0.8,
        ),
        alea.nextDouble() * 1.1 + 0.3,
        Paint()
          ..color = Colors.white.withValues(
            alpha: 0.2 + alea.nextDouble() * 0.55,
          ),
      );
    }
  }

  /// La Terre : océans, continents, atmosphère.
  void _terre(Canvas canvas, Offset centre, double rayon) {
    Realisme.atmosphere(
      canvas,
      centre,
      rayon,
      couleur: const Color(0xFF86C2F2),
    );
    Realisme.sphere(
      canvas,
      centre,
      rayon,
      couleur: const Color(0xFF1C5C9E),
      lumiere: const Offset(-0.5, -0.65),
    );
    Realisme.continents(canvas, centre, rayon, graine: 8, nombre: 14);
    // Quelques nuages, qui achèvent de dire « vue depuis l'espace ».
    final math.Random alea = math.Random(23);
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: centre, radius: rayon)),
    );
    for (int i = 0; i < 10; i++) {
      final double theta = alea.nextDouble() * math.pi - math.pi;
      final double r = rayon * (0.3 + alea.nextDouble() * 0.65);
      canvas.drawOval(
        Rect.fromCenter(
          center: centre + Offset(math.cos(theta) * r, math.sin(theta) * r),
          width: 30 + alea.nextDouble() * 60,
          height: 10 + alea.nextDouble() * 14,
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.restore();
  }

  /// La montagne et son canon. Rend la position de la bouche.
  Offset _montagne(Canvas canvas, Offset centre, double rayon) {
    // Au sommet du globe, là où la courbure se lit le mieux.
    final Offset sommet = Offset(centre.dx, centre.dy - rayon);
    const double hauteur = 34;

    // Newton la voulait « très haute, au-dessus de l'atmosphère » — sans
    // quoi l'air freinerait le boulet et l'expérience ne dirait rien.
    // Des flancs brisés plutôt que deux droites : une montagne n'est pas
    // une pyramide, et le profil irrégulier est ce qui la rend crédible.
    final Path roche = Path()
      ..moveTo(sommet.dx - 44, sommet.dy + 8)
      ..lineTo(sommet.dx - 27, sommet.dy - 11)
      ..lineTo(sommet.dx - 18, sommet.dy - 9)
      ..lineTo(sommet.dx - 4, sommet.dy - hauteur)
      ..lineTo(sommet.dx + 6, sommet.dy - hauteur + 9)
      ..lineTo(sommet.dx + 14, sommet.dy - 14)
      ..lineTo(sommet.dx + 26, sommet.dy - 12)
      ..lineTo(sommet.dx + 46, sommet.dy + 9)
      ..close();
    canvas.drawPath(
      roche,
      Realisme.chair(roche.getBounds(), const Color(0xFF6E6257)),
    );
    // De la neige au sommet : une montagne assez haute pour sortir de
    // l'air est une montagne enneigée.
    canvas.drawPath(
      Path()
        ..moveTo(sommet.dx - 12, sommet.dy - hauteur + 14)
        ..lineTo(sommet.dx - 7, sommet.dy - hauteur + 6)
        ..lineTo(sommet.dx - 4, sommet.dy - hauteur)
        ..lineTo(sommet.dx + 6, sommet.dy - hauteur + 9)
        ..lineTo(sommet.dx + 10, sommet.dy - hauteur + 17)
        ..lineTo(sommet.dx + 2, sommet.dy - hauteur + 13)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.88),
    );

    // Le canon, pointé à l'horizontale : c'est la vitesse de côté qui met
    // en orbite, et un canon incliné brouillerait ce point.
    final Offset culasse = Offset(sommet.dx - 6, sommet.dy - hauteur + 6);
    final Offset bouche = culasse + const Offset(26, -1);
    canvas.drawLine(
      culasse,
      bouche,
      Paint()
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3A3A40),
    );
    canvas.drawCircle(culasse, 5, Paint()..color = const Color(0xFF2B2B30));
    return bouche;
  }

  /// La trajectoire, calculée comme une conique et non approchée.
  void _trajectoire(
    Canvas canvas,
    Offset centre,
    double rayon,
    Offset bouche,
  ) {
    // Le tir est horizontal depuis l'apogée (ou le périgée) de l'orbite :
    // l'ellipse a donc son grand axe vertical, un foyer au centre de la
    // Terre, et le point de tir sur son contour. On la dessine par
    // l'équation polaire d'une conique, ce qui donne la vraie forme —
    // ellipse rentrante, cercle, ellipse sortante, puis hyperbole.
    final double rapport = vitesse / NewtonCannonFigure.vitesseOrbitale;
    final double rTir = (bouche - centre).distance;
    final double e = (rapport * rapport - 1).abs();
    // Paramètre de la conique : p = r₀ × (v/v₀)², avec r₀ le rayon de tir.
    final double p = rTir * rapport * rapport;
    // L'angle du point de tir, mesuré depuis la verticale haute.
    final double angleTir = math.atan2(
      bouche.dx - centre.dx,
      centre.dy - bouche.dy,
    );
    // Trop lent : le périgée est du côté opposé, donc le boulet part du
    // point le plus haut de sa trajectoire. Trop rapide : il en part du
    // plus bas. Le signe suit.
    final bool rentrante = rapport < 1;

    final Path chemin = Path();
    bool commence = false;
    bool touche = false;
    for (double t = 0; t <= math.pi * 2; t += 0.012) {
      // Anomalie vraie, comptée depuis le point de tir.
      final double nu = rentrante ? math.pi + t : t;
      final double denominateur = 1 + e * math.cos(nu);
      if (denominateur <= 0.001) break;
      final double r = p / denominateur;
      if (r > rayon * 9) break;
      final double theta = angleTir + t;
      final Offset point = centre +
          Offset(math.sin(theta) * r, -math.cos(theta) * r);
      if (!commence) {
        chemin.moveTo(point.dx, point.dy);
        commence = true;
      } else {
        chemin.lineTo(point.dx, point.dy);
      }
      // Le boulet s'arrête s'il touche le sol, et c'est le fait central :
      // ce n'est pas la trajectoire qui change de nature, c'est qu'elle
      // rencontre la Terre ou non.
      if (t > 0.05 && r <= rayon) {
        touche = true;
        break;
      }
    }

    canvas.drawPath(
      chemin,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = accent.withValues(alpha: 0.95),
    );

    // Le point d'impact, s'il y en a un.
    if (touche) {
      final ui = chemin.computeMetrics().last;
      final Offset fin = ui.getTangentForOffset(ui.length)!.position;
      canvas.drawCircle(
        fin,
        5,
        Paint()
          ..color = const Color(0xFFE2603C)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // Le boulet, à la bouche du canon.
    canvas.drawCircle(bouche, 3.6, Paint()..color = const Color(0xFF1D1D22));
    canvas.drawCircle(
      bouche.translate(-1, -1),
      1.3,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_CanonPainter old) =>
      old.vitesse != vitesse || old.accent != accent;
}
