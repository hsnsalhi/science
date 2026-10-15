/// Nova, la mascotte d'Eurêka.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';

/// Expression de Nova.
enum MascotMood {
  /// Au repos, sourire léger.
  calme,

  /// Content : grand sourire, yeux plissés.
  joyeux,

  /// En réflexion : un sourcil levé.
  pensif,

  /// Félicitations : yeux en étoile.
  bravo,

  /// Compatissant, après une erreur. Jamais triste ni accusateur.
  rassurant,
}

/// Mascotte dessinée au pinceau : un atome à visage.
///
/// Entièrement vectorielle et peinte par [CustomPainter], donc nette à toutes
/// les densités d'écran, sans aucun fichier image ni Lottie dans le dépôt.
/// C'est aussi ce qui permet de changer son expression ou sa couleur selon la
/// matière, ce qu'une illustration figée ne permettrait pas.
class Mascot extends StatefulWidget {
  const Mascot({
    this.mood = MascotMood.calme,
    this.size = 96,
    this.color,
    this.animate = true,
    super.key,
  });

  final MascotMood mood;
  final double size;

  /// Couleur du noyau ; par défaut la couleur de marque.
  final Color? color;

  /// Faire tourner les électrons et respirer le noyau.
  final bool animate;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Mascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  /// Démarre ou arrête la boucle selon les préférences de confort.
  ///
  /// Important au-delà du confort : une animation infinie qui tourne alors
  /// qu'on a demandé de les réduire consomme de la batterie et empêche tout
  /// test widget de se stabiliser.
  void _sync() {
    final bool shouldRun = widget.animate && !context.reduceMotion;
    if (shouldRun && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldRun && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.color ?? context.colors.primary;
    final bool still = context.reduceMotion || !widget.animate;
    return Semantics(
      label: 'Nova, la mascotte',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, _) => CustomPaint(
            painter: _MascotPainter(
              mood: widget.mood,
              color: color,
              progress: still ? 0.12 : _controller.value,
              electronColor: context.tokens.gold,
            ),
          ),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter({
    required this.mood,
    required this.color,
    required this.progress,
    required this.electronColor,
  });

  final MascotMood mood;
  final Color color;
  final Color electronColor;

  /// Phase de l'animation, de 0 à 1.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double unit = size.shortestSide;
    final double angle = progress * 2 * math.pi;

    // Respiration : le noyau grossit et rétrécit très légèrement.
    final double breathe = 1 + 0.02 * math.sin(angle * 2);
    final double nucleus = unit * 0.3 * breathe;

    _paintOrbits(canvas, center, unit, angle);
    _paintNucleus(canvas, center, nucleus);
    _paintFace(canvas, center, nucleus);
  }

  /// Deux orbites inclinées et leurs électrons.
  void _paintOrbits(Canvas canvas, Offset center, double unit, double angle) {
    final double rx = unit * 0.47;
    final double ry = unit * 0.19;
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, unit * 0.018)
      ..color = color.withValues(alpha: 0.35);

    for (int i = 0; i < 2; i++) {
      final double tilt = i == 0 ? math.pi / 5 : -math.pi / 5;
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(tilt);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        stroke,
      );

      // Électron sur l'orbite : les deux sont en opposition de phase.
      final double phase = angle + (i == 0 ? 0 : math.pi);
      final Offset electron = Offset(
        math.cos(phase) * rx,
        math.sin(phase) * ry,
      );
      canvas.drawCircle(electron, unit * 0.045, Paint()..color = electronColor);
      canvas.restore();
    }
  }

  void _paintNucleus(Canvas canvas, Offset center, double radius) {
    final Rect bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            Color.lerp(color, Colors.white, 0.18)!,
            Color.lerp(color, Colors.black, 0.1)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
    );
    // Reflet, pour que la sphère ne paraisse pas plate.
    canvas.drawCircle(
      center.translate(-radius * 0.32, -radius * 0.34),
      radius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  void _paintFace(Canvas canvas, Offset center, double radius) {
    final Paint ink = Paint()
      ..color = const Color(0xFF11162A)
      ..style = PaintingStyle.fill;
    final Paint line = Paint()
      ..color = const Color(0xFF11162A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.11
      ..strokeCap = StrokeCap.round;

    final double eyeDx = radius * 0.38;
    final double eyeDy = -radius * 0.12;
    final Offset leftEye = center.translate(-eyeDx, eyeDy);
    final Offset rightEye = center.translate(eyeDx, eyeDy);
    final double eyeR = radius * 0.13;

    switch (mood) {
      case MascotMood.calme:
      case MascotMood.rassurant:
        canvas
          ..drawCircle(leftEye, eyeR, ink)
          ..drawCircle(rightEye, eyeR, ink);
      case MascotMood.joyeux:
        // Yeux plissés : deux arcs vers le haut.
        for (final Offset eye in <Offset>[leftEye, rightEye]) {
          canvas.drawArc(
            Rect.fromCenter(center: eye, width: eyeR * 3, height: eyeR * 2.6),
            math.pi,
            math.pi,
            false,
            line,
          );
        }
      case MascotMood.pensif:
        canvas
          ..drawCircle(leftEye, eyeR, ink)
          ..drawCircle(rightEye, eyeR, ink)
          // Sourcil levé à droite.
          ..drawLine(
            rightEye.translate(-eyeR * 1.4, -eyeR * 2.4),
            rightEye.translate(eyeR * 1.4, -eyeR * 3.2),
            line,
          );
      case MascotMood.bravo:
        for (final Offset eye in <Offset>[leftEye, rightEye]) {
          _drawStar(canvas, eye, eyeR * 1.7, ink);
        }
    }

    // Bouche : la courbure porte l'émotion.
    final double mouthWidth = radius * 0.72;
    final double curve = switch (mood) {
      MascotMood.calme => radius * 0.2,
      MascotMood.joyeux => radius * 0.46,
      MascotMood.bravo => radius * 0.5,
      MascotMood.pensif => radius * 0.06,
      // Légèrement remontée : Nova encourage, elle ne boude pas.
      MascotMood.rassurant => radius * 0.14,
    };
    final Offset mouthStart = center.translate(-mouthWidth / 2, radius * 0.32);
    final Path mouth = Path()
      ..moveTo(mouthStart.dx, mouthStart.dy)
      ..quadraticBezierTo(
        center.dx,
        mouthStart.dy + curve,
        mouthStart.dx + mouthWidth,
        mouthStart.dy,
      );
    canvas.drawPath(mouth, line);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final Path path = Path();
    for (int i = 0; i < 10; i++) {
      final double r = i.isEven ? radius : radius * 0.45;
      final double a = -math.pi / 2 + i * math.pi / 5;
      final Offset point = center.translate(math.cos(a) * r, math.sin(a) * r);
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.progress != progress || old.mood != mood || old.color != color;
}

/// Nova accompagnée d'une bulle de dialogue.
class MascotMessage extends StatelessWidget {
  const MascotMessage({
    required this.message,
    this.mood = MascotMood.calme,
    this.size = 72,
    this.color,
    super.key,
  });

  final String message;
  final MascotMood mood;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Mascot(mood: mood, size: size, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: tokens.border, width: 1.2),
            ),
            child: Text(message, style: context.text.bodyMedium),
          ),
        ),
      ],
    );
  }
}

/// Couleur de repli de Nova quand aucune matière n'est en contexte.
const Color mascotDefaultColor = AppColors.brand;
