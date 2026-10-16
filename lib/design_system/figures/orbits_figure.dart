/// Les orbites des planètes internes, vues de dessus.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'solar_system_figure.dart';

/// Période de révolution, en jours terrestres.
///
/// La liste suit l'ordre de [planetes], Mercure d'abord : les deux tables
/// s'indexent ensemble, ce qui permet de confronter une période à une
/// distance sans recopier l'une ni l'autre. La figure ne dessine que les
/// quatre premières, les seules dont l'orbite tienne à l'écran, mais la loi
/// de Kepler ne s'arrête pas à Mars et le chapitre du lycée l'éprouve sur
/// les huit.
const List<double> periodes = <double>[
  88,
  225,
  365,
  687,
  4333,
  10759,
  30687,
  60190,
];

/// Les quatre planètes rocheuses tournant autour du Soleil.
///
/// Le chapitre affirme que plus une planète est loin, plus son année est
/// longue. Écrit, c'est une phrase de plus à croire ; montré, cela se
/// constate : au bout d'une année terrestre, Mercure a fait quatre tours
/// et Mars pas la moitié d'un.
///
/// Le temps avance tout seul, et se reprend à la main. Sous « réduire les
/// animations », la figure démarre à l'arrêt : le curseur suffit à tout
/// voir, personne n'est obligé de subir un mouvement continu.
class OrbitsFigure extends StatefulWidget {
  const OrbitsFigure({required this.accent, super.key});

  final Color accent;

  @override
  State<OrbitsFigure> createState() => _OrbitsFigureState();
}

class _OrbitsFigureState extends State<OrbitsFigure>
    with SingleTickerProviderStateMixin {
  /// Durée d'un tour complet de Mars, la plus lente des quatre.
  static const Duration _cycle = Duration(seconds: 24);

  /// Jours couverts par un cycle complet de l'animation.
  static const double _joursParCycle = 687;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _cycle,
  )..addListener(_rafraichir);

  /// Jours écoulés depuis le départ.
  double _jours = 0;

  bool _enMarche = false;
  bool _demarrageFait = false;

  void _rafraichir() {
    setState(() => _jours = _controller.value * _joursParCycle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _basculer() {
    context.tapFeedback();
    setState(() {
      _enMarche = !_enMarche;
      if (_enMarche) {
        _controller.repeat(min: _controller.value, max: 1);
      } else {
        _controller.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;

    // Le mouvement ne se déclenche de lui-même que si l'élève n'a pas
    // demandé à les réduire.
    if (!_demarrageFait) {
      _demarrageFait = true;
      if (!context.reduceMotion) {
        _enMarche = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _enMarche) _controller.repeat();
        });
      }
    }

    final int annees = (_jours / 365).floor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.25,
          child: CustomPaint(
            painter: _OrbitesPainter(
              jours: _jours,
              accent: widget.accent,
              trait: tokens.border,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Les compteurs de tours font la démonstration : quatre nombres
        // partis ensemble, qui divergent sous les yeux. Posés ici plutôt
        // que peints dans le canevas, ils suivent le thème et ne
        // chevauchent plus les orbites.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (int i = 0; i < 4; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: planetes[i].couleur,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${planetes[i].nom} '
                    '${(_jours / periodes[i]).toStringAsFixed(1).replaceAll('.', ',')}',
                    style: context.text.labelSmall?.copyWith(
                      color: i == 2 ? widget.accent : tokens.inkMuted,
                      fontWeight: i == 2 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'tours effectués',
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          annees == 0
              ? '${_jours.round()} jours écoulés'
              : '${_jours.round()} jours — '
                    '$annees an${annees > 1 ? 's' : ''} sur Terre',
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            IconButton(
              onPressed: _basculer,
              tooltip: _enMarche ? 'Arrêter le temps' : 'Lancer le temps',
              icon: Icon(
                _enMarche ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.accent,
              ),
            ),
            Expanded(
              child: Slider(
                value: _controller.value,
                label: '${_jours.round()} j',
                onChanged: (double v) {
                  if (_enMarche) {
                    _controller.stop();
                    setState(() => _enMarche = false);
                  }
                  _controller.value = v;
                },
              ),
            ),
          ],
        ),
        Text(
          'Un tour de Mars = 687 jours',
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

class _OrbitesPainter extends CustomPainter {
  const _OrbitesPainter({
    required this.jours,
    required this.accent,
    required this.trait,
  });

  final double jours;
  final Color accent;
  final Color trait;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double rayonMax = math.min(size.width, size.height) / 2 - 22;
    final double distanceMax = planetes[3].distance;

    canvas.drawCircle(centre, 12, Paint()..color = const Color(0xFFFFB020));

    for (int i = 0; i < 4; i++) {
      final Planete p = planetes[i];
      // Les rayons suivent les distances réelles : Mars est trois fois
      // plus loin que Mercure, et cela doit se voir.
      final double rayon = rayonMax * (p.distance / distanceMax);
      canvas.drawCircle(
        centre,
        rayon,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = trait,
      );

      // Départ aligné : au bout d'une année terrestre, l'écart entre les
      // quatre positions est la démonstration même.
      final double angle = -math.pi / 2 + 2 * math.pi * (jours / periodes[i]);
      final Offset position =
          centre + Offset(math.cos(angle) * rayon, math.sin(angle) * rayon);

      final double taille = 4 + (i == 2 ? 2 : 0);
      canvas.drawCircle(position, taille, Paint()..color = p.couleur);
      if (i == 2) {
        canvas.drawCircle(
          position,
          taille + 4,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = accent,
        );
      }

    }
  }

  @override
  bool shouldRepaint(_OrbitesPainter old) => old.jours != jours;
}
