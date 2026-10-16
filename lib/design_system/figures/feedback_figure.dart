/// Un asservissement proportionnel, et ce que le gain fait à la réponse.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// La réponse d'un système bouclé, dont on règle le gain.
///
/// Un asservissement proportionnel se résume souvent à « plus le gain est
/// grand, mieux c'est ». La courbe dit autre chose, et en trois temps.
///
/// À gain faible, le système atteint une valeur stable mais trop basse :
/// c'est l'erreur statique, et elle est inhérente à une commande
/// proportionnelle — sans écart, il n'y a pas de commande.
///
/// À gain moyen, la réponse est rapide et l'erreur devient petite.
///
/// Au-delà d'un seuil, la correction dépasse la cible à chaque pas et la
/// réponse oscille ; plus loin encore, elle diverge. Le gain n'est donc
/// pas un curseur de qualité : c'est un compromis dont les deux bouts
/// sont mauvais.
class FeedbackFigure extends StatefulWidget {
  const FeedbackFigure({required this.accent, super.key});

  final Color accent;

  /// Rapidité propre du procédé, entre 0 et 1.
  static const double rapidite = 0.3;

  /// La consigne à atteindre.
  static const double consigne = 1;

  /// Nombre de pas simulés.
  static const int pas = 40;

  /// Le pôle de la boucle fermée.
  ///
  /// Toute la dynamique en dépend : la réponse est stable si sa valeur
  /// absolue est inférieure à 1, et oscillante s'il est négatif.
  static double pole(double gain) => 1 - rapidite * (1 + gain);

  /// La boucle est-elle stable ?
  static bool stable(double gain) => pole(gain).abs() < 1;

  /// La réponse oscille-t-elle autour de la consigne ?
  static bool oscillant(double gain) => pole(gain) < 0;

  /// La valeur atteinte en régime permanent.
  ///
  /// Elle vaut consigne × gain / (1 + gain) : toujours en dessous de la
  /// consigne, et d'autant plus proche que le gain est grand. C'est
  /// l'erreur statique, et aucun réglage du gain ne l'annule.
  static double regimePermanent(double gain) =>
      consigne * gain / (1 + gain);

  /// La réponse pas à pas, en partant de zéro.
  static List<double> reponse(double gain) {
    final List<double> sortie = <double>[0];
    double y = 0;
    for (int i = 0; i < pas; i++) {
      final double ecart = consigne - y;
      y = (1 - rapidite) * y + rapidite * gain * ecart;
      sortie.add(y);
    }
    return sortie;
  }

  @override
  State<FeedbackFigure> createState() => _FeedbackFigureState();
}

class _FeedbackFigureState extends State<FeedbackFigure> {
  double _gain = 1;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool stable = FeedbackFigure.stable(_gain);
    final bool oscillant = FeedbackFigure.oscillant(_gain);
    final double permanent = FeedbackFigure.regimePermanent(_gain);

    final String verdict;
    if (!stable) {
      verdict = 'Gain trop fort : la réponse diverge.';
    } else if (oscillant) {
      verdict = 'La réponse dépasse la consigne et oscille avant de se '
          'poser.';
    } else {
      verdict = 'Réponse sans dépassement, qui s’arrête à '
          '${NumericQuestion.formatNumber((permanent * 100).roundToDouble() / 100)} '
          'au lieu de 1.';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.6,
          child: CustomPaint(
            painter: _ReponsePainter(
              reponse: FeedbackFigure.reponse(_gain),
              accent: stable ? widget.accent : tokens.error,
              ink: context.colors.onSurface,
              trait: tokens.border,
              muted: tokens.inkMuted,
              surface: context.colors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 36,
          child: Text(
            verdict,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: stable ? tokens.inkMuted : tokens.error,
            ),
          ),
        ),
        Row(
          children: <Widget>[
            SizedBox(
              width: 44,
              child: Text(
                'gain',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkMuted,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _gain,
                min: 0.25,
                max: 7,
                divisions: 27,
                onChanged: (double v) {
                  context.tapFeedback();
                  setState(() => _gain = (v * 4).roundToDouble() / 4);
                },
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                NumericQuestion.formatNumber(_gain),
                textAlign: TextAlign.right,
                style: AppTypography.formula(
                  size: 14,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReponsePainter extends CustomPainter {
  const _ReponsePainter({
    required this.reponse,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final List<double> reponse;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color surface;

  /// Hauteur représentée, en unités de consigne.
  static const double hauteur = 2.2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = surface);
    canvas.clipRect(Offset.zero & size);

    Offset p(double t, double y) => Offset(
      size.width * t / (reponse.length - 1),
      size.height * (1 - y / hauteur),
    );

    // La consigne, en pointillé : c'est la ligne que la réponse cherche.
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(
        Offset(x, p(0, FeedbackFigure.consigne).dy),
        Offset(x + 5, p(0, FeedbackFigure.consigne).dy),
        Paint()
          ..color = muted
          ..strokeWidth = 1.4,
      );
    }
    canvas.drawLine(
      p(0, 0),
      Offset(size.width, p(0, 0).dy),
      Paint()
        ..color = ink.withValues(alpha: 0.5)
        ..strokeWidth = 1.5,
    );

    final Path courbe = Path();
    bool commence = false;
    for (int i = 0; i < reponse.length; i++) {
      final double y = reponse[i].clamp(-hauteur, hauteur * 2);
      final Offset point = p(i.toDouble(), y);
      if (!commence) {
        courbe.moveTo(point.dx, point.dy);
        commence = true;
      } else {
        courbe.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      courbe,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = accent,
    );

    // Les points simulés, pour rappeler que le temps avance par pas.
    for (int i = 0; i < reponse.length; i += 2) {
      final double y = reponse[i];
      if (y.abs() > hauteur * 1.5) continue;
      canvas.drawCircle(
        p(i.toDouble(), y),
        2.2,
        Paint()..color = accent.withValues(alpha: 0.75),
      );
    }

    // Pas de graduation verticale : deux traits de six pixels sans
    // libellé se lisaient comme des défauts de tracé, et la seule
    // référence utile — la consigne — est déjà là, en pointillé.
  }

  @override
  bool shouldRepaint(_ReponsePainter old) =>
      old.reponse.length != reponse.length ||
      old.accent != accent ||
      old.reponse.last != reponse.last;
}
