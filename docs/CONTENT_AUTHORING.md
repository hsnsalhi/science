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
| `subject` | `maths`, `physique-chimie`, `informatique` ou `svt`. |
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
| `figure` | Une figure manipulable | `figureId` (obligatoire), `title`, `body` |
| `etape` | Une étape de méthode, numérotée automatiquement | `title`, `body` |
| `aRetenir` | La synthèse de fin | `title`, `body`, `bullets`, `formula` |

Les formules s'écrivent en Unicode : `a² + b² = c²`, `√2`, `×`, `÷`, `π`, `≈`.

### Les sept types de question

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
```

La comparaison des réponses textuelles ignore la casse, les accents, les
espaces, les apostrophes et la notation des exposants : « HYPOTÉNUSE »,
« hypotenuse » et « hypoténuse » sont la même réponse, et `c²` vaut `c2`. Il
reste utile de lister les variantes de fond dans `accepted` (synonymes,
singulier/pluriel).

## 3. Les figures interactives

Une figure se cite par une clé, jamais par un nom de fichier :

| `figureId` | Figure |
|---|---|
| `triangle-sides` | Triangle rectangle manipulable, nomme les côtés |
| `pythagore-carres` | Carrés construits sur les côtés (preuve visuelle) |
| `triangle-reciproque` | Teste si un triangle est rectangle |
| `droite-graduee` | Droite graduée des relatifs : position, opposé, distance à zéro |
| `thales-configuration` | Configuration de Thalès : la parallèle coulisse, les rapports restent égaux |

Ajouter une figure demande cette fois du code : écrire le widget dans
`lib/design_system/figures/`, puis l'inscrire dans `FigureRegistry`. Le reste
du contenu n'a pas à changer.

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
- **Doser les XP** : 20 à 25 pour un cours court, 40 pour un défi long.
