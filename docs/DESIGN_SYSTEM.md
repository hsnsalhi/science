# Design system — Eurêka

Tout ce qui relève de l'apparence est décidé à un seul endroit, puis réutilisé.
Un écran qui code en dur une couleur, un espacement ou une durée est un bug.

---

## 1. Intentions

| Intention | Traduction visuelle |
|---|---|
| Une application pour un enfant de 7 ans **et** un étudiant de 20 ans | Formes arrondies et couleurs franches, mais aucune illustration enfantine ni ton condescendant. La mascotte est un atome, pas un animal. |
| Chaque matière doit être reconnaissable avant d'être lue | Une couleur et une icône par matière, appliquées partout : tuile, anneau de progression, boutons, figures. |
| Le toucher doit être gratifiant | Les boutons ont un relief de 4 px et s'enfoncent sous le doigt ; les cartes s'écrasent de 2 %. |
| Se tromper ne doit pas punir | Les états d'erreur utilisent un rouge doux, une vibration brève et une mascotte rassurante — jamais déçue. |
| Lisible dans toutes les conditions | Contrastes AA, cibles tactiles ≥ 44 dp, interlignes à 1,5, thème sombre complet. |

## 2. Couleurs

`lib/core/theme/app_colors.dart`

**Marque** — bleu-violet `#4C6FFF` (actions), or `#FFB020` (XP, récompenses).

**Matières**

| Matière | Couleur | Pourquoi |
|---|---|---|
| Mathématiques | indigo `#5B5BD6` | abstraction, rigueur |
| Physique-chimie | orange `#F2762E` | énergie, chaleur, réaction |
| Informatique | turquoise `#0E9C9C` | signal, écran |
| SVT | vert `#2FA85A` | le vivant |

**Niveaux** — primaire `#F2709C`, collège `#3FA9F5`, lycée `#8B5CF6`,
université `#D9A325`.

**Sémantique** — succès `#16A96A`, erreur `#E5484D`, alerte `#F5A524`,
information `#0EA5E9`.

Les couleurs ne sont jamais employées directement par un écran : elles
alimentent `ThemeData` et `AppTokens`, une `ThemeExtension` qui transporte ce
que Material ne prévoit pas (le vert de « bonne réponse », l'or de l'XP, les
ombres). Un composant écrit `context.tokens.success` et bascule en thème
sombre sans une seule condition.

## 3. Typographie

`lib/core/theme/app_typography.dart`

- **Baloo 2** pour les titres : arrondie, chaleureuse, donne le ton « jeu ».
- **Nunito** pour le texte : très lisible en petit corps, formes ouvertes.
- **Deux polices de repli**, consultées glyphe par glyphe pour ce que les
  deux premières ne dessinent pas : l’alphabet grec et les opérateurs
  mathématiques. Elles ne sont jamais la police principale d’un style, et
  leur arrivée n’a modifié aucune capture de référence. Détail et licences
  dans `assets/fonts/README.md`.

Les deux sont des polices **variables** embarquées dans l'application : un
seul fichier couvre toutes les graisses, et rien n'est téléchargé à
l'exécution. Flutter n'applique pas toujours `fontWeight` à l'axe `wght` d'une
police variable, donc chaque style déclare aussi une `FontVariation` — c'est
la raison d'être du constructeur privé `_style`.

Échelle : `display` (40/32/28) → `headline` (25/22/19) → `title` (19/16/14) →
`body` (17/15/13) → `label` (16/13/11). Les styles de corps ont une hauteur de
ligne de 1,5 : un énoncé d'exercice tient rarement sur une ligne.

## 4. Espacements, rayons, durées

`lib/core/theme/app_spacing.dart`

- Espacements sur une base de 4 : `xxs 2 · xs 4 · sm 8 · md 12 · lg 16 ·
  xl 24 · xxl 32 · xxxl 48`.
- Rayons : `xs 8 · sm 12 · md 16 · lg 22 · xl 28 · pill`.
- Durées : `instant 120 ms` (appui) · `fast 180 ms` (changement d'état) ·
  `base 280 ms` (transition) · `slow 450 ms` (barre de progression) ·
  `celebration 1200 ms`.

Les durées sont courtes volontairement : une interface destinée à un enfant
doit répondre immédiatement. L'animation souligne l'action, elle ne la fait
pas attendre.

## 5. Composants

| Composant | Fichier | Particularité |
|---|---|---|
| `AppButton` | `app_button.dart` | Relief de 4 px, enfoncement au toucher, 5 variantes, 3 tailles |
| `AppCard` | `app_card.dart` | Surface unique de l'application, cliquable ou non |
| `AppNotice` | `app_card.dart` | Encadré teinté : astuce, rappel, mise en garde |
| `AppScaffold` | `app_scaffold.dart` | Marge adaptative, largeur de contenu bornée, barre basse |
| `AnswerTile` | `answer_tile.dart` | 5 états, chacun signalé par **couleur + icône** |
| `LessonPath` | `lesson_path.dart` | Parcours en serpentin dessiné au pinceau |
| `ProgressRing` / `AppProgressBar` / `StepProgress` / `StarRow` | `progress_indicators.dart` | Tous animés et annotés pour les lecteurs d'écran |
| `Mascot` | `mascot.dart` | Nova, atome à visage, 5 expressions, 100 % vectorielle |
| `ConfettiOverlay` | `confetti.dart` | Célébration écrite à la main, sans dépendance |
| `TileGrid` | `tile_grid.dart` | Grille à hauteur libre, insensible à l'agrandissement du texte |
| `FormulaBlock` | `formula_block.dart` | Formule centrée, défilante si longue, chiffres tabulaires |

### Pourquoi aucune dépendance d'animation

Confettis, mascotte, figures scientifiques, serpentin : tout est écrit avec
`AnimationController` et `CustomPainter`. Le dépôt ne contient aucune image ni
fichier Lottie. Conséquences concrètes : l'application reste légère, les
figures sont nettes à toutes les densités d'écran, la mascotte peut prendre la
couleur de la matière en cours, et le projet n'hérite pas d'une dépendance à
maintenir pour quatre secondes d'animation.

## 6. L'icône de l'application

L'icône est **calculée en 3D**, pas dessinée : `tool/render3d.py` est un
petit moteur de lancer de rayon sur surfaces implicites (sphères, tores),
avec éclairage de studio, ombres portées douces, occlusion ambiante et
réflexion spéculaire. `tool/icon_concepts.py` décrit les scènes,
`tool/generate_icons.py` produit tous les fichiers.

```bash
python3 tool/generate_icons.py --list              # concepts disponibles
python3 tool/generate_icons.py --concept orbite    # en changer
```

Pourquoi un moteur plutôt qu'une image : l'occlusion entre les anneaux et le
noyau est réelle — une orbite passe devant, l'autre derrière, et chacune
porte son ombre. Un dégradé plat ne peut qu'imiter cela, et cela se voit.
Changer d'angle, de couleur ou de concept ne coûte ensuite qu'une ligne, et
toutes les tailles restent rigoureusement cohérentes.

Trois contraintes ont décidé du dessin :

| Contrainte | Conséquence |
|---|---|
| Lisible à **20 px** (Réglages, Spotlight) | Deux masses seulement — un noyau, deux anneaux. Les traits fins et le troisième anneau ont été écartés après comparaison à taille réelle. |
| Contraste fort avec le fond | Fond indigo soutenu plutôt que pastel : un sujet clair sur fond pâle devient une tache grise une fois réduit. |
| Marge généreuse | Le sujet occupe environ 72 % du cadre ; le masque du système rogne les bords. |

Toutes les tailles dérivent d'un **même rendu de 1024 px** réduit au filtre
de Lanczos, avec un léger renforcement en dessous de 72 px. Rendre chaque
taille séparément produirait des icônes subtilement différentes, ce qui se
remarque quand le système les affiche côte à côte.

Sur Android, l'icône adaptative reçoit ses deux calques : le sujet détouré
en avant, le dégradé en arrière — et non un aplat de couleur.

## 7. Mise en page adaptative

`lib/core/layout/breakpoints.dart`

| Classe | Largeur | Comportement |
|---|---|---|
| `compact` | < 600 dp | Téléphone : une colonne, barre de navigation basse |
| `medium` | 600–1023 dp | Téléphone paysage, petite tablette : grilles à 3 colonnes |
| `expanded` | ≥ 1024 dp | Tablette : rail de navigation latéral avec intitulés |

L'application ne demande jamais « est-ce un iPad ? » mais « de combien de
largeur je dispose ? ». Le contenu est systématiquement borné en largeur
(`AppScaffold.maxContentWidth`), sans quoi une tablette de 12 pouces
afficherait des lignes de texte de 1 000 px, illisibles.

Les grilles de tuiles utilisent `TileGrid` plutôt qu'une `GridView` à
`childAspectRatio` : un rapport fixe suppose qu'on connaît la hauteur du texte
à l'avance, ce qui devient faux dès qu'un intitulé passe sur deux lignes ou
qu'un utilisateur agrandit la police.

## 8. Accessibilité

- Cibles tactiles d'au moins 44 dp ; options de quiz à 60 dp.
- Tout élément interactif porte un `Semantics` explicite ; les barres et
  anneaux de progression annoncent leur valeur.
- Juste/faux se distingue par la **couleur et l'icône**, jamais par la couleur
  seule.
- Le réglage système « réduire les animations » est respecté sans que
  l'utilisateur ait à le répéter, et un réglage propre à l'application s'y
  ajoute (`AppMotion`).
- Un facteur d'agrandissement du texte propre à l'application se **combine**
  au réglage système au lieu de l'écraser.
- Les vibrations sont désactivables.

### Le piège à ne jamais reproduire

Quand les animations sont réduites, un composant animé doit afficher son
contenu **immédiatement**, et non le laisser invisible. Toutes les briques de
`animations.dart` renvoient l'enfant tel quel dans ce cas. De même, une boucle
d'animation infinie (mascotte, pulsation) doit être **réellement arrêtée** :
sinon elle consomme de la batterie et empêche tout test d'interface de se
stabiliser.
