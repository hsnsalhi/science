/// Déroulé d'un quiz, du premier énoncé à la célébration.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/content/content_catalog.dart';
import '../../design_system/animations.dart';
import '../../design_system/chips.dart';
import '../../design_system/app_button.dart';
import '../../design_system/app_scaffold.dart';
import '../../design_system/progress_indicators.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/lesson.dart';
import '../../domain/models/progress.dart';
import '../../domain/models/question.dart';
import '../../domain/services/xp_engine.dart';
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
  /// Temps accordé par question dans un défi chronométré.
  static const Duration _fenetre = Duration(seconds: 30);

  QuizSession? _session;
  LessonOutcome? _outcome;
  int _shakeTrigger = 0;

  /// Début de la question en cours, quand le chronomètre tourne.
  DateTime? _depart;
  Timer? _battement;

  @override
  void dispose() {
    _battement?.cancel();
    super.dispose();
  }

  /// Temps restant, ou `null` si la question n'est pas chronométrée.
  Duration? get _restant {
    final DateTime? depart = _depart;
    if (depart == null) return null;
    final Duration ecoule = ref.read(clockProvider)().difference(depart);
    final Duration reste = _fenetre - ecoule;
    return reste.isNegative ? Duration.zero : reste;
  }

  void _lancerChrono() {
    _battement?.cancel();
    _depart = ref.read(clockProvider)();
    // Un battement de cinq par seconde suffit à une barre qui se vide ;
    // rafraîchir à chaque image coûterait sans rien montrer de plus.
    _battement = Timer.periodic(const Duration(milliseconds: 200), (Timer t) {
      if (!mounted) return;
      if ((_restant ?? Duration.zero) <= Duration.zero) t.cancel();
      setState(() {});
    });
  }

  void _arreterChrono() {
    _battement?.cancel();
    _battement = null;
  }

  QuizSession _ensureSession(Lesson lesson) => _session ??= QuizSession.start(
    lesson.questions,
    random: ref.read(quizRandomProvider)(),
  );

  void _onAnswer(Answer? answer) {
    setState(() => _session = _session!.withDraft(answer));
  }

  void _validate() {
    // Le clavier n'a plus rien à saisir une fois la réponse envoyée, et il
    // masquerait la moitié du retour.
    FocusScope.of(context).unfocus();
    // Hors défi chronométré, le bonus de rapidité est toujours accordé :
    // couper le chronomètre ne doit pas coûter d'XP.
    final Duration? reste = _restant;
    final bool rapide = reste == null || reste > Duration.zero;
    _arreterChrono();
    final QuizSession next = _session!.validate(rapide: rapide);
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
    if (next.phase == QuizPhase.answering && _depart != null) {
      _lancerChrono();
    }
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
      _session = QuizSession.start(
        lesson.questions,
        random: ref.read(quizRandomProvider)(),
      );
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

    // Le chronomètre ne concerne que les défis, et seulement si l'élève
    // l'a laissé actif. Lancé ici plutôt qu'à l'initialisation parce que
    // la leçon n'est connue qu'une fois le catalogue lu.
    final bool chronometre =
        lesson.kind == LessonKind.defi &&
        ref.watch(settingsProvider).timedChallenges;
    if (chronometre && _depart == null && !locked) {
      _lancerChrono();
    }
    final Duration? reste = chronometre ? _restant : null;

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
        // Les XP se cumulent sous les yeux : sans ce compteur, le gain de
        // chaque question disparaît avec le panneau de retour.
        if (session.xpEarned > 0)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppChip(
              label: '${session.xpEarned} XP',
              icon: Icons.bolt_rounded,
              color: palette.base,
              dense: true,
            ),
          ),
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
                xpEarned: session.currentAttempt.xpEarned,
                combo: session.combo,
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
          // Un glissement vers le bas referme le clavier : deuxième sortie,
          // utile parce que le pavé numérique d'iOS n'a pas de touche de
          // retour.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (reste != null) ...<Widget>[
                _Chrono(reste: reste, fenetre: _fenetre, accent: palette.base),
                const SizedBox(height: AppSpacing.lg),
              ],
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

/// Compte à rebours d'une question de défi.
///
/// Il n'enlève rien : arrivé à zéro, la question se joue normalement,
/// seul le bonus de rapidité est perdu. La barre le dit en toutes lettres
/// plutôt que de laisser croire à une sanction.
class _Chrono extends StatelessWidget {
  const _Chrono({
    required this.reste,
    required this.fenetre,
    required this.accent,
  });

  final Duration reste;
  final Duration fenetre;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool ecoule = reste <= Duration.zero;
    final bool presse = !ecoule && reste.inSeconds < 10;
    final Color couleur = ecoule
        ? tokens.inkSubtle
        : (presse ? tokens.warning : accent);
    final double part = (reste.inMilliseconds / fenetre.inMilliseconds).clamp(
      0.0,
      1.0,
    );

    return Semantics(
      liveRegion: presse,
      label: ecoule
          ? 'Temps écoulé, la question reste ouverte.'
          : '${reste.inSeconds} secondes pour le bonus.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                ecoule ? Icons.timer_off_rounded : Icons.timer_rounded,
                size: 16,
                color: couleur,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                ecoule
                    ? 'Temps écoulé — la question reste ouverte'
                    : '${reste.inSeconds} s pour +${XpEngine.speedBonus} XP',
                style: context.text.labelMedium?.copyWith(color: couleur),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: part,
              minHeight: 6,
              backgroundColor: tokens.border,
              valueColor: AlwaysStoppedAnimation<Color>(couleur),
            ),
          ),
        ],
      ),
    );
  }
}
