/// Pastilles d'information.
library;

import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_tokens.dart';
import '../domain/models/education_level.dart';
import 'visuals.dart';

/// Pastille compacte : icône, valeur, couleur d'accent.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    this.icon,
    this.color,
    this.filled = true,
    this.dense = false,
    super.key,
  });

  final String label;
  final IconData? icon;

  /// Couleur d'accent ; par défaut, la couleur de texte secondaire.
  final Color? color;

  /// Afficher un fond teinté.
  final bool filled;

  /// Version réduite, pour les listes denses.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Color accent = color ?? tokens.inkMuted;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: filled
            ? accent.withValues(alpha: context.isDark ? 0.2 : 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: filled ? null : Border.all(color: tokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 13 : 15, color: accent),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: (dense ? context.text.labelSmall : context.text.labelMedium)
                ?.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

/// Pastille d'un niveau scolaire.
class LevelChip extends StatelessWidget {
  const LevelChip({required this.level, this.dense = false, super.key});

  final EducationLevel level;
  final bool dense;

  @override
  Widget build(BuildContext context) => AppChip(
    label: level.label,
    icon: LevelVisuals.icon(level),
    color: LevelVisuals.color(level),
    dense: dense,
  );
}

/// Grande tuile de statistique, pour le profil et l'accueil.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: tokens.border, width: 1.2),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 24, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: context.text.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: context.text.labelSmall?.copyWith(color: tokens.inkMuted),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
