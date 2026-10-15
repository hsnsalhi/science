/// Lecture stricte des cartes JSON du contenu pédagogique.
library;

/// Accès typé et strict aux champs d'un objet JSON.
///
/// Le contenu d'Eurêka est écrit à la main dans des fichiers JSON. Une faute
/// de frappe dans un nom de champ doit produire une erreur claire, nommant le
/// champ fautif, et non un `null` qui se propage jusqu'à un écran vide. Tous
/// les accesseurs obligatoires lèvent donc une [FormatException] explicite.
extension JsonRead on Map<String, Object?> {
  /// Chaîne non vide obligatoire.
  String str(String key, {String? context}) {
    final Object? value = this[key];
    if (value is! String || value.isEmpty) {
      throw FormatException(
        '${context ?? 'Objet'} : champ "$key" manquant ou vide.',
      );
    }
    return value;
  }

  /// Chaîne optionnelle ; une chaîne vide est traitée comme absente.
  String? strOrNull(String key) {
    final Object? value = this[key];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  /// Nombre obligatoire (entier ou décimal).
  double number(String key, {String? context}) {
    final Object? value = this[key];
    if (value is num) return value.toDouble();
    throw FormatException(
      '${context ?? 'Objet'} : champ numérique "$key" manquant.',
    );
  }

  /// Nombre optionnel, avec valeur de repli.
  double numberOr(String key, double fallback) {
    final Object? value = this[key];
    return value is num ? value.toDouble() : fallback;
  }

  /// Entier obligatoire.
  int integer(String key, {String? context}) =>
      number(key, context: context).round();

  /// Entier optionnel, avec valeur de repli.
  int integerOr(String key, int fallback) =>
      numberOr(key, fallback.toDouble()).round();

  /// Booléen optionnel, avec valeur de repli.
  bool boolOr(String key, bool fallback) {
    final Object? value = this[key];
    return value is bool ? value : fallback;
  }

  /// Liste de chaînes ; liste vide si le champ est absent.
  List<String> strings(String key, {String? context}) {
    final Object? value = this[key];
    if (value == null) return const <String>[];
    if (value is! List) {
      throw FormatException(
        '${context ?? 'Objet'} : champ "$key" devrait être une liste.',
      );
    }
    return value
        .map((Object? e) {
          if (e is! String) {
            throw FormatException(
              '${context ?? 'Objet'} : "$key" contient une valeur non textuelle.',
            );
          }
          return e;
        })
        .toList(growable: false);
  }

  /// Liste d'objets JSON ; liste vide si le champ est absent.
  List<Map<String, Object?>> objects(String key, {String? context}) {
    final Object? value = this[key];
    if (value == null) return const <Map<String, Object?>>[];
    if (value is! List) {
      throw FormatException(
        '${context ?? 'Objet'} : champ "$key" devrait être une liste.',
      );
    }
    return value
        .map((Object? e) {
          if (e is! Map) {
            throw FormatException(
              '${context ?? 'Objet'} : "$key" contient un élément non objet.',
            );
          }
          return e.cast<String, Object?>();
        })
        .toList(growable: false);
  }
}
