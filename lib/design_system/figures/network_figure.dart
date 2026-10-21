/// Un paquet qui traverse un réseau, et les liens qu'on peut couper.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Un nœud du réseau, avec sa place sur la figure.
///
/// Les positions sont données en fractions de la zone de dessin, pour que
/// la figure tienne aussi bien sur un téléphone que sur une tablette.
class NoeudReseau {
  const NoeudReseau(this.nom, this.x, this.y);

  /// Ce qui s'affiche dans la boîte.
  final String nom;

  /// Abscisse, entre 0 et 1.
  final double x;

  /// Ordonnée, entre 0 et 1.
  final double y;
}

/// Un réseau que l'élève sabote, et le paquet qui trouve un autre chemin.
///
/// « Internet a été conçu pour résister à la panne d'une partie de ses
/// machines » est une phrase qu'on lit partout et qui n'apprend rien tant
/// qu'on n'a pas coupé soi-même un câble pour voir le paquet passer
/// ailleurs. C'est exactement ce que la figure propose : toucher un lien
/// le coupe, et le chemin se recalcule sous les yeux.
///
/// Le chemin n'est pas dessiné à l'avance : il est cherché par un parcours
/// en largeur à chaque changement, comme le ferait un routeur. Couper
/// assez de liens finit donc par isoler le serveur, et la figure le dit
/// au lieu de tricher.
class NetworkFigure extends StatefulWidget {
  const NetworkFigure({required this.accent, super.key});

  /// Couleur d'accent de la matière.
  final Color accent;

  /// Les machines du réseau. La première est l'ordinateur de l'élève, la
  /// dernière le serveur qu'il veut joindre.
  static const List<NoeudReseau> noeuds = <NoeudReseau>[
    NoeudReseau('toi', 0.09, 0.5),
    NoeudReseau('A', 0.33, 0.2),
    NoeudReseau('B', 0.33, 0.8),
    NoeudReseau('C', 0.58, 0.5),
    NoeudReseau('D', 0.58, 0.14),
    NoeudReseau('E', 0.58, 0.86),
    NoeudReseau('serveur', 0.88, 0.5),
  ];

  /// Les câbles, par indices de nœuds.
  static const List<(int, int)> liens = <(int, int)>[
    (0, 1),
    (0, 2),
    (1, 3),
    (1, 4),
    (2, 3),
    (2, 5),
    (3, 6),
    (4, 6),
    (5, 6),
  ];

  /// Le plus court chemin de `depart` à `arrivee`, liens coupés exclus.
  ///
  /// Parcours en largeur : on explore d'abord tous les voisins, puis leurs
  /// voisins. Le premier chemin trouvé est donc le plus court en nombre de
  /// sauts, ce qui est bien le critère d'un routeur. Retourne une liste
  /// vide quand le serveur est injoignable.
  static List<int> chemin(Set<int> coupes, {int depart = 0, int arrivee = 6}) {
    final Map<int, List<int>> voisins = <int, List<int>>{};
    for (int i = 0; i < liens.length; i++) {
      if (coupes.contains(i)) continue;
      final (int a, int b) = liens[i];
      voisins.putIfAbsent(a, () => <int>[]).add(b);
      voisins.putIfAbsent(b, () => <int>[]).add(a);
    }

    final Map<int, int> venantDe = <int, int>{depart: -1};
    final List<int> file = <int>[depart];
    while (file.isNotEmpty) {
      final int courant = file.removeAt(0);
      if (courant == arrivee) break;
      for (final int suivant in voisins[courant] ?? const <int>[]) {
        if (venantDe.containsKey(suivant)) continue;
        venantDe[suivant] = courant;
        file.add(suivant);
      }
    }
    if (!venantDe.containsKey(arrivee)) return const <int>[];

    final List<int> route = <int>[];
    int noeud = arrivee;
    while (noeud != -1) {
      route.insert(0, noeud);
      noeud = venantDe[noeud]!;
    }
    return route;
  }

  /// Nombre de sauts d'un chemin : un saut par câble emprunté.
  static int sauts(List<int> chemin) =>
      chemin.isEmpty ? 0 : chemin.length - 1;

  @override
  State<NetworkFigure> createState() => _NetworkFigureState();
}

class _NetworkFigureState extends State<NetworkFigure>
    with SingleTickerProviderStateMixin {
  final Set<int> _coupes = <int>{};
  bool _demarre = false;

  late final AnimationController _voyage = AnimationController(
    duration: const Duration(milliseconds: 2600),
    vsync: this,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_demarre) return;
    _demarre = true;
    if (!context.reduceMotion) _voyage.repeat();
  }

  @override
  void dispose() {
    _voyage.dispose();
    super.dispose();
  }

  /// Le lien le plus proche d'un point touché, s'il est assez près.
  int? _lienSous(Offset point, Size taille) {
    double meilleure = 26;
    int? trouve;
    for (int i = 0; i < NetworkFigure.liens.length; i++) {
      final (int a, int b) = NetworkFigure.liens[i];
      final Offset pa = _position(NetworkFigure.noeuds[a], taille);
      final Offset pb = _position(NetworkFigure.noeuds[b], taille);
      final double d = _distanceAuSegment(point, pa, pb);
      if (d < meilleure) {
        meilleure = d;
        trouve = i;
      }
    }
    return trouve;
  }

  static Offset _position(NoeudReseau n, Size taille) =>
      Offset(n.x * taille.width, n.y * taille.height);

  /// Distance d'un point à un segment, et non à la droite qui le porte :
  /// toucher au-delà du bout d'un câble ne doit pas le sélectionner.
  static double _distanceAuSegment(Offset p, Offset a, Offset b) {
    final Offset ab = b - a;
    final double longueur2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (longueur2 == 0) return (p - a).distance;
    final double t =
        (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / longueur2).clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }

  void _basculer(int lien) {
    setState(() {
      if (_coupes.contains(lien)) {
        _coupes.remove(lien);
      } else {
        _coupes.add(lien);
      }
    });
    if (NetworkFigure.chemin(_coupes).isEmpty) {
      context.errorFeedback();
    } else {
      context.tapFeedback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final List<int> route = NetworkFigure.chemin(_coupes);
    final bool coupe = route.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                final Size taille = Size(contraintes.maxWidth, 200);
                return GestureDetector(
                  onTapUp: (TapUpDetails details) {
                    final int? lien =
                        _lienSous(details.localPosition, taille);
                    if (lien != null) _basculer(lien);
                  },
                  child: AnimatedBuilder(
                    animation: _voyage,
                    builder: (BuildContext context, Widget? _) => CustomPaint(
                      size: taille,
                      painter: _ReseauPainter(
                        coupes: _coupes,
                        route: route,
                        avance: context.reduceMotion ? 0.5 : _voyage.value,
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
          coupe
              ? 'serveur injoignable'
              : '${NetworkFigure.sauts(route)} sauts : '
                  '${route.map((int i) => NetworkFigure.noeuds[i].nom).join(' puis ')}',
          textAlign: TextAlign.center,
          style: AppTypography.formula(
            size: 15,
            color: coupe ? tokens.error : widget.accent,
          ),
        ),
        Text(
          coupe
              ? 'Tu as coupé tous les chemins. Il en faut beaucoup : c’est '
                  'exactement ce pour quoi le réseau a été conçu.'
              : _coupes.isEmpty
                  ? 'Touche un câble pour le couper. Le paquet en prendra '
                      'un autre.'
                  : '${_coupes.length} câble${_coupes.length > 1 ? 's' : ''} '
                      'coupé${_coupes.length > 1 ? 's' : ''}, et le paquet '
                      'passe quand même.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(
            color: coupe ? tokens.error : tokens.inkSubtle,
          ),
        ),
        if (_coupes.isNotEmpty)
          TextButton(
            onPressed: () {
              setState(_coupes.clear);
              context.tapFeedback();
            },
            child: const Text('Tout réparer'),
          ),
      ],
    );
  }
}

/// Les machines, les câbles, et le paquet qui avance.
class _ReseauPainter extends CustomPainter {
  const _ReseauPainter({
    required this.coupes,
    required this.route,
    required this.avance,
    required this.accent,
    required this.tokens,
  });

  final Set<int> coupes;
  final List<int> route;
  final double avance;
  final Color accent;
  final AppTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tokens.surfaceAlt);

    Offset position(int i) => Offset(
          NetworkFigure.noeuds[i].x * size.width,
          NetworkFigure.noeuds[i].y * size.height,
        );

    // Les câbles empruntés sont repérés pour être tracés en évidence.
    final Set<String> empruntes = <String>{
      for (int i = 0; i + 1 < route.length; i++)
        '${math.min(route[i], route[i + 1])}-'
            '${math.max(route[i], route[i + 1])}',
    };

    for (int i = 0; i < NetworkFigure.liens.length; i++) {
      final (int a, int b) = NetworkFigure.liens[i];
      final Offset pa = position(a);
      final Offset pb = position(b);
      final bool casse = coupes.contains(i);
      final bool emprunte =
          empruntes.contains('${math.min(a, b)}-${math.max(a, b)}');

      if (casse) {
        // Un câble coupé se dessine coupé : deux moignons et un vide au
        // milieu. Un trait en pointillé se lirait comme « liaison faible ».
        final Offset milieu = (pa + pb) / 2;
        final Offset vers = (pb - pa) / (pb - pa).distance;
        final Paint moignon = Paint()
          ..color = tokens.error.withValues(alpha: 0.7)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(pa, milieu - vers * 9, moignon);
        canvas.drawLine(milieu + vers * 9, pb, moignon);
        // La croix qui dit « coupé », à l'endroit de la coupure.
        final Offset perp = Offset(-vers.dy, vers.dx) * 5;
        canvas.drawLine(milieu - perp, milieu + perp, moignon);
      } else {
        canvas.drawLine(
          pa,
          pb,
          Paint()
            ..color = emprunte
                ? accent
                : tokens.inkSubtle.withValues(alpha: 0.35)
            ..strokeWidth = emprunte ? 3.4 : 1.8
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    for (int i = 0; i < NetworkFigure.noeuds.length; i++) {
      final NoeudReseau n = NetworkFigure.noeuds[i];
      final Offset p = position(i);
      final bool bout = i == 0 || i == NetworkFigure.noeuds.length - 1;
      final Rect boite = Rect.fromCenter(
        center: p,
        width: bout ? 54 : 30,
        height: 24,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(boite, const Radius.circular(5)),
        Paint()..color = bout ? accent : tokens.surfaceAlt,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(boite, const Radius.circular(5)),
        Paint()
          ..color = bout ? accent : tokens.inkMuted
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke,
      );
      _etiquette(
        canvas,
        n.nom,
        p,
        bout ? Colors.white : tokens.inkMuted,
      );
    }

    // Le paquet : un petit carré qui avance de saut en saut, pour qu'on
    // voie qu'il franchit des machines et non une ligne continue.
    if (route.length >= 2) {
      final double total = (route.length - 1).toDouble();
      final double place = avance * total;
      final int saut = place.floor().clamp(0, route.length - 2);
      final double part = place - saut;
      final Offset p =
          Offset.lerp(position(route[saut]), position(route[saut + 1]), part)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p, width: 13, height: 10),
          const Radius.circular(2),
        ),
        Paint()..color = tokens.warning,
      );
    }
  }

  void _etiquette(Canvas canvas, String texte, Offset centre, Color couleur) {
    final TextPainter peintre = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          color: couleur,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    peintre.paint(
      canvas,
      centre - Offset(peintre.width / 2, peintre.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ReseauPainter ancien) =>
      !setEquals(ancien.coupes, coupes) ||
      !listEquals(ancien.route, route) ||
      ancien.avance != avance ||
      ancien.accent != accent ||
      ancien.tokens != tokens;
}
