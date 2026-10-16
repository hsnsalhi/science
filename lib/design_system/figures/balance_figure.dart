/// Une balance à deux plateaux, pour résoudre une équation par gestes.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

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

  @override
  void paint(Canvas canvas, Size size) {
    final double centre = size.width / 2;
    const double hauteurFleau = 34;
    final double demiFleau = math.min(centre - 20, 110);

    // Le fléau reste horizontal : les deux gestes proposés préservent
    // l'égalité, donc l'équilibre. Le montrer pencher serait enseigner le
    // contraire de ce que la figure dit.
    canvas.drawLine(
      Offset(centre - demiFleau, hauteurFleau),
      Offset(centre + demiFleau, hauteurFleau),
      Paint()
        ..color = trait
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(centre, hauteurFleau)
        ..lineTo(centre - 16, 112)
        ..lineTo(centre + 16, 112)
        ..close(),
      Paint()..color = trait.withValues(alpha: 0.5),
    );

    _plateau(canvas, centre - demiFleau, hauteurFleau, coefficient,
        constante, true);
    _plateau(canvas, centre + demiFleau, hauteurFleau, 0, total, false);
  }

  /// Un plateau, ses jetons x et ses jetons unité.
  void _plateau(
    Canvas canvas,
    double x,
    double hautFleau,
    int nbX,
    int nbUn,
    bool gauche,
  ) {
    const double hautPlateau = 86;
    canvas.drawLine(
      Offset(x, hautFleau),
      Offset(x, hautPlateau),
      Paint()
        ..color = trait
        ..strokeWidth = 1.6,
    );
    canvas.drawLine(
      Offset(x - 34, hautPlateau),
      Offset(x + 34, hautPlateau),
      Paint()
        ..color = trait
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Les jetons sont empilés par rangées de six, pour qu'un plateau à
    // vingt unités reste lisible sans changer d'échelle.
    const double taille = 11;
    const double ecart = 2.5;
    final List<({Color couleur, String etiquette})> jetons =
        <({Color couleur, String etiquette})>[
      for (int i = 0; i < nbX; i++) (couleur: accent, etiquette: 'x'),
      for (int i = 0; i < nbUn.abs(); i++)
        (couleur: muted.withValues(alpha: 0.6), etiquette: ''),
    ];
    for (int i = 0; i < jetons.length; i++) {
      final int colonne = i % 6;
      final int rangee = i ~/ 6;
      final double cx =
          x - 2.5 * (taille + ecart) + colonne * (taille + ecart);
      final double cy = hautPlateau - 8 - rangee * (taille + ecart);
      final Rect r = Rect.fromCenter(
        center: Offset(cx, cy),
        width: taille,
        height: taille,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(3)),
        Paint()..color = jetons[i].couleur,
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
