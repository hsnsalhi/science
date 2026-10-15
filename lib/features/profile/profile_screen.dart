/// Profil : rang, statistiques, activité.
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
import '../../design_system/app_button.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_scaffold.dart';
import '../../design_system/chips.dart';
import '../../design_system/mascot.dart';
import '../../design_system/progress_indicators.dart';
import '../../design_system/visuals.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/progress.dart';
import '../../domain/models/rank.dart';
import '../../domain/models/subject.dart';
import '../../domain/services/mastery_engine.dart';
import '../../domain/services/streak_engine.dart';
import '../../domain/services/xp_engine.dart';

/// Tableau de bord personnel de l'élève.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({required this.onOpenSettings, super.key});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProgressState progress = ref.watch(progressProvider);
    final ContentCatalog catalog = ref.watch(contentCatalogProvider);
    final StreakInfo streak = ref.watch(streakProvider);
    final DateTime now = ref.watch(clockProvider)();

    final int lessonsDone = progress.lessons.values
        .where((LessonRecord r) => r.isCompleted)
        .length;
    final int chaptersMastered = catalog.chapters
        .where(
          (Chapter c) =>
              c.isPlayable && chapterProgressOf(c, progress).stars >= 3,
        )
        .length;

    return AppScaffold(
      title: 'Mon profil',
      maxContentWidth: 760,
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
          _RankCard(progress: progress),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  icon: Icons.bolt_rounded,
                  value: '${progress.totalXp}',
                  label: 'XP au total',
                  color: context.tokens.gold,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '${streak.current}',
                  label: 'série en cours',
                  color: const Color(0xFFF2762E),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(
                  icon: Icons.emoji_events_rounded,
                  value: '${progress.bestStreak}',
                  label: 'meilleure série',
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  icon: Icons.menu_book_rounded,
                  value: '$lessonsDone',
                  label: 'leçons terminées',
                  color: context.tokens.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(
                  icon: Icons.star_rounded,
                  value: '$chaptersMastered',
                  label: 'chapitres maîtrisés',
                  color: context.tokens.gold,
                ),
              ),
            ],
          ),
          const SectionHeader(
            title: 'Ces deux semaines',
            subtitle: 'XP gagnés par jour',
          ),
          _ActivityChart(
            dailyXp: progress.dailyXp,
            goal: progress.profile.dailyGoalXp,
            today: now,
          ),
          const SectionHeader(title: 'Par matière'),
          for (final Subject subject in catalog.subjects)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _SubjectProgressRow(
                subject: subject,
                completion: subjectCompletion(
                  catalog,
                  progress,
                  subject.id,
                  progress.profile.level,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.progress});

  final ProgressState progress;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Rank rank = progress.rank;
    final int? toNext = XpEngine.xpToNextRank(progress.totalXp);
    return AppCard(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Mascot(size: 72, mood: MascotMood.joyeux),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      progress.profile.firstName ?? 'Élève curieux',
                      style: context.text.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: <Widget>[
                        AppChip(
                          label: rank.label,
                          icon: Icons.military_tech_rounded,
                          color: tokens.gold,
                          dense: true,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        LevelChip(level: progress.profile.level, dense: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppProgressBar(
            value: XpEngine.rankProgress(progress.totalXp),
            semanticLabel: 'Progression vers le rang suivant',
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              toNext == null
                  ? 'Rang maximal atteint. Chapeau.'
                  : 'Encore $toNext XP pour devenir ${rank.next!.label}.',
              style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Histogramme des XP des quatorze derniers jours.
class _ActivityChart extends StatelessWidget {
  const _ActivityChart({
    required this.dailyXp,
    required this.goal,
    required this.today,
  });

  final Map<DayKey, int> dailyXp;
  final int goal;
  final DateTime today;

  /// Nombre de jours affichés.
  static const int days = 14;

  static const List<String> _initials = <String>[
    'L',
    'M',
    'M',
    'J',
    'V',
    'S',
    'D',
  ];

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final List<(DateTime, int)> series = <(DateTime, int)>[
      for (int i = days - 1; i >= 0; i--)
        () {
          final DateTime day = DateTime(
            today.year,
            today.month,
            today.day,
          ).subtract(Duration(days: i));
          return (day, dailyXp[dayKeyOf(day)] ?? 0);
        }(),
    ];
    final int peak = series.fold<int>(
      goal,
      (int m, (DateTime, int) e) => e.$2 > m ? e.$2 : m,
    );

    return AppCard(
      child: SizedBox(
        height: 136,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (final (DateTime day, int xp) in series)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        xp > 0 ? '$xp' : '',
                        style: context.text.labelSmall?.copyWith(
                          color: tokens.inkSubtle,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: peak == 0 ? 0 : xp / peak,
                        ),
                        duration: AppDurations.slow,
                        curve: AppCurves.move,
                        builder: (BuildContext context, double t, _) =>
                            Container(
                              height: 8 + 74 * t,
                              decoration: BoxDecoration(
                                color: xp >= goal && goal > 0
                                    ? tokens.success
                                    : (xp > 0
                                          ? context.colors.primary.withValues(
                                              alpha: 0.5,
                                            )
                                          : tokens.surfaceAlt),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.xs,
                                ),
                              ),
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _initials[day.weekday - 1],
                        style: context.text.labelSmall?.copyWith(
                          color: tokens.inkSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubjectProgressRow extends StatelessWidget {
  const _SubjectProgressRow({required this.subject, required this.completion});

  final Subject subject;
  final double completion;

  @override
  Widget build(BuildContext context) {
    final SubjectPalette palette = SubjectPalettes.of(subject.id);
    return Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: palette.base.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Icon(
            SubjectVisuals.icon(subject.iconKey),
            size: 20,
            color: palette.base,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(subject.name, style: context.text.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              AppProgressBar(
                value: completion,
                height: 8,
                color: palette.base,
                semanticLabel: 'Avancement en ${subject.name}',
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          '${(completion * 100).round()} %',
          style: context.text.labelMedium?.copyWith(
            color: context.tokens.inkMuted,
          ),
        ),
      ],
    );
  }
}

/// Étoiles de maîtrise maximales d'un chapitre, exposé pour les tests.
const int maxChapterStars = MasteryEngine.maxStars;
