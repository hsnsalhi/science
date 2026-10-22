# Écrire du contenu pour Eurêka

> Ce guide s'adresse à une personne qui rédige des chapitres — professeur,
> étudiant, bénévole. **Aucune connaissance de Dart n'est nécessaire.**

Tout le contenu vit dans `assets/content/` au format JSON. Pour ajouter un
chapitre, il faut modifier un fichier d'index et créer un fichier de contenu.

---

## 1. Déclarer le chapitre au catalogue

Dans `assets/content/catalog.json`, section `chapters` :

```json
{
  "id": "maths-college-les-fractions",
  "subject": "maths",
  "level": "college",
  "title": "Les fractions",
  "summary": "Comparer, additionner et simplifier des fractions.",
  "order": 1,
  "status": "disponible",
  "content": "chapters/maths-college-fractions.json",
  "objectives": [
    "Comparer deux fractions",
    "Additionner des fractions de dénominateurs différents"
  ]
}
```

| Champ | Rôle |
|---|---|
| `id` | Identifiant unique, **jamais modifié** ensuite : la progression des élèves y est attachée. Convention : `matière-niveau-titre`. |
| `subject` | `maths`, `physique-chimie`, `informatique`, `svt`, `technologie`, `astronomie`, `logique` ou `histoire-sciences`. |
| `level` | `primaire`, `college`, `lycee` ou `universite`. |
| `order` | Place dans la progression de la matière pour ce niveau. |
| `status` | `bientot` (annoncé) ou `disponible` (jouable). |
| `content` | Chemin du fichier de leçons, obligatoire si `disponible`. |
| `objectives` | Facultatif, affiché avant de commencer. |

## 2. Écrire les leçons

Dans `assets/content/chapters/<nom>.json` :

```json
{
  "chapter": "maths-college-les-fractions",
  "lessons": [
    {
      "id": "comparer",
      "title": "Comparer deux fractions",
      "subtitle": "Savoir laquelle est la plus grande, sans calculatrice.",
      "kind": "cours",
      "xp": 25,
      "minutes": 6,
      "cards": [ … ],
      "questions": [ … ]
    }
  ]
}
```

Le champ `chapter` doit reprendre exactement l'`id` du catalogue : c'est un
garde-fou contre les copier-coller.

`kind` vaut `cours` (découverte), `entrainement` (répétition) ou `defi`
(problèmes). Un bon chapitre enchaîne les trois.

### Les cartes d'apprentissage

Une carte = un écran = **une seule idée**. C'est la contrainte qui rend le
cours lisible sur un téléphone.

| `kind` | À utiliser pour | Champs |
|---|---|---|
| `texte` | Une explication | `title`, `body` |
| `formule` | Une formule mise en valeur | `formula` (obligatoire), `title`, `body` |
| `exemple` | Un exemple résolu | `title`, `body` |
| `astuce` | Un piège fréquent | `body` |
| `avertissement` | Une mise en garde de sécurité | `body` |
| `figure` | Une figure manipulable | `figureId` (obligatoire), `title`, `body` |
| `etape` | Une étape de méthode, numérotée automatiquement | `title`, `body` |
| `aRetenir` | La synthèse de fin | `title`, `body`, `bullets`, `formula` |

Les formules s'écrivent en Unicode : `a² + b² = c²`, `√2`, `×`, `÷`, `π`, `≈`.

**Le jeu de caractères s'est élargi, il n'est pas infini.** Un caractère
qu'aucune police embarquée ne dessine apparaît comme un rectangle vide —
sans la moindre erreur, chez l'élève et nulle part ailleurs.

Sont désormais disponibles, grâce à deux polices de repli décrites dans
`assets/fonts/README.md` :

- tout l'alphabet grec, majuscules et minuscules : `λ`, `θ`, `ω`, `ρ`, `α`,
  `Δ`, `Σ`, `Ω`, et les variantes `ϑ ϕ ϖ ϱ ϵ` ;
- les opérateurs et les flèches : `∈ ∉ ⊂ ⊃ ∪ ∩ ∀ ∃ ⇒ ⇔ → ← ↑ ↓ ↔ ∇ ∝ ⊥ ≡
  ∧ ∨ ¬ ⌈⌉⌊⌋` ;
- les exposants et indices en lettre ou en signe : `xⁿ`, `Mg²⁺`, `Cl⁻`,
  `MgCl₂`.

Restent absents : les coches (`✓`, `✗`), les symboles décoratifs et
l'essentiel des blocs Unicode au-delà des mathématiques courantes.

Deux habitudes valent mieux qu'une liste à retenir. D'abord, le symbole
s'écrit quand c'est le symbole qu'il faut apprendre à lire — `λ = v / f`
plutôt que « lambda égale v sur f » — et le mot quand c'est le mot qu'on
emploie en français, comme « une particule alpha » ou « la sonde lambda ».
Ensuite, devant un signe inhabituel, on lance
`flutter test test/data/typographie_test.dart` : il lit les tables de
caractères des quatre polices et refuse tout contenu qui ne s'afficherait
pas. Mieux vaut le lancer avant d'écrire une formule que découvrir des
carrés sur une capture d'écran.

### Les neuf types de question

Chaque question exige `id`, `kind`, `prompt` et **`explanation`**. Les champs
facultatifs `hint` (indice sans pénalité) et `figureId` s'ajoutent partout.

> **L'explication est le champ le plus important du fichier.** Elle s'affiche
> même quand l'élève a juste. Une application qui se contente de dire « faux »
> n'apprend rien.

```json
// 1. choixUnique — exactement une bonne réponse
{"id":"q1","kind":"choixUnique","prompt":"…","explanation":"…",
 "options":[{"text":"Juste","correct":true},{"text":"Faux"}],"shuffle":true}

// 2. choixMultiple — au moins une bonne réponse, toutes exigées
{"id":"q2","kind":"choixMultiple","prompt":"…","explanation":"…",
 "options":[{"text":"A","correct":true},{"text":"B","correct":true},{"text":"C"}]}

// 3. vraiFaux
{"id":"q3","kind":"vraiFaux","prompt":"…","answer":false,"explanation":"…"}

// 4. saisieNumerique — tolérance pour accepter un arrondi
{"id":"q4","kind":"saisieNumerique","prompt":"…","explanation":"…",
 "answer":1.41,"tolerance":0.02,"unit":"cm"}

// 5. texteATrous — autant de "___" que d'entrées dans "blanks"
{"id":"q5","kind":"texteATrous","prompt":"…","explanation":"…",
 "template":"Le carré de l'___ vaut ___.",
 "blanks":[{"accepted":["hypoténuse"]},{"accepted":["225"]}]}

// 6. remiseEnOrdre — "items" dans le BON ordre, mélangé à l'affichage
{"id":"q6","kind":"remiseEnOrdre","prompt":"…","explanation":"…",
 "items":["D'abord","Ensuite","Enfin"]}

// 7. appariement — colonne de droite mélangée à l'affichage
{"id":"q7","kind":"appariement","prompt":"…","explanation":"…",
 "pairs":[{"left":"Angle droit","right":"90°"},{"left":"Plat","right":"180°"}]}

// 8. tri — éléments à ranger dans des catégories, au glisser-déposer
//    "category" est l'indice dans "categories" ; aucune ne peut rester vide
{"id":"q8","kind":"tri","prompt":"…","explanation":"…",
 "categories":["Rocheuses","Géantes"],
 "items":[{"text":"Mars","category":0},{"text":"Jupiter","category":1}]}

// 9. estimation — ordre de grandeur visé au curseur
//    "logarithmic" n'agit que sur la course du curseur, pas sur la correction
{"id":"q9","kind":"estimation","prompt":"…","explanation":"…",
 "min":100,"max":20000,"answer":4495,"tolerance":1500,
 "unit":"millions de km","logarithmic":true}
```

Le `tri` refuse d'emblée une catégorie sans élément ou un indice hors
limites : ces fautes ne se verraient qu'en jouant. L'`estimation` refuse
une réponse hors de la course du curseur et une échelle logarithmique
partant de zéro.

Une `estimation` n'est pas une `saisieNumerique` déguisée : elle demande un
jugement, pas un calcul. Sa tolérance doit être large — viser la bonne
dizaine de minutes, le bon millier de kilomètres. Un exercice d'estimation
qui exige le dixième près devient une loterie.

La comparaison des réponses textuelles ignore la casse, les accents, les
espaces, les apostrophes et la notation des exposants : « HYPOTÉNUSE »,
« hypotenuse » et « hypoténuse » sont la même réponse, et `c²` vaut `c2`. Il
reste utile de lister les variantes de fond dans `accepted` (synonymes,
singulier/pluriel).

## 3. Les figures interactives

### La règle qui passe avant les autres : montrer, puis seulement dire

Trois niveaux, du moins bon au meilleur. On monte aussi haut que la notion
le permet, et on ne s'arrête au niveau inférieur que faute de mieux :

1. **Un paragraphe.** Le dernier recours. Une notion qu'on ne sait pas
   dessiner est une notion qu'on n'a pas encore comprise assez pour
   l'enseigner.
2. **Un dessin.** Mieux : l'élève voit la chose au lieu de la reconstruire
   dans sa tête.
3. **Une animation.** Mieux encore : il voit la chose *changer*, et un
   changement porte la cause.
4. **Une animation qu'il pilote.** Le but. Il pose la question, l'appareil
   répond, et la règle est ce qui reste quand il a fini de jouer.

L'exemple qui a fixé cette règle, et qui est en place dans
`gravitation-et-systeme-solaire` : pour la pesanteur, un objet pendu à un
fil et un curseur de masse. Le fil s'allonge, la flèche du poids grandit, la
jauge rougit, puis le fil casse et l'objet tombe — d'une chute accélérée, pas
linéaire. Aucune phrase sur « P = m × g » n'apprend cela ; après, la formule
ne fait que nommer ce que l'élève vient de mesurer. La figure est
`fil-qui-casse`, le chapitre ouvre dessus, et la formule arrive en deuxième
carte.

Conséquences pratiques :

- **Chaque leçon ouvre sur une figure.** Pas une carte de texte qui prépare
  la figure : la figure, d'abord, avec une consigne d'action dans son `body`
  (« Pousse le curseur », « Écarte les deux corps »). L'élève manipule avant
  de lire.
- **Le texte devient une légende.** Ce qui restait de l'ancien paragraphe
  tient en deux phrases après la figure, pour nommer ce qui vient d'être vu.
- **Une figure sans commande est un brouillon.** Les 69 figures du registre
  offrent toutes au moins un curseur, un choix ou une zone à manipuler, et
  `test/data/figures_density_test.dart` refuse qu'on en ajoute une qui n'en
  ait pas.
- **Aucune leçon jouable n'est sans figure.** La garantie porte sur la
  leçon et non sur le chapitre : un chapitre peut très bien ouvrir sur une
  belle figure et enchaîner trois leçons de texte. C'est exactement ce qui
  était arrivé, et le test le rend désormais impossible.
- **La part de cartes `figure` ne redescend pas.** Le même fichier de test
  tient un plancher, qu'on relève à chaque lot repris. Un chapitre ajouté
  sans figure fait tomber la moyenne, et le test le dit avant la revue.
- **Un chapitre porte au moins cinq cartes `figure`, pas quatre.** Une
  leçon qui ouvre sur un dessin et enchaîne quatre cartes de texte pèse
  20 % de figures, en dessous du plancher actuel. Écrire quatre leçons
  sur ce modèle fait donc reculer la moyenne du corpus à chaque chapitre,
  et le test refuse le lot — ce qui est arrivé deux fois.

  Le rattrapage consiste à placer une seconde figure au milieu d'une
  leçon, là où une autre vue montre ce que la première ne peut pas :
  le noyau qui grossit d'une fusion à l'autre, le rectangle découpé
  qu'al-Khwarizmi utilisait comme démonstration, l'orbite comme chute
  qui dure. Autant le prévoir en écrivant plutôt qu'en réparant : une
  seconde figure choisie pour sa nécessité vaut mieux qu'une seconde
  figure choisie pour un quota.

Une figure se cite par une clé, jamais par un nom de fichier :

La liste complète fait foi dans
`lib/design_system/figures/figure_registry.dart` — il y en a 69
aujourd'hui, et la recopier ici la rendrait fausse dès la figure suivante.
Pour la relire en une commande :

```bash
grep -oE "^\s+'[a-z0-9-]+':" lib/design_system/figures/figure_registry.dart
```

Ajouter une figure demande cette fois du code : écrire le widget dans
`lib/design_system/figures/`, puis l'inscrire dans `FigureRegistry`. Le reste
du contenu n'a pas à changer. Une `figureId` inconnue fait échouer
`test/data/content_test.dart`, qui compare le contenu au registre réel :
aucune faute de frappe n'atteint un élève.

### La règle : ce qui existe doit y ressembler

Quand une figure représente une chose réelle, elle s'en approche. Une Lune
est grise et criblée, pas un rond ; un cœur est un cône émoussé qui pointe en
bas à gauche, pas le symbole des cartes à jouer ; un poumon a un bord
irrégulier, pas un ovale. Le ciel de la Lune est noir en plein jour, et c'est
une information qu'aucune phrase ne fait passer aussi bien que l'image.

Ce n'est pas de la décoration. L'ombrage d'une sphère **est** le contenu
quand on parle de phases ; le dégradé du limbe est ce qui dit qu'un astre est
une boule et non un disque ; le grain alvéolaire d'un poumon est l'argument
du chapitre sur la surface d'échange. Un schéma plat demande à l'élève de
faire ce travail dans sa tête, et la plupart ne le font pas.

`lib/design_system/figures/realism.dart` fournit l'outillage commun :
sphères éclairées, terminateur jour-nuit, cratères, bandes nuageuses,
calottes, couronne solaire, cônes d'ombre, parois organiques. Tout y est
déterministe — jamais de `Random()` sans graine — pour que les captures de
référence restent stables.

Trois réserves, qui valent règles :

- **L'abstrait reste abstrait.** Un rectangle qui illustre `k(a + b)` est
  déjà la chose elle-même ; lui ajouter une texture ne l'approcherait de
  rien. La règle vise ce qui existe dans le monde, pas les objets
  mathématiques.
- **Dire ce qu'on ne peut pas montrer.** Aucune figure ne peut tenir
  l'échelle du Système solaire. La figure des éclipses l'écrit donc en
  toutes lettres sous le dessin, plutôt que de laisser croire que la Lune
  est à trois diamètres terrestres.
- **La géométrie se vérifie.** `test/domain/realisme_test.dart` mesure la
  surface d'ombre réellement peinte et la compare à la fraction éclairée
  théorique d'une sphère, à seize phases. Un croissant au bord intérieur
  droit décrit un disque découpé et non une boule ; personne ne le
  remarquerait à l'œil, le test si.

Pour mettre une figure au point sans naviguer dans l'application :

```bash
flutter test tool/figure_preview/preview.dart --update-goldens
```

Les images sortent dans `tool/figure_preview/out/`, qui n'est pas versionné.

## 4. Vérifier son travail

```bash
flutter test test/data/content_test.dart
```

La suite échoue — en nommant le champ fautif — si :

- un champ obligatoire manque ou est vide ;
- deux chapitres, deux leçons ou deux questions partagent un identifiant ;
- un `choixUnique` n'a pas exactement une bonne réponse ;
- le nombre de `___` ne correspond pas au nombre de `blanks` ;
- une `figureId` ne correspond à aucune figure ;
- une explication fait moins de vingt caractères ;
- un chapitre `disponible` n'a pas de fichier de contenu.

C'est volontairement strict : une coquille doit arrêter la suite de tests,
jamais atteindre un élève.

## 5. Conseils de rédaction

- **Tutoyer** l'élève, sans infantiliser. Le même texte est lu en CM2 et en
  licence selon le chapitre ; c'est le vocabulaire du niveau qui change, pas
  le ton.
- **Une idée par carte.** Si une carte demande de défiler, la couper en deux.
- **Expliquer le pourquoi, pas seulement le comment.** La carte « figure »
  existe pour cela : montrer que la règle fonctionne, avant de l'énoncer.
- **Nommer les pièges** dans une carte `astuce` : l'erreur fréquente anticipée
  vaut mieux que l'erreur corrigée.
- **Réserver `avertissement` à ce qui peut blesser** — l'électricité du
  secteur, un produit chimique, une source de chaleur. Elle est ambre et
  porte un triangle, là où l'astuce est bleue : un enfant doit voir la
  différence avant d'avoir lu.
- **Préférer une figure existante.** Écrire un chapitre autour d'une figure
  déjà faite coûte environ deux fois moins cher qu'en inventer une, et la
  figure y gagne : celle du code génétique sert à trois chapitres, de la
  seconde à la licence.
- **Doser les XP** : 20 à 25 pour un cours court, 40 pour un défi long.
