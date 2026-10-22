/// Une onde qui se propage, et le point du milieu qui ne va nulle part.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Un milieu dans lequel un son se propage, avec sa célérité réelle.
///
/// Les trois valeurs sont celles de la littérature à 20 degrés Celsius,
/// et c'est important : la célérité du son dépend de la température, et
/// donner des chiffres pris à des températures différentes ferait
/// mentir la comparaison que la figure demande de faire.
enum MilieuSonore {
  air('l\'air', 343),
  helium('l\'hélium', 1007),
  eau('l\'eau', 1480);

  const MilieuSonore(this.nom, this.celerite);

  /// Le nom du milieu, avec son article.
  final String nom;

  /// La célérité du son dans ce milieu, en mètres par seconde.
  ///
  /// C'est une propriété du milieu, et non de la source : c'est tout
  /// l'intérêt de la ranger ici et non à côté de la fréquence.
  final double celerite;
}

/// Un haut-parleur, une onde qui avance, et un point du milieu qui
/// monte et descend sur place.
///
/// La figure n'offre que deux réglages, et ce choix est le fond de la
/// leçon : on choisit le milieu, qui fixe la célérité, et on choisit la
/// fréquence, qui est le fait de la source. La longueur d'onde, elle,
/// ne se règle pas — elle est ce qui reste, et l'élève la voit
/// s'allonger ou se resserrer sans y avoir touché.
///
/// Laisser régler les trois grandeurs séparément aurait été plus
/// confortable et aurait enseigné une chose fausse.
class WaveFigure extends StatefulWidget {
  const WaveFigure({required this.accent, super.key});

  final Color accent;

  /// La longueur de milieu représentée par le dessin, en mètres.
  ///
  /// Elle est fixe, et c'est ce qui permet de voir la longueur d'onde
  /// changer : si la fenêtre s'adaptait, le dessin aurait toujours la
  /// même allure et il n'y aurait plus rien à observer.
  static const double fenetre = 2;

  /// Les bornes du curseur de fréquence, en hertz.
  static const double frequenceMin = 170;
  static const double frequenceMax = 2000;

  /// La position du point du milieu qu'on suit, en mètres depuis la
  /// source.
  static const double pointSuivi = 1.4;

  /// La longueur d'onde, en mètres, pour ce milieu et cette fréquence.
  ///
  /// C'est la relation fondamentale, et la figure ne fait que la
  /// montrer : la longueur d'onde est la distance parcourue pendant une
  /// période.
  static double longueurDOnde(MilieuSonore milieu, double frequence) =>
      milieu.celerite / frequence;

  /// La période, en secondes, pour cette fréquence.
  static double periode(double frequence) => 1 / frequence;

  /// Le nombre de longueurs d'onde qui tiennent dans la fenêtre.
  static double ondesVisibles(MilieuSonore milieu, double frequence) =>
      fenetre / longueurDOnde(milieu, frequence);

  /// L'élongation du milieu au point d'abscisse [metres], en fraction de
  /// l'amplitude, après la fraction de période [phase].
  ///
  /// C'est la forme d'onde progressive. Le signe moins devant la phase
  /// est ce qui fait avancer l'onde vers la droite : l'inverser la
  /// ferait remonter vers la source, et rien d'autre dans le dessin ne
  /// le signalerait.
  static double elongation({
    required double metres,
    required double longueurDOnde,
    required double phase,
  }) => math.sin(2 * math.pi * (metres / longueurDOnde - phase));

  @override
  State<WaveFigure> createState() => _WaveFigureState();
}

class _WaveFigureState extends State<WaveFigure>
    with SingleTickerProviderStateMixin {
  MilieuSonore _milieu = MilieuSonore.air;
  double _frequence = 440;

  // Une période de l'onde dure deux secondes et demie à l'écran. Aucune
  // des fréquences réglables n'est observable à l'œil — 170 hertz, c'est
  // déjà 170 allers-retours par seconde — donc le mouvement est
  // nécessairement ralenti, et le dire sous le dessin vaut mieux que de
  // laisser croire à du temps réel.
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..addListener(() => setState(() {}));

  bool _demarrageFait = false;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;

    // context.reduceMotion lit un MediaQuery : il n'est pas lisible
    // depuis initState, d'où ce démarrage au premier build.
    if (!_demarrageFait) {
      _demarrageFait = true;
      if (!context.reduceMotion) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _controleur.repeat();
        });
      }
    }

    final double lambda = WaveFigure.longueurDOnde(_milieu, _frequence);
    final double periodeMs = WaveFigure.periode(_frequence) * 1000;
    final bool lambdaTient = lambda <= WaveFigure.fenetre;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (final MilieuSonore m in MilieuSonore.values)
              ChoiceChip(
                selected: m == _milieu,
                label: Text(
                  m.nom,
                  style: context.text.labelMedium?.copyWith(
                    color: m == _milieu
                        ? widget.accent
                        : context.colors.onSurface,
                  ),
                ),
                onSelected: (bool _) {
                  context.tapFeedback();
                  setState(() => _milieu = m);
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: 1.08,
          child: CustomPaint(
            painter: _OndePainter(
              longueurDOnde: lambda,
              phase: _controleur.value,
              accent: widget.accent,
              ink: context.colors.onSurface,
              trait: tokens.border,
              muted: tokens.inkMuted,
              point: tokens.gold,
              surface: context.colors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'En haut l’air, qui avance et recule. En bas le graphique de '
          'ce déplacement : la courbe n’est pas une photographie de l’air.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'v = ${NumericQuestion.formatNumber(_milieu.celerite)} m/s   ·   '
          'f = ${NumericQuestion.formatNumber(_frequence.roundToDouble())} Hz',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 16, color: tokens.inkMuted),
        ),
        Text(
          'λ = v / f = '
          '${NumericQuestion.formatNumber((lambda * 100).roundToDouble() / 100)}'
          ' m',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 19, color: widget.accent),
        ),
        Text(
          lambdaTient
              ? 'C’est la longueur d’onde, marquée sous le dessin. '
                    'Une période dure '
                    '${NumericQuestion.formatNumber(
                      (periodeMs * 100).roundToDouble() / 100,
                    )} ms, et le mouvement est ralenti.'
              : 'λ dépasse les '
                    '${NumericQuestion.formatNumber(WaveFigure.fenetre)} m de '
                    'la fenêtre : on n’en voit qu’un morceau.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        Slider(
          value: _frequence,
          min: WaveFigure.frequenceMin,
          max: WaveFigure.frequenceMax,
          divisions: 61,
          onChanged: (double v) {
            context.tapFeedback();
            setState(() => _frequence = (v / 10).roundToDouble() * 10);
          },
        ),
        Text(
          'Change le milieu, puis la fréquence : λ suit sans qu’on y touche',
          textAlign: TextAlign.center,
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

class _OndePainter extends CustomPainter {
  const _OndePainter({
    required this.longueurDOnde,
    required this.phase,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.point,
    required this.surface,
  });

  /// La longueur d'onde, en mètres.
  final double longueurDOnde;

  /// Avancement de l'animation, entre 0 et 1. L'onde parcourt une
  /// longueur d'onde par cycle, donc cette valeur est aussi la fraction
  /// de période écoulée.
  final double phase;

  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color point;
  final Color surface;

  double _elongation(double metres) => WaveFigure.elongation(
    metres: metres,
    longueurDOnde: longueurDOnde,
    phase: phase,
  );

  @override
  void paint(Canvas canvas, Size size) {
    const double margeGauche = 34;
    const double margeDroite = 12;
    final double largeur = size.width - margeGauche - margeDroite;
    final double parMetre = largeur / WaveFigure.fenetre;

    // Deux vues l'une au-dessus de l'autre, et c'est volontaire : en
    // haut l'air lui-même, en bas le graphique de son déplacement. Un
    // son est une onde longitudinale — l'air avance et recule dans le
    // sens de la propagation — et la sinusoïde que tout le monde dessine
    // n'est pas une photographie de l'air, c'est la courbe de son
    // déplacement. Ne montrer que la sinusoïde installe l'idée fausse
    // que l'air monte et descend.
    const double hautBande = 12;
    final double basBande = hautBande + (size.height - 42) * 0.34;
    final double hautGraphe = basBande + 14;
    final double basAxe = size.height - 30;
    final double milieu = (hautGraphe + basAxe) / 2;
    final double amplitude = (basAxe - hautGraphe) / 2 - 6;

    canvas.drawRect(
      Rect.fromLTRB(margeGauche, hautBande, size.width - margeDroite, basBande),
      Paint()..color = surface,
    );
    canvas.drawRect(
      Rect.fromLTRB(margeGauche, hautGraphe, size.width - margeDroite, basAxe),
      Paint()..color = surface,
    );

    _bandeDAir(canvas, margeGauche, hautBande, basBande, largeur, parMetre);
    _hautParleur(canvas, margeGauche, hautBande, basBande, parMetre);

    // La ligne de repos : c'est elle que l'élève doit garder en tête,
    // parce que la courbe oscille autour d'elle et ne la quitte jamais
    // en moyenne.
    canvas.drawLine(
      Offset(margeGauche, milieu),
      Offset(size.width - margeDroite, milieu),
      Paint()
        ..color = trait
        ..strokeWidth = 1,
    );

    _reglette(canvas, size, margeGauche, basAxe, parMetre);

    // La courbe, échantillonnée assez finement pour que la plus courte
    // longueur d'onde réglable reste lisse : à 2000 Hz dans l'air il y a
    // près de douze périodes dans la fenêtre, donc un pas de deux pixels
    // suffit tout juste.
    final Path onde = Path();
    for (double px = 0; px <= largeur; px += 2) {
      final double y = milieu - amplitude * _elongation(px / parMetre);
      if (px == 0) {
        onde.moveTo(margeGauche + px, y);
      } else {
        onde.lineTo(margeGauche + px, y);
      }
    }
    canvas.drawPath(
      onde,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );

    _pointDuGraphe(canvas, margeGauche, milieu, amplitude, parMetre);
    if (longueurDOnde <= WaveFigure.fenetre) {
      _crochetLambda(canvas, margeGauche, basAxe, parMetre);
    }
  }

  /// L'amplitude du va-et-vient de l'air, en pixels.
  ///
  /// Proportionnelle à la longueur d'onde, parce que c'est elle qui
  /// décide de la force du resserrement — mais plafonnée, sinon une onde
  /// de huit mètres enverrait les particules d'un bout à l'autre de la
  /// fenêtre. Le plafond déforme l'amplitude ; il ne déplace pas les
  /// zones comprimées, qui sont ce qu'il faut voir.
  double _amplitudeAir(double parMetre) =>
      math.min(longueurDOnde * parMetre / 8, 15);

  /// La tranche d'air, vue de dessus, avec ses zones serrées et ses
  /// zones écartées.
  ///
  /// Chaque particule est à sa position de repos, décalée vers la droite
  /// ou vers la gauche par l'élongation. Les compressions naissent donc
  /// toutes seules du calcul : rien n'est dessiné « en plus foncé » pour
  /// les suggérer.
  void _bandeDAir(
    Canvas canvas,
    double margeGauche,
    double haut,
    double bas,
    double largeur,
    double parMetre,
  ) {
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(margeGauche, haut, margeGauche + largeur, bas));

    final double amplitudeAir = _amplitudeAir(parMetre);
    final math.Random alea = math.Random(11);
    const int rangees = 5;
    final double pasY = (bas - haut) / (rangees + 1);
    final Paint grain = Paint()..color = muted.withValues(alpha: 0.75);

    // On déborde de part et d'autre : une particule dont le repos est
    // juste à gauche du cadre peut y entrer, et l'oublier creuserait un
    // vide au bord qui n'a aucune raison physique.
    for (double repos = -20; repos <= largeur + 20; repos += 6.5) {
      final double decalage =
          amplitudeAir * _elongation(repos / parMetre);
      for (int r = 0; r < rangees; r++) {
        final double y = haut + pasY * (r + 1) + (alea.nextDouble() - 0.5) * 7;
        canvas.drawCircle(
          Offset(margeGauche + repos + decalage, y),
          1.5,
          grain,
        );
      }
    }

    // La particule qu'on suit : même calcul que les autres, mais on la
    // montre avec le rail sur lequel elle se limite. L'onde file vers la
    // droite et elle, elle fait du surplace — c'est tout ce que la
    // figure a à dire.
    final double reposSuivi = WaveFigure.pointSuivi * parMetre;
    final double ySuivi = (haut + bas) / 2;
    canvas.drawLine(
      Offset(margeGauche + reposSuivi - amplitudeAir, ySuivi),
      Offset(margeGauche + reposSuivi + amplitudeAir, ySuivi),
      Paint()
        ..color = point.withValues(alpha: 0.45)
        ..strokeWidth = 1.4,
    );
    // Les butées dépassent franchement du disque : sans cela, la
    // particule arrivée en bout de course recouvre son propre repère et
    // paraît s'être échappée du rail, ce qui est exactement l'inverse de
    // ce que la figure veut montrer.
    for (final double bout in <double>[-amplitudeAir, amplitudeAir]) {
      canvas.drawLine(
        Offset(margeGauche + reposSuivi + bout, ySuivi - 7),
        Offset(margeGauche + reposSuivi + bout, ySuivi + 7),
        Paint()
          ..color = point.withValues(alpha: 0.55)
          ..strokeWidth = 1.4,
      );
    }
    canvas.drawCircle(
      Offset(
        margeGauche +
            reposSuivi +
            amplitudeAir * _elongation(WaveFigure.pointSuivi),
        ySuivi,
      ),
      4,
      Paint()..color = point,
    );
    canvas.restore();
  }

  /// La graduation en mètres sous le dessin.
  ///
  /// Sans elle, le dessin ne dit rien : une sinusoïde resserrée peut
  /// aussi bien être une onde courte qu'un zoom arrière, et c'est
  /// l'échelle qui tranche.
  void _reglette(
    Canvas canvas,
    Size size,
    double margeGauche,
    double basAxe,
    double parMetre,
  ) {
    final Paint crayon = Paint()
      ..color = trait
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(margeGauche, basAxe),
      Offset(size.width - 12, basAxe),
      crayon,
    );
    for (int demi = 0; demi <= WaveFigure.fenetre * 2; demi++) {
      final double metres = demi / 2;
      final double x = margeGauche + metres * parMetre;
      final bool entier = demi % 2 == 0;
      canvas.drawLine(
        Offset(x, basAxe),
        Offset(x, basAxe + (entier ? 6 : 3)),
        crayon,
      );
      if (entier) {
        _texte(
          canvas,
          '${NumericQuestion.formatNumber(metres)} m',
          Offset(x, basAxe + 9),
          muted,
          11,
          centre: true,
        );
      }
    }
  }

  /// La membrane du haut-parleur, qui pousse et tire l'air.
  ///
  /// Elle se déplace horizontalement, comme l'air qu'elle met en
  /// mouvement : c'est elle qui crée les compressions, et la voir
  /// avancer juste avant qu'une zone serrée parte vers la droite est ce
  /// qui relie la source à l'onde.
  void _hautParleur(
    Canvas canvas,
    double margeGauche,
    double haut,
    double bas,
    double parMetre,
  ) {
    final double y = (haut + bas) / 2;
    final double demiHauteur = (bas - haut) * 0.42;
    final double x =
        margeGauche + _amplitudeAir(parMetre) * _elongation(0);

    // Le coffret, posé dans la marge, qui ne bouge pas.
    canvas.drawRect(
      Rect.fromLTRB(margeGauche - 22, y - demiHauteur * 0.55,
          margeGauche - 12, y + demiHauteur * 0.55),
      Paint()..color = muted.withValues(alpha: 0.3),
    );
    canvas.drawPath(
      Path()
        ..moveTo(margeGauche - 12, y - demiHauteur * 0.55)
        ..lineTo(margeGauche - 2, y - demiHauteur)
        ..moveTo(margeGauche - 12, y + demiHauteur * 0.55)
        ..lineTo(margeGauche - 2, y + demiHauteur),
      Paint()
        ..color = muted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // La membrane, qui suit l'élongation en x = 0.
    canvas.drawLine(
      Offset(x, y - demiHauteur),
      Offset(x, y + demiHauteur),
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Le même point, reporté sur le graphique.
  ///
  /// Il porte la même couleur que la particule suivie dans la bande, et
  /// c'est le pont entre les deux vues : ce qui est un déplacement vers
  /// la droite en haut devient une hauteur en bas. L'axe vertical du
  /// graphique n'est pas une hauteur réelle, et deux repères de la même
  /// couleur le disent mieux qu'une phrase.
  void _pointDuGraphe(
    Canvas canvas,
    double margeGauche,
    double milieu,
    double amplitude,
    double parMetre,
  ) {
    final double x = margeGauche + WaveFigure.pointSuivi * parMetre;
    final double y = milieu - amplitude * _elongation(WaveFigure.pointSuivi);

    canvas.drawLine(
      Offset(x, milieu - amplitude),
      Offset(x, milieu + amplitude),
      Paint()
        ..color = point.withValues(alpha: 0.45)
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(Offset(x, y), 5, Paint()..color = point);
    canvas.drawCircle(
      Offset(x, y),
      5,
      Paint()
        ..color = surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  /// Le crochet qui mesure une longueur d'onde sur la réglette.
  ///
  /// Il est posé à partir de l'origine et non d'une crête : une crête
  /// se déplace, et un crochet qui glisserait avec elle laisserait
  /// croire que la longueur d'onde bouge aussi.
  void _crochetLambda(
    Canvas canvas,
    double margeGauche,
    double basAxe,
    double parMetre,
  ) {
    final double y = basAxe - 11;
    final double fin = margeGauche + longueurDOnde * parMetre;
    final Paint crayon = Paint()
      ..color = ink
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(margeGauche, y), Offset(fin, y), crayon);
    canvas.drawLine(Offset(margeGauche, y - 4), Offset(margeGauche, y + 4), crayon);
    canvas.drawLine(Offset(fin, y - 4), Offset(fin, y + 4), crayon);
    _texte(
      canvas,
      'λ',
      Offset((margeGauche + fin) / 2, y - 21),
      ink,
      15,
      centre: true,
    );
  }

  void _texte(
    Canvas canvas,
    String contenu,
    Offset ou,
    Color couleur,
    double taille, {
    bool centre = false,
  }) {
    final TextPainter peintre = TextPainter(
      text: TextSpan(
        text: contenu,
        style: AppTypography.formula(size: taille, color: couleur),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    peintre.paint(
      canvas,
      centre ? ou - Offset(peintre.width / 2, 0) : ou,
    );
  }

  @override
  bool shouldRepaint(_OndePainter ancien) =>
      ancien.longueurDOnde != longueurDOnde ||
      ancien.phase != phase ||
      ancien.accent != accent;
}
