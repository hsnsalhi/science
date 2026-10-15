/// Première ouverture de l'application.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../design_system/animations.dart';
import '../../design_system/app_button.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_scaffold.dart';
import '../../design_system/mascot.dart';
import '../../design_system/visuals.dart';
import '../../domain/models/education_level.dart';

/// Accueil des nouveaux élèves, en trois écrans.
///
/// Trois questions, pas une de plus, et aucune n'est obligatoire au sens
/// juridique : pas de compte, pas d'e-mail, pas d'âge. Le prénom sert
/// uniquement à écrire « Bonjour Inès » sur l'accueil et ne quitte jamais
/// l'appareil.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({required this.onFinished, super.key});

  /// Appelé une fois l'onboarding validé.
  final VoidCallback onFinished;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  final TextEditingController _name = TextEditingController();

  int _step = 0;
  EducationLevel? _level;
  int _goal = 20;

  /// Objectifs proposés, en XP par jour.
  static const List<(int, String, String)> _goals = <(int, String, String)>[
    (10, 'Tranquille', 'environ 5 minutes par jour'),
    (20, 'Régulier', 'environ 10 minutes par jour'),
    (40, 'Motivé', 'environ 20 minutes par jour'),
  ];

  static const int _lastStep = 2;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _canContinue => _step != 1 || _level != null;

  void _next() {
    if (_step < _lastStep) {
      _pages.nextPage(duration: AppDurations.base, curve: AppCurves.move);
      return;
    }
    ref
        .read(progressProvider.notifier)
        .completeOnboarding(
          level: _level ?? EducationLevel.college,
          dailyGoalXp: _goal,
          firstName: _name.text.trim(),
        );
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      padBody: false,
      maxContentWidth: 560,
      body: Column(
        children: <Widget>[
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (int index) => setState(() => _step = index),
              children: <Widget>[
                const _WelcomePage(),
                _LevelPage(
                  selected: _level,
                  onSelected: (EducationLevel level) =>
                      setState(() => _level = level),
                ),
                _GoalPage(
                  goals: _goals,
                  selected: _goal,
                  nameController: _name,
                  onSelected: (int goal) => setState(() => _goal = goal),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              children: <Widget>[
                _Dots(count: _lastStep + 1, active: _step),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: _step == _lastStep ? 'C\'est parti !' : 'Continuer',
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: _canContinue ? _next : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const PopIn(child: Mascot(size: 150, mood: MascotMood.joyeux)),
          const SizedBox(height: AppSpacing.xxl),
          SlideFadeIn(
            delay: const Duration(milliseconds: 120),
            child: Text(
              'Bienvenue dans Eurêka',
              style: context.text.displaySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SlideFadeIn(
            delay: const Duration(milliseconds: 220),
            child: Text(
              'Les maths, la physique-chimie, l\'informatique et la SVT, '
              'du primaire à l\'université. En jouant, en manipulant, '
              'à ton rythme.',
              style: context.text.bodyLarge?.copyWith(
                color: context.tokens.inkMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SlideFadeIn(
            delay: Duration(milliseconds: 320),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                _Promise(icon: Icons.favorite_rounded, label: 'Gratuit'),
                _Promise(icon: Icons.wifi_off_rounded, label: 'Hors-ligne'),
                _Promise(icon: Icons.block_rounded, label: 'Sans publicité'),
                _Promise(icon: Icons.lock_rounded, label: 'Sans compte'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Promise extends StatelessWidget {
  const _Promise({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: context.colors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: context.text.labelMedium),
        ],
      ),
    );
  }
}

class _LevelPage extends StatelessWidget {
  const _LevelPage({required this.selected, required this.onSelected});

  final EducationLevel? selected;
  final ValueChanged<EducationLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      children: <Widget>[
        Text('Où en es-tu ?', style: context.text.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'On mettra ce niveau en avant. Tu pourras en changer quand tu veux, '
          'et explorer les autres à tout moment.',
          style: context.text.bodyMedium?.copyWith(
            color: context.tokens.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final EducationLevel level in EducationLevel.ordered)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _LevelOption(
              level: level,
              selected: selected == level,
              onTap: () => onSelected(level),
            ),
          ),
      ],
    );
  }
}

class _LevelOption extends StatelessWidget {
  const _LevelOption({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final EducationLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = LevelVisuals.color(level);
    return AppCard(
      onTap: onTap,
      borderColor: selected ? color : null,
      background: selected
          ? color.withValues(alpha: context.isDark ? 0.16 : 0.08)
          : null,
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(LevelVisuals.icon(level), color: color),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Wrap plutôt que Row : « 2ᵈᵉ → Terminale » passe à la
                // ligne sur un petit écran au lieu de déborder.
                Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(level.label, style: context.text.titleMedium),
                    Text(
                      level.grades,
                      style: context.text.labelSmall?.copyWith(
                        color: context.tokens.inkSubtle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  level.description,
                  style: context.text.bodySmall?.copyWith(
                    color: context.tokens.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? color : context.tokens.inkSubtle,
          ),
        ],
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  const _GoalPage({
    required this.goals,
    required this.selected,
    required this.onSelected,
    required this.nameController,
  });

  final List<(int, String, String)> goals;
  final int selected;
  final ValueChanged<int> onSelected;
  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      children: <Widget>[
        Text('Ton objectif du jour', style: context.text.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Un petit objectif tenu vaut mieux qu\'un grand abandonné.',
          style: context.text.bodyMedium?.copyWith(
            color: context.tokens.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final (int xp, String title, String subtitle) in goals)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              onTap: () => onSelected(xp),
              borderColor: selected == xp ? context.colors.primary : null,
              background: selected == xp ? context.tokens.brandSoft : null,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(title, style: context.text.titleMedium),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '$xp XP · $subtitle',
                          style: context.text.bodySmall?.copyWith(
                            color: context.tokens.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected == xp
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected == xp
                        ? context.colors.primary
                        : context.tokens.inkSubtle,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text('Comment t\'appelles-tu ?', style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Facultatif. Ce prénom reste sur ton appareil.',
          style: context.text.bodySmall?.copyWith(
            color: context.tokens.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: 'Ton prénom',
            counterText: '',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppDurations.fast,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active
                  ? context.colors.primary
                  : context.tokens.border,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
      ],
    );
  }
}
