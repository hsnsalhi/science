/// Soleil, Terre, Lune : où tombe l'ombre, et pourquoi si rarement.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';
import 'realism.dart';

/// Ce qu'un alignement donné produit.
enum TypeEclipse {
  /// La Lune est entre le Soleil et la Terre, et assez bien alignée.
  soleil('Éclipse de Soleil', 'La Lune masque le Soleil. Nouvelle lune.'),

  /// La Terre est entre le Soleil et la Lune, et assez bien alignée.
  lune('Éclipse de Lune', 'La Lune entre dans l\'ombre de la Terre. Pleine lune.'),

  /// Les trois astres sont alignés en longitude mais la Lune passe à côté.
  manquee(
    'Pas d\'éclipse',
    'Alignée, mais trop haut ou trop bas : l\'ombre rate sa cible.',
  ),

  /// La Lune n'est pas du tout dans l'axe.
  aucune('Pas d\'éclipse', 'La Lune n\'est pas dans l\'axe Soleil-Terre.');

  const TypeEclipse(this.titre, this.explication);

  final String titre;
  final String explication;
}

/// L'alignement des trois astres, réglable en position et en inclinaison.
///
/// Le chapitre pose une question que les schémas de manuel n'aident pas à
/// résoudre : la Lune repasse devant le Soleil chaque mois, alors pourquoi
/// les éclipses sont-elles rares ? Un schéma plat suggère qu'il en faudrait
/// une par mois, et laisse l'élève avec une contradiction.
///
/// La réponse est que l'orbite lunaire est inclinée d'environ 5 degrés : le
/// plus souvent la Lune passe au-dessus ou au-dessous de l'axe, et l'ombre
/// manque sa cible. La figure donne donc deux réglages — la position sur
/// l'orbite et la hauteur hors du plan — parce qu'un seul ne pourrait pas
/// faire comprendre la rareté.
class EclipseFigure extends StatefulWidget {
  const EclipseFigure({required this.accent, super.key});

  final Color accent;

  /// Demi-ouverture tolérée, en degrés, pour que l'alignement compte.
  ///
  /// Au-delà, le cône d'ombre passe à côté. L'ordre de grandeur est celui
  /// de la réalité : les éclipses ne se produisent que dans une fenêtre
  /// étroite autour des nœuds de l'orbite lunaire.
  static const double toleranceLongitude = 15;

  /// Écart hors du plan toléré, en degrés.
  static const double toleranceLatitude = 1.5;

  /// Inclinaison réelle de l'orbite lunaire, en degrés.
  static const double inclinaison = 5.1;

  /// Ce que produit la Lune à [longitude] degrés, décalée de [latitude].
  ///
  /// La longitude est comptée depuis la direction du Soleil : 0 place la
  /// Lune entre le Soleil et la Terre (nouvelle lune), 180 la place
  /// derrière la Terre (pleine lune).
  static TypeEclipse classer(double longitude, double latitude) {
    final double l = _normaliser(longitude);
    final bool horsDuPlan = latitude.abs() > toleranceLatitude;
    final bool versLeSoleil = l <= toleranceLongitude ||
        l >= 360 - toleranceLongitude;
    final bool derriere = (l - 180).abs() <= toleranceLongitude;

    if (!versLeSoleil && !derriere) return TypeEclipse.aucune;
    if (horsDuPlan) return TypeEclipse.manquee;
    return versLeSoleil ? TypeEclipse.soleil : TypeEclipse.lune;
  }

  /// Phase de la Lune vue de la Terre, à [longitude] degrés.
  ///
  /// Sert à vérifier l'affirmation du cours : une éclipse de Soleil ne peut
  /// arriver qu'à la nouvelle lune, une éclipse de Lune qu'à la pleine lune.
  static String phase(double longitude) {
    final double l = _normaliser(longitude);
    if (l <= 22.5 || l >= 337.5) return 'nouvelle lune';
    if ((l - 180).abs() <= 22.5) return 'pleine lune';
    if ((l - 90).abs() <= 22.5) return 'premier quartier';
    if ((l - 270).abs() <= 22.5) return 'dernier quartier';
    return l < 180 ? 'croissante' : 'décroissante';
  }

  static double _normaliser(double degres) {
    double d = degres % 360;
    if (d < 0) d += 360;
    return d;
  }

  @override
  State<EclipseFigure> createState() => _EclipseFigureState();
}

class _EclipseFigureState extends State<EclipseFigure> {
  double _longitude = 0;
  double _latitude = 0;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // La Lune fait le tour de son orbite : les phases se succèdent, et
    // l'éclipse ne se produit qu'au passage par le nœud. C'est pourquoi
    // il n'y en a pas à chaque pleine lune, et cela se voit ici au lieu
    // de s'énoncer.
    final double? tour = Autoplay.phase(context);
    final double longitude = _tenue || tour == null
        ? _longitude
        : tour * 360;
    final double latitude = _latitude;
    final TypeEclipse type = EclipseFigure.classer(longitude, latitude);
    final bool eclipse =
        type == TypeEclipse.soleil || type == TypeEclipse.lune;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 160,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, 160),
                painter: _EclipsePainter(
                  longitude: longitude,
                  latitude: latitude,
                  type: type,
                  accent: widget.accent,
                  trait: tokens.border,
                  muted: tokens.inkMuted,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          type.titre,
          textAlign: TextAlign.center,
          style: AppTypography.formula(
            size: 18,
            color: eclipse ? widget.accent : tokens.inkMuted,
          ),
        ),
        Text(
          type.explication,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        Text(
          'Phase : ${EclipseFigure.phase(longitude)}.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        // Ce qu'aucun dessin ne peut montrer, et qu'il vaut mieux écrire
        // que laisser croire : à l'échelle, si la Terre faisait ce disque,
        // la Lune serait à trois mètres et le Soleil à plus d'un
        // kilomètre. La figure est juste en géométrie, fausse en échelle.
        Text(
          'Tailles et distances ne sont pas à l\'échelle : '
          'le Soleil serait mille fois plus loin.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(
            color: tokens.inkSubtle,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _Curseur(
          nom: 'position',
          valeur: longitude,
          min: 0,
          max: 360,
          suffixe: '°',
          accent: widget.accent,
          onChanged: (double v) => setState(() {
            _tenue = true;
            _longitude = v;
          }),
        ),
        _Curseur(
          nom: 'hauteur',
          valeur: _latitude,
          min: -EclipseFigure.inclinaison,
          max: EclipseFigure.inclinaison,
          suffixe: '°',
          accent: widget.accent,
          onChanged: (double v) => setState(() {
            _tenue = true;
            _latitude = v;
          }),
        ),
      ],
    );
  }
}

/// Un curseur réel, avec son nom et sa valeur.
class _Curseur extends StatelessWidget {
  const _Curseur({
    required this.nom,
    required this.valeur,
    required this.min,
    required this.max,
    required this.suffixe,
    required this.accent,
    required this.onChanged,
  });

  final String nom;
  final double valeur;
  final double min;
  final double max;
  final String suffixe;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 64,
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
          width: 42,
          child: Text(
            '${valeur.round()}$suffixe',
            textAlign: TextAlign.right,
            style: AppTypography.formula(size: 14, color: accent),
          ),
        ),
      ],
    );
  }
}

class _EclipsePainter extends CustomPainter {
  const _EclipsePainter({
    required this.longitude,
    required this.latitude,
    required this.type,
    required this.accent,
    required this.trait,
    required this.muted,
  });

  final double longitude;
  final double latitude;
  final TypeEclipse type;
  final Color accent;
  final Color trait;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    const double axeY = 96;
    const double xSoleil = 40;
    final double xTerre = size.width * 0.60;
    final double rayonOrbite = math.min(size.width * 0.28, 70);

    _fond(canvas, size);

    // L'axe Soleil-Terre : la seule ligne sur laquelle une éclipse devient
    // possible. Discret, parce que c'est une aide de lecture et non une
    // chose qui existe dans le ciel.
    canvas.drawLine(
      const Offset(xSoleil, axeY),
      Offset(size.width - 6, axeY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 1,
    );

    _orbite(canvas, xTerre, axeY, rayonOrbite);

    // La position de la Lune : la longitude la place sur l'orbite, la
    // hauteur la décale hors du plan.
    final double rad = longitude * math.pi / 180;
    final double lx = xTerre - math.cos(rad) * rayonOrbite;
    final double ly =
        axeY + math.sin(rad) * rayonOrbite * 0.26 - latitude * 4.6;
    // Devant ou derrière la Terre : la Lune passe sous le disque terrestre
    // quand elle est du côté opposé au Soleil.
    final bool lunePremierPlan = math.cos(rad) > 0;

    if (!lunePremierPlan) {
      _lune(canvas, Offset(lx, ly), const Offset(xSoleil, axeY));
    }
    _coneSiEclipse(canvas, Offset(lx, ly), Offset(xTerre, axeY));
    _soleil(canvas, const Offset(xSoleil, axeY));
    _terre(canvas, Offset(xTerre, axeY), const Offset(xSoleil, axeY));
    if (lunePremierPlan) {
      _lune(canvas, Offset(lx, ly), const Offset(xSoleil, axeY));
    }

    _etiquette(canvas, const Offset(xSoleil, axeY), 20, 'Soleil');
    _etiquette(canvas, Offset(xTerre, axeY), 15, 'Terre');
  }

  /// Le vide, et ses étoiles. Positions figées.
  void _fond(Canvas canvas, Size size) {
    final Rect cadre = Offset.zero & size;
    canvas.drawRect(
      cadre,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.6, -0.1),
          radius: 1.3,
          colors: <Color>[Color(0xFF131A2B), Color(0xFF05070D)],
        ).createShader(cadre),
    );
    final math.Random alea = math.Random(42);
    for (int i = 0; i < 70; i++) {
      canvas.drawCircle(
        Offset(alea.nextDouble() * size.width, alea.nextDouble() * size.height),
        alea.nextDouble() * 1.1 + 0.3,
        Paint()
          ..color = Colors.white.withValues(
            alpha: 0.25 + alea.nextDouble() * 0.5,
          ),
      );
    }
  }

  /// L'orbite lunaire, vue par la tranche et inclinée.
  ///
  /// C'est le seul point de vue depuis lequel la rareté des éclipses se
  /// voit : de dessus, l'inclinaison disparaît et le schéma suggère une
  /// éclipse par mois.
  void _orbite(Canvas canvas, double xTerre, double axeY, double rayon) {
    canvas.save();
    canvas.translate(xTerre, axeY);
    canvas.rotate(-0.17);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: rayon * 2,
        height: rayon * 0.52,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.restore();
  }

  /// Le Soleil : une sphère incandescente et sa couronne.
  void _soleil(Canvas canvas, Offset centre) {
    const Color feu = Color(0xFFFFC53D);
    Realisme.couronne(canvas, centre, 20, couleur: feu, portee: 2.9);
    canvas.drawCircle(
      centre,
      20,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFFFFF4C2), Color(0xFFFFB515), Color(0xFFE8730C)],
          stops: <double>[0, 0.6, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: 20)),
    );
    // Quelques taches : le Soleil n'est pas une surface unie, et c'est
    // Galilée qui l'a établi en les regardant dériver.
    final math.Random alea = math.Random(5);
    for (int i = 0; i < 4; i++) {
      final double r = 20 * math.sqrt(alea.nextDouble()) * 0.7;
      final double a = alea.nextDouble() * 2 * math.pi;
      canvas.drawCircle(
        centre + Offset(math.cos(a) * r, math.sin(a) * r),
        1.4 + alea.nextDouble() * 1.6,
        Paint()..color = const Color(0xFFB4530A).withValues(alpha: 0.45),
      );
    }
  }

  /// La Terre : océans, continents, atmosphère, et sa face nuit.
  void _terre(Canvas canvas, Offset centre, Offset soleil) {
    const double rayon = 15;
    final Offset versSoleil = (soleil - centre) / (soleil - centre).distance;
    Realisme.atmosphere(canvas, centre, rayon, couleur: const Color(0xFF7FB9F0));
    Realisme.sphere(
      canvas,
      centre,
      rayon,
      couleur: const Color(0xFF1F5FA8),
      lumiere: versSoleil,
    );
    Realisme.continents(canvas, centre, rayon, graine: 3, nombre: 4);
    _faceNuit(canvas, centre, rayon, versSoleil);
  }

  /// La Lune : grise, criblée, éclairée du côté du Soleil.
  ///
  /// La figure est une vue de dessus du système, pas une vue depuis la
  /// Terre. Y dessiner une phase lunaire serait une faute : dans ce
  /// point de vue, la Lune n'a pas de phase, elle a un côté jour et un
  /// côté nuit, exactement comme la Terre à côté d'elle. La phase est ce
  /// que cette même géométrie produit quand on la regarde d'ici — et
  /// c'est ce que montre l'autre figure du chapitre.
  void _lune(Canvas canvas, Offset centre, Offset soleil) {
    const double rayon = 7.5;
    final Offset versSoleil = (soleil - centre) / (soleil - centre).distance;
    Realisme.sphere(
      canvas,
      centre,
      rayon,
      couleur: const Color(0xFFB8B5AD),
      lumiere: versSoleil,
    );
    Realisme.crateres(
      canvas,
      centre,
      rayon,
      graine: 7,
      nombre: 9,
      intensite: 1.6,
    );
    _faceNuit(canvas, centre, rayon, versSoleil);
  }

  /// Assombrit la moitié de la sphère qui tourne le dos au Soleil.
  ///
  /// Les deux astres reçoivent le même traitement, et c'est voulu : le
  /// jour et la nuit sont le même phénomène sur la Terre et sur la Lune.
  void _faceNuit(
    Canvas canvas,
    Offset centre,
    double rayon,
    Offset versSoleil,
  ) {
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: rayon)),
    );
    // On tourne le repère pour que « l'opposé du Soleil » soit la droite,
    // puis on noircit ce demi-disque. Le flou adoucit le terminateur,
    // qui dans la réalité n'est pas une arête nette.
    canvas.rotate(math.atan2(versSoleil.dy, versSoleil.dx));
    canvas.drawRect(
      Rect.fromLTWH(-rayon * 1.05, -rayon, rayon * 1.05, rayon * 2),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.62)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rayon * 0.22),
    );
    canvas.restore();
  }

  /// Le cône d'ombre, quand il tombe juste.
  ///
  /// Le dessiner en permanence laisserait croire qu'une éclipse a lieu
  /// chaque mois, ce qui est précisément l'erreur à défaire.
  void _coneSiEclipse(Canvas canvas, Offset lune, Offset terre) {
    if (type != TypeEclipse.soleil && type != TypeEclipse.lune) return;
    final bool deSoleil = type == TypeEclipse.soleil;
    final Offset depuis = deSoleil ? lune : terre;
    final Offset vers = deSoleil ? terre : lune;
    Realisme.coneOmbre(
      canvas,
      depuis,
      deSoleil ? 7.5 : 15,
      vers - depuis,
      (vers - depuis).distance,
      couleur: Colors.black,
    );
  }

  void _etiquette(Canvas canvas, Offset centre, double rayon, String nom) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: nom,
        style: const TextStyle(
          fontFamily: AppTypography.body,
          fontFamilyFallback: AppTypography.replis,
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      centre.translate(-painter.width / 2, rayon + 5),
    );
  }

  @override
  bool shouldRepaint(_EclipsePainter old) =>
      old.longitude != longitude ||
      old.latitude != latitude ||
      old.type != type ||
      old.accent != accent;
}
