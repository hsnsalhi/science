/// Un octet dont on bascule les bits, et le nombre qu'il représente.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Huit interrupteurs, et le nombre qu'ils écrivent.
///
/// La numération binaire s'enseigne d'ordinaire par des divisions
/// successives, qui donnent le bon résultat sans rien faire
/// comprendre. Ici les huit bits sont des interrupteurs, et au-dessus
/// de chacun figure ce qu'il vaut : 128, 64, 32… Allumer un bit ajoute
/// sa valeur, l'éteindre la retire. Le nombre se lit par addition, ce
/// qui est exactement ce qu'est une écriture positionnelle.
///
/// Les deux bornes se constatent au lieu de se retenir : tous les bits
/// éteints donnent 0, tous allumés 255, et il n'existe aucune façon
/// d'écrire 256 sur huit bits.
class BinaryFigure extends StatefulWidget {
  const BinaryFigure({required this.accent, super.key});

  final Color accent;

  /// Nombre de bits d'un octet.
  static const int bits = 8;

  /// Plus grande valeur représentable sur un octet.
  static const int maximum = 255;

  /// Poids du bit de rang [rang], le rang 0 étant celui de poids fort.
  static int poids(int rang) => 1 << (bits - 1 - rang);

  /// Valeur décimale écrite par ces bits, du poids fort au poids faible.
  static int valeur(List<bool> allumes) {
    int total = 0;
    for (int i = 0; i < allumes.length; i++) {
      if (allumes[i]) total += poids(i);
    }
    return total;
  }

  /// Écriture binaire d'un nombre, sur huit bits.
  static List<bool> ecriture(int nombre) =>
      <bool>[for (int i = 0; i < bits; i++) (nombre & poids(i)) != 0];

  /// Écriture hexadécimale, sur deux chiffres.
  static String hexadecimal(int nombre) =>
      nombre.toRadixString(16).toUpperCase().padLeft(2, '0');

  @override
  State<BinaryFigure> createState() => _BinaryFigureState();
}

class _BinaryFigureState extends State<BinaryFigure> {
  // 0100 1101 : une valeur de départ qui mobilise quatre bits, assez
  // pour que l'addition des poids ait quelque chose à montrer.
  List<bool> _allumes = BinaryFigure.ecriture(77);

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final int valeur = BinaryFigure.valeur(_allumes);
    final List<int> actifs = <int>[
      for (int i = 0; i < BinaryFigure.bits; i++)
        if (_allumes[i]) BinaryFigure.poids(i),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (int i = 0; i < BinaryFigure.bits; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _Bit(
                    poids: BinaryFigure.poids(i),
                    allume: _allumes[i],
                    accent: widget.accent,
                    onTap: () {
                      context.tapFeedback();
                      setState(() {
                        _allumes = <bool>[..._allumes];
                        _allumes[i] = !_allumes[i];
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          NumericQuestion.formatNumber(valeur.toDouble()),
          style: AppTypography.formula(size: 30, color: widget.accent),
        ),
        Text(
          actifs.isEmpty
              ? 'Aucun bit allumé : le nombre vaut zéro.'
              : '${actifs.join(' + ')} = '
                    '${NumericQuestion.formatNumber(valeur.toDouble())}',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'en hexadécimal : ${BinaryFigure.hexadecimal(valeur)}',
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          children: <Widget>[
            _Raccourci(
              texte: 'Tout éteindre',
              accent: widget.accent,
              onTap: () => setState(
                () => _allumes = BinaryFigure.ecriture(0),
              ),
            ),
            _Raccourci(
              texte: 'Tout allumer',
              accent: widget.accent,
              onTap: () => setState(
                () => _allumes = BinaryFigure.ecriture(BinaryFigure.maximum),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Touche un bit pour l\'allumer ou l\'éteindre',
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

/// Un bit, avec son poids écrit au-dessus.
class _Bit extends StatelessWidget {
  const _Bit({
    required this.poids,
    required this.allume,
    required this.accent,
    required this.onTap,
  });

  final int poids;
  final bool allume;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$poids',
          style: context.text.labelSmall?.copyWith(
            color: allume ? accent : tokens.inkSubtle,
            fontWeight: allume ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: context.motionDuration(AppDurations.fast),
            height: 46,
            decoration: BoxDecoration(
              color: allume ? accent : context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(
                color: allume ? accent : tokens.border,
                width: allume ? 2 : 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              allume ? '1' : '0',
              style: AppTypography.formula(
                size: 20,
                color: allume ? Colors.white : tokens.inkSubtle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Raccourci extends StatelessWidget {
  const _Raccourci({
    required this.texte,
    required this.accent,
    required this.onTap,
  });

  final String texte;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilledButton.tonal(
    onPressed: () {
      context.tapFeedback();
      onTap();
    },
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      visualDensity: VisualDensity.compact,
    ),
    child: Text(texte, style: context.text.labelMedium),
  );
}
