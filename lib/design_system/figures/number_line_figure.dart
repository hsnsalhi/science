/// Droite graduée des nombres relatifs.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Droite graduée de −10 à 10, avec un point que l'élève déplace.
///
/// Voir le point franchir le zéro, et son opposé venir à sa rencontre, dit
/// en une seconde ce qu'un paragraphe explique mal : un nombre relatif, c'est
/// une distance à zéro et un côté. « Le plus petit est le plus à gauche »
/// devient alors une observation plutôt qu'une règle à retenir — c'est tout
/// l'intérêt de manipuler avant d'énoncer.
class NumberLineFigure extends StatefulWidget {
  const NumberLineFigure({required this.accent, super.key});

  final Color accent;

  /// Bornes de la graduation.
  static const double min = -10;
  static const double max = 10;

  /// Écriture d'un relatif : signe explicite et vrai signe « moins ».
  static String signed(int value) {
    if (value == 0) return '0';
    return value > 0 ? '+$value' : '−${value.abs()}';
  }

  @override
  State<NumberLineFigure> createState() => _NumberLineFigureState();
}

class _NumberLineFigureState extends State<NumberLineFigure> {
  double _value = -4;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final int value = _value.round();
    final int distance = value.abs();

    return Column(
      children: <Widget>[
        Semantics(
          label:
              'Droite graduée de −10 à 10. Le point est sur '
              '${NumberLineFigure.signed(value)}, à $distance unités de zéro. '
              'Son opposé est ${NumberLineFigure.signed(-value)}.',
          child: AspectRatio(
            aspectRatio: 2.0,
            child: CustomPaint(
              painter: _NumberLinePainter(
                value: value,
                accent: widget.accent,
                ink: context.colors.onSurface,
                muted: tokens.inkMuted,
                border: tokens.border,
                surface: context.colors.surface,
              ),
            ),
          ),
        ),
        Slider(
          value: _value,
          min: NumberLineFigure.min,
          max: NumberLineFigure.max,
          divisions: (NumberLineFigure.max - NumberLineFigure.min).round(),
          label: NumberLineFigure.signed(value),
          onChanged: (double next) => setState(() => _value = next),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: widget.accent.withValues(alpha: context.isDark ? 0.16 : 0.1),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            children: <Widget>[
              Text(
                '${NumberLineFigure.signed(value)}   ·   opposé : '
                '${NumberLineFigure.signed(-value)}',
                style: AppTypography.formula(size: 16, color: widget.accent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value == 0
                    ? 'Zéro n\'est ni positif ni négatif, et il est son '
                          'propre opposé.'
                    : 'Ce nombre est ${value > 0 ? 'positif' : 'négatif'} et '
                          'se trouve à $distance '
                          'unité${distance > 1 ? 's' : ''} de zéro. Son '
                          'opposé est à la même distance, de l\'autre côté.',
                style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NumberLinePainter extends CustomPainter {
  _NumberLinePainter({
    required this.value,
    required this.accent,
    required this.ink,
    required this.muted,
    required this.border,
    required this.surface,
  });

  /// Position du point, en unités de la graduation.
  final int value;

  final Color accent;
  final Color ink;
  final Color muted;
  final Color border;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    const double pad = 22;
    final double axisY = size.height * 0.62;
    final double unit =
        (size.width - pad * 2) / (NumberLineFigure.max - NumberLineFigure.min);
    double x(num at) => pad + (at - NumberLineFigure.min) * unit;

    // Les négatifs reposent sur un fond légèrement teinté : le « côté » de
    // zéro se lit avant même les graduations.
    canvas.drawRect(
      Rect.fromLTRB(0, 0, x(0), size.height),
      Paint()..color = muted.withValues(alpha: 0.08),
    );

    final Paint axis = Paint()
      ..color = border
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(pad / 2, axisY),
      Offset(size.width - pad / 2, axisY),
      axis,
    );
    for (final double direction in <double>[-1, 1]) {
      final double tip = direction < 0 ? pad / 2 : size.width - pad / 2;
      canvas
        ..drawLine(
          Offset(tip, axisY),
          Offset(tip - direction * 7, axisY - 5),
          axis,
        )
        ..drawLine(
          Offset(tip, axisY),
          Offset(tip - direction * 7, axisY + 5),
          axis,
        );
    }

    for (
      int tick = NumberLineFigure.min.toInt();
      tick <= NumberLineFigure.max.toInt();
      tick++
    ) {
      final bool major = tick % 5 == 0;
      canvas.drawLine(
        Offset(x(tick), axisY - (major ? 9 : 5)),
        Offset(x(tick), axisY + (major ? 9 : 5)),
        Paint()
          ..color = tick == 0 ? ink : border
          ..strokeWidth = tick == 0 ? 2.5 : 1.5,
      );
      if (major) {
        _text(
          canvas,
          Offset(x(tick), axisY + 24),
          NumberLineFigure.signed(tick),
          color: tick == 0 ? ink : muted,
          bold: tick == 0,
        );
      }
    }

    // La distance à zéro, matérialisée par le segment parcouru.
    if (value != 0) {
      final double from = x(0);
      final double to = x(value);
      canvas.drawLine(
        Offset(from, axisY - 18),
        Offset(to, axisY - 18),
        Paint()
          ..color = accent.withValues(alpha: 0.55)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      _text(
        canvas,
        Offset((from + to) / 2, axisY - 34),
        '${value.abs()} unité${value.abs() > 1 ? 's' : ''}',
        color: accent,
        bold: true,
        background: true,
      );
    }

    // L'opposé, en creux : même distance, autre côté.
    canvas.drawCircle(
      Offset(x(-value), axisY),
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = muted,
    );

    canvas
      ..drawCircle(Offset(x(value), axisY), 10, Paint()..color = accent)
      ..drawCircle(
        Offset(x(value), axisY),
        10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = surface,
      );
    _text(
      canvas,
      Offset(x(value), axisY + 42),
      NumberLineFigure.signed(value),
      color: accent,
      bold: true,
      background: true,
    );
  }

  void _text(
    Canvas canvas,
    Offset at,
    String label, {
    required Color color,
    bool bold = false,
    bool background = false,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          fontVariations: <FontVariation>[
            FontVariation('wght', bold ? 700 : 600),
          ],
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final Rect box = Rect.fromCenter(
      center: at,
      width: painter.width + 8,
      height: painter.height + 2,
    );
    if (background) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(5)),
        Paint()..color = surface.withValues(alpha: 0.92),
      );
    }
    painter.paint(
      canvas,
      box.center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_NumberLinePainter old) =>
      old.value != value || old.accent != accent || old.ink != ink;
}
