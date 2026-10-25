/// Routes de l'application.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/chapter/chapter_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lesson/lesson_reel_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/quiz/quiz_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/subjects/subject_screen.dart';
import '../features/subjects/subjects_screen.dart';
import 'providers.dart';

/// Chemins nommés, pour éviter les chaînes disséminées dans le code.
abstract final class Routes {
  static const String onboarding = '/bienvenue';
  static const String home = '/';
  static const String subjects = '/matieres';
  static const String profile = '/profil';
  static const String settings = '/reglages';

  static String subject(String subjectId) => '/matiere/$subjectId';
  static String chapter(String chapterId) => '/chapitre/$chapterId';
  static String lesson(String chapterId, String lessonId) =>
      '/lecon/$chapterId/$lessonId';
  static String quiz(String chapterId, String lessonId) =>
      '/exercices/$chapterId/$lessonId';
}

/// Routeur de l'application.
///
/// Les trois onglets vivent dans une [StatefulShellRoute] : chacun garde son
/// historique, si bien que revenir sur « Matières » rouvre l'écran où on
/// l'avait laissé. Les écrans de détail (matière, chapitre, leçon, quiz) sont
/// empilés **par-dessus** la coquille : pendant une leçon, la barre de
/// navigation disparaît, ce qui évite de sortir d'un quiz par mégarde.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.home,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final bool onboarded = ref.read(progressProvider).profile.onboarded;
      final bool atOnboarding = state.matchedLocation == Routes.onboarding;
      if (!onboarded && !atOnboarding) return Routes.onboarding;
      if (onboarded && atOnboarding) return Routes.home;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.onboarding,
        builder: (BuildContext context, GoRouterState state) =>
            OnboardingScreen(onFinished: () => context.go(Routes.home)),
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell shell,
            ) {
              return AppShell(
                currentIndex: shell.currentIndex,
                onSelect: (int index) => shell.goBranch(
                  index,
                  // Re-toucher l'onglet courant revient à sa racine.
                  initialLocation: index == shell.currentIndex,
                ),
                child: shell,
              );
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.home,
                builder: (BuildContext context, GoRouterState state) =>
                    HomeScreen(
                      onOpenSubject: (String id) =>
                          context.push(Routes.subject(id)),
                      onOpenLesson: (String chapterId, String lessonId) =>
                          context.push(Routes.lesson(chapterId, lessonId)),
                      onOpenSettings: () => context.push(Routes.settings),
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.subjects,
                builder: (BuildContext context, GoRouterState state) =>
                    SubjectsScreen(
                      onOpenSubject: (String id) =>
                          context.push(Routes.subject(id)),
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.profile,
                builder: (BuildContext context, GoRouterState state) =>
                    ProfileScreen(
                      onOpenSettings: () => context.push(Routes.settings),
                    ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/matiere/:subjectId',
        parentNavigatorKey: rootKey,
        builder: (BuildContext context, GoRouterState state) => SubjectScreen(
          subjectId: state.pathParameters['subjectId']!,
          onOpenChapter: (String chapterId) =>
              context.push(Routes.chapter(chapterId)),
        ),
      ),
      GoRoute(
        path: '/chapitre/:chapterId',
        parentNavigatorKey: rootKey,
        builder: (BuildContext context, GoRouterState state) => ChapterScreen(
          chapterId: state.pathParameters['chapterId']!,
          onOpenLesson: (String chapterId, String lessonId) =>
              context.push(Routes.lesson(chapterId, lessonId)),
        ),
      ),
      GoRoute(
        path: '/lecon/:chapterId/:lessonId',
        parentNavigatorKey: rootKey,
        builder: (BuildContext context, GoRouterState state) => LessonReelScreen(
          chapterId: state.pathParameters['chapterId']!,
          lessonId: state.pathParameters['lessonId']!,
          onStartQuiz: (String chapterId, String lessonId) =>
              context.pushReplacement(Routes.quiz(chapterId, lessonId)),
          onFinishWithoutQuiz: () => context.pop(),
        ),
      ),
      // Le quiz est une route de premier niveau, et non une sous-route de la
      // leçon : une sous-route empilerait la page de leçon sous celle du quiz,
      // ce qui perturbe le remplacement de page au moment de passer de l'une
      // à l'autre.
      GoRoute(
        path: '/exercices/:chapterId/:lessonId',
        parentNavigatorKey: rootKey,
        builder: (BuildContext context, GoRouterState state) => QuizScreen(
          chapterId: state.pathParameters['chapterId']!,
          lessonId: state.pathParameters['lessonId']!,
          onExit: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
          onOpenNextLesson: (String chapterId, String lessonId) =>
              context.pushReplacement(Routes.lesson(chapterId, lessonId)),
        ),
      ),
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: rootKey,
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsScreen(),
      ),
    ],
  );
});
