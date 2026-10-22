/// Une balance à deux plateaux, pour résoudre une équation par gestes.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'realism.dart';

/// L'équation ax + b = c, posée sur une balance qu'on rééquilibre.
///
/// « Ce qu'on fait d'un côté, on le fait de l'autre » est une consigne, et
/// les consignes s'appliquent de travers dès qu'on ne voit plus pourquoi.
/// Sur une balance, il n'y a plus de consigne : retirer trois poids d'un
/// seul plateau fait pencher la balance, et cela se voit avant qu'on ait
/// écrit quoi que ce soit.
///
/// Les deux boutons ne proposent que des gestes légitimes, appliqués des
/// deux côtés à la fois, jusqu'à ce qu'il ne reste qu'un x d'un côté. Le
/// déséquilibre n'est donc jamais montré comme une option : il est montré
/// comme ce qui n'arrive pas quand on s'y prend bien.
class BalanceFigure extends StatefulWidget {
  const BalanceFigure({required this.accent, super.key});

  final Color accent;

  /// État d'une équation de la forme `coefficient × x + constante = total`.
  ///
  /// Les deux transformations sont exposées comme fonctions pures pour que
  /// le test puisse vérifier ce qui compte vraiment : qu'elles préservent
  /// la solution. Une figure qui enseignerait un geste invalide serait
  /// pire qu'aucune figure.
  static ({int coefficient, int constante, int total}) retirer(
    ({int coefficient, int constante, int total}) etat,
    int combien,
  ) => (
    coefficient: etat.coefficient,
    constante: etat.constante - combien,
    total: etat.total - combien,
  );

  /// Divise les deux membres par [diviseur].
  ///
  /// Renvoie `null` si le diviseur est nul, ou si la division ne tombe pas
  /// juste des deux côtés : la figure ne montre que des étapes exactes.
  static ({int coefficient, int constante, int total})? diviser(
    ({int coefficient, int constante, int total}) etat,
    int diviseur,
  ) {
    if (diviseur == 0) return null;
    if (etat.coefficient % diviseur != 0 ||
        etat.constante % diviseur != 0 ||
        etat.total % diviseur != 0) {
      return null;
    }
    return (
      coefficient: etat.coefficient ~/ diviseur,
      constante: etat.constante ~/ diviseur,
      total: etat.total ~/ diviseur,
    );
  }

  /// Solution de l'équation, ou `null` si le coefficient est nul.
  static double? solution(
    ({int coefficient, int constante, int total}) etat,
  ) {
    if (etat.coefficient == 0) return null;
    return (etat.total - etat.constante) / etat.coefficient;
  }

  /// L'équation est-elle résolue, c'est-à-dire de la forme `x = valeur` ?
  static bool resolue(
    ({int coefficient, int constante, int total}) etat,
  ) => etat.coefficient == 1 && etat.constante == 0;

  @override
  State<BalanceFigure> createState() => _BalanceFigureState();
}

class _BalanceFigureState extends State<BalanceFigure> {
  static const ({int coefficient, int constante, int total}) _depart =
      (coefficient: 3, constante: 5, total: 20);

  ({int coefficient, int constante, int total}) _etat = _depart;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool fini = BalanceFigure.resolue(_etat);
    final double? solution = BalanceFigure.solution(_etat);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 130,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, 130),
                painter: _BalancePainter(
                  coefficient: _etat.coefficient,
                  constante: _etat.constante,
                  total: _etat.total,
                  accent: widget.accent,
                  trait: tokens.border,
                  muted: tokens.inkMuted,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _ecrire(_etat),
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 20, color: widget.accent),
        ),
        Text(
          fini
              ? 'Résolu : il ne reste qu\'un x d\'un côté.'
              : 'Solution inchangée : x = ${_joli(solution)}.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            if (_etat.constante != 0)
              FilledButton.tonal(
                onPressed: () {
                  context.tapFeedback();
                  setState(
                    () => _etat = BalanceFigure.retirer(
                      _etat,
                      _etat.constante,
                    ),
                  );
                },
                child: Text(
                  'retirer ${_etat.constante} des deux côtés',
                ),
              ),
            if (_etat.constante == 0 && _etat.coefficient > 1)
              FilledButton.tonal(
                onPressed: () {
                  context.tapFeedback();
                  final ({int coefficient, int constante, int total})? suite =
                      BalanceFigure.diviser(_etat, _etat.coefficient);
                  if (suite != null) setState(() => _etat = suite);
                },
                child: Text(
                  'diviser les deux côtés par ${_etat.coefficient}',
                ),
              ),
            if (_etat != _depart)
              OutlinedButton(
                onPressed: () {
                  context.tapFeedback();
                  setState(() => _etat = _depart);
                },
                child: const Text('recommencer'),
              ),
          ],
        ),
      ],
    );
  }

  static String _ecrire(({int coefficient, int constante, int total}) e) {
    final String gauche = switch ((e.coefficient, e.constante)) {
      (1, 0) => 'x',
      (final int a, 0) => '${a}x',
      (1, final int b) => b > 0 ? 'x + $b' : 'x − ${-b}',
      (final int a, final int b) =>
        b > 0 ? '${a}x + $b' : '${a}x − ${-b}',
    };
    return '$gauche = ${e.total}';
  }

  static String _joli(double? valeur) {
    if (valeur == null) return 'indéterminé';
    if (valeur == valeur.roundToDouble()) return valeur.round().toString();
    return valeur.toStringAsFixed(2).replaceAll('.', ',');
  }
}

class _BalancePainter extends CustomPainter {
  const _BalancePainter({
    required this.coefficient,
    required this.constante,
    required this.total,
    required this.accent,
    required this.trait,
    required this.muted,
  });

  final int coefficient;
  final int constante;
  final int total;
  final Color accent;
  final Color trait;
  final Color muted;

  /// Le laiton d'une vraie balance d'épicier.
  static const Color _laiton = Color(0xFFBE9A4A);
  static const Color _laitonSombre = Color(0xFF7D6227);
  static const Color _bois = Color(0xFF6B4B32);

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    const double hauteurFleau = 30;
    final double demiFleau = math.min(cx - 26, 108);
    const double hautPlateau = 88;

    // Le fléau reste horizontal, et ce n'est pas une facilité de dessin :
    // les deux gestes que la figure propose préservent l'égalité, donc
    // l'équilibre. Montrer la balance pencher enseignerait le contraire de
    // ce qu'elle a à dire.
    _socle(canvas, cx, size.height);
    _colonne(canvas, cx, hauteurFleau, size.height);
    _fleau(canvas, cx, hauteurFleau, demiFleau);
    _aiguille(canvas, cx, hauteurFleau);

    _plateau(canvas, cx - demiFleau, hauteurFleau, hautPlateau,
        coefficient, constante);
    _plateau(canvas, cx + demiFleau, hauteurFleau, hautPlateau, 0, total);
  }

  /// Le pied, lesté : une balance tient debout toute seule.
  void _socle(Canvas canvas, double cx, double hauteur) {
    final Rect cadre = Rect.fromCenter(
      center: Offset(cx, hauteur - 7),
      width: 86,
      height: 13,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cadre, const Radius.circular(5)),
      Realisme.chair(cadre, _bois),
    );
    // L'ombre portée, qui pose l'objet sur une table plutôt que dans le vide.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 4, hauteur - 1),
        width: 104,
        height: 9,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  /// La colonne centrale et son chapiteau.
  void _colonne(Canvas canvas, double cx, double hautFleau, double hauteur) {
    final Rect fut = Rect.fromCenter(
      center: Offset(cx, (hautFleau + hauteur - 14) / 2),
      width: 11,
      height: hauteur - 14 - hautFleau,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(fut, const Radius.circular(4)),
      Realisme.chair(fut, _laiton),
    );
    // Le chapiteau qui porte le couteau du fléau.
    canvas.drawPath(
      Path()
        ..moveTo(cx - 13, hautFleau + 12)
        ..lineTo(cx, hautFleau + 1)
        ..lineTo(cx + 13, hautFleau + 12)
        ..close(),
      Paint()..color = _laitonSombre,
    );
  }

  /// Le fléau, avec son renflement central.
  void _fleau(Canvas canvas, double cx, double hauteur, double demi) {
    final Rect barre = Rect.fromCenter(
      center: Offset(cx, hauteur),
      width: demi * 2,
      height: 7,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barre, const Radius.circular(3.5)),
      Realisme.chair(barre, _laiton),
    );
    // Les deux embouts d'où pendent les plateaux.
    for (final double cote in <double>[-1, 1]) {
      canvas.drawCircle(
        Offset(cx + cote * demi, hauteur),
        5,
        Paint()..color = _laitonSombre,
      );
    }
    canvas.drawCircle(
      Offset(cx, hauteur),
      7,
      Paint()..color = _laitonSombre,
    );
  }

  /// L'aiguille et son repère : elle est au zéro, et doit y rester.
  void _aiguille(Canvas canvas, double cx, double hautFleau) {
    canvas.drawLine(
      Offset(cx, hautFleau + 6),
      Offset(cx, hautFleau + 26),
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = _laitonSombre,
    );
    // La graduation derrière l'aiguille : c'est elle qui rend l'équilibre
    // lisible comme un fait et non comme une impression.
    for (final double decalage in <double>[-9, -4.5, 0, 4.5, 9]) {
      final bool centre = decalage == 0;
      canvas.drawLine(
        Offset(cx + decalage, hautFleau + 27),
        Offset(cx + decalage, hautFleau + (centre ? 34 : 31)),
        Paint()
          ..strokeWidth = centre ? 1.8 : 1
          ..color = trait.withValues(alpha: centre ? 0.8 : 0.45),
      );
    }
  }

  /// Un plateau suspendu, et ce qu'on y a posé.
  void _plateau(
    Canvas canvas,
    double x,
    double hautFleau,
    double hautPlateau,
    int nbX,
    int nbUn,
  ) {
    // Trois cordes, comme sur une vraie balance : une seule tige ferait
    // tourner le plateau au moindre déséquilibre.
    const double demiLargeur = 38;
    for (final double cote in <double>[-1, 0, 1]) {
      canvas.drawLine(
        Offset(x, hautFleau + 4),
        Offset(x + cote * demiLargeur * 0.8, hautPlateau - 3),
        Paint()
          ..strokeWidth = 1.1
          ..color = _laitonSombre.withValues(alpha: 0.8),
      );
    }

    // Le plateau : une coupelle, pas un trait. Son creux est ce qui
    // retient les objets.
    final Rect coupelle = Rect.fromCenter(
      center: Offset(x, hautPlateau + 3),
      width: demiLargeur * 2,
      height: 13,
    );
    canvas.drawOval(coupelle, Realisme.chair(coupelle, _laiton));
    canvas.drawOval(
      coupelle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _laitonSombre,
    );
    // Le bord supérieur, plus clair : la lumière vient d'en haut.
    canvas.drawArc(
      coupelle,
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.4),
    );

    _poids(canvas, x, hautPlateau, nbX, nbUn);
  }

  /// Les masses posées dans la coupelle.
  ///
  /// Les x sont des sachets scellés dont on ignore le contenu — c'est
  /// exactement ce qu'est une inconnue. Les unités sont des poids
  /// d'épicier, empilés par rangées pour rester lisibles jusqu'à vingt.
  void _poids(
    Canvas canvas,
    double x,
    double hautPlateau,
    int nbX,
    int nbUn,
  ) {
    const double taille = 13;
    const double ecart = 2;
    const int parRangee = 5;
    double y = hautPlateau - 4;

    // Les poids unité d'abord, au fond de la coupelle.
    for (int i = 0; i < nbUn.abs(); i++) {
      final int colonne = i % parRangee;
      final int rangee = i ~/ parRangee;
      final Rect masse = Rect.fromCenter(
        center: Offset(
          x - (parRangee - 1) / 2 * (taille + ecart) +
              colonne * (taille + ecart),
          y - rangee * (taille * 0.62 + ecart),
        ),
        width: taille,
        height: taille * 0.62,
      );
      // Un poids d'épicier : un tronc de cône avec son bouton.
      canvas.drawPath(
        Path()
          ..moveTo(masse.left, masse.bottom)
          ..lineTo(masse.left + 2, masse.top)
          ..lineTo(masse.right - 2, masse.top)
          ..lineTo(masse.right, masse.bottom)
          ..close(),
        Realisme.chair(masse, muted),
      );
      canvas.drawCircle(
        Offset(masse.center.dx, masse.top - 1),
        1.6,
        Paint()..color = Color.lerp(muted, Colors.black, 0.3)!,
      );
    }

    // Puis les sachets « x », posés par-dessus pour rester visibles.
    y -= ((nbUn.abs() + parRangee - 1) ~/ parRangee) * (taille * 0.62 + ecart);
    for (int i = 0; i < nbX; i++) {
      final Rect sachet = Rect.fromCenter(
        center: Offset(
          x - (nbX - 1) / 2 * (taille + 3) + i * (taille + 3),
          y - 7,
        ),
        width: taille,
        height: taille * 1.15,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(sachet, const Radius.circular(2.5)),
        Realisme.chair(sachet, accent),
      );
      // Le cordon du sachet : il est fermé, on ne sait pas ce qu'il y a
      // dedans. C'est l'image même de l'inconnue.
      canvas.drawLine(
        Offset(sachet.left + 2, sachet.top + 2.5),
        Offset(sachet.right - 2, sachet.top + 2.5),
        Paint()
          ..strokeWidth = 1.6
          ..color = Color.lerp(accent, Colors.black, 0.4)!,
      );
      final TextPainter etiquette = TextPainter(
        text: TextSpan(
          text: 'x',
          style: TextStyle(
            fontFamily: AppTypography.body,
            fontFamilyFallback: AppTypography.replis,
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      etiquette.paint(
        canvas,
        sachet.center.translate(-etiquette.width / 2, -1),
      );
    }
  }

  @override
  bool shouldRepaint(_BalancePainter old) =>
      old.coefficient != coefficient ||
      old.constante != constante ||
      old.total != total ||
      old.accent != accent;
}
