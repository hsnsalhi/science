/// Saisie des réponses, un composant par type de question.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../design_system/animations.dart';
import '../../design_system/answer_tile.dart';
import '../../design_system/chips.dart';
import '../../design_system/figures/figure_registry.dart';
import '../../domain/models/question.dart';
import '../../domain/services/quiz_session.dart';

/// Zone de réponse adaptée au type de la question courante.
///
/// Un seul point d'entrée pour les sept types d'exercices : l'écran de quiz
/// n'a aucune condition sur le type de question, et ajouter un type se fait
/// ici sans toucher à l'orchestration.
class QuestionAnswerArea extends StatelessWidget {
  const QuestionAnswerArea({
    required this.question,
    required this.session,
    required this.onAnswer,
    required this.accent,
    required this.locked,
    super.key,
  });

  final Question question;
  final QuizSession session;

  /// Remonte la réponse composée, ou `null` si elle est incomplète.
  final ValueChanged<Answer?> onAnswer;

  final Color accent;

  /// `true` pendant l'affichage du retour : la saisie est figée.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final Key key = ValueKey<String>(question.id);
    return switch (question) {
      SingleChoiceQuestion() || MultipleChoiceQuestion() => _ChoiceView(
        key: key,
        question: question,
        session: session,
        onAnswer: onAnswer,
        locked: locked,
      ),
      TrueFalseQuestion() => _TrueFalseView(
        key: key,
        question: question as TrueFalseQuestion,
        draft: session.draft,
        onAnswer: onAnswer,
        locked: locked,
        verdict: session.verdict,
      ),
      NumericQuestion() => _NumericView(
        key: key,
        question: question as NumericQuestion,
        onAnswer: onAnswer,
        locked: locked,
        accent: accent,
      ),
      FillBlanksQuestion() => _BlanksView(
        key: key,
        question: question as FillBlanksQuestion,
        onAnswer: onAnswer,
        locked: locked,
        accent: accent,
      ),
      OrderingQuestion() => _OrderingView(
        key: key,
        question: question as OrderingQuestion,
        session: session,
        onAnswer: onAnswer,
        locked: locked,
        accent: accent,
      ),
      MatchingQuestion() => _MatchingView(
        key: key,
        question: question as MatchingQuestion,
        session: session,
        onAnswer: onAnswer,
        locked: locked,
        accent: accent,
      ),
    };
  }
}

/// Figure interactive associée à une question, si elle en a une.
class QuestionFigure extends StatelessWidget {
  const QuestionFigure({
    required this.figureId,
    required this.accent,
    super.key,
  });

  final String figureId;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: context.tokens.border),
    ),
    child: FigureRegistry.build(context, figureId, accent),
  );
}

// ------------------------------------------------------- Choix unique/multiple

class _ChoiceView extends StatelessWidget {
  const _ChoiceView({
    required this.question,
    required this.session,
    required this.onAnswer,
    required this.locked,
    super.key,
  });

  final Question question;
  final QuizSession session;
  final ValueChanged<Answer?> onAnswer;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final bool multi = question is MultipleChoiceQuestion;
    final List<AnswerOption> options = question is SingleChoiceQuestion
        ? (question as SingleChoiceQuestion).options
        : (question as MultipleChoiceQuestion).options;
    final List<int> order =
        session.displayOrder[question.id] ??
        List<int>.generate(options.length, (int i) => i);
    final Set<int> selected = switch (session.draft) {
      final ChoiceAnswer answer => answer.selected,
      _ => const <int>{},
    };

    void toggle(int originalIndex) {
      if (locked) return;
      if (multi) {
        final Set<int> next = Set<int>.of(selected);
        next.contains(originalIndex)
            ? next.remove(originalIndex)
            : next.add(originalIndex);
        onAnswer(next.isEmpty ? null : ChoiceAnswer(next));
      } else {
        onAnswer(ChoiceAnswer(<int>{originalIndex}));
      }
    }

    return Column(
      children: <Widget>[
        if (multi)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.checklist_rounded,
                  size: 16,
                  color: context.tokens.inkMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Plusieurs réponses possibles',
                  style: context.text.labelSmall?.copyWith(
                    color: context.tokens.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        // Les réponses se posent l'une après l'autre. La clé porte
        // l'identifiant de la question : sans elle, l'état d'animation
        // survivrait au changement de question et seule la première
        // volée serait jouée.
        for (int position = 0; position < order.length; position++)
          SlideFadeIn(
            key: ValueKey<String>('${question.id}-$position'),
            delay: Duration(milliseconds: 60 * position),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AnswerTile(
                label: options[order[position]].text,
                leadingLetter: optionLetter(position),
                multiSelect: multi,
                state: _stateFor(
                  correct: options[order[position]].isCorrect,
                  isSelected: selected.contains(order[position]),
                ),
                onTap: locked ? null : () => toggle(order[position]),
              ),
            ),
          ),
      ],
    );
  }

  AnswerTileState _stateFor({required bool correct, required bool isSelected}) {
    if (!locked) {
      return isSelected ? AnswerTileState.selected : AnswerTileState.idle;
    }
    if (isSelected) {
      return correct ? AnswerTileState.correct : AnswerTileState.wrong;
    }
    // La bonne réponse non choisie n'est révélée qu'une fois les essais
    // épuisés : sinon on priverait l'élève de son second essai.
    if (correct && session.verdict == QuizVerdict.revealed) {
      return AnswerTileState.revealed;
    }
    return AnswerTileState.idle;
  }
}

// ----------------------------------------------------------------- Vrai/Faux

class _TrueFalseView extends StatelessWidget {
  const _TrueFalseView({
    required this.question,
    required this.draft,
    required this.onAnswer,
    required this.locked,
    required this.verdict,
    super.key,
  });

  final TrueFalseQuestion question;
  final Answer? draft;
  final ValueChanged<Answer?> onAnswer;
  final bool locked;
  final QuizVerdict? verdict;

  @override
  Widget build(BuildContext context) {
    final bool? chosen = switch (draft) {
      final BooleanAnswer answer => answer.value,
      _ => null,
    };

    AnswerTileState stateFor(bool value) {
      if (!locked) {
        return chosen == value
            ? AnswerTileState.selected
            : AnswerTileState.idle;
      }
      if (chosen == value) {
        return value == question.expected
            ? AnswerTileState.correct
            : AnswerTileState.wrong;
      }
      if (value == question.expected && verdict == QuizVerdict.revealed) {
        return AnswerTileState.revealed;
      }
      return AnswerTileState.idle;
    }

    return Row(
      children: <Widget>[
        for (final bool value in <bool>[true, false]) ...<Widget>[
          Expanded(
            child: AnswerTile(
              label: value ? 'Vrai' : 'Faux',
              state: stateFor(value),
              onTap: locked ? null : () => onAnswer(BooleanAnswer(value)),
            ),
          ),
          if (value) const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------ Saisie numérique

class _NumericView extends StatefulWidget {
  const _NumericView({
    required this.question,
    required this.onAnswer,
    required this.locked,
    required this.accent,
    super.key,
  });

  final NumericQuestion question;
  final ValueChanged<Answer?> onAnswer;
  final bool locked;
  final Color accent;

  @override
  State<_NumericView> createState() => _NumericViewState();
}

class _NumericViewState extends State<_NumericView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: !widget.locked,
            autofocus: false,
            textAlign: TextAlign.center,
            style: AppTypography.formula(
              size: 26,
              color: context.colors.onSurface,
            ),
            // Clavier décimal, virgule française acceptée à la lecture.
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
            ],
            decoration: const InputDecoration(hintText: '?'),
            onChanged: (String value) =>
                widget.onAnswer(switch (NumericQuestion.parseInput(value)) {
                  final double parsed => NumericAnswer(parsed),
                  null => null,
                }),
          ),
        ),
        if (widget.question.unit != null) ...<Widget>[
          const SizedBox(width: AppSpacing.md),
          Text(
            widget.question.unit!,
            style: context.text.titleLarge?.copyWith(
              color: context.tokens.inkMuted,
            ),
          ),
        ],
      ],
    );
  }
}

// -------------------------------------------------------------- Texte à trous

class _BlanksView extends StatefulWidget {
  const _BlanksView({
    required this.question,
    required this.onAnswer,
    required this.locked,
    required this.accent,
    super.key,
  });

  final FillBlanksQuestion question;
  final ValueChanged<Answer?> onAnswer;
  final bool locked;
  final Color accent;

  @override
  State<_BlanksView> createState() => _BlanksViewState();
}

class _BlanksViewState extends State<_BlanksView> {
  late final List<TextEditingController> _controllers =
      List<TextEditingController>.generate(
        widget.question.blankCount,
        (_) => TextEditingController(),
      );

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final List<String> entries = _controllers
        .map((TextEditingController c) => c.text)
        .toList(growable: false);
    widget.onAnswer(
      entries.any((String e) => e.trim().isEmpty)
          ? null
          : BlanksAnswer(entries),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> segments = widget.question.segments;
    final TextStyle style = AppTypography.formula(
      size: 19,
      color: context.colors.onSurface,
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (int i = 0; i < segments.length; i++) ...<Widget>[
          if (segments[i].trim().isNotEmpty)
            Text(segments[i].trim(), style: style),
          if (i < widget.question.blankCount)
            SizedBox(
              width: 96,
              child: TextField(
                controller: _controllers[i],
                enabled: !widget.locked,
                textAlign: TextAlign.center,
                style: style.copyWith(color: widget.accent),
                // Un trou qui attend un nombre ouvre le pavé numérique et
                // refuse les lettres : sans cela, le clavier alphabétique
                // s'ouvrait sur « 15² = ___ » et laissait écrire n'importe
                // quoi.
                keyboardType: widget.question.isNumericBlank(i)
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                inputFormatters: widget.question.isNumericBlank(i)
                    ? <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,\-]'),
                        ),
                      ]
                    : null,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.md,
                  ),
                  hintText: '…',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.accent, width: 2),
                  ),
                ),
                onChanged: (_) => _emit(),
              ),
            ),
        ],
      ],
    );
  }
}

// ----------------------------------------------------------- Remise en ordre

class _OrderingView extends StatefulWidget {
  const _OrderingView({
    required this.question,
    required this.session,
    required this.onAnswer,
    required this.locked,
    required this.accent,
    super.key,
  });

  final OrderingQuestion question;
  final QuizSession session;
  final ValueChanged<Answer?> onAnswer;
  final bool locked;
  final Color accent;

  @override
  State<_OrderingView> createState() => _OrderingViewState();
}

class _OrderingViewState extends State<_OrderingView> {
  late final List<int> _order = List<int>.of(
    widget.session.displayOrder[widget.question.id] ??
        List<int>.generate(widget.question.items.length, (int i) => i),
  );

  @override
  void initState() {
    super.initState();
    // L'ordre affiché est déjà une réponse valide : on l'envoie tout de suite
    // pour que le bouton « Valider » soit actif sans déplacement préalable.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onAnswer(OrderingAnswer(_order));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: !widget.locked,
      itemCount: _order.length,
      // `onReorderItem` reçoit un index déjà corrigé pour le retrait de
      // l'élément déplacé, contrairement à l'ancien `onReorder`.
      onReorderItem: (int oldIndex, int newIndex) {
        if (widget.locked) return;
        setState(() => _order.insert(newIndex, _order.removeAt(oldIndex)));
        widget.onAnswer(OrderingAnswer(_order));
      },
      itemBuilder: (BuildContext context, int position) {
        final int original = _order[position];
        return Padding(
          key: ValueKey<int>(original),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: widget.locked && _order[position] == position
                    ? context.tokens.success
                    : context.tokens.border,
                width: 1.5,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${position + 1}',
                    style: context.text.labelMedium?.copyWith(
                      color: widget.accent,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    widget.question.items[original],
                    style: context.text.bodyMedium,
                  ),
                ),
                Icon(
                  Icons.drag_handle_rounded,
                  color: context.tokens.inkSubtle,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --------------------------------------------------------------- Appariement

class _MatchingView extends StatefulWidget {
  const _MatchingView({
    required this.question,
    required this.session,
    required this.onAnswer,
    required this.locked,
    required this.accent,
    super.key,
  });

  final MatchingQuestion question;
  final QuizSession session;
  final ValueChanged<Answer?> onAnswer;
  final bool locked;
  final Color accent;

  @override
  State<_MatchingView> createState() => _MatchingViewState();
}

class _MatchingViewState extends State<_MatchingView> {
  /// Associations composées : indice de gauche vers indice de droite.
  final Map<int, int> _pairing = <int, int>{};

  /// Étiquette choisie du doigt, pour qui préfère toucher que glisser.
  int? _selectedLeft;

  late final List<int> _rightOrder =
      widget.session.matchOrder[widget.question.id] ??
      List<int>.generate(widget.question.pairs.length, (int i) => i);

  /// Associe l'étiquette [left] à la définition [right].
  void _lier(int left, int right) {
    if (widget.locked) return;
    context.tapFeedback();
    setState(() {
      // Une définition ne reçoit qu'une étiquette : celle qui s'y trouvait
      // retourne dans la réserve.
      _pairing.removeWhere((_, int value) => value == right);
      _pairing[left] = right;
      _selectedLeft = null;
    });
    _emit();
  }

  void _reprendre(int left) {
    if (widget.locked) return;
    setState(() {
      _pairing.remove(left);
      _selectedLeft = null;
    });
    _emit();
  }

  void _toucherEtiquette(int left) {
    if (widget.locked) return;
    if (_pairing.containsKey(left)) {
      _reprendre(left);
      return;
    }
    setState(() => _selectedLeft = _selectedLeft == left ? null : left);
  }

  void _toucherDefinition(int right) {
    final int? left = _selectedLeft;
    if (left == null) return;
    _lier(left, right);
  }

  void _emit() {
    widget.onAnswer(
      _pairing.length == widget.question.pairs.length
          ? MatchingAnswer(Map<int, int>.of(_pairing))
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<MatchPair> pairs = widget.question.pairs;
    final List<int> libres = <int>[
      for (int i = 0; i < pairs.length; i++)
        if (!_pairing.containsKey(i)) i,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          libres.isEmpty
              ? 'Touche une étiquette posée pour la reprendre.'
              : 'Fais glisser chaque étiquette sur sa définition.',
          style: context.text.labelSmall?.copyWith(
            color: context.tokens.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // La réserve d'étiquettes. Elle se vide à mesure qu'on les place :
        // ce qu'il reste à faire se voit d'un coup d'œil, ce qu'une
        // colonne figée avec des numéros ne montrait pas.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final int i in libres)
              _Etiquette(
                label: pairs[i].left,
                accent: widget.accent,
                selectionnee: _selectedLeft == i,
                locked: widget.locked,
                onTap: () => _toucherEtiquette(i),
                index: i,
              ),
            if (libres.isEmpty)
              Text(
                'Toutes les étiquettes sont placées.',
                style: context.text.bodySmall?.copyWith(
                  color: context.tokens.inkMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        for (int slot = 0; slot < _rightOrder.length; slot++)
          _Definition(
            texte: pairs[_rightOrder[slot]].right,
            right: _rightOrder[slot],
            posee: _pairing.entries
                .where((MapEntry<int, int> e) => e.value == _rightOrder[slot])
                .map((MapEntry<int, int> e) => e.key)
                .firstOrNull,
            etiquetteDe: (int left) => pairs[left].left,
            accent: widget.accent,
            locked: widget.locked,
            attendUnDepot: _selectedLeft != null,
            onAccepte: (int left) => _lier(left, _rightOrder[slot]),
            onTap: () => _toucherDefinition(_rightOrder[slot]),
            onReprendre: _reprendre,
          ),
      ],
    );
  }
}

/// Étiquette à poser sur une définition.
class _Etiquette extends StatelessWidget {
  const _Etiquette({
    required this.label,
    required this.accent,
    required this.selectionnee,
    required this.locked,
    required this.onTap,
    required this.index,
  });

  final String label;
  final Color accent;
  final bool selectionnee;
  final bool locked;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final Widget corps = _corps(context, flottante: false);
    if (locked) return corps;
    return Draggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: _corps(context, flottante: true),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: corps),
      child: GestureDetector(onTap: onTap, child: corps),
    );
  }

  Widget _corps(BuildContext context, {required bool flottante}) {
    final AppTokens tokens = context.tokens;
    final bool mise = selectionnee || flottante;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: mise
            ? accent.withValues(alpha: context.isDark ? 0.24 : 0.12)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(
          color: mise ? accent : tokens.border,
          width: mise ? 2 : 1.5,
        ),
        boxShadow: flottante
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.drag_indicator_rounded, size: 18, color: tokens.inkSubtle),
          const SizedBox(width: AppSpacing.xs),
          Flexible(child: Text(label, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}

/// Définition qui accueille une étiquette.
class _Definition extends StatelessWidget {
  const _Definition({
    required this.texte,
    required this.right,
    required this.posee,
    required this.etiquetteDe,
    required this.accent,
    required this.locked,
    required this.attendUnDepot,
    required this.onAccepte,
    required this.onTap,
    required this.onReprendre,
  });

  final String texte;
  final int right;

  /// Indice de l'étiquette posée ici, s'il y en a une.
  final int? posee;

  final String Function(int left) etiquetteDe;
  final Color accent;
  final bool locked;

  /// Une étiquette est sélectionnée au doigt : la cible s'annonce.
  final bool attendUnDepot;

  final void Function(int left) onAccepte;
  final VoidCallback onTap;
  final void Function(int left) onReprendre;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onAcceptWithDetails: (DragTargetDetails<int> d) => onAccepte(d.data),
      builder:
          (
            BuildContext context,
            List<int?> candidats,
            List<dynamic> rejetes,
          ) {
            final AppTokens tokens = context.tokens;
            final bool survol = candidats.isNotEmpty;
            final bool juste = locked && posee == right;
            final Color bordure = locked
                ? (juste ? tokens.success : tokens.error)
                : (survol || attendUnDepot ? accent : tokens.border);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: context.motionDuration(AppDurations.fast),
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: survol
                        ? accent.withValues(alpha: context.isDark ? 0.2 : 0.09)
                        : context.colors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                      color: bordure,
                      width: survol || locked ? 2 : 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(texte, style: context.text.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      // Emplacement vide, visible. Une carte ordinaire ne
                      // dit pas qu'on peut y déposer quelque chose, et la
                      // consigne au-dessus ne désigne pas laquelle.
                      if (posee == null)
                        Container(
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withValues(
                              alpha: survol ? 0.18 : 0.06,
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Text(
                            survol ? 'Lâche ici' : 'Dépose une étiquette',
                            style: context.text.labelSmall?.copyWith(
                              color: survol ? accent : tokens.inkSubtle,
                            ),
                          ),
                        ),
                      if (posee != null) ...<Widget>[
                        GestureDetector(
                          onTap: locked ? null : () => onReprendre(posee!),
                          child: AppChip(
                            label: etiquetteDe(posee!),
                            icon: locked
                                ? (juste
                                      ? Icons.check_rounded
                                      : Icons.close_rounded)
                                : Icons.close_rounded,
                            color: locked
                                ? (juste ? tokens.success : tokens.error)
                                : accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }
}
