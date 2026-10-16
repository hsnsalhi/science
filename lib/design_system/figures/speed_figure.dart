/// Un mobile qui parcourt une piste, et la vitesse qui s'en déduit.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Un mobile lancé sur une piste graduée, dont on règle la vitesse.
///
/// La relation v = d ÷ t s'écrit en une ligne et ne se comprend pas pour
/// autant. Ici on règle la vitesse, et on voit le mobile mettre deux fois
/// moins de temps quand elle double — les trois nombres bougent ensemble,
/// et c'est leur lien qui se lit, pas la formule.
///
/// Les positions successives restent marquées derrière le mobile : à
/// vitesse constante, elles sont également espacées. C'est la définition
/// d'un mouvement uniforme, montrée plutôt qu'énoncée.
class SpeedFigure extends StatefulWidget {
  const SpeedFigure({required this.accent, super.key});

  final Color accent;

  /// Longueur de la piste, en mètres.
  static const double distance = 60;

  @override
  State<SpeedFigure> createState() => _SpeedFigureState();
}

class _SpeedFigureState extends State<SpeedFigure>
    with SingleTickerProviderStateMixin {
  /// Vitesse réglée, en mètres par seconde.
  double _vitesse = 10;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..addListener(() => setState(() {}));

  bool _demarrageFait = false;

  /// Durée du parcours à la vitesse courante, en secondes.
  double get _duree => SpeedFigure.distance / _vitesse;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _relancer() {
    // La durée de l'animation suit la durée réelle du parcours : c'est ce
    // qui fait que doubler la vitesse se voit, au lieu de se lire.
    _controller.duration = Duration(milliseconds: (_duree * 1000).round());
    _controller.forward(from: 0);
  }

  String _n(double v) =>
      NumericQuestion.formatNumber((v * 10).roundToDouble() / 10);

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;

    if (!_demarrageFait) {
      _demarrageFait = true;
      if (!context.reduceMotion) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _relancer();
        });
      }
    }

    final double parcouru = SpeedFigure.distance * _controller.value;
    final double ecoule = _duree * _controller.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 96,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, 96),
                painter: _PistePainter(
                  avancement: _controller.value,
                  accent: widget.accent,
                  trait: tokens.border,
                  muted: tokens.inkMuted,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.lg,
          children: <Widget>[
            _Mesure(
              nom: 'distance',
              valeur: '${_n(parcouru)} m',
              accent: widget.accent,
            ),
            _Mesure(
              nom: 'temps',
              valeur: '${_n(ecoule)} s',
              accent: widget.accent,
            ),
            _Mesure(
              nom: 'vitesse',
              valeur: '${_n(_vitesse)} m/s',
              accent: widget.accent,
              fort: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Les ${_n(SpeedFigure.distance)} m en ${_n(_duree)} s',
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        Row(
          children: <Widget>[
            IconButton(
              tooltip: 'Relancer',
              onPressed: () {
                context.tapFeedback();
                _relancer();
              },
              icon: Icon(Icons.replay_rounded, color: widget.accent),
            ),
            Expanded(
              child: Slider(
                value: _vitesse,
                min: 2,
                max: 30,
                divisions: 28,
                label: '${_n(_vitesse)} m/s',
                onChanged: (double v) {
                  setState(() => _vitesse = v);
                  _relancer();
                },
              ),
            ),
          ],
        ),
        Text(
          'Règle la vitesse : le temps de parcours suit',
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

/// Une grandeur mesurée, affichée en grand.
class _Mesure extends StatelessWidget {
  const _Mesure({
    required this.nom,
    required this.valeur,
    required this.accent,
    this.fort = false,
  });

  final String nom;
  final String valeur;
  final Color accent;
  final bool fort;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          valeur,
          style: AppTypography.formula(
            size: fort ? 20 : 17,
            color: fort ? accent : context.colors.onSurface,
          ),
        ),
        Text(
          nom,
          style: context.text.labelSmall?.copyWith(
            color: context.tokens.inkSubtle,
          ),
        ),
      ],
    );
  }
}

class _PistePainter extends CustomPainter {
  const _PistePainter({
    required this.avancement,
    required this.accent,
    required this.trait,
    required this.muted,
  });

  final double avancement;
  final Color accent;
  final Color trait;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    const double marge = 18;
    final double y = size.height * 0.52;
    final double utile = size.width - marge * 2;

    canvas.drawLine(
      Offset(marge, y),
      Offset(size.width - marge, y),
      Paint()
        ..color = trait
        ..strokeWidth = 2,
    );

    // Graduations tous les dix mètres.
    for (int m = 0; m <= 60; m += 10) {
      final double x = marge + utile * (m / 60);
      canvas.drawLine(
        Offset(x, y + 6),
        Offset(x, y + 12),
        Paint()
          ..color = trait
          ..strokeWidth = 1,
      );
      _texte(canvas, '$m', Offset(x, y + 22), muted);
    }

    // Les positions déjà occupées, également espacées : la trace d'un
    // mouvement uniforme.
    for (int i = 1; i <= 8; i++) {
      final double part = i / 8;
      if (part > avancement) break;
      canvas.drawCircle(
        Offset(marge + utile * part, y),
        3,
        Paint()..color = accent.withValues(alpha: 0.35),
      );
    }

    final Offset mobile = Offset(marge + utile * avancement, y);
    canvas.drawCircle(mobile, 9, Paint()..color = accent);
    canvas.drawCircle(
      mobile,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent.withValues(alpha: 0.4),
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
          fontWeight: FontWeight.w600,
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
  bool shouldRepaint(_PistePainter old) =>
      old.avancement != avancement || old.accent != accent;
}
