/// Figures interactives autour du triangle rectangle.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Côté mis en évidence dans la figure.
enum TriangleSide { horizontal, vertical, hypotenuse }

/// Triangle rectangle manipulable.
///
/// L'élève fait glisser le doigt pour changer la longueur des deux côtés de
/// l'angle droit ; l'hypoténuse suit. Toucher un côté affiche son nom.
///
/// Manipuler soi-même la figure fait bien plus que la regarder : c'est en
/// voyant l'hypoténuse rester le côté le plus long, quelles que soient les
/// valeurs, qu'on retient le vocabulaire.
class RightTriangleFigure extends StatefulWidget {
  const RightTriangleFigure({
    required this.accent,
    this.showSquares = false,
    this.initialA = 4,
    this.initialB = 3,
    super.key,
  });

  /// Couleur d'accent de la matière.
  final Color accent;

  /// Dessiner les carrés construits sur chaque côté (preuve visuelle).
  final bool showSquares;

  final double initialA;
  final double initialB;

  /// Bornes des côtés, en unités.
  static const double minSide = 2;
  static const double maxSide = 9;

  @override
  State<RightTriangleFigure> createState() => _RightTriangleFigureState();
}

class _RightTriangleFigureState extends State<RightTriangleFigure> {
  late double _a = widget.initialA;
  late double _b = widget.initialB;
  TriangleSide? _highlighted;

  double get _c => math.sqrt(_a * _a + _b * _b);

  /// Sensibilité du glissement : combien de pixels pour une unité.
  static const double _pixelsPerUnit = 26;

  void _onPan(DragUpdateDetails details) {
    setState(() {
      _a = (_a + details.delta.dx / _pixelsPerUnit).clamp(
        RightTriangleFigure.minSide,
        RightTriangleFigure.maxSide,
      );
      // L'axe vertical de l'écran est inversé par rapport à la figure.
      _b = (_b - details.delta.dy / _pixelsPerUnit).clamp(
        RightTriangleFigure.minSide,
        RightTriangleFigure.maxSide,
      );
    });
  }

  void _cycleHighlight() {
    const List<TriangleSide?> cycle = <TriangleSide?>[
      TriangleSide.horizontal,
      TriangleSide.vertical,
      TriangleSide.hypotenuse,
      null,
    ];
    setState(() {
      final int i = cycle.indexOf(_highlighted);
      _highlighted = cycle[(i + 1) % cycle.length];
    });
    context.tapFeedback();
  }

  String get _highlightLabel => switch (_highlighted) {
    TriangleSide.horizontal =>
      'Côté de l\'angle droit — longueur ${_format(_a)}',
    TriangleSide.vertical => 'Côté de l\'angle droit — longueur ${_format(_b)}',
    TriangleSide.hypotenuse =>
      'Hypoténuse — le côté opposé à l\'angle droit, toujours le plus long',
    null => 'Touche la figure pour nommer les côtés',
  };

  static String _format(double value) =>
      NumericQuestion.formatNumber((value * 100).roundToDouble() / 100);

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // La figure épouse son contenu : dans une carte de leçon, la
    // hauteur offerte dépasse ce que le tracé peut occuper, et une
    // colonne qui la prend toute pousse ses légendes loin sous le
    // dessin.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          label:
              'Triangle rectangle de côtés ${_format(_a)} et ${_format(_b)}, '
              'hypoténuse ${_format(_c)}. Glisse pour modifier les côtés.',
          child: GestureDetector(
            onPanUpdate: _onPan,
            onTap: _cycleHighlight,
            child: AspectRatio(
              aspectRatio: widget.showSquares ? 1.1 : 1.35,
              child: CustomPaint(
                painter: _TrianglePainter(
                  a: _a,
                  b: _b,
                  accent: widget.accent,
                  showSquares: widget.showSquares,
                  highlighted: _highlighted,
                  surface: context.colors.surface,
                  ink: context.colors.onSurface,
                  muted: tokens.inkMuted,
                  grid: tokens.border,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.showSquares)
          _ProofLine(a: _a, b: _b, accent: widget.accent)
        else
          Text(
            _highlightLabel,
            textAlign: TextAlign.center,
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
                'Glisse sur la figure pour changer les côtés',
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
}

/// Égalité numérique affichée sous la preuve visuelle.
class _ProofLine extends StatelessWidget {
  const _ProofLine({required this.a, required this.b, required this.accent});

  final double a;
  final double b;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double c2 = a * a + b * b;
    String n(double v) =>
        NumericQuestion.formatNumber((v * 100).roundToDouble() / 100);
    return Column(
      children: <Widget>[
        Text(
          '${n(a * a)}  +  ${n(b * b)}  =  ${n(c2)}',
          style: AppTypography.formula(size: 19, color: accent),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'aire bleue + aire verte = aire orange',
          style: context.text.labelSmall?.copyWith(
            color: context.tokens.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter({
    required this.a,
    required this.b,
    required this.accent,
    required this.showSquares,
    required this.highlighted,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.grid,
  });

  final double a;
  final double b;
  final Color accent;
  final bool showSquares;
  final TriangleSide? highlighted;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color grid;

  /// Couleurs des trois carrés de la preuve.
  static const Color _squareA = Color(0xFF3B82F6);
  static const Color _squareB = Color(0xFF22C55E);
  static const Color _squareC = Color(0xFFF59E0B);

  @override
  void paint(Canvas canvas, Size size) {
    // Repère mathématique : origine à l'angle droit, y vers le haut.
    const Offset c = Offset.zero;
    final Offset bPoint = Offset(a, 0);
    final Offset aPoint = Offset(0, b);
    final double hyp = math.sqrt(a * a + b * b);
    // Normale extérieure de l'hypoténuse, de longueur égale à l'hypoténuse.
    final Offset normal = Offset(b, a);

    final List<Offset> squareOnA = <Offset>[
      c,
      bPoint,
      Offset(a, -a),
      Offset(0, -a),
    ];
    final List<Offset> squareOnB = <Offset>[
      c,
      aPoint,
      Offset(-b, b),
      Offset(-b, 0),
    ];
    final List<Offset> squareOnC = <Offset>[
      aPoint,
      bPoint,
      bPoint + normal,
      aPoint + normal,
    ];

    final List<Offset> all = <Offset>[
      c,
      bPoint,
      aPoint,
      if (showSquares) ...squareOnA,
      if (showSquares) ...squareOnB,
      if (showSquares) ...squareOnC,
    ];

    // Ajustement à la zone de dessin, marges comprises.
    const double pad = 34;
    double minX = all.first.dx, maxX = all.first.dx;
    double minY = all.first.dy, maxY = all.first.dy;
    for (final Offset p in all) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    final double scale = math.min(
      (size.width - pad * 2) / math.max(maxX - minX, 0.001),
      (size.height - pad * 2) / math.max(maxY - minY, 0.001),
    );
    final double offsetX =
        (size.width - (maxX - minX) * scale) / 2 - minX * scale;
    final double offsetY =
        (size.height + (maxY - minY) * scale) / 2 + minY * scale;

    Offset project(Offset p) =>
        Offset(offsetX + p.dx * scale, offsetY - p.dy * scale);

    if (showSquares) {
      _fillPolygon(canvas, squareOnA.map(project).toList(), _squareA);
      _fillPolygon(canvas, squareOnB.map(project).toList(), _squareB);
      _fillPolygon(canvas, squareOnC.map(project).toList(), _squareC);
    }

    // Triangle.
    final Path triangle = Path()
      ..moveTo(project(c).dx, project(c).dy)
      ..lineTo(project(bPoint).dx, project(bPoint).dy)
      ..lineTo(project(aPoint).dx, project(aPoint).dy)
      ..close();
    canvas
      ..drawPath(triangle, Paint()..color = accent.withValues(alpha: 0.18))
      ..drawPath(
        triangle,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..color = accent,
      );

    _drawSide(canvas, project(c), project(bPoint), TriangleSide.horizontal);
    _drawSide(canvas, project(c), project(aPoint), TriangleSide.vertical);
    _drawSide(
      canvas,
      project(aPoint),
      project(bPoint),
      TriangleSide.hypotenuse,
    );
    _drawRightAngle(canvas, project(c), project(bPoint), project(aPoint));

    _label(canvas, project(Offset(a / 2, 0)) + const Offset(0, 18), _n(a));
    _label(canvas, project(Offset(0, b / 2)) - const Offset(18, 0), _n(b));
    _label(
      canvas,
      project(Offset(a / 2, b / 2)) + Offset(14 * (a / hyp), -14 * (b / hyp)),
      _n(hyp),
      bold: true,
    );
  }

  String _n(double v) =>
      NumericQuestion.formatNumber((v * 100).roundToDouble() / 100);

  void _fillPolygon(Canvas canvas, List<Offset> points, Color color) {
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final Offset p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas
      ..drawPath(path, Paint()..color = color.withValues(alpha: 0.28))
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: 0.9),
      );
  }

  void _drawSide(Canvas canvas, Offset from, Offset to, TriangleSide side) {
    if (highlighted != side) return;
    canvas.drawLine(
      from,
      to,
      Paint()
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = accent,
    );
  }

  /// Petit carré marquant l'angle droit.
  void _drawRightAngle(Canvas canvas, Offset corner, Offset along, Offset up) {
    const double len = 14;
    final Offset u = (along - corner) / (along - corner).distance * len;
    final Offset v = (up - corner) / (up - corner).distance * len;
    final Path path = Path()
      ..moveTo(corner.dx + u.dx, corner.dy + u.dy)
      ..lineTo(corner.dx + u.dx + v.dx, corner.dy + u.dy + v.dy)
      ..lineTo(corner.dx + v.dx, corner.dy + v.dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = muted,
    );
  }

  void _label(Canvas canvas, Offset at, String text, {bool bold = false}) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontFamilyFallback: AppTypography.replis,
          fontSize: 13,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
          fontVariations: <FontVariation>[
            FontVariation('wght', bold ? 800 : 700),
          ],
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
      Paint()..color = surface.withValues(alpha: 0.9),
    );
    painter.paint(
      canvas,
      box.center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) =>
      old.a != a ||
      old.b != b ||
      old.highlighted != highlighted ||
      old.showSquares != showSquares ||
      old.accent != accent ||
      old.surface != surface;
}
