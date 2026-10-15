/// Câblage Riverpod de l'application.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/content/content_catalog.dart';
import '../data/local/key_value_store.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/models/app_settings.dart';
import '../domain/models/education_level.dart';
import '../domain/models/progress.dart';
import '../domain/services/progress_engine.dart';
import '../domain/services/streak_engine.dart';

/// Horloge de l'application.
///
/// Toute lecture de « maintenant » passe par ce fournisseur, jamais par
/// `DateTime.now()` directement. C'est ce qui rend les séries de jours
/// testables : un test remplace l'horloge et fait défiler les jours.
final Provider<DateTime Function()> clockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

/// Magasin local. **Remplacé au démarrage** par `main.dart`.
final Provider<KeyValueStore> keyValueStoreProvider = Provider<KeyValueStore>(
  (Ref ref) => throw StateError(
    'keyValueStoreProvider doit être remplacé au démarrage '
    '(voir main.dart).',
  ),
);

/// Contenu pédagogique. **Remplacé au démarrage** par `main.dart`.
final Provider<ContentCatalog> contentCatalogProvider =
    Provider<ContentCatalog>(
      (Ref ref) => throw StateError(
        'contentCatalogProvider doit être remplacé au démarrage '
        '(voir main.dart).',
      ),
    );

final Provider<ProgressRepository> progressRepositoryProvider =
    Provider<ProgressRepository>(
      (Ref ref) => ProgressRepository(ref.watch(keyValueStoreProvider)),
    );

final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
      (Ref ref) => SettingsRepository(ref.watch(keyValueStoreProvider)),
    );

// ---------------------------------------------------------------- Progression

/// État de progression de l'élève et ses mutations.
///
/// L'écriture disque est déclenchée après chaque mutation mais n'est jamais
/// attendue par l'interface : l'état en mémoire est la source d'affichage, le
/// disque n'est qu'une sauvegarde. Une leçon terminée s'affiche donc
/// instantanément, même sur un appareil lent.
class ProgressController extends Notifier<ProgressState> {
  @override
  ProgressState build() => ref.read(progressRepositoryProvider).load();

  /// Enregistre une leçon terminée et renvoie le nouvel état.
  ProgressState completeLesson(LessonOutcome outcome) {
    final DateTime now = ref.read(clockProvider)();
    state = ProgressEngine.applyOutcome(state, outcome, now: now);
    _persist();
    return state;
  }

  /// Termine l'onboarding.
  void completeOnboarding({
    required EducationLevel level,
    required int dailyGoalXp,
    String? firstName,
  }) {
    state = state.copyWith(
      profile: state.profile.copyWith(
        level: level,
        dailyGoalXp: dailyGoalXp,
        firstName: firstName,
        clearFirstName: firstName == null || firstName.isEmpty,
        onboarded: true,
      ),
    );
    _persist();
  }

  /// Change le niveau scolaire mis en avant.
  void setLevel(EducationLevel level) {
    if (state.profile.level == level) return;
    state = state.copyWith(profile: state.profile.copyWith(level: level));
    _persist();
  }

  /// Change l'objectif quotidien.
  void setDailyGoal(int xp) {
    state = state.copyWith(profile: state.profile.copyWith(dailyGoalXp: xp));
    _persist();
  }

  /// Change le prénom affiché.
  void setFirstName(String? firstName) {
    final String? value = (firstName == null || firstName.trim().isEmpty)
        ? null
        : firstName.trim();
    state = state.copyWith(
      profile: state.profile.copyWith(
        firstName: value,
        clearFirstName: value == null,
      ),
    );
    _persist();
  }

  /// Efface toute la progression, en gardant le profil (niveau, objectif).
  ///
  /// Garder le profil est délibéré : « recommencer à zéro » veut dire effacer
  /// les scores, pas se faire redemander sa classe.
  void resetProgress() {
    state = ProgressState(profile: state.profile);
    _persist();
  }

  /// Efface tout, profil compris : l'application redémarre à l'onboarding.
  void resetEverything() {
    state = const ProgressState();
    _persist();
  }

  void _persist() {
    // L'échec d'écriture ne doit pas remonter jusqu'à l'élève : au pire, la
    // progression de la session en cours n'est pas conservée.
    unawaited(ref.read(progressRepositoryProvider).save(state));
  }
}

final NotifierProvider<ProgressController, ProgressState> progressProvider =
    NotifierProvider<ProgressController, ProgressState>(ProgressController.new);

/// Série de jours en cours, recalculée à chaque changement de progression.
final Provider<StreakInfo> streakProvider = Provider<StreakInfo>((Ref ref) {
  final ProgressState progress = ref.watch(progressProvider);
  return StreakEngine.compute(
    dailyXp: progress.dailyXp,
    dailyGoalXp: progress.profile.dailyGoalXp,
    today: ref.watch(clockProvider)(),
  );
});

/// XP gagnés aujourd'hui.
final Provider<int> todayXpProvider = Provider<int>((Ref ref) {
  final ProgressState progress = ref.watch(progressProvider);
  return progress.xpOn(dayKeyOf(ref.watch(clockProvider)()));
});

// ------------------------------------------------------------------ Réglages

/// Réglages de confort et leurs mutations.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsRepositoryProvider).load();

  void setTheme(ThemePreference theme) => _update(state.copyWith(theme: theme));

  void setReduceMotion(bool value) =>
      _update(state.copyWith(reduceMotion: value));

  void setHaptics(bool value) => _update(state.copyWith(haptics: value));

  void setTextScale(double value) => _update(
    state.copyWith(
      textScale: value.clamp(
        AppSettings.minTextScale,
        AppSettings.maxTextScale,
      ),
    ),
  );

  void _update(AppSettings next) {
    state = next;
    unawaited(ref.read(settingsRepositoryProvider).save(next));
  }
}

final NotifierProvider<SettingsController, AppSettings> settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
