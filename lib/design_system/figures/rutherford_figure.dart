/// La feuille d'or de Rutherford : viser le noyau, et voir la balle revenir.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'realism.dart';

/// La diffusion d'une particule alpha par un noyau, visée par l'élève.
///
/// En 1909, Geiger et Marsden envoient des particules alpha sur une feuille
/// d'or et en voient revenir une sur huit mille. Rutherford dira que c'est
/// aussi incroyable qu'un obus de marine rebondissant sur une feuille de
/// papier de soie. Le modèle de Thomson — une charge positive diluée dans
/// tout l'atome — ne peut pas produire cela : une charge étalée repousse
/// mollement. Il faut qu'elle soit concentrée.
///
/// La commande est le paramètre d'impact : de quelle distance l'élève
/// manque le noyau. C'est le bon bouton, parce que c'est lui qui explique
/// la statistique de l'expérience — viser juste est rare, donc le rebond
/// est rare, donc le noyau est minuscule.
class RutherfordFigure extends StatefulWidget {
  const RutherfordFigure({required this.accent, super.key});

  /// Couleur d'accent de la matière.
  final Color accent;

  /// Paramètre d'impact maximal, en unités arbitraires.
  static const double viseeMax = 3;

  /// Rayon au-delà duquel on arrête de tracer l'hyperbole.
  static const double rayonTrace = 16;

  /// Distance d'approche minimale dans un choc frontal.
  ///
  /// Elle fixe l'échelle : c'est le rapport entre l'énergie électrique au
  /// contact et l'énergie cinétique de la particule. On la prend à 1 pour
  /// que les angles couvrent toute la plage utile sur la course du curseur.
  static const double diametreDeCollision = 1;

  /// L'angle de déviation, en degrés.
  ///
  /// C'est la formule de Rutherford, obtenue en résolvant le mouvement
  /// képlérien répulsif : tan(θ/2) = d / (2b), où `d` est le diamètre de
  /// collision et `b` le paramètre d'impact. Elle est exacte, pas ajustée
  /// à l'œil, et `test/widget/rutherford_test.dart` la compare à une
  /// intégration pas à pas du mouvement.
  static double deviationDegres(double visee) {
    if (visee <= 0) return 180;
    final double demi = math.atan(diametreDeCollision / (2 * visee));
    return 2 * demi * 180 / math.pi;
  }

  /// La trajectoire : l'hyperbole exacte du mouvement képlérien répulsif.
  ///
  /// On ne trace pas une jolie courbe à la main. Avec un potentiel α/r, une
  /// masse et une vitesse d'arrivée unités, l'orbite est
  ///
  ///     r(φ) = p / (e × cos φ − 1),  p = b² / α,  e = √(1 + b²/α²)
  ///
  /// et α vaut la moitié du diamètre de collision. Les asymptotes sont en
  /// cos φ = 1/e, ce qui redonne exactement la formule de déviation
  /// ci-dessus — `test/widget/rutherford_test.dart` le vérifie, et vérifie
  /// aussi les deux contre une intégration pas à pas indépendante.
  ///
  /// Repère rendu : le noyau à l'origine, la particule arrivant de la
  /// gauche parallèlement à l'axe des x, déviée vers le haut. Le premier
  /// point donne la hauteur de l'asymptote d'arrivée, c'est-à-dire la
  /// visée elle-même.
  static List<Offset> trajectoire(double visee, {int pas = 240}) {
    final double b = math.max(visee, 1e-3);
    const double alpha = diametreDeCollision / 2;
    final double e = math.sqrt(1 + (b * b) / (alpha * alpha));
    final double p = (b * b) / alpha;
    final double phiInfini = math.acos(1 / e);

    // On s'arrête là où le rayon atteint `rayonTrace` : à l'asymptote
    // exacte, r est infini. Borner par le rayon et non par une fraction de
    // l'angle donne une portion de courbe de longueur comparable à toutes
    // les visées, ce qui garde le tracé lisible.
    final double cosBord = ((1 + p / rayonTrace) / e).clamp(-1.0, 1.0);
    final double bord = math.min(math.acos(cosBord), phiInfini * 0.999);

    final List<Offset> brut = <Offset>[];
    for (int i = 0; i <= pas; i++) {
      final double phi = -bord + 2 * bord * i / pas;
      final double r = p / (e * math.cos(phi) - 1);
      brut.add(Offset(math.cos(phi) * r, math.sin(phi) * r));
    }

    // Orientation : on tourne l'orbite pour que la branche d'arrivée soit
    // horizontale et dirigée vers la droite. Mesurer l'angle sur le
    // premier segment plutôt que le calculer évite de se tromper de signe.
    final Offset premier = brut[1] - brut[0];
    final double rotation = -math.atan2(premier.dy, premier.dx);
    final double c = math.cos(rotation);
    final double s = math.sin(rotation);
    List<Offset> points = brut
        .map((Offset o) => Offset(o.dx * c - o.dy * s, o.dx * s + o.dy * c))
        .toList();

    // La déviation doit se voir vers le haut, dans le sens où l'élève a
    // écarté la visée : si la symétrie l'a mise en bas, on la retourne.
    if (points.first.dy < 0) {
      points = points.map((Offset o) => Offset(o.dx, -o.dy)).toList();
    }
    return points;
  }

  /// L'angle de sortie lu sur la trajectoire tracée, en degrés.
  static double deviationTracee(double visee) {
    final List<Offset> points = trajectoire(visee);
    final Offset vitesse = points.last - points[points.length - 2];
    return math.atan2(vitesse.dy, vitesse.dx).abs() * 180 / math.pi;
  }

  /// La même déviation, obtenue en intégrant le mouvement pas à pas.
  ///
  /// Cette fonction ne sert pas à l'affichage : elle est le témoin
  /// indépendant de la formule et de l'hyperbole. On lâche la particule
  /// loin à gauche et on la laisse être repoussée en 1/r², sans jamais
  /// utiliser le résultat analytique.
  static double deviationIntegree(double visee, {double dt = 0.002}) {
    const double alpha = diametreDeCollision / 2;
    const double depart = 40;

    double x = -depart;
    double y = math.max(visee, 1e-3);
    double vx = 1;
    double vy = 0;

    // Assez de pas pour traverser : la particule part de −40 et doit
    // ressortir à +40, à vitesse voisine de 1.
    final int pasMax = (4 * depart / dt).ceil();
    for (int i = 0; i < pasMax; i++) {
      final double r2 = x * x + y * y;
      final double r = math.sqrt(r2);
      // Répulsion de Coulomb : a = α / r², dirigée loin du noyau.
      final double a = alpha / (r2 * r);
      vx += a * x * dt;
      vy += a * y * dt;
      x += vx * dt;
      y += vy * dt;
      if (x > depart) break;
    }
    return math.atan2(vy, vx).abs() * 180 / math.pi;
  }

  /// Sur combien de tirs un seul revient en arrière, à cette visée.
  ///
  /// La section efficace de rétrodiffusion est proportionnelle au carré du
  /// paramètre d'impact qui la produit ; on compare à la surface qu'occupe
  /// un atome. C'est ce rapport qui a donné « un sur huit mille ».
  static int tirsPourUnRebond(double visee) {
    if (visee <= 0) return 1;
    const double rayonAtome = 60;
    final double rapport = (rayonAtome / visee) * (rayonAtome / visee);
    return rapport.round();
  }

  @override
  State<RutherfordFigure> createState() => _RutherfordFigureState();
}

class _RutherfordFigureState extends State<RutherfordFigure>
    with SingleTickerProviderStateMixin {
  double _visee = 1.6;
  late final AnimationController _tir = AnimationController(
    duration: const Duration(milliseconds: 1500),
    vsync: this,
  );

  bool _demarre = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `reduceMotion` lit MediaQuery, qu'on n'a pas le droit de consulter
    // depuis initState. Le drapeau évite de relancer le tir à chaque
    // changement de thème.
    if (_demarre) return;
    _demarre = true;
    if (!context.reduceMotion) _tir.repeat();
  }

  @override
  void dispose() {
    _tir.dispose();
    super.dispose();
  }

  void _regler(double valeur) {
    final double visee = (valeur * 20).roundToDouble() / 20;
    if (visee == _visee) return;
    setState(() => _visee = visee);
    if (RutherfordFigure.deviationDegres(visee) > 90) {
      context.errorFeedback();
    } else {
      context.tapFeedback();
    }
  }


  /// Les grands nombres, groupés par trois : « 1 406 », pas « 1406 ».
  ///
  /// L'espace fine insécable (U+202F) manquant dans la police, on prend
  /// l'espace insécable ordinaire, que Nunito dessine.
  String _milliers(int n) {
    final String chiffres = n.toString();
    final StringBuffer sortie = StringBuffer();
    for (int i = 0; i < chiffres.length; i++) {
      if (i > 0 && (chiffres.length - i) % 3 == 0) sortie.write('\u00A0');
      sortie.write(chiffres[i]);
    }
    return sortie.toString();
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double angle = RutherfordFigure.deviationDegres(_visee);
    final bool rebond = angle > 90;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return GestureDetector(
                  // Viser au doigt : on déplace la ligne de tir
                  // verticalement, exactement comme on viserait.
                  onVerticalDragUpdate: (DragUpdateDetails details) {
                    const double h = 200;
                    const double axe = h * 0.74;
                    const double echelle = h * 0.105;
                    _regler(
                      ((axe - details.localPosition.dy) / echelle)
                          .clamp(0.05, RutherfordFigure.viseeMax),
                    );
                  },
                  child: AnimatedBuilder(
                    animation: _tir,
                    builder: (BuildContext context, Widget? _) => CustomPaint(
                      size: Size(contraintes.maxWidth, 200),
                      painter: _RutherfordPainter(
                        visee: _visee,
                        avance: context.reduceMotion ? 1 : _tir.value,
                        accent: widget.accent,
                        tokens: tokens,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'déviation ${angle.round()}°',
          textAlign: TextAlign.center,
          style: AppTypography.formula(
            size: 18,
            color: rebond ? tokens.error : widget.accent,
          ),
        ),
        Text(
          rebond
              ? 'Elle revient. Rien de dilué ne peut faire ça : '
                  'la charge est concentrée en un point.'
              : 'Elle passe presque droit, comme la grande majorité '
                  'des tirs.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        Text(
          'viser d’aussi près : 1 tir sur '
          '${_milliers(RutherfordFigure.tirsPourUnRebond(_visee))}',
          textAlign: TextAlign.center,
          style: context.text.labelSmall?.copyWith(color: tokens.inkMuted),
        ),
        Row(
          children: <Widget>[
            SizedBox(
              width: 46,
              child: Text(
                'visée',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkSubtle,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _visee,
                min: 0.05,
                max: RutherfordFigure.viseeMax,
                onChanged: _regler,
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                _visee < 0.2 ? 'le noyau' : 'à côté',
                textAlign: TextAlign.right,
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkSubtle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Le noyau, le nuage d'électrons, et la trajectoire intégrée.
class _RutherfordPainter extends CustomPainter {
  const _RutherfordPainter({
    required this.visee,
    required this.avance,
    required this.accent,
    required this.tokens,
  });

  final double visee;
  final double avance;
  final Color accent;
  final AppTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tokens.surfaceAlt);

    // Le noyau est posé bas et à gauche : la branche déviée part vers le
    // haut à droite, et c'est elle qu'il faut voir en entier.
    final Offset noyau = Offset(size.width * 0.46, size.height * 0.74);
    final double echelle = size.height * 0.105;

    _dessinerAtome(canvas, size, noyau, echelle);
    _dessinerTrajectoire(canvas, size, noyau, echelle);
    _dessinerNoyau(canvas, noyau);
    _dessinerVisee(canvas, size, noyau, echelle);
  }

  /// Le nuage électronique : vide à l'échelle, et c'est le point.
  void _dessinerAtome(Canvas canvas, Size size, Offset noyau, double echelle) {
    final double rayonAtome = echelle * 3.6;
    canvas.drawCircle(
      noyau,
      rayonAtome,
      Paint()
        ..color = tokens.inkSubtle.withValues(alpha: 0.18)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
    // Quelques électrons, loin et légers : on ne les dessine pas en orbite
    // sagement circulaire, ils ne le sont pas.
    final math.Random alea = math.Random(11);
    for (int i = 0; i < 7; i++) {
      final double a = alea.nextDouble() * math.pi * 2;
      final double r = rayonAtome * (0.55 + alea.nextDouble() * 0.42);
      canvas.drawCircle(
        noyau + Offset(math.cos(a) * r, math.sin(a) * r),
        2.1,
        Paint()..color = tokens.info.withValues(alpha: 0.7),
      );
    }
    _etiquette(
      canvas,
      'atome d’or : surtout du vide',
      Offset(8, size.height - 20),
      tokens.inkSubtle,
    );
  }

  /// Le noyau : petit, dense, doré. Son rayon réel serait invisible ici,
  /// et la figure le dit en toutes lettres.
  void _dessinerNoyau(Canvas canvas, Offset noyau) {
    Realisme.sphere(canvas, noyau, 7, couleur: tokens.gold);
    canvas.drawCircle(
      noyau,
      13,
      Paint()
        ..color = tokens.gold.withValues(alpha: 0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    _etiquette(canvas, '+', noyau + const Offset(-3, -20), tokens.gold);
  }

  /// La trajectoire, telle que l'intégration la donne.
  void _dessinerTrajectoire(
    Canvas canvas,
    Size size,
    Offset noyau,
    double echelle,
  ) {
    final List<Offset> points = RutherfordFigure.trajectoire(visee);
    Offset versEcran(Offset p) =>
        noyau + Offset(p.dx * echelle, -p.dy * echelle);

    final Path chemin = Path();
    bool commence = false;
    for (final Offset p in points) {
      final Offset e = versEcran(p);
      if (e.dx < -40 || e.dx > size.width + 40) continue;
      if (!commence) {
        chemin.moveTo(e.dx, e.dy);
        commence = true;
      } else {
        chemin.lineTo(e.dx, e.dy);
      }
    }
    canvas.drawPath(
      chemin,
      Paint()
        ..color = accent.withValues(alpha: 0.85)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke,
    );

    // La ligne qu'elle aurait suivie sans noyau : sans elle, « déviée » est
    // un mot, et l'élève n'a rien pour comparer.
    final double hauteur = noyau.dy - visee * echelle;
    canvas.drawLine(
      Offset(0, hauteur),
      Offset(size.width, hauteur),
      Paint()
        ..color = tokens.inkSubtle.withValues(alpha: 0.35)
        ..strokeWidth = 1.2,
    );

    // L'angle lui-même, tracé au point de sortie : un arc entre la
    // direction d'arrivée et celle de départ. Sans lui, « 35° » est un
    // nombre posé à côté du dessin plutôt qu'une mesure sur le dessin.
    // On pose l'arc sur le dernier point encore confortablement dans le
    // cadre : à cet endroit la courbe est déjà sur son asymptote, donc
    // l'angle mesuré est bien la déviation, et il se voit.
    int repere = points.length - 1;
    while (repere > 1) {
      final Offset e = versEcran(points[repere]);
      if (e.dx < size.width - 68 && e.dy > 46) break;
      repere--;
    }
    final Offset sortie = versEcran(points[repere]);
    final Offset vitesse = points[repere] - points[repere - 1];
    final double angleSortie = math.atan2(-vitesse.dy, vitesse.dx);
    final double rayonArc = math.min(34, size.width * 0.1);
    canvas.drawLine(
      sortie,
      sortie + Offset(rayonArc * 1.5, 0),
      Paint()
        ..color = tokens.inkSubtle.withValues(alpha: 0.45)
        ..strokeWidth = 1,
    );
    canvas.drawArc(
      Rect.fromCircle(center: sortie, radius: rayonArc),
      -angleSortie,
      angleSortie,
      false,
      Paint()
        ..color = accent
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke,
    );

    // La particule elle-même, posée sur son chemin : c'est elle qui donne
    // le mouvement, et le sens de parcours.
    final int index = (avance * (points.length - 1)).clamp(
      0,
      points.length - 1,
    ).round();
    final Offset position = versEcran(points[index]);
    Realisme.sphere(canvas, position, 5.5, couleur: tokens.error);
    _etiquette(canvas, 'α', position + const Offset(6, -18), tokens.error);
  }

  /// Le repère de visée : la distance au noyau, mesurée et nommée.
  void _dessinerVisee(
    Canvas canvas,
    Size size,
    Offset noyau,
    double echelle,
  ) {
    final double y = noyau.dy - visee * echelle;
    final Paint cote = Paint()
      ..color = tokens.inkMuted.withValues(alpha: 0.6)
      ..strokeWidth = 1.2;
    final double x = size.width * 0.2;
    canvas.drawLine(Offset(x, y), Offset(x, noyau.dy), cote);
    for (final double yy in <double>[y, noyau.dy]) {
      canvas.drawLine(Offset(x - 4, yy), Offset(x + 4, yy), cote);
    }
    _etiquette(canvas, 'visée', Offset(x + 7, (y + noyau.dy) / 2 - 7),
        tokens.inkMuted);
  }

  void _etiquette(Canvas canvas, String texte, Offset ou, Color couleur) {
    TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontFamilyFallback: AppTypography.replis,
          color: couleur,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, ou);
  }

  @override
  bool shouldRepaint(_RutherfordPainter ancien) =>
      ancien.visee != visee ||
      ancien.avance != avance ||
      ancien.accent != accent ||
      ancien.tokens != tokens;
}
