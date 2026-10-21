/// Des objets, des tiroirs, et le tiroir qui déborde quoi qu'on fasse.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Le principe des tiroirs, que l'élève essaie de mettre en défaut.
///
/// L'énoncé — « si l'on range plus d'objets que de tiroirs, un tiroir en
/// contient au moins deux » — a l'air d'une évidence creuse, et c'est
/// exactement pourquoi il faut le manipuler. L'élève a le droit de
/// redistribuer autant de fois qu'il veut ; il ne trouvera pas de
/// contre-exemple, et c'est cet échec répété qui installe la certitude.
///
/// Le même appareil sert à la version renforcée : avec treize personnes
/// et douze mois, un mois en reçoit deux ; avec vingt-cinq et douze, un
/// mois en reçoit trois. La figure affiche ce minimum garanti, qui est le
/// quotient arrondi vers le haut.
class PigeonholeFigure extends StatefulWidget {
  const PigeonholeFigure({required this.accent, super.key});

  /// Couleur d'accent de la matière.
  final Color accent;

  /// Nombre maximal d'objets à ranger.
  static const int objetsMax = 26;

  /// Nombre maximal de tiroirs.
  static const int tiroirsMax = 12;

  /// Le nombre d'objets qu'au moins un tiroir contiendra forcément.
  ///
  /// C'est le quotient arrondi vers le haut : si la meilleure répartition
  /// possible met `q` objets partout, il en reste à placer, et ils vont
  /// bien quelque part. Aucune astuce de rangement n'y échappe.
  static int minimumGaranti(int objets, int tiroirs) {
    if (tiroirs <= 0) return objets;
    return (objets + tiroirs - 1) ~/ tiroirs;
  }

  /// La répartition la plus égale possible : le cas le plus favorable.
  ///
  /// C'est elle qu'il faut battre pour mettre le principe en défaut. On la
  /// donne donc à voir, plutôt que de la laisser deviner.
  static List<int> repartitionLaPlusEgale(int objets, int tiroirs) {
    final List<int> tas = List<int>.filled(tiroirs, objets ~/ tiroirs);
    for (int i = 0; i < objets % tiroirs; i++) {
      tas[i]++;
    }
    return tas;
  }

  /// Une répartition au hasard, pour laisser l'élève tenter sa chance.
  static List<int> repartitionAuHasard(int objets, int tiroirs, int graine) {
    final math.Random alea = math.Random(graine);
    final List<int> tas = List<int>.filled(tiroirs, 0);
    for (int i = 0; i < objets; i++) {
      tas[alea.nextInt(tiroirs)]++;
    }
    return tas;
  }

  @override
  State<PigeonholeFigure> createState() => _PigeonholeFigureState();
}

class _PigeonholeFigureState extends State<PigeonholeFigure> {
  int _objets = 13;
  int _tiroirs = 12;
  int _graine = 0;

  /// `_graine` nul signifie « la répartition la plus égale », c'est-à-dire
  /// le cas le plus favorable à celui qui voudrait éviter le débordement.
  List<int> get _tas => _graine == 0
      ? PigeonholeFigure.repartitionLaPlusEgale(_objets, _tiroirs)
      : PigeonholeFigure.repartitionAuHasard(_objets, _tiroirs, _graine);

  void _reglerObjets(double valeur) {
    final int n = valeur.round();
    if (n == _objets) return;
    setState(() {
      _objets = n;
      _graine = 0;
    });
    context.tapFeedback();
  }

  void _reglerTiroirs(double valeur) {
    final int n = valeur.round();
    if (n == _tiroirs) return;
    setState(() {
      _tiroirs = n;
      _graine = 0;
    });
    context.tapFeedback();
  }

  void _redistribuer() {
    setState(() => _graine = _graine + 1);
    if (_objets > _tiroirs) {
      context.errorFeedback();
    } else {
      context.tapFeedback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final int garanti = PigeonholeFigure.minimumGaranti(_objets, _tiroirs);
    final List<int> tas = _tas;
    final int plusGrand = tas.reduce(math.max);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 184,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return CustomPaint(
                  size: Size(contraintes.maxWidth, 184),
                  painter: _TiroirsPainter(
                    tas: tas,
                    seuil: garanti,
                    accent: widget.accent,
                    tokens: tokens,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$_objets objets dans $_tiroirs tiroirs',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 17, color: widget.accent),
        ),
        Text(
          garanti >= 2
              ? 'Un tiroir en contient au moins $garanti. '
                  'Essaie de l’éviter : tu ne pourras pas.'
              : 'Il y a assez de tiroirs : chacun peut n’en recevoir qu’un.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(
            color: garanti >= 2 ? tokens.warning : tokens.success,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'ici, le plus rempli en a $plusGrand',
          textAlign: TextAlign.center,
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
        _curseur(
          context,
          'objets',
          _objets.toDouble(),
          1,
          PigeonholeFigure.objetsMax.toDouble(),
          _reglerObjets,
        ),
        _curseur(
          context,
          'tiroirs',
          _tiroirs.toDouble(),
          1,
          PigeonholeFigure.tiroirsMax.toDouble(),
          _reglerTiroirs,
        ),
        TextButton(
          onPressed: _redistribuer,
          child: const Text('Essaie une autre répartition'),
        ),
      ],
    );
  }

  Widget _curseur(
    BuildContext context,
    String nom,
    double valeur,
    double mini,
    double maxi,
    ValueChanged<double> quand,
  ) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 54,
          child: Text(
            nom,
            style: context.text.labelSmall?.copyWith(
              color: context.tokens.inkSubtle,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: valeur,
            min: mini,
            max: maxi,
            divisions: (maxi - mini).round(),
            label: '${valeur.round()}',
            onChanged: quand,
          ),
        ),
      ],
    );
  }
}

/// Une rangée de tiroirs, et les objets empilés dedans.
class _TiroirsPainter extends CustomPainter {
  const _TiroirsPainter({
    required this.tas,
    required this.seuil,
    required this.accent,
    required this.tokens,
  });

  final List<int> tas;
  final int seuil;
  final Color accent;
  final AppTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tokens.surfaceAlt);

    final double largeur = (size.width - 20) / tas.length;
    final double base = size.height - 22;
    final double rayon = math.min(largeur * 0.3, 9);

    for (int i = 0; i < tas.length; i++) {
      final double gauche = 10 + i * largeur;
      final Rect tiroir = Rect.fromLTRB(
        gauche + 2,
        26,
        gauche + largeur - 2,
        base,
      );
      final bool deborde = tas[i] >= seuil && seuil >= 2;

      // Le tiroir : un caisson ouvert sur le dessus, avec une poignée.
      // Un rectangle vide se lirait comme une colonne de graphique, et ce
      // chapitre ne parle pas de statistiques.
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          tiroir,
          bottomLeft: const Radius.circular(4),
          bottomRight: const Radius.circular(4),
        ),
        Paint()
          ..color = deborde
              ? tokens.warning.withValues(alpha: 0.16)
              : tokens.border.withValues(alpha: 0.35),
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          tiroir,
          bottomLeft: const Radius.circular(4),
          bottomRight: const Radius.circular(4),
        ),
        Paint()
          ..color = deborde ? tokens.warning : tokens.inkSubtle
          ..strokeWidth = deborde ? 2 : 1.2
          ..style = PaintingStyle.stroke,
      );
      canvas.drawLine(
        Offset(tiroir.center.dx - largeur * 0.14, base - 5),
        Offset(tiroir.center.dx + largeur * 0.14, base - 5),
        Paint()
          ..color = tokens.inkSubtle.withValues(alpha: 0.7)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );

      // Les objets, empilés depuis le fond.
      for (int j = 0; j < tas[i]; j++) {
        final double y = base - 14 - j * (rayon * 2 + 2);
        if (y < 30) break;
        canvas.drawCircle(
          Offset(tiroir.center.dx, y),
          rayon,
          Paint()..color = deborde && j > 0 ? tokens.warning : accent,
        );
      }

      // Le compte, au-dessus du tiroir : sans lui, l'élève recompte des
      // ronds au lieu de lire la règle.
      _etiquette(
        canvas,
        '${tas[i]}',
        Offset(tiroir.center.dx - 4, 10),
        deborde ? tokens.warning : tokens.inkMuted,
      );
    }
  }

  void _etiquette(Canvas canvas, String texte, Offset ou, Color couleur) {
    TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          color: couleur,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, ou);
  }

  @override
  bool shouldRepaint(_TiroirsPainter ancien) =>
      !listEquals(ancien.tas, tas) ||
      ancien.seuil != seuil ||
      ancien.accent != accent ||
      ancien.tokens != tokens;
}
