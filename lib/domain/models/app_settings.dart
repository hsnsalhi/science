/// Réglages de confort de l'application.
library;

/// Préférence de thème.
enum ThemePreference {
  systeme('systeme', 'Automatique'),
  clair('clair', 'Clair'),
  sombre('sombre', 'Sombre');

  const ThemePreference(this.id, this.label);

  final String id;
  final String label;

  static ThemePreference parse(String? id) {
    for (final ThemePreference value in values) {
      if (value.id == id) return value;
    }
    return ThemePreference.systeme;
  }
}

/// Réglages de l'application, persistés localement.
class AppSettings {
  const AppSettings({
    this.theme = ThemePreference.systeme,
    this.reduceMotion = false,
    this.haptics = true,
    this.textScale = 1.0,
  });

  final ThemePreference theme;

  /// Supprime les animations décoratives. Le réglage système équivalent est
  /// respecté en plus de celui-ci (voir `AppMotion`).
  final bool reduceMotion;

  /// Autorise les vibrations de retour.
  final bool haptics;

  /// Facteur d'agrandissement du texte, en plus du réglage système.
  ///
  /// Présent parce que l'application s'adresse aussi à des élèves de primaire
  /// qui lisent plus confortablement en grand, sans pour autant que toute leur
  /// tablette soit réglée ainsi.
  final double textScale;

  /// Bornes du facteur d'agrandissement.
  static const double minTextScale = 0.9;
  static const double maxTextScale = 1.4;

  AppSettings copyWith({
    ThemePreference? theme,
    bool? reduceMotion,
    bool? haptics,
    double? textScale,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      haptics: haptics ?? this.haptics,
      textScale: textScale ?? this.textScale,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'theme': theme.id,
    'reduceMotion': reduceMotion,
    'haptics': haptics,
    'textScale': textScale,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    final Object? scale = json['textScale'];
    return AppSettings(
      theme: ThemePreference.parse(json['theme'] as String?),
      reduceMotion: json['reduceMotion'] == true,
      haptics: json['haptics'] != false,
      textScale: scale is num
          ? scale.toDouble().clamp(minTextScale, maxTextScale)
          : 1.0,
    );
  }
}
