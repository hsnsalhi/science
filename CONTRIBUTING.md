# Contribuer à Eurêka

Deux façons d'aider, et la première ne demande aucune connaissance en
programmation.

## Écrire du contenu

C'est le besoin principal : 85 chapitres sont annoncés, sept sont écrits.
Le guide complet est dans [docs/CONTENT_AUTHORING.md](docs/CONTENT_AUTHORING.md).
En résumé : on ajoute une entrée dans `assets/content/catalog.json`, on écrit
un fichier JSON de leçons, et on lance

```bash
flutter test test/data/content_test.dart
```

qui signale toute coquille en nommant le champ fautif.

## Contribuer au code

```bash
flutter pub get
flutter analyze    # doit rester sans aucun avertissement
flutter test       # doit rester vert
```

Quelques règles qui comptent plus que les autres :

- **Les valeurs d'apparence viennent du thème.** Une couleur, un espacement ou
  une durée écrits en dur dans un écran sont à remplacer par le jeton
  correspondant (`docs/DESIGN_SYSTEM.md`).
- **`domain/` ne dépend pas de Flutter.** Les règles métier doivent rester
  testables en pur Dart.
- **Toute animation respecte `context.reduceMotion`** et n'empêche jamais le
  contenu de s'afficher.
- **Aucune requête réseau, aucune collecte.** Une contribution qui introduit
  l'une ou l'autre change la nature du produit et doit être discutée d'abord.
- **Une nouvelle dépendance se justifie.** Le projet en compte trois ; chaque
  ajout est une charge de maintenance pour une application destinée à rester
  gratuite longtemps.

## Style

Le projet suit `flutter_lints` avec quelques règles supplémentaires
(`analysis_options.yaml`) : types de retour explicites, guillemets simples,
virgules finales, `const` partout où c'est possible. `dart format .` avant de
proposer un changement.

Les commentaires et la documentation sont en français, comme l'application.
On commente le **pourquoi** d'une décision, pas ce que le code fait déjà
lisiblement.
