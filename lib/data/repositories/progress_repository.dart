/// Persistance de la progression.
library;

import 'dart:convert';

import '../../domain/models/progress.dart';
import '../local/key_value_store.dart';

/// Lit et écrit la progression dans le magasin local.
///
/// En cas de données illisibles (format changé, écriture interrompue), on
/// repart d'une progression vide plutôt que de bloquer l'application : perdre
/// un historique est désagréable, ne plus pouvoir ouvrir l'application l'est
/// beaucoup plus.
class ProgressRepository {
  const ProgressRepository(this._store);

  /// Clé de stockage. Le suffixe de version permet une future migration sans
  /// écraser les données de l'ancien format.
  static const String storageKey = 'eureka.progress.v1';

  final KeyValueStore _store;

  /// Charge la progression enregistrée.
  ProgressState load() {
    final String? raw = _store.read(storageKey);
    if (raw == null || raw.isEmpty) return const ProgressState();
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return const ProgressState();
      return ProgressState.fromJson(decoded.cast<String, Object?>());
    } on FormatException {
      return const ProgressState();
    }
  }

  /// Enregistre la progression.
  Future<void> save(ProgressState state) =>
      _store.write(storageKey, jsonEncode(state.toJson()));

  /// Efface toute la progression.
  Future<void> clear() => _store.delete(storageKey);
}
