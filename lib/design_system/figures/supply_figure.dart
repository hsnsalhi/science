/// Le trajet du dioxygène et du glucose, de l'entrée jusqu'à la cellule.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Ce qu'on suit à travers le corps.
enum Cargaison {
  /// Entre par les poumons.
  dioxygene('dioxygène', 'Il entre par les alvéoles.'),

  /// Entre par l'intestin, après digestion.
  glucose('glucose', 'Il entre par les villosités intestinales.');

  const Cargaison(this.nom, this.entree);

  final String nom;
  final String entree;
}

/// Une étape du trajet.
class Etape {
  const Etape(this.lieu, this.detail);

  final String lieu;
  final String detail;
}

/// Le trajet d'une molécule, étape par étape.
///
/// Les trois appareils sont presque toujours enseignés séparément — un
/// chapitre digestion, un chapitre respiration, un chapitre circulation —
/// et l'élève en sort avec trois schémas qui ne se touchent pas. Or le fait
/// qui compte est justement qu'ils se touchent : deux portes et une route,
/// au service d'une seule réaction dans chaque cellule.
///
/// La figure ne montre donc pas trois appareils mais un trajet, qu'on
/// parcourt d'un bout à l'autre. Et elle en montre deux, le dioxygène et le
/// glucose, parce que leur point commun — ils finissent au même endroit,
/// après être entrés par des portes différentes — est l'idée du chapitre.
class SupplyFigure extends StatefulWidget {
  const SupplyFigure({required this.accent, super.key});

  final Color accent;

  /// Le trajet du dioxygène : air, alvéole, sang, cœur, capillaire, cellule.
  static const List<Etape> trajetDioxygene = <Etape>[
    Etape('air inspiré', 'Environ 21 % de dioxygène.'),
    Etape('alvéole', '300 millions de sacs : la surface d\'échange.'),
    Etape('sang', 'Fixé sur l\'hémoglobine des globules rouges.'),
    Etape('cœur gauche', 'Renvoyé vers tout le corps par l\'aorte.'),
    Etape('capillaire', 'Une paroi d\'une cellule : l\'échange a lieu ici.'),
    Etape('cellule', 'Brûle le glucose et libère l\'énergie.'),
  ];

  /// Le trajet du glucose : aliment, digestion, villosité, sang, cellule.
  static const List<Etape> trajetGlucose = <Etape>[
    Etape('aliment', 'L\'amidon est une chaîne de centaines de glucoses.'),
    Etape('digestion', 'Les enzymes coupent la chaîne en glucoses.'),
    Etape('villosité', 'Des millions de replis : la surface d\'échange.'),
    Etape('sang', 'Transporté dissous, vers le foie puis le corps.'),
    Etape('capillaire', 'Une paroi d\'une cellule : l\'échange a lieu ici.'),
    Etape('cellule', 'Brûlé avec le dioxygène, il libère l\'énergie.'),
  ];

  /// Le trajet correspondant à [cargaison].
  static List<Etape> trajet(Cargaison cargaison) =>
      switch (cargaison) {
        Cargaison.dioxygene => trajetDioxygene,
        Cargaison.glucose => trajetGlucose,
      };

  /// Les deux trajets se rejoignent-ils, et où ?
  ///
  /// Renvoie les lieux communs aux deux, dans l'ordre du trajet. Le
  /// chapitre affirme qu'ils finissent au même endroit ; cette fonction
  /// permet de le vérifier plutôt que de le croire.
  static List<String> lieuxCommuns() {
    final Set<String> glucose =
        trajetGlucose.map((Etape e) => e.lieu).toSet();
    return <String>[
      for (final Etape e in trajetDioxygene)
        if (glucose.contains(e.lieu)) e.lieu,
    ];
  }

  @override
  State<SupplyFigure> createState() => _SupplyFigureState();
}

class _SupplyFigureState extends State<SupplyFigure> {
  Cargaison _cargaison = Cargaison.dioxygene;
  int _etape = 0;

  List<Etape> get _trajet => SupplyFigure.trajet(_cargaison);

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Etape courante = _trajet[_etape];
    final bool arrive = _etape == _trajet.length - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          children: Cargaison.values.map((Cargaison c) {
            return ChoiceChip(
              label: Text(c.nom),
              selected: c == _cargaison,
              onSelected: (_) {
                context.tapFeedback();
                setState(() {
                  _cargaison = c;
                  _etape = 0;
                });
              },
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Le trajet en entier, toujours visible : c'est la continuité du
        // parcours que la figure a à montrer, pas l'étape isolée.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < _trajet.length; i++)
              _Rang(
                index: i,
                total: _trajet.length,
                etape: _trajet[i],
                atteinte: i <= _etape,
                courante: i == _etape,
                accent: widget.accent,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          courante.detail,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            FilledButton.tonal(
              onPressed: arrive
                  ? null
                  : () {
                      context.tapFeedback();
                      setState(() => _etape++);
                    },
              child: const Text('étape suivante'),
            ),
            if (_etape > 0)
              OutlinedButton(
                onPressed: () {
                  context.tapFeedback();
                  setState(() => _etape = 0);
                },
                child: const Text('recommencer'),
              ),
          ],
        ),
        if (arrive)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Les deux trajets finissent ici, dans la même cellule.',
              textAlign: TextAlign.center,
              style: AppTypography.formula(size: 14, color: widget.accent),
            ),
          ),
      ],
    );
  }
}

/// Une étape du trajet, allumée ou non.
class _Rang extends StatelessWidget {
  const _Rang({
    required this.index,
    required this.total,
    required this.etape,
    required this.atteinte,
    required this.courante,
    required this.accent,
  });

  final int index;
  final int total;
  final Etape etape;
  final bool atteinte;
  final bool courante;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Color couleur = atteinte ? accent : tokens.inkSubtle;
    return Row(
      children: <Widget>[
        // La pastille et le segment qui la relie à la suivante : le
        // segment est ce qui dit « c'est un trajet » et non une liste.
        SizedBox(
          width: 22,
          child: Column(
            children: <Widget>[
              Container(
                width: courante ? 13 : 9,
                height: courante ? 13 : 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: atteinte ? accent : tokens.border,
                ),
              ),
              if (index < total - 1)
                Container(
                  width: 2,
                  height: 12,
                  color: atteinte ? accent.withValues(alpha: 0.5)
                      : tokens.border,
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              etape.lieu,
              style: context.text.bodySmall?.copyWith(
                color: couleur,
                fontWeight: courante ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
