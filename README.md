# Eurêka

> Apprendre les sciences en s'amusant, du primaire à l'université.
> **Gratuit, sans publicité, sans compte, hors-ligne.**

Application mobile Flutter (iOS et Android, téléphone et tablette) couvrant
les **mathématiques**, la **physique-chimie**, l'**informatique** et la **SVT**,
pour quatre niveaux : primaire, collège, lycée, université.

---

## Ce que contient ce dépôt aujourd'hui

| Brique | État |
|---|---|
| Application Flutter iOS + Android, téléphone et tablette | ✅ |
| Design system complet (couleurs, typographie, composants, thème sombre) | ✅ |
| Navigation, onboarding, accueil, catalogue, profil, réglages | ✅ |
| Moteur de leçon : cartes d'apprentissage + figures interactives | ✅ |
| Moteur de quiz : **7 types d'exercices**, correction expliquée | ✅ |
| Gamification locale : XP, rangs, séries, étoiles de maîtrise | ✅ |
| Catalogue des **85 chapitres** annoncés sur 4 matières × 4 niveaux | ✅ |
| Contenu rédigé de bout en bout | **1 chapitre** (Pythagore, 4 leçons, 19 questions) |
| 75 tests (domaine, contenu, parcours d'interface) | ✅ |
| Icône d'application, générée en code (`tool/generate_icons.py`) | ✅ |
| Pipeline de publication TestFlight sans Mac | ✅ |

Le chapitre **« Le théorème de Pythagore »** (maths, collège) est le modèle de
référence : il est entièrement jouable et exerce les sept types d'exercices.
Les 84 autres chapitres sont annoncés au catalogue avec le statut « bientôt »,
afin que l'élève voie tout de suite l'étendue du programme. Écrire un nouveau
chapitre ne demande pas de toucher au code Dart : voir
[docs/CONTENT_AUTHORING.md](docs/CONTENT_AUTHORING.md).

## Les quatre promesses du produit

1. **Gratuit pour toujours.** Aucune publicité, aucun achat intégré, aucune
   limite de vies ou d'énergie. L'interface ne réserve aucun emplacement à de
   la monétisation future.
2. **Hors-ligne.** Tout le contenu est embarqué dans l'application. Aucune
   requête réseau n'est nécessaire, nulle part.
3. **Aucune donnée collectée.** Pas de compte, pas d'e-mail, pas de mesure
   d'audience. La progression vit sur l'appareil et nulle part ailleurs — ce
   qui rend l'application utilisable par un enfant sans démarche de
   consentement.
4. **Une seule application, tous les niveaux.** Un élève de CE1 et un étudiant
   de licence ouvrent la même application ; c'est le niveau choisi qui change
   ce qui est mis en avant, jamais ce qui est accessible.

## Tester sur un vrai téléphone

Le dépôt contient un workflow GitHub Actions qui construit l'IPA signé et
l'envoie sur **TestFlight depuis un runner macOS** : posséder un Mac n'est pas
nécessaire, seul le compte Apple Developer l'est.

Mise en place (une heure, une seule fois) puis un clic par build :
[docs/TESTFLIGHT.md](docs/TESTFLIGHT.md).

## Démarrer

```bash
flutter pub get
flutter run              # appareil ou émulateur connecté
flutter test             # 75 tests
flutter analyze          # analyse statique stricte
```

Flutter 3.47 ou plus récent (Dart 3.13+).

## Structure

```
lib/
  app/           amorçage, thème appliqué, routes, providers Riverpod
  core/          jetons de design, mise en page adaptative, préférences
  design_system/ composants réutilisables, mascotte, figures interactives
  domain/        modèles et règles métier — Dart pur, sans Flutter
  data/          chargement du contenu, stockage local, dépôts
  features/      un dossier par écran
assets/
  content/       le contenu pédagogique, en JSON
  fonts/         Nunito et Baloo 2 (variables, embarquées)
test/
  domain/        moteurs XP, séries, maîtrise, quiz
  data/          validation du contenu réellement embarqué
  widget/        parcours complet, de l'onboarding à la correction
```

Trois dépendances seulement : `flutter_riverpod`, `go_router`,
`shared_preferences`. Les animations, les confettis, la mascotte et les figures
scientifiques sont dessinés à la main — aucun fichier image, aucune Lottie.

Détails : [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) ·
[docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) ·
[docs/ROADMAP.md](docs/ROADMAP.md)

## Captures du parcours

Le parcours type, tel qu'il est couvert par les tests :

1. **Onboarding** — trois écrans : bienvenue, niveau scolaire, objectif
   quotidien (le prénom est facultatif).
2. **Accueil** — anneau de l'objectif du jour, série, bouton « Reprendre »
   vers la prochaine leçon, grille des matières.
3. **Chapitre** — parcours en serpentin, étoiles de maîtrise, objectifs.
4. **Leçon** — une carte par écran, avec figures manipulables au doigt.
5. **Quiz** — réponse, puis **retour expliqué systématique**, y compris quand
   la réponse est juste. Une erreur donne un second essai avant la solution.
6. **Bilan** — XP animés, confettis en cas de sans-faute, avancement du
   chapitre.

## Licence

À définir par le propriétaire du dépôt avant publication sur les stores.
