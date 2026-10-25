/// Deux roues dentées qui s'entraînent, et le rapport qui s'en déduit.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Un engrenage à deux roues, dont on règle la seconde.
///
/// Le rapport de transmission s'écrit en une fraction et ne se comprend
/// qu'en regardant tourner les roues : une petite roue menée fait
/// plusieurs tours pendant que la grande en fait un seul, et toujours en
/// sens inverse. Les deux compteurs sont là pour qu'on le constate plutôt
/// que de le croire.
///
/// Les dents sont dessinées à pas constant, et la roue menée tourne à
/// l'exacte vitesse que lui impose ce pas : ce qu'on voit à l'écran est
/// bien le mouvement que donnerait l'objet réel, pas une approximation
/// décorative.
class GearsFigure extends StatefulWidget {
  const GearsFigure({required this.accent, super.key});

  final Color accent;

  /// Nombre de dents de la roue menante, celle qu'on entraîne.
  static const int dentsMenante = 12;

  /// Rapport de transmission : nombre de tours de la roue menée pour un
  /// tour de la menante.
  ///
  /// C'est le rapport des nombres de dents, et rien d'autre : le diamètre
  /// s'en déduit, il n'intervient pas.
  static double rapport(int dentsMenante, int dentsMenee) =>
      dentsMenante / dentsMenee;

  /// Deux roues en prise tournent toujours en sens contraire.
  ///
  /// Dans une chaîne de roues, le sens s'inverse à chaque contact : la
  /// dernière tourne donc comme la première si le nombre de roues est
  /// impair.
  static bool memeSens(int nombreDeRoues) => nombreDeRoues.isOdd;

  @override
  State<GearsFigure> createState() => _GearsFigureState();
}

class _GearsFigureState extends State<GearsFigure>
    with SingleTickerProviderStateMixin {
  int _dentsMenee = 24;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..addListener(() => setState(() {}));

  bool _demarrageFait = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _basculer() {
    context.tapFeedback();
    if (_controller.isAnimating) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
    setState(() {});
  }

  String _n(double v) =>
      NumericQuestion.formatNumber((v * 100).roundToDouble() / 100);

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;

    if (!_demarrageFait) {
      _demarrageFait = true;
      if (!context.reduceMotion) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _controller.repeat();
        });
      }
    }

    // Deux tours de la roue menante par cycle d'animation : assez pour
    // voir les compteurs se décaler, assez lent pour suivre une dent.
    final double toursMenante = _controller.value * 2;
    // Le nombre de dents de la menée change par paliers : on voit le
    // rapport passer de la démultiplication à la multiplication, et les
    // deux compteurs se décaler d'autant. Un balayage continu ferait
    // sauter les dents, ce qui n'a aucun sens mécanique.
    final int? palier = Autoplay.sweepEntier(context, min: 3, max: 12);
    final int dentsMenee = _tenue || palier == null
        ? _dentsMenee
        : palier * 2;
    final double rapport = GearsFigure.rapport(
      GearsFigure.dentsMenante,
      dentsMenee,
    );
    final double toursMenee = toursMenante * rapport;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 200,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, 200),
                painter: _EngrenagePainter(
                  toursMenante: toursMenante,
                  dentsMenante: GearsFigure.dentsMenante,
                  dentsMenee: dentsMenee,
                  accent: widget.accent,
                  second: tokens.inkMuted,
                  trait: tokens.border,
                  surface: context.colors.surface,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            _Compteur(
              nom: 'menante · ${GearsFigure.dentsMenante} dents',
              valeur: '${_n(toursMenante)} tour${toursMenante >= 2 ? 's' : ''}',
              couleur: widget.accent,
            ),
            _Compteur(
              nom: 'menée · $dentsMenee dents',
              valeur: '${_n(toursMenee)} tour${toursMenee >= 2 ? 's' : ''}',
              couleur: tokens.inkMuted,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Un tour de la menante : ${_n(rapport)} tour'
          '${rapport >= 2 ? 's' : ''} de la menée, en sens inverse.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: widget.accent),
        ),
        Row(
          children: <Widget>[
            IconButton(
              tooltip: _controller.isAnimating ? 'Arrêter' : 'Tourner',
              onPressed: _basculer,
              icon: Icon(
                _controller.isAnimating
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: widget.accent,
              ),
            ),
            Expanded(
              child: Slider(
                value: dentsMenee.toDouble(),
                min: 6,
                max: 24,
                divisions: 9,
                // Pas d'infobulle : le nombre de dents est déjà écrit
                // sous la roue menée, et la bulle recouvrait la phrase
                // qui donne le rapport.
                onChanged: (double v) => setState(() {
                  _tenue = true;
                  _dentsMenee = (v / 2).round() * 2;
                }),
              ),
            ),
          ],
        ),
        Text(
          'Change le nombre de dents de la roue menée',
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

class _Compteur extends StatelessWidget {
  const _Compteur({
    required this.nom,
    required this.valeur,
    required this.couleur,
  });

  final String nom;
  final String valeur;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(valeur, style: AppTypography.formula(size: 18, color: couleur)),
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

class _EngrenagePainter extends CustomPainter {
  const _EngrenagePainter({
    required this.toursMenante,
    required this.dentsMenante,
    required this.dentsMenee,
    required this.accent,
    required this.second,
    required this.trait,
    required this.surface,
  });

  final double toursMenante;
  final int dentsMenante;
  final int dentsMenee;
  final Color accent;
  final Color second;
  final Color trait;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    // Même pas de denture pour les deux roues, sans quoi elles ne
    // pourraient pas s'engrener : le rayon est donc proportionnel au
    // nombre de dents.
    const double marge = 10;
    final double largeurUtile = size.width - marge * 2;
    final int total = dentsMenante + dentsMenee;
    // Le module se règle sur la place disponible, en largeur comme en
    // hauteur : la plus grande roue doit tenir dans les deux sens.
    final double moduleLargeur = largeurUtile / total;
    final double moduleHauteur =
        (size.height - marge * 2) / math.max(dentsMenante, dentsMenee);
    final double module = math.min(moduleLargeur, moduleHauteur);

    final double rayonA = module * dentsMenante / 2;
    final double rayonB = module * dentsMenee / 2;
    final double y = size.height / 2;
    final double gauche = (size.width - (rayonA + rayonB) * 2) / 2;
    final Offset centreA = Offset(gauche + rayonA, y);
    final Offset centreB = Offset(gauche + rayonA * 2 + rayonB, y);

    final double angleA = toursMenante * 2 * math.pi;
    // Condition de roulement sans glissement : les arcs parcourus sont
    // égaux, donc les angles sont inversement proportionnels aux dents.
    final double angleB = -angleA * dentsMenante / dentsMenee;

    _roue(canvas, centreA, rayonA, dentsMenante, angleA, 0, accent);
    // La menée est décalée d'un demi-pas : un creux lui fait face là où
    // la menante présente une dent. C'est cet alignement qui rend le
    // contact crédible à l'œil.
    _roue(
      canvas,
      centreB,
      rayonB,
      dentsMenee,
      angleB,
      math.pi - math.pi / dentsMenee,
      second,
    );
  }

  void _roue(
    Canvas canvas,
    Offset centre,
    double rayon,
    int dents,
    double angle,
    double decalage,
    Color couleur,
  ) {
    final double hauteurDent = rayon * 0.14;
    final double corps = rayon - hauteurDent;

    // Les dents d'abord, pour que le corps les recouvre à leur base.
    // La dent occupe un peu moins de la moitié du pas : au-delà, elle
    // ne tiendrait plus dans le creux de l'autre roue, et le dessin
    // montrerait un engrènement impossible.
    final double demiDent = math.pi / dents * 0.46;
    for (int i = 0; i < dents; i++) {
      final double a = angle + decalage + i * 2 * math.pi / dents;
      final Path dent = Path();
      final List<Offset> sommets = <Offset>[
        centre + Offset(math.cos(a - demiDent), math.sin(a - demiDent)) * corps,
        centre +
            Offset(math.cos(a - demiDent * 0.55), math.sin(a - demiDent * 0.55)) *
                rayon,
        centre +
            Offset(math.cos(a + demiDent * 0.55), math.sin(a + demiDent * 0.55)) *
                rayon,
        centre + Offset(math.cos(a + demiDent), math.sin(a + demiDent)) * corps,
      ];
      dent.addPolygon(sommets, true);
      canvas.drawPath(dent, Paint()..color = couleur);
    }

    canvas.drawCircle(centre, corps, Paint()..color = couleur);
    canvas.drawCircle(centre, corps * 0.32, Paint()..color = surface);
    canvas.drawCircle(
      centre,
      corps * 0.32,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = trait,
    );

    // Un rayon marqué : sans lui, une roue qui tourne a l'air immobile.
    canvas.drawLine(
      centre + Offset(math.cos(angle), math.sin(angle)) * (corps * 0.32),
      centre + Offset(math.cos(angle), math.sin(angle)) * (corps * 0.92),
      Paint()
        ..color = surface
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_EngrenagePainter old) =>
      old.toursMenante != toursMenante ||
      old.dentsMenee != dentsMenee ||
      old.accent != accent;
}
