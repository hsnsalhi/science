/// Une séquence d'ARN qu'on mute, et la protéine qui en sort.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Le code génétique, et ce qu'une mutation en fait.
///
/// Le code génétique se présente d'ordinaire comme un tableau de
/// soixante-quatre cases qu'on consulte. Ici on change une base d'une
/// touche, et la protéine se retraduit sous les yeux. Trois issues
/// apparaissent alors d'elles-mêmes : la protéine ne change pas, elle
/// change d'un acide aminé, ou elle s'arrête net.
///
/// C'est la première issue qui vaut le détour. Qu'une mutation puisse
/// être sans effet ne se devine pas, et c'est pourtant la conséquence
/// directe d'un code à soixante-quatre codons pour vingt acides aminés.
class DnaFigure extends StatefulWidget {
  const DnaFigure({required this.accent, super.key});

  final Color accent;

  /// Les quatre bases de l'ARN messager.
  static const List<String> bases = <String>['A', 'U', 'G', 'C'];

  /// Séquence de départ : début de codage, puis deux acides aminés.
  static const String sequenceInitiale = 'AUGUUCGGA';

  /// La base d'ADN qui fait face à chaque base de l'ARN messager.
  static const Map<String, String> complement = <String, String>{
    'A': 'T',
    'U': 'A',
    'G': 'C',
    'C': 'G',
  };

  /// Le brin d'ADN à partir duquel l'ARN [arn] a été transcrit.
  ///
  /// Base pour base : l'ARN est la copie complémentaire de ce brin, où
  /// l'uracile remplace la thymine.
  static String brinTranscrit(String arn) =>
      arn.split('').map((String base) => complement[base] ?? '?').join();

  /// Le code génétique, codon par codon.
  ///
  /// Soixante-quatre codons pour vingt acides aminés et trois signaux
  /// d'arrêt : c'est cette redondance qui rend certaines mutations
  /// silencieuses.
  static const Map<String, String> code = <String, String>{
    'UUU': 'Phe', 'UUC': 'Phe', 'UUA': 'Leu', 'UUG': 'Leu',
    'CUU': 'Leu', 'CUC': 'Leu', 'CUA': 'Leu', 'CUG': 'Leu',
    'AUU': 'Ile', 'AUC': 'Ile', 'AUA': 'Ile', 'AUG': 'Met',
    'GUU': 'Val', 'GUC': 'Val', 'GUA': 'Val', 'GUG': 'Val',
    'UCU': 'Ser', 'UCC': 'Ser', 'UCA': 'Ser', 'UCG': 'Ser',
    'CCU': 'Pro', 'CCC': 'Pro', 'CCA': 'Pro', 'CCG': 'Pro',
    'ACU': 'Thr', 'ACC': 'Thr', 'ACA': 'Thr', 'ACG': 'Thr',
    'GCU': 'Ala', 'GCC': 'Ala', 'GCA': 'Ala', 'GCG': 'Ala',
    'UAU': 'Tyr', 'UAC': 'Tyr', 'UAA': 'Stop', 'UAG': 'Stop',
    'CAU': 'His', 'CAC': 'His', 'CAA': 'Gln', 'CAG': 'Gln',
    'AAU': 'Asn', 'AAC': 'Asn', 'AAA': 'Lys', 'AAG': 'Lys',
    'GAU': 'Asp', 'GAC': 'Asp', 'GAA': 'Glu', 'GAG': 'Glu',
    'UGU': 'Cys', 'UGC': 'Cys', 'UGA': 'Stop', 'UGG': 'Trp',
    'CGU': 'Arg', 'CGC': 'Arg', 'CGA': 'Arg', 'CGG': 'Arg',
    'AGU': 'Ser', 'AGC': 'Ser', 'AGA': 'Arg', 'AGG': 'Arg',
    'GGU': 'Gly', 'GGC': 'Gly', 'GGA': 'Gly', 'GGG': 'Gly',
  };

  /// Nom complet de chaque acide aminé.
  static const Map<String, String> noms = <String, String>{
    'Ala': 'alanine',
    'Arg': 'arginine',
    'Asn': 'asparagine',
    'Asp': 'aspartate',
    'Cys': 'cystéine',
    'Gln': 'glutamine',
    'Glu': 'glutamate',
    'Gly': 'glycine',
    'His': 'histidine',
    'Ile': 'isoleucine',
    'Leu': 'leucine',
    'Lys': 'lysine',
    'Met': 'méthionine',
    'Phe': 'phénylalanine',
    'Pro': 'proline',
    'Ser': 'sérine',
    'Thr': 'thréonine',
    'Trp': 'tryptophane',
    'Tyr': 'tyrosine',
    'Val': 'valine',
    'Stop': 'arrêt de la traduction',
  };

  /// Découpe une séquence en codons de trois bases.
  static List<String> codons(String sequence) => <String>[
    for (int i = 0; i + 3 <= sequence.length; i += 3)
      sequence.substring(i, i + 3),
  ];

  /// Acide aminé codé par un codon.
  static String acideAmine(String codon) => code[codon] ?? '?';

  /// Protéine obtenue, la traduction s'arrêtant au premier signal.
  static List<String> traduire(String sequence) {
    final List<String> proteine = <String>[];
    for (final String codon in codons(sequence)) {
      final String acide = acideAmine(codon);
      if (acide == 'Stop') break;
      proteine.add(acide);
    }
    return proteine;
  }

  @override
  State<DnaFigure> createState() => _DnaFigureState();
}

class _DnaFigureState extends State<DnaFigure> {
  String _sequence = DnaFigure.sequenceInitiale;

  void _muter(int position) {
    final String actuelle = _sequence[position];
    final int suivante =
        (DnaFigure.bases.indexOf(actuelle) + 1) % DnaFigure.bases.length;
    setState(() {
      _sequence = _sequence.replaceRange(
        position,
        position + 1,
        DnaFigure.bases[suivante],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final List<String> codons = DnaFigure.codons(_sequence);
    final List<String> depart =
        DnaFigure.traduire(DnaFigure.sequenceInitiale);
    final List<String> proteine = DnaFigure.traduire(_sequence);

    final String verdict;
    if (_sequence == DnaFigure.sequenceInitiale) {
      verdict = 'Séquence d\'origine. Touche une base pour la changer.';
    } else if (proteine.length < depart.length) {
      verdict = 'La traduction s\'arrête plus tôt : la protéine est '
          'tronquée.';
    } else if (proteine.join() == depart.join()) {
      verdict = 'La protéine est inchangée : la mutation est silencieuse.';
    } else {
      verdict = 'Un acide aminé a changé : la protéine est modifiée.';
    }

    final String brin = DnaFigure.brinTranscrit(_sequence);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'ADN, brin transcrit',
          style: context.text.labelSmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int c = 0; c * 3 < brin.length; c++) ...<Widget>[
              if (c > 0) const SizedBox(width: AppSpacing.sm),
              _BrinAdn(
                bases: brin.substring(c * 3, c * 3 + 3),
                accent: widget.accent,
                modifie: codons[c] !=
                    DnaFigure.codons(DnaFigure.sequenceInitiale)[c],
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.arrow_downward_rounded,
              size: 16,
              color: tokens.inkMuted,
            ),
            const SizedBox(width: 4),
            Text(
              'transcription',
              style: context.text.labelSmall?.copyWith(color: tokens.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'ARN messager',
          style: context.text.labelSmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int c = 0; c < codons.length; c++) ...<Widget>[
              if (c > 0) const SizedBox(width: AppSpacing.sm),
              _Codon(
                codon: codons[c],
                acide: DnaFigure.acideAmine(codons[c]),
                modifie: codons[c] !=
                    DnaFigure.codons(DnaFigure.sequenceInitiale)[c],
                accent: widget.accent,
                onBase: (int i) {
                  context.tapFeedback();
                  _muter(c * 3 + i);
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          proteine.isEmpty
              ? 'Aucune protéine'
              : proteine
                    .map((String a) => DnaFigure.noms[a] ?? a)
                    .join(' — '),
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 16, color: widget.accent),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 40,
          child: Text(
            verdict,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: () {
            context.tapFeedback();
            setState(() => _sequence = DnaFigure.sequenceInitiale);
          },
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          label: const Text('Revenir à la séquence d\'origine'),
        ),
      ],
    );
  }
}

/// Les trois bases d'ADN qui font face à un codon.
///
/// Elles ne se touchent pas : c'est l'ARN qu'on manipule, et le brin suit.
class _BrinAdn extends StatelessWidget {
  const _BrinAdn({
    required this.bases,
    required this.accent,
    required this.modifie,
  });

  final String bases;
  final Color accent;
  final bool modifie;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < bases.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: SizedBox(
              width: 30,
              height: 26,
              child: Center(
                child: Text(
                  bases[i],
                  style: AppTypography.formula(
                    size: 15,
                    color: modifie ? accent : tokens.inkMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Un codon : trois bases touchables, et l'acide aminé dessous.
class _Codon extends StatelessWidget {
  const _Codon({
    required this.codon,
    required this.acide,
    required this.modifie,
    required this.accent,
    required this.onBase,
  });

  final String codon;
  final String acide;
  final bool modifie;
  final Color accent;
  final ValueChanged<int> onBase;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool arret = acide == 'Stop';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < codon.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: GestureDetector(
                  onTap: () => onBase(i),
                  child: Container(
                    width: 30,
                    height: 38,
                    decoration: BoxDecoration(
                      color: modifie
                          ? accent.withValues(
                              alpha: context.isDark ? 0.3 : 0.16,
                            )
                          : context.colors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: modifie ? accent : tokens.border,
                        width: modifie ? 2 : 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      codon[i],
                      style: AppTypography.formula(
                        size: 17,
                        color: modifie ? accent : context.colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          acide,
          style: context.text.labelSmall?.copyWith(
            color: arret ? tokens.error : tokens.inkMuted,
            fontWeight: arret ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
