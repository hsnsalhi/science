/// Tuile de matière et carte de chapitre.
library;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_tokens.dart';
import '../domain/models/chapter.dart';
import 'app_card.dart';
import 'chips.dart';
import 'progress_indicators.dart';
import 'visuals.dart';

/// Grande tuile colorée d'une matière, sur l'accueil.
class SubjectTile extends StatelessWidget {
  const SubjectTile({
    required this.name,
    required this.tagline,
    required this.iconKey,
    required this.palette,
    required this.onTap,
    this.chapterCount = 0,
    this.completion = 0,
    super.key,
  });

  final String name;
  final String tagline;
  final String iconKey;
  final SubjectPalette palette;
  final VoidCallback onTap;

  /// Nombre de chapitres disponibles pour le niveau affiché.
  final int chapterCount;

  /// Part des chapitres terminés, de 0 à 1.
  final double completion;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      background: Colors.transparent,
      borderColor: Colors.transparent,
      semanticLabel: '$name. $tagline. $chapterCount chapitres.',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: palette.gradient,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Icon(
                      SubjectVisuals.icon(iconKey),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (completion > 0)
                    ProgressRing(
                      value: completion,
                      size: 36,
                      thickness: 4,
                      color: Colors.white,
                      trackColor: Colors.white.withValues(alpha: 0.3),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                name,
                style: context.text.titleLarge?.copyWith(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                tagline,
                style: context.text.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                chapterCount == 0
                    ? 'Bientôt disponible'
                    : '$chapterCount chapitre${chapterCount > 1 ? 's' : ''}',
                style: context.text.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte d'un chapitre dans la liste d'une matière.
class ChapterCard extends StatelessWidget {
  const ChapterCard({
    required this.chapter,
    required this.completion,
    required this.stars,
    required this.onTap,
    super.key,
  });

  final Chapter chapter;

  /// Part des leçons terminées, de 0 à 1.
  final double completion;

  /// Étoiles de maîtrise obtenues.
  final int stars;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final SubjectPalette palette = SubjectPalettes.of(chapter.subjectId);
    final bool playable = chapter.isPlayable;

    return AppCard(
      onTap: playable ? onTap : null,
      semanticLabel: playable
          ? '${chapter.title}. ${chapter.summary}'
          : '${chapter.title}. Bientôt disponible.',
      child: Opacity(
        opacity: playable ? 1 : 0.62,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ProgressRing(
              value: completion,
              size: 50,
              thickness: 5,
              color: palette.base,
              child: completion >= 1
                  ? Icon(Icons.check_rounded, size: 22, color: palette.base)
                  : Text(
                      '${chapter.order}',
                      style: context.text.titleMedium?.copyWith(
                        color: palette.base,
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(chapter.title, style: context.text.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    chapter.summary,
                    style: context.text.bodySmall?.copyWith(
                      color: tokens.inkMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      // Les classes d'abord : un élève cherche son année
                      // avant de lire le reste de la carte.
                      if (chapter.grades.isNotEmpty)
                        AppChip(
                          label: chapter.grades.join(' · '),
                          icon: Icons.school_rounded,
                          color: palette.base,
                          dense: true,
                        ),
                      if (playable) ...<Widget>[
                        StarRow(filled: stars, size: 17, animate: false),
                        AppChip(
                          label: '${chapter.lessons.length} leçons',
                          icon: Icons.layers_rounded,
                          dense: true,
                        ),
                        AppChip(
                          label: '${chapter.estimatedMinutes} min',
                          icon: Icons.schedule_rounded,
                          dense: true,
                        ),
                      ] else
                        AppChip(
                          label: 'Bientôt',
                          icon: Icons.hourglass_empty_rounded,
                          color: tokens.warning,
                          dense: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (playable)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: tokens.inkSubtle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
