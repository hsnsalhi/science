/// Bouton principal de l'application.
library;

import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_tokens.dart';

/// Rôle visuel d'un bouton.
enum AppButtonVariant {
  /// Action principale de l'écran.
  primary,

  /// Action secondaire, sur fond de surface.
  secondary,

  /// Action discrète, sans fond.
  ghost,

  /// Validation d'une bonne réponse.
  success,

  /// Action destructrice (réinitialiser la progression).
  danger,
}

/// Taille d'un bouton.
enum AppButtonSize {
  large(height: 56, fontSize: 17, padding: AppSpacing.xl),
  medium(height: 48, fontSize: 15, padding: AppSpacing.lg),
  small(height: 38, fontSize: 13, padding: AppSpacing.md);

  const AppButtonSize({
    required this.height,
    required this.fontSize,
    required this.padding,
  });

  final double height;
  final double fontSize;
  final double padding;
}

/// Bouton à relief, qui s'enfonce sous le doigt.
///
/// Le bord inférieur plus sombre et l'enfoncement de 4 px donnent une
/// sensation physique de pression. Ce détail compte plus qu'il n'y paraît pour
/// une application utilisée par des enfants : il rend l'appui évident et
/// gratifiant, là où un bouton plat ne confirme rien.
///
/// Un bouton désactivé reste visible et annonce son état par le contraste,
/// jamais par la disparition.
class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.color,
    super.key,
  });

  /// Raccourci pour une action secondaire.
  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.color,
    super.key,
  }) : variant = AppButtonVariant.secondary;

  /// Raccourci pour une action discrète.
  const AppButton.ghost({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.color,
    super.key,
  }) : variant = AppButtonVariant.ghost;

  final String label;

  /// `null` désactive le bouton.
  final VoidCallback? onPressed;

  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Icône avant le texte.
  final IconData? icon;

  /// Icône après le texte.
  final IconData? trailingIcon;

  /// Occuper toute la largeur disponible.
  final bool expand;

  /// Teinte imposée (couleur de la matière, par exemple).
  final Color? color;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  /// Hauteur du relief sous le bouton.
  static const double _edge = 4;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final ColorScheme colors = context.colors;
    final bool ghost = widget.variant == AppButtonVariant.ghost;

    final Color base = switch (widget.variant) {
      AppButtonVariant.primary => widget.color ?? colors.primary,
      AppButtonVariant.success => tokens.success,
      AppButtonVariant.danger => tokens.error,
      AppButtonVariant.secondary => colors.surface,
      AppButtonVariant.ghost => Colors.transparent,
    };
    final Color foreground = switch (widget.variant) {
      AppButtonVariant.primary => colors.onPrimary,
      AppButtonVariant.success => Colors.white,
      AppButtonVariant.danger => Colors.white,
      AppButtonVariant.secondary => widget.color ?? colors.onSurface,
      AppButtonVariant.ghost => widget.color ?? tokens.inkMuted,
    };

    // Le relief est une version assombrie de la couleur de fond ; pour un
    // bouton secondaire, c'est le trait de contour qui joue ce rôle.
    final Color edgeColor = switch (widget.variant) {
      AppButtonVariant.secondary => tokens.border,
      AppButtonVariant.ghost => Colors.transparent,
      _ => Color.lerp(base, Colors.black, 0.22)!,
    };

    final double radius = widget.size == AppButtonSize.small
        ? AppRadii.sm
        : AppRadii.md;
    final double drop = ghost ? 0 : _edge;
    final double offset = _enabled && _pressed ? drop : 0;

    Widget content = DefaultTextStyle(
      style: (context.text.labelLarge ?? const TextStyle()).copyWith(
        fontSize: widget.size.fontSize,
        color: _enabled ? foreground : tokens.inkSubtle,
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (widget.icon != null) ...<Widget>[
            Icon(
              widget.icon,
              size: widget.size.fontSize + 5,
              color: _enabled ? foreground : tokens.inkSubtle,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          if (widget.trailingIcon != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              widget.trailingIcon,
              size: widget.size.fontSize + 5,
              color: _enabled ? foreground : tokens.inkSubtle,
            ),
          ],
        ],
      ),
    );

    content = Container(
      height: widget.size.height,
      padding: EdgeInsets.symmetric(horizontal: widget.size.padding),
      decoration: BoxDecoration(
        color: _enabled ? base : tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
        border: widget.variant == AppButtonVariant.secondary
            ? Border.all(color: tokens.border, width: 1.5)
            : null,
      ),
      alignment: Alignment.center,
      child: content,
    );

    // La pile se dimensionne sur son enfant non positionné (le corps du
    // bouton plus la marge du relief). C'est ce qui permet au bouton de tenir
    // aussi bien dans une Row sans contrainte de largeur qu'en pleine largeur.
    Widget stack = Stack(
      children: <Widget>[
        if (drop > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: widget.size.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _enabled ? edgeColor : tokens.border,
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
        AnimatedPadding(
          duration: context.motionDuration(AppDurations.instant),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(top: offset, bottom: drop - offset),
          child: content,
        ),
      ],
    );
    if (widget.expand) {
      stack = SizedBox(width: double.infinity, child: stack);
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTap: _enabled
              ? () {
                  context.tapFeedback();
                  widget.onPressed!.call();
                }
              : null,
          child: stack,
        ),
      ),
    );
  }
}

/// Bouton circulaire discret, pour la navigation et les actions d'en-tête.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.filled = true,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// Afficher un fond de surface derrière l'icône.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Tooltip(
      message: tooltip ?? '',
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onPressed == null
              ? null
              : () {
                  context.tapFeedback();
                  onPressed!.call();
                },
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Container(
            // 44 dp : cible tactile confortable, y compris pour un enfant.
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: filled ? context.colors.surface : Colors.transparent,
              shape: BoxShape.circle,
              border: filled ? Border.all(color: tokens.border) : null,
            ),
            child: Icon(icon, size: 22, color: context.colors.onSurface),
          ),
        ),
      ),
    );
  }
}
