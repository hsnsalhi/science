/// Éclat de récompense joué sur une bonne réponse.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';

/// Gerbe de particules partant du centre, jouée à chaque bonne réponse.
///
/// Les confettis de fin de leçon récompensent le parcours entier ; il
/// manquait une récompense à l'échelle de la question. Sans elle, réussir
/// et se tromper se ressemblent : dans les deux cas un panneau de texte
/// s'ouvre. Cet éclat dure moins d'une seconde et ne retarde rien — il se
/// superpose au retour, qui s'affiche en même temps.
///
/// Respecte `context.reduceMotion` : l'enfant est alors affiché seul.
class RewardBurst extends StatefulWidget {
  const RewardBurst({
    required this.child,
    required this.trigger,
    this.color,
    this.pieces = 22,
    super.key,
  });

  final Widget child;

  /// Change de valeur pour déclencher un éclat. `null` ne joue rien.
  final Object? trigger;

  final Color? color;
  final int pieces;

  @override
  State<RewardBurst> createState() => _RewardBurstState();
}

class _RewardBurstState extends State<RewardBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );
  late List<_Spark> _sparks = _build(widget.pieces);

  static List<_Spark> _build(int count) {
    final math.Random random = math.Random(7);
    return List<_Spark>.generate(count, (int i) {
      // Les particules partent dans toutes les directions, avec juste
      // assez d'irrégularité pour que la gerbe ne ressemble pas à une
      // horloge.
      final double base = i / count * 2 * math.pi;
      return _Spark(
        angle: base + (random.nextDouble() - 0.5) * 0.45,
        distance: 0.55 + random.nextDouble() * 0.45,
        size: 3.5 + random.nextDouble() * 4.5,
        delay: random.nextDouble() * 0.12,
        round: random.nextBool(),
      );
    });
  }

  @override
  void didUpdateWidget(RewardBurst old) {
    super.didUpdateWidget(old);
    if (widget.pieces != old.pieces) _sparks = _build(widget.pieces);
    final Object? trigger = widget.trigger;
    if (trigger != null && trigger != old.trigger && !context.reduceMotion) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    final Color color = widget.color ?? Theme.of(context).colorScheme.primary;
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? _) {
                if (_controller.isDismissed) {
                  return const SizedBox.shrink();
                }
                return CustomPaint(
                  painter: _BurstPainter(
                    sparks: _sparks,
                    progress: _controller.value,
                    color: color,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Spark {
  const _Spark({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
    required this.round,
  });

  final double angle;

  /// Part du rayon disponible que la particule parcourt.
  final double distance;

  final double size;
  final double delay;
  final bool round;
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({
    required this.sparks,
    required this.progress,
    required this.color,
  });

  final List<_Spark> sparks;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = size.center(Offset.zero);
    final double rayon = math.min(size.width, size.height) * 0.72;

    for (final _Spark spark in sparks) {
      final double t = ((progress - spark.delay) / (1 - spark.delay))
          .clamp(0.0, 1.0);
      if (t <= 0) continue;
      // Départ vif, fin molle : la particule ralentit en s'éloignant.
      final double eased = 1 - math.pow(1 - t, 2.4).toDouble();
      final double d = eased * rayon * spark.distance;
      final Offset p = centre + Offset(
        math.cos(spark.angle) * d,
        math.sin(spark.angle) * d,
      );
      final Paint paint = Paint()
        ..color = color.withValues(alpha: (1 - t) * 0.9);
      final double taille = spark.size * (1 - t * 0.55);
      if (spark.round) {
        canvas.drawCircle(p, taille / 2, paint);
      } else {
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(spark.angle + t * 2.4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: taille,
              height: taille * 0.6,
            ),
            const Radius.circular(1.2),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) =>
      old.progress != progress || old.color != color;
}
