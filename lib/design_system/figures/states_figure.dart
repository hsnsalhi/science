/// Les trois états de l'eau, et ce que font ses particules.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Les trois états de la matière.
enum EtatMatiere {
  solide('solide', 'glace'),
  liquide('liquide', 'eau liquide'),
  gaz('gaz', 'vapeur d\'eau');

  const EtatMatiere(this.nom, this.exemple);

  final String nom;

  /// Comment cet état de l'eau s'appelle dans la vie courante.
  final String exemple;
}

/// Un thermomètre et une boîte de particules.
///
/// On déplace la température, et les particules changent d'allure :
/// rangées et serrées, puis glissant les unes sur les autres, puis
/// dispersées dans toute la boîte. Le nombre de particules, lui, ne
/// change jamais — c'est ce que la figure doit faire remarquer, parce
/// que « la glace fond, donc elle disparaît un peu » est une idée qui
/// tient tant qu'on n'a pas compté.
class StatesFigure extends StatefulWidget {
  const StatesFigure({required this.accent, super.key});

  final Color accent;

  /// Température de fusion de l'eau, en degrés Celsius.
  static const double fusion = 0;

  /// Température d'ébullition de l'eau sous la pression ordinaire.
  static const double ebullition = 100;

  /// Nombre de particules dessinées, constant par construction.
  static const int particules = 36;

  /// État de l'eau à cette température.
  static EtatMatiere etat(double celsius) {
    if (celsius < fusion) return EtatMatiere.solide;
    if (celsius < ebullition) return EtatMatiere.liquide;
    return EtatMatiere.gaz;
  }

  @override
  State<StatesFigure> createState() => _StatesFigureState();
}

class _StatesFigureState extends State<StatesFigure>
    with SingleTickerProviderStateMixin {
  double _temperature = 20;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..addListener(() => setState(() {}));

  bool _demarrageFait = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // Le thermomètre balaie de −20 à 140 °C : la glace fond à zéro,
    // l'eau bout à cent, et les deux changements d'état se produisent
    // sans qu'on ait à les provoquer.
    final double temperature = _tenue
        ? _temperature
        : Autoplay.sweepPas(context, min: -20, max: 140, pas: 1) ??
              _temperature;
    final EtatMatiere etat = StatesFigure.etat(temperature);

    if (!_demarrageFait) {
      _demarrageFait = true;
      if (!context.reduceMotion) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _controller.repeat();
        });
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.3,
          child: CustomPaint(
            painter: _MatierePainter(
              temperature: temperature,
              phase: _controller.value,
              accent: widget.accent,
              trait: tokens.border,
              muted: tokens.inkMuted,
              surface: context.colors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${NumericQuestion.formatNumber(temperature.roundToDouble())} °C · '
          '${etat.exemple}',
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          'Toujours ${StatesFigure.particules} particules : elles ne '
          'disparaissent pas, elles se rangent autrement.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        Slider(
          value: temperature,
          min: -20,
          max: 140,
          divisions: 160,
          onChanged: (double v) {
            context.tapFeedback();
            setState(() {
              _tenue = true;
              _temperature = v.roundToDouble();
            });
          },
        ),
        Text(
          'Fais varier la température',
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

class _MatierePainter extends CustomPainter {
  const _MatierePainter({
    required this.temperature,
    required this.phase,
    required this.accent,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final double temperature;

  /// Avancement de l'animation, entre 0 et 1.
  final double phase;

  final Color accent;
  final Color trait;
  final Color muted;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect boite = Rect.fromLTRB(
      size.width * 0.26,
      10,
      size.width - 10,
      size.height - 22,
    );
    _thermometre(canvas, Rect.fromLTRB(10, 10, size.width * 0.20, size.height - 22));

    canvas.drawRect(boite, Paint()..color = surface);
    canvas.save();
    canvas.clipRect(boite);

    final EtatMatiere etat = StatesFigure.etat(temperature);
    // Positions reproductibles : un générateur à graine fixe, pour que
    // la figure ne saute pas d'un redessin à l'autre.
    final math.Random alea = math.Random(7);
    const int colonnes = 6;
    for (int i = 0; i < StatesFigure.particules; i++) {
      final int ligne = i ~/ colonnes;
      final int colonne = i % colonnes;
      final double bruitX = alea.nextDouble() - 0.5;
      final double bruitY = alea.nextDouble() - 0.5;
      final double battement =
          math.sin(2 * math.pi * (phase + i / StatesFigure.particules));

      late Offset centre;
      switch (etat) {
        case EtatMatiere.solide:
          // Un réseau régulier et compact, qui ne fait que vibrer sur
          // place. Il occupe la même place que le liquide : un glaçon
          // qui fond ne change presque pas de volume, et la figure ne
          // doit pas suggérer le contraire.
          centre = Offset(
            boite.center.dx + (colonne - 2.5) * boite.width * 0.115,
            boite.bottom - boite.height * 0.07 -
                ligne * boite.height * 0.082,
          ) + Offset(battement * 1.6, -battement * 1.6);
        case EtatMatiere.liquide:
          // Aussi serrées, mais en désordre, et toujours dans le bas du
          // récipient : un liquide a un volume, pas une forme.
          centre = Offset(
            boite.center.dx +
                (colonne - 2.5) * boite.width * 0.115 +
                bruitX * boite.width * 0.07,
            boite.bottom -
                boite.height * 0.07 -
                ligne * boite.height * 0.082 +
                bruitY * boite.height * 0.05,
          ) + Offset(battement * 3, -battement * 2);
        case EtatMatiere.gaz:
          // Dispersées dans toute la boîte : un gaz occupe tout le
          // volume qu'on lui laisse. Les positions partent d'une grille
          // secouée plutôt que d'un tirage libre, qui laissait des
          // paquets et des trous.
          centre = Offset(
            boite.left +
                boite.width * (colonne + 0.5) / colonnes +
                bruitX * boite.width * 0.14 +
                battement * 9,
            boite.top +
                boite.height * (ligne + 0.5) / 6 +
                bruitY * boite.height * 0.14 -
                battement * 9,
          );
      }
      canvas.drawCircle(centre, 7, Paint()..color = accent);
      canvas.drawCircle(
        centre,
        7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = accent.withValues(alpha: 0.5),
      );
    }

    // Le niveau du liquide, qui rappelle qu'il garde son volume.
    if (etat == EtatMatiere.liquide) {
      canvas.drawLine(
        Offset(boite.left, boite.bottom - boite.height * 0.5),
        Offset(boite.right, boite.bottom - boite.height * 0.5),
        Paint()
          ..color = accent.withValues(alpha: 0.35)
          ..strokeWidth = 1.5,
      );
    }
    canvas.restore();

    canvas.drawRect(
      boite,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = trait,
    );
    _texte(
      canvas,
      switch (etat) {
        EtatMatiere.solide => 'rangées et serrées',
        EtatMatiere.liquide => 'serrées mais libres de glisser',
        EtatMatiere.gaz => 'dispersées dans tout le volume',
      },
      Offset(boite.center.dx, size.height - 10),
      muted,
    );
  }

  /// Un thermomètre gradué, avec les deux changements d'état marqués.
  void _thermometre(Canvas canvas, Rect zone) {
    final double x = zone.center.dx;
    final Rect tube = Rect.fromLTRB(x - 9, zone.top + 6, x + 9, zone.bottom - 18);
    final RRect arrondi =
        RRect.fromRectAndRadius(tube, const Radius.circular(9));
    canvas.drawRRect(arrondi, Paint()..color = surface);

    double hauteurDe(double celsius) =>
        tube.bottom - tube.height * ((celsius + 20) / 160).clamp(0.0, 1.0);

    canvas.save();
    canvas.clipRRect(arrondi);
    canvas.drawRect(
      Rect.fromLTRB(tube.left, hauteurDe(temperature), tube.right, tube.bottom),
      Paint()..color = accent,
    );
    canvas.restore();
    canvas.drawRRect(
      arrondi,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = trait,
    );

    // Le réservoir, toujours plein : sans lui, le thermomètre paraît
    // cassé au minimum de l'échelle.
    final Offset reservoir = Offset(x, tube.bottom + 2);
    canvas.drawCircle(reservoir, 13, Paint()..color = accent);
    canvas.drawCircle(
      reservoir,
      13,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = trait,
    );

    for (final double seuil in <double>[
      StatesFigure.fusion,
      StatesFigure.ebullition,
    ]) {
      final double y = hauteurDe(seuil);
      canvas.drawLine(
        Offset(tube.right + 2, y),
        Offset(tube.right + 9, y),
        Paint()
          ..color = muted
          ..strokeWidth = 1.5,
      );
      _texte(canvas, '${seuil.round()}°', Offset(tube.left - 13, y), muted);
    }
  }

  void _texte(Canvas canvas, String texte, Offset centre, Color couleur) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontFamilyFallback: AppTypography.replis,
          color: couleur,
          fontSize: 11,
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
  bool shouldRepaint(_MatierePainter old) =>
      old.temperature != temperature ||
      old.phase != phase ||
      old.accent != accent;
}
