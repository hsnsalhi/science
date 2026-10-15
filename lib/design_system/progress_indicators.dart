/// Indicateurs de progression.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_tokens.dart';

/// Anneau de progression, avec un contenu libre au centre.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.value,
    this.size = 56,
    this.thickness = 6,
    this.color,
    this.trackColor,
    this.child,
    super.key,
  });

  /// Avancement, de 0 à 1.
  final double value;

  final double size;
  final double thickness;
  final Color? color;
  final Color? trackColor;

  /// Contenu centré (pourcentage, icône…).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final Color active = color ?? context.colors.primary;
    final Color track = trackColor ?? context.tokens.surfaceAlt;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: context.motionDuration(AppDurations.slow),
        curve: AppCurves.move,
        builder: (BuildContext context, double t, Widget? inner) => CustomPaint(
          painter: _RingPainter(
            value: t,
            color: active,
            trackColor: track,
            thickness: thickness,
          ),
          child: Center(child: inner),
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.thickness,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - thickness) / 2;
    final Paint track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (value <= 0) return;
    final Paint arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      // Départ en haut, sens horaire.
      -math.pi / 2,
      2 * math.pi * value,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.thickness != thickness;
}

/// Barre de progression arrondie et animée.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    this.height = 12,
    this.color,
    this.trackColor,
    this.semanticLabel,
    super.key,
  });

  /// Avancement, de 0 à 1.
  final double value;

  final double height;
  final Color? color;
  final Color? trackColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Color active = color ?? context.colors.primary;
    return Semantics(
      label: semanticLabel,
      value: '${(value.clamp(0.0, 1.0) * 100).round()} %',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Container(
          height: height,
          color: trackColor ?? context.tokens.surfaceAlt,
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: context.motionDuration(AppDurations.slow),
              curve: AppCurves.move,
              builder: (BuildContext context, double t, _) =>
                  FractionallySizedBox(
                    widthFactor: t == 0 ? 0 : t,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: active,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progression par segments : une case par question d'un quiz.
///
/// Préférée à une barre continue pendant un quiz : l'élève voit d'un coup
/// d'œil combien de questions restent, et non un pourcentage abstrait.
class StepProgress extends StatelessWidget {
  const StepProgress({
    required this.total,
    required this.currentIndex,
    required this.results,
    super.key,
  });

  final int total;

  /// Index de la question en cours.
  final int currentIndex;

  /// `true` (réussi), `false` (raté) ou `null` (pas encore traité), par étape.
  final List<bool?> results;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Semantics(
      label: 'Question ${math.min(currentIndex + 1, total)} sur $total',
      child: Row(
        children: <Widget>[
          for (int i = 0; i < total; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
                child: AnimatedContainer(
                  duration: context.motionDuration(AppDurations.fast),
                  height: 8,
                  decoration: BoxDecoration(
                    color: switch (results.elementAtOrNull(i)) {
                      true => tokens.success,
                      false => tokens.error,
                      null =>
                        i == currentIndex
                            ? context.colors.primary.withValues(alpha: 0.45)
                            : tokens.surfaceAlt,
                    },
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rangée d'étoiles de maîtrise.
class StarRow extends StatelessWidget {
  const StarRow({
    required this.filled,
    this.total = 3,
    this.size = 20,
    this.animate = true,
    super.key,
  });

  /// Nombre d'étoiles obtenues.
  final int filled;

  final int total;
  final double size;

  /// Animer l'apparition des étoiles obtenues.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool still = !animate || context.reduceMotion;
    return Semantics(
      label: '$filled étoile${filled > 1 ? 's' : ''} sur $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < total; i++)
            Padding(
              padding: EdgeInsets.only(right: i == total - 1 ? 0 : 2),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: still ? 1 : 0, end: 1),
                duration: still
                    ? Duration.zero
                    : AppDurations.base + Duration(milliseconds: 120 * i),
                curve: AppCurves.pop,
                builder: (BuildContext context, double t, Widget? child) =>
                    Transform.scale(scale: i < filled ? t : 1, child: child),
                child: Icon(
                  i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size,
                  color: i < filled ? tokens.gold : tokens.inkSubtle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
