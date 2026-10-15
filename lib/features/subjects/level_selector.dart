/// Sélecteur de niveau scolaire.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../design_system/visuals.dart';
import '../../domain/models/education_level.dart';

/// Barre de choix du niveau, défilante sur petit écran.
///
/// Changer de niveau est une action courante et assumée : un élève de 3ᵉ peut
/// réviser une notion de 5ᵉ, un lycéen peut aller voir le supérieur. Le
/// sélecteur reste donc visible en permanence plutôt que caché dans les
/// réglages.
class LevelSelector extends StatelessWidget {
  const LevelSelector({
    required this.selected,
    required this.onSelected,
    this.availableLevels,
    super.key,
  });

  final EducationLevel selected;
  final ValueChanged<EducationLevel> onSelected;

  /// Niveaux proposés ; tous par défaut.
  final List<EducationLevel>? availableLevels;

  @override
  Widget build(BuildContext context) {
    final List<EducationLevel> levels =
        availableLevels ?? EducationLevel.ordered;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: levels.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final EducationLevel level = levels[index];
          final bool active = level == selected;
          final Color color = LevelVisuals.color(level);
          return GestureDetector(
            onTap: () {
              context.tapFeedback();
              onSelected(level);
            },
            child: AnimatedContainer(
              duration: context.motionDuration(AppDurations.fast),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: active
                    ? color.withValues(alpha: context.isDark ? 0.24 : 0.14)
                    : context.colors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: active ? color : context.tokens.border,
                  width: active ? 1.8 : 1.2,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    LevelVisuals.icon(level),
                    size: 17,
                    color: active ? color : context.tokens.inkSubtle,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    level.label,
                    style: context.text.labelMedium?.copyWith(
                      color: active ? color : context.tokens.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
