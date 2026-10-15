# Architecture — Eurêka

> Application mobile gratuite d'apprentissage des sciences (maths, physique-chimie,
> informatique, SVT) du primaire à l'université. Flutter, 100 % hors-ligne.

## 1. Principes directeurs

| Principe | Conséquence concrète |
|---|---|
| **Gratuit, pour toujours** | Aucune publicité, aucun achat intégré, aucun mur de paiement, aucune « vie » limitée. Les écrans ne contiennent aucun emplacement réservé à de la monétisation. |
| **Hors-ligne d'abord** | Tout le contenu pédagogique est embarqué dans l'APK/IPA (`assets/content/**.json`). Aucune requête réseau n'est nécessaire pour utiliser l'application. |
| **Zéro donnée personnelle** | Aucun compte, aucun identifiant, aucune télémétrie. La progression vit uniquement sur l'appareil. L'application est utilisable par un enfant de 7 ans sans consentement parental à collecter. |
| **Un seul code, quatre formats** | iOS + Android, téléphone + tablette, portrait + paysage. La mise en page est pilotée par des points de rupture, jamais par `Platform.isIOS`. |
| **Contenu = donnée, pas code** | Ajouter un chapitre ne demande pas de toucher à Dart : on écrit un fichier JSON. Voir `CONTENT_AUTHORING.md`. |
| **Accessible** | Cibles tactiles ≥ 48 dp, contrastes AA, `Semantics` sur tout élément interactif, respect de la taille de police système, option « animations réduites ». |

## 2. Vue d'ensemble des couches

```
┌──────────────────────────────────────────────────────────┐
│  features/            écrans + contrôleurs d'écran        │
│  (onboarding, home, subject, chapter, lesson, quiz, …)    │
└───────────────┬──────────────────────────────────────────┘
                │ lit/écrit via providers Riverpod
┌───────────────▼──────────────────────────────────────────┐
│  design_system/       widgets réutilisables, sans logique │
│  core/theme           couleurs, typo, espacements, thème  │
└───────────────┬──────────────────────────────────────────┘
                │
┌───────────────▼──────────────────────────────────────────┐
│  domain/              modèles immuables + règles métier   │
│  models/ (Subject, Chapter, Lesson, Question, Progress)   │
│  services/ (XpEngine, StreakEngine, MasteryEngine)        │
└───────────────┬──────────────────────────────────────────┘
                │
┌───────────────▼──────────────────────────────────────────┐
│  data/                                                    │
│  content/      chargement + validation des JSON           │
│  repositories/ ContentRepository, ProgressRepository      │
│  local/        KeyValueStore (abstraction de stockage)    │
└──────────────────────────────────────────────────────────┘
```

**Règle de dépendance** : `features → design_system → domain → data`. Jamais l'inverse.
`domain/` ne connaît ni Flutter ni le stockage ; il est testable en pur Dart.

## 3. Pourquoi ces choix techniques

### Flutter
Rendu identique sur iOS et Android, 60/120 fps sur les animations, et surtout un
moteur de dessin (`CustomPainter`) qui permet de **construire les figures
scientifiques interactives en code** — triangle rectangle manipulable, circuit
électrique, cellule, courbe de fonction — sans dépendre d'images ni de Lottie.
Conséquence : l'application reste légère et chaque figure est nette à toutes les
densités d'écran.

### Riverpod (`flutter_riverpod`)
Injection de dépendances + état réactif sans `BuildContext`, testable sans widget.
Les moteurs de jeu (`XpEngine`…) sont exposés en providers, donc remplaçables en test.

### go_router
Routage déclaratif par URL (`/subject/maths/chapter/pythagore/lesson/2`), ce qui
donne gratuitement : liens profonds, restauration d'état, et navigation cohérente
sur tablette.

### `KeyValueStore` plutôt que `shared_preferences` partout
Une interface de 4 méthodes, implémentée aujourd'hui par `shared_preferences`.
Le jour où un backend de synchronisation est souhaité, on écrit une seconde
implémentation sans toucher au reste de l'application. C'est la seule couture
prévue pour un futur serveur.

### Aucune dépendance d'animation externe
Confettis, mascotte, transitions, compteurs : tout est écrit avec
`AnimationController` + `CustomPainter`. Moins de 3 dépendances au total dans
`pubspec.yaml`, donc une maintenance longue durée réaliste pour un projet gratuit.

## 4. Modèle de contenu

```
Subject  (maths, physique-chimie, informatique, svt)
  └─ Track      = un (Subject × EducationLevel)
       └─ Chapter    (ex. « Le théorème de Pythagore »)
            └─ Lesson    kind: cours | entrainement | defi
                 ├─ List<LessonCard>   les écrans d'apprentissage
                 └─ List<Question>     l'évaluation finale
```

`EducationLevel` : `primaire`, `college`, `lycee`, `universite`.

Types de questions pris en charge (`QuestionKind`) :
`choixUnique`, `choixMultiple`, `vraiFaux`, `saisieNumerique`, `texteATrous`,
`remiseEnOrdre`, `appariement`.

Chaque `LessonCard` a un `kind` (`texte`, `formule`, `exemple`, `astuce`,
`figure`, `etape`) et une `figureId` optionnelle qui pointe vers une figure
interactive enregistrée dans `FigureRegistry`.

## 5. Progression et gamification (toute locale)

| Mécanique | Règle |
|---|---|
| **XP** | Chaque leçon donne `xpReward`. Une réponse juste du premier coup : +10 XP. Après une erreur : +4 XP (on valorise la persévérance, on ne la punit pas). |
| **Rangs** | `Curieux → Explorateur → Apprenti → Chercheur → Savant → Génie`, seuils dans `XpEngine`. |
| **Série (streak)** | Jours consécutifs avec l'objectif quotidien atteint. Un « gel » automatique protège une absence d'un jour : on ne casse pas la motivation d'un enfant pour un week-end. |
| **Maîtrise** | 0 à 3 étoiles par chapitre, calculées sur la justesse et la régularité (`MasteryEngine`). La 3ᵉ étoile demande de revenir plus tard : révision espacée implicite. |
| **Objectif quotidien** | Choisi à l'onboarding (10 / 20 / 40 XP) et modifiable. |

Aucune mécanique ne bloque l'accès au contenu : tout chapitre est **toujours
ouvrable**, même non débloqué. Les verrous visuels sont des suggestions de
parcours, pas des barrières — un élève en retard ou en avance doit pouvoir aller
où il veut.

## 6. Mise en page adaptative

`core/layout/breakpoints.dart` définit trois classes de largeur :

| Classe | Largeur | Comportement |
|---|---|---|
| `compact` | < 600 dp | Téléphone. Une colonne, barre de navigation basse. |
| `medium` | 600–1023 dp | Petite tablette / téléphone paysage. Grilles à 2–3 colonnes. |
| `expanded` | ≥ 1024 dp | Tablette. Volet latéral permanent + contenu, deux panneaux dans le lecteur de leçon. |

Le contenu est systématiquement borné en largeur (`AppScaffold.maxContentWidth`)
pour que les lignes de texte restent lisibles sur une tablette de 12 pouces.

## 7. Tests

- `test/domain/` — moteurs XP, série, maîtrise : pur Dart, rapides, déterministes.
- `test/data/` — validation du chargement JSON : tout fichier de contenu mal formé
  doit faire échouer la suite, pas l'application en production.
- `test/widget/` — composants du design system et parcours de quiz.

## 8. Publication

Voir `docs/RELEASE.md` pour la signature Android, les certificats iOS et les
métadonnées des stores.
