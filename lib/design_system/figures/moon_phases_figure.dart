/// Les phases de la Lune, vues d'en haut et vues d'ici.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// La Lune autour de la Terre, et ce qu'on en voit depuis le sol.
///
/// Deux dessins côte à côte, parce que la difficulté est exactement là :
/// la moitié éclairée de la Lune ne change jamais — c'est toujours celle
/// qui fait face au Soleil — et pourtant ce qu'on voit d'ici change tous
/// les soirs. Tant qu'on ne met pas les deux images ensemble, la phase
/// reste une liste de noms à apprendre.
///
/// L'ombre de la Terre n'intervient nulle part dans ce dessin. C'est
/// voulu : croire que les phases viennent de cette ombre est l'erreur la
/// plus répandue, et la figure doit rendre cette explication impossible
/// plutôt que de la démentir par une phrase.
class MoonPhasesFigure extends StatefulWidget {
  const MoonPhasesFigure({required this.accent, super.key});

  final Color accent;

  /// Durée d'une lunaison, en jours : d'une nouvelle lune à la suivante.
  static const double periode = 29.53;

  /// Part du disque lunaire éclairée, vue depuis la Terre, entre 0 et 1.
  static double fractionEclairee(double jours) {
    final double phase = 2 * math.pi * jours / periode;
    return (1 - math.cos(phase)) / 2;
  }

  /// `true` si la Lune grossit de soir en soir.
  static bool croissante(double jours) {
    final double t = jours % periode;
    return t < periode / 2;
  }

  /// Les huit phases traditionnelles, dans l'ordre.
  static const List<String> phases = <String>[
    'Nouvelle Lune',
    'Premier croissant',
    'Premier quartier',
    'Gibbeuse croissante',
    'Pleine Lune',
    'Gibbeuse décroissante',
    'Dernier quartier',
    'Dernier croissant',
  ];

  /// Nom de la phase à ce jour de la lunaison.
  ///
  /// Les quatre phases remarquables — nouvelle lune, quartiers, pleine
  /// lune — sont des instants, pas des périodes : on ne leur accorde
  /// qu'un jour et demi environ. Les croissants et les gibbeuses occupent
  /// tout le reste, soit cinq jours chacun. Donner huit tranches égales
  /// ferait annoncer « premier quartier » devant un disque éclairé au
  /// tiers.
  static String nomDePhase(double jours) {
    final double f = (jours % periode) / periode;
    if (f < 0.035 || f >= 0.965) return phases[0];
    if (f < 0.23) return phases[1];
    if (f < 0.27) return phases[2];
    if (f < 0.465) return phases[3];
    if (f < 0.535) return phases[4];
    if (f < 0.73) return phases[5];
    if (f < 0.77) return phases[6];
    return phases[7];
  }

  @override
  State<MoonPhasesFigure> createState() => _MoonPhasesFigureState();
}

class _MoonPhasesFigureState extends State<MoonPhasesFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
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

    final double jours = _controller.value * MoonPhasesFigure.periode;
    final double fraction = MoonPhasesFigure.fractionEclairee(jours);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.05,
          child: CustomPaint(
            painter: _LunePainter(
              jours: jours,
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
          MoonPhasesFigure.nomDePhase(jours),
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          'jour ${NumericQuestion.formatNumber(jours.roundToDouble())} '
          'de la lunaison · '
          '${NumericQuestion.formatNumber((fraction * 100).roundToDouble())} % '
          'du disque éclairé',
          textAlign: TextAlign.center,
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
        Row(
          children: <Widget>[
            IconButton(
              tooltip: _controller.isAnimating ? 'Arrêter' : 'Lancer',
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
                value: _controller.value,
                onChanged: (double v) {
                  _controller.stop();
                  setState(() => _controller.value = v);
                },
              ),
            ),
          ],
        ),
        Text(
          'Fais tourner la Lune autour de la Terre',
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

class _LunePainter extends CustomPainter {
  const _LunePainter({
    required this.jours,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final double jours;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color surface;

  static const Color _soleil = Color(0xFFF5A524);
  static const Color _eclaire = Color(0xFFF2E9D8);

  @override
  void paint(Canvas canvas, Size size) {
    final double hautVueDessus = size.height * 0.62;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, hautVueDessus));
    _vueDeDessus(canvas, Rect.fromLTWH(0, 0, size.width, hautVueDessus));
    canvas.restore();
    _vueDIci(
      canvas,
      Rect.fromLTWH(
        0,
        hautVueDessus,
        size.width,
        size.height - hautVueDessus,
      ),
    );
  }

  /// La scène vue d'en haut : le Soleil à gauche, la Terre, la Lune sur
  /// son orbite, et la moitié éclairée qui regarde toujours le Soleil.
  void _vueDeDessus(Canvas canvas, Rect zone) {
    final double phase = 2 * math.pi * jours / MoonPhasesFigure.periode;
    final Offset terre = Offset(zone.center.dx + zone.width * 0.08,
        zone.center.dy);
    final double orbite = math.min(zone.width * 0.30, zone.height * 0.38);

    // Les rayons du Soleil, venus de la gauche et parallèles.
    final Paint rayon = Paint()
      ..color = _soleil.withValues(alpha: 0.55)
      ..strokeWidth = 1.5;
    for (int i = -2; i <= 2; i++) {
      final double y = terre.dy + i * orbite * 0.5;
      canvas.drawLine(Offset(zone.left + 4, y), Offset(terre.dx - orbite * 1.5, y), rayon);
      canvas.drawLine(
        Offset(terre.dx - orbite * 1.5, y),
        Offset(terre.dx - orbite * 1.5 - 7, y - 3),
        rayon,
      );
      canvas.drawLine(
        Offset(terre.dx - orbite * 1.5, y),
        Offset(terre.dx - orbite * 1.5 - 7, y + 3),
        rayon,
      );
    }
    _texte(canvas, 'lumière du Soleil', Offset(zone.left + 54, zone.top + 12),
        muted);

    canvas.drawCircle(
      terre,
      orbite,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = trait,
    );
    canvas.drawCircle(terre, 13, Paint()..color = accent);
    _texte(canvas, 'Terre', terre + const Offset(0, 24), muted);

    // À la nouvelle lune, la Lune est du côté du Soleil ; à la pleine
    // lune, de l'autre côté.
    final Offset lune =
        terre + Offset(-math.cos(phase), math.sin(phase)) * orbite;
    const double rayonLune = 13;
    canvas.drawCircle(lune, rayonLune, Paint()..color = ink.withValues(alpha: 0.55));
    // La moitié tournée vers le Soleil, toujours la même : un demi-disque
    // à gauche, quelle que soit la position sur l'orbite.
    canvas.drawPath(
      Path()
        ..addArc(
          Rect.fromCircle(center: lune, radius: rayonLune),
          math.pi / 2,
          math.pi,
        )
        ..close(),
      Paint()..color = _eclaire,
    );
    canvas.drawCircle(
      lune,
      rayonLune,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = trait,
    );

    // La ligne de regard, depuis la Terre vers la Lune.
    canvas.drawLine(
      terre,
      lune,
      Paint()
        ..color = accent.withValues(alpha: 0.3)
        ..strokeWidth = 1.2,
    );
  }

  /// Ce qu'on voit depuis la Terre : le disque, et sa part éclairée.
  void _vueDIci(Canvas canvas, Rect zone) {
    final double phase = 2 * math.pi * jours / MoonPhasesFigure.periode;
    final double rayon = math.min(zone.height * 0.40, zone.width * 0.16);
    final Offset centre = Offset(zone.center.dx, zone.top + zone.height * 0.47);

    canvas.drawCircle(centre, rayon + 7, Paint()..color = const Color(0xFF1B2038));
    canvas.drawCircle(centre, rayon, Paint()..color = ink.withValues(alpha: 0.5));

    // La partie éclairée : tous les points du disque situés du bon côté
    // du terminateur, lequel se projette en demi-ellipse.
    final double cosPhase = math.cos(phase);
    final bool droite = math.sin(phase) >= 0;
    final Path eclairee = Path();
    const int pas = 48;
    for (int i = 0; i <= pas; i++) {
      final double y = -rayon + 2 * rayon * i / pas;
      final double demiLargeur = math.sqrt(math.max(0, rayon * rayon - y * y));
      final double x = cosPhase * demiLargeur * (droite ? 1 : -1);
      final Offset p = centre + Offset(x, y);
      i == 0 ? eclairee.moveTo(p.dx, p.dy) : eclairee.lineTo(p.dx, p.dy);
    }
    for (int i = pas; i >= 0; i--) {
      final double y = -rayon + 2 * rayon * i / pas;
      final double demiLargeur = math.sqrt(math.max(0, rayon * rayon - y * y));
      final Offset p = centre + Offset(droite ? demiLargeur : -demiLargeur, y);
      eclairee.lineTo(p.dx, p.dy);
    }
    eclairee.close();
    canvas.drawPath(eclairee, Paint()..color = _eclaire);

    // Sous le disque, jamais dessus : le libellé se posait sur la Lune
    // dès que la place verticale était généreuse.
    _texte(
      canvas,
      'vue depuis la Terre',
      Offset(
        zone.center.dx,
        math.min(centre.dy + rayon + 16, zone.bottom - 8),
      ),
      muted,
    );
  }

  void _texte(Canvas canvas, String texte, Offset centre, Color couleur) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
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
  bool shouldRepaint(_LunePainter old) =>
      old.jours != jours || old.accent != accent;
}
