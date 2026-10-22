/// Un solide en perspective cavalière, qu'on choisit et qu'on incline.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Un solide usuel, avec ses sommets et ses arêtes.
///
/// Les sommets sont donnés en coordonnées de l'espace, dans un cube unité :
/// x vers la droite, y vers le haut, z vers le fond. La projection s'en
/// charge ensuite.
enum SolideUsuel {
  /// Le cube : six faces carrées.
  cube('Cube', 6, 12, 8),

  /// Le pavé droit : même famille que le cube, proportions libres.
  pave('Pavé droit', 6, 12, 8),

  /// La pyramide à base carrée.
  pyramide('Pyramide', 5, 8, 5),

  /// Le prisme droit à base triangulaire.
  prisme('Prisme', 5, 9, 6);

  const SolideUsuel(this.nom, this.faces, this.aretes, this.sommets);

  /// Le nom affiché sur le bouton.
  final String nom;

  /// Nombre de faces.
  final int faces;

  /// Nombre d'arêtes.
  final int aretes;

  /// Nombre de sommets.
  final int sommets;

  /// La relation d'Euler : faces moins arêtes plus sommets.
  ///
  /// Elle vaut 2 pour tout solide convexe, et c'est le genre de résultat
  /// qu'un élève croit sur parole jusqu'à ce qu'il le vérifie lui-même sur
  /// quatre solides différents.
  int get euler => faces - aretes + sommets;

  /// Les sommets, en coordonnées de l'espace.
  List<(double, double, double)> get points => switch (this) {
        SolideUsuel.cube => const <(double, double, double)>[
            (0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0),
            (0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1),
          ],
        SolideUsuel.pave => const <(double, double, double)>[
            (0, 0, 0), (1.6, 0, 0), (1.6, 0.7, 0), (0, 0.7, 0),
            (0, 0, 1), (1.6, 0, 1), (1.6, 0.7, 1), (0, 0.7, 1),
          ],
        SolideUsuel.pyramide => const <(double, double, double)>[
            (0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1),
            (0.5, 1.1, 0.5),
          ],
        SolideUsuel.prisme => const <(double, double, double)>[
            (0, 0, 0), (1, 0, 0), (0.5, 1, 0),
            (0, 0, 1), (1, 0, 1), (0.5, 1, 1),
          ],
      };

  /// Les arêtes, par indices de sommets.
  List<(int, int)> get segments => switch (this) {
        SolideUsuel.cube || SolideUsuel.pave => const <(int, int)>[
            (0, 1), (1, 2), (2, 3), (3, 0),
            (4, 5), (5, 6), (6, 7), (7, 4),
            (0, 4), (1, 5), (2, 6), (3, 7),
          ],
        SolideUsuel.pyramide => const <(int, int)>[
            (0, 1), (1, 2), (2, 3), (3, 0),
            (0, 4), (1, 4), (2, 4), (3, 4),
          ],
        SolideUsuel.prisme => const <(int, int)>[
            (0, 1), (1, 2), (2, 0),
            (3, 4), (4, 5), (5, 3),
            (0, 3), (1, 4), (2, 5),
          ],
      };

  /// Les arêtes cachées, par indices dans [segments].
  ///
  /// Dans une perspective cavalière vue de face et d'en haut à droite, ce
  /// sont celles qui passent derrière le solide. On les désigne plutôt que
  /// de les calculer : à quatre solides fixes, un calcul de faces visibles
  /// coûterait plus qu'il ne rapporte.
  List<int> get cachees => switch (this) {
        SolideUsuel.cube || SolideUsuel.pave => const <int>[4, 7, 8],
        SolideUsuel.pyramide => const <int>[2, 3, 4],
        SolideUsuel.prisme => const <int>[3, 5, 6],
      };
}

/// Un solide dessiné en perspective cavalière, réglable par l'élève.
///
/// La perspective cavalière n'est pas un dessin ressemblant : c'est une
/// convention. La face avant est en vraie grandeur, et la profondeur part
/// en oblique selon un angle et un coefficient qu'on choisit. Tant qu'on
/// ne les a pas fait varier soi-même, on croit que le dessin est imposé —
/// alors que deux élèves obéissant à la même consigne peuvent produire
/// deux dessins très différents, tous les deux justes.
///
/// Le second usage de la figure est le comptage. Faces, arêtes et sommets
/// s'affichent, et avec eux la relation d'Euler, qui vaut 2 sur les quatre
/// solides proposés.
class SolidFigure extends StatefulWidget {
  const SolidFigure({required this.accent, super.key});

  /// Couleur d'accent de la matière.
  final Color accent;

  /// Projection cavalière d'un point de l'espace sur le plan du dessin.
  ///
  /// La face avant (z = 0) est en vraie grandeur ; la profondeur s'ajoute
  /// selon `angle`, réduite par `fuite`. C'est la définition même de la
  /// perspective cavalière, et `test/widget/solide_test.dart` vérifie
  /// qu'un point de la face avant n'est jamais déplacé.
  static (double, double) projeter(
    (double, double, double) point, {
    required double angleDegres,
    required double fuite,
  }) {
    final double a = angleDegres * math.pi / 180;
    final (double x, double y, double z) = point;
    return (x + z * fuite * math.cos(a), y + z * fuite * math.sin(a));
  }

  @override
  State<SolidFigure> createState() => _SolidFigureState();
}

class _SolidFigureState extends State<SolidFigure> {
  SolideUsuel _solide = SolideUsuel.cube;
  double _angle = 45;
  double _fuite = 0.5;
  bool _cachees = true;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          children: <Widget>[
            for (final SolideUsuel s in SolideUsuel.values)
              ChoiceChip(
                label: Text(s.nom),
                selected: _solide == s,
                onSelected: (_) {
                  setState(() => _solide = s);
                  context.tapFeedback();
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 182,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return CustomPaint(
                  size: Size(contraintes.maxWidth, 182),
                  painter: _SolidePainter(
                    solide: _solide,
                    angle: _angle,
                    fuite: _fuite,
                    cachees: _cachees,
                    accent: widget.accent,
                    tokens: tokens,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${_solide.faces} faces   ${_solide.aretes} arêtes   '
          '${_solide.sommets} sommets',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 15, color: widget.accent),
        ),
        Text(
          '${_solide.faces} − ${_solide.aretes} + ${_solide.sommets} = '
          '${_solide.euler}',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(
            color: tokens.success,
            fontWeight: FontWeight.w600,
          ),
        ),
        _curseur(context, 'fuyante', _angle, 15, 75, '${_angle.round()}°',
            (double v) => setState(() => _angle = v)),
        _curseur(context, 'réduction', _fuite, 0.25, 1,
            _fuite.toStringAsFixed(2).replaceAll('.', ','),
            (double v) => setState(() => _fuite = v)),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: _cachees,
          title: Text(
            'Montrer les arêtes cachées',
            style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
          ),
          onChanged: (bool v) {
            setState(() => _cachees = v);
            context.tapFeedback();
          },
        ),
      ],
    );
  }

  Widget _curseur(
    BuildContext context,
    String nom,
    double valeur,
    double mini,
    double maxi,
    String affichage,
    ValueChanged<double> quand,
  ) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 66,
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
            min: mini,
            max: maxi,
            onChanged: (double v) {
              quand(v);
              context.tapFeedback();
            },
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            affichage,
            textAlign: TextAlign.right,
            style: AppTypography.formula(size: 13, color: widget.accent),
          ),
        ),
      ],
    );
  }
}

/// Le solide, ses arêtes vues et ses arêtes cachées.
class _SolidePainter extends CustomPainter {
  const _SolidePainter({
    required this.solide,
    required this.angle,
    required this.fuite,
    required this.cachees,
    required this.accent,
    required this.tokens,
  });

  final SolideUsuel solide;
  final double angle;
  final double fuite;
  final bool cachees;
  final Color accent;
  final AppTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tokens.surfaceAlt);

    final List<(double, double)> plats = <(double, double)>[
      for (final (double, double, double) p in solide.points)
        SolidFigure.projeter(p, angleDegres: angle, fuite: fuite),
    ];

    // On cadre sur l'étendue réelle du dessin : changer la fuyante déplace
    // le solide, et un cadrage fixe le ferait sortir de la boîte.
    double minX = plats.first.$1, maxX = plats.first.$1;
    double minY = plats.first.$2, maxY = plats.first.$2;
    for (final (double x, double y) in plats) {
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }
    final double echelle = math.min(
      (size.width - 48) / math.max(maxX - minX, 0.001),
      (size.height - 36) / math.max(maxY - minY, 0.001),
    );
    final double decaleX = (size.width - (maxX - minX) * echelle) / 2;
    final double decaleY = (size.height - (maxY - minY) * echelle) / 2;

    Offset versEcran((double, double) p) => Offset(
          decaleX + (p.$1 - minX) * echelle,
          // L'axe des y de l'espace monte, celui de l'écran descend.
          size.height - decaleY - (p.$2 - minY) * echelle,
        );

    final Paint vue = Paint()
      ..color = accent
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < solide.segments.length; i++) {
      final (int a, int b) = solide.segments[i];
      final Offset pa = versEcran(plats[a]);
      final Offset pb = versEcran(plats[b]);
      if (solide.cachees.contains(i)) {
        if (!cachees) continue;
        // Une arête cachée se dessine en pointillé : c'est la convention
        // du dessin technique, et elle dit « elle est là, derrière ».
        _pointille(canvas, pa, pb, tokens.inkSubtle.withValues(alpha: 0.8));
      } else {
        canvas.drawLine(pa, pb, vue);
      }
    }

    for (int i = 0; i < plats.length; i++) {
      canvas.drawCircle(versEcran(plats[i]), 3.2, Paint()..color = accent);
    }

    _etiquette(canvas, 'face avant en vraie grandeur',
        Offset(10, size.height - 18), tokens.inkSubtle);
  }

  void _pointille(Canvas canvas, Offset a, Offset b, Color couleur) {
    const double trait = 6;
    const double vide = 4;
    final double longueur = (b - a).distance;
    final Offset sens = (b - a) / longueur;
    final Paint p = Paint()
      ..color = couleur
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    double parcouru = 0;
    while (parcouru < longueur) {
      final double fin = math.min(parcouru + trait, longueur);
      canvas.drawLine(a + sens * parcouru, a + sens * fin, p);
      parcouru = fin + vide;
    }
  }

  void _etiquette(Canvas canvas, String texte, Offset ou, Color couleur) {
    TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontFamilyFallback: AppTypography.replis,
          color: couleur,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, ou);
  }

  @override
  bool shouldRepaint(_SolidePainter ancien) =>
      ancien.solide != solide ||
      ancien.angle != angle ||
      ancien.fuite != fuite ||
      ancien.cachees != cachees ||
      ancien.accent != accent ||
      ancien.tokens != tokens;
}
