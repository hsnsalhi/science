/// La chaîne d'énergie, et ce qu'elle perd à chaque étage.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';

/// Quatre étages de conversion, et le rendement qui en sort.
///
/// Le rendement global d'une chaîne se calcule en multipliant ceux des
/// étages, et cette multiplication est contre-intuitive : quatre étages
/// très honnêtes à 80 % ne laissent passer que 41 % de l'énergie. Écrit,
/// le résultat se croit mal. Réglé étage par étage, il se constate.
///
/// La barre rétrécit à chaque étage, et ce qui manque est l'énergie
/// perdue. On voit alors qu'améliorer le meilleur étage ne sert presque à
/// rien, et que le pire commande tout le reste.
class EnergyChainFigure extends StatefulWidget {
  const EnergyChainFigure({required this.accent, super.key});

  final Color accent;

  /// Les étages de la chaîne, dans l'ordre.
  static const List<String> etages = <String>[
    'Alimenter',
    'Distribuer',
    'Convertir',
    'Transmettre',
  ];

  /// Rendements de départ, en pour-cent.
  static const List<double> rendementsInitiaux = <double>[90, 95, 40, 85];

  /// Le rendement global d'une chaîne, en pour-cent.
  ///
  /// Les rendements se multiplient : chaque étage ne transmet qu'une
  /// fraction de ce qu'il reçoit, et non de ce qui est entré au départ.
  static double rendementGlobal(List<double> rendements) {
    double part = 1;
    for (final double r in rendements) {
      part *= r / 100;
    }
    return part * 100;
  }

  /// L'énergie encore disponible après [etage] étages, en pour-cent.
  static double apres(List<double> rendements, int etage) =>
      rendementGlobal(rendements.take(etage).toList());

  @override
  State<EnergyChainFigure> createState() => _EnergyChainFigureState();
}

class _EnergyChainFigureState extends State<EnergyChainFigure> {
  List<double> _rendements = List<double>.of(
    EnergyChainFigure.rendementsInitiaux,
  );

  int _choisi = 2;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // Chaque étage est désigné à son tour, et son rendement balaie : le
    // produit global s'effondre dès qu'un seul étage faiblit, et c'est la
    // leçon de la chaîne — le maillon faible décide du tout.
    final int? lequel = Autoplay.index(context, EnergyChainFigure.etages.length);
    final int choisi = _tenue || lequel == null ? _choisi : lequel;
    final double? pilote = Autoplay.sweepPas(
      context,
      min: 20,
      max: 95,
      pas: 5,
      cycles: EnergyChainFigure.etages.length,
    );
    final List<double> rendements = _tenue || pilote == null
        ? _rendements
        : (List<double>.of(_rendements)..[choisi] = pilote);
    final double global = EnergyChainFigure.rendementGlobal(rendements);
    final double pire = rendements.reduce((double a, double b) =>
        a < b ? a : b);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < EnergyChainFigure.etages.length; i++)
          _Etage(
            nom: EnergyChainFigure.etages[i],
            rendement: rendements[i],
            restant: EnergyChainFigure.apres(rendements, i + 1),
            avant: EnergyChainFigure.apres(rendements, i),
            accent: widget.accent,
            choisi: i == choisi,
            leMoinsBon: rendements[i] == pire,
            onTap: () {
              context.tapFeedback();
              setState(() {
                _tenue = true;
                _rendements = rendements;
                _choisi = i;
              });
            },
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Rendement global : ${global.round()} %',
          style: AppTypography.formula(size: 17, color: widget.accent),
        ),
        Text(
          'Sur 100 entrés, il en sort ${global.round()}. '
          'Le reste part en chaleur.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            SizedBox(
              width: 86,
              child: Text(
                EnergyChainFigure.etages[choisi],
                style: context.text.labelMedium?.copyWith(
                  color: widget.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: rendements[choisi],
                min: 10,
                max: 100,
                divisions: 18,
                onChanged: (double v) {
                  context.tapFeedback();
                  setState(() {
                    _tenue = true;
                    _choisi = choisi;
                    _rendements = List<double>.of(rendements)
                      ..[choisi] = (v / 5).roundToDouble() * 5;
                  });
                },
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${rendements[choisi].round()} %',
                textAlign: TextAlign.right,
                style: AppTypography.formula(
                  size: 14,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Un étage de la chaîne : son nom, son rendement, et ce qui en ressort.
class _Etage extends StatelessWidget {
  const _Etage({
    required this.nom,
    required this.rendement,
    required this.restant,
    required this.avant,
    required this.accent,
    required this.choisi,
    required this.leMoinsBon,
    required this.onTap,
  });

  final String nom;
  final double rendement;
  final double restant;
  final double avant;
  final Color accent;
  final bool choisi;
  final bool leMoinsBon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 86,
              child: Text(
                nom,
                style: context.text.labelMedium?.copyWith(
                  color: choisi ? accent : tokens.inkMuted,
                  fontWeight: choisi ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints contraintes) {
                  final double large = contraintes.maxWidth;
                  return SizedBox(
                    height: 22,
                    child: Stack(
                      children: <Widget>[
                        // Ce qui entrait dans l'étage, en clair.
                        Container(
                          width: large * avant / 100,
                          decoration: BoxDecoration(
                            color: tokens.border,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        // Ce qui en ressort, en plein.
                        AnimatedContainer(
                          duration: context.motionDuration(AppDurations.fast),
                          width: large * restant / 100,
                          decoration: BoxDecoration(
                            color: leMoinsBon
                                ? tokens.warning
                                : accent.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${rendement.round()} %',
                textAlign: TextAlign.right,
                style: AppTypography.formula(
                  size: 13,
                  color: leMoinsBon ? tokens.warning : tokens.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
