/// Catalogue complet des matières.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/selectors.dart';
import '../../core/layout/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/content/content_catalog.dart';
import '../../design_system/animations.dart';
import '../../design_system/app_scaffold.dart';
import '../../design_system/subject_tile.dart';
import '../../design_system/tile_grid.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/progress.dart';
import '../../domain/models/subject.dart';
import 'level_selector.dart';

/// Toutes les matières, filtrées par niveau.
class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({required this.onOpenSubject, super.key});

  final void Function(String subjectId) onOpenSubject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProgressState progress = ref.watch(progressProvider);
    final ContentCatalog catalog = ref.watch(contentCatalogProvider);
    final int columns = context.widthClass == WidthClass.compact ? 2 : 3;

    return AppScaffold(
      title: 'Matières',
      maxContentWidth: 860,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LevelSelector(
            selected: progress.profile.level,
            onSelected: ref.read(progressProvider.notifier).setLevel,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            progress.profile.level.grades,
            style: context.text.bodySmall?.copyWith(
              color: context.tokens.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TileGrid(
            columns: columns,
            children: <Widget>[
              for (int index = 0; index < catalog.subjects.length; index++)
                SlideFadeIn(
                  delay: Duration(milliseconds: 50 * index),
                  child: Builder(
                    builder: (BuildContext context) {
                      final Subject subject = catalog.subjects[index];
                      return SubjectTile(
                        name: subject.name,
                        tagline: subject.tagline,
                        iconKey: subject.iconKey,
                        palette: SubjectPalettes.of(subject.id),
                        chapterCount: catalog
                            .chaptersOf(subject.id, progress.profile.level)
                            .where((Chapter c) => c.isPlayable)
                            .length,
                        completion: subjectCompletion(
                          catalog,
                          progress,
                          subject.id,
                          progress.profile.level,
                        ),
                        onTap: () => onOpenSubject(subject.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
