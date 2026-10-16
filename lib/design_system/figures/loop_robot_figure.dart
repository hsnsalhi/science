/// Un robot qui exécute une boucle, sur une grille.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Un robot qui répète « avancer de 2, tourner à droite ».
///
/// Une boucle se définit en une phrase et ne se comprend qu'en la voyant
/// tourner. Ici on règle le nombre de répétitions et on regarde le tracé :
/// à trois, le chemin reste ouvert ; à quatre, il se referme en carré ; à
/// cinq, le robot repasse sur ses pas. Le bon nombre de tours n'est pas
/// une consigne à retenir, c'est une conséquence qu'on observe.
class LoopRobotFigure extends StatefulWidget {
  const LoopRobotFigure({required this.accent, super.key});

  final Color accent;

  /// Côté de la grille, en cases.
  static const int cotes = 7;

  /// Nombre de cases parcourues à chaque « avancer ».
  static const int pas = 2;

  /// Positions successives du robot pour [tours] répétitions.
  ///
  /// Le robot part du coin bas-gauche en regardant vers le haut, puis
  /// répète « avancer de [pas], tourner à droite ». Les positions sont
  /// bornées à la grille : un programme qui sortirait du plateau s'arrête
  /// au bord plutôt que de disparaître.
  static List<({int x, int y})> chemin(int tours) {
    int x = 1;
    int y = cotes - 2;
    // Direction initiale : vers le haut de l'écran.
    int dx = 0;
    int dy = -1;
    final List<({int x, int y})> points = <({int x, int y})>[(x: x, y: y)];
    for (int t = 0; t < tours; t++) {
      for (int p = 0; p < pas; p++) {
        x = (x + dx).clamp(0, cotes - 1);
        y = (y + dy).clamp(0, cotes - 1);
        points.add((x: x, y: y));
      }
      // Tourner à droite : (dx, dy) devient (-dy, dx).
      final int ancien = dx;
      dx = -dy;
      dy = ancien;
    }
    return points;
  }

  @override
  State<LoopRobotFigure> createState() => _LoopRobotFigureState();
}

class _LoopRobotFigureState extends State<LoopRobotFigure>
    with SingleTickerProviderStateMixin {
  int _tours = 4;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..addListener(() => setState(() {}));

  bool _demarrageFait = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _executer() {
    final List<({int x, int y})> points = LoopRobotFigure.chemin(_tours);
    _controller.duration = Duration(milliseconds: 260 * points.length);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final List<({int x, int y})> points = LoopRobotFigure.chemin(_tours);
    final int atteint = (points.length * _controller.value)
        .floor()
        .clamp(0, points.length - 1);
    final bool ferme =
        points.last.x == points.first.x && points.last.y == points.first.y;

    if (!_demarrageFait) {
      _demarrageFait = true;
      if (!context.reduceMotion) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _executer();
        });
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Le programme, écrit comme il se lirait dans un cahier.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: tokens.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'répéter $_tours fois',
                style: AppTypography.formula(size: 15, color: widget.accent),
              ),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: Text(
                  'avancer de ${LoopRobotFigure.pas}\ntourner à droite',
                  style: AppTypography.formula(
                    size: 15,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _GrillePainter(
              points: points,
              atteint: atteint,
              accent: widget.accent,
              trait: tokens.border,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          ferme
              ? 'Le chemin se referme : le robot est revenu au départ.'
              : 'Le chemin ne se referme pas.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(
            color: ferme ? tokens.success : tokens.inkMuted,
          ),
        ),
        Row(
          children: <Widget>[
            IconButton(
              tooltip: 'Exécuter',
              onPressed: () {
                context.tapFeedback();
                _executer();
              },
              icon: Icon(Icons.play_arrow_rounded, color: widget.accent),
            ),
            Expanded(
              child: Slider(
                value: _tours.toDouble(),
                min: 1,
                max: 6,
                divisions: 5,
                label: '$_tours tours',
                onChanged: (double v) {
                  setState(() => _tours = v.round());
                  _executer();
                },
              ),
            ),
          ],
        ),
        Text(
          'Change le nombre de tours, puis exécute',
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

class _GrillePainter extends CustomPainter {
  const _GrillePainter({
    required this.points,
    required this.atteint,
    required this.accent,
    required this.trait,
  });

  final List<({int x, int y})> points;
  final int atteint;
  final Color accent;
  final Color trait;

  @override
  void paint(Canvas canvas, Size size) {
    const int n = LoopRobotFigure.cotes;
    final double cote = math.min(size.width, size.height) / n;
    final double dx = (size.width - cote * n) / 2;
    final double dy = (size.height - cote * n) / 2;

    Offset centre(({int x, int y}) p) =>
        Offset(dx + (p.x + 0.5) * cote, dy + (p.y + 0.5) * cote);

    for (int i = 0; i <= n; i++) {
      final Paint p = Paint()
        ..color = trait
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(dx + i * cote, dy),
        Offset(dx + i * cote, dy + n * cote),
        p,
      );
      canvas.drawLine(
        Offset(dx, dy + i * cote),
        Offset(dx + n * cote, dy + i * cote),
        p,
      );
    }

    // Le chemin déjà parcouru.
    if (atteint > 0) {
      final Path chemin = Path()
        ..moveTo(centre(points.first).dx, centre(points.first).dy);
      for (int i = 1; i <= atteint; i++) {
        chemin.lineTo(centre(points[i]).dx, centre(points[i]).dy);
      }
      canvas.drawPath(
        chemin,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = accent.withValues(alpha: 0.55),
      );
    }

    // Départ, puis robot.
    canvas.drawCircle(
      centre(points.first),
      cote * 0.16,
      Paint()..color = accent.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      centre(points[atteint]),
      cote * 0.26,
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(_GrillePainter old) =>
      old.atteint != atteint ||
      old.points.length != points.length ||
      old.accent != accent;
}
