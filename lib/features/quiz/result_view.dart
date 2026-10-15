/// Écran de fin de leçon.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/selectors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../design_system/animations.dart';
import '../../design_system/app_button.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_scaffold.dart';
import '../../design_system/chips.dart';
import '../../design_system/confetti.dart';
import '../../design_system/mascot.dart';
import '../../design_system/progress_indicators.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/lesson.dart';
import '../../domain/models/progress.dart';
import '../../domain/services/streak_engine.dart';
import '../../domain/services/quiz_session.dart';

/// Bilan d'une leçon terminée.
///
/// La célébration est proportionnée : des confettis pour un sans-faute, un
/// bilan chaleureux sinon. Un écran de fin identique quel que soit le
/// résultat rendrait la récompense sans valeur ; un écran punitif
/// découragerait. L'entre-deux est l'objectif.
class QuizResultView extends ConsumerWidget {
  const QuizResultView({
    required this.session,
    required this.chapter,
    required this.lesson,
    required this.accent,
    required this.onExit,
    required this.onRestart,
    this.onNextLesson,
    super.key,
  });

  final QuizSession session;
  final Chapter chapter;
  final Lesson lesson;
  final Color accent;
  final VoidCallback onExit;
  final VoidCallback onRestart;

  /// `null` s'il s'agit de la dernière leçon du chapitre.
  final VoidCallback? onNextLesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppTokens tokens = context.tokens;
    final ProgressState progress = ref.watch(progressProvider);
    final StreakInfo streak = ref.watch(streakProvider);
    final ChapterProgressView view = chapterProgressOf(chapter, progress);
    final bool perfect = session.isPerfect;
    final int percent = session.total == 0
        ? 0
        : (session.solvedFirstTry / session.total * 100).round();

    return ConfettiOverlay(
      play: perfect,
      child: AppScaffold(
        maxContentWidth: 560,
        bottomBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (onNextLesson != null)
              AppButton(
                label: 'Leçon suivante',
                color: accent,
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: onNextLesson,
              )
            else
              AppButton(
                label: 'Retour au chapitre',
                color: accent,
                onPressed: onExit,
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AppButton.ghost(
                  label: 'Refaire',
                  icon: Icons.refresh_rounded,
                  onPressed: onRestart,
                ),
                if (onNextLesson != null)
                  AppButton.ghost(
                    label: 'Retour au chapitre',
                    icon: Icons.list_rounded,
                    onPressed: onExit,
                  ),
              ],
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.xl),
            PopIn(
              child: Mascot(
                size: 128,
                mood: perfect ? MascotMood.bravo : MascotMood.joyeux,
                color: accent,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              perfect ? 'Sans faute !' : 'Leçon terminée',
              style: context.text.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _encouragement(percent),
              style: context.text.bodyMedium?.copyWith(color: tokens.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: <Widget>[
                Expanded(
                  child: _XpTile(xp: session.xpEarned, perfect: perfect),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatTile(
                    icon: Icons.check_circle_rounded,
                    value: '${session.solvedFirstTry}/${session.total}',
                    label: 'du premier coup',
                    color: tokens.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatTile(
                    icon: Icons.local_fire_department_rounded,
                    value: '${streak.current}',
                    label: streak.current > 1 ? 'jours de suite' : 'jour',
                    color: const Color(0xFFF2762E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          chapter.title,
                          style: context.text.titleMedium,
                        ),
                      ),
                      StarRow(filled: view.stars, size: 20),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppProgressBar(
                    value: view.completion,
                    color: accent,
                    semanticLabel: 'Avancement du chapitre',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    view.stars < 3
                        ? _starHint(view.stars)
                        : 'Chapitre maîtrisé. Bravo !',
                    style: context.text.bodySmall?.copyWith(
                      color: tokens.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _encouragement(int percent) {
    if (percent == 100) return 'Toutes les réponses justes du premier coup.';
    if (percent >= 70) return 'Très bon travail, continue comme ça.';
    if (percent >= 40) {
      return 'C\'est en cours. Refaire la leçon fixera les idées.';
    }
    return 'Le plus dur est de commencer, et c\'est fait. On y retourne ?';
  }

  String _starHint(int stars) => switch (stars) {
    0 => 'Termine toutes les leçons du chapitre pour décrocher ta 1ʳᵉ étoile.',
    1 => 'Vise 80 % de bonnes réponses pour la 2ᵉ étoile.',
    _ => 'Reviens un autre jour avec un quasi sans-faute pour la 3ᵉ étoile.',
  };
}

/// Tuile des XP gagnés, avec le bonus de sans-faute détaillé.
class _XpTile extends StatelessWidget {
  const _XpTile({required this.xp, required this.perfect});

  final int xp;
  final bool perfect;

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
          Icon(Icons.bolt_rounded, size: 24, color: tokens.gold),
          const SizedBox(height: AppSpacing.sm),
          CountUpText(value: xp, prefix: '+', style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            perfect ? 'XP, bonus compris' : 'XP gagnés',
            style: context.text.labelSmall?.copyWith(color: tokens.inkMuted),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
