/// Lecture d'une leçon en fil vertical : un plan par geste du pouce.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/content/content_catalog.dart';
import '../../design_system/app_button.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_scaffold.dart';
import '../../design_system/figures/autoplay.dart';
import '../../design_system/figures/figure_registry.dart';
import '../../design_system/formula_block.dart';
import '../../design_system/visuals.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/lesson.dart';
import '../../domain/services/lesson_reel.dart';

/// Le cours en fil : on monte au pouce, et chaque plan bouge.
///
/// L'écran précédent présentait une carte par page et un bouton
/// « Suivant ». Les deux défauts se tenaient : le bouton demandait de
/// viser, et la carte portait son corps entier — quatre paragraphes, soit
/// une page de cours. Des élèves comme des professeurs l'ont trouvé aussi
/// ennuyeux que ce qui existe déjà, et ils avaient raison.
///
/// Ici la figure occupe l'écran et se joue toute seule ; le texte passe
/// par-dessus, un paragraphe à la fois, comme un sous-titre ; et on
/// avance d'un glissement vers le haut, sans rien viser. Le découpage ne
/// coûte aucune réécriture : il suit les paragraphes déjà écrits.
class LessonReelScreen extends ConsumerStatefulWidget {
  const LessonReelScreen({
    required this.chapterId,
    required this.lessonId,
    required this.onStartQuiz,
    required this.onFinishWithoutQuiz,
    super.key,
  });

  final String chapterId;
  final String lessonId;
  final void Function(String chapterId, String lessonId) onStartQuiz;
  final VoidCallback onFinishWithoutQuiz;

  @override
  ConsumerState<LessonReelScreen> createState() => _LessonReelScreenState();
}

/// Part de la hauteur revenant à la figure.
///
/// La frontière est fixe, et c'est voulu : un cadre qui se redimensionne
/// selon la longueur de la légende fait sautiller l'image d'un plan à
/// l'autre, ce qui attire l'œil là où il n'y a rien à voir. La légende
/// commence donc toujours à la même ligne, et c'est la figure qui se
/// centre dans ce qui lui revient.
const double _partScene = 0.66;

class _LessonReelScreenState extends ConsumerState<LessonReelScreen>
    with TickerProviderStateMixin {
  final PageController _pages = PageController();

  /// Horloge des figures : un cycle de balayage.
  late final AnimationController _horloge = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  /// Horloge du cadrage : une lente respiration de l'image, bien plus
  /// longue que celle des figures pour qu'on ne la remarque pas.
  late final AnimationController _cadrage = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  );

  int _index = 0;
  bool _demarrageFait = false;
  bool _sortieLancee = false;

  @override
  void dispose() {
    _pages.dispose();
    _horloge.dispose();
    _cadrage.dispose();
    super.dispose();
  }

  /// `reduceMotion` lit `MediaQuery`, donc pas d'`initState` : on démarre
  /// au premier `build`, une seule fois.
  void _demarrer(bool reduceMotion) {
    if (_demarrageFait) return;
    _demarrageFait = true;
    if (reduceMotion) return;
    _horloge.repeat();
    _cadrage.repeat(reverse: true);
  }

  void _terminer(Chapter chapter, Lesson lesson) {
    if (_sortieLancee) return;
    _sortieLancee = true;
    if (lesson.hasQuiz) {
      widget.onStartQuiz(chapter.id, lesson.id);
    } else {
      widget.onFinishWithoutQuiz();
    }
  }

  /// Ouvre la figure à sa taille, avec ses commandes, pour la manipuler.
  ///
  /// Sur la scène la figure est mise à l'échelle pour tenir dans le cadre,
  /// ce qui rapetissit ses curseurs. Les garder utilisables demande un
  /// écran à elle : on la sort donc en panneau, où elle reprend sa taille
  /// de lecture et où le défilement du fil ne lui dispute plus le doigt.
  void _manipuler(String figureId, Color accent) {
    context.tapFeedback();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.5,
          maxChildSize: 0.96,
          expand: false,
          builder: (BuildContext context, ScrollController scroll) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.lg),
                ),
              ),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.tokens.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.touch_app_rounded,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'À toi de la manipuler',
                          style: context.text.labelMedium?.copyWith(
                            color: accent,
                          ),
                        ),
                        const Spacer(),
                        AppIconButton(
                          icon: Icons.close_rounded,
                          tooltip: 'Fermer',
                          filled: false,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      child: AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: FigureRegistry.build(context, figureId, accent),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

    // Un entraînement pur n'a aucune carte : on va droit aux questions.
    if (lesson.cards.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onStartQuiz(chapter.id, lesson.id);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool reduceMotion = context.reduceMotion;
    _demarrer(reduceMotion);

    final SubjectPalette palette = SubjectPalettes.of(chapter.subjectId);
    final List<ReelBeat> beats = LessonReel.of(lesson);
    final ReelBeat courant = beats[_index.clamp(0, beats.length - 1)];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NotificationListener<ScrollNotification>(
        // Tirer vers le haut au-delà du dernier plan enchaîne sur les
        // exercices, sans avoir à viser le bouton : c'est le même geste
        // que pour changer de plan, prolongé.
        onNotification: (ScrollNotification n) {
          if (n is ScrollUpdateNotification &&
              n.metrics.pixels > n.metrics.maxScrollExtent + 72) {
            _terminer(chapter, lesson);
          }
          return false;
        },
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // 1. La scène. Elle est en dehors du PageView, donc la figure
            // n'est pas remontée quand on change de légende : elle
            // continue de jouer d'un plan à l'autre, et ne repart de zéro
            // qu'en changeant de carte.
            _Scene(
              figureId: courant.figureId,
              accent: palette.base,
              horloge: _horloge,
              cadrage: _cadrage,
              pages: _pages,
              reduceMotion: reduceMotion,
            ),

            // 3. Les légendes : un plan par page, fond transparent.
            PageView.builder(
              controller: _pages,
              scrollDirection: Axis.vertical,
              itemCount: beats.length,
              onPageChanged: (int i) {
                context.tapFeedback();
                setState(() => _index = i);
              },
              itemBuilder: (BuildContext context, int i) {
                final ReelBeat beat = beats[i];
                return _Legende(
                  key: ValueKey<String>(beat.id),
                  beat: beat,
                  accent: palette.base,
                  actif: i == _index,
                  reduceMotion: reduceMotion,
                  onTerminer: () => _terminer(chapter, lesson),
                  hasQuiz: lesson.hasQuiz,
                );
              },
            ),

            // 4. L'en-tête : avancement, titre, sortie.
            _Entete(
              titre: lesson.title,
              index: _index,
              total: beats.length,
              accent: palette.base,
              onFermer: () => Navigator.of(context).maybePop(),
            ),

            // 5. L'invitation à manipuler la figure à sa taille.
            if (courant.figureId != null)
              Positioned(
                right: AppSpacing.lg,
                top: MediaQuery.sizeOf(context).height * _partScene - 42,
                child: _PiluleManipuler(
                  accent: palette.base,
                  onPressed: () =>
                      _manipuler(courant.figureId!, palette.base),
                ),
              ),

            // 6. Le geste, montré une fois. Il disparaît dès qu'il a été
            // fait : un tutoriel qui reste est un tutoriel qui a échoué.
            if (_index == 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.paddingOf(context).bottom + 18,
                child: _IndiceGeste(reduceMotion: reduceMotion),
              ),
          ],
        ),
      ),
    );
  }
}

/// La figure à l'affiche, cadrée et animée.
class _Scene extends StatelessWidget {
  const _Scene({
    required this.figureId,
    required this.accent,
    required this.horloge,
    required this.cadrage,
    required this.pages,
    required this.reduceMotion,
  });

  final String? figureId;
  final Color accent;
  final AnimationController horloge;
  final AnimationController cadrage;
  final PageController pages;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (figureId == null) return const SizedBox.shrink();

    // La figure occupe la moitié haute : le bas revient à la légende, et
    // ce partage ne bouge pas d'un plan à l'autre. Un cadre qui se
    // redimensionne selon la longueur du texte donne une image qui
    // sautille, ce qui attire l'œil là où il n'y a rien à voir.
    final double hauteur = MediaQuery.sizeOf(context).height;
    final double haut = MediaQuery.paddingOf(context).top;

    final Widget figure = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: FittedBox(
        fit: BoxFit.contain,
        // Largeur de référence : la figure se dessine comme sur un
        // téléphone, puis l'ensemble est mis à l'échelle du cadre. Cela
        // évite qu'une figure déborde — elle rétrécit — et lui donne la
        // même allure sur toutes les tailles d'écran.
        child: SizedBox(
          width: 360,
          child: FigureRegistry.build(context, figureId!, accent),
        ),
      ),
    );

    final Widget anime = reduceMotion
        ? figure
        : AnimatedBuilder(
            animation: horloge,
            builder: (BuildContext context, Widget? child) {
              return FigureStage(
                phase: horloge.value,
                actif: true,
                child: child!,
              );
            },
            child: figure,
          );

    final Widget cadre = SizedBox(
      height: hauteur * _partScene,
      child: Padding(
        // En haut, la place de l'en-tête ; en bas, celle de la pastille
        // « Manipuler », qui se range sur la frontière.
        padding: EdgeInsets.only(top: haut + 60, bottom: 46),
        // La figure se range en bas de sa part, contre la légende : le
        // dessin et le texte forment alors un seul bloc au centre de
        // l'écran, et le vide se répartit aux deux bords au lieu de
        // s'ouvrir entre les deux.
        child: Align(alignment: Alignment.bottomCenter, child: anime),
      ),
    );

    if (reduceMotion) {
      return Align(alignment: Alignment.topCenter, child: cadre);
    }

    // Respiration lente, et dérive liée au défilement. Les deux donnent la
    // profondeur : l'image vit un peu, et elle ne colle pas au texte quand
    // on glisse.
    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[cadrage, pages]),
        builder: (BuildContext context, Widget? child) {
          final double respire =
              1 + 0.045 * (0.5 - 0.5 * math.cos(math.pi * cadrage.value));
          final double page = pages.hasClients
              ? (pages.page ?? pages.initialPage.toDouble())
              : 0;
          return Transform.translate(
            offset: Offset(0, -(page % 1) * 14),
            child: Transform.scale(scale: respire, child: child),
          );
        },
        child: cadre,
      ),
    );
  }
}

/// Le texte d'un plan, posé dans la moitié basse.
class _Legende extends StatelessWidget {
  const _Legende({
    required this.beat,
    required this.accent,
    required this.actif,
    required this.reduceMotion,
    required this.onTerminer,
    required this.hasQuiz,
    super.key,
  });

  final ReelBeat beat;
  final Color accent;
  final bool actif;
  final bool reduceMotion;
  final VoidCallback onTerminer;
  final bool hasQuiz;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double hauteur = MediaQuery.sizeOf(context).height;

    final Widget corps = switch (beat.kind) {
      BeatKind.ouverture => Text(
        beat.text ?? '',
        style: context.text.headlineMedium?.copyWith(height: 1.15),
      ),
      BeatKind.formule => FormulaBlock(
        formula: beat.formula ?? '',
        accent: accent,
      ),
      BeatKind.point => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 9, right: AppSpacing.md),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              beat.text ?? '',
              style: context.text.titleMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
      BeatKind.sortie => _Sortie(
        message: beat.text ?? '',
        accent: accent,
        hasQuiz: hasQuiz,
        onTerminer: onTerminer,
      ),
      BeatKind.propos => Text(
        beat.text ?? '',
        // Plus gros que le corps d'un cours : à cette taille, un
        // paragraphe se lit sans s'arrêter, et il n'y en a qu'un.
        style: context.text.titleMedium?.copyWith(height: 1.45),
      ),
    };

    final String? etiquette = beat.cardKind == null
        ? null
        : CardVisuals.label(beat.cardKind!);
    final IconData? icone = beat.cardKind == null
        ? null
        : CardVisuals.icon(beat.cardKind!);
    // Le surtitre rappelle de quelle idée on parle, puisque le titre de la
    // carte n'est plein écran qu'au plan d'ouverture.
    final bool montrerSurtitre =
        beat.kind != BeatKind.ouverture && beat.kind != BeatKind.sortie;
    final Color couleurAlerte = switch (beat.cardKind) {
      LessonCardKind.avertissement => tokens.warning,
      LessonCardKind.astuce => tokens.info,
      _ => accent,
    };

    final Widget contenu = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (montrerSurtitre && (etiquette != null || beat.kicker != null))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: <Widget>[
                if (icone != null) ...<Widget>[
                  Icon(icone, size: 15, color: couleurAlerte),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Text(
                    <String>[
                      if (etiquette != null)
                        beat.stepNumber == null
                            ? etiquette
                            : '$etiquette ${beat.stepNumber}',
                      if (beat.kicker != null) beat.kicker!,
                    ].join(' · '),
                    style: context.text.labelMedium?.copyWith(
                      color: couleurAlerte,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        corps,
      ],
    );

    // Une mise en garde doit se reconnaître avant d'être lue : c'est la
    // seule carte dont la couleur porte une information. Le surtitre teinté
    // n'y suffit pas sur un fond chargé, donc la légende prend ici une
    // surface à elle, bordée de la couleur d'alerte.
    final bool encadrer =
        beat.cardKind == LessonCardKind.avertissement ||
        beat.cardKind == LessonCardKind.astuce;
    final Widget cadre = encadrer
        ? Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: couleurAlerte.withValues(
                alpha: context.isDark ? 0.18 : 0.1,
              ),
              border: Border.all(
                color: couleurAlerte.withValues(alpha: 0.45),
              ),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: contenu,
          )
        : contenu;

    // La légende commence juste sous la figure, et non en bas de
    // l'écran : collée en bas, elle laissait un vide au milieu de
    // chaque plan, ce qui faisait paraître la page creuse.
    final Widget place = Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        hauteur * _partScene + AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.paddingOf(context).bottom + 54,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: SingleChildScrollView(child: cadre),
      ),
    );

    if (reduceMotion || !actif) return place;
    // Le texte monte d'un cran en apparaissant : c'est le mouvement qui
    // dit « nouvelle légende » quand deux plans partagent la figure.
    return _MonteeTexte(key: ValueKey<String>(beat.id), child: place);
  }
}

/// Apparition par le bas, une fois, à la prise de vue du plan.
class _MonteeTexte extends StatefulWidget {
  const _MonteeTexte({required this.child, super.key});

  final Widget child;

  @override
  State<_MonteeTexte> createState() => _MonteeTexteState();
}

class _MonteeTexteState extends State<_MonteeTexte>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CurvedAnimation courbe = CurvedAnimation(
      parent: _c,
      curve: AppCurves.enter,
    );
    return AnimatedBuilder(
      animation: courbe,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: courbe.value,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - courbe.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Dernier plan : l'enchaînement vers les exercices.
class _Sortie extends StatelessWidget {
  const _Sortie({
    required this.message,
    required this.accent,
    required this.hasQuiz,
    required this.onTerminer,
  });

  final String message;
  final Color accent;
  final bool hasQuiz;
  final VoidCallback onTerminer;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(message, style: context.text.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        Text(
          hasQuiz
              ? 'Glisse encore vers le haut, ou appuie.'
              : 'Glisse encore vers le haut pour sortir.',
          style: context.text.bodyMedium?.copyWith(
            color: context.tokens.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: hasQuiz ? 'Passer aux exercices' : 'Terminer',
          color: accent,
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: onTerminer,
        ),
      ],
    );
  }
}

/// Avancement en segments, titre, et bouton de sortie.
class _Entete extends StatelessWidget {
  const _Entete({
    required this.titre,
    required this.index,
    required this.total,
    required this.accent,
    required this.onFermer,
  });

  final String titre;
  final int index;
  final int total;
  final Color accent;
  final VoidCallback onFermer;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Positioned(
      top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            label: 'Plan ${index + 1} sur $total',
            child: Row(
              children: <Widget>[
                for (int i = 0; i < total; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == total - 1 ? 0 : 3,
                      ),
                      child: AnimatedContainer(
                        duration: context.motionDuration(AppDurations.fast),
                        height: 3,
                        decoration: BoxDecoration(
                          color: i <= index
                              ? accent
                              : tokens.inkSubtle.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  titre,
                  style: context.text.labelMedium?.copyWith(
                    color: tokens.inkMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Quitter la leçon',
                filled: false,
                onPressed: onFermer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pastille qui ouvre la figure à sa taille.
class _PiluleManipuler extends StatelessWidget {
  const _PiluleManipuler({required this.accent, required this.onPressed});

  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.touch_app_rounded,
                size: 17,
                color: Colors.white,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Manipuler',
                style: context.text.labelMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le geste de défilement, montré au premier plan seulement.
class _IndiceGeste extends StatefulWidget {
  const _IndiceGeste({required this.reduceMotion});

  final bool reduceMotion;

  @override
  State<_IndiceGeste> createState() => _IndiceGesteState();
}

class _IndiceGesteState extends State<_IndiceGeste>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget texte = Column(
      children: <Widget>[
        const Icon(Icons.keyboard_arrow_up_rounded, size: 26),
        Text(
          'Glisse vers le haut',
          style: context.text.labelMedium?.copyWith(
            color: context.tokens.inkMuted,
          ),
        ),
      ],
    );
    if (widget.reduceMotion) return IgnorePointer(child: texte);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? child) {
          final double t = 0.5 - 0.5 * math.cos(2 * math.pi * _c.value);
          return Opacity(
            opacity: 0.45 + 0.55 * t,
            child: Transform.translate(offset: Offset(0, -7 * t), child: child),
          );
        },
        child: texte,
      ),
    );
  }
}
