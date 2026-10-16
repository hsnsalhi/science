/// Une cellule à explorer, animale ou végétale.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Un constituant de la cellule, avec son rôle et sa place.
class Organite {
  const Organite({
    required this.nom,
    required this.role,
    required this.position,
    required this.taille,
    required this.vegetaleSeulement,
    this.rectangulaire = false,
  });

  final String nom;
  final String role;

  /// Centre, en coordonnées relatives à la cellule.
  final Offset position;

  /// Demi-dimensions, relatives elles aussi.
  final Size taille;

  /// `true` si cet élément n'existe que dans les cellules végétales.
  final bool vegetaleSeulement;

  /// Dessiné en rectangle arrondi plutôt qu'en ovale.
  final bool rectangulaire;
}

/// Une cellule qu'on explore du doigt, et qui change de type.
///
/// Un schéma de cellule légendé est illisible : six flèches, six noms,
/// et rien qui dise à quoi chaque partie sert. Ici on touche une partie
/// et on lit son rôle, une seule à la fois.
///
/// Le basculement animale / végétale est le second ressort : ce ne sont
/// pas deux schémas à mémoriser séparément, mais le même auquel on
/// ajoute trois éléments. Ce que les plantes ont en plus — la paroi, les
/// chloroplastes, la grande vacuole — est exactement ce qui explique
/// qu'elles tiennent debout et se nourrissent de lumière.
class CellFigure extends StatefulWidget {
  const CellFigure({required this.accent, super.key});

  final Color accent;

  /// Tous les constituants, végétaux compris.
  ///
  /// L'ordre est celui du dessin : les enveloppes d'abord, puis ce
  /// qu'elles contiennent. Les tailles sont des demi-dimensions,
  /// relatives au cadre, et choisies pour qu'aucun organite n'en
  /// recouvre un autre — un schéma où les pièces se chevauchent ne se
  /// lit pas.
  static const List<Organite> tous = <Organite>[
    Organite(
      nom: 'Paroi',
      role: 'Enveloppe rigide, en cellulose : c\'est elle qui fait tenir '
          'la plante debout.',
      position: Offset(0.5, 0.5),
      taille: Size(0.44, 0.42),
      vegetaleSeulement: true,
      rectangulaire: true,
    ),
    Organite(
      nom: 'Membrane',
      role: 'Entoure la cellule et contrôle ce qui entre et sort.',
      position: Offset(0.5, 0.5),
      taille: Size(0.40, 0.38),
      vegetaleSeulement: false,
    ),
    Organite(
      nom: 'Noyau',
      role: 'Contient l\'ADN : le programme de la cellule.',
      position: Offset(0.32, 0.36),
      taille: Size(0.085, 0.10),
      vegetaleSeulement: false,
    ),
    Organite(
      nom: 'Vacuole',
      role: 'Grande poche d\'eau qui gonfle la cellule et la maintient '
          'ferme.',
      position: Offset(0.63, 0.52),
      taille: Size(0.11, 0.12),
      vegetaleSeulement: true,
    ),
    Organite(
      nom: 'Mitochondrie',
      role: 'Libère l\'énergie des aliments. On en trouve dans toutes '
          'les cellules, animales comme végétales.',
      position: Offset(0.70, 0.28),
      taille: Size(0.065, 0.035),
      vegetaleSeulement: false,
    ),
    Organite(
      nom: 'Chloroplaste',
      role: 'Capte la lumière du Soleil pour fabriquer des sucres. '
          'C\'est lui qui rend les feuilles vertes.',
      position: Offset(0.31, 0.64),
      taille: Size(0.06, 0.035),
      vegetaleSeulement: true,
    ),
    Organite(
      nom: 'Cytoplasme',
      role: 'Le liquide où baignent tous les autres éléments.',
      position: Offset(0.53, 0.76),
      taille: Size(0.05, 0.045),
      vegetaleSeulement: false,
    ),
  ];

  /// Les constituants présents dans le type de cellule demandé.
  static List<Organite> organites({required bool vegetale}) =>
      tous.where((Organite o) => vegetale || !o.vegetaleSeulement).toList();

  /// Les constituants propres aux cellules végétales.
  static List<Organite> get propresAuxVegetaux =>
      tous.where((Organite o) => o.vegetaleSeulement).toList();

  @override
  State<CellFigure> createState() => _CellFigureState();
}

class _CellFigureState extends State<CellFigure> {
  bool _vegetale = false;
  String? _choisi;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final List<Organite> presents = CellFigure.organites(vegetale: _vegetale);
    final Organite? choisi = presents
        .where((Organite o) => o.nom == _choisi)
        .firstOrNull;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.25,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints contraintes) {
              final Size taille = contraintes.biggest;
              return Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CellulePainter(
                        organites: presents,
                        choisi: _choisi,
                        vegetale: _vegetale,
                        accent: widget.accent,
                        trait: tokens.border,
                        muted: tokens.inkMuted,
                        surface: context.colors.surface,
                      ),
                    ),
                  ),
                  // Les zones touchables sont posées par-dessus le
                  // dessin, dans l'ordre du dessin : les enveloppes
                  // d'abord, donc en dessous. Empilées à l'envers, la
                  // paroi recouvrait toute la cellule et interceptait
                  // les touches destinées aux organites.
                  for (final Organite o in presents)
                    Positioned(
                      left: (o.position.dx - o.taille.width) * taille.width,
                      top: (o.position.dy - o.taille.height) * taille.height,
                      width: o.taille.width * 2 * taille.width,
                      height: o.taille.height * 2 * taille.height,
                      child: GestureDetector(
                        behavior: o.nom == 'Membrane' || o.nom == 'Paroi'
                            ? HitTestBehavior.translucent
                            : HitTestBehavior.opaque,
                        onTap: () {
                          context.tapFeedback();
                          setState(
                            () => _choisi = _choisi == o.nom ? null : o.nom,
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          choisi?.nom ?? 'Touche une partie de la cellule',
          style: AppTypography.formula(size: 17, color: widget.accent),
        ),
        SizedBox(
          height: 54,
          child: Text(
            choisi?.role ??
                'Cellule ${_vegetale ? 'végétale' : 'animale'} : '
                    '${presents.length} constituants.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: () {
            context.tapFeedback();
            setState(() {
              _vegetale = !_vegetale;
              _choisi = null;
            });
          },
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: Text(
            _vegetale ? 'Voir une cellule animale' : 'Voir une cellule végétale',
          ),
        ),
      ],
    );
  }
}

class _CellulePainter extends CustomPainter {
  const _CellulePainter({
    required this.organites,
    required this.choisi,
    required this.vegetale,
    required this.accent,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final List<Organite> organites;
  final String? choisi;
  final bool vegetale;
  final Color accent;
  final Color trait;
  final Color muted;
  final Color surface;

  static const Color _vert = Color(0xFF16A34A);
  static const Color _indigo = Color(0xFF4F46E5);
  static const Color _orange = Color(0xFFEA580C);
  static const Color _bleu = Color(0xFF38BDF8);

  @override
  void paint(Canvas canvas, Size size) {
    for (final Organite o in organites) {
      final Rect boite = Rect.fromCenter(
        center: Offset(
          o.position.dx * size.width,
          o.position.dy * size.height,
        ),
        width: o.taille.width * 2 * size.width,
        height: o.taille.height * 2 * size.height,
      );
      final bool actif = o.nom == choisi;
      // Une couleur par organite : tout peindre à la couleur de la
      // matière rendait le schéma uniformément vert, donc illisible.
      final Color couleur = switch (o.nom) {
        'Chloroplaste' => _vert,
        'Noyau' => _indigo,
        'Mitochondrie' => _orange,
        'Vacuole' => _bleu,
        'Paroi' || 'Membrane' => trait,
        _ => accent,
      };

      final Paint fond = Paint()
        ..color = switch (o.nom) {
          'Membrane' || 'Paroi' => surface,
          'Cytoplasme' => accent.withValues(alpha: actif ? 0.3 : 0.12),
          _ => couleur.withValues(alpha: actif ? 0.85 : 0.5),
        };
      final Paint bord = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = actif ? 3.5 : 2
        ..color = actif ? accent : couleur;

      if (o.rectangulaire) {
        final RRect arrondi =
            RRect.fromRectAndRadius(boite, const Radius.circular(14));
        canvas.drawRRect(arrondi, fond);
        canvas.drawRRect(arrondi, bord);
      } else {
        canvas.drawOval(boite, fond);
        canvas.drawOval(boite, bord);
      }

      // Le nom, posé sous l'élément. Les deux enveloppes font
      // exception : leur centre est occupé, on les nomme sur leur
      // bord supérieur.
      final Offset ancre = switch (o.nom) {
        'Paroi' => Offset(boite.left + 32, boite.top + 11),
        'Membrane' => Offset(boite.center.dx, boite.top + 11),
        _ => Offset(boite.center.dx, boite.bottom + 10),
      };
      _texte(canvas, o.nom, ancre, actif ? accent : muted, gras: actif);
    }
    _texte(
      canvas,
      vegetale ? 'cellule végétale' : 'cellule animale',
      Offset(size.width / 2, 10),
      muted,
    );
  }

  void _texte(
    Canvas canvas,
    String texte,
    Offset centre,
    Color couleur, {
    bool gras = false,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          color: couleur,
          fontSize: 11,
          fontWeight: gras ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      centre - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_CellulePainter old) =>
      old.choisi != choisi ||
      old.vegetale != vegetale ||
      old.accent != accent;
}
