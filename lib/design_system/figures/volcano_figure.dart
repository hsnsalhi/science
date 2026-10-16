/// Un volcan en coupe : ce qu'il y a sous la montagne.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'realism.dart';

/// L'état du volcan.
enum EtatVolcan {
  /// Au repos : la chambre se remplit lentement.
  repos('Au repos', 'Le magma s\'accumule sous la montagne.'),

  /// La pression monte, le sol se bombe.
  pression('Sous pression', 'Le sol se bombe, la roche se fissure.'),

  /// Lave fluide qui coule en rivières.
  rouge('Éruption rouge', 'La lave est fluide : elle coule, on peut fuir.'),

  /// Lave épaisse qui bouche et explose.
  gris(
    'Éruption grise',
    'La lave épaisse a bouché la cheminée : tout part d\'un coup.',
  );

  const EtatVolcan(this.titre, this.explication);

  final String titre;
  final String explication;
}

/// Une coupe de volcan, de la chambre magmatique au panache.
///
/// Un volcan est un objet que tout le monde croit connaître et que personne
/// n'a vu en coupe. Le dessiner comme un triangle avec un trait rouge au
/// milieu ne dit rien de l'essentiel : que le magma vient de très bas, qu'il
/// s'accumule d'abord dans une poche, et que la montagne elle-même est faite
/// des couches de ses éruptions passées.
///
/// La coupe montre donc ces couches alternées — coulées sombres et lits de
/// cendres clairs —, la chambre en profondeur, la cheminée qui la relie au
/// cratère, et les dykes latéraux par où le magma s'échappe parfois sur le
/// flanc. Les deux types d'éruption que le chapitre distingue se voient
/// alors pour ce qu'ils sont : une différence de fluidité, pas de taille.
class VolcanoFigure extends StatefulWidget {
  const VolcanoFigure({required this.accent, super.key});

  final Color accent;

  /// Remplissage de la chambre magmatique, de 0 à 1, selon l'état.
  ///
  /// Exposé pour que le test vérifie ce que la figure raconte : la chambre
  /// se remplit au repos, atteint son maximum sous pression, et se vide en
  /// éruption. Une figure qui montrerait une chambre pleine après
  /// l'éruption enseignerait le contraire du chapitre.
  static double remplissage(EtatVolcan etat) => switch (etat) {
    EtatVolcan.repos => 0.45,
    EtatVolcan.pression => 1,
    EtatVolcan.rouge => 0.55,
    EtatVolcan.gris => 0.25,
  };

  /// La cheminée est-elle obstruée ?
  ///
  /// C'est la cause de la différence entre les deux éruptions : une lave
  /// épaisse bouche le conduit, la pression monte, et la sortie se fait
  /// d'un coup.
  static bool chemineeObstruee(EtatVolcan etat) => etat == EtatVolcan.gris;

  /// Y a-t-il de la matière qui sort ?
  static bool enEruption(EtatVolcan etat) =>
      etat == EtatVolcan.rouge || etat == EtatVolcan.gris;

  @override
  State<VolcanoFigure> createState() => _VolcanoFigureState();
}

class _VolcanoFigureState extends State<VolcanoFigure> {
  EtatVolcan _etat = EtatVolcan.repos;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 230,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return CustomPaint(
                  size: Size(contraintes.maxWidth, 230),
                  painter: _VolcanPainter(etat: _etat, accent: widget.accent),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _etat.titre,
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 17, color: widget.accent),
        ),
        Text(
          _etat.explication,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: EtatVolcan.values.map((EtatVolcan e) {
            return ChoiceChip(
              label: Text(e.titre),
              selected: e == _etat,
              onSelected: (_) {
                context.tapFeedback();
                setState(() => _etat = e);
              },
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _VolcanPainter extends CustomPainter {
  const _VolcanPainter({required this.etat, required this.accent});

  final EtatVolcan etat;
  final Color accent;

  static const Color _magma = Color(0xFFE8521F);
  static const Color _roche = Color(0xFF5A4A41);
  static const Color _croute = Color(0xFF7A6354);

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width * 0.46;
    final double solY = size.height * 0.52;
    final double sommetY = size.height * 0.12;

    _ciel(canvas, size, solY);
    _sousSol(canvas, size, solY);
    final Path cone = _montagne(canvas, size, cx, solY, sommetY);
    _couches(canvas, cone, cx, solY, sommetY);
    _chambreEtCheminee(canvas, size, cx, solY, sommetY);
    if (VolcanoFigure.enEruption(etat)) {
      _eruption(canvas, size, cx, sommetY, solY);
    }
  }

  /// Le ciel, assombri par les cendres pendant une éruption grise.
  void _ciel(Canvas canvas, Size size, double solY) {
    final Rect cadre = Rect.fromLTWH(0, 0, size.width, solY + 2);
    final bool cendres = etat == EtatVolcan.gris;
    canvas.drawRect(
      cadre,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: cendres
              ? <Color>[const Color(0xFF4A4038), const Color(0xFF8A7A6A)]
              : <Color>[const Color(0xFF5FA3DE), const Color(0xFFBFDDF4)],
        ).createShader(cadre),
    );
  }

  /// Le sous-sol, en couches de roche de plus en plus chaudes.
  void _sousSol(Canvas canvas, Size size, double solY) {
    final Rect cadre = Rect.fromLTWH(0, solY, size.width, size.height - solY);
    canvas.drawRect(
      cadre,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            _croute,
            _roche,
            Color(0xFF6B3326),
          ],
          stops: <double>[0, 0.45, 1],
        ).createShader(cadre),
    );
    // Des strates : la roche profonde est stratifiée, pas homogène, et
    // c'est ce qui permet de lire son histoire.
    final math.Random alea = math.Random(53);
    for (int i = 0; i < 9; i++) {
      final double y = solY + 8 + i * (size.height - solY) / 9;
      final Path strate = Path()..moveTo(-5, y);
      for (double x = 0; x <= size.width + 10; x += 24) {
        strate.lineTo(x, y + (alea.nextDouble() - 0.5) * 7);
      }
      canvas.drawPath(
        strate,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.black.withValues(alpha: 0.14),
      );
    }
  }

  /// Le cône du volcan. Rend son contour.
  Path _montagne(
    Canvas canvas,
    Size size,
    double cx,
    double solY,
    double sommetY,
  ) {
    final double demiBase = size.width * 0.34;
    // Un profil concave, comme celui d'un vrai strato-volcan : les flancs
    // sont raides en haut et s'évasent en bas, parce que la lave et les
    // cendres ne s'arrêtent pas au même endroit.
    final Path cone = Path()
      ..moveTo(cx - demiBase, solY + 2)
      ..cubicTo(
        cx - demiBase * 0.55, solY - 14,
        cx - 30, sommetY + 26,
        cx - 15, sommetY + 4,
      )
      ..lineTo(cx + 15, sommetY + 6)
      ..cubicTo(
        cx + 32, sommetY + 28,
        cx + demiBase * 0.58, solY - 12,
        cx + demiBase, solY + 2,
      )
      ..close();
    canvas.drawPath(cone, Realisme.chair(cone.getBounds(), _croute));
    return cone;
  }

  /// Les couches d'éruptions passées, dont la montagne est faite.
  void _couches(
    Canvas canvas,
    Path cone,
    double cx,
    double solY,
    double sommetY,
  ) {
    canvas.save();
    canvas.clipPath(cone);
    // Coulées sombres et lits de cendres clairs, alternés : c'est
    // l'empilement des éruptions passées, et c'est pourquoi le mot
    // « strato-volcan » existe.
    const int nombre = 26;
    for (int i = 0; i < nombre; i++) {
      final double t = i / nombre;
      final double y = sommetY + (solY - sommetY) * t;
      final double largeur = 30 + t * 190;
      final bool coulee = i.isEven;
      final Path couche = Path()
        ..moveTo(cx - largeur, y + 12)
        ..quadraticBezierTo(cx, y - 5, cx + largeur, y + 12)
        ..lineTo(cx + largeur, y + 15)
        ..quadraticBezierTo(cx, y - 1, cx - largeur, y + 15)
        ..close();
      canvas.drawPath(
        couche,
        Paint()
          ..color = (coulee
                  ? const Color(0xFF3F342D)
                  : const Color(0xFFA8937F))
              .withValues(alpha: 0.24),
      );
    }
    canvas.restore();
  }

  /// La chambre magmatique, la cheminée, et les dykes latéraux.
  void _chambreEtCheminee(
    Canvas canvas,
    Size size,
    double cx,
    double solY,
    double sommetY,
  ) {
    final double remplissage = VolcanoFigure.remplissage(etat);
    final Rect chambre = Rect.fromCenter(
      center: Offset(cx, size.height * 0.84),
      width: size.width * 0.42,
      height: size.height * 0.2,
    );

    // La poche : un contour irrégulier, parce qu'une chambre magmatique
    // n'est pas un ballon mais un réseau de fissures remplies.
    final Path poche = Realisme.paroiOrganique(
      chambre,
      graine: 61,
      sommets: 13,
      irregularite: 0.2,
    );
    // La part vide de la poche : de la roche fracturée, pas un trou noir.
    // Un remplissage trop sombre écraserait le magma, qui est pourtant ce
    // que la figure a à montrer.
    canvas.drawPath(
      poche,
      Paint()..color = const Color(0xFF3A2A22).withValues(alpha: 0.55),
    );

    // Le magma ne remplit la poche que jusqu'à un certain niveau, et ce
    // niveau est l'information : il monte au repos, culmine sous
    // pression, retombe après l'éruption.
    canvas.save();
    canvas.clipPath(poche);
    // Le contour organique déborde du cadre théorique : on mesure donc le
    // niveau sur la poche elle-même, sinon « à moitié pleine » ne
    // correspond pas à ce qu'on voit.
    final Rect reelle = poche.getBounds();
    final double hautMagma =
        reelle.bottom - reelle.height * remplissage;
    canvas.drawRect(
      Rect.fromLTRB(
        reelle.left - 10,
        hautMagma,
        reelle.right + 10,
        reelle.bottom + 10,
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFFFC14D),
            _magma,
            Color(0xFF9E2A0C),
          ],
        ).createShader(reelle),
    );
    canvas.restore();
    canvas.drawPath(
      poche,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.black.withValues(alpha: 0.5),
    );

    // La cheminée, qui relie la chambre au cratère. Elle est sinueuse :
    // le magma suit les fissures, il ne perce pas un tuyau droit.
    final Path cheminee = Path()
      ..moveTo(cx - 4, chambre.top + 6)
      ..cubicTo(
        cx + 14, solY + 24,
        cx - 16, solY - 20,
        cx - 2, sommetY + 8,
      );
    final bool bouchee = VolcanoFigure.chemineeObstruee(etat);
    canvas.drawPath(
      cheminee,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withValues(alpha: 0.45),
    );
    canvas.drawPath(
      cheminee,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = bouchee
            ? const Color(0xFF6B5547)
            : _magma.withValues(alpha: etat == EtatVolcan.repos ? 0.55 : 1),
    );

    // Le bouchon de lave épaisse, cause de l'explosion.
    if (bouchee) {
      canvas.drawCircle(
        Offset(cx - 2, sommetY + 14),
        9,
        Paint()..color = const Color(0xFF4F4038),
      );
    }

    // Un dyke latéral : le magma s'échappe parfois sur le flanc, et le
    // cratère n'est pas sa seule porte.
    canvas.drawPath(
      Path()
        ..moveTo(cx + 6, solY + 16)
        ..cubicTo(
          cx + 40, solY + 6,
          cx + 54, solY - 10,
          cx + 68, solY - 18,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = _magma.withValues(alpha: 0.5),
    );
  }

  /// Ce qui sort : une coulée, ou un panache.
  void _eruption(
    Canvas canvas,
    Size size,
    double cx,
    double sommetY,
    double solY,
  ) {
    final math.Random alea = math.Random(77);
    if (etat == EtatVolcan.rouge) {
      // Des coulées qui descendent les flancs, incandescentes en haut et
      // refroidies en bas : la lave noircit en avançant.
      for (final double sens in <double>[-1, 0.3, 1]) {
        final Path coulee = Path()
          ..moveTo(cx + sens * 6, sommetY + 8);
        double x = cx + sens * 6;
        double y = sommetY + 8;
        for (int i = 0; i < 5; i++) {
          x += sens * (10 + alea.nextDouble() * 14);
          y += 14 + alea.nextDouble() * 10;
          coulee.lineTo(x, y);
        }
        canvas.drawPath(
          coulee,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFFFFD66B),
                _magma,
                Color(0xFF5A2516),
              ],
            ).createShader(coulee.getBounds()),
        );
      }
      // La lueur au-dessus du cratère.
      canvas.drawCircle(
        Offset(cx, sommetY + 6),
        22,
        Paint()
          ..color = const Color(0xFFFF9838).withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    } else {
      // Le panache : des bouffées qui s'élargissent en montant, et la
      // nuée ardente qui dévale la pente — c'est elle qui tue.
      for (int i = 0; i < 16; i++) {
        final double t = i / 16;
        canvas.drawCircle(
          Offset(
            cx + (alea.nextDouble() - 0.5) * (14 + t * 90),
            sommetY + 6 - t * (sommetY - 4),
          ),
          8 + t * 24,
          Paint()
            ..color = const Color(0xFF6B6058)
                .withValues(alpha: 0.42 - t * 0.14)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
        );
      }
      for (final double sens in <double>[-1, 1]) {
        canvas.drawPath(
          Path()
            ..moveTo(cx + sens * 10, sommetY + 16)
            ..quadraticBezierTo(
              cx + sens * 70, sommetY + 70,
              cx + sens * 125, solY - 2,
            )
            ..lineTo(cx + sens * 125, solY + 8)
            ..quadraticBezierTo(
              cx + sens * 60, sommetY + 86,
              cx + sens * 10, sommetY + 32,
            )
            ..close(),
          Paint()
            ..color = const Color(0xFF8B7B6B).withValues(alpha: 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_VolcanPainter old) =>
      old.etat != etat || old.accent != accent;
}
