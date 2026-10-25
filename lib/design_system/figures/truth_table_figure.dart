/// Table de vérité manipulable : deux interrupteurs, trois résultats.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';

/// Deux affirmations qu'on allume ou éteint, et ce que valent « et »,
/// « ou » et « non ».
///
/// Une table de vérité imprimée se lit comme un tableau à apprendre. En
/// basculant soi-même A et B, on voit la ligne changer : « ou » reste
/// allumé quand les deux le sont — c'est le point que l'usage courant
/// fait manquer, et il faut l'avoir sous les yeux pour y croire.
class TruthTableFigure extends StatefulWidget {
  const TruthTableFigure({required this.accent, super.key});

  final Color accent;

  @override
  State<TruthTableFigure> createState() => _TruthTableFigureState();
}

class _TruthTableFigureState extends State<TruthTableFigure> {
  bool _a = true;
  bool _b = false;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  void _basculer(bool valeurA, bool a, bool b) {
    context.tapFeedback();
    setState(() {
      // Le premier geste fige la combinaison affichée avant d'en changer
      // une moitié : sinon l'autre sauterait à sa valeur de départ.
      _a = valeurA ? !a : a;
      _b = valeurA ? b : !b;
      _tenue = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Les quatre combinaisons défilent dans l'ordre : chaque opérateur
    // montre ses quatre résultats, et la table se remplit d'elle-même.
    final int? combinaison = Autoplay.index(context, 4);
    final bool a = _tenue || combinaison == null ? _a : combinaison < 2;
    final bool b = _tenue || combinaison == null ? _b : combinaison.isEven;
    final AppTokens tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _Interrupteur(
                nom: 'A',
                phrase: 'Le nombre est pair',
                actif: a,
                accent: widget.accent,
                onTap: () => _basculer(true, a, b),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _Interrupteur(
                nom: 'B',
                phrase: 'Le nombre dépasse 10',
                actif: b,
                accent: widget.accent,
                onTap: () => _basculer(false, a, b),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Ligne(nom: 'A et B', vrai: a && b, accent: widget.accent),
        _Ligne(nom: 'A ou B', vrai: a || b, accent: widget.accent),
        _Ligne(nom: 'non A', vrai: !a, accent: widget.accent),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Touche A ou B pour les changer',
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

/// Une affirmation qu'on allume ou qu'on éteint.
class _Interrupteur extends StatelessWidget {
  const _Interrupteur({
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
                  actif
                      ? Icons.check_circle_rounded
                      : Icons.cancel_outlined,
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

/// Résultat d'une opération logique, pour les valeurs courantes de A et B.
class _Ligne extends StatelessWidget {
  const _Ligne({required this.nom, required this.vrai, required this.accent});

  final String nom;
  final bool vrai;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Color couleur = vrai ? tokens.success : tokens.inkSubtle;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 76,
            child: Text(nom, style: context.text.titleSmall),
          ),
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
                  fontWeight: vrai ? FontWeight.w700 : FontWeight.w400,
                ) ??
                const TextStyle(),
            child: Text(vrai ? 'vrai' : 'faux'),
          ),
        ],
      ),
    );
  }
}
