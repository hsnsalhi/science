/// Mise en valeur des formules.
library;

import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/app_typography.dart';

/// Formule centrée dans un encadré.
///
/// Les formules sont écrites en Unicode dans le contenu (`a² + b² = c²`),
/// pas en LaTeX : cela couvre tout le programme jusqu'au lycée sans embarquer
/// de moteur de rendu mathématique, et reste lisible par un lecteur d'écran.
/// Le passage à LaTeX est prévu pour les chapitres universitaires (voir la
/// feuille de route).
class FormulaBlock extends StatelessWidget {
  const FormulaBlock({
    required this.formula,
    this.caption,
    this.accent,
    this.fontSize = 24,
    super.key,
  });

  final String formula;

  /// Légende sous la formule.
  final String? caption;

  /// Couleur d'accent ; par défaut, la couleur de marque.
  final Color? accent;

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Color color = accent ?? context.colors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        children: <Widget>[
          // Une formule longue défile plutôt que de se couper n'importe où.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              formula,
              style: AppTypography.formula(size: fontSize, color: color),
              textAlign: TextAlign.center,
            ),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              caption!,
              style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Formule courte insérée dans une ligne de texte.
class InlineFormula extends StatelessWidget {
  const InlineFormula(this.formula, {this.color, super.key});

  final String formula;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color accent = color ?? context.colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: context.isDark ? 0.18 : 0.09),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Text(
        formula,
        style: AppTypography.formula(size: 15, color: accent),
      ),
    );
  }
}
