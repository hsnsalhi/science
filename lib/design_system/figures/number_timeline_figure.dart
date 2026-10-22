/// Deux mille quatre cents ans entre l'usage d'un nombre et son droit de cité.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Une famille de nombres, avec la date où on s'en sert et celle où on
/// l'admet.
///
/// Les dates d'apparition sont celles du premier usage attesté ; les dates
/// d'acceptation, celles où la communauté savante cesse de les traiter
/// comme des expédients. Les deux sont des bornes raisonnables et non des
/// instants : on les présente comme telles dans la figure.
enum FamilleDeNombres {
  /// Les entiers : personne ne les a jamais contestés.
  entiers('Entiers', -3000, -3000, 'Personne ne les a jamais refusés.'),

  /// Les irrationnels : découverts par les pythagoriciens, fondés par
  /// Dedekind en 1872.
  irrationnels(
    'Irrationnels',
    -500,
    1872,
    'Découverts vers −500, enfin définis proprement par Dedekind en 1872.',
  ),

  /// Le zéro : chiffre indien, admis en Europe avec Fibonacci.
  zero(
    'Zéro',
    500,
    1202,
    'Chiffre indien vers 500, apporté en Europe par Fibonacci en 1202.',
  ),

  /// Les négatifs : dettes chinoises, acceptés vers 1800.
  negatifs(
    'Négatifs',
    -200,
    1800,
    'Des dettes comptées en Chine vers −200 ; encore « absurdes » pour '
        'beaucoup au dix-huitième siècle.',
  ),

  /// Les imaginaires : Cardan en 1545, Gauss en 1831.
  imaginaires(
    'Imaginaires',
    1545,
    1831,
    'Cardan s’en sert en 1545 en s’en excusant ; Gauss les installe en '
        '1831 en les dessinant dans un plan.',
  );

  const FamilleDeNombres(this.nom, this.usage, this.acceptation, this.note);

  /// Le nom de la famille.
  final String nom;

  /// L'année du premier usage attesté. Négative avant notre ère.
  final int usage;

  /// L'année où la famille cesse d'être contestée.
  final int acceptation;

  /// Ce que la figure dit de cette famille.
  final String note;

  /// Le nombre d'années passées à s'en servir sans l'admettre.
  int get attente => acceptation - usage;

  /// L'état de la famille à une date donnée.
  EtatDuNombre etat(int annee) {
    if (annee < usage) return EtatDuNombre.inconnu;
    if (annee < acceptation) return EtatDuNombre.utiliseMaisRefuse;
    return EtatDuNombre.admis;
  }
}

/// Où en est une famille de nombres, à une date donnée.
enum EtatDuNombre {
  /// Personne ne s'en sert encore.
  inconnu('pas encore là'),

  /// On s'en sert, et on continue de dire que ce n'est pas un nombre.
  utiliseMaisRefuse('utilisé, mais refusé'),

  /// Admis sans discussion.
  admis('admis');

  const EtatDuNombre(this.libelle);

  /// Le mot affiché dans la figure.
  final String libelle;
}

/// La frise des nombres, que l'élève parcourt année par année.
///
/// L'histoire que raconte ce chapitre est toujours la même : un nombre
/// sert d'abord, et on l'autorise ensuite — parfois vingt siècles après.
/// Écrite en paragraphes, cette répétition est une liste de dates ; sur
/// une frise qu'on fait défiler, c'est une forme qu'on voit, et la longue
/// barre orange des irrationnels se passe de commentaire.
class NumberTimelineFigure extends StatefulWidget {
  const NumberTimelineFigure({required this.accent, super.key});

  /// Couleur d'accent de la matière.
  final Color accent;

  /// Première année de la frise.
  static const int debut = -600;

  /// Dernière année de la frise.
  static const int fin = 1900;

  /// Les familles qu'on utilisait sans les admettre, à cette date.
  static List<FamilleDeNombres> enSursis(int annee) => FamilleDeNombres.values
      .where((FamilleDeNombres f) => f.etat(annee) == EtatDuNombre.utiliseMaisRefuse)
      .toList();

  /// La famille qui aura attendu le plus longtemps.
  static FamilleDeNombres laPlusLongueAttente() =>
      FamilleDeNombres.values.reduce(
        (FamilleDeNombres a, FamilleDeNombres b) =>
            a.attente >= b.attente ? a : b,
      );

  @override
  State<NumberTimelineFigure> createState() => _NumberTimelineFigureState();
}

class _NumberTimelineFigureState extends State<NumberTimelineFigure> {
  double _annee = 1700;

  void _regler(double valeur) {
    final double annee = (valeur / 10).roundToDouble() * 10;
    if (annee == _annee) return;
    setState(() => _annee = annee);
    context.tapFeedback();
  }

  /// L'année en toutes lettres : « 500 avant J.-C. », pas « −500 ».
  String get _anneeEcrite {
    final int a = _annee.round();
    return a < 0 ? '${-a} avant J.-C.' : 'an $a';
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final int annee = _annee.round();
    final List<FamilleDeNombres> sursis =
        NumberTimelineFigure.enSursis(annee);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 196,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return GestureDetector(
                  onHorizontalDragUpdate: (DragUpdateDetails details) {
                    final double part =
                        (details.localPosition.dx / contraintes.maxWidth)
                            .clamp(0.0, 1.0);
                    _regler(
                      NumberTimelineFigure.debut +
                          part *
                              (NumberTimelineFigure.fin -
                                  NumberTimelineFigure.debut),
                    );
                  },
                  child: CustomPaint(
                    size: Size(contraintes.maxWidth, 196),
                    painter: _FrisePainter(
                      annee: annee,
                      accent: widget.accent,
                      tokens: tokens,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _anneeEcrite,
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          sursis.isEmpty
              ? 'À cette date, aucun nombre n’est contesté.'
              : 'On s’en sert sans les admettre : '
                  '${sursis.map((FamilleDeNombres f) => f.nom.toLowerCase()).join(', ')}.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(
            color: sursis.isEmpty ? tokens.success : tokens.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
        Slider(
          value: _annee,
          min: NumberTimelineFigure.debut.toDouble(),
          max: NumberTimelineFigure.fin.toDouble(),
          onChanged: _regler,
        ),
      ],
    );
  }
}

/// La frise : une ligne par famille, deux couleurs par ligne.
class _FrisePainter extends CustomPainter {
  const _FrisePainter({
    required this.annee,
    required this.accent,
    required this.tokens,
  });

  final int annee;
  final Color accent;
  final AppTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tokens.surfaceAlt);

    const double marge = 86;
    final double largeur = size.width - marge - 12;
    double versX(int an) =>
        marge +
        largeur *
            (an - NumberTimelineFigure.debut) /
            (NumberTimelineFigure.fin - NumberTimelineFigure.debut);

    const List<FamilleDeNombres> familles = FamilleDeNombres.values;
    final double pas = (size.height - 34) / familles.length;

    // Les siècles, en fond : une frise sans graduations est un dessin.
    for (int an = -500; an <= NumberTimelineFigure.fin; an += 500) {
      final double x = versX(an);
      canvas.drawLine(
        Offset(x, 16),
        Offset(x, size.height - 18),
        Paint()..color = tokens.border.withValues(alpha: 0.6),
      );
      _etiquette(
        canvas,
        an < 0 ? '${-an} av.' : '$an',
        Offset(x + 3, size.height - 16),
        tokens.inkSubtle,
        taille: 10,
      );
    }

    for (int i = 0; i < familles.length; i++) {
      final FamilleDeNombres famille = familles[i];
      final double y = 24 + i * pas;
      _etiquette(canvas, famille.nom, Offset(6, y - 6), tokens.inkMuted);

      final double debutX = math.max(versX(famille.usage), marge);
      final double admisX = versX(famille.acceptation);

      // La barre orange : le temps passé à s'en servir en le refusant.
      // C'est la seule chose que cette figure a vraiment à montrer.
      if (admisX > debutX) {
        canvas.drawLine(
          Offset(debutX, y),
          Offset(admisX, y),
          Paint()
            ..color = tokens.warning.withValues(alpha: 0.85)
            ..strokeWidth = 9
            ..strokeCap = StrokeCap.round,
        );
      }
      // La barre verte : admis, sans plus de discussion.
      canvas.drawLine(
        Offset(math.max(admisX, debutX), y),
        Offset(size.width - 10, y),
        Paint()
          ..color = tokens.success.withValues(alpha: 0.75)
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round,
      );

      // Le curseur n'y est pas encore : on grise ce qui est à venir.
      final double curseurX = versX(annee);
      if (curseurX < size.width) {
        canvas.drawLine(
          Offset(math.max(curseurX, marge), y),
          Offset(size.width - 10, y),
          Paint()
            ..color = tokens.surfaceAlt.withValues(alpha: 0.9)
            ..strokeWidth = 11
            ..strokeCap = StrokeCap.butt,
        );
      }
    }

    // Le trait de l'année : c'est lui que l'élève déplace.
    final double x = versX(annee);
    canvas.drawLine(
      Offset(x, 10),
      Offset(x, size.height - 18),
      Paint()
        ..color = accent
        ..strokeWidth = 2.4,
    );
    canvas.drawCircle(Offset(x, 10), 4, Paint()..color = accent);
  }

  void _etiquette(
    Canvas canvas,
    String texte,
    Offset ou,
    Color couleur, {
    double taille = 11.5,
  }) {
    TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontFamilyFallback: AppTypography.replis,
          color: couleur,
          fontSize: taille,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, ou);
  }

  @override
  bool shouldRepaint(_FrisePainter ancien) =>
      ancien.annee != annee ||
      ancien.accent != accent ||
      ancien.tokens != tokens;
}
