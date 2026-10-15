/// Retour affiché après chaque validation.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../design_system/animations.dart';
import '../../design_system/app_button.dart';
import '../../design_system/chips.dart';
import '../../design_system/mascot.dart';
import '../../design_system/reward_burst.dart';
import '../../domain/models/question.dart';
import '../../domain/services/quiz_session.dart';
import '../../domain/services/xp_engine.dart';

/// Panneau de retour : verdict, explication, suite.
///
/// Ce panneau est le moment pédagogique du quiz. Trois règles s'y appliquent :
/// l'explication s'affiche **aussi** quand la réponse est juste ; une erreur
/// donne d'abord un second essai, pas la solution ; et le ton reste
/// encourageant — Nova a une expression rassurante, jamais déçue.
class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    required this.verdict,
    required this.question,
    required this.accent,
    required this.onContinue,
    this.xpEarned = 0,
    this.combo = 0,
    super.key,
  });

  final QuizVerdict verdict;
  final Question question;
  final Color accent;
  final VoidCallback onContinue;

  /// XP gagnés sur cette question, affichés comme récompense immédiate.
  final int xpEarned;

  /// Bonnes réponses d'affilée du premier coup, série en cours comprise.
  final int combo;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool correct = verdict == QuizVerdict.correct;
    final bool retry = verdict == QuizVerdict.retry;

    final Color color = switch (verdict) {
      QuizVerdict.correct => tokens.success,
      QuizVerdict.retry => tokens.warning,
      QuizVerdict.revealed => tokens.error,
    };
    final String title = switch (verdict) {
      QuizVerdict.correct => 'Bien vu !',
      QuizVerdict.retry => 'Pas tout à fait…',
      QuizVerdict.revealed => 'On regarde ensemble',
    };
    final MascotMood mood = switch (verdict) {
      QuizVerdict.correct => MascotMood.bravo,
      QuizVerdict.retry => MascotMood.pensif,
      QuizVerdict.revealed => MascotMood.rassurant,
    };

    return PopIn(
      duration: AppDurations.fast,
      from: 0.98,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // L'éclat part de la mascotte : c'est le point que l'œil
              // regarde au moment où le panneau s'ouvre.
              RewardBurst(
                trigger: correct ? question.id : null,
                color: color,
                child: Mascot(mood: mood, size: 52, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          title,
                          style: context.text.titleLarge?.copyWith(
                            color: color,
                          ),
                        ),
                        if (correct && xpEarned > 0) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          PopIn(
                            delay: const Duration(milliseconds: 120),
                            from: 0.4,
                            child: AppChip(
                              label: '+$xpEarned XP',
                              icon: Icons.bolt_rounded,
                              color: color,
                              dense: true,
                            ),
                          ),
                        ],
                        // Le bonus de rapidité est annoncé à part : fondu
                        // dans le total, il passerait pour un barème qui
                        // change tout seul.
                        if (correct && xpEarned > XpEngine.xpFirstTry)
                          ...<Widget>[
                            const SizedBox(width: AppSpacing.xs),
                            PopIn(
                              delay: const Duration(milliseconds: 180),
                              from: 0.4,
                              child: AppChip(
                                label: 'rapide',
                                icon: Icons.timer_rounded,
                                color: accent,
                                dense: true,
                              ),
                            ),
                          ],
                        // La série ne s'annonce qu'à partir de deux : à un,
                        // elle n'a encore rien d'une série.
                        if (correct && combo >= 2) ...<Widget>[
                          const SizedBox(width: AppSpacing.xs),
                          PopIn(
                            delay: const Duration(milliseconds: 220),
                            from: 0.4,
                            child: AppChip(
                              label: '×$combo',
                              icon: Icons.local_fire_department_rounded,
                              color: tokens.warning,
                              dense: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      // On ne révèle l'explication qu'une fois la question
                      // close : pendant un second essai, elle serait la
                      // réponse.
                      retry
                          ? 'Relis bien l\'énoncé, puis retente.'
                          : question.explanation,
                      style: context.text.bodyMedium,
                    ),
                    if (!correct && !retry) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Bonne réponse : ${question.solutionLabel}',
                        style: context.text.labelMedium?.copyWith(
                          color: tokens.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: retry ? 'Réessayer' : 'Continuer',
            variant: correct
                ? AppButtonVariant.success
                : AppButtonVariant.primary,
            color: retry ? accent : null,
            trailingIcon: retry
                ? Icons.refresh_rounded
                : Icons.arrow_forward_rounded,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
