/// Une pile et une file côte à côte, nourries des mêmes éléments.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';

/// Les mêmes entrées, deux ordres de sortie.
///
/// Dit avec des mots — « la pile sort le dernier, la file sort le premier » —
/// l'énoncé s'apprend et se confond aussitôt, parce que rien ne distingue
/// les deux phrases à la relecture. Les deux structures ne diffèrent pas par
/// leur contenu mais par une règle, et une règle ne se voit pas dans une
/// définition : elle se voit dans ses conséquences.
///
/// La figure nourrit donc les deux structures des mêmes éléments, en même
/// temps, et les fait sortir côte à côte. L'élève ne lit pas deux
/// définitions, il regarde deux colonnes se vider dans des ordres opposés.
class StackQueueFigure extends StatefulWidget {
  const StackQueueFigure({required this.accent, super.key});

  final Color accent;

  /// Ce qui sort d'une pile dont le contenu est [elements].
  ///
  /// Le dernier entré sort le premier. La fonction est pure et exposée
  /// pour que le test puisse la confronter à une implémentation
  /// indépendante plutôt qu'à elle-même.
  static List<int> sortiePile(List<int> elements) =>
      elements.reversed.toList(growable: false);

  /// Ce qui sort d'une file dont le contenu est [elements].
  static List<int> sortieFile(List<int> elements) =>
      List<int>.of(elements, growable: false);

  /// Les deux structures rendent-elles le même ordre ?
  ///
  /// Vrai seulement pour zéro ou un élément, et pour les contenus
  /// palindromes — un fait que la figure ne dit pas mais que le test
  /// vérifie, pour s'assurer qu'elle ne montre pas deux colonnes
  /// identiques en croyant montrer une différence.
  static bool memeOrdre(List<int> elements) {
    final List<int> p = sortiePile(elements);
    final List<int> f = sortieFile(elements);
    for (int i = 0; i < elements.length; i++) {
      if (p[i] != f[i]) return false;
    }
    return true;
  }

  @override
  State<StackQueueFigure> createState() => _StackQueueFigureState();
}

class _StackQueueFigureState extends State<StackQueueFigure> {
  final List<int> _contenu = <int>[1, 2, 3];
  final List<int> _sortiPile = <int>[];
  final List<int> _sortiFile = <int>[];
  int _prochain = 4;

  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;

  /// La suite d'opérations que l'horloge rejoue.
  ///
  /// Deux ajouts, puis des retraits : c'est la séquence la plus courte qui
  /// fasse voir la différence entre les deux règles de sortie. La pile
  /// rend les derniers entrés, la file rend les premiers, et les deux
  /// colonnes se remplissent dans des ordres inverses.
  static const List<bool> _script = <bool>[
    true, true, false, false, true, false, false, false,
  ];

  /// L'état après [pas] opérations du script, rejoué depuis le départ.
  ///
  /// Une pile n'a pas de valeur de curseur : son état est une histoire.
  /// On la rejoue donc, ce qui reste une fonction pure et tient dans un
  /// `build`.
  ({List<int> contenu, List<int> pile, List<int> file, int prochain}) _rejouer(
    int pas,
  ) {
    final List<int> contenu = <int>[1, 2, 3];
    final List<int> pile = <int>[];
    final List<int> file = <int>[];
    int prochain = 4;
    for (int i = 0; i < pas && i < _script.length; i++) {
      if (_script[i]) {
        contenu.add(prochain);
        prochain++;
      } else if (contenu.isNotEmpty) {
        pile.add(contenu.last);
        file.add(contenu.first);
        contenu.removeLast();
      }
    }
    return (contenu: contenu, pile: pile, file: file, prochain: prochain);
  }

  bool get _vide => _contenu.isEmpty;

  void _ajouter() {
    setState(() {
      _tenue = true;
      _contenu.add(_prochain);
      _prochain++;
    });
  }

  void _retirer() {
    if (_vide) return;
    setState(() {
      // Les deux structures reçoivent le même contenu ; seule la règle de
      // sortie diffère, et c'est ce que la figure a à montrer.
      _tenue = true;
      _sortiPile.add(_contenu.last);
      _sortiFile.add(_contenu.first);
      _contenu.removeLast();
    });
  }

  void _recommencer() {
    setState(() {
      _tenue = true;
      _contenu
        ..clear()
        ..addAll(<int>[1, 2, 3]);
      _sortiPile.clear();
      _sortiFile.clear();
      _prochain = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // La séquence se rejoue : on ajoute, on retire, et les deux colonnes
    // de sortie se remplissent dans l'ordre inverse l'une de l'autre.
    // C'est la seule chose que cette figure a à montrer, et elle la
    // montre sans qu'on appuie.
    final int? pas = Autoplay.index(context, _script.length + 2);
    final bool pilote = !_tenue && pas != null;
    final ({List<int> contenu, List<int> pile, List<int> file, int prochain})
    etat = pilote
        ? _rejouer(pas)
        : (
            contenu: _contenu,
            pile: _sortiPile,
            file: _sortiFile,
            prochain: _prochain,
          );
    final List<int> contenu = etat.contenu;
    final List<int> sortiPile = etat.pile;
    final List<int> sortiFile = etat.file;
    final int prochain = etat.prochain;
    final bool vide = contenu.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _Colonne(
                titre: 'pile (LIFO)',
                sousTitre: 'sort le dernier entré',
                sortis: sortiPile,
                accent: widget.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _Colonne(
                titre: 'file (FIFO)',
                sousTitre: 'sort le premier entré',
                sortis: sortiFile,
                accent: tokens.inkMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          vide
              ? 'Les deux structures sont vides.'
              : 'Contenu commun : ${contenu.join(' · ')}',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 16, color: widget.accent),
        ),
        Text(
          sortiPile.length < 2
              ? 'Retire des éléments pour voir les deux ordres diverger.'
              : 'Les mêmes entrées, deux sorties.',
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
              onPressed: contenu.length >= 7
                  ? null
                  : () {
                      context.tapFeedback();
                      _ajouter();
                    },
              child: Text('ajouter $prochain'),
            ),
            FilledButton.tonal(
              onPressed: vide
                  ? null
                  : () {
                      context.tapFeedback();
                      _retirer();
                    },
              child: const Text('retirer un élément'),
            ),
            if (sortiPile.isNotEmpty || prochain != 4)
              OutlinedButton(
                onPressed: () {
                  context.tapFeedback();
                  _recommencer();
                },
                child: const Text('recommencer'),
              ),
          ],
        ),
      ],
    );
  }
}

/// Une colonne : le nom de la structure et ce qui en est déjà sorti.
class _Colonne extends StatelessWidget {
  const _Colonne({
    required this.titre,
    required this.sousTitre,
    required this.sortis,
    required this.accent,
  });

  final String titre;
  final String sousTitre;
  final List<int> sortis;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          titre,
          textAlign: TextAlign.center,
          style: context.text.labelMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          sousTitre,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 92,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.border),
          ),
          child: sortis.isEmpty
              ? Center(
                  child: Text(
                    'rien encore',
                    style: context.text.bodySmall?.copyWith(
                      color: tokens.inkSubtle,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    for (int i = 0; i < sortis.length; i++)
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          '${sortis[i]}',
                          style: AppTypography.formula(
                            size: 13,
                            color: accent,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
