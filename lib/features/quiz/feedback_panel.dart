/// Retour affiché après chaque validation.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../design_system/animations.dart';
import '../../design_system/app_button.dart';
import '../../design_system/mascot.dart';
import '../../domain/models/question.dart';
import '../../domain/services/quiz_session.dart';

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
    super.key,
  });

  final QuizVerdict verdict;
  final Question question;
  final Color accent;
  final VoidCallback onContinue;

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
              Mascot(mood: mood, size: 52, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: context.text.titleLarge?.copyWith(color: color),
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
