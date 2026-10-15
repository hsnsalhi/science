/// Parcours de leçons en serpentin.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_tokens.dart';
import '../domain/models/lesson.dart';
import 'animations.dart';
import 'visuals.dart';

/// État d'une leçon dans le parcours.
enum LessonNodeState {
  /// Déjà terminée.
  termine,

  /// Prochaine leçon conseillée.
  enCours,

  /// Pas encore abordée.
  aVenir,
}

/// Données d'affichage d'une étape du parcours.
class LessonNodeData {
  const LessonNodeData({
    required this.id,
    required this.title,
    required this.kind,
    required this.state,
    this.perfect = false,
  });

  final String id;
  final String title;
  final LessonKind kind;
  final LessonNodeState state;

  /// Leçon réussie sans aucune faute.
  final bool perfect;
}

/// Parcours vertical en serpentin, façon carte d'aventure.
///
/// Le serpentin n'est pas qu'une décoration : il transforme une liste en
/// chemin, ce qui rend la progression lisible d'un coup d'œil et donne envie
/// d'aller à l'étape suivante. L'amplitude s'adapte à la largeur, si bien que
/// le même parcours reste harmonieux sur un téléphone comme sur une tablette.
///
/// Aucune étape n'est verrouillée : [LessonNodeState.aVenir] signale un
/// conseil d'ordre, pas une interdiction. Un élève peut sauter directement au
/// défi final s'il le souhaite.
class LessonPath extends StatelessWidget {
  const LessonPath({
    required this.nodes,
    required this.color,
    required this.onTap,
    super.key,
  });

  /// Diamètre d'une pastille.
  static const double nodeSize = 64;

  /// Distance verticale entre deux pastilles.
  static const double step = 122;

  static const double _labelWidth = 150;
  static const double _labelHeight = 42;

  final List<LessonNodeData> nodes;

  /// Couleur de la matière.
  final Color color;

  final void Function(String lessonId) onTap;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        // L'amplitude reste modérée pour que les libellés ne sortent jamais.
        final double amplitude = math.min(width * 0.2, 86);
        final double height =
            nodeSize / 2 +
            (nodes.length - 1) * step +
            nodeSize / 2 +
            _labelHeight +
            AppSpacing.lg;

        final List<Offset> centers = <Offset>[
          for (int i = 0; i < nodes.length; i++)
            Offset(
              width / 2 + amplitude * math.sin(i * math.pi / 2),
              nodeSize / 2 + i * step,
            ),
        ];

        return SizedBox(
          height: height,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _PathPainter(
                    centers: centers,
                    color: color,
                    trackColor: context.tokens.surfaceAlt,
                    doneUpTo: nodes
                        .lastIndexWhere(
                          (LessonNodeData n) =>
                              n.state == LessonNodeState.termine,
                        )
                        .clamp(-1, nodes.length - 1),
                  ),
                ),
              ),
              for (int i = 0; i < nodes.length; i++) ...<Widget>[
                Positioned(
                  left: centers[i].dx - nodeSize / 2,
                  top: centers[i].dy - nodeSize / 2,
                  width: nodeSize,
                  height: nodeSize,
                  child: SlideFadeIn(
                    delay: Duration(milliseconds: 60 * i),
                    child: _Node(
                      data: nodes[i],
                      color: color,
                      index: i,
                      onTap: () => onTap(nodes[i].id),
                    ),
                  ),
                ),
                Positioned(
                  left: centers[i].dx - _labelWidth / 2,
                  top: centers[i].dy + nodeSize / 2 + AppSpacing.sm,
                  width: _labelWidth,
                  height: _labelHeight,
                  child: IgnorePointer(
                    child: Text(
                      nodes[i].title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelMedium?.copyWith(
                        color: nodes[i].state == LessonNodeState.aVenir
                            ? context.tokens.inkSubtle
                            : context.colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.data,
    required this.color,
    required this.index,
    required this.onTap,
  });

  final LessonNodeData data;
  final Color color;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool done = data.state == LessonNodeState.termine;
    final bool current = data.state == LessonNodeState.enCours;

    final Color fill = done || current ? color : tokens.surfaceAlt;
    final Color foreground = done || current ? Colors.white : tokens.inkSubtle;

    Widget circle = Container(
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(
          color: current ? color : (done ? color : tokens.border),
          width: current ? 3 : 1.5,
        ),
        boxShadow: done || current ? tokens.cardShadow : null,
      ),
      child: Center(
        child: Icon(
          done ? Icons.check_rounded : LessonVisuals.icon(data.kind),
          color: foreground,
          size: 28,
        ),
      ),
    );

    if (data.perfect) {
      circle = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(child: circle),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: context.colors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.star_rounded, size: 15, color: tokens.gold),
            ),
          ),
        ],
      );
    }

    // Seule l'étape conseillée pulse : si tout bougeait, plus rien ne
    // ressortirait.
    final Widget node = GentlePulse(enabled: current, child: circle);

    return Semantics(
      button: true,
      label:
          '${data.kind.label} ${index + 1} : ${data.title}'
          '${done ? ', terminée' : ''}',
      child: GestureDetector(
        onTap: () {
          context.tapFeedback();
          onTap();
        },
        child: node,
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.centers,
    required this.color,
    required this.trackColor,
    required this.doneUpTo,
  });

  final List<Offset> centers;
  final Color color;
  final Color trackColor;

  /// Index de la dernière étape terminée ; -1 si aucune.
  final int doneUpTo;

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < centers.length - 1; i++) {
      final Offset a = centers[i];
      final Offset b = centers[i + 1];
      // Courbe douce : le point de contrôle reprend l'abscisse de départ,
      // ce qui donne au trait l'allure d'un ruban.
      final Path path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(a.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
      paint.color = i < doneUpTo ? color.withValues(alpha: 0.55) : trackColor;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.doneUpTo != doneUpTo ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.centers != centers;
}
