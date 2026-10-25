/// La classification emboîtée : qui partage quoi.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';

/// Un être vivant, et les attributs qu'on lui observe.
class EtreVivant {
  const EtreVivant(this.nom, this.attributs);

  final String nom;

  /// Les attributs observés, parmi ceux de [ClassificationFigure.groupes].
  final Set<String> attributs;
}

/// Des boîtes emboîtées, et les animaux qu'on y range.
///
/// La classification s'enseigne souvent comme une liste de noms de groupes
/// à retenir. Elle repose pourtant sur un seul geste : ranger ensemble ce
/// qui partage un attribut, et constater que les groupes ainsi formés
/// s'emboîtent au lieu de se croiser.
///
/// Ici on touche un animal, et les boîtes auxquelles il appartient
/// s'allument. L'emboîtement devient une observation : tout ce qui a des
/// poils a aussi quatre membres et des vertèbres, jamais l'inverse. On ne
/// classe pas par ce qui manque — un escargot n'est pas « sans vertèbres »,
/// il est simplement en dehors de cette boîte.
class ClassificationFigure extends StatefulWidget {
  const ClassificationFigure({required this.accent, super.key});

  final Color accent;

  /// Les groupes, du plus large au plus étroit.
  ///
  /// L'ordre est celui de l'emboîtement : chaque groupe est inclus dans
  /// celui qui le précède, sauf les deux derniers, qui sont deux branches
  /// parallèles du groupe « quatre membres ».
  static const List<String> groupes = <String>[
    'vertèbres',
    'quatre membres',
    'poils',
    'plumes',
  ];

  /// Le nom affiché pour chaque groupe.
  static const Map<String, String> intitules = <String, String>{
    'vertèbres': 'a des vertèbres',
    'quatre membres': 'a quatre membres',
    'poils': 'a des poils',
    'plumes': 'a des plumes',
  };

  /// Les animaux de la figure, avec leurs attributs observés.
  static const List<EtreVivant> animaux = <EtreVivant>[
    EtreVivant('escargot', <String>{}),
    EtreVivant('truite', <String>{'vertèbres'}),
    EtreVivant('grenouille', <String>{'vertèbres', 'quatre membres'}),
    EtreVivant('lézard', <String>{'vertèbres', 'quatre membres'}),
    EtreVivant('pigeon', <String>{'vertèbres', 'quatre membres', 'plumes'}),
    EtreVivant('chat', <String>{'vertèbres', 'quatre membres', 'poils'}),
    EtreVivant('souris', <String>{'vertèbres', 'quatre membres', 'poils'}),
  ];

  /// Les animaux qui possèdent [attribut].
  static List<EtreVivant> membres(String attribut) => <EtreVivant>[
    for (final EtreVivant e in animaux)
      if (e.attributs.contains(attribut)) e,
  ];

  /// Le groupe le plus étroit auquel [vivant] appartient, ou `null`.
  static String? plusPetitGroupe(EtreVivant vivant) {
    String? trouve;
    for (final String groupe in groupes) {
      if (vivant.attributs.contains(groupe)) trouve = groupe;
    }
    return trouve;
  }

  @override
  State<ClassificationFigure> createState() => _ClassificationFigureState();
}

class _ClassificationFigureState extends State<ClassificationFigure> {
  EtreVivant? _choisi;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  bool _allumeDe(EtreVivant? choisi, String groupe) =>
      choisi != null && choisi.attributs.contains(groupe);

  @override
  Widget build(BuildContext context) {
    // Chaque animal est désigné à son tour : ses attributs s'allument, et
    // les boîtes où il tombe se révèlent de proche en proche. On voit le
    // classement se faire au lieu de le lire.
    final int? lequel = Autoplay.index(
      context,
      ClassificationFigure.animaux.length,
    );
    final EtreVivant? choisi = _tenue || lequel == null
        ? _choisi
        : ClassificationFigure.animaux[lequel];
    final AppTokens tokens = context.tokens;

    // Les trois niveaux emboîtés, le dernier se divisant en deux branches.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Boite(
          titre: ClassificationFigure.intitules['vertèbres']!,
          allume: _allumeDe(choisi, 'vertèbres'),
          accent: widget.accent,
          enfant: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Noms(
                noms: const <String>['truite'],
                choisi: choisi?.nom,
                accent: widget.accent,
              ),
              _Boite(
                titre: ClassificationFigure.intitules['quatre membres']!,
                allume: _allumeDe(choisi, 'quatre membres'),
                accent: widget.accent,
                enfant: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _Noms(
                      noms: const <String>['grenouille', 'lézard'],
                      choisi: choisi?.nom,
                      accent: widget.accent,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: _Boite(
                            titre:
                                ClassificationFigure.intitules['poils']!,
                            allume: _allumeDe(choisi, 'poils'),
                            accent: widget.accent,
                            enfant: _Noms(
                              noms: const <String>['chat', 'souris'],
                              choisi: choisi?.nom,
                              accent: widget.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _Boite(
                            titre:
                                ClassificationFigure.intitules['plumes']!,
                            allume: _allumeDe(choisi, 'plumes'),
                            accent: widget.accent,
                            enfant: _Noms(
                              noms: const <String>['pigeon'],
                              choisi: choisi?.nom,
                              accent: widget.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // L'escargot reste dehors : il n'a aucun des attributs.
        _Noms(
          noms: const <String>['escargot'],
          choisi: choisi?.nom,
          accent: widget.accent,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (final EtreVivant e in ClassificationFigure.animaux)
              ActionChip(
                label: Text(e.nom),
                backgroundColor: e == choisi
                    ? widget.accent.withValues(
                        alpha: context.isDark ? 0.3 : 0.16,
                      )
                    : null,
                onPressed: () {
                  context.tapFeedback();
                  setState(() {
                    _tenue = true;
                    _choisi = e == choisi ? null : e;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 36,
          child: Text(
            _choisi == null
                ? 'Touche un animal pour voir les boîtes auxquelles il appartient.'
                : _choisi!.attributs.isEmpty
                ? 'L’escargot n’a aucun de ces attributs : il reste en dehors.'
                : 'Le ${_choisi!.nom} a : '
                      '${_choisi!.attributs.join(', ')}.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
          ),
        ),
      ],
    );
  }
}

/// Une boîte de classification, avec son intitulé en haut.
class _Boite extends StatelessWidget {
  const _Boite({
    required this.titre,
    required this.allume,
    required this.accent,
    required this.enfant,
  });

  final String titre;
  final bool allume;
  final Color accent;
  final Widget enfant;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return AnimatedContainer(
      duration: context.motionDuration(AppDurations.fast),
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      decoration: BoxDecoration(
        color: allume
            ? accent.withValues(alpha: context.isDark ? 0.18 : 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: allume ? accent : tokens.border,
          width: allume ? 2 : 1.4,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            titre,
            textAlign: TextAlign.center,
            style: context.text.labelSmall?.copyWith(
              color: allume ? accent : tokens.inkMuted,
              fontWeight: allume ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          enfant,
        ],
      ),
    );
  }
}

/// Les noms d'animaux posés dans une boîte.
class _Noms extends StatelessWidget {
  const _Noms({
    required this.noms,
    required this.choisi,
    required this.accent,
  });

  final List<String> noms;
  final String? choisi;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: <Widget>[
        for (final String nom in noms)
          Text(
            nom,
            style: context.text.bodySmall?.copyWith(
              color: nom == choisi ? accent : tokens.inkMuted,
              fontWeight: nom == choisi ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
