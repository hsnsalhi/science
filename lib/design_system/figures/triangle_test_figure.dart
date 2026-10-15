/// Figure de la réciproque : ce triangle est-il rectangle ?
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Triangle de côtés 6 et 8, dont le troisième côté est réglable.
///
/// L'élève fait varier le grand côté et voit la forme changer en direct :
/// l'angle n'est droit qu'à l'instant précis où `6² + 8² = c²`, c'est-à-dire
/// `c = 10`. Faire « passer » le triangle par cet instant ancre la réciproque
/// bien mieux qu'un énoncé.
class TriangleTestFigure extends StatefulWidget {
  const TriangleTestFigure({required this.accent, super.key});

  final Color accent;

  /// Côtés fixes.
  static const double sideB = 6;
  static const double sideA = 8;

  /// Bornes du côté réglable (inégalité triangulaire oblige).
  static const double minC = 3.5;
  static const double maxC = 13;

  @override
  State<TriangleTestFigure> createState() => _TriangleTestFigureState();
}

class _TriangleTestFigureState extends State<TriangleTestFigure> {
  double _c = 7;

  static const double _tolerance = 0.05;

  bool get _isRight =>
      (TriangleTestFigure.sideA * TriangleTestFigure.sideA +
              TriangleTestFigure.sideB * TriangleTestFigure.sideB -
              _c * _c)
          .abs() <
      _tolerance;

  static String _n(double v) =>
      NumericQuestion.formatNumber((v * 100).roundToDouble() / 100);

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    const double sum =
        TriangleTestFigure.sideA * TriangleTestFigure.sideA +
        TriangleTestFigure.sideB * TriangleTestFigure.sideB;
    final double square = _c * _c;
    final Color verdictColor = _isRight ? tokens.success : tokens.inkMuted;

    return Column(
      children: <Widget>[
        Semantics(
          label:
              'Triangle de côtés 6, 8 et ${_n(_c)}. '
              '${_isRight ? 'Il est rectangle.' : 'Il n\'est pas rectangle.'}',
          child: AspectRatio(
            aspectRatio: 1.5,
            child: CustomPaint(
              painter: _TestPainter(
                a: TriangleTestFigure.sideA,
                b: TriangleTestFigure.sideB,
                c: _c,
                accent: widget.accent,
                isRight: _isRight,
                success: tokens.success,
                ink: context.colors.onSurface,
                surface: context.colors.surface,
              ),
            ),
          ),
        ),
        Slider(
          value: _c,
          min: TriangleTestFigure.minC,
          max: TriangleTestFigure.maxC,
          label: _n(_c),
          onChanged: (double value) => setState(() => _c = value),
        ),
        Text(
          'Troisième côté : ${_n(_c)}',
          style: context.text.labelMedium?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: verdictColor.withValues(alpha: context.isDark ? 0.16 : 0.1),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            children: <Widget>[
              Text(
                '6² + 8² = ${_n(sum)}   ·   c² = ${_n(square)}',
                style: AppTypography.formula(size: 16, color: verdictColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _isRight
                    ? 'Les deux sont égaux : le triangle est rectangle.'
                    : 'Les deux diffèrent : le triangle n\'est pas rectangle.',
                style: context.text.bodySmall?.copyWith(color: verdictColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TestPainter extends CustomPainter {
  _TestPainter({
    required this.a,
    required this.b,
    required this.c,
    required this.accent,
    required this.isRight,
    required this.success,
    required this.ink,
    required this.surface,
  });

  /// Longueurs des côtés : [c] est la base, [b] part de A, [a] arrive en B.
  final double a;
  final double b;
  final double c;

  final Color accent;
  final bool isRight;
  final Color success;
  final Color ink;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    // Troisième sommet obtenu par la loi des cosinus, dans le repère où
    // A = (0, 0) et B = (c, 0).
    final double x = (c * c + b * b - a * a) / (2 * c);
    final double ySquared = b * b - x * x;
    if (ySquared <= 0) return;
    final double y = math.sqrt(ySquared);

    const double pad = 28;
    final double scale = math.min(
      (size.width - pad * 2) / math.max(c, x.abs()),
      (size.height - pad * 2) / y,
    );
    final double originX = (size.width - c * scale) / 2;
    final double originY = size.height - pad;

    Offset project(double px, double py) =>
        Offset(originX + px * scale, originY - py * scale);

    final Offset pointA = project(0, 0);
    final Offset pointB = project(c, 0);
    final Offset pointC = project(x, y);

    final Color stroke = isRight ? success : accent;
    final Path path = Path()
      ..moveTo(pointA.dx, pointA.dy)
      ..lineTo(pointB.dx, pointB.dy)
      ..lineTo(pointC.dx, pointC.dy)
      ..close();

    canvas
      ..drawPath(path, Paint()..color = stroke.withValues(alpha: 0.18))
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..color = stroke,
      );

    if (isRight) _drawRightAngle(canvas, pointC, pointA, pointB, success);

    _label(
      canvas,
      Offset.lerp(pointA, pointB, 0.5)! + const Offset(0, 16),
      'c = ${_n(c)}',
    );
    _label(
      canvas,
      Offset.lerp(pointA, pointC, 0.5)! + const Offset(-20, 0),
      '6',
    );
    _label(
      canvas,
      Offset.lerp(pointB, pointC, 0.5)! + const Offset(20, 0),
      '8',
    );
  }

  String _n(double v) =>
      NumericQuestion.formatNumber((v * 100).roundToDouble() / 100);

  void _drawRightAngle(
    Canvas canvas,
    Offset corner,
    Offset p1,
    Offset p2,
    Color color,
  ) {
    const double len = 13;
    final Offset u = (p1 - corner) / (p1 - corner).distance * len;
    final Offset v = (p2 - corner) / (p2 - corner).distance * len;
    canvas.drawPath(
      Path()
        ..moveTo(corner.dx + u.dx, corner.dy + u.dy)
        ..lineTo(corner.dx + u.dx + v.dx, corner.dy + u.dy + v.dy)
        ..lineTo(corner.dx + v.dx, corner.dy + v.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  void _label(Canvas canvas, Offset at, String text) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          fontVariations: const <FontVariation>[FontVariation('wght', 700)],
          color: ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final Rect box = Rect.fromCenter(
      center: at,
      width: painter.width + 10,
      height: painter.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(6)),
      Paint()..color = surface.withValues(alpha: 0.92),
    );
    painter.paint(
      canvas,
      box.center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_TestPainter old) =>
      old.c != c || old.accent != accent || old.isRight != isRight;
}
