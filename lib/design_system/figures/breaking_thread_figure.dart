/// Un objet pendu à un fil, et le fil qui finit par céder.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Un objet suspendu dont l'élève règle la masse, jusqu'à la rupture.
///
/// Cette figure existe parce qu'une phrase comme « le poids est une force
/// proportionnelle à la masse » ne produit aucune image. Un élève la relit,
/// la recopie, et ne saura pas prévoir ce qui arrive si l'on double la
/// masse.
///
/// Ici il le fait. Il pousse le curseur, voit le fil s'allonger, voit la
/// flèche du poids grandir, et à un moment précis — qu'il peut approcher
/// gramme par gramme — le fil cède et l'objet tombe pour de bon, en
/// accélérant. La valeur de rupture n'est pas écrite dans le cours : elle
/// se découvre en poussant.
///
/// Le fil se comporte comme un ressort tant qu'il tient : son allongement
/// est proportionnel à la tension, ce qui donne au curseur un retour visuel
/// continu avant l'événement. Sans cet allongement, la figure serait
/// immobile jusqu'à la rupture, et l'élève ne verrait pas venir.
class BreakingThreadFigure extends StatefulWidget {
  const BreakingThreadFigure({required this.accent, super.key});

  final Color accent;

  /// Pesanteur terrestre, en newtons par kilogramme.
  static const double pesanteur = 9.8;

  /// Ce que le fil supporte avant de céder, en newtons.
  ///
  /// Cinquante newtons placent la rupture à 5,1 kg, donc au milieu de la
  /// course du curseur : l'élève peut l'approcher des deux côtés.
  static const double chargeDeRupture = 50;

  /// Masse maximale réglable, en kilogrammes.
  static const double masseMax = 10;

  /// Le poids d'une masse, en newtons.
  static double poids(double masseKg) => masseKg * pesanteur;

  /// La masse exacte à laquelle le fil cède, en kilogrammes.
  static double masseDeRupture() => chargeDeRupture / pesanteur;

  /// `true` si le fil cède sous cette masse.
  static bool casse(double masseKg) => poids(masseKg) > chargeDeRupture;

  /// Allongement du fil, de 0 à 1, pour une masse donnée.
  ///
  /// Proportionnel à la tension, comme un ressort, et plafonné à 1 juste
  /// avant la rupture.
  static double allongement(double masseKg) {
    final double fraction = poids(masseKg) / chargeDeRupture;
    return fraction.clamp(0.0, 1.0);
  }

  @override
  State<BreakingThreadFigure> createState() => _BreakingThreadFigureState();
}

class _BreakingThreadFigureState extends State<BreakingThreadFigure>
    with SingleTickerProviderStateMixin {
  double _masse = 2;

  /// Le fil est-il rompu ? Une fois rompu il le reste, jusqu'au renouage :
  /// baisser la masse ne recolle pas un fil cassé, et c'est le point.
  bool _rompu = false;

  late final AnimationController _chute = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _chute.dispose();
    super.dispose();
  }

  void _reglerMasse(double valeur) {
    final double masse = (valeur * 10).roundToDouble() / 10;
    if (_rompu) return;
    setState(() => _masse = masse);
    if (BreakingThreadFigure.casse(masse)) {
      setState(() => _rompu = true);
      context.errorFeedback();
      if (context.reduceMotion) {
        _chute.value = 1;
      } else {
        _chute.forward(from: 0);
      }
    } else {
      context.tapFeedback();
    }
  }

  void _renouer() {
    context.tapFeedback();
    _chute.value = 0;
    setState(() {
      _rompu = false;
      _masse = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double poids = BreakingThreadFigure.poids(_masse);
    final double tension = _rompu ? 0 : poids;
    final double marge = BreakingThreadFigure.chargeDeRupture - poids;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 260,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return AnimatedBuilder(
                  animation: _chute,
                  builder: (BuildContext context, Widget? _) {
                    return CustomPaint(
                      size: Size(contraintes.maxWidth, 260),
                      painter: _FilPainter(
                        masse: _masse,
                        rompu: _rompu,
                        chute: _chute.value,
                        accent: widget.accent,
                        tokens: tokens,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'P = ${_nombre(_masse)} × 9,8 = ${_nombre(poids)} N',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        const SizedBox(height: AppSpacing.xs),
        _Jauge(
          tension: tension,
          rupture: BreakingThreadFigure.chargeDeRupture,
          rompu: _rompu,
          accent: widget.accent,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _rompu
              ? 'Le fil a cédé : le poids a dépassé les 50 N qu\'il tenait.'
              : marge < 5
                  ? 'Le fil est à ${_nombre(marge)} N de céder.'
                  : 'Le fil tient. Pousse encore.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(
            color: _rompu ? tokens.error : tokens.inkSubtle,
          ),
        ),
        Row(
          children: <Widget>[
            SizedBox(
              width: 54,
              child: Text(
                'masse',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkSubtle,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _masse,
                min: 0.5,
                max: BreakingThreadFigure.masseMax,
                divisions: 95,
                onChanged: _rompu ? null : _reglerMasse,
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                '${_nombre(_masse)} kg',
                textAlign: TextAlign.right,
                style: AppTypography.formula(size: 14, color: widget.accent),
              ),
            ),
          ],
        ),
        if (_rompu)
          TextButton.icon(
            onPressed: _renouer,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Renouer le fil'),
          ),
      ],
    );
  }

  static String _nombre(double valeur) {
    if (valeur == valeur.roundToDouble()) return valeur.round().toString();
    return valeur.toStringAsFixed(1).replaceAll('.', ',');
  }
}

/// La barre de tension, qui rougit à l'approche de la rupture.
class _Jauge extends StatelessWidget {
  const _Jauge({
    required this.tension,
    required this.rupture,
    required this.rompu,
    required this.accent,
  });

  final double tension;
  final double rupture;
  final bool rompu;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double fraction = (tension / rupture).clamp(0.0, 1.0);
    final Color couleur = rompu
        ? tokens.error
        : fraction > 0.9
            ? tokens.error
            : fraction > 0.7
                ? tokens.warning
                : accent;

    return Row(
      children: <Widget>[
        SizedBox(
          width: 54,
          child: Text(
            'tension',
            style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: <Widget>[
                  Container(color: tokens.surfaceAlt),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(color: couleur),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            '${tension.round()} / ${rupture.round()}',
            textAlign: TextAlign.right,
            style: AppTypography.formula(size: 12, color: couleur),
          ),
        ),
      ],
    );
  }
}

class _FilPainter extends CustomPainter {
  _FilPainter({
    required this.masse,
    required this.rompu,
    required this.chute,
    required this.accent,
    required this.tokens,
  });

  final double masse;
  final bool rompu;

  /// Avancement de la chute, de 0 à 1.
  final double chute;

  final Color accent;
  final AppTokens tokens;

  /// Hauteur du crochet sous le plafond.
  static const double _yCrochet = 26;

  /// Longueur du fil au repos.
  static const double _filRepos = 84;

  /// Allongement maximal du fil juste avant rupture.
  static const double _filEtire = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cote = 30 + 34 * (masse / BreakingThreadFigure.masseMax);

    _peindrePlafond(canvas, size);

    final double allonge = BreakingThreadFigure.allongement(masse);
    final double longueurFil = _filRepos + _filEtire * allonge;
    final double yObjetSuspendu = _yCrochet + longueurFil;

    // La chute : accélérée, comme une vraie chute libre — la distance
    // parcourue suit le carré du temps, pas le temps lui-même. Un objet qui
    // descendrait à vitesse constante ne ressemblerait à rien de réel.
    final double solY = size.height - 18;
    final double restant = solY - cote / 2 - yObjetSuspendu;
    final double descente = rompu ? restant * chute * chute : 0;
    final double yObjet = yObjetSuspendu + descente;

    if (!rompu) {
      _peindreFil(canvas, cx, _yCrochet, yObjet - cote / 2, allonge);
    } else {
      _peindreFilRompu(canvas, cx, _yCrochet, longueurFil, chute);
    }

    _peindreObjet(canvas, Offset(cx, yObjet), cote, size);
    if (!rompu) {
      _peindreFlechePoids(canvas, Offset(cx, yObjet + cote / 2), size);
    }
    _peindreSol(canvas, size, solY);
  }

  void _peindrePlafond(Canvas canvas, Size size) {
    final Paint poutre = Paint()..color = tokens.inkSubtle.withValues(alpha: 0.5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 14), poutre);
    // Les hachures d'un support fixe, convention de tous les schémas de
    // mécanique : elles disent « ceci ne bouge pas ».
    final Paint trait = Paint()
      ..color = tokens.inkSubtle.withValues(alpha: 0.55)
      ..strokeWidth = 1.4;
    for (double x = 4; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 14), Offset(x - 7, 22), trait);
    }
    // Le crochet.
    final Paint crochet = Paint()
      ..color = tokens.inkSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, 20), radius: 6),
      0,
      math.pi,
      false,
      crochet,
    );
  }

  void _peindreFil(
    Canvas canvas,
    double cx,
    double yHaut,
    double yBas,
    double allonge,
  ) {
    // Le fil s'amincit en s'étirant : un fil tendu à la limite est
    // visiblement plus fin qu'un fil au repos, et c'est un signal de plus
    // avant la rupture.
    final Paint fil = Paint()
      ..color = allonge > 0.9
          ? tokens.error
          : allonge > 0.7
              ? tokens.warning
              : tokens.inkMuted
      ..strokeWidth = 3.0 - 1.4 * allonge
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, yHaut), Offset(cx, yBas), fil);
  }

  void _peindreFilRompu(
    Canvas canvas,
    double cx,
    double yHaut,
    double longueur,
    double avancement,
  ) {
    // Les deux bouts se rétractent en se tordant : un fil qui casse ne
    // reste pas rectiligne, il fouette.
    final Paint fil = Paint()
      ..color = tokens.error
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double retrait = longueur * 0.42 * avancement;
    final Path haut = Path()..moveTo(cx, yHaut);
    for (int i = 1; i <= 6; i++) {
      final double t = i / 6;
      final double y = yHaut + (longueur * 0.5 - retrait) * t;
      final double ecart = math.sin(t * math.pi * 2.2) * 7 * avancement;
      haut.lineTo(cx + ecart, y);
    }
    canvas.drawPath(haut, fil);
  }

  void _peindreObjet(Canvas canvas, Offset centre, double cote, Size size) {
    final Rect boite = Rect.fromCenter(
      center: centre,
      width: cote,
      height: cote,
    );
    // Un bloc métallique : dégradé pour le volume, arête claire en haut.
    final Paint corps = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          accent.withValues(alpha: 0.95),
          accent.withValues(alpha: 0.6),
        ],
      ).createShader(boite);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boite, const Radius.circular(4)),
      corps,
    );
    final Paint arete = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.6;
    canvas.drawLine(boite.topLeft, boite.topRight, arete);

    // L'anneau par lequel le fil le tient.
    final Paint anneau = Paint()
      ..color = tokens.inkMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(centre.dx, boite.top - 4), 4, anneau);

    // La masse écrite sur le bloc : l'élève doit pouvoir relier le nombre
    // du curseur à l'objet qu'il voit, sans déplacer les yeux.
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: masse == masse.roundToDouble()
            ? '${masse.round()} kg'
            : '${masse.toStringAsFixed(1).replaceAll('.', ',')} kg',
        style: AppTypography.formula(size: 11, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  void _peindreFlechePoids(Canvas canvas, Offset depart, Size size) {
    // La flèche du poids, à l'échelle de la charge de rupture : elle atteint
    // sa longueur maximale exactement quand le fil cède.
    final double fraction =
        BreakingThreadFigure.poids(masse) / BreakingThreadFigure.chargeDeRupture;
    final double longueur = 46 * fraction.clamp(0.0, 1.0);
    if (longueur < 4) return;

    final Paint fleche = Paint()
      ..color = tokens.error
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final Offset bout = depart + Offset(0, longueur);
    canvas.drawLine(depart + const Offset(0, 6), bout, fleche);
    final Path pointe = Path()
      ..moveTo(bout.dx, bout.dy + 5)
      ..lineTo(bout.dx - 4.5, bout.dy - 3)
      ..lineTo(bout.dx + 4.5, bout.dy - 3)
      ..close();
    canvas.drawPath(pointe, Paint()..color = tokens.error);

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: 'P',
        style: AppTypography.formula(size: 13, color: tokens.error),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(bout.dx + 7, bout.dy - 12));
  }

  void _peindreSol(Canvas canvas, Size size, double y) {
    final Paint sol = Paint()
      ..color = tokens.inkSubtle.withValues(alpha: 0.28)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), sol);
  }

  @override
  bool shouldRepaint(_FilPainter ancien) =>
      ancien.masse != masse ||
      ancien.rompu != rompu ||
      ancien.chute != chute ||
      ancien.accent != accent;
}
