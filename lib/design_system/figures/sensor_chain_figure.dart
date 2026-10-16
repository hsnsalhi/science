/// La chaîne d'information : capteur, traitement, actionneur.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Un thermostat complet, du capteur au radiateur.
///
/// « Capteur, traitement, actionneur » est une liste de trois mots qu'on
/// retient sans la comprendre. Ici les trois sont reliés : on règle la
/// température mesurée et le seuil, et l'on voit la décision se prendre
/// et le radiateur s'allumer.
///
/// L'intérêt est de pouvoir faire varier le seuil sans toucher à la
/// température, et l'inverse. La décision dépend des deux, et c'est le
/// programme — pas le capteur — qui la prend.
class SensorChainFigure extends StatefulWidget {
  const SensorChainFigure({required this.accent, super.key});

  final Color accent;

  /// Le chauffage se déclenche-t-il ?
  ///
  /// La condition est stricte : à température égale au seuil, le
  /// radiateur reste éteint. C'est un choix de programmation, et c'est
  /// exactement le genre de détail qu'un cas limite révèle.
  static bool chauffe(double mesure, double seuil) => mesure < seuil;

  @override
  State<SensorChainFigure> createState() => _SensorChainFigureState();
}

class _SensorChainFigureState extends State<SensorChainFigure> {
  double _mesure = 17;
  double _seuil = 19;

  String _n(double v) =>
      NumericQuestion.formatNumber((v * 10).roundToDouble() / 10);

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool chauffe = SensorChainFigure.chauffe(_mesure, _seuil);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // IntrinsicHeight : les trois blocs doivent avoir la même
        // hauteur, et une Row étirée sans hauteur connue en demanderait
        // une infinie.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _Bloc(
                  etiquette: 'capteur',
                  titre: '${_n(_mesure)} °C',
                  detail: 'thermomètre',
                  icone: Icons.thermostat_rounded,
                  actif: true,
                  accent: widget.accent,
                ),
              ),
              _Fleche(accent: widget.accent),
              Expanded(
                child: _Bloc(
                  etiquette: 'traitement',
                  titre: chauffe ? 'vrai' : 'faux',
                  detail: 'si T < ${_n(_seuil)} °C',
                  icone: Icons.account_tree_rounded,
                  actif: chauffe,
                  accent: widget.accent,
                ),
              ),
              _Fleche(accent: widget.accent),
              Expanded(
                child: _Bloc(
                  etiquette: 'actionneur',
                  titre: chauffe ? 'allumé' : 'éteint',
                  detail: 'radiateur',
                  icone: Icons.local_fire_department_rounded,
                  actif: chauffe,
                  accent: widget.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          chauffe
              ? 'Il fait moins de ${_n(_seuil)} °C : le programme allume le '
                    'radiateur.'
              : 'Il fait au moins ${_n(_seuil)} °C : le programme le laisse '
                    'éteint.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        _Reglage(
          nom: 'température',
          valeur: _mesure,
          affichage: '${_n(_mesure)} °C',
          accent: widget.accent,
          onChanged: (double v) => setState(() => _mesure = v),
        ),
        _Reglage(
          nom: 'seuil',
          valeur: _seuil,
          affichage: '${_n(_seuil)} °C',
          accent: widget.accent,
          onChanged: (double v) => setState(() => _seuil = v),
        ),
      ],
    );
  }
}

class _Fleche extends StatelessWidget {
  const _Fleche({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    child: Center(
      child: Icon(Icons.arrow_forward_rounded, size: 18, color: accent),
    ),
  );
}

class _Bloc extends StatelessWidget {
  const _Bloc({
    required this.etiquette,
    required this.titre,
    required this.detail,
    required this.icone,
    required this.actif,
    required this.accent,
  });

  final String etiquette;
  final String titre;
  final String detail;
  final IconData icone;
  final bool actif;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
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
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            etiquette,
            style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
          ),
          const SizedBox(height: AppSpacing.xs),
          Icon(icone, size: 24, color: actif ? accent : tokens.inkSubtle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: AppTypography.formula(
              size: 15,
              color: actif ? accent : tokens.inkMuted,
            ),
          ),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
          ),
        ],
      ),
    );
  }
}

class _Reglage extends StatelessWidget {
  const _Reglage({
    required this.nom,
    required this.valeur,
    required this.affichage,
    required this.accent,
    required this.onChanged,
  });

  final String nom;
  final double valeur;
  final String affichage;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 92,
          child: Text(
            nom,
            style: context.text.labelSmall?.copyWith(
              color: context.tokens.inkSubtle,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: valeur,
            min: 10,
            max: 28,
            divisions: 36,
            onChanged: (double v) {
              context.tapFeedback();
              onChanged(v);
            },
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            affichage,
            textAlign: TextAlign.right,
            style: AppTypography.formula(size: 14, color: accent),
          ),
        ),
      ],
    );
  }
}
