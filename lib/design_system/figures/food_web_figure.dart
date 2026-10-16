/// Un réseau alimentaire dont on peut retirer une espèce.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Une espèce du réseau, avec ce dont elle se nourrit.
class Espece {
  const Espece({
    required this.nom,
    required this.mange,
    required this.position,
  });

  final String nom;

  /// Ce que cette espèce mange. Vide pour un producteur, qui tire son
  /// énergie du Soleil.
  final List<String> mange;

  /// Place dans le dessin, en coordonnées relatives.
  final Offset position;

  bool get estProducteur => mange.isEmpty;
}

/// Cinq espèces d'un pré, et ce qui arrive quand l'une disparaît.
///
/// On retire une espèce d'une touche, et la figure grise celles qui
/// n'ont plus rien à manger — en suivant la chaîne jusqu'au bout, car
/// le prédateur d'une espèce affamée l'est à son tour.
///
/// L'intérêt tient au contraste entre deux retraits. Retirer l'herbe
/// vide le pré. Retirer le renard n'affame personne : rien ne grise, et
/// pourtant quelque chose se passe, que la figure ne montre pas et que
/// la leçon doit dire — les lapins pullulent, puis l'herbe manque. Une
/// figure qui prétendrait tout montrer mentirait ici.
class FoodWebFigure extends StatefulWidget {
  const FoodWebFigure({required this.accent, super.key});

  final Color accent;

  /// Le réseau du pré.
  static const List<Espece> reseau = <Espece>[
    Espece(nom: 'Herbe', mange: <String>[], position: Offset(0.5, 0.92)),
    Espece(nom: 'Lapin', mange: <String>['Herbe'], position: Offset(0.22, 0.54)),
    Espece(
      nom: 'Criquet',
      mange: <String>['Herbe'],
      position: Offset(0.78, 0.54),
    ),
    Espece(nom: 'Renard', mange: <String>['Lapin'], position: Offset(0.22, 0.12)),
    Espece(
      nom: 'Oiseau',
      mange: <String>['Criquet'],
      position: Offset(0.78, 0.12),
    ),
  ];

  /// Espèces privées de nourriture si [absente] disparaît.
  ///
  /// On ne s'arrête pas au premier rang : une espèce qui n'a plus rien
  /// à manger disparaît à son tour, et prive ses propres prédateurs.
  /// C'est ce qui fait qu'un réseau s'effondre au lieu de perdre une
  /// case.
  static Set<String> affectees(String absente) {
    final Set<String> disparues = <String>{absente};
    bool encore = true;
    while (encore) {
      encore = false;
      for (final Espece e in reseau) {
        if (disparues.contains(e.nom) || e.estProducteur) continue;
        final bool plusRien =
            e.mange.every((String proie) => disparues.contains(proie));
        if (plusRien) {
          disparues.add(e.nom);
          encore = true;
        }
      }
    }
    return disparues..remove(absente);
  }

  @override
  State<FoodWebFigure> createState() => _FoodWebFigureState();
}

class _FoodWebFigureState extends State<FoodWebFigure> {
  String? _absente;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Set<String> affectees = _absente == null
        ? const <String>{}
        : FoodWebFigure.affectees(_absente!);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.1,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints contraintes) {
              final Size taille = contraintes.biggest;
              return Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ReseauPainter(
                        absente: _absente,
                        affectees: affectees,
                        accent: widget.accent,
                        trait: tokens.border,
                        muted: tokens.inkMuted,
                      ),
                    ),
                  ),
                  for (final Espece e in FoodWebFigure.reseau)
                    Positioned(
                      left: e.position.dx * taille.width - 44,
                      top: e.position.dy * taille.height - 20,
                      width: 88,
                      height: 40,
                      child: _Pastille(
                        nom: e.nom,
                        retiree: _absente == e.nom,
                        affectee: affectees.contains(e.nom),
                        accent: widget.accent,
                        onTap: () => setState(
                          () => _absente = _absente == e.nom ? null : e.nom,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          switch ((_absente, affectees.length)) {
            (null, _) => 'Touche une espèce pour la retirer du pré.',
            // « Sans Herbe » plutôt que « Herbe retirée » : la tournure
            // évite d'accorder au genre de chaque espèce, et tiendra
            // encore si le réseau en accueille d'autres.
            (final String nom, 0) =>
              'Sans $nom : personne ne meurt de faim, mais ses proies '
                  'vont se multiplier.',
            (final String nom, final int combien) =>
              'Sans $nom : $combien espèce${combien > 1 ? 's' : ''} '
                  'n\'${combien > 1 ? 'ont' : 'a'} plus rien à manger.',
          },
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(
            color: _absente == null ? tokens.inkMuted : widget.accent,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Les flèches vont de la proie vers celui qui la mange',
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({
    required this.nom,
    required this.retiree,
    required this.affectee,
    required this.accent,
    required this.onTap,
  });

  final String nom;
  final bool retiree;
  final bool affectee;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Color fond = retiree
        ? tokens.surfaceAlt
        : (affectee ? tokens.surfaceAlt : accent);
    final Color encre = retiree || affectee ? tokens.inkSubtle : Colors.white;

    return GestureDetector(
      onTap: () {
        context.tapFeedback();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: retiree ? accent : tokens.border,
            width: retiree ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          // « × » et non « ✕ » : le second manque aux polices du projet.
          retiree ? '× $nom' : nom,
          style: AppTypography.formula(size: 13, color: encre),
        ),
      ),
    );
  }
}

class _ReseauPainter extends CustomPainter {
  const _ReseauPainter({
    required this.absente,
    required this.affectees,
    required this.accent,
    required this.trait,
    required this.muted,
  });

  final String? absente;
  final Set<String> affectees;
  final Color accent;
  final Color trait;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    for (final Espece e in FoodWebFigure.reseau) {
      for (final String proie in e.mange) {
        final Espece source = FoodWebFigure.reseau.firstWhere(
          (Espece x) => x.nom == proie,
        );
        final bool rompue = absente == proie ||
            absente == e.nom ||
            affectees.contains(proie) ||
            affectees.contains(e.nom);
        _fleche(
          canvas,
          Offset(
            source.position.dx * size.width,
            source.position.dy * size.height,
          ),
          Offset(e.position.dx * size.width, e.position.dy * size.height),
          rompue ? trait : accent,
        );
      }
    }
  }

  /// Une flèche de la proie vers le prédateur, raccourcie aux deux bouts
  /// pour ne pas passer sous les pastilles.
  void _fleche(Canvas canvas, Offset depart, Offset arrivee, Color couleur) {
    final Offset direction = (arrivee - depart) / (arrivee - depart).distance;
    final Offset a = depart + direction * 24;
    final Offset b = arrivee - direction * 24;
    final Paint peinture = Paint()
      ..color = couleur
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a, b, peinture);

    final double angle = math.atan2(direction.dy, direction.dx);
    for (final double ecart in <double>[2.6, -2.6]) {
      canvas.drawLine(
        b,
        b + Offset(math.cos(angle + ecart), math.sin(angle + ecart)) * 10,
        peinture,
      );
    }
  }

  @override
  bool shouldRepaint(_ReseauPainter old) =>
      old.absente != absente || old.accent != accent;
}
