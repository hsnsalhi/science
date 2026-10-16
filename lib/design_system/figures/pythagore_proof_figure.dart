/// Démonstration animée du théorème de Pythagore, par réarrangement.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Pose d'un triangle : sommet de l'angle droit, et quart de tour.
///
/// Publique parce que les quatre poses de chaque disposition ont été
/// établies à la main : c'est précisément ce qu'un test doit vérifier.
class ProofPose {
  const ProofPose(this.x, this.y, this.quarts);

  final double x;
  final double y;

  /// Rotation, en quarts de tour dans le sens horaire de l'écran.
  final int quarts;
}

/// La preuve par réarrangement, à faire glisser du bout du doigt.
///
/// Deux fois le même carré de côté a + b, et les quatre mêmes triangles
/// rectangles posés dedans. D'un côté ils laissent libres deux carrés, a²
/// et b² ; de l'autre, un seul, c². Comme le grand carré et les triangles
/// n'ont pas changé, les aires libres sont égales : a² + b² = c².
///
/// L'intérêt d'animer tient à un détail : les triangles ne se déforment
/// pas, ils glissent. C'est cela qu'une figure fixe ne peut pas montrer,
/// et c'est tout l'argument — on voit que rien n'est ajouté ni retiré.
class PythagoreProofFigure extends StatefulWidget {
  const PythagoreProofFigure({required this.accent, super.key});

  final Color accent;

  /// Côtés de l'angle droit. Trois et quatre : le triangle que tout le
  /// monde reconnaît, dont l'hypoténuse vaut cinq.
  static const double a = 3;
  static const double b = 4;

  /// Poses de départ : les triangles laissent libres a² et b².
  static const List<ProofPose> posesDepart = <ProofPose>[
    ProofPose(a, 0, 0),
    ProofPose(a, a, 1),
    ProofPose(a + b, a, 2),
    ProofPose(0, a + b, 3),
  ];

  /// Poses d'arrivée : les quatre hypoténuses bordent le carré c².
  static const List<ProofPose> posesArrivee = <ProofPose>[
    ProofPose(0, 0, 0),
    ProofPose(a + b, 0, 1),
    ProofPose(a + b, a + b, 2),
    ProofPose(0, a + b, 3),
  ];

  @override
  State<PythagoreProofFigure> createState() => _PythagoreProofFigureState();
}

class _PythagoreProofFigureState extends State<PythagoreProofFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..addListener(() => setState(() {}));

  bool _demarrageFait = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _basculer() {
    context.tapFeedback();
    if (_controller.isAnimating) {
      _controller.stop();
    } else if (_controller.value >= 0.999) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double t = Curves.easeInOutCubic.transform(_controller.value);

    if (!_demarrageFait) {
      _demarrageFait = true;
      if (!context.reduceMotion) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _controller.forward();
        });
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _PreuvePainter(
              t: t,
              a: PythagoreProofFigure.a,
              b: PythagoreProofFigure.b,
              depart: PythagoreProofFigure.posesDepart,
              arrivee: PythagoreProofFigure.posesArrivee,
              accent: widget.accent,
              ink: context.colors.onSurface,
              trait: tokens.border,
              surface: context.colors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          t < 0.5 ? 'a² + b²' : 'c²',
          style: AppTypography.formula(size: 20, color: widget.accent),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Même carré, mêmes triangles : l\'aire libre ne change pas.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            IconButton(
              onPressed: _basculer,
              tooltip: _controller.isAnimating
                  ? 'Arrêter'
                  : (_controller.value >= 0.999 ? 'Revenir' : 'Lancer'),
              icon: Icon(
                _controller.isAnimating
                    ? Icons.pause_rounded
                    : (_controller.value >= 0.999
                          ? Icons.replay_rounded
                          : Icons.play_arrow_rounded),
                color: widget.accent,
              ),
            ),
            Expanded(
              child: Slider(
                value: _controller.value,
                onChanged: (double v) {
                  _controller.stop();
                  _controller.value = v;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreuvePainter extends CustomPainter {
  const _PreuvePainter({
    required this.t,
    required this.a,
    required this.b,
    required this.depart,
    required this.arrivee,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.surface,
  });

  final double t;
  final double a;
  final double b;
  final List<ProofPose> depart;
  final List<ProofPose> arrivee;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    const double marge = 16;
    final double cote = a + b;
    final double echelle = (math.min(size.width, size.height) - marge * 2) /
        cote;
    final Offset origine = Offset(
      (size.width - cote * echelle) / 2,
      (size.height - cote * echelle) / 2,
    );

    Offset p(double x, double y) =>
        origine + Offset(x * echelle, y * echelle);

    // Le grand carré, identique d'un bout à l'autre : c'est lui qui rend
    // la comparaison valable.
    final Rect grand = Rect.fromPoints(p(0, 0), p(cote, cote));
    canvas.drawRect(grand, Paint()..color = surface);
    canvas.drawRect(
      grand,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = trait,
    );

    // Aires libres : les deux carrés s'effacent à mesure que celui de
    // l'hypoténuse apparaît.
    final Paint libre = Paint()..color = accent.withValues(alpha: 0.18 * (1 - t));
    canvas.drawRect(Rect.fromPoints(p(0, 0), p(a, a)), libre);
    canvas.drawRect(Rect.fromPoints(p(a, a), p(cote, cote)), libre);

    final Path incline = Path()
      ..moveTo(p(b, 0).dx, p(b, 0).dy)
      ..lineTo(p(cote, b).dx, p(cote, b).dy)
      ..lineTo(p(a, cote).dx, p(a, cote).dy)
      ..lineTo(p(0, a).dx, p(0, a).dy)
      ..close();
    canvas.drawPath(
      incline,
      Paint()..color = accent.withValues(alpha: 0.18 * t),
    );

    if (t < 0.5) {
      _etiquette(canvas, 'a²', p(a / 2, a / 2), accent, 1 - t * 2);
      _etiquette(canvas, 'b²', p(a + b / 2, a + b / 2), accent, 1 - t * 2);
    } else {
      _etiquette(canvas, 'c²', p(cote / 2, cote / 2), accent, t * 2 - 1);
    }

    // Les quatre triangles, qui glissent sans tourner ni se déformer.
    //
    // Ils partent l'un après l'autre : lancés ensemble, ils se croisaient
    // au milieu du parcours et le dessin devenait illisible juste au
    // moment où il fallait suivre les pièces. Décalés, on voit chacune
    // trouver sa place.
    for (int i = 0; i < depart.length; i++) {
      final ProofPose d = depart[i];
      final ProofPose f = arrivee[i];
      const double chevauchement = 0.18;
      final double debut = i * chevauchement;
      const double duree = 1 - 3 * chevauchement;
      final double part = ((t - debut) / duree).clamp(0.0, 1.0);
      final double x = d.x + (f.x - d.x) * part;
      final double y = d.y + (f.y - d.y) * part;
      final double angle = d.quarts * math.pi / 2;

      // Sommet de l'angle droit, puis les deux côtés dans le repère tourné.
      final Offset coin = p(x, y);
      final Offset versB = Offset(math.cos(angle), math.sin(angle)) *
          (b * echelle);
      final Offset versA = Offset(-math.sin(angle), math.cos(angle)) *
          (a * echelle);

      final Path triangle = Path()
        ..moveTo(coin.dx, coin.dy)
        ..lineTo(coin.dx + versB.dx, coin.dy + versB.dy)
        ..lineTo(coin.dx + versA.dx, coin.dy + versA.dy)
        ..close();

      canvas.drawPath(triangle, Paint()..color = accent.withValues(alpha: 0.75));
      canvas.drawPath(
        triangle,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = accent,
      );
    }
  }

  void _etiquette(
    Canvas canvas,
    String texte,
    Offset centre,
    Color couleur,
    double opacite,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          color: couleur.withValues(alpha: opacite.clamp(0.0, 1.0)),
          fontSize: 18,
          fontWeight: FontWeight.w800,
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
  bool shouldRepaint(_PreuvePainter old) => old.t != t || old.accent != accent;
}
