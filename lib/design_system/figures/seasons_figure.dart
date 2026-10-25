/// Les saisons, expliquées par l'inclinaison de l'axe.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// La Terre sur son orbite, axe penché, et la durée du jour qui suit.
///
/// La cause des saisons est l'une des erreurs les mieux partagées :
/// presque tout le monde répond « la Terre est plus proche du Soleil en
/// été ». La figure rend cette réponse intenable en montrant deux
/// choses à la fois — l'axe garde la même direction tout au long de
/// l'année, et les deux hémisphères ont des saisons opposées au même
/// instant. Une distance ne pourrait pas produire cela.
///
/// L'orbite est dessinée presque circulaire, parce qu'elle l'est : son
/// excentricité réelle ne se verrait pas à l'œil. Une orbite très
/// allongée, comme on en voit souvent dans les manuels, installe
/// précisément l'erreur qu'il faut défaire.
class SeasonsFigure extends StatefulWidget {
  const SeasonsFigure({required this.accent, super.key});

  final Color accent;

  /// Inclinaison de l'axe de rotation, en degrés.
  static const double inclinaison = 23.44;

  /// Latitude de référence pour la durée du jour : celle de Paris.
  static const double latitudeParis = 48.85;

  /// Instant du solstice de juin, en mois écoulés depuis le 1er janvier.
  ///
  /// Le 21 juin tombe à 5,69 mois : c'est sur lui que tout le modèle
  /// s'accroche, et non sur un début de mois commode. Avec un calage
  /// approximatif, les équinoxes tombaient à côté et le jour n'y durait
  /// pas douze heures — ce que le chapitre affirme pourtant.
  static const double solsticeJuin = 5.69;

  /// Déclinaison du Soleil au mois donné, en degrés.
  ///
  /// C'est la latitude où le Soleil passe au zénith à midi : positive
  /// quand il éclaire davantage l'hémisphère nord.
  static double declinaison(double mois) =>
      inclinaison * math.cos(2 * math.pi * (mois - solsticeJuin) / 12);

  /// Durée du jour, en heures, à une latitude donnée.
  ///
  /// Issue de l'angle horaire du coucher : cos H = −tan φ × tan δ. Les
  /// cas où le Soleil ne se couche pas, ou ne se lève pas, sortent de
  /// l'intervalle et sont ramenés à vingt-quatre ou zéro heure.
  static double dureeDuJour(double mois, {double latitude = latitudeParis}) {
    final double phi = latitude * math.pi / 180;
    final double delta = declinaison(mois) * math.pi / 180;
    final double cosH = -math.tan(phi) * math.tan(delta);
    if (cosH <= -1) return 24;
    if (cosH >= 1) return 0;
    return 24 * math.acos(cosH) / math.pi;
  }

  /// Saison dans l'hémisphère nord, au mois donné.
  ///
  /// Les bornes sont les équinoxes et les solstices, pas les débuts de
  /// mois : le printemps commence le 21 mars, pas le 1er avril.
  static String saisonNord(double mois) {
    final double m = mois % 12;
    const double equinoxePrintemps = solsticeJuin - 3;
    const double equinoxeAutomne = solsticeJuin + 3;
    const double solsticeDecembre = solsticeJuin + 6;
    if (m < equinoxePrintemps || m >= solsticeDecembre) return 'hiver';
    if (m < solsticeJuin) return 'printemps';
    if (m < equinoxeAutomne) return 'été';
    return 'automne';
  }

  /// Saison dans l'hémisphère sud : toujours l'opposée.
  static String saisonSud(double mois) => switch (saisonNord(mois)) {
    'hiver' => 'été',
    'printemps' => 'automne',
    'été' => 'hiver',
    _ => 'printemps',
  };

  static const List<String> mois = <String>[
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  @override
  State<SeasonsFigure> createState() => _SeasonsFigureState();
}

class _SeasonsFigureState extends State<SeasonsFigure> {
  double _mois = 6;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // L'année défile en entier : l'axe garde son inclinaison, la durée
    // du jour s'allonge puis se raccourcit, et les deux hémisphères sont
    // toujours en saison opposée. C'est l'année vue d'un coup.
    final double mois = _tenue
        ? _mois
        : Autoplay.sweep(context, min: 0, max: 11.99) ?? _mois;
    final double duree = SeasonsFigure.dureeDuJour(mois);
    final int heures = duree.floor();
    final int minutes = ((duree - heures) * 60).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.15,
          child: CustomPaint(
            painter: _SaisonsPainter(
              mois: mois,
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
          'En ${SeasonsFigure.mois[mois.floor() % 12]} · '
          '${SeasonsFigure.saisonNord(mois)} au nord, '
          '${SeasonsFigure.saisonSud(mois)} au sud',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 16, color: widget.accent),
        ),
        Text(
          'Durée du jour à Paris : $heures h '
          '${minutes.toString().padLeft(2, '0')}  ·  '
          'Soleil au zénith à '
          '${NumericQuestion.formatNumber(
            (SeasonsFigure.declinaison(mois) * 10).roundToDouble() / 10,
          )}° de latitude',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        Slider(
          value: mois,
          max: 12,
          divisions: 24,
          onChanged: (double v) {
            context.tapFeedback();
            setState(() {
              _tenue = true;
              _mois = v;
            });
          },
        ),
        Text(
          'Fais passer l\'année : l\'axe ne change jamais de direction',
          textAlign: TextAlign.center,
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

class _SaisonsPainter extends CustomPainter {
  const _SaisonsPainter({
    required this.mois,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final double mois;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color surface;

  static const Color _soleil = Color(0xFFF5A524);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset soleil = Offset(size.width / 2, size.height / 2);
    final double rayonOrbite =
        math.min(size.width, size.height) * 0.33;

    // L'orbite est vue de biais : son tracé doit être l'ellipse sur
    // laquelle les positions tombent, sinon les Terres flotteraient à
    // côté du chemin qu'elles sont censées suivre.
    canvas.drawOval(
      Rect.fromCenter(
        center: soleil,
        width: rayonOrbite * 2,
        height: rayonOrbite * 2 * 0.62,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = trait,
    );
    canvas.drawCircle(soleil, 16, Paint()..color = _soleil);

    // Les quatre positions remarquables, dessinées en pâle : on voit du
    // même coup que l'axe pointe toujours dans la même direction.
    for (int quart = 0; quart < 4; quart++) {
      _terre(
        canvas,
        _position(soleil, rayonOrbite, SeasonsFigure.solsticeJuin + quart * 3),
        11,
        soleil,
        pale: true,
      );
    }

    final Offset terre = _position(soleil, rayonOrbite, mois);
    _terre(canvas, terre, 20, soleil);

    // Les rayons qui vont du Soleil à la Terre : ils arrivent toujours
    // perpendiculaires à l'orbite, et c'est l'axe penché qui fait la
    // différence.
    final Offset direction = (terre - soleil) / (terre - soleil).distance;
    canvas.drawLine(
      soleil + direction * 18,
      terre - direction * 24,
      Paint()
        ..color = _soleil.withValues(alpha: 0.6)
        ..strokeWidth = 1.5,
    );

    // Les deux solstices, nommés à l'extérieur de l'orbite pour ne pas
    // tomber sur la Terre elle-même.
    _texte(canvas, 'juin', _position(soleil, rayonOrbite, SeasonsFigure.solsticeJuin) +
        const Offset(0, 46), muted);
    _texte(canvas, 'décembre', _position(soleil, rayonOrbite, SeasonsFigure.solsticeJuin + 6) +
        const Offset(0, 46), muted);
  }

  Offset _position(Offset centre, double rayon, double mois) {
    // Juin à droite, décembre à gauche : l'axe penche vers la droite,
    // donc l'hémisphère nord est éclairé quand la Terre est à droite.
    final double angle =
        2 * math.pi * (mois - SeasonsFigure.solsticeJuin) / 12;
    return centre + Offset(math.cos(angle), math.sin(angle) * 0.62) * rayon;
  }

  /// La Terre, son axe penché et sa moitié dans l'ombre.
  void _terre(
    Canvas canvas,
    Offset centre,
    double rayon,
    Offset soleil, {
    bool pale = false,
  }) {
    final double alpha = pale ? 0.3 : 1;
    canvas.drawCircle(
      centre,
      rayon,
      Paint()..color = accent.withValues(alpha: 0.85 * alpha),
    );

    // La moitié opposée au Soleil est dans la nuit.
    final Offset vers = (centre - soleil) / (centre - soleil).distance;
    final double angle = math.atan2(vers.dy, vers.dx);
    canvas.drawPath(
      Path()
        ..addArc(
          Rect.fromCircle(center: centre, radius: rayon),
          angle - math.pi / 2,
          math.pi,
        )
        ..close(),
      Paint()..color = const Color(0xFF1B2038).withValues(alpha: 0.55 * alpha),
    );

    // L'axe, toujours incliné dans la même direction.
    const double theta =
        (90 - SeasonsFigure.inclinaison) * math.pi / 180;
    // L'axe penche vers la gauche du dessin : la Terre de juin étant
    // placée à droite du Soleil, son pôle nord se trouve ainsi incliné
    // vers lui, ce qui est bien la configuration de l'été boréal. Avec
    // l'inclinaison opposée, la figure annonçait juin tout en dessinant
    // décembre.
    final Offset axe = Offset(-math.cos(theta), -math.sin(theta));
    canvas.drawLine(
      centre - axe * (rayon * 1.35),
      centre + axe * (rayon * 1.35),
      Paint()
        ..color = ink.withValues(alpha: 0.8 * alpha)
        ..strokeWidth = pale ? 1.2 : 2
        ..strokeCap = StrokeCap.round,
    );
    if (!pale) {
      canvas.drawCircle(
        centre + axe * (rayon * 1.35),
        3,
        Paint()..color = surface,
      );
      _texte(canvas, 'N', centre + axe * (rayon * 2.1), muted);
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
  bool shouldRepaint(_SaisonsPainter old) =>
      old.mois != mois || old.accent != accent;
}
