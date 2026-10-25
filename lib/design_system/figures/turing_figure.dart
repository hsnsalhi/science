/// Une machine de Turing qui ajoute 1, pas à pas.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';

/// L'état complet d'une machine : son ruban, la case lue, son état interne.
///
/// Tout ce qu'une machine de Turing « sait » tient dans ces trois champs.
/// C'est le point que la figure doit faire passer : il n'y a pas de mémoire
/// cachée, pas de variable, rien d'autre que le ruban et un nom d'état.
class EtatMachine {
  const EtatMachine({
    required this.ruban,
    required this.tete,
    required this.etat,
  });

  /// Les cases du ruban, chacune portant '0' ou '1'.
  final String ruban;

  /// L'indice de la case sous la tête de lecture.
  final int tete;

  /// Le nom de l'état interne : `ajoute` ou `fini`.
  final String etat;

  bool get termine => etat == TuringFigure.fini;

  @override
  bool operator ==(Object other) =>
      other is EtatMachine &&
      other.ruban == ruban &&
      other.tete == tete &&
      other.etat == etat;

  @override
  int get hashCode => Object.hash(ruban, tete, etat);
}

/// Une machine de Turing complète, qu'on fait tourner un pas à la fois.
///
/// La machine de Turing se raconte d'ordinaire avec un tableau de règles,
/// et le tableau ne convainc personne. Ici la machine tourne : on voit la
/// tête se déplacer, une case changer, l'état basculer. Au bout de quelques
/// pas, le ruban porte un nombre de plus qu'au départ.
///
/// Le programme choisi — ajouter 1 à un nombre binaire — a deux qualités.
/// Il est assez court pour tenir en trois règles, et son résultat se
/// vérifie par un calcul que l'élève sait déjà faire. La machine n'est donc
/// pas à croire sur parole : elle est à confronter à une addition.
class TuringFigure extends StatefulWidget {
  const TuringFigure({required this.accent, super.key});

  final Color accent;

  /// Nombre de cases du ruban.
  static const int cases = 8;

  /// L'état de départ : la tête à droite, prête à ajouter.
  static const String ajoute = 'ajoute';

  /// L'état d'arrêt. Une machine qui l'atteint ne fait plus rien.
  static const String fini = 'fini';

  /// Ruban de départ : 11, en binaire sur huit cases.
  static const String rubanInitial = '00001011';

  /// Les trois règles du programme, telles qu'elles s'affichent.
  static const List<String> regles = <String>[
    'ajoute, lit 0 : écrit 1, va à gauche, passe à fini',
    'ajoute, lit 1 : écrit 0, va à gauche, reste à ajouter',
    'fini : la machine s’arrête',
  ];

  /// L'état initial pour un ruban donné.
  static EtatMachine depart(String ruban) =>
      EtatMachine(ruban: ruban, tete: ruban.length - 1, etat: ajoute);

  /// Un pas de la machine.
  ///
  /// Un seul pas : lire la case, écrire, se déplacer, changer d'état. Si la
  /// machine est déjà finie, ou si la tête est sortie du ruban, l'état est
  /// rendu inchangé — une machine ne « plante » pas, elle s'arrête.
  static EtatMachine pas(EtatMachine courant) {
    if (courant.termine) return courant;
    if (courant.tete < 0 || courant.tete >= courant.ruban.length) {
      return EtatMachine(
        ruban: courant.ruban,
        tete: courant.tete,
        etat: fini,
      );
    }
    final String lu = courant.ruban[courant.tete];
    final String ecrit = lu == '1' ? '0' : '1';
    return EtatMachine(
      ruban: courant.ruban.replaceRange(
        courant.tete,
        courant.tete + 1,
        ecrit,
      ),
      tete: courant.tete - 1,
      // Lire 0 termine l'addition : il n'y a plus de retenue à propager.
      etat: lu == '1' ? ajoute : fini,
    );
  }

  /// La machine menée jusqu'à l'arrêt.
  ///
  /// [maxPas] garde le calcul borné : une machine quelconque peut ne jamais
  /// s'arrêter, et c'est précisément le sujet du chapitre.
  static EtatMachine executer(String ruban, {int maxPas = 100}) {
    EtatMachine courant = depart(ruban);
    for (int i = 0; i < maxPas && !courant.termine; i++) {
      courant = pas(courant);
    }
    return courant;
  }

  /// La valeur décimale d'un ruban.
  static int valeur(String ruban) => int.parse(ruban, radix: 2);

  /// Le ruban qui représente [valeur], sur [cases] cases.
  static String ruban(int valeur) =>
      valeur.toRadixString(2).padLeft(cases, '0');

  @override
  State<TuringFigure> createState() => _TuringFigureState();
}

class _TuringFigureState extends State<TuringFigure> {
  EtatMachine _etat = TuringFigure.depart(TuringFigure.rubanInitial);
  int _pas = 0;
  int _depart = TuringFigure.valeur(TuringFigure.rubanInitial);

  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;

  /// L'état de la machine après [pas] pas depuis le ruban de départ.
  ///
  /// Rejouer depuis le début est le seul moyen honnête de piloter un
  /// automate : son état n'est pas une valeur de curseur, c'est une
  /// histoire. La fonction reste pure, donc utilisable dans un `build`,
  /// et vingt-cinq pas ne coûtent rien.
  EtatMachine _rejouer(int pas) {
    EtatMachine etat = TuringFigure.depart(_etat.ruban);
    for (int i = 0; i < pas && !etat.termine; i++) {
      etat = TuringFigure.pas(etat);
    }
    return etat;
  }

  void _avancer() {
    if (_etat.termine) return;
    setState(() {
      _tenue = true;
      _etat = TuringFigure.pas(_etat);
      _pas++;
    });
  }

  void _toutExecuter() {
    setState(() {
      _tenue = true;
      while (!_etat.termine && _pas < 100) {
        _etat = TuringFigure.pas(_etat);
        _pas++;
      }
    });
  }

  void _reinitialiser(String ruban) {
    setState(() {
      _etat = TuringFigure.depart(ruban);
      _pas = 0;
      _depart = TuringFigure.valeur(ruban);
    });
  }

  void _basculer(int index) {
    if (_pas > 0) return;
    final String bit = _etat.ruban[index] == '1' ? '0' : '1';
    _reinitialiser(_etat.ruban.replaceRange(index, index + 1, bit));
  }

  @override
  Widget build(BuildContext context) {
    // La machine tourne : un pas après l'autre, jusqu'à l'arrêt, puis
    // elle repart. L'élève voit la tête lire, écrire et se déplacer sans
    // avoir à appuyer, et c'est le fonctionnement qui est le sujet.
    final double? avance = Autoplay.ramp(context, maintien: 0.28);
    final EtatMachine etat = _tenue || avance == null
        ? _etat
        : _rejouer((avance * 25).round());
    final int pas = _tenue || avance == null ? _pas : (avance * 25).round();
    final AppTokens tokens = context.tokens;
    final int actuelle = TuringFigure.valeur(etat.ruban);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int i = 0; i < etat.ruban.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: GestureDetector(
                  onTap: () {
                    context.tapFeedback();
                    _basculer(i);
                  },
                  child: AnimatedContainer(
                    duration: context.motionDuration(AppDurations.fast),
                    width: 32,
                    height: 40,
                    decoration: BoxDecoration(
                      color: i == etat.tete
                          ? widget.accent.withValues(
                              alpha: context.isDark ? 0.3 : 0.16,
                            )
                          : context.colors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: i == etat.tete ? widget.accent : tokens.border,
                        width: i == etat.tete ? 2 : 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      etat.ruban[i],
                      style: AppTypography.formula(
                        size: 18,
                        color: i == etat.tete
                            ? widget.accent
                            : context.colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Le repère de la tête, sous la case lue : sans lui, un ruban
        // entièrement identique ne dirait pas où en est la machine.
        SizedBox(
          height: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < etat.ruban.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: SizedBox(
                    width: 32,
                    child: i == etat.tete
                        ? Icon(
                            Icons.arrow_drop_up_rounded,
                            size: 18,
                            color: widget.accent,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ),
        Text(
          etat.termine
              ? 'État : fini. La machine s’arrête.'
              : 'État : ${_etat.etat}. Elle lit '
                    '${etat.tete >= 0 ? etat.ruban[etat.tete] : 'rien'}.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        // En cours de calcul, le ruban porte un nombre qui ne veut rien
        // dire : la retenue l'a momentanément diminué. L'afficher alors
        // ferait croire à une erreur, alors on ne compare qu'à l'arrêt.
        Text(
          etat.termine
              ? '$_depart devient $actuelle   ($pas pas)'
              : '$pas pas, calcul en cours',
          style: AppTypography.formula(
            size: 15,
            color: etat.termine && actuelle == _depart + 1
                ? tokens.success
                : tokens.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: etat.termine
                  ? null
                  : () {
                      context.tapFeedback();
                      _avancer();
                    },
              icon: const Icon(Icons.skip_next_rounded, size: 18),
              label: const Text('Un pas'),
            ),
            FilledButton.tonalIcon(
              onPressed: etat.termine
                  ? null
                  : () {
                      context.tapFeedback();
                      _toutExecuter();
                    },
              icon: const Icon(Icons.fast_forward_rounded, size: 18),
              label: const Text('Jusqu’au bout'),
            ),
            TextButton.icon(
              onPressed: () {
                context.tapFeedback();
                _reinitialiser(TuringFigure.rubanInitial);
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Recommencer'),
            ),
          ],
        ),
      ],
    );
  }
}
