/// Point d'entrée d'Eurêka.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/theme/app_theme.dart';
import 'data/content/content_catalog.dart';
import 'data/content/content_loader.dart';
import 'data/local/key_value_store.dart';

/// Démarre l'application.
///
/// Deux choses sont chargées avant le premier cadre : le magasin local et
/// tout le contenu pédagogique. Les deux sont rapides (lecture d'assets
/// embarqués) et cela permet ensuite une navigation entièrement synchrone,
/// sans le moindre indicateur de chargement dans l'application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Téléphone comme tablette, portrait comme paysage : la mise en page
  // s'adapte, rien n'est verrouillé.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  final SharedPreferencesStore store = await SharedPreferencesStore.open();

  final ContentCatalog catalog;
  try {
    catalog = await ContentLoader().load();
  } on FormatException catch (error) {
    // Un contenu invalide est un bug de développement, jamais quelque chose
    // qu'un élève doit subir sans explication.
    runApp(_ContentErrorApp(message: error.message));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        contentCatalogProvider.overrideWithValue(catalog),
      ],
      child: const EurekaApp(),
    ),
  );
}

/// Écran affiché si le contenu embarqué est illisible.
class _ContentErrorApp extends StatelessWidget {
  const _ContentErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.bug_report_outlined, size: 48),
                const SizedBox(height: 16),
                const Text('Le contenu de l\'application est illisible.'),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
