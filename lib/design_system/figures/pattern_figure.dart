/// Des suites de motifs à continuer.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';

/// Trois régularités, et la case suivante à deviner.
///
/// Une suite de motifs se lit vite et se vérifie seul : l'élève voit cinq
/// éléments, propose le sixième, et la figure dit tout de suite s'il a vu
/// la règle. C'est le même geste que la suite numérique du lycée, mais
/// sans un seul nombre à manipuler.
///
/// Les trois suites sont choisies pour ne pas se continuer de la même
/// manière : l'une alterne, l'autre répète un motif de trois, la dernière
/// grandit. Un élève qui réussit la première en comptant une case sur deux
/// se trompe sur la troisième — et c'est là qu'il cherche la règle plutôt
/// que le rythme.
class PatternFigure extends StatefulWidget {
  const PatternFigure({required this.accent, super.key});

  final Color accent;

  /// La suite dont les éléments grandissent au lieu de se répéter.
  static const int croissante = 2;

  /// Le motif qui se répète, pour les suites périodiques.
  static const List<List<String>> motifs = <List<String>>[
    <String>['rond-rouge', 'rond-bleu'],
    <String>['rond-vert', 'rond-vert', 'carre-orange'],
    <String>[],
  ];

  /// Le nom de chaque suite, tel qu'il s'annonce à l'élève.
  static const List<String> titres = <String>[
    'Un rouge, un bleu',
    'Deux ronds, un carré',
    'Un point de plus',
  ];

  /// L'élément de la suite [suite] à la position [position], comptée à
  /// partir de zéro.
  ///
  /// Les suites périodiques rebouclent sur leur motif ; la suite croissante
  /// rend `points-1`, `points-2`, et ainsi de suite.
  static String element(int suite, int position) {
    if (suite == croissante) return 'points-${position + 1}';
    final List<String> motif = motifs[suite];
    return motif[position % motif.length];
  }

  /// La longueur du motif qui se répète, ou zéro si la suite grandit.
  static int periode(int suite) =>
      suite == croissante ? 0 : motifs[suite].length;

  /// Trois propositions pour la case cachée, dont une seule est juste.
  ///
  /// Les fausses sont choisies pour rester crédibles : les autres motifs de
  /// la même suite, ou, pour la suite croissante, un point de trop et un
  /// point de moins. Un élève qui décale d'un cran se trompe ; celui qui a
  /// vu la règle ne se trompe pas.
  static List<String> propositions(int suite, int position) {
    final List<String> pool = <String>[element(suite, position)];
    if (suite == croissante) {
      pool.add('points-$position');
      pool.add('points-${position + 2}');
    } else {
      for (final String motif in motifs[suite]) {
        if (!pool.contains(motif)) pool.add(motif);
      }
      for (final String autre in <String>[
        'carre-orange',
        'rond-bleu',
        'rond-rouge',
      ]) {
        if (pool.length >= 3) break;
        if (!pool.contains(autre)) pool.add(autre);
      }
    }
    return pool.take(3).toList()..sort();
  }

  @override
  State<PatternFigure> createState() => _PatternFigureState();
}

class _PatternFigureState extends State<PatternFigure> {
  /// Les cinq premières cases sont montrées, la sixième est à trouver.
  static const int montrees = 5;

  int _suite = 0;
  /// Cette figure n'est pas pilotée par l'horloge de la scène, et c'est
  /// délibéré : elle pose une question et attend une réponse. Faire
  /// défiler le motif pendant que l'élève cherche lui retirerait
  /// l'exercice des mains.
  String? _choisi;

  bool get _juste => _choisi == PatternFigure.element(_suite, montrees);

  void _suivante() {
    setState(() {
      _suite = (_suite + 1) % PatternFigure.motifs.length;
      _choisi = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final List<String> choix =
        PatternFigure.propositions(_suite, montrees);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          PatternFigure.titres[_suite],
          style: context.text.labelLarge?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (int i = 0; i < montrees; i++)
              _Case(element: PatternFigure.element(_suite, i)),
            AnimatedSwitcher(
              duration: context.motionDuration(AppDurations.base),
              transitionBuilder: (Widget enfant, Animation<double> t) =>
                  ScaleTransition(scale: t, child: enfant),
              child: _choisi == null
                  ? _Case(
                      key: const ValueKey<String>('cachee'),
                      element: null,
                      accent: widget.accent,
                    )
                  : _Case(
                      key: ValueKey<String>(_choisi!),
                      element: _choisi,
                      accent: _juste ? tokens.success : tokens.error,
                    ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_choisi == null)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Quelle case vient ensuite ?',
                style: context.text.bodyMedium?.copyWith(
                  color: tokens.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (final String element in choix)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          context.tapFeedback();
                          setState(() => _choisi = element);
                        },
                        child: _Case(element: element, proposition: true),
                      ),
                    ),
                ],
              ),
            ],
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _juste
                    ? 'Oui ! La règle se poursuit.'
                    : 'Pas celle-là. Regarde le début de la suite.',
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: _juste ? tokens.success : tokens.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      context.tapFeedback();
                      setState(() => _choisi = null);
                    },
                    child: const Text('Réessayer'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.tonal(
                    onPressed: () {
                      context.tapFeedback();
                      _suivante();
                    },
                    child: const Text('Une autre suite'),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

/// Une case de la suite : un motif, une proposition, ou la case cachée.
class _Case extends StatelessWidget {
  const _Case({
    required this.element,
    this.accent,
    this.proposition = false,
    super.key,
  });

  /// Le motif à dessiner, ou `null` pour la case encore cachée.
  final String? element;
  final Color? accent;
  final bool proposition;

  static const Map<String, Color> _couleurs = <String, Color>{
    'rouge': Color(0xFFE05252),
    'bleu': Color(0xFF3D7BE0),
    'vert': Color(0xFF3FA66A),
    'orange': Color(0xFFE09338),
  };

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Color bordure = accent ?? tokens.border;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(
          color: bordure,
          width: accent != null || proposition ? 2 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: element == null
          ? Text(
              '?',
              style: context.text.titleMedium?.copyWith(
                color: accent ?? tokens.inkMuted,
                fontWeight: FontWeight.w800,
              ),
            )
          : _motif(context, element!),
    );
  }

  Widget _motif(BuildContext context, String code) {
    final List<String> parts = code.split('-');
    if (parts.first == 'points') {
      final int nombre = int.parse(parts[1]);
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 3,
        runSpacing: 3,
        children: <Widget>[
          for (int i = 0; i < nombre; i++)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF6B4FBB),
                shape: BoxShape.circle,
              ),
            ),
        ],
      );
    }
    final Color couleur = _couleurs[parts[1]] ?? context.colors.primary;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: couleur,
        shape: parts.first == 'rond' ? BoxShape.circle : BoxShape.rectangle,
        borderRadius:
            parts.first == 'rond' ? null : BorderRadius.circular(4),
      ),
    );
  }
}
