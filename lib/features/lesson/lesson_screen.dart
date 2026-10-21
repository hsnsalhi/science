/// Lecteur de leçon : les cartes d'apprentissage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/content/content_catalog.dart';
import '../../design_system/animations.dart';
import '../../design_system/app_button.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_scaffold.dart';
import '../../design_system/figures/figure_registry.dart';
import '../../design_system/formula_block.dart';
import '../../design_system/mascot.dart';
import '../../design_system/progress_indicators.dart';
import '../../design_system/visuals.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/lesson.dart';

/// Défilé des cartes d'une leçon, puis passage aux exercices.
///
/// Une carte par écran, un bouton pour avancer : c'est le format le plus
/// simple possible, et c'est volontaire. Un cours présenté comme un long
/// texte défilant n'est jamais lu en entier sur un téléphone.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({
    required this.chapterId,
    required this.lessonId,
    required this.onStartQuiz,
    required this.onFinishWithoutQuiz,
    super.key,
  });

  final String chapterId;
  final String lessonId;

  /// Appelé à la fin des cartes quand la leçon comporte des questions.
  final void Function(String chapterId, String lessonId) onStartQuiz;

  /// Appelé à la fin d'une leçon sans questions.
  final VoidCallback onFinishWithoutQuiz;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  final PageController _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pages.animateToPage(
      index,
      duration: AppDurations.base,
      curve: AppCurves.move,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ContentCatalog catalog = ref.watch(contentCatalogProvider);
    final Chapter? chapter = catalog.chapterById(widget.chapterId);
    final Lesson? lesson = chapter?.lessonById(widget.lessonId);

    if (chapter == null || lesson == null) {
      return const AppScaffold(
        showBack: true,
        title: 'Leçon',
        body: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Leçon introuvable',
          message: 'Cette leçon n\'existe plus dans le contenu.',
        ),
      );
    }

    final SubjectPalette palette = SubjectPalettes.of(chapter.subjectId);

    // Une leçon d'entraînement pur n'a aucune carte : on va droit aux
    // questions sans faire cliquer l'élève dans le vide.
    if (lesson.cards.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onStartQuiz(chapter.id, lesson.id);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isLast = _index == lesson.cards.length - 1;

    return AppScaffold(
      scrollable: false,
      padBody: false,
      maxContentWidth: 640,
      titleWidget: _LessonHeader(
        lesson: lesson,
        index: _index,
        total: lesson.cards.length,
        color: palette.base,
      ),
      actions: <Widget>[
        AppIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Quitter la leçon',
          filled: false,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
      bottomBar: Row(
        children: <Widget>[
          if (_index > 0) ...<Widget>[
            AppButton.secondary(
              label: 'Précédent',
              icon: Icons.arrow_back_rounded,
              expand: false,
              size: AppButtonSize.medium,
              onPressed: () => _goTo(_index - 1),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: AppButton(
              label: isLast
                  ? (lesson.hasQuiz ? 'Passer aux exercices' : 'Terminer')
                  : 'Suivant',
              color: palette.base,
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: () {
                if (!isLast) {
                  _goTo(_index + 1);
                } else if (lesson.hasQuiz) {
                  widget.onStartQuiz(chapter.id, lesson.id);
                } else {
                  widget.onFinishWithoutQuiz();
                }
              },
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pages,
        onPageChanged: (int index) => setState(() => _index = index),
        itemCount: lesson.cards.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: LessonCardView(
              card: lesson.cards[index],
              accent: palette.base,
              stepNumber: _stepNumber(lesson, index),
            ),
          );
        },
      ),
    );
  }

  /// Numéro affiché sur une carte « étape », en comptant les étapes seules.
  int? _stepNumber(Lesson lesson, int index) {
    if (lesson.cards[index].kind != LessonCardKind.etape) return null;
    int n = 0;
    for (int i = 0; i <= index; i++) {
      if (lesson.cards[i].kind == LessonCardKind.etape) n++;
    }
    return n;
  }
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({
    required this.lesson,
    required this.index,
    required this.total,
    required this.color,
  });

  final Lesson lesson;
  final int index;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          lesson.title,
          style: context.text.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppProgressBar(
          value: (index + 1) / total,
          height: 6,
          color: color,
          semanticLabel: 'Carte ${index + 1} sur $total',
        ),
      ],
    );
  }
}

/// Affichage d'une carte d'apprentissage.
class LessonCardView extends StatelessWidget {
  const LessonCardView({
    required this.card,
    required this.accent,
    this.stepNumber,
    super.key,
  });

  final LessonCard card;
  final Color accent;

  /// Rang de l'étape, pour les cartes de méthode.
  final int? stepNumber;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final String? label = CardVisuals.label(card.kind);
    final IconData? icon = CardVisuals.icon(card.kind);

    // L'en-tête reste en haut ; le reste occupe la hauteur disponible.
    // Une carte tient un écran : laisser le contenu s'empiler en haut
    // d'une page à moitié vide la fait paraître bavarde et creuse à la
    // fois.
    final List<Widget> head = <Widget>[
      if (label != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 17, color: accent),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                stepNumber == null ? label : '$label $stepNumber',
                style: context.text.labelMedium?.copyWith(color: accent),
              ),
            ],
          ),
        ),
      if (card.title != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(card.title!, style: context.text.headlineMedium),
        ),
    ];

    final List<Widget> prose = <Widget>[
      if (card.body != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Text(card.body!, style: context.text.bodyLarge),
        ),
      if (card.formula != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: FormulaBlock(formula: card.formula!, accent: accent),
        ),
      for (final String bullet in card.bullets)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(top: 8, right: AppSpacing.md),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(child: Text(bullet, style: context.text.bodyMedium)),
            ],
          ),
        ),
    ];

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ...head,
        // Quand la carte porte une figure, c'est elle qu'on regarde :
        // elle prend toute la place restante, et le texte passe au-dessus
        // en une ligne. L'inverse — un paragraphe suivi d'une vignette —
        // donne une page de cours, pas un écran qu'on manipule.
        if (card.figureId != null) ...<Widget>[
          if (prose.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: prose,
            ),
          // La carte épouse la figure plutôt que de s'étirer : le tracé
          // est limité par la largeur, l'étirer en hauteur n'ajoutait que
          // du blanc à l'intérieur. Le vide restant va à la page, qui le
          // répartit au-dessus et au-dessous.
          //
          // Le défilement n'est pas une précaution de principe : une
          // figure pilotable porte ses commandes sous le dessin, et sur un
          // écran court ce sont elles qui sortaient du cadre. L'élève
          // voyait la figure sans pouvoir la manipuler, ce qui est pire
          // que pas de figure du tout.
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: FigureRegistry.build(context, card.figureId!, accent),
                ),
              ),
            ),
          ),
        ] else
          // Sans figure, le texte se centre : court, il est au milieu de
          // l'écran plutôt que collé en haut ; long, il défile.
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: prose,
                ),
              ),
            ),
          ),
      ],
    );

    return PopIn(
      key: ValueKey<String>(card.id),
      child: switch (card.kind) {
        // Les encadrés gardent une surface teintée : ils se repèrent d'un
        // coup d'œil quand on refeuillette la leçon.
        LessonCardKind.astuce => Center(
          child: AppNotice(
            color: tokens.info,
            icon: Icons.tips_and_updates_rounded,
            title: 'Astuce',
            child: Text(card.body ?? '', style: context.text.bodyMedium),
          ),
        ),
        // La mise en garde emprunte la même forme que l'astuce, mais la
        // couleur d'alerte : c'est la seule carte qu'un élève doit
        // reconnaître avant de l'avoir lue.
        LessonCardKind.avertissement => Center(
          child: AppNotice(
            color: tokens.warning,
            icon: Icons.warning_amber_rounded,
            title: 'Prudence',
            child: Text(card.body ?? '', style: context.text.bodyMedium),
          ),
        ),
        LessonCardKind.aRetenir => Center(
          child: SingleChildScrollView(
            child: _Remember(card: card, accent: accent),
          ),
        ),
        _ => content,
      },
    );
  }
}

/// Encadré de synthèse, accompagné de Nova.
class _Remember extends StatelessWidget {
  const _Remember({required this.card, required this.accent});

  final LessonCard card;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MascotMessage(
          message: card.title ?? 'On récapitule !',
          mood: MascotMood.joyeux,
          color: accent,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          background: accent.withValues(alpha: context.isDark ? 0.14 : 0.07),
          borderColor: accent.withValues(alpha: 0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (card.body != null)
                Text(card.body!, style: context.text.bodyLarge),
              if (card.formula != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                FormulaBlock(formula: card.formula!, accent: accent),
              ],
              for (final String bullet in card.bullets)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.check_rounded, size: 18, color: accent),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(bullet, style: context.text.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
