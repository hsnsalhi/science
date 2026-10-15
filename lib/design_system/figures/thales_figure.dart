/// Configuration de Thalès : deux parallèles, un sommet commun.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Triangle ABC dont la parallèle (MN) coulisse le long des côtés.
///
/// Le théorème de Thalès dit que trois rapports restent égaux ; ici ils
/// restent égaux sous le doigt de l'élève. Voir le petit triangle grandir
/// sans jamais changer de forme installe l'idée d'agrandissement, dont
/// l'égalité des quotients n'est que la traduction chiffrée.
class ThalesFigure extends StatefulWidget {
  const ThalesFigure({required this.accent, super.key});

  final Color accent;

  /// Bornes du rapport AM/AB.
  static const double minRatio = 0.2;
  static const double maxRatio = 0.85;

  @override
  State<ThalesFigure> createState() => _ThalesFigureState();
}

class _ThalesFigureState extends State<ThalesFigure> {
  double _ratio = 0.5;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final String k = NumericQuestion.formatNumber(
      (_ratio * 100).roundToDouble() / 100,
    );

    return Column(
      children: <Widget>[
        Semantics(
          label:
              'Triangle ABC. La droite MN, parallèle à BC, coupe les côtés '
              'de sorte que AM divisé par AB vaut $k.',
          child: AspectRatio(
            aspectRatio: 1.45,
            child: CustomPaint(
              painter: _ThalesPainter(
                ratio: _ratio,
                accent: widget.accent,
                ink: context.colors.onSurface,
                muted: tokens.inkMuted,
                surface: context.colors.surface,
              ),
            ),
          ),
        ),
        Slider(
          value: _ratio,
          min: ThalesFigure.minRatio,
          max: ThalesFigure.maxRatio,
          divisions: 13,
          label: k,
          onChanged: (double next) => setState(() => _ratio = next),
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
                'AM/AB = AN/AC = MN/BC = $k',
                style: AppTypography.formula(size: 16, color: widget.accent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Fais coulisser la droite (MN) : les trois rapports gardent '
                'toujours la même valeur. Le petit triangle change de taille, '
                'jamais de forme.',
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

class _ThalesPainter extends CustomPainter {
  _ThalesPainter({
    required this.ratio,
    required this.accent,
    required this.ink,
    required this.muted,
    required this.surface,
  });

  /// Rapport AM/AB, entre 0 et 1.
  final double ratio;

  final Color accent;
  final Color ink;
  final Color muted;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    const double pad = 30;
    final double width = size.width - pad * 2;
    final double height = size.height - pad * 2;

    // Un triangle quelconque : un sommet décentré évite de laisser croire
    // que la configuration exige un triangle isocèle.
    final Offset a = Offset(pad + width * 0.38, pad);
    final Offset b = Offset(pad, pad + height);
    final Offset c = Offset(pad + width, pad + height);

    // M et N sont les images de B et C par la réduction de centre A et de
    // rapport [ratio] : les trois quotients sont donc exacts par
    // construction, et non approchés par le dessin.
    final Offset m = Offset.lerp(a, b, ratio)!;
    final Offset n = Offset.lerp(a, c, ratio)!;

    final Path big = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..close();
    final Path small = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(m.dx, m.dy)
      ..lineTo(n.dx, n.dy)
      ..close();

    canvas
      ..drawPath(big, Paint()..color = muted.withValues(alpha: 0.1))
      ..drawPath(small, Paint()..color = accent.withValues(alpha: 0.22))
      ..drawPath(
        big,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..color = muted,
      )
      ..drawLine(
        m,
        n,
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = accent,
      );

    // Les chevrons marquent le parallélisme, comme sur une figure tracée
    // à la main : c'est la convention que l'élève retrouvera partout.
    _chevron(canvas, Offset.lerp(m, n, 0.5)!, n - m, accent);
    _chevron(canvas, Offset.lerp(b, c, 0.5)!, c - b, muted);

    for (final (Offset at, String label, Offset shift)
        in <(Offset, String, Offset)>[
          (a, 'A', const Offset(0, -16)),
          (b, 'B', const Offset(-14, 12)),
          (c, 'C', const Offset(14, 12)),
          (m, 'M', const Offset(-16, 0)),
          (n, 'N', const Offset(16, 0)),
        ]) {
      canvas.drawCircle(at, 4, Paint()..color = ink);
      _label(canvas, at + shift, label);
    }
  }

  void _chevron(Canvas canvas, Offset at, Offset direction, Color color) {
    final double angle = math.atan2(direction.dy, direction.dx);
    const double arm = 6;
    Offset arrow(double offset) => Offset(
      at.dx + arm * math.cos(angle + offset),
      at.dy + arm * math.sin(angle + offset),
    );
    canvas.drawPath(
      Path()
        ..moveTo(arrow(math.pi * 0.75).dx, arrow(math.pi * 0.75).dy)
        ..lineTo(at.dx, at.dy)
        ..lineTo(arrow(-math.pi * 0.75).dx, arrow(-math.pi * 0.75).dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  void _label(Canvas canvas, Offset at, String text) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontVariations: const <FontVariation>[FontVariation('wght', 700)],
          color: ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final Rect box = Rect.fromCenter(
      center: at,
      width: painter.width + 8,
      height: painter.height + 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(5)),
      Paint()..color = surface.withValues(alpha: 0.9),
    );
    painter.paint(
      canvas,
      box.center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ThalesPainter old) =>
      old.ratio != ratio || old.accent != accent || old.ink != ink;
}
