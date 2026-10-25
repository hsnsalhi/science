/// Croisement génétique : deux parents, quatre descendants possibles.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';

/// Un croisement de pois, à composer soi-même.
///
/// L'exemple est celui de Mendel : la couleur des graines de pois est
/// portée par un seul gène, à deux versions — jaune domine vert. On
/// évite ainsi d'enseigner, sous prétexte de simplicité, une génétique
/// humaine fausse : la couleur des yeux dépend de nombreux gènes, et
/// servir ce raccourci serait installer une erreur durable.
///
/// On compose les deux parents, et les quatre combinaisons possibles
/// apparaissent. L'intérêt tient à ce qu'on peut échouer à produire du
/// vert : deux parents jaunes peuvent en donner, ou pas, selon ce qu'ils
/// portent — et cela ne se devine qu'en essayant.
class CrossFigure extends StatefulWidget {
  const CrossFigure({required this.accent, super.key});

  final Color accent;

  /// Un pois est jaune dès qu'il porte au moins un allèle dominant.
  ///
  /// Publique parce que le contenu du chapitre annonce des proportions —
  /// trois jaunes sur quatre, la moitié de vertes — que les tests
  /// recalculent avec cette règle. Figure et corrigés disent ainsi la
  /// même chose par construction.
  static bool estJaune(List<bool> alleles) => alleles.any((bool a) => a);

  @override
  State<CrossFigure> createState() => _CrossFigureState();
}

class _CrossFigureState extends State<CrossFigure> {
  /// Allèles de chaque parent. `true` pour la version dominante J.
  List<bool> _pere = <bool>[true, false];
  List<bool> _mere = <bool>[true, false];
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;

  static const Color _jaune = Color(0xFFE3B505);
  static const Color _vert = Color(0xFF3F9142);

  void _basculer(bool pere, int index) {
    context.tapFeedback();
    setState(() {
      _tenue = true;
      final List<bool> cible = pere ? _pere : _mere;
      final List<bool> suivant = List<bool>.of(cible);
      suivant[index] = !suivant[index];
      if (pere) {
        _pere = suivant;
      } else {
        _mere = suivant;
      }
    });
  }

  /// Les quatre descendants possibles, chacun avec ses deux allèles.
  List<List<bool>> _descendantsDe(List<bool> pere, List<bool> mere) =>
      <List<bool>>[
        for (final bool p in pere)
          for (final bool m in mere) <bool>[p, m],
      ];

  /// Les quatre croisements classiques, dans l'ordre où on les enseigne.
  ///
  /// Hétérozygote par hétérozygote donne le trois pour un ; les trois
  /// autres cas montrent ce qui arrive quand un parent est homozygote.
  static const List<(List<bool>, List<bool>)> _croisements =
      <(List<bool>, List<bool>)>[
        (<bool>[true, false], <bool>[true, false]),
        (<bool>[true, true], <bool>[false, false]),
        (<bool>[true, false], <bool>[false, false]),
        (<bool>[true, true], <bool>[true, false]),
      ];

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // Les quatre croisements classiques se succèdent : le trois pour un
    // apparaît, puis disparaît quand un parent devient homozygote. C'est
    // la comparaison qui enseigne, et elle se fait d'elle-même.
    final int? lequel = Autoplay.index(context, _croisements.length);
    final List<bool> pere = _tenue || lequel == null
        ? _pere
        : _croisements[lequel].$1;
    final List<bool> mere = _tenue || lequel == null
        ? _mere
        : _croisements[lequel].$2;
    final List<List<bool>> enfants = _descendantsDe(pere, mere);
    final int jaunes = enfants.where(CrossFigure.estJaune).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Parent(
          titre: 'Parent 1',
          alleles: pere,
          accent: widget.accent,
          onBascule: (int i) => _basculer(true, i),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Parent(
          titre: 'Parent 2',
          alleles: mere,
          accent: widget.accent,
          onBascule: (int i) => _basculer(false, i),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Les quatre graines possibles',
          style: context.text.labelMedium?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (final List<bool> enfant in enfants)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                ),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: CrossFigure.estJaune(enfant) ? _jaune : _vert,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      enfant.map((bool a) => a ? 'J' : 'v').join(),
                      style: context.text.labelMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          jaunes == 4
              ? 'Les quatre sont jaunes'
              : '$jaunes jaune${jaunes > 1 ? 's' : ''} '
                    'sur 4, ${4 - jaunes} vert${4 - jaunes > 1 ? 's' : ''}',
          style: context.text.titleSmall?.copyWith(color: widget.accent),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'J domine v : une graine est verte seulement si elle porte vv',
          textAlign: TextAlign.center,
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

/// Les deux allèles d'un parent, qu'on bascule du doigt.
class _Parent extends StatelessWidget {
  const _Parent({
    required this.titre,
    required this.alleles,
    required this.accent,
    required this.onBascule,
  });

  final String titre;
  final List<bool> alleles;
  final Color accent;
  final void Function(int index) onBascule;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 86,
          child: Text(titre, style: context.text.labelMedium),
        ),
        for (int i = 0; i < alleles.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => onBascule(i),
              child: AnimatedContainer(
                duration: context.motionDuration(AppDurations.fast),
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: alleles[i]
                      ? accent.withValues(alpha: context.isDark ? 0.26 : 0.14)
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: alleles[i] ? accent : context.tokens.border,
                    width: alleles[i] ? 2 : 1.5,
                  ),
                ),
                child: Text(
                  alleles[i] ? 'J' : 'v',
                  style: context.text.titleMedium?.copyWith(
                    color: alleles[i] ? accent : context.tokens.inkMuted,
                  ),
                ),
              ),
            ),
          ),
        Flexible(
          child: Text(
            'touche pour changer',
            style: context.text.labelSmall?.copyWith(
              color: context.tokens.inkSubtle,
            ),
          ),
        ),
      ],
    );
  }
}
