/// Célébration par confettis.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_tokens.dart';

/// Pluie de confettis jouée une fois, par-dessus un contenu.
///
/// Écrite à la main plutôt qu'avec un paquet dédié : une centaine de lignes
/// de [CustomPainter] suffisent, et l'application évite une dépendance de plus
/// à maintenir pour quatre secondes d'animation.
///
/// Respecte `context.reduceMotion` : l'enfant est alors affiché seul.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    required this.child,
    this.play = true,
    this.pieces = 70,
    this.colors,
    super.key,
  });

  final Widget child;

  /// Déclenche la pluie quand la valeur passe à `true`.
  final bool play;

  /// Nombre de confettis.
  final int pieces;

  /// Palette ; par défaut, les couleurs de marque et de récompense.
  final List<Color>? colors;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late List<_Piece> _confetti = <_Piece>[];

  @override
  void initState() {
    super.initState();
    if (widget.play) _start();
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) _start();
  }

  void _start() {
    if (!mounted) return;
    final math.Random rng = math.Random();
    _confetti = List<_Piece>.generate(
      widget.pieces,
      (int i) => _Piece.random(rng, i / widget.pieces),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    final List<Color> palette =
        widget.colors ??
        <Color>[
          context.colors.primary,
          context.tokens.gold,
          context.tokens.success,
          context.colors.secondary,
          context.tokens.info,
        ];
    return Stack(
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, _) => _controller.isDismissed
                  ? const SizedBox.shrink()
                  : CustomPaint(
                      painter: _ConfettiPainter(
                        pieces: _confetti,
                        progress: _controller.value,
                        palette: palette,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Un confetti et sa trajectoire.
class _Piece {
  _Piece({
    required this.x,
    required this.delay,
    required this.drift,
    required this.spin,
    required this.sizeFactor,
    required this.colorIndex,
    required this.isCircle,
  });

  factory _Piece.random(math.Random rng, double seed) => _Piece(
    x: rng.nextDouble(),
    // Un départ échelonné évite le « rideau » de confettis tous alignés.
    delay: seed * 0.45,
    drift: rng.nextDouble() * 2 - 1,
    spin: rng.nextDouble() * 6 - 3,
    sizeFactor: 0.6 + rng.nextDouble() * 0.9,
    colorIndex: rng.nextInt(1000),
    isCircle: rng.nextBool(),
  );

  /// Position horizontale de départ, de 0 à 1.
  final double x;

  /// Retard avant la chute, en fraction de l'animation.
  final double delay;

  /// Dérive horizontale.
  final double drift;

  /// Vitesse de rotation.
  final double spin;

  final double sizeFactor;
  final int colorIndex;
  final bool isCircle;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.pieces,
    required this.progress,
    required this.palette,
  });

  final List<_Piece> pieces;
  final double progress;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (final _Piece piece in pieces) {
      final double t = ((progress - piece.delay) / (1 - piece.delay)).clamp(
        0.0,
        1.0,
      );
      if (t <= 0) continue;

      // Chute accélérée, dérive sinusoïdale, disparition sur le dernier tiers.
      final double y = Curves.easeInQuad.transform(t) * (size.height + 60) - 30;
      final double x =
          piece.x * size.width +
          math.sin(t * math.pi * 2 + piece.drift * 3) * 28 * piece.drift;
      final double opacity = t > 0.7 ? (1 - (t - 0.7) / 0.3) : 1;
      final double side = 7 * piece.sizeFactor;

      paint.color = palette[piece.colorIndex % palette.length].withValues(
        alpha: opacity.clamp(0.0, 1.0),
      );

      canvas
        ..save()
        ..translate(x, y)
        ..rotate(t * piece.spin * math.pi);
      if (piece.isCircle) {
        canvas.drawCircle(Offset.zero, side / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: side,
              height: side * 0.55,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
