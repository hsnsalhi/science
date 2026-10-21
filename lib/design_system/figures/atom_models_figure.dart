/// Deux mille cinq cents ans d'atome, en quatre dessins qu'on compare.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'realism.dart';

/// Un modèle de l'atome, à sa date, avec ce qui l'a tué.
enum ModeleAtome {
  /// Démocrite, vers 400 avant notre ère : un grain insécable.
  democrite(
    'Démocrite',
    'vers 400 avant J.-C.',
    'Un grain plein, qu’on ne peut pas couper. C’est une idée, pas une '
        'mesure : rien ne permet encore de la vérifier.',
    'Tenu pour une rêverie pendant vingt-deux siècles.',
  ),

  /// Thomson, 1897 : du positif dilué, des électrons dedans.
  thomson(
    'Thomson',
    '1897',
    'Thomson vient de découvrir l’électron, négatif. L’atome étant neutre, '
        'il imagine une pâte positive où les électrons sont enfoncés comme '
        'des raisins dans un cake.',
    'La feuille d’or de 1909 : une pâte molle ne renvoie rien en arrière.',
  ),

  /// Rutherford, 1911 : presque tout le vide, tout le poids au centre.
  rutherford(
    'Rutherford',
    '1911',
    'Toute la charge positive et presque toute la masse tiennent dans un '
        'noyau minuscule. Le reste est vide, parcouru d’électrons.',
    'Un électron qui tourne devrait rayonner et tomber en un instant.',
  ),

  /// Bohr, 1913 : des couches permises, et pas d'autres.
  bohr(
    'Bohr',
    '1913',
    'Les électrons n’ont droit qu’à certaines couches. Pour changer de '
        'couche, il faut absorber ou émettre un grain de lumière précis.',
    'Exact pour l’hydrogène, faux dès l’hélium : il faudra la mécanique '
        'quantique.',
  );

  const ModeleAtome(this.nom, this.date, this.idee, this.faille);

  /// Le nom du modèle, pour le bouton.
  final String nom;

  /// L'année, qui situe la découverte dans l'histoire.
  final String date;

  /// Ce que le modèle propose.
  final String idee;

  /// Ce qui l'a mis en défaut : c'est cela qui fait avancer la science.
  final String faille;
}

/// Les quatre modèles historiques de l'atome, que l'élève fait défiler.
///
/// Le chapitre raconte une succession d'idées fausses, et c'est exactement
/// ce qu'il faut montrer : chaque modèle explique ce que le précédent ne
/// savait pas expliquer, et chacun meurt d'une mesure. Un paragraphe qui
/// énumère « Démocrite, Thomson, Rutherford, Bohr » n'apprend rien ; quatre
/// dessins qu'on commute sous l'œil montrent le mouvement.
///
/// La deuxième commande est l'échelle. Dire que l'atome est vide ne marche
/// pas : tout le monde l'a entendu et personne ne le voit. Le curseur
/// d'agrandissement ramène le noyau à sa taille réelle devant l'atome —
/// un rapport de cent mille — jusqu'à ce qu'il disparaisse.
class AtomModelsFigure extends StatefulWidget {
  const AtomModelsFigure({required this.accent, super.key});

  /// Couleur d'accent de la matière.
  final Color accent;

  /// Rapport réel entre le rayon de l'atome et celui du noyau.
  ///
  /// Un atome mesure environ un dixième de milliardième de mètre, un noyau
  /// cent mille fois moins. C'est ce nombre, et lui seul, qui rend
  /// l'expérience de la feuille d'or compréhensible.
  static const int rapportAtomeNoyau = 100000;

  /// Le rayon du noyau à l'écran, en pixels, pour un agrandissement donné.
  ///
  /// À `fidelite` nul on dessine le noyau gros, comme tous les schémas de
  /// manuel ; à 1 on le dessine à l'échelle, et il devient invisible. Le
  /// trajet entre les deux est le contenu de la figure.
  static double rayonNoyau(double rayonAtome, double fidelite) {
    final double honnete = rayonAtome / rapportAtomeNoyau;
    return rayonAtome * 0.1 * (1 - fidelite) + honnete * fidelite;
  }

  /// Le facteur d'agrandissement affiché, pour une fidélité donnée.
  static int agrandissement(double fidelite) {
    if (fidelite <= 0) return 1;
    // On interpole en échelle logarithmique : c'est ainsi que l'écart se
    // parcourt, et la lecture reste régulière d'un bout à l'autre.
    final double log = fidelite * math.log(rapportAtomeNoyau / 10);
    return math.exp(log).round();
  }

  @override
  State<AtomModelsFigure> createState() => _AtomModelsFigureState();
}

class _AtomModelsFigureState extends State<AtomModelsFigure>
    with SingleTickerProviderStateMixin {
  ModeleAtome _modele = ModeleAtome.democrite;
  double _fidelite = 0;
  bool _demarre = false;

  late final AnimationController _ronde = AnimationController(
    duration: const Duration(seconds: 7),
    vsync: this,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_demarre) return;
    _demarre = true;
    if (!context.reduceMotion) _ronde.repeat();
  }

  @override
  void dispose() {
    _ronde.dispose();
    super.dispose();
  }

  void _choisir(ModeleAtome modele) {
    if (modele == _modele) return;
    setState(() {
      _modele = modele;
      // L'échelle ne veut rien dire pour un grain plein ni pour une pâte :
      // on la remet à zéro en quittant un modèle à noyau.
      if (modele != ModeleAtome.rutherford && modele != ModeleAtome.bohr) {
        _fidelite = 0;
      }
    });
    context.tapFeedback();
  }

  bool get _aUnNoyau =>
      _modele == ModeleAtome.rutherford || _modele == ModeleAtome.bohr;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          children: <Widget>[
            for (final ModeleAtome modele in ModeleAtome.values)
              ChoiceChip(
                label: Text(modele.nom),
                selected: _modele == modele,
                onSelected: (_) => _choisir(modele),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 190,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return AnimatedBuilder(
                  animation: _ronde,
                  builder: (BuildContext context, Widget? _) => CustomPaint(
                    size: Size(contraintes.maxWidth, 190),
                    painter: _ModelePainter(
                      modele: _modele,
                      fidelite: _fidelite,
                      phase: context.reduceMotion ? 0 : _ronde.value,
                      accent: widget.accent,
                      tokens: tokens,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_modele.nom} — ${_modele.date}',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 15, color: widget.accent),
        ),
        Text(
          _modele.idee,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ce qui l’a mis en défaut : ${_modele.faille}',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.error),
        ),
        if (_aUnNoyau) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              SizedBox(
                width: 60,
                child: Text(
                  'échelle',
                  style: context.text.labelSmall?.copyWith(
                    color: tokens.inkSubtle,
                  ),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _fidelite,
                  onChanged: (double valeur) {
                    setState(() => _fidelite = valeur);
                    context.tapFeedback();
                  },
                ),
              ),
            ],
          ),
          Text(
            _fidelite < 0.02
                ? 'Noyau dessiné comme dans les manuels : beaucoup trop gros.'
                : _fidelite > 0.96
                    ? 'Taille réelle. Le noyau est ce point, et tout le reste '
                        'est vide : voilà pourquoi presque tout passe au '
                        'travers.'
                    : 'Noyau réduit ${_milliers(AtomModelsFigure.agrandissement(_fidelite))} fois. '
                        'Il en reste encore à perdre.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
          ),
        ],
      ],
    );
  }

  /// Les grands nombres, groupés par trois, avec l'espace insécable que la
  /// police sait dessiner.
  String _milliers(int n) {
    final String chiffres = n.toString();
    final StringBuffer sortie = StringBuffer();
    for (int i = 0; i < chiffres.length; i++) {
      if (i > 0 && (chiffres.length - i) % 3 == 0) sortie.write(' ');
      sortie.write(chiffres[i]);
    }
    return sortie.toString();
  }
}

/// Les quatre atomes, chacun dessiné selon ce que son auteur croyait.
class _ModelePainter extends CustomPainter {
  const _ModelePainter({
    required this.modele,
    required this.fidelite,
    required this.phase,
    required this.accent,
    required this.tokens,
  });

  final ModeleAtome modele;
  final double fidelite;
  final double phase;
  final Color accent;
  final AppTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tokens.surfaceAlt);
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double rayon = math.min(size.width * 0.26, size.height * 0.4);

    switch (modele) {
      case ModeleAtome.democrite:
        _grainPlein(canvas, centre, rayon);
      case ModeleAtome.thomson:
        _pateAuxRaisins(canvas, centre, rayon);
      case ModeleAtome.rutherford:
        _noyauEtVide(canvas, centre, rayon, quantifie: false);
      case ModeleAtome.bohr:
        _noyauEtVide(canvas, centre, rayon, quantifie: true);
    }
  }

  /// Démocrite : une pierre, pas une bille. Une chose qu'on ne peut pas
  /// couper doit avoir l'air d'un morceau de matière, pas d'un symbole.
  void _grainPlein(Canvas canvas, Offset centre, double rayon) {
    final math.Random alea = math.Random(5);
    final Path grain = Path();
    const int cotes = 13;
    for (int i = 0; i <= cotes; i++) {
      final double a = i * 2 * math.pi / cotes;
      final double r = rayon * (0.86 + alea.nextDouble() * 0.2);
      final Offset p = centre + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        grain.moveTo(p.dx, p.dy);
      } else {
        grain.lineTo(p.dx, p.dy);
      }
    }
    grain.close();
    canvas.drawPath(
      grain,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          colors: <Color>[
            Color(0xFF9A8F7F),
            Color(0xFF554C41),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: rayon * 1.1)),
    );
    canvas.drawPath(
      grain,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
    // Le couteau qui n'entame pas : l'argument de Démocrite est une
    // expérience de pensée, et elle se dessine.
    final Paint lame = Paint()
      ..color = tokens.inkMuted
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      centre + Offset(-rayon * 2.1, -rayon * 0.9),
      centre + Offset(-rayon * 1.05, -rayon * 0.1),
      lame,
    );
    _etiquette(
      canvas,
      'insécable',
      centre + Offset(rayon * 1.1, -8),
      tokens.inkMuted,
    );
  }

  /// Thomson : une pâte positive diffuse, des électrons enfoncés dedans.
  void _pateAuxRaisins(Canvas canvas, Offset centre, double rayon) {
    canvas.drawCircle(
      centre,
      rayon,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            tokens.error.withValues(alpha: 0.42),
            tokens.error.withValues(alpha: 0.14),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: rayon)),
    );
    canvas.drawCircle(
      centre,
      rayon,
      Paint()
        ..color = tokens.error.withValues(alpha: 0.5)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
    final math.Random alea = math.Random(9);
    for (int i = 0; i < 9; i++) {
      final double a = alea.nextDouble() * math.pi * 2;
      final double r = rayon * 0.82 * math.sqrt(alea.nextDouble());
      Realisme.sphere(
        canvas,
        centre + Offset(math.cos(a) * r, math.sin(a) * r),
        4.2,
        couleur: tokens.info,
      );
    }
    _etiquette(canvas, 'charge positive diluée',
        centre + Offset(-rayon * 0.9, rayon * 1.25), tokens.error);
  }

  /// Rutherford et Bohr : un noyau, du vide, des électrons.
  void _noyauEtVide(
    Canvas canvas,
    Offset centre,
    double rayon, {
    required bool quantifie,
  }) {
    canvas.drawCircle(
      centre,
      rayon,
      Paint()
        ..color = tokens.inkSubtle.withValues(alpha: 0.22)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    if (quantifie) {
      // Bohr : des couches permises, dessinées pleines, et rien entre
      // elles. L'interdit est le contenu du modèle.
      for (final double part in <double>[0.45, 0.72, 0.97]) {
        canvas.drawCircle(
          centre,
          rayon * part,
          Paint()
            ..color = accent.withValues(alpha: 0.4)
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke,
        );
      }
      const List<(double, int)> couches = <(double, int)>[
        (0.45, 2),
        (0.72, 4),
        (0.97, 3),
      ];
      for (final (double part, int nombre) in couches) {
        for (int i = 0; i < nombre; i++) {
          final double a =
              phase * 2 * math.pi / part + i * 2 * math.pi / nombre;
          Realisme.sphere(
            canvas,
            centre +
                Offset(
                  math.cos(a) * rayon * part,
                  math.sin(a) * rayon * part,
                ),
            4,
            couleur: tokens.info,
          );
        }
      }
    } else {
      // Rutherford : des trajectoires quelconques, parce qu'il n'avait
      // aucune raison de les croire circulaires ni régulières.
      final math.Random alea = math.Random(4);
      for (int i = 0; i < 5; i++) {
        final double inclinaison = alea.nextDouble() * math.pi;
        final double grand = rayon * (0.6 + alea.nextDouble() * 0.38);
        final double petit = grand * (0.3 + alea.nextDouble() * 0.5);
        canvas.save();
        canvas.translate(centre.dx, centre.dy);
        canvas.rotate(inclinaison);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: grand * 2,
            height: petit * 2,
          ),
          Paint()
            ..color = tokens.inkSubtle.withValues(alpha: 0.3)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
        final double a = phase * 2 * math.pi + i * 1.3;
        Realisme.sphere(
          canvas,
          Offset(math.cos(a) * grand, math.sin(a) * petit),
          4,
          couleur: tokens.info,
        );
        canvas.restore();
      }
    }

    // Le noyau, à la taille que l'élève a choisie.
    final double rayonNoyau = AtomModelsFigure.rayonNoyau(rayon, fidelite);
    if (rayonNoyau >= 1.4) {
      Realisme.sphere(canvas, centre, rayonNoyau, couleur: tokens.gold);
    } else {
      // En dessous du pixel, une sphère ombrée ne veut plus rien dire : on
      // pose un point et un cercle de repérage, sans quoi l'élève croirait
      // que le noyau a disparu du modèle.
      canvas.drawCircle(centre, 1.1, Paint()..color = tokens.gold);
      canvas.drawCircle(
        centre,
        12,
        Paint()
          ..color = tokens.gold.withValues(alpha: 0.45)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
    _etiquette(
      canvas,
      'noyau',
      centre + Offset(rayon * 0.12, rayon * 0.14),
      tokens.gold,
    );
    _etiquette(
      canvas,
      'vide',
      centre + Offset(rayon * 0.5, -rayon * 0.72),
      tokens.inkSubtle,
    );
  }

  void _etiquette(Canvas canvas, String texte, Offset ou, Color couleur) {
    TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
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
  bool shouldRepaint(_ModelePainter ancien) =>
      ancien.modele != modele ||
      ancien.fidelite != fidelite ||
      ancien.phase != phase ||
      ancien.accent != accent ||
      ancien.tokens != tokens;
}
