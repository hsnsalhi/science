/// Une suite dont on règle le premier terme et la raison.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Les premiers termes d'une suite, en bâtons.
///
/// Une suite arithmétique et une suite géométrique se définissent par
/// une ligne chacune, et rien dans ces deux lignes ne laisse deviner à
/// quel point leurs comportements diffèrent. Posées côte à côte en
/// bâtons, la différence saute aux yeux : l'une monte en marches
/// régulières, l'autre s'envole.
///
/// Le bouton qui bascule d'un type à l'autre garde les mêmes réglages,
/// de sorte que la comparaison porte sur le seul mode de croissance.
class SequenceFigure extends StatefulWidget {
  const SequenceFigure({required this.accent, super.key});

  final Color accent;

  /// Nombre de termes affichés.
  static const int termes = 10;

  /// Terme de rang [n], le rang 0 étant le premier.
  ///
  /// Arithmétique : on ajoute la raison à chaque pas.
  /// Géométrique : on multiplie par la raison.
  static double terme(
    int n, {
    required double premier,
    required double raison,
    required bool geometrique,
  }) =>
      geometrique
      ? premier * math.pow(raison, n).toDouble()
      : premier + raison * n;

  /// Somme des [combien] premiers termes.
  static double somme(
    int combien, {
    required double premier,
    required double raison,
    required bool geometrique,
  }) {
    double total = 0;
    for (int n = 0; n < combien; n++) {
      total += terme(
        n,
        premier: premier,
        raison: raison,
        geometrique: geometrique,
      );
    }
    return total;
  }

  @override
  State<SequenceFigure> createState() => _SequenceFigureState();
}

class _SequenceFigureState extends State<SequenceFigure> {
  double _premier = 2;
  double _raison = 3;
  bool _geometrique = false;

  String _n(double v) =>
      NumericQuestion.formatNumber((v * 100).roundToDouble() / 100);

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final List<double> valeurs = <double>[
      for (int n = 0; n < SequenceFigure.termes; n++)
        SequenceFigure.terme(
          n,
          premier: _premier,
          raison: _raison,
          geometrique: _geometrique,
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.45,
          child: CustomPaint(
            painter: _SuitePainter(
              valeurs: valeurs,
              accent: widget.accent,
              ink: context.colors.onSurface,
              trait: tokens.border,
              muted: tokens.inkMuted,
              surface: context.colors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          // « u(n+1) » plutôt que « uₙ₊₁ » : les indices en lettre et
          // en signe manquent aux polices du projet et s'affichaient en
          // carrés, alors que les chiffres en indice passent.
          _geometrique
              ? 'u(n+1) = ${_n(_raison)} × u(n)'
              : 'u(n+1) = u(n) + ${_n(_raison)}',
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          'u₀ = ${_n(_premier)}  ·  u₉ = ${_n(valeurs.last)}  ·  '
          'somme des 10 premiers : ${_n(valeurs.reduce(
            (double a, double b) => a + b,
          ))}',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        FilledButton.tonalIcon(
          onPressed: () {
            context.tapFeedback();
            setState(() => _geometrique = !_geometrique);
          },
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: Text(
            _geometrique ? 'Voir une suite arithmétique' : 'Voir une suite géométrique',
          ),
        ),
        _Reglage(
          nom: 'premier terme',
          valeur: _premier,
          min: 1,
          max: 10,
          affichage: _n(_premier),
          accent: widget.accent,
          onChanged: (double v) =>
              setState(() => _premier = v.roundToDouble()),
        ),
        _Reglage(
          nom: 'raison',
          valeur: _raison,
          min: _geometrique ? 0.5 : -5,
          max: _geometrique ? 3 : 10,
          affichage: _n(_raison),
          accent: widget.accent,
          onChanged: (double v) => setState(
            () => _raison = _geometrique
                ? (v * 4).roundToDouble() / 4
                : v.roundToDouble(),
          ),
        ),
      ],
    );
  }
}

class _Reglage extends StatelessWidget {
  const _Reglage({
    required this.nom,
    required this.valeur,
    required this.min,
    required this.max,
    required this.affichage,
    required this.accent,
    required this.onChanged,
  });

  final String nom;
  final double valeur;
  final double min;
  final double max;
  final String affichage;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      SizedBox(
        width: 96,
        child: Text(
          nom,
          style: context.text.labelSmall?.copyWith(
            color: context.tokens.inkSubtle,
          ),
        ),
      ),
      Expanded(
        child: Slider(
          value: valeur.clamp(min, max),
          min: min,
          max: max,
          onChanged: (double v) {
            context.tapFeedback();
            onChanged(v);
          },
        ),
      ),
      SizedBox(
        width: 44,
        child: Text(
          affichage,
          textAlign: TextAlign.right,
          style: AppTypography.formula(size: 15, color: accent),
        ),
      ),
    ],
  );
}

class _SuitePainter extends CustomPainter {
  const _SuitePainter({
    required this.valeurs,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final List<double> valeurs;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    const double marge = 18;
    final Rect cadre = Rect.fromLTRB(
      marge,
      10,
      size.width - marge,
      size.height - 24,
    );
    canvas.drawRect(cadre, Paint()..color = surface);

    double maximum = 1;
    double minimum = 0;
    for (final double v in valeurs) {
      maximum = math.max(maximum, v);
      minimum = math.min(minimum, v);
    }
    // L'échelle suit les valeurs : une suite géométrique dépasse de
    // plusieurs ordres de grandeur celles qui l'entourent, et une
    // échelle figée écraserait les premiers termes contre l'axe.
    final double etendue = maximum - minimum;
    final double zero = cadre.bottom - cadre.height * (-minimum) / etendue;

    canvas.drawLine(
      Offset(cadre.left, zero),
      Offset(cadre.right, zero),
      Paint()
        ..color = ink.withValues(alpha: 0.6)
        ..strokeWidth = 1.5,
    );

    final double pas = cadre.width / valeurs.length;
    for (int n = 0; n < valeurs.length; n++) {
      final double hauteur = cadre.height * valeurs[n] / etendue;
      final Rect baton = Rect.fromLTRB(
        cadre.left + pas * n + pas * 0.18,
        valeurs[n] >= 0 ? zero - hauteur : zero,
        cadre.left + pas * (n + 1) - pas * 0.18,
        valeurs[n] >= 0 ? zero : zero - hauteur,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          baton,
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        Paint()..color = accent.withValues(alpha: 0.85),
      );
      _texte(
        canvas,
        '$n',
        Offset(baton.center.dx, cadre.bottom + 12),
        muted,
      );
    }

    canvas.drawRect(
      cadre,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = trait,
    );
  }

  void _texte(Canvas canvas, String texte, Offset centre, Color couleur) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          color: couleur,
          fontSize: 10,
          fontWeight: FontWeight.w700,
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
  bool shouldRepaint(_SuitePainter old) =>
      old.valeurs != valeurs || old.accent != accent;
}
