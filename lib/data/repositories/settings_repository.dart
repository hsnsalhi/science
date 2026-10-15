/// Persistance des réglages.
library;

import 'dart:convert';

import '../../domain/models/app_settings.dart';
import '../local/key_value_store.dart';

/// Lit et écrit les réglages dans le magasin local.
class SettingsRepository {
  const SettingsRepository(this._store);

  static const String storageKey = 'eureka.settings.v1';

  final KeyValueStore _store;

  AppSettings load() {
    final String? raw = _store.read(storageKey);
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return const AppSettings();
      return AppSettings.fromJson(decoded.cast<String, Object?>());
    } on FormatException {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) =>
      _store.write(storageKey, jsonEncode(settings.toJson()));
}
