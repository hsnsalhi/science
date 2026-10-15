import 'dart:convert';

import 'package:eureka/app/providers.dart';
import 'package:eureka/app/selectors.dart';
import 'package:eureka/data/content/content_catalog.dart';
import 'package:eureka/data/content/content_loader.dart';
import 'package:eureka/data/local/key_value_store.dart';
import 'package:eureka/data/repositories/progress_repository.dart';
import 'package:eureka/domain/models/chapter.dart';
import 'package:eureka/domain/models/education_level.dart';
import 'package:eureka/domain/models/progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ce que désigne « Reprendre » sur l'accueil.
///
/// Tant qu'un seul chapitre était jouable, la question ne se posait pas.
/// Avec plusieurs matières pourvues, parcourir le catalogue dans l'ordre
/// renverrait l'élève vers une autre matière à chaque session, et le rang
/// d'un chapitre — qui n'a de sens qu'au sein de sa matière — déciderait
/// de tout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;

  setUpAll(() async {
    catalog = await ContentLoader().load();
  });

  ProviderContainer conteneur({Map<String, LessonRecord> records = const {}}) {
    final ProgressState etat = ProgressState(
      profile: const LearnerProfile(
        firstName: 'Inès',
        level: EducationLevel.college,
        onboarded: true,
      ),
      lessons: records,
    );
    final InMemoryStore store = InMemoryStore(<String, String>{
      ProgressRepository.storageKey: jsonEncode(etat.toJson()),
    });
    final ProviderContainer container = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        contentCatalogProvider.overrideWithValue(catalog),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('le catalogue range les chapitres par matière, puis par niveau', () {
    final List<Chapter> college = catalog.playableChapters(
      EducationLevel.college,
    );
    expect(college.length, greaterThanOrEqualTo(2));
    final List<String> matieres = <String>[
      for (final Chapter c in college) c.subjectId,
    ];
    final List<int> rangs = <int>[
      for (final String m in matieres)
        catalog.subjects.indexWhere((dynamic s) => s.id == m),
    ];
    final List<int> tries = List<int>.of(rangs)..sort();
    expect(rangs, tries, reason: 'les matières sont mêlées');
  });

  test('sans aucune trace, la première matière du catalogue est proposée', () {
    final NextStep? next = conteneur().read(nextStepProvider);
    expect(next, isNotNull);
    expect(next!.chapter.subjectId, catalog.subjects.first.id);
    expect(next.isReview, isFalse);
  });

  test('un chapitre entamé passe avant un chapitre intact', () {
    // On entame le second chapitre jouable, et on vérifie que c'est lui
    // qui est proposé — pas le premier du catalogue.
    final List<Chapter> jouables = catalog.playableChapters(
      EducationLevel.college,
    );
    final Chapter second = jouables[1];
    final NextStep? next = conteneur(
      records: <String, LessonRecord>{
        '${second.id}/${second.lessons.first.id}': const LessonRecord(
          attempts: 1,
          bestCorrect: 2,
          bestTotal: 4,
        ),
      },
    ).read(nextStepProvider);

    expect(next, isNotNull);
    expect(next!.chapter.id, second.id);
    expect(next.lesson.id, second.lessons[1].id);
  });
}
