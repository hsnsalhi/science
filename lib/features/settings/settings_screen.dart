/// Réglages et informations sur l'application.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../design_system/app_button.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_scaffold.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/education_level.dart';
import '../../domain/models/progress.dart';
import '../subjects/level_selector.dart';

/// Écran de réglages.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Objectifs quotidiens proposés, en XP.
  static const List<int> goals = <int>[10, 20, 40, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final ProgressState progress = ref.watch(progressProvider);
    final SettingsController controller = ref.read(settingsProvider.notifier);
    final ProgressController progressController = ref.read(
      progressProvider.notifier,
    );

    return AppScaffold(
      showBack: true,
      title: 'Réglages',
      maxContentWidth: 640,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionHeader(
            title: 'Apprentissage',
            padding: EdgeInsets.only(bottom: AppSpacing.md),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Niveau mis en avant', style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.md),
                LevelSelector(
                  selected: progress.profile.level,
                  onSelected: progressController.setLevel,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Objectif quotidien', style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final int goal in goals)
                      ChoiceChip(
                        label: Text('$goal XP'),
                        selected: progress.profile.dailyGoalXp == goal,
                        onSelected: (_) =>
                            progressController.setDailyGoal(goal),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Prénom affiché', style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                _NameField(
                  initial: progress.profile.firstName,
                  onChanged: progressController.setFirstName,
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Confort'),
          AppCard(
            child: Column(
              children: <Widget>[
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Réduire les animations'),
                  subtitle: const Text(
                    'Supprime les effets décoratifs. Le réglage de ton '
                    'téléphone est déjà respecté automatiquement.',
                  ),
                  value: settings.reduceMotion,
                  onChanged: controller.setReduceMotion,
                ),
                const Divider(),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vibrations'),
                  subtitle: const Text('Retour au toucher et aux réponses.'),
                  value: settings.haptics,
                  onChanged: controller.setHaptics,
                ),
                const Divider(),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Défis chronométrés'),
                  subtitle: const Text(
                    'Un compte à rebours sur les défis, pour un bonus. '
                    'Désactivé, le bonus reste acquis.',
                  ),
                  value: settings.timedChallenges,
                  onChanged: controller.setTimedChallenges,
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Taille du texte', style: context.text.titleSmall),
                      Slider(
                        value: settings.textScale,
                        min: AppSettings.minTextScale,
                        max: AppSettings.maxTextScale,
                        divisions: 5,
                        label: '×${settings.textScale.toStringAsFixed(2)}',
                        onChanged: controller.setTextScale,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Apparence'),
          AppCard(
            child: RadioGroup<ThemePreference>(
              groupValue: settings.theme,
              onChanged: (ThemePreference? value) {
                if (value != null) controller.setTheme(value);
              },
              child: Column(
                children: <Widget>[
                  for (final ThemePreference theme in ThemePreference.values)
                    RadioListTile<ThemePreference>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(theme.label),
                      value: theme,
                    ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Mes données'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Tout ce que tu fais dans Eurêka reste sur cet appareil : '
                  'aucun compte, aucun serveur, aucune publicité, aucune '
                  'mesure d\'audience. Désinstaller l\'application efface '
                  'donc définitivement ta progression.',
                  style: context.text.bodySmall?.copyWith(
                    color: context.tokens.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Réinitialiser ma progression',
                  variant: AppButtonVariant.danger,
                  size: AppButtonSize.medium,
                  icon: Icons.restart_alt_rounded,
                  onPressed: () => _confirmReset(context, progressController),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'À propos'),
          const _AboutCard(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    ProgressController controller,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Tout recommencer ?'),
        content: const Text(
          'Tes XP, tes séries et tes étoiles seront effacés. '
          'Ton niveau et ton objectif seront conservés. '
          'Cette action est définitive.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      controller.resetProgress();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progression réinitialisée.')),
        );
      }
    }
  }
}

class _NameField extends StatefulWidget {
  const _NameField({required this.initial, required this.onChanged});

  final String? initial;
  final ValueChanged<String?> onChanged;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLength: 20,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        hintText: 'Ton prénom (facultatif)',
        counterText: '',
        prefixIcon: Icon(Icons.person_outline_rounded),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Eurêka', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Apprendre les sciences en s\'amusant, du primaire à '
            'l\'université. Gratuit, hors-ligne, pour toujours.',
            style: context.text.bodySmall?.copyWith(
              color: context.tokens.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              _Fact(icon: Icons.favorite_rounded, label: '0 € — toujours'),
              _Fact(icon: Icons.block_rounded, label: '0 publicité'),
              _Fact(icon: Icons.cloud_off_rounded, label: '0 donnée envoyée'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Niveaux couverts : '
            '${EducationLevel.ordered.map((EducationLevel l) => l.label).join(' · ')}',
            style: context.text.labelSmall?.copyWith(
              color: context.tokens.inkSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

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
          Icon(icon, size: 15, color: context.tokens.success),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: context.text.labelSmall),
        ],
      ),
    );
  }
}
