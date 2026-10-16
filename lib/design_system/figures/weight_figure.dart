/// Le même sac sur quatre astres, et la flèche du poids qui change.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'realism.dart';

/// La surface d'un astre, telle qu'elle se présente.
enum Surface {
  /// Grise, criblée de cratères, sans air.
  crateres,

  /// Rouille, avec ses calottes de glace.
  rouille,

  /// Océans, continents, atmosphère.
  oceans,

  /// Bandes nuageuses d'une géante gazeuse.
  nuages,
}

/// Un astre : sa pesanteur et son aspect.
class Astre {
  const Astre({
    required this.nom,
    required this.pesanteur,
    required this.couleur,
    required this.surface,
    required this.graine,
  });

  /// Le nom affiché.
  final String nom;

  /// Intensité de la pesanteur en surface, en newtons par kilogramme.
  final double pesanteur;

  /// Teinte du sol en pleine lumière.
  final Color couleur;

  /// Ce qu'on voit à sa surface.
  final Surface surface;

  /// Graine du relief, pour que l'astre garde toujours le même visage.
  final int graine;
}

/// Un sac posé sur le sol de l'astre choisi, et son poids dessiné.
///
/// Première version, cette figure montrait un carré gris posé sur rien, avec
/// une flèche dessous. Cela suffisait à comparer deux longueurs, mais rien
/// n'y disait qu'on changeait de monde : passer de la Lune à Jupiter
/// n'allongeait qu'un trait. Or ce que l'élève doit retenir est justement
/// qu'on a changé d'astre et pas d'objet.
///
/// Les quatre astres se présentent donc tels qu'ils sont. On voit l'horizon
/// courbe de la Lune et ses cratères, le sol rouille de Mars sous un ciel
/// rose, l'herbe et le ciel bleu de la Terre, les bandes ocre de Jupiter.
/// Le sac, lui, ne change jamais : même taille, même ombre, même contenu.
/// C'est le seul moyen de rendre visible ce qu'une phrase ne fait pas
/// passer — la masse est à l'objet, le poids est au lieu.
class WeightFigure extends StatefulWidget {
  const WeightFigure({required this.accent, super.key});

  final Color accent;

  /// Les quatre astres de la figure, par pesanteur croissante.
  ///
  /// Les valeurs sont celles de la surface, arrondies au dixième : ce sont
  /// celles que le chapitre annonce et que les questions font calculer.
  static const List<Astre> astres = <Astre>[
    Astre(
      nom: 'Lune',
      pesanteur: 1.6,
      couleur: Color(0xFF9A9A96),
      surface: Surface.crateres,
      graine: 7,
    ),
    Astre(
      nom: 'Mars',
      pesanteur: 3.7,
      couleur: Color(0xFFB4552F),
      surface: Surface.rouille,
      graine: 13,
    ),
    Astre(
      nom: 'Terre',
      pesanteur: 9.8,
      couleur: Color(0xFF2E7D4F),
      surface: Surface.oceans,
      graine: 3,
    ),
    Astre(
      nom: 'Jupiter',
      pesanteur: 24.8,
      couleur: Color(0xFFC89766),
      surface: Surface.nuages,
      graine: 11,
    ),
  ];

  /// L'astre de ce nom, ou `null` s'il est inconnu.
  static Astre? astre(String nom) {
    for (final Astre a in astres) {
      if (a.nom == nom) return a;
    }
    return null;
  }

  /// Intensité de la pesanteur par nom d'astre.
  static Map<String, double> get pesanteur => <String, double>{
    for (final Astre a in astres) a.nom: a.pesanteur,
  };

  /// Poids d'une masse sur un astre, en newtons : P = m × g.
  ///
  /// Renvoie `null` si l'astre est inconnu, plutôt que de supposer la Terre :
  /// une faute de frappe doit se voir, pas se corriger toute seule.
  static double? poids(double masseKg, String nom) {
    final Astre? a = astre(nom);
    return a == null ? null : masseKg * a.pesanteur;
  }

  /// Masse correspondant à un poids mesuré sur un astre : m = P ÷ g.
  static double? masse(double poidsN, String nom) {
    final Astre? a = astre(nom);
    return a == null || a.pesanteur == 0 ? null : poidsN / a.pesanteur;
  }

  /// Combien de fois le poids est plus faible sur cet astre que sur Terre.
  static double? facteurFaceALaTerre(String nom) {
    final Astre? a = astre(nom);
    final double terre = astre('Terre')!.pesanteur;
    return a == null || a.pesanteur == 0 ? null : terre / a.pesanteur;
  }

  @override
  State<WeightFigure> createState() => _WeightFigureState();
}

class _WeightFigureState extends State<WeightFigure> {
  double _masse = 4;
  String _nom = 'Terre';

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Astre astre = WeightFigure.astre(_nom)!;
    final double poids = WeightFigure.poids(_masse, _nom)!;
    final double maxPoids = _masse * WeightFigure.astres.last.pesanteur;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 216,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return CustomPaint(
                  size: Size(contraintes.maxWidth, 216),
                  painter: _PoidsPainter(
                    astre: astre,
                    // La flèche est à l'échelle du poids le plus fort
                    // atteignable, pour que passer de la Lune à Jupiter se
                    // voie sans que la figure se redimensionne.
                    fraction: maxPoids == 0 ? 0 : poids / maxPoids,
                    accent: widget.accent,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'P = ${_nombre(_masse)} × ${_nombre(astre.pesanteur)} '
          '= ${_nombre(poids)} N',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          'Le sac contient toujours ${_nombre(_masse)} kg, '
          'sur les quatre astres.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          children: WeightFigure.astres.map((Astre a) {
            return ChoiceChip(
              label: Text(a.nom),
              selected: a.nom == _nom,
              onSelected: (_) {
                context.tapFeedback();
                setState(() => _nom = a.nom);
              },
            );
          }).toList(growable: false),
        ),
        Row(
          children: <Widget>[
            SizedBox(
              width: 54,
              child: Text(
                'masse',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkSubtle,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _masse,
                min: 1,
                max: 20,
                divisions: 19,
                onChanged: (double v) {
                  context.tapFeedback();
                  setState(() => _masse = v.roundToDouble());
                },
              ),
            ),
            SizedBox(
              width: 46,
              child: Text(
                '${_nombre(_masse)} kg',
                textAlign: TextAlign.right,
                style: AppTypography.formula(
                  size: 14,
                  color: widget.accent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Écrit un nombre à la française, sans décimale inutile.
  static String _nombre(double valeur) {
    if (valeur == valeur.roundToDouble()) return valeur.round().toString();
    return valeur.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class _PoidsPainter extends CustomPainter {
  const _PoidsPainter({
    required this.astre,
    required this.fraction,
    required this.accent,
  });

  final Astre astre;
  final double fraction;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    _ciel(canvas, size);
    final double hauteurSol = _sol(canvas, size);
    _sac(canvas, size, hauteurSol);
    _fleche(canvas, size, hauteurSol);
  }

  /// Le ciel de l'astre : noir et étoilé sans air, coloré avec.
  void _ciel(Canvas canvas, Size size) {
    final Rect cadre = Offset.zero & size;
    final (Color haut, Color bas) = switch (astre.surface) {
      // Sans atmosphère, le ciel est noir en plein jour. C'est l'un des
      // faits les plus contre-intuitifs de la Lune, et il se montre ici
      // sans un mot.
      Surface.crateres => (const Color(0xFF05060B), const Color(0xFF14161F)),
      // Mars a une atmosphère ténue et poussiéreuse : ciel beige rosé.
      Surface.rouille => (const Color(0xFF6E4A3A), const Color(0xFFC79070)),
      Surface.oceans => (const Color(0xFF4A90D9), const Color(0xFFBBDCF5)),
      // Jupiter n'a pas de sol ; on se place au-dessus des nuages.
      Surface.nuages => (const Color(0xFF6B4B2E), const Color(0xFFD6B089)),
    };
    canvas.drawRect(
      cadre,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[haut, bas],
        ).createShader(cadre),
    );

    if (astre.surface != Surface.crateres) return;
    // Des étoiles, uniquement là où le ciel est noir. Positions figées :
    // un ciel qui scintille au hasard rendrait les captures instables.
    final math.Random alea = math.Random(astre.graine);
    for (int i = 0; i < 40; i++) {
      final Offset point = Offset(
        alea.nextDouble() * size.width,
        alea.nextDouble() * size.height * 0.62,
      );
      canvas.drawCircle(
        point,
        alea.nextDouble() * 1.1 + 0.4,
        Paint()
          ..color = Colors.white.withValues(
            alpha: 0.35 + alea.nextDouble() * 0.5,
          ),
      );
    }
  }

  /// Le sol, courbe comme celui d'un astre. Rend la hauteur de l'horizon.
  double _sol(Canvas canvas, Size size) {
    final double hauteur = size.height * 0.47;
    // Un horizon bombé : sur un petit astre la courbure se voit, et c'est
    // une information. Un trait droit dirait « plancher », pas « planète ».
    final double fleche = switch (astre.surface) {
      Surface.crateres => 26,
      Surface.rouille => 18,
      Surface.oceans => 10,
      Surface.nuages => 6,
    };
    final Path sol = Path()
      ..moveTo(-10, hauteur + fleche)
      ..quadraticBezierTo(
        size.width / 2,
        hauteur - fleche,
        size.width + 10,
        hauteur + fleche,
      )
      ..lineTo(size.width + 10, size.height + 10)
      ..lineTo(-10, size.height + 10)
      ..close();

    final Rect cadreSol = Rect.fromLTWH(
      0,
      hauteur - fleche,
      size.width,
      size.height - hauteur + fleche,
    );
    canvas.save();
    canvas.clipPath(sol);
    canvas.drawRect(cadreSol, Realisme.chair(cadreSol, astre.couleur));

    switch (astre.surface) {
      case Surface.crateres:
        // Des cratères en perspective, aplatis car vus de rase-mottes.
        final math.Random alea = math.Random(astre.graine);
        for (int i = 0; i < 16; i++) {
          final double y = hauteur + alea.nextDouble() * (size.height - hauteur);
          final double proche = (y - hauteur) / (size.height - hauteur);
          final double largeur = 12 + proche * 46;
          final Offset centre = Offset(alea.nextDouble() * size.width, y);
          final Rect cuvette = Rect.fromCenter(
            center: centre,
            width: largeur,
            height: largeur * 0.3,
          );
          canvas.drawOval(
            cuvette,
            Paint()..color = Colors.black.withValues(alpha: 0.18),
          );
          canvas.drawArc(
            cuvette.shift(const Offset(0, -1.5)),
            math.pi,
            math.pi,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = Colors.white.withValues(alpha: 0.16),
          );
        }
      case Surface.rouille:
        // Des rochers épars, et de la poussière plus claire au loin.
        final math.Random alea = math.Random(astre.graine);
        for (int i = 0; i < 14; i++) {
          final double y = hauteur + alea.nextDouble() * (size.height - hauteur);
          final double taille = 4 + alea.nextDouble() * 11;
          canvas.drawPath(
            Realisme.paroiOrganique(
              Rect.fromCenter(
                center: Offset(alea.nextDouble() * size.width, y),
                width: taille * 2,
                height: taille * 1.2,
              ),
              graine: astre.graine + i,
              sommets: 7,
              irregularite: 0.3,
            ),
            Paint()
              ..color = Color.lerp(
                astre.couleur,
                Colors.black,
                0.3 + alea.nextDouble() * 0.2,
              )!,
          );
        }
      case Surface.oceans:
        // De l'herbe : des touffes, pas une moquette verte.
        final math.Random alea = math.Random(astre.graine);
        for (int i = 0; i < 170; i++) {
          final double y = hauteur + alea.nextDouble() * (size.height - hauteur);
          final double x = alea.nextDouble() * size.width;
          final double longueur = 3 + (y - hauteur) / 8;
          canvas.drawLine(
            Offset(x, y),
            Offset(x + (alea.nextDouble() - 0.5) * 3, y - longueur),
            Paint()
              ..strokeWidth = 1.1
              ..color = Color.lerp(
                astre.couleur,
                alea.nextBool() ? Colors.white : Colors.black,
                0.18,
              )!,
          );
        }
      case Surface.nuages:
        // Jupiter n'a pas de sol : le sac repose sur une couche de nuages.
        // Les bandes sont tracées en perspective — serrées près de
        // l'horizon, larges au premier plan — parce que c'est ainsi qu'on
        // verrait un pont de nuages depuis sa surface. Le découpage
        // circulaire de Realisme.bandes convient à une planète vue de
        // loin, pas à un sol vu de dessus.
        final math.Random alea = math.Random(astre.graine);
        final double profondeur = size.height - hauteur + fleche;
        double y = hauteur - fleche;
        int rang = 0;
        while (y < size.height + 10) {
          final double avancement = (y - hauteur + fleche) / profondeur;
          // L'épaisseur croît avec la distance au point de fuite.
          final double epaisseur = 3 + avancement * avancement * 46;
          final bool sombre = rang.isOdd;
          canvas.drawRect(
            Rect.fromLTWH(-10, y, size.width + 20, epaisseur),
            Paint()
              ..color = (sombre
                      ? Color.lerp(astre.couleur, const Color(0xFF6B3F21), 0.5)!
                      : Color.lerp(astre.couleur, Colors.white, 0.3)!)
                  .withValues(alpha: 0.55)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
          );
          y += epaisseur;
          rang++;
        }
        // Quelques tourbillons : l'atmosphère de Jupiter est agitée, et
        // des bandes parfaitement droites feraient plancher de bois.
        for (int i = 0; i < 7; i++) {
          final double cy = hauteur + alea.nextDouble() * profondeur;
          final double proche = (cy - hauteur) / profondeur;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(alea.nextDouble() * size.width, cy),
              width: 40 + proche * 120,
              height: 6 + proche * 22,
            ),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.12)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
        }
        // La Grande Tache rouge, au loin : c'est la marque de Jupiter, et
        // elle existe depuis au moins trois siècles.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.74, hauteur + profondeur * 0.17),
            width: 86,
            height: 20,
          ),
          Paint()
            ..color = const Color(0xFFBE5B40).withValues(alpha: 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
    }
    canvas.restore();
    return hauteur;
  }

  /// Le sac : toujours le même, où qu'on soit.
  void _sac(Canvas canvas, Size size, double hauteurSol) {
    final double cx = size.width / 2;
    final double base = hauteurSol + 13;
    const double largeur = 46;
    const double hauteur = 52;

    // L'ombre portée, écrasée au sol.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 4, base + 3),
        width: largeur * 1.15,
        height: 11,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Le corps du sac : un sac de toile, plus large en bas, avec un col
    // froncé. Un rectangle aurait dit « boîte » et perdu l'idée qu'on
    // transporte quelque chose.
    final Rect cadre = Rect.fromLTWH(
      cx - largeur / 2,
      base - hauteur,
      largeur,
      hauteur,
    );
    final Path toile = Path()
      ..moveTo(cadre.left + 7, cadre.top + 12)
      ..cubicTo(
        cadre.left - 5, cadre.top + 34,
        cadre.left - 1, cadre.bottom,
        cx, cadre.bottom,
      )
      ..cubicTo(
        cadre.right + 1, cadre.bottom,
        cadre.right + 5, cadre.top + 34,
        cadre.right - 7, cadre.top + 12,
      )
      ..close();
    canvas.drawPath(toile, Realisme.chair(cadre, const Color(0xFFBE9A6A)));
    canvas.drawPath(
      toile,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF6E5436).withValues(alpha: 0.7),
    );

    // Les plis de la toile, qui disent qu'elle est souple et pleine.
    for (final double decalage in <double>[-12, 0, 12]) {
      canvas.drawPath(
        Path()
          ..moveTo(cx + decalage, cadre.top + 18)
          ..quadraticBezierTo(
            cx + decalage + 3,
            cadre.center.dy,
            cx + decalage * 1.3,
            cadre.bottom - 4,
          ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black.withValues(alpha: 0.12),
      );
    }

    // Le col et sa cordelette.
    canvas.drawPath(
      Path()
        ..moveTo(cadre.left + 7, cadre.top + 12)
        ..quadraticBezierTo(cx, cadre.top + 2, cadre.right - 7, cadre.top + 12),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF6E5436),
    );
  }

  /// La flèche du poids, et le repère du maximum atteignable.
  void _fleche(Canvas canvas, Size size, double hauteurSol) {
    final double cx = size.width / 2;
    final double depart = hauteurSol + 24;
    final double longueurMax = size.height - depart - 10;
    final double longueur = math.max(7, longueurMax * fraction.clamp(0, 1));

    // Le repère pointillé du poids maximal : sans lui, « plus court » n'a
    // rien à quoi se comparer.
    const double xRepere = 34;
    final Paint repere = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (double y = depart; y < depart + longueurMax; y += 10) {
      canvas.drawLine(
        Offset(cx + xRepere, y),
        Offset(cx + xRepere, math.min(y + 4, depart + longueurMax)),
        repere,
      );
    }
    // Le trait de butée, qui dit où s'arrête le poids le plus fort
    // possible. Sans lui, une flèche courte n'est courte que dans
    // l'absolu, et la comparaison entre astres se perd.
    canvas.drawLine(
      Offset(cx + xRepere - 7, depart + longueurMax),
      Offset(cx + xRepere + 7, depart + longueurMax),
      repere,
    );

    // Les flèches sont tracées, pas écrites : la police du contenu n'a pas
    // de glyphe de flèche, et un rectangle vide serait pire que rien.
    canvas.drawLine(
      Offset(cx, depart),
      Offset(cx, depart + longueur),
      Paint()
        ..color = accent
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx, depart + longueur + 10)
        ..lineTo(cx - 7.5, depart + longueur - 2)
        ..lineTo(cx + 7.5, depart + longueur - 2)
        ..close(),
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(_PoidsPainter old) =>
      old.fraction != fraction ||
      old.astre.nom != astre.nom ||
      old.accent != accent;
}
