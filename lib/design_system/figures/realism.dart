/// Outils de rendu pour les figures qui représentent des choses réelles.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// De quoi dessiner un objet réel comme un objet réel.
///
/// Les figures de ce dossier étaient toutes faites de disques plats et de
/// traits. C'est lisible, et c'est ce qu'on trouve dans les manuels — mais
/// une Lune qui est un rond gris n'apprend rien de la Lune, et un appareil
/// digestif fait de pastilles reliées par un fil n'apprend rien du corps.
/// Quand la figure montre une chose qui existe, elle doit s'en approcher :
/// la sphère doit être éclairée d'un côté, la Lune doit porter ses cratères,
/// Jupiter ses bandes, Mars sa calotte.
///
/// Rien ici n'est décoratif au sens où on pourrait l'enlever sans perte.
/// L'ombrage d'une sphère **est** l'information quand on parle de phases ;
/// le dégradé du limbe est ce qui dit qu'un astre est une boule et non un
/// disque ; la couronne du Soleil est ce qui le distingue d'une planète
/// jaune. Un schéma plat demande à l'élève de faire ce travail dans sa
/// tête, et la plupart ne le font pas.
///
/// Tout est déterministe — les cratères viennent d'un générateur ensemencé,
/// jamais de `Random()` sans graine — pour que les captures de référence
/// restent stables d'une exécution à l'autre.
abstract final class Realisme {
  /// Direction d'éclairement par défaut, en haut à gauche.
  static const Offset lumiereParDefaut = Offset(-0.45, -0.5);

  /// Part de lumière ambiante : ce qui reste visible côté nuit.
  ///
  /// Zéro donnerait un noir absolu, qui est physiquement juste dans le vide
  /// mais illisible sur un écran. Une valeur basse laisse deviner le volume
  /// sans prétendre qu'il y a de la lumière là où il n'y en a pas.
  static const double ambiantParDefaut = 0.16;

  /// Fraction du disque visible qui est éclairée, pour un angle de phase.
  ///
  /// L'angle de phase est l'angle Soleil-astre-observateur, en degrés : 0
  /// donne un disque plein, 180 un disque noir, 90 un quartier. La formule
  /// est celle d'une sphère éclairée par un faisceau parallèle.
  ///
  /// Exposée pour que les tests puissent la confronter à la surface
  /// réellement peinte, plutôt que de croire le dessin sur parole.
  static double fractionEclairee(double anglePhaseDegres) {
    final double rad = anglePhaseDegres * math.pi / 180;
    return (1 + math.cos(rad)) / 2;
  }

  /// Le contour de la partie non éclairée d'un disque de rayon [rayon].
  ///
  /// La frontière jour-nuit d'une sphère est un grand cercle ; vue de face
  /// elle se projette en demi-ellipse, dont la largeur vaut
  /// `rayon × |cos(angle)|`. C'est ce qui donne aux croissants leur bord
  /// intérieur courbe — un bord droit serait le signe qu'on a dessiné un
  /// disque découpé et non une boule éclairée.
  ///
  /// [anglePhaseDegres] de 0 rend un chemin vide, 180 le disque entier.
  static Path contourNuit(double rayon, double anglePhaseDegres) {
    double angle = anglePhaseDegres % 360;
    if (angle < 0) angle += 360;
    if (angle == 0) return Path();

    final Rect disque = Rect.fromCircle(center: Offset.zero, radius: rayon);
    if (angle == 180) return Path()..addOval(disque);

    // Le cycle est symétrique : après le plein, l'ombre passe simplement
    // de l'autre côté. On construit donc le cas « ombre à droite » puis on
    // le renverse, plutôt que de tenir deux fois la même géométrie — une
    // erreur dans l'une des deux branches serait invisible dans l'autre.
    final bool miroir = angle > 180;
    final double equivalent = miroir ? 360 - angle : angle;
    final double cos = math.cos(equivalent * math.pi / 180);
    final Rect terminateur = Rect.fromCenter(
      center: Offset.zero,
      width: rayon * cos.abs() * 2,
      height: rayon * 2,
    );

    // Le demi-disque de droite, du haut vers le bas par le limbe…
    final Path chemin = Path()
      ..moveTo(0, -rayon)
      ..arcTo(disque, -math.pi / 2, math.pi, false);
    // … puis le retour par le terminateur. Il bombe vers la droite quand
    // l'astre est presque plein — l'ombre n'est alors qu'un croissant
    // mince, et l'ellipse se retranche du demi-disque. Il bombe vers la
    // gauche après le quartier, et s'y ajoute.
    chemin
      ..arcTo(terminateur, math.pi / 2, cos > 0 ? -math.pi : math.pi, false)
      ..close();

    if (!miroir) return chemin;
    // Symétrie par rapport à l'axe vertical, en colonnes comme l'attend
    // Path.transform.
    return chemin.transform(
      Float64List.fromList(<double>[
        -1, 0, 0, 0, //
        0, 1, 0, 0, //
        0, 0, 1, 0, //
        0, 0, 0, 1, //
      ]),
    );
  }

  /// Peint une sphère éclairée, avec son dégradé et son limbe sombre.
  ///
  /// [couleur] est la teinte de la surface en pleine lumière. Le reste est
  /// calculé : le reflet est décalé vers la source, le limbe s'assombrit,
  /// et le côté opposé tombe à [ambiant].
  static void sphere(
    Canvas canvas,
    Offset centre,
    double rayon, {
    required Color couleur,
    Offset lumiere = lumiereParDefaut,
    double ambiant = ambiantParDefaut,
  }) {
    final Rect cadre = Rect.fromCircle(center: centre, radius: rayon);
    // Le reflet n'est pas au centre : c'est ce décalage qui fait la boule.
    final Alignment reflet = Alignment(
      lumiere.dx.clamp(-1.0, 1.0),
      lumiere.dy.clamp(-1.0, 1.0),
    );
    canvas.drawCircle(
      centre,
      rayon,
      Paint()
        ..shader = RadialGradient(
          center: reflet,
          radius: 1.05,
          colors: <Color>[
            _eclaircir(couleur, 0.38),
            couleur,
            Color.lerp(couleur, Colors.black, 1 - ambiant)!,
          ],
          stops: const <double>[0, 0.52, 1],
        ).createShader(cadre),
    );
    // L'assombrissement du bord : sans lui, la sphère redevient un disque
    // dès qu'on la regarde une seconde fois.
    canvas.drawCircle(
      centre,
      rayon,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            couleur.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.26),
          ],
          stops: const <double>[0.72, 1],
        ).createShader(cadre),
    );
  }

  /// Pose l'ombre de la phase sur une sphère déjà peinte.
  static void phase(
    Canvas canvas,
    Offset centre,
    double rayon,
    double anglePhaseDegres, {
    double ambiant = ambiantParDefaut,
  }) {
    final Path nuit = contourNuit(rayon, anglePhaseDegres);
    if (nuit.getBounds().isEmpty) return;
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.drawPath(
      nuit,
      Paint()..color = Colors.black.withValues(alpha: 1 - ambiant),
    );
    canvas.restore();
  }

  /// Les cratères d'un astre sans atmosphère, déterministes.
  ///
  /// Les positions viennent d'un générateur ensemencé : la Lune a toujours
  /// les mêmes, comme la vraie. Les cratères près du bord sont aplatis par
  /// la perspective, ce qui évite l'effet « pois sur un rond ».
  static void crateres(
    Canvas canvas,
    Offset centre,
    double rayon, {
    int graine = 7,
    int nombre = 14,
    Offset lumiere = lumiereParDefaut,
    double intensite = 1,
  }) {
    final math.Random alea = math.Random(graine);
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: centre, radius: rayon)),
    );
    for (int i = 0; i < nombre; i++) {
      // Racine carrée du tirage : sans elle les cratères s'entassent au
      // centre, parce qu'un tirage uniforme en rayon n'est pas uniforme
      // en surface.
      final double r = rayon * math.sqrt(alea.nextDouble()) * 0.92;
      final double theta = alea.nextDouble() * 2 * math.pi;
      final double taille = rayon * (0.055 + alea.nextDouble() * 0.13);
      final Offset position = centre + Offset(
        math.cos(theta) * r,
        math.sin(theta) * r,
      );
      // Aplatissement dû à la courbure : plus on s'éloigne du centre du
      // disque, plus le cratère est vu de biais.
      final double obliquite = 1 - (r / rayon) * 0.55;
      final Rect cuvette = Rect.fromCenter(
        center: position,
        width: taille * 2,
        height: taille * 2 * obliquite,
      );
      canvas.drawOval(
        cuvette,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.13 * intensite),
      );
      // Le liseré clair du côté de la lumière : c'est lui qui fait creux
      // plutôt que tache.
      canvas.drawArc(
        cuvette.shift(-lumiere * taille * 0.22),
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.6, taille * 0.16)
          ..color = Colors.white.withValues(alpha: 0.10 * intensite),
      );
    }
    canvas.restore();
  }

  /// Des bandes nuageuses parallèles, pour une géante gazeuse.
  static void bandes(
    Canvas canvas,
    Offset centre,
    double rayon, {
    required Color couleur,
    int nombre = 7,
    int graine = 11,
  }) {
    final math.Random alea = math.Random(graine);
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: centre, radius: rayon)),
    );
    for (int i = 0; i < nombre; i++) {
      final double y = centre.dy - rayon + rayon * 2 * (i + 0.5) / nombre;
      final double epaisseur = rayon * 2 / nombre * (0.5 + alea.nextDouble() * 0.5);
      final bool sombre = i.isOdd;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(centre.dx, y),
          width: rayon * 2,
          height: epaisseur,
        ),
        Paint()
          ..color = (sombre
                  ? Color.lerp(couleur, Colors.brown.shade900, 0.45)!
                  : _eclaircir(couleur, 0.22))
              .withValues(alpha: 0.5),
      );
    }
    canvas.restore();
  }

  /// Une calotte polaire blanche, en haut et en bas du disque.
  static void calottes(
    Canvas canvas,
    Offset centre,
    double rayon, {
    double etendue = 0.22,
  }) {
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: centre, radius: rayon)),
    );
    for (final double signe in <double>[-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centre.dx, centre.dy + signe * rayon * 0.94),
          width: rayon * 1.5,
          height: rayon * etendue * 2,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.72),
      );
    }
    canvas.restore();
  }

  /// Des continents, posés toujours au même endroit.
  static void continents(
    Canvas canvas,
    Offset centre,
    double rayon, {
    Color couleur = const Color(0xFF3E8E4F),
    int graine = 3,
    int nombre = 5,
  }) {
    final math.Random alea = math.Random(graine);
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: centre, radius: rayon)),
    );
    for (int i = 0; i < nombre; i++) {
      final double theta = alea.nextDouble() * 2 * math.pi;
      final double r = rayon * math.sqrt(alea.nextDouble()) * 0.8;
      final Offset base = centre + Offset(
        math.cos(theta) * r,
        math.sin(theta) * r,
      );
      // Une forme irrégulière fermée : un continent n'est pas un rond.
      final Path terre = Path();
      const int sommets = 9;
      for (int s = 0; s <= sommets; s++) {
        final double a = s / sommets * 2 * math.pi;
        final double d = rayon * (0.12 + alea.nextDouble() * 0.2);
        final Offset point =
            base + Offset(math.cos(a) * d, math.sin(a) * d * 0.7);
        if (s == 0) {
          terre.moveTo(point.dx, point.dy);
        } else {
          terre.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(terre..close(), Paint()..color = couleur);
    }
    canvas.restore();
  }

  /// Une couronne lumineuse autour d'une source.
  ///
  /// Trois halos de rayons croissants plutôt qu'un seul : la décroissance
  /// est alors plus douce qu'un dégradé unique, et le Soleil cesse de
  /// ressembler à un disque jaune posé sur du noir.
  static void couronne(
    Canvas canvas,
    Offset centre,
    double rayon, {
    required Color couleur,
    double portee = 2.6,
  }) {
    for (final (double facteur, double opacite) in <(double, double)>[
      (portee, 0.10),
      (portee * 0.66, 0.16),
      (portee * 0.4, 0.26),
    ]) {
      canvas.drawCircle(
        centre,
        rayon * facteur,
        Paint()
          ..color = couleur.withValues(alpha: opacite)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  /// Un liseré d'atmosphère sur le limbe d'une planète.
  static void atmosphere(
    Canvas canvas,
    Offset centre,
    double rayon, {
    required Color couleur,
  }) {
    canvas.drawCircle(
      centre,
      rayon * 1.06,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rayon * 0.12
        ..color = couleur.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  /// Un cône d'ombre derrière un astre, avec ombre et pénombre.
  ///
  /// L'ombre d'une sphère éclairée par une source étendue n'est pas un
  /// cylindre : elle se resserre, et elle est bordée d'une pénombre. C'est
  /// cette forme qui explique qu'une éclipse totale ne concerne qu'une
  /// bande étroite de la Terre.
  static void coneOmbre(
    Canvas canvas,
    Offset sommet,
    double rayonAstre,
    Offset direction,
    double longueur, {
    required Color couleur,
  }) {
    final double norme = direction.distance;
    if (norme == 0 || longueur <= 0) return;
    final Offset u = direction / norme;
    final Offset perpendiculaire = Offset(-u.dy, u.dx);
    final Offset bout = sommet + u * longueur;

    // La pénombre s'évase, l'ombre se resserre : les deux cônes sont
    // dessinés séparément parce qu'ils disent deux choses différentes.
    final Path penombre = Path()
      ..moveTo(
        (sommet + perpendiculaire * rayonAstre).dx,
        (sommet + perpendiculaire * rayonAstre).dy,
      )
      ..lineTo(
        (bout + perpendiculaire * rayonAstre * 2.1).dx,
        (bout + perpendiculaire * rayonAstre * 2.1).dy,
      )
      ..lineTo(
        (bout - perpendiculaire * rayonAstre * 2.1).dx,
        (bout - perpendiculaire * rayonAstre * 2.1).dy,
      )
      ..lineTo(
        (sommet - perpendiculaire * rayonAstre).dx,
        (sommet - perpendiculaire * rayonAstre).dy,
      )
      ..close();
    canvas.drawPath(
      penombre,
      Paint()..color = couleur.withValues(alpha: 0.16),
    );
    // Le liseré de la pénombre. Dans le vide, une ombre ne se voit pas —
    // il n'y a pas de poussière pour la révéler. Ce contour est donc une
    // convention de lecture assumée, sans quoi le cône serait du noir sur
    // du noir et la figure ne montrerait rien du tout.
    canvas.drawPath(
      penombre,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.18),
    );

    final Path ombre = Path()
      ..moveTo(
        (sommet + perpendiculaire * rayonAstre * 0.92).dx,
        (sommet + perpendiculaire * rayonAstre * 0.92).dy,
      )
      ..lineTo(bout.dx, bout.dy)
      ..lineTo(
        (sommet - perpendiculaire * rayonAstre * 0.92).dx,
        (sommet - perpendiculaire * rayonAstre * 0.92).dy,
      )
      ..close();
    canvas.drawPath(
      ombre,
      Paint()..color = couleur.withValues(alpha: 0.55),
    );
    canvas.drawPath(
      ombre,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  /// Une paroi organique : un contour irrégulier mais stable.
  ///
  /// Les organes n'ont pas de bords droits. Un rectangle arrondi pour un
  /// estomac ou un poumon est la marque du schéma, pas de l'organe.
  static Path paroiOrganique(
    Rect cadre, {
    int graine = 5,
    int sommets = 14,
    double irregularite = 0.1,
  }) {
    final math.Random alea = math.Random(graine);
    final Offset centre = cadre.center;
    final List<Offset> points = <Offset>[];
    for (int i = 0; i < sommets; i++) {
      final double a = i / sommets * 2 * math.pi;
      final double variation = 1 + (alea.nextDouble() - 0.5) * 2 * irregularite;
      points.add(
        Offset(
          centre.dx + math.cos(a) * cadre.width / 2 * variation,
          centre.dy + math.sin(a) * cadre.height / 2 * variation,
        ),
      );
    }
    // Courbes de Bézier entre les milieux des segments : le contour est
    // alors lisse partout, sans angle visible.
    final Path chemin = Path();
    Offset milieu(Offset a, Offset b) => (a + b) / 2;
    chemin.moveTo(
      milieu(points.last, points.first).dx,
      milieu(points.last, points.first).dy,
    );
    for (int i = 0; i < points.length; i++) {
      final Offset suivant = points[(i + 1) % points.length];
      final Offset fin = milieu(points[i], suivant);
      chemin.quadraticBezierTo(
        points[i].dx,
        points[i].dy,
        fin.dx,
        fin.dy,
      );
    }
    return chemin..close();
  }

  /// Un dégradé de chair, du clair au foncé, pour remplir un organe.
  static Paint chair(Rect cadre, Color couleur) => Paint()
    ..shader = ui.Gradient.linear(
      cadre.topLeft,
      cadre.bottomRight,
      <Color>[
        _eclaircir(couleur, 0.25),
        couleur,
        Color.lerp(couleur, Colors.black, 0.22)!,
      ],
      <double>[0, 0.55, 1],
    );

  static Color _eclaircir(Color couleur, double part) =>
      Color.lerp(couleur, Colors.white, part)!;
}
