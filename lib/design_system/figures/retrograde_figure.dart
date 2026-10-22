/// La boucle de Mars : ce que le géocentrisme n'expliquait pas.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Un point du relevé : la date, et la direction où l'on voit Mars.
typedef PointDuCiel = ({double annees, double longitude});

/// Mars vue depuis la Terre, pendant que les deux tournent autour du
/// Soleil.
///
/// Pendant quelques semaines, tous les deux ans environ, Mars semble
/// s'arrêter puis reculer dans le ciel avant de repartir. C'est
/// l'observation qui a tenu les astronomes en échec pendant quinze
/// siècles : pour la rendre, le modèle géocentrique devait ajouter des
/// cercles sur les cercles.
///
/// Ici, il n'y a aucun cercle supplémentaire : deux planètes sur deux
/// orbites, et la Terre qui dépasse Mars par l'intérieur. Le recul
/// apparent sort du calcul tout seul, et c'est exactement l'argument de
/// Copernic — non pas que son modèle soit plus simple à croire, mais
/// qu'il n'a rien à ajouter pour rendre ce qu'on voit.
class RetrogradeFigure extends StatefulWidget {
  const RetrogradeFigure({required this.accent, super.key});

  final Color accent;

  /// Durée d'un tour, en années terrestres.
  static const double periodeTerre = 1;
  static const double periodeMars = 1.8808;

  /// Rayon de l'orbite, en unités astronomiques.
  static const double rayonTerre = 1;
  static const double rayonMars = 1.5237;

  /// Durée que met la Terre pour reprendre un tour d'avance sur Mars.
  ///
  /// C'est l'intervalle entre deux reculs apparents : la Terre doit
  /// rattraper puis dépasser Mars.
  static double get periodeSynodique =>
      1 / (1 / periodeTerre - 1 / periodeMars);

  static ({double x, double y}) _position(
    double annees,
    double rayon,
    double periode,
  ) {
    final double a = 2 * math.pi * annees / periode;
    return (x: rayon * math.cos(a), y: rayon * math.sin(a));
  }

  /// Position de la Terre sur son orbite, en unités astronomiques.
  static ({double x, double y}) terre(double annees) =>
      _position(annees, rayonTerre, periodeTerre);

  /// Position de Mars sur son orbite.
  static ({double x, double y}) mars(double annees) =>
      _position(annees, rayonMars, periodeMars);

  /// Direction dans laquelle on voit Mars depuis la Terre, en degrés.
  ///
  /// C'est la seule chose qu'un observateur mesure : un angle dans le
  /// ciel. Les distances, il ne les connaît pas.
  static double longitudeApparente(double annees) {
    final ({double x, double y}) t = terre(annees);
    final ({double x, double y}) m = mars(annees);
    return math.atan2(m.y - t.y, m.x - t.x) * 180 / math.pi;
  }

  /// `true` si Mars recule dans le ciel à cette date.
  static bool recule(double annees) {
    const double h = 0.001;
    return _ecart(
          longitudeApparente(annees - h),
          longitudeApparente(annees + h),
        ) <
        0;
  }

  /// Écart entre deux longitudes, ramené dans ]-180°, 180°].
  ///
  /// Sans ce repli, le passage de 359° à 1° compterait pour un recul de
  /// 358 degrés.
  static double _ecart(double avant, double apres) {
    double d = apres - avant;
    while (d > 180) {
      d -= 360;
    }
    while (d <= -180) {
      d += 360;
    }
    return d;
  }

  /// Relevé des directions successives, déplié.
  ///
  /// Un observateur note un angle entre 0° et 360° ; pour tracer une
  /// courbe lisible, on cumule les écarts plutôt que de repartir à zéro
  /// à chaque tour de ciel.
  static List<PointDuCiel> releve(double duree, {int points = 400}) {
    final List<PointDuCiel> trace = <PointDuCiel>[];
    double cumul = longitudeApparente(0);
    double precedent = cumul;
    trace.add((annees: 0, longitude: cumul));
    for (int i = 1; i <= points; i++) {
      final double t = duree * i / points;
      final double brut = longitudeApparente(t);
      cumul += _ecart(precedent, brut);
      precedent = brut;
      trace.add((annees: t, longitude: cumul));
    }
    return trace;
  }

  @override
  State<RetrogradeFigure> createState() => _RetrogradeFigureState();
}

class _RetrogradeFigureState extends State<RetrogradeFigure>
    with SingleTickerProviderStateMixin {
  /// Deux reculs entiers tiennent dans cette durée.
  static const double _duree = 4.4;

  late final List<PointDuCiel> _trace = RetrogradeFigure.releve(_duree);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
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

    final double t = _controller.value * _duree;
    final bool recule = RetrogradeFigure.recule(t);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 0.92,
          child: CustomPaint(
            painter: _CielPainter(
              instant: t,
              duree: _duree,
              trace: _trace,
              accent: widget.accent,
              ink: context.colors.onSurface,
              trait: tokens.border,
              muted: tokens.inkMuted,
              alerte: tokens.error,
              surface: context.colors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          recule ? 'Mars recule dans le ciel' : 'Mars avance dans le ciel',
          style: AppTypography.formula(
            size: 17,
            color: recule ? tokens.error : widget.accent,
          ),
        ),
        Text(
          'après ${NumericQuestion.formatNumber((t * 12).roundToDouble())} mois',
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
          'Fais avancer le temps et suis la trace à droite',
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

class _CielPainter extends CustomPainter {
  const _CielPainter({
    required this.instant,
    required this.duree,
    required this.trace,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.alerte,
    required this.surface,
  });

  final double instant;
  final double duree;
  final List<PointDuCiel> trace;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color alerte;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    // Les orbites en haut, le relevé du ciel en bas : la cause, puis ce
    // qu'on en voit.
    final double hautOrbites = size.height * 0.56;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, hautOrbites));
    _orbites(canvas, Rect.fromLTWH(0, 0, size.width, hautOrbites));
    canvas.restore();
    _releve(
      canvas,
      Rect.fromLTWH(0, hautOrbites, size.width, size.height - hautOrbites),
    );
  }

  void _orbites(Canvas canvas, Rect zone) {
    final double echelle =
        math.min(zone.width, zone.height) * 0.46 / RetrogradeFigure.rayonMars;
    final Offset soleil = Offset(zone.center.dx, zone.center.dy);

    Offset p(({double x, double y}) v) =>
        soleil + Offset(v.x * echelle, v.y * echelle);

    for (final double rayon in <double>[
      RetrogradeFigure.rayonTerre,
      RetrogradeFigure.rayonMars,
    ]) {
      canvas.drawCircle(
        soleil,
        rayon * echelle,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = trait,
      );
    }

    final Offset terre = p(RetrogradeFigure.terre(instant));
    final Offset mars = p(RetrogradeFigure.mars(instant));

    // La ligne de visée, prolongée : c'est elle qui pointe l'endroit du
    // ciel où Mars apparaît.
    final Offset direction = (mars - terre) / (mars - terre).distance;
    canvas.drawLine(
      terre,
      terre + direction * (zone.width + zone.height),
      Paint()
        ..color = accent.withValues(alpha: 0.35)
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(soleil, 9, Paint()..color = const Color(0xFFF5A524));
    canvas.drawCircle(terre, 6, Paint()..color = accent);
    canvas.drawCircle(mars, 6, Paint()..color = alerte);
    _texte(canvas, 'Terre', terre + const Offset(0, -16), accent);
    _texte(canvas, 'Mars', mars + const Offset(0, -16), alerte);
  }

  /// Le relevé : la direction observée, semaine après semaine.
  ///
  /// On n'affiche que les derniers mois. Sur quatre ans, Mars fait plus
  /// de deux tours de ciel et son recul — seize degrés — disparaîtrait
  /// dans l'épaisseur du trait : c'est d'ailleurs pourquoi il a fallu
  /// des relevés patients pour le mettre en évidence.
  void _releve(Canvas canvas, Rect zone) {
    const double marge = 26;
    const double fenetre = 0.55;
    final Rect cadre = Rect.fromLTRB(
      zone.left + marge,
      zone.top + 18,
      zone.right - marge * 0.5,
      zone.bottom - 16,
    );

    final double debut = math.max(0, instant - fenetre);
    final double fin = math.max(instant, 0.12);
    final List<PointDuCiel> vus = <PointDuCiel>[
      for (final PointDuCiel point in trace)
        if (point.annees >= debut && point.annees <= fin) point,
    ];
    if (vus.length < 2) return;

    double minLong = vus.first.longitude;
    double maxLong = vus.first.longitude;
    for (final PointDuCiel point in vus) {
      minLong = math.min(minLong, point.longitude);
      maxLong = math.max(maxLong, point.longitude);
    }
    final double etendue = math.max(maxLong - minLong, 1);

    Offset p(PointDuCiel point) => Offset(
      cadre.left + cadre.width * (point.longitude - minLong) / etendue,
      // Le temps monte : la courbe se construit de bas en haut, comme
      // une frise qu'on remplit en avançant.
      cadre.bottom - cadre.height * (point.annees - debut) / (fin - debut),
    );

    canvas.drawRect(cadre, Paint()..color = surface);
    canvas.drawRect(
      cadre,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = trait,
    );

    // Segment par segment : rouge là où Mars revient en arrière.
    for (int i = 1; i < vus.length; i++) {
      final bool arriere = vus[i].longitude < vus[i - 1].longitude;
      canvas.drawLine(
        p(vus[i - 1]),
        p(vus[i]),
        Paint()
          ..color = arriere ? alerte : accent
          ..strokeWidth = arriere ? 5 : 3
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(p(vus.last), 5, Paint()..color = ink);

    _texte(
      canvas,
      'direction observée dans le ciel',
      Offset(cadre.center.dx, zone.top + 8),
      muted,
    );
    canvas.save();
    canvas.translate(zone.left + 10, cadre.center.dy);
    canvas.rotate(-math.pi / 2);
    _texte(canvas, 'les six derniers mois', Offset.zero, muted);
    canvas.restore();
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
  bool shouldRepaint(_CielPainter old) =>
      old.instant != instant || old.accent != accent;
}
