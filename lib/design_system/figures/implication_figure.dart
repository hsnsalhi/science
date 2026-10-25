/// « Si… alors » mis à l'épreuve des quatre cas.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';

/// Une implication, sa réciproque, et le seul cas qui les met en défaut.
///
/// « S'il pleut, alors le sol est mouillé » est une phrase que chacun
/// accepte, et dont presque personne ne sait dire quand elle est fausse.
/// Elle ne l'est que dans un cas : il pleut et le sol est sec. Les trois
/// autres la laissent debout, y compris celui où il ne pleut pas et où
/// le sol est pourtant mouillé — quelqu'un a arrosé.
///
/// C'est précisément ce cas qui porte la leçon : il rend l'implication
/// vraie tout en rendant sa réciproque fausse. Une figure qui ne
/// montrerait que l'implication laisserait croire que les deux vont
/// ensemble, ce qui est l'erreur à défaire.
class ImplicationFigure extends StatefulWidget {
  const ImplicationFigure({required this.accent, super.key});

  final Color accent;

  /// Valeur de « si [a] alors [b] ».
  ///
  /// Fausse uniquement quand la condition est vraie et la conclusion
  /// fausse : promettre quelque chose et ne pas le tenir.
  static bool implique(bool a, bool b) => !a || b;

  /// Ce que le cas courant permet de dire, en une phrase.
  static String commentaire(bool pluie, bool mouille) {
    if (pluie && mouille) return 'La règle est respectée.';
    if (pluie && !mouille) {
      return 'C\'est le seul cas interdit : il pleut et le sol est sec.';
    }
    if (!pluie && mouille) {
      return 'Le sol est mouillé sans pluie : quelqu\'un a arrosé. '
          'La règle tient toujours, mais sa réciproque tombe.';
    }
    return 'Sans pluie et sans eau, la règle n\'est pas mise à l\'épreuve.';
  }

  @override
  State<ImplicationFigure> createState() => _ImplicationFigureState();
}

class _ImplicationFigureState extends State<ImplicationFigure> {
  bool _pluie = true;
  bool _mouille = true;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // Les quatre cas défilent, et celui qui surprend arrive de lui-même :
    // pas de pluie et sol mouillé, où l'implication reste vraie. C'est le
    // cas qu'un élève ne va jamais chercher tout seul.
    final int? cas = Autoplay.index(context, 4);
    final bool pluie = _tenue || cas == null ? _pluie : cas < 2;
    final bool mouille = _tenue || cas == null ? _mouille : cas.isEven;
    final bool directe = ImplicationFigure.implique(pluie, mouille);
    final bool reciproque = ImplicationFigure.implique(mouille, pluie);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _Bascule(
                nom: 'P',
                phrase: 'il pleut',
                actif: pluie,
                accent: widget.accent,
                onTap: () {
                  context.tapFeedback();
                  setState(() {
                    _pluie = !pluie;
                    _mouille = mouille;
                    _tenue = true;
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _Bascule(
                nom: 'M',
                phrase: 'le sol est mouillé',
                actif: mouille,
                accent: widget.accent,
                onTap: () {
                  context.tapFeedback();
                  setState(() {
                    _pluie = pluie;
                    _mouille = !mouille;
                    _tenue = true;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _Verdict(
          enonce: 'Si P alors M',
          vrai: directe,
          accent: widget.accent,
        ),
        _Verdict(
          enonce: 'Réciproque : si M alors P',
          vrai: reciproque,
          accent: widget.accent,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          ImplicationFigure.commentaire(pluie, mouille),
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Touche P ou M pour changer de cas',
          textAlign: TextAlign.center,
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

/// Une affirmation qu'on allume ou qu'on éteint.
class _Bascule extends StatelessWidget {
  const _Bascule({
    required this.nom,
    required this.phrase,
    required this.actif,
    required this.accent,
    required this.onTap,
  });

  final String nom;
  final String phrase;
  final bool actif;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: context.motionDuration(AppDurations.fast),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: actif
              ? accent.withValues(alpha: context.isDark ? 0.24 : 0.12)
              : context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: actif ? accent : tokens.border,
            width: actif ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  nom,
                  style: context.text.titleMedium?.copyWith(
                    color: actif ? accent : tokens.inkMuted,
                  ),
                ),
                const Spacer(),
                Icon(
                  actif ? Icons.check_circle_rounded : Icons.cancel_outlined,
                  size: 20,
                  color: actif ? accent : tokens.inkSubtle,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              phrase,
              style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              actif ? 'vrai' : 'faux',
              style: context.text.labelMedium?.copyWith(
                color: actif ? accent : tokens.inkSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le sort d'un énoncé dans le cas courant.
class _Verdict extends StatelessWidget {
  const _Verdict({
    required this.enonce,
    required this.vrai,
    required this.accent,
  });

  final String enonce;
  final bool vrai;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Color couleur = vrai ? tokens.success : tokens.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(enonce, style: context.text.titleSmall)),
          Icon(
            vrai ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 20,
            color: couleur,
          ),
          const SizedBox(width: AppSpacing.xs),
          AnimatedDefaultTextStyle(
            duration: context.motionDuration(AppDurations.fast),
            style:
                context.text.bodyMedium?.copyWith(
                  color: couleur,
                  fontWeight: FontWeight.w700,
                ) ??
                const TextStyle(),
            child: Text(vrai ? 'vrai' : 'faux'),
          ),
        ],
      ),
    );
  }
}
