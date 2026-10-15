/// Déroulé d'un quiz, du premier énoncé à la célébration.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/content/content_catalog.dart';
import '../../design_system/animations.dart';
import '../../design_system/app_button.dart';
import '../../design_system/app_scaffold.dart';
import '../../design_system/progress_indicators.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/lesson.dart';
import '../../domain/models/progress.dart';
import '../../domain/models/question.dart';
import '../../domain/services/quiz_session.dart';
import 'feedback_panel.dart';
import 'question_views.dart';
import 'result_view.dart';

/// Écran de quiz d'une leçon.
///
/// Toute la logique de déroulé vit dans [QuizSession], en Dart pur ; cet
/// écran ne fait que l'afficher et transmettre les gestes. C'est ce partage
/// qui permet de tester un parcours complet sans interface.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({
    required this.chapterId,
    required this.lessonId,
    required this.onExit,
    required this.onOpenNextLesson,
    super.key,
  });

  final String chapterId;
  final String lessonId;

  /// Quitter le quiz (retour au chapitre).
  final VoidCallback onExit;

  /// Ouvrir la leçon suivante du chapitre.
  final void Function(String chapterId, String lessonId) onOpenNextLesson;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  QuizSession? _session;
  LessonOutcome? _outcome;
  int _shakeTrigger = 0;

  QuizSession _ensureSession(Lesson lesson) =>
      _session ??= QuizSession.start(lesson.questions);

  void _onAnswer(Answer? answer) {
    setState(() => _session = _session!.withDraft(answer));
  }

  void _validate() {
    final QuizSession next = _session!.validate();
    if (next.verdict == QuizVerdict.correct) {
      context.successFeedback();
    } else {
      context.errorFeedback();
      _shakeTrigger++;
    }
    setState(() => _session = next);
  }

  void _advance(Chapter chapter, Lesson lesson) {
    final QuizSession next = _session!.advance();
    if (next.phase == QuizPhase.finished && _outcome == null) {
      final bool firstTime = !ref
          .read(progressProvider)
          .recordFor(chapter.id, lesson.id)
          .isCompleted;
      final LessonOutcome outcome = next.toOutcome(
        chapterId: chapter.id,
        lessonId: lesson.id,
        firstTimeCompleted: firstTime,
      );
      ref.read(progressProvider.notifier).completeLesson(outcome);
      _outcome = outcome;
    }
    setState(() => _session = next);
  }

  void _restart(Lesson lesson) {
    setState(() {
      _session = QuizSession.start(lesson.questions);
      _outcome = null;
      _shakeTrigger = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ContentCatalog catalog = ref.watch(contentCatalogProvider);
    final Chapter? chapter = catalog.chapterById(widget.chapterId);
    final Lesson? lesson = chapter?.lessonById(widget.lessonId);

    if (chapter == null || lesson == null || !lesson.hasQuiz) {
      return const AppScaffold(
        showBack: true,
        title: 'Exercices',
        body: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Exercices introuvables',
          message: 'Cette leçon ne comporte pas de questions.',
        ),
      );
    }

    final SubjectPalette palette = SubjectPalettes.of(chapter.subjectId);
    final QuizSession session = _ensureSession(lesson);

    if (session.phase == QuizPhase.finished) {
      return QuizResultView(
        session: session,
        chapter: chapter,
        lesson: lesson,
        accent: palette.base,
        onExit: widget.onExit,
        onRestart: () => _restart(lesson),
        onNextLesson: _nextLessonId(chapter, lesson) == null
            ? null
            : () => widget.onOpenNextLesson(
                chapter.id,
                _nextLessonId(chapter, lesson)!,
              ),
      );
    }

    final Question question = session.current!;
    final bool locked = session.phase == QuizPhase.feedback;

    return AppScaffold(
      scrollable: false,
      padBody: false,
      maxContentWidth: 640,
      titleWidget: StepProgress(
        total: session.total,
        currentIndex: session.index,
        results: <bool?>[
          for (int i = 0; i < session.total; i++)
            if (i < session.index)
              session.attempts[lesson.questions[i].id]?.solvedFirstTry ?? false
            else
              null,
        ],
      ),
      actions: <Widget>[
        AppIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Quitter les exercices',
          filled: false,
          onPressed: () => _confirmExit(context),
        ),
      ],
      bottomBar: _BottomArea(
        child: locked
            ? FeedbackPanel(
                verdict: session.verdict!,
                question: question,
                accent: palette.base,
                onContinue: () => _advance(chapter, lesson),
              )
            : _ValidateBar(
                canValidate: session.canValidate,
                hintAvailable: question.hint != null && !session.hintRevealed,
                accent: palette.base,
                onHint: () => setState(() => _session = session.revealHint()),
                onValidate: _validate,
              ),
      ),
      body: Shake(
        trigger: _shakeTrigger,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(question.prompt, style: context.text.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              if (question.figureId != null) ...<Widget>[
                QuestionFigure(
                  figureId: question.figureId!,
                  accent: palette.base,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (session.hintRevealed && question.hint != null) ...<Widget>[
                _HintBox(hint: question.hint!),
                const SizedBox(height: AppSpacing.lg),
              ],
              QuestionAnswerArea(
                question: question,
                session: session,
                accent: palette.base,
                locked: locked,
                onAnswer: _onAnswer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Identifiant de la leçon suivante du chapitre, s'il y en a une.
  String? _nextLessonId(Chapter chapter, Lesson lesson) {
    final int index = chapter.lessons.indexWhere(
      (Lesson l) => l.id == lesson.id,
    );
    if (index < 0 || index + 1 >= chapter.lessons.length) return null;
    return chapter.lessons[index + 1].id;
  }

  /// Confirme l'abandon : quitter en cours de quiz perd les XP de la session.
  Future<void> _confirmExit(BuildContext context) async {
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Quitter les exercices ?'),
        content: const Text(
          'Ta progression dans ces exercices ne sera pas enregistrée. '
          'Tu pourras les recommencer quand tu veux.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (leave ?? false) widget.onExit();
  }
}

/// Bas d'écran du quiz, dont la hauteur change entre saisie et retour.
///
/// [AnimatedSize] ne supporte pas une durée nulle : il se redemande une mise
/// en page pendant sa propre mise en page et la boucle ne s'arrête jamais. En
/// mode « animations réduites », on affiche donc l'enfant sans transition.
class _BottomArea extends StatelessWidget {
  const _BottomArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return AnimatedSize(
      duration: AppDurations.fast,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

/// Barre de validation, avec accès à l'indice.
class _ValidateBar extends StatelessWidget {
  const _ValidateBar({
    required this.canValidate,
    required this.hintAvailable,
    required this.accent,
    required this.onHint,
    required this.onValidate,
  });

  final bool canValidate;
  final bool hintAvailable;
  final Color accent;
  final VoidCallback onHint;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (hintAvailable) ...<Widget>[
          AppButton.secondary(
            label: 'Indice',
            icon: Icons.lightbulb_outline_rounded,
            expand: false,
            size: AppButtonSize.large,
            onPressed: onHint,
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: AppButton(
            label: 'Valider',
            color: accent,
            onPressed: canValidate ? onValidate : null,
          ),
        ),
      ],
    );
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return PopIn(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.tokens.goldSoft,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.lightbulb_rounded, color: context.tokens.gold, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(hint, style: context.text.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
