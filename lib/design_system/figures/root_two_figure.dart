/// La diagonale du carré, et la fraction qui n'arrive jamais dessus.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// La chasse à la fraction qui vaudrait la racine de deux.
///
/// L'irrationalité de √2 se démontre en six lignes, et ces six lignes ne
/// convainquent personne qui n'ait d'abord essayé. L'élève doit sentir
/// l'échec avant qu'on lui explique pourquoi il était inévitable : c'est
/// l'ordre dans lequel les Grecs l'ont vécu, et le scandale vient de là.
///
/// La commande est le dénominateur. Pour chaque `q`, la figure prend le
/// meilleur `p` possible et affiche les deux carrés que la démonstration
/// compare : `p²` et `2q²`. Ils s'approchent — 49 contre 50, 1 154 contre
/// 1 152 — et l'écart ne tombe jamais à zéro. Il vaut toujours au moins 1,
/// parce que ce sont des entiers, et c'est précisément ce que la preuve
/// par parité transforme en impossibilité.
class RootTwoFigure extends StatefulWidget {
  const RootTwoFigure({required this.accent, super.key});

  /// Couleur d'accent de la matière.
  final Color accent;

  /// Plus grand dénominateur proposé.
  static const int denominateurMax = 70;

  /// Le numérateur qui approche le mieux `q × √2`.
  static int meilleurNumerateur(int q) => (q * math.sqrt2).round();

  /// L'écart entier entre `p²` et `2q²`.
  ///
  /// C'est le cœur du chapitre : cet écart est un entier non nul. Il peut
  /// devenir minuscule devant les nombres comparés, il ne peut pas
  /// s'annuler — et une démonstration, contrairement à un tableau de
  /// valeurs, sait dire pourquoi.
  static int ecart(int q) {
    final int p = meilleurNumerateur(q);
    return p * p - 2 * q * q;
  }

  /// Les premières fractions qui battent toutes les précédentes.
  ///
  /// Ce sont les réduites de la fraction continue de √2, obtenues par la
  /// récurrence de Pell : chaque terme vaut deux fois le précédent plus
  /// l'avant-dernier. On ne les écrit pas en dur — elles se calculent, et
  /// `test/widget/racine_de_deux_test.dart` vérifie qu'elles sont bien les
  /// meilleures approximations de leur taille.
  static List<(int, int)> reduites({int combien = 8}) {
    final List<(int, int)> suite = <(int, int)>[(1, 1), (3, 2)];
    while (suite.length < combien) {
      final (int pAvant, int qAvant) = suite[suite.length - 2];
      final (int p, int q) = suite.last;
      suite.add((2 * p + pAvant, 2 * q + qAvant));
    }
    return suite.take(combien).toList();
  }

  @override
  State<RootTwoFigure> createState() => _RootTwoFigureState();
}

class _RootTwoFigureState extends State<RootTwoFigure> {
  int _q = 1;

  void _regler(double valeur) {
    final int q = valeur.round().clamp(1, RootTwoFigure.denominateurMax);
    if (q == _q) return;
    setState(() => _q = q);
    context.tapFeedback();
  }

  /// Le prochain dénominateur qui améliore vraiment l'approximation.
  void _sauterAuMeilleur() {
    final List<(int, int)> reduites = RootTwoFigure.reduites();
    for (final (int _, int q) in reduites) {
      if (q > _q && q <= RootTwoFigure.denominateurMax) {
        setState(() => _q = q);
        context.successFeedback();
        return;
      }
    }
    setState(() => _q = 1);
    context.tapFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final int p = RootTwoFigure.meilleurNumerateur(_q);
    final int ecart = RootTwoFigure.ecart(_q);
    final double valeur = p / _q;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 186,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return CustomPaint(
                  size: Size(contraintes.maxWidth, 186),
                  painter: _CarrePainter(
                    fraction: valeur,
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
          '$p / $_q = ${valeur.toStringAsFixed(6).replaceAll('.', ',')}',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          '${p * p} contre ${2 * _q * _q}   '
          'écart ${ecart > 0 ? '+' : ''}$ecart',
          textAlign: TextAlign.center,
          style: AppTypography.formula(
            size: 15,
            color: ecart.abs() <= 1 ? tokens.warning : tokens.inkMuted,
          ),
        ),
        Text(
          ecart.abs() == 1
              ? 'Il ne manque qu’une unité. Et il en manquera toujours au '
                  'moins une : ce sont des entiers.'
              : 'p × p ne vaut pas 2 × q × q. Essaie encore.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        Row(
          children: <Widget>[
            SizedBox(
              width: 76,
              child: Text(
                'dénominateur',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkSubtle,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _q.toDouble(),
                min: 1,
                max: RootTwoFigure.denominateurMax.toDouble(),
                divisions: RootTwoFigure.denominateurMax - 1,
                label: '$_q',
                onChanged: _regler,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: _sauterAuMeilleur,
          child: const Text('Sauter à la meilleure suivante'),
        ),
      ],
    );
  }
}

/// Le carré de côté 1, sa diagonale, et la longueur de la fraction.
class _CarrePainter extends CustomPainter {
  const _CarrePainter({
    required this.fraction,
    required this.accent,
    required this.tokens,
  });

  final double fraction;
  final Color accent;
  final AppTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tokens.surfaceAlt);

    final double cote = math.min(size.width * 0.3, size.height * 0.54);
    final Offset coin = Offset(size.width * 0.08, size.height * 0.84);
    final Rect carre = Rect.fromLTWH(coin.dx, coin.dy - cote, cote, cote);

    // Le carré de côté 1 : c'est l'objet dont on parle, et il doit être
    // posé sur une base, pas flotter.
    canvas.drawRect(
      carre,
      Paint()..color = accent.withValues(alpha: 0.12),
    );
    canvas.drawRect(
      carre,
      Paint()
        ..color = tokens.inkMuted
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    _etiquette(canvas, '1', Offset(carre.center.dx - 4, carre.bottom + 5),
        tokens.inkMuted);
    _etiquette(canvas, '1', Offset(carre.left - 13, carre.center.dy - 8),
        tokens.inkMuted);

    // La diagonale : la longueur dont on cherche la mesure.
    canvas.drawLine(
      carre.bottomLeft,
      carre.topRight,
      Paint()
        ..color = accent
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // On rabat la diagonale sur l'horizontale, à droite du carré : c'est
    // le geste du compas, et c'est ce qui rend les deux longueurs
    // comparables à l'œil.
    final double diagonale = cote * math.sqrt2;
    // Les deux barres tiennent dans le quart bas-droit, à la même échelle
    // que le carré : comparer deux longueurs d'échelles différentes
    // n'apprendrait rien.
    final double ligne = size.height * 0.5;
    final double departX = size.width * 0.46;
    canvas.drawArc(
      Rect.fromCircle(center: carre.bottomLeft, radius: diagonale),
      -math.pi / 4,
      math.pi / 4,
      false,
      Paint()
        ..color = tokens.inkSubtle.withValues(alpha: 0.4)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    _barre(
      canvas,
      Offset(departX, ligne),
      diagonale,
      accent,
      'la diagonale',
    );
    _barre(
      canvas,
      Offset(departX, ligne + 40),
      cote * fraction,
      fraction * fraction < 2 ? tokens.error : tokens.warning,
      'la fraction',
    );

    // Le trait de comparaison : sans lui, l'élève doit mesurer de l'œil
    // deux barres presque égales, ce qui est exactement ce qu'on ne veut
    // pas lui demander.
    canvas.drawLine(
      Offset(departX + diagonale, ligne - 8),
      Offset(departX + diagonale, ligne + 50),
      Paint()
        ..color = accent.withValues(alpha: 0.55)
        ..strokeWidth = 1.2,
    );
  }

  /// Une longueur posée à plat, avec son nom.
  void _barre(
    Canvas canvas,
    Offset depart,
    double longueur,
    Color couleur,
    String nom,
  ) {
    canvas.drawLine(
      depart,
      depart + Offset(longueur, 0),
      Paint()
        ..color = couleur
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    _etiquette(canvas, nom, depart + const Offset(0, -16), couleur);
  }

  void _etiquette(Canvas canvas, String texte, Offset ou, Color couleur) {
    TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          color: couleur,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, ou);
  }

  @override
  bool shouldRepaint(_CarrePainter ancien) =>
      ancien.fraction != fraction ||
      ancien.accent != accent ||
      ancien.tokens != tokens;
}
