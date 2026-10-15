/// Racine de l'application.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_theme.dart';
import '../domain/models/app_settings.dart';
import 'providers.dart';
import 'router.dart';

/// Application Eurêka.
class EurekaApp extends ConsumerWidget {
  const EurekaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final GoRouter router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Eurêka',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (settings.theme) {
        ThemePreference.systeme => ThemeMode.system,
        ThemePreference.clair => ThemeMode.light,
        ThemePreference.sombre => ThemeMode.dark,
      },
      // L'application est francophone ; les libellés Material (boutons de
      // dialogue, sélecteurs) doivent l'être aussi.
      locale: const Locale('fr'),
      supportedLocales: const <Locale>[Locale('fr')],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData media = MediaQuery.of(context);
        return AppMotion(
          reduceMotionPreference: settings.reduceMotion,
          hapticsEnabled: settings.haptics,
          child: MediaQuery(
            // Le réglage de l'application se combine à celui du système au
            // lieu de l'écraser : un élève qui a déjà grossi le texte de son
            // téléphone garde son confort.
            data: media.copyWith(
              textScaler: media.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.6,
              ),
            ),
            child: _TextScale(factor: settings.textScale, child: child!),
          ),
        );
      },
    );
  }
}

/// Applique le facteur d'agrandissement choisi dans les réglages.
class _TextScale extends StatelessWidget {
  const _TextScale({required this.factor, required this.child});

  final double factor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (factor == 1.0) return child;
    final MediaQueryData media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: _ScaledTextScaler(media.textScaler, factor),
      ),
      child: child,
    );
  }
}

/// Multiplie une échelle de texte existante par un facteur fixe.
class _ScaledTextScaler extends TextScaler {
  const _ScaledTextScaler(this._base, this._factor);

  final TextScaler _base;
  final double _factor;

  @override
  double scale(double fontSize) => _base.scale(fontSize) * _factor;

  // `textScaleFactor` est abandonné par Flutter au profit de `scale`, mais
  // reste exigé par le contrat de la classe : on le dérive de `scale`.
  @Deprecated('Utiliser scale(). Conservé pour satisfaire TextScaler.')
  @override
  double get textScaleFactor => scale(14) / 14;
}
