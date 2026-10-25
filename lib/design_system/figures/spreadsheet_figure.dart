/// Un tableur minuscule : on change une case, tout le reste se recalcule.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';

/// Le tableur du dépensier, que l'élève modifie case par case.
///
/// Ce qui distingue un tableur d'une table posée sur du papier tient en
/// une phrase : une case peut contenir une question plutôt qu'un nombre.
/// Tant qu'on n'a pas vu une colonne entière se refaire après avoir changé
/// un seul chiffre, cette phrase reste creuse.
///
/// La figure tient donc quatre lignes de dépenses, chacune avec un prix et
/// une quantité, et deux colonnes calculées : le total de la ligne, et le
/// total général. L'élève choisit une case et règle sa valeur ; tout ce
/// qui en dépend suit immédiatement, et la figure peut montrer les
/// formules à la place des résultats.
class SpreadsheetFigure extends StatefulWidget {
  const SpreadsheetFigure({required this.accent, super.key});

  /// Couleur d'accent de la matière.
  final Color accent;

  /// Les intitulés des lignes.
  static const List<String> articles = <String>[
    'Cahiers',
    'Stylos',
    'Classeurs',
    'Colle',
  ];

  /// Prix unitaires de départ, en euros.
  static const List<double> prixDepart = <double>[2.5, 1.2, 4, 3.5];

  /// Quantités de départ.
  static const List<int> quantitesDepart = <int>[6, 10, 3, 2];

  /// Le total d'une ligne : prix × quantité.
  static double totalLigne(double prix, int quantite) => prix * quantite;

  /// Le total général : la somme des totaux de ligne.
  ///
  /// On refait la somme à chaque appel plutôt que de la garder de côté :
  /// un tableur fait exactement cela, et c'est pour cette raison qu'il ne
  /// se trompe jamais d'un centime après une modification.
  static double totalGeneral(List<double> prix, List<int> quantites) {
    double somme = 0;
    for (int i = 0; i < prix.length; i++) {
      somme += totalLigne(prix[i], quantites[i]);
    }
    return somme;
  }

  /// Le nom d'une case, à la façon d'un tableur : colonne puis ligne.
  ///
  /// La ligne 1 porte les en-têtes, donc la première dépense est en
  /// ligne 2 — c'est la source d'erreur la plus banale des débutants, et
  /// la figure l'affiche telle quelle plutôt que de la masquer.
  static String nomCase(int colonne, int ligne) =>
      '${String.fromCharCode(65 + colonne)}${ligne + 2}';

  @override
  State<SpreadsheetFigure> createState() => _SpreadsheetFigureState();
}

class _SpreadsheetFigureState extends State<SpreadsheetFigure> {
  late final List<double> _prix =
      List<double>.of(SpreadsheetFigure.prixDepart);
  late final List<int> _quantites =
      List<int>.of(SpreadsheetFigure.quantitesDepart);

  /// La case sélectionnée : ligne, et colonne (1 = prix, 2 = quantité).
  int _ligne = 0;
  int _colonne = 2;
  bool _formules = false;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  void _choisir(int ligne, int colonne) {
    if (ligne == _ligne && colonne == _colonne) return;
    setState(() {
      _ligne = ligne;
      _colonne = colonne;
    });
    context.tapFeedback();
  }

  void _regler(double valeur) {
    setState(() {
      if (_colonne == 1) {
        _prix[_ligne] = (valeur * 2).roundToDouble() / 2;
      } else {
        _quantites[_ligne] = valeur.round();
      }
    });
    context.tapFeedback();
  }

  String _nombre(double v) =>
      v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // La sélection parcourt les cellules modifiables, et l'affichage
    // bascule entre valeurs et formules : on voit que les totaux ne sont
    // pas saisis mais calculés, ce qui est tout l'objet d'un tableur.
    final int nbLignes = SpreadsheetFigure.articles.length;
    final int? pas = Autoplay.index(context, nbLignes * 2);
    final bool formules = _tenue || pas == null
        ? _formules
        : pas >= nbLignes;
    final int ligne = _tenue || pas == null ? _ligne : pas % nbLignes;
    final int colonne = _tenue || pas == null ? _colonne : 2;
    final double total =
        SpreadsheetFigure.totalGeneral(_prix, _quantites);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 186,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                final Size taille = Size(contraintes.maxWidth, 186);
                return GestureDetector(
                  onTapUp: (TapUpDetails d) {
                    // Les deux colonnes modifiables sont la deuxième et la
                    // troisième ; les totaux ne se touchent pas, puisque
                    // c'est le tableur qui les écrit.
                    final double largeur = taille.width / 4;
                    final double hauteur = taille.height / 5;
                    final int colonne =
                        (d.localPosition.dx / largeur).floor().clamp(0, 3);
                    final int ligne =
                        (d.localPosition.dy / hauteur).floor() - 1;
                    if (ligne < 0 || ligne >= SpreadsheetFigure.articles.length) {
                      return;
                    }
                    if (colonne == 1 || colonne == 2) {
                      _choisir(ligne, colonne);
                    }
                  },
                  child: CustomPaint(
                    size: taille,
                    painter: _TableurPainter(
                      prix: _prix,
                      quantites: _quantites,
                      ligne: ligne,
                      colonne: colonne,
                      formules: formules,
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
          'total : ${_nombre(total)} €',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          'Touche une case blanche, règle-la, et regarde les deux colonnes '
          'grises se refaire toutes seules.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        Row(
          children: <Widget>[
            SizedBox(
              width: 48,
              child: Text(
                SpreadsheetFigure.nomCase(colonne, _ligne),
                style: AppTypography.formula(size: 14, color: widget.accent),
              ),
            ),
            Expanded(
              child: _colonne == 1
                  ? Slider(
                      value: _prix[_ligne],
                      max: 12,
                      divisions: 24,
                      label: '${_nombre(_prix[_ligne])} €',
                      onChanged: _regler,
                    )
                  : Slider(
                      value: _quantites[_ligne].toDouble(),
                      max: 20,
                      divisions: 20,
                      label: '${_quantites[_ligne]}',
                      onChanged: _regler,
                    ),
            ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          children: <Widget>[
            ChoiceChip(
              label: const Text('Résultats'),
              selected: !formules,
              onSelected: (_) {
                setState(() {
                  _tenue = true;
                  _ligne = ligne;
                  _colonne = colonne;
                  _formules = false;
                });
                context.tapFeedback();
              },
            ),
            ChoiceChip(
              label: const Text('Formules'),
              selected: formules,
              onSelected: (_) {
                setState(() {
                  _tenue = true;
                  _ligne = ligne;
                  _colonne = colonne;
                  _formules = true;
                });
                context.tapFeedback();
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// La grille, ses en-têtes, ses cases saisies et ses cases calculées.
class _TableurPainter extends CustomPainter {
  const _TableurPainter({
    required this.prix,
    required this.quantites,
    required this.ligne,
    required this.colonne,
    required this.formules,
    required this.accent,
    required this.tokens,
  });

  final List<double> prix;
  final List<int> quantites;
  final int ligne;
  final int colonne;
  final bool formules;
  final Color accent;
  final AppTokens tokens;

  static String _n(double v) =>
      v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2).replaceAll('.', ',');

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tokens.surfaceAlt);

    final double largeur = size.width / 4;
    final double hauteur = size.height / 5;
    const List<String> entetes = <String>['Article', 'Prix', 'Nombre', 'Total'];

    for (int c = 0; c < 4; c++) {
      for (int l = 0; l < 5; l++) {
        final Rect cellule = Rect.fromLTWH(
          c * largeur,
          l * hauteur,
          largeur,
          hauteur,
        );
        final bool entete = l == 0;
        // La colonne calculée est grisée : dans un tableur, une case qu'on
        // ne saisit pas se distingue de celle qu'on saisit, sans quoi on
        // écrase une formule sans le vouloir.
        final bool calculee = !entete && c == 3;
        final bool choisie = !entete && l - 1 == ligne && c == colonne;

        canvas.drawRect(
          cellule,
          Paint()
            ..color = entete
                ? tokens.border.withValues(alpha: 0.5)
                : calculee
                    ? tokens.border.withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.55),
        );
        canvas.drawRect(
          cellule,
          Paint()
            ..color = tokens.inkSubtle.withValues(alpha: 0.35)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
        if (choisie) {
          canvas.drawRect(
            cellule.deflate(1.5),
            Paint()
              ..color = accent
              ..strokeWidth = 2.6
              ..style = PaintingStyle.stroke,
          );
        }

        final String texte;
        if (entete) {
          texte = entetes[c];
        } else {
          final int i = l - 1;
          texte = switch (c) {
            0 => SpreadsheetFigure.articles[i],
            1 => '${_n(prix[i])} €',
            2 => '${quantites[i]}',
            _ => formules
                ? '=B${i + 2}*C${i + 2}'
                : '${_n(SpreadsheetFigure.totalLigne(prix[i], quantites[i]))} €',
          };
        }
        _texte(
          canvas,
          texte,
          cellule,
          entete || calculee ? tokens.inkMuted : tokens.inkSubtle,
          gras: entete,
          taille: formules && calculee ? 9.5 : 11,
        );
      }
    }
  }

  void _texte(
    Canvas canvas,
    String texte,
    Rect cellule,
    Color couleur, {
    bool gras = false,
    double taille = 11,
  }) {
    final TextPainter peintre = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontFamilyFallback: AppTypography.replis,
          color: couleur,
          fontSize: taille,
          fontWeight: gras ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: cellule.width - 8);
    peintre.paint(
      canvas,
      Offset(
        cellule.center.dx - peintre.width / 2,
        cellule.center.dy - peintre.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_TableurPainter ancien) =>
      !listEquals(ancien.prix, prix) ||
      !listEquals(ancien.quantites, quantites) ||
      ancien.ligne != ligne ||
      ancien.colonne != colonne ||
      ancien.formules != formules ||
      ancien.accent != accent ||
      ancien.tokens != tokens;
}
