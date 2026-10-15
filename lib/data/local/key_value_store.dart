/// Abstraction de stockage local.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Stockage clé/valeur persistant.
///
/// C'est **la seule couture prévue pour un futur serveur**. Aujourd'hui tout
/// vit sur l'appareil ; le jour où une synchronisation multi-appareils est
/// souhaitée, il suffit d'écrire une seconde implémentation de cette
/// interface. Aucun écran, aucun dépôt ne connaît `SharedPreferences`.
///
/// Les lectures sont synchrones : l'implémentation est préchargée au démarrage,
/// ce qui évite un écran de chargement à chaque affichage de la progression.
abstract interface class KeyValueStore {
  /// Valeur associée à [key], ou `null`.
  String? read(String key);

  /// Écrit [value] sous [key].
  Future<void> write(String key, String value);

  /// Supprime [key].
  Future<void> delete(String key);

  /// Efface tout le contenu du magasin.
  Future<void> clear();
}

/// Implémentation sur `SharedPreferences`.
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._prefs);

  /// Charge le magasin. À appeler une fois, au démarrage.
  static Future<SharedPreferencesStore> open() async =>
      SharedPreferencesStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> delete(String key) => _prefs.remove(key);

  @override
  Future<void> clear() => _prefs.clear();
}

/// Magasin en mémoire, pour les tests et les aperçus.
class InMemoryStore implements KeyValueStore {
  InMemoryStore([Map<String, String>? initial])
    : _values = <String, String>{...?initial};

  final Map<String, String> _values;

  @override
  String? read(String key) => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> clear() async => _values.clear();
}
