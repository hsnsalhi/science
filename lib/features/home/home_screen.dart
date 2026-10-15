/// Écran d'accueil.
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
import '../../design_system/app_button.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_scaffold.dart';
import '../../design_system/chips.dart';
import '../../design_system/progress_indicators.dart';
import '../../design_system/subject_tile.dart';
import '../../design_system/tile_grid.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/progress.dart';
import '../../domain/models/rank.dart';
import '../../domain/models/subject.dart';
import '../../domain/services/streak_engine.dart';

/// Accueil : objectif du jour, reprise, matières.
///
/// L'écran répond à une seule question — « qu'est-ce que je fais
/// maintenant ? » — avant de proposer d'explorer. D'où l'ordre : objectif,
/// bouton de reprise, puis seulement le catalogue.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    required this.onOpenSubject,
    required this.onOpenLesson,
    required this.onOpenSettings,
    super.key,
  });

  final void Function(String subjectId) onOpenSubject;
  final void Function(String chapterId, String lessonId) onOpenLesson;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProgressState progress = ref.watch(progressProvider);
    final ContentCatalog catalog = ref.watch(contentCatalogProvider);
    final StreakInfo streak = ref.watch(streakProvider);
    final int todayXp = ref.watch(todayXpProvider);
    final NextStep? next = ref.watch(nextStepProvider);

    final String? name = progress.profile.firstName;
    final int goal = progress.profile.dailyGoalXp;

    return AppScaffold(
      maxContentWidth: 860,
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            name == null ? 'Bonjour !' : 'Bonjour $name',
            style: context.text.headlineMedium,
          ),
          Text(
            progress.profile.level.label,
            style: context.text.labelSmall?.copyWith(
              color: context.tokens.inkMuted,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        AppIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Réglages',
          filled: false,
          onPressed: onOpenSettings,
        ),
      ],
      body: StaggeredColumn(
        spacing: AppSpacing.lg,
        children: <Widget>[
          _DailyGoalCard(
            todayXp: todayXp,
            goal: goal,
            streak: streak,
            rank: progress.rank,
          ),
          if (next != null)
            _ContinueCard(
              next: next,
              onTap: () => onOpenLesson(next.chapter.id, next.lesson.id),
            ),
          const SectionHeader(
            title: 'Les matières',
            padding: EdgeInsets.only(top: AppSpacing.md),
          ),
          _SubjectGrid(
            catalog: catalog,
            progress: progress,
            onOpenSubject: onOpenSubject,
          ),
        ],
      ),
    );
  }
}

/// Carte de l'objectif quotidien.
class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({
    required this.todayXp,
    required this.goal,
    required this.streak,
    required this.rank,
  });

  final int todayXp;
  final int goal;
  final StreakInfo streak;
  final Rank rank;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool reached = todayXp >= goal;
    return AppCard(
      child: Row(
        children: <Widget>[
          ProgressRing(
            value: goal == 0 ? 0 : todayXp / goal,
            size: 78,
            thickness: 8,
            color: reached ? tokens.success : context.colors.primary,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CountUpText(value: todayXp, style: context.text.titleMedium),
                Text(
                  '/ $goal',
                  style: context.text.labelSmall?.copyWith(
                    color: tokens.inkSubtle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  reached ? 'Objectif du jour atteint ' : 'Objectif du jour',
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  reached
                      ? 'Bravo ! Tout XP de plus est du bonus.'
                      : 'Encore ${goal - todayXp} XP pour y arriver.',
                  style: context.text.bodySmall?.copyWith(
                    color: tokens.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    AppChip(
                      label: streak.current == 0
                          ? 'Aucune série'
                          : '${streak.current} jour'
                                '${streak.current > 1 ? 's' : ''}',
                      icon: Icons.local_fire_department_rounded,
                      color: streak.current > 0
                          ? const Color(0xFFF2762E)
                          : tokens.inkSubtle,
                      dense: true,
                    ),
                    AppChip(
                      label: rank.label,
                      icon: Icons.military_tech_rounded,
                      color: tokens.gold,
                      dense: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte « reprendre où j'en étais ».
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.next, required this.onTap});

  final NextStep next;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SubjectPalette palette = SubjectPalettes.of(next.chapter.subjectId);
    return AppCard(
      onTap: onTap,
      background: palette.tint(Theme.of(context).brightness),
      borderColor: palette.base.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                next.isReview
                    ? Icons.refresh_rounded
                    : Icons.play_circle_fill_rounded,
                color: palette.base,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                next.isReview ? 'Réviser' : 'Reprendre',
                style: context.text.labelMedium?.copyWith(color: palette.base),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(next.lesson.title, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            next.chapter.title,
            style: context.text.bodySmall?.copyWith(
              color: context.tokens.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: next.isReview ? 'Réviser la leçon' : 'Commencer',
            color: palette.base,
            size: AppButtonSize.medium,
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _SubjectGrid extends StatelessWidget {
  const _SubjectGrid({
    required this.catalog,
    required this.progress,
    required this.onOpenSubject,
  });

  final ContentCatalog catalog;
  final ProgressState progress;
  final void Function(String subjectId) onOpenSubject;

  @override
  Widget build(BuildContext context) {
    final int columns = context.widthClass == WidthClass.compact ? 2 : 3;
    return TileGrid(
      columns: columns,
      children: <Widget>[
        for (final Subject subject in catalog.subjects)
          SubjectTile(
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
          ),
      ],
    );
  }
}

/// Rappel de la promesse du projet, en pied d'accueil.
