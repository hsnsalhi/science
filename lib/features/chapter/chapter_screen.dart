/// Parcours d'un chapitre.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/selectors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/content/content_catalog.dart';
import '../../design_system/app_button.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_scaffold.dart';
import '../../design_system/chips.dart';
import '../../design_system/lesson_path.dart';
import '../../design_system/progress_indicators.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/lesson.dart';
import '../../domain/models/progress.dart';

/// En-tête du chapitre puis parcours de ses leçons.
class ChapterScreen extends ConsumerWidget {
  const ChapterScreen({
    required this.chapterId,
    required this.onOpenLesson,
    super.key,
  });

  final String chapterId;
  final void Function(String chapterId, String lessonId) onOpenLesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContentCatalog catalog = ref.watch(contentCatalogProvider);
    final ProgressState progress = ref.watch(progressProvider);
    final Chapter? chapter = catalog.chapterById(chapterId);

    if (chapter == null || chapter.lessons.isEmpty) {
      return const AppScaffold(
        showBack: true,
        title: 'Chapitre',
        body: EmptyState(
          icon: Icons.hourglass_empty_rounded,
          title: 'Chapitre en préparation',
          message: 'Le contenu de ce chapitre n\'est pas encore disponible.',
        ),
      );
    }

    final SubjectPalette palette = SubjectPalettes.of(chapter.subjectId);
    final ChapterProgressView view = chapterProgressOf(chapter, progress);
    final String? nextLessonId = view.nextLessonId;

    return AppScaffold(
      showBack: true,
      title: chapter.title,
      maxContentWidth: 640,
      bottomBar: AppButton(
        label: view.completion >= 1
            ? 'Réviser le chapitre'
            : (view.completion > 0 ? 'Continuer' : 'Commencer'),
        color: palette.base,
        trailingIcon: Icons.arrow_forward_rounded,
        onPressed: () =>
            onOpenLesson(chapter.id, nextLessonId ?? chapter.lessons.first.id),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ChapterHeader(chapter: chapter, view: view, palette: palette),
          const SizedBox(height: AppSpacing.xl),
          LessonPath(
            color: palette.base,
            nodes: <LessonNodeData>[
              for (final Lesson lesson in chapter.lessons)
                LessonNodeData(
                  id: lesson.id,
                  title: lesson.title,
                  kind: lesson.kind,
                  perfect: progress.recordFor(chapter.id, lesson.id).isPerfect,
                  state: _stateOf(
                    lessonId: lesson.id,
                    record: progress.recordFor(chapter.id, lesson.id),
                    nextLessonId: nextLessonId,
                  ),
                ),
            ],
            onTap: (String lessonId) => onOpenLesson(chapter.id, lessonId),
          ),
        ],
      ),
    );
  }

  static LessonNodeState _stateOf({
    required String lessonId,
    required LessonRecord record,
    required String? nextLessonId,
  }) {
    if (record.isCompleted) return LessonNodeState.termine;
    if (lessonId == nextLessonId) return LessonNodeState.enCours;
    return LessonNodeState.aVenir;
  }
}

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({
    required this.chapter,
    required this.view,
    required this.palette,
  });

  final Chapter chapter;
  final ChapterProgressView view;
  final SubjectPalette palette;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      background: palette.tint(Theme.of(context).brightness),
      borderColor: palette.base.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              StarRow(filled: view.stars, size: 22),
              const Spacer(),
              AppChip(
                label: '${chapter.estimatedMinutes} min',
                icon: Icons.schedule_rounded,
                color: palette.base,
                dense: true,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppChip(
                label: '${chapter.totalXp} XP',
                icon: Icons.bolt_rounded,
                color: context.tokens.gold,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(chapter.summary, style: context.text.bodyMedium),
          if (chapter.objectives.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'À la fin de ce chapitre, tu sauras :',
              style: context.text.labelMedium?.copyWith(
                color: context.tokens.inkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final String objective in chapter.objectives)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 17,
                      color: palette.base,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(objective, style: context.text.bodySmall),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppProgressBar(
            value: view.completion,
            color: palette.base,
            semanticLabel: 'Avancement du chapitre',
          ),
        ],
      ),
    );
  }
}
