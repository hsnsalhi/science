/// Proposition de réponse d'un quiz.
library;

import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_tokens.dart';

/// État visuel d'une proposition.
enum AnswerTileState {
  /// Disponible, non choisie.
  idle,

  /// Choisie, avant validation.
  selected,

  /// Bonne réponse, après validation.
  correct,

  /// Réponse choisie à tort, après validation.
  wrong,

  /// Bonne réponse révélée alors qu'elle n'avait pas été choisie.
  revealed,
}

/// Case de réponse d'un quiz.
///
/// Les cinq états sont tous distingués par **deux** signaux : la couleur et
/// une icône. Une personne daltonienne, ou un élève qui lit l'écran au soleil,
/// voit la différence entre juste et faux sans dépendre de la teinte.
class AnswerTile extends StatelessWidget {
  const AnswerTile({
    required this.label,
    required this.state,
    required this.onTap,
    this.leadingLetter,
    this.multiSelect = false,
    super.key,
  });

  final String label;
  final AnswerTileState state;

  /// `null` rend la case inerte (pendant l'affichage du retour).
  final VoidCallback? onTap;

  /// Lettre affichée à gauche (A, B, C…).
  final String? leadingLetter;

  /// Afficher une case à cocher plutôt qu'un rond.
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final (Color border, Color background, Color? icon) = switch (state) {
      AnswerTileState.idle => (tokens.border, context.colors.surface, null),
      AnswerTileState.selected => (
        context.colors.primary,
        context.colors.primary.withValues(alpha: context.isDark ? 0.18 : 0.08),
        null,
      ),
      AnswerTileState.correct => (
        tokens.success,
        tokens.successSoft,
        tokens.success,
      ),
      AnswerTileState.wrong => (tokens.error, tokens.errorSoft, tokens.error),
      AnswerTileState.revealed => (
        tokens.success,
        tokens.successSoft,
        tokens.success,
      ),
    };

    final IconData? trailing = switch (state) {
      AnswerTileState.correct => Icons.check_circle_rounded,
      AnswerTileState.revealed => Icons.lightbulb_rounded,
      AnswerTileState.wrong => Icons.cancel_rounded,
      _ => null,
    };

    final bool emphasised = state != AnswerTileState.idle;

    return Semantics(
      button: onTap != null,
      selected: state == AnswerTileState.selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                context.tapFeedback();
                onTap!.call();
              },
        child: AnimatedContainer(
          duration: context.motionDuration(AppDurations.fast),
          curve: Curves.easeOut,
          // 60 dp minimum : confortable au pouce, y compris pour un enfant.
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: border, width: emphasised ? 2 : 1.5),
          ),
          child: Row(
            children: <Widget>[
              _Marker(
                letter: leadingLetter,
                state: state,
                multiSelect: multiSelect,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyLarge?.copyWith(
                    fontWeight: emphasised ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                Icon(trailing, color: icon, size: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.letter,
    required this.state,
    required this.multiSelect,
  });

  final String? letter;
  final AnswerTileState state;
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool active = state != AnswerTileState.idle;
    final Color accent = switch (state) {
      AnswerTileState.idle => tokens.inkSubtle,
      AnswerTileState.selected => context.colors.primary,
      AnswerTileState.wrong => tokens.error,
      _ => tokens.success,
    };

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? accent : Colors.transparent,
        borderRadius: BorderRadius.circular(
          multiSelect ? AppRadii.xs : AppRadii.pill,
        ),
        border: Border.all(color: accent, width: 1.8),
      ),
      alignment: Alignment.center,
      child: letter == null
          ? (active
                ? Icon(
                    multiSelect ? Icons.check_rounded : Icons.circle,
                    size: multiSelect ? 18 : 10,
                    color: Colors.white,
                  )
                : const SizedBox.shrink())
          : Text(
              letter!,
              style: context.text.labelMedium?.copyWith(
                color: active ? Colors.white : tokens.inkMuted,
              ),
            ),
    );
  }
}

/// Lettre d'une proposition (A, B, C…) à partir de son rang.
String optionLetter(int index) => String.fromCharCode(65 + index);
