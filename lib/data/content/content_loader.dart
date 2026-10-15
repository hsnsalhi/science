/// Chargement du contenu pédagogique depuis les assets.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/models/chapter.dart';
import '../../domain/models/json_read.dart';
import '../../domain/models/lesson.dart';
import '../../domain/models/subject.dart';
import 'content_catalog.dart';

/// Lit `assets/content/` et construit le [ContentCatalog].
///
/// Le chargement est strict : un fichier de contenu mal formé lève une
/// [FormatException] nommant le champ fautif. C'est volontaire — ces erreurs
/// doivent être attrapées par les tests (`test/data/content_test.dart`) avant
/// d'atteindre un élève.
class ContentLoader {
  ContentLoader({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  /// Racine des fichiers de contenu.
  static const String root = 'assets/content';

  /// Fichier d'index.
  static const String catalogPath = '$root/catalog.json';

  final AssetBundle bundle;

  /// Charge le catalogue et le contenu de tous les chapitres disponibles.
  Future<ContentCatalog> load() async {
    final Map<String, Object?> catalog = await _readJson(catalogPath);

    final List<Subject> subjects = catalog
        .objects('subjects', context: 'Catalogue')
        .map(Subject.fromJson)
        .toList(growable: false);
    if (subjects.isEmpty) {
      throw const FormatException('Catalogue : aucune matière déclarée.');
    }

    final Set<String> subjectIds = subjects.map((Subject s) => s.id).toSet();

    final List<Chapter> chapters = <Chapter>[];
    final Set<String> seenIds = <String>{};
    for (final Map<String, Object?> entry in catalog.objects(
      'chapters',
      context: 'Catalogue',
    )) {
      final Chapter chapter = Chapter.fromCatalogJson(entry);
      if (!seenIds.add(chapter.id)) {
        throw FormatException(
          'Catalogue : identifiant de chapitre en double "${chapter.id}".',
        );
      }
      if (!subjectIds.contains(chapter.subjectId)) {
        throw FormatException(
          'Chapitre "${chapter.id}" : matière inconnue '
          '"${chapter.subjectId}".',
        );
      }
      chapters.add(
        chapter.contentPath == null
            ? chapter
            : chapter.withLessons(await _loadLessons(chapter)),
      );
    }

    return ContentCatalog(subjects: subjects, chapters: chapters);
  }

  Future<List<Lesson>> _loadLessons(Chapter chapter) async {
    final Map<String, Object?> json = await _readJson(
      '$root/${chapter.contentPath}',
    );
    return Chapter.lessonsFromJson(json, chapter.id);
  }

  Future<Map<String, Object?>> _readJson(String path) async {
    final String raw;
    try {
      raw = await bundle.loadString(path);
    } on FlutterError {
      throw FormatException('Fichier de contenu introuvable : "$path".');
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException('"$path" : la racine doit être un objet JSON.');
    }
    return decoded.cast<String, Object?>();
  }
}
