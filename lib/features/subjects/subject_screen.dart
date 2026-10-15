/// Chapitres d'une matière.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/selectors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/content/content_catalog.dart';
import '../../design_system/animations.dart';
import '../../design_system/app_scaffold.dart';
import '../../design_system/subject_tile.dart';
import '../../design_system/visuals.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/progress.dart';
import '../../domain/models/subject.dart';
import 'level_selector.dart';

/// Liste des chapitres d'une matière pour le niveau choisi.
class SubjectScreen extends ConsumerWidget {
  const SubjectScreen({
    required this.subjectId,
    required this.onOpenChapter,
    super.key,
  });

  final String subjectId;
  final void Function(String chapterId) onOpenChapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContentCatalog catalog = ref.watch(contentCatalogProvider);
    final ProgressState progress = ref.watch(progressProvider);
    final Subject? subject = catalog.subjectById(subjectId);

    if (subject == null) {
      return const AppScaffold(
        showBack: true,
        title: 'Matière',
        body: EmptyState(
          icon: Icons.help_outline_rounded,
          title: 'Matière introuvable',
          message: 'Cette matière n\'existe pas ou plus dans le catalogue.',
        ),
      );
    }

    final SubjectPalette palette = SubjectPalettes.of(subject.id);
    final List<Chapter> chapters = catalog.chaptersOf(
      subject.id,
      progress.profile.level,
    );

    return AppScaffold(
      showBack: true,
      title: subject.name,
      maxContentWidth: 760,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SubjectHeader(subject: subject, palette: palette),
          const SizedBox(height: AppSpacing.lg),
          LevelSelector(
            selected: progress.profile.level,
            availableLevels: subject.levels,
            onSelected: ref.read(progressProvider.notifier).setLevel,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (chapters.isEmpty)
            EmptyState(
              icon: Icons.construction_rounded,
              title: 'Rien ici pour l\'instant',
              message:
                  '${subject.name} en ${progress.profile.level.label} arrive '
                  'bientôt. Essaie un autre niveau en attendant.',
            )
          else
            for (int i = 0; i < chapters.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: SlideFadeIn(
                  // Le catalogue d'une matière peut compter une
                  // quinzaine de chapitres : au-delà des premiers,
                  // l'escalier d'apparition ferait attendre.
                  delay: Duration(milliseconds: 45 * (i < 8 ? i : 8)),
                  child: Builder(
                    builder: (BuildContext context) {
                      final Chapter chapter = chapters[i];
                      final ChapterProgressView view = chapterProgressOf(
                        chapter,
                        progress,
                      );
                      return ChapterCard(
                        chapter: chapter,
                        completion: view.completion,
                        stars: view.stars,
                        onTap: () => onOpenChapter(chapter.id),
                      );
                    },
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({required this.subject, required this.palette});

  final Subject subject;
  final SubjectPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: palette.gradient,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(
              SubjectVisuals.icon(subject.iconKey),
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  subject.tagline,
                  style: context.text.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subject.description,
                  style: context.text.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
