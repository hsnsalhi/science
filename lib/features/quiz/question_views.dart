/// Saisie des réponses, un composant par type de question.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../design_system/answer_tile.dart';
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
        for (int position = 0; position < order.length; position++)
          Padding(
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

  int? _selectedLeft;

  late final List<int> _rightOrder =
      widget.session.matchOrder[widget.question.id] ??
      List<int>.generate(widget.question.pairs.length, (int i) => i);

  void _tapLeft(int index) {
    if (widget.locked) return;
    setState(() {
      if (_pairing.containsKey(index)) {
        // Toucher une paire déjà formée la défait : c'est le geste attendu.
        _pairing.remove(index);
        _selectedLeft = null;
      } else {
        _selectedLeft = _selectedLeft == index ? null : index;
      }
    });
    _emit();
  }

  void _tapRight(int right) {
    if (widget.locked) return;
    final int? left = _selectedLeft;
    if (left == null) return;
    setState(() {
      _pairing.removeWhere((_, int value) => value == right);
      _pairing[left] = right;
      _selectedLeft = null;
    });
    _emit();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Touche un élément de gauche, puis son correspondant à droite.',
          style: context.text.labelSmall?.copyWith(
            color: context.tokens.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < pairs.length; i++)
                    _MatchCell(
                      label: pairs[i].left,
                      badge: _pairing.containsKey(i)
                          ? '${_slotOf(_pairing[i]!) + 1}'
                          : null,
                      selected: _selectedLeft == i,
                      correct: widget.locked ? _pairing[i] == i : null,
                      accent: widget.accent,
                      onTap: () => _tapLeft(i),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                children: <Widget>[
                  for (int slot = 0; slot < _rightOrder.length; slot++)
                    _MatchCell(
                      label: pairs[_rightOrder[slot]].right,
                      badge: '${slot + 1}',
                      selected: _pairing.containsValue(_rightOrder[slot]),
                      correct: null,
                      accent: widget.accent,
                      onTap: () => _tapRight(_rightOrder[slot]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Position affichée de l'élément de droite [right].
  int _slotOf(int right) => _rightOrder.indexOf(right);
}

class _MatchCell extends StatelessWidget {
  const _MatchCell({
    required this.label,
    required this.badge,
    required this.selected,
    required this.correct,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String? badge;
  final bool selected;

  /// `null` tant que la question n'est pas corrigée.
  final bool? correct;

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final Color border = switch (correct) {
      true => tokens.success,
      false => tokens.error,
      null => selected ? accent : tokens.border,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: context.isDark ? 0.18 : 0.08)
                : context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: border, width: selected ? 2 : 1.5),
          ),
          child: Row(
            children: <Widget>[
              Expanded(child: Text(label, style: context.text.bodyMedium)),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(left: AppSpacing.sm),
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge!,
                    style: context.text.labelSmall?.copyWith(color: accent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
