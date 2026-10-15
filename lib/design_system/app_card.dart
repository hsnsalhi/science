/// Cartes et surfaces.
library;

import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_tokens.dart';

/// Surface posée, cliquable ou non.
///
/// Toutes les cartes de l'application passent par ici : c'est ce qui garantit
/// un même rayon, une même ombre et un même retour au toucher partout.
class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.background,
    this.borderColor,
    this.radius = AppRadii.lg,
    this.elevated = true,
    this.semanticLabel,
    super.key,
  });

  final Widget child;

  /// Rend la carte cliquable et active l'effet d'enfoncement.
  final VoidCallback? onTap;

  final EdgeInsets padding;

  /// Fond ; par défaut la surface du thème.
  final Color? background;

  /// Contour ; par défaut la bordure du thème.
  final Color? borderColor;

  final double radius;

  /// Portée d'une ombre douce.
  final bool elevated;

  final String? semanticLabel;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Widget surface = AnimatedScale(
      // Un enfoncement de 2 % suffit : au-delà, une grande carte donne
      // l'impression de « sauter ».
      scale: _pressed ? 0.98 : 1,
      duration: context.motionDuration(AppDurations.instant),
      curve: Curves.easeOut,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.background ?? context.colors.surface,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: widget.borderColor ?? tokens.border,
            width: 1.2,
          ),
          boxShadow: widget.elevated ? tokens.cardShadow : null,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) {
      return widget.semanticLabel == null
          ? surface
          : Semantics(label: widget.semanticLabel, child: surface);
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          context.tapFeedback();
          widget.onTap!.call();
        },
        child: surface,
      ),
    );
  }
}

/// Encadré teinté, pour une astuce, un rappel ou une mise en garde.
class AppNotice extends StatelessWidget {
  const AppNotice({
    required this.child,
    required this.color,
    this.icon,
    this.title,
    super.key,
  });

  final Widget child;

  /// Couleur d'accent ; le fond en est une version très atténuée.
  final Color color;

  final IconData? icon;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: context.text.labelMedium?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          child,
        ],
      ),
    );
  }
}
