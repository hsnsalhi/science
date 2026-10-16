# Eurêka

> Apprendre les sciences en s'amusant, du primaire à l'université.
> **Gratuit, sans publicité, sans compte, hors-ligne.**

Application mobile Flutter (iOS et Android, téléphone et tablette) couvrant
huit matières — **mathématiques**, **physique-chimie**, **informatique**,
**SVT**, **technologie**, **astronomie**, **logique et énigmes**, **histoire
des sciences** — pour quatre niveaux : primaire, collège, lycée, université.

---

## Ce que contient ce dépôt aujourd'hui

| Brique | État |
|---|---|
| Application Flutter iOS + Android, téléphone et tablette | ✅ |
| Design system complet (couleurs, typographie, composants, thème sombre) | ✅ |
| Navigation, onboarding, accueil, catalogue, profil, réglages | ✅ |
| Moteur de leçon : cartes d'apprentissage + figures interactives | ✅ |
| Moteur de quiz : **9 types d'exercices**, correction expliquée | ✅ |
| Gamification locale : XP, rangs, séries, étoiles de maîtrise | ✅ |
| Catalogue des **230 chapitres** annoncés sur 8 matières × 4 niveaux | ✅ |
| Contenu rédigé de bout en bout | **67 chapitres** : 268 leçons, 979 cartes, 1 216 questions |
| **51 figures interactives**, dessinées d'après le réel | ✅ |
| 572 tests (domaine, contenu, parcours d'interface) | ✅ |
| Icône d'application, **rendue en 3D** par un moteur maison (`tool/render3d.py`) | ✅ |
| Pipeline de publication TestFlight sans Mac | ✅ |
| Pipeline Android : APK installable, puis Google Play | ✅ |

Les soixante-sept chapitres rédigés couvrent les huit matières et les quatre
niveaux : un élève de CM1 comme un étudiant de licence trouve de quoi jouer.
Les autres chapitres sont annoncés au catalogue avec le statut « bientôt »,
afin que l'élève voie tout de suite l'étendue du programme. Écrire un nouveau
chapitre ne demande pas de toucher au code Dart : voir
[docs/CONTENT_AUTHORING.md](docs/CONTENT_AUTHORING.md).

Les corrigés ne sont pas relus mais **recalculés** par les tests : les
proportions d'un croisement génétique sont rejouées sur la figure qui les
produit, les racines d'un trinôme sont relues dans l'énoncé puis résolues, le
chemin d'un robot est exécuté. Une faute d'arithmétique dans un corrigé fait
échouer la suite avant d'atteindre un élève — c'est ainsi qu'a été trouvée,
entre autres, une erreur de comptage sur la recherche dichotomique.

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

Deux workflows GitHub Actions, indépendants et lançables en parallèle.

**Android** — [docs/ANDROID.md](docs/ANDROID.md). Le plus court chemin :
onglet Actions → *Android* → *Run workflow*, et l'APK est dans les artefacts
huit minutes plus tard. Ni compte, ni clé, ni machine particulière. Une clé
de téléversement, puis un compte Play Console à 25 $ une seule fois, ouvrent
ensuite la piste de test interne. `tool/android_signing.py` fabrique la clé
et `tool/play_upload.py` fait l'envoi — avec la seule bibliothèque standard,
sans action tierce à qui confier le compte de service.

**iOS** — [docs/TESTFLIGHT.md](docs/TESTFLIGHT.md). Le workflow construit
l'IPA signé et l'envoie sur **TestFlight depuis un runner macOS** : posséder
un Mac n'est pas nécessaire, seul le compte Apple Developer l'est. Compter
une heure de mise en place, puis un clic par build. `tool/ios_signing.py`
crée le certificat de distribution depuis Linux, **vérifie la cohérence
certificat / profil / clé d'API avant le premier build**, et produit les
valeurs des secrets GitHub.

Plusieurs applications sur le même compte Apple ? Six des sept secrets se
partagent — voir [docs/SECRETS.md](docs/SECRETS.md).

## Démarrer

```bash
flutter pub get
flutter run              # appareil ou émulateur connecté
flutter test             # 572 tests
flutter analyze          # analyse statique stricte
```

Flutter 3.47 ou plus récent (Dart 3.13+).

## Site public

`site/` contient les quatre pages statiques publiées sous
`techlyb.com/eureka/` : présentation, assistance, et la politique de
confidentialité en français et en anglais — Apple exige ces deux dernières
URL pour toute mise en ligne. Déploiement et champs à compléter :
[site/README.md](site/README.md).

## Structure

```
lib/
  app/           amorçage, thème appliqué, routes, providers Riverpod
  core/          jetons de design, mise en page adaptative, préférences
  design_system/ composants réutilisables, mascotte, figures interactives
  domain/        modèles et règles métier — Dart pur, sans Flutter
  data/          chargement du contenu, stockage local, dépôts
  features/      un dossier par écran
site/          les pages publiques (confidentialité, assistance)
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
