# Les polices d'Eurêka

Quatre fichiers, tous embarqués dans l'application : rien n'est téléchargé à
l'exécution. Deux servent à écrire, deux ne servent qu'à compléter les
premières, glyphe par glyphe.

Toutes sont sous **SIL Open Font License 1.1** — le texte est dans `OFL.txt`,
à côté de ce fichier. C'est la licence qui exige que ces mentions voyagent
avec les fichiers.

## Les polices principales

| Fichier | Famille | Rôle | Copyright |
|---|---|---|---|
| `Nunito.ttf` | `Nunito` | Texte courant, titres de carte, formules | Copyright 2014 The Nunito Project Authors |
| `Baloo2.ttf` | `Baloo2` | Titres d'écran et de célébration | Copyright 2019 The Baloo 2 Project Authors |

Les deux sont **variables** : un seul fichier porte tout l'axe de graisse,
piloté par `FontVariation('wght', …)` dans `lib/core/theme/app_typography.dart`.

## Les polices de repli

Ni Nunito ni Baloo 2 ne contiennent l'alphabet grec. Elles n'ont que cinq
signes d'origine grecque, retenus pour leur usage mathématique : π, Δ, Σ, Ω
et µ. Un cours de physique qui ne peut écrire ni λ, ni θ, ni ω n'est pas un
cours de physique — d'où ces deux compléments.

| Fichier | Famille | Apporte | Copyright |
|---|---|---|---|
| `NotoSansGrec.ttf` | `NotoSansGrec` | L'alphabet grec complet, ses variantes (ϑ ϕ ϖ ϱ ϵ) et les exposants et indices `⁺ ⁻ ⁿ ₊ ₋ ₙ` | Copyright 2022 The Noto Project Authors |
| `NotoSansMath.ttf` | `NotoSansMath` | Les opérateurs et flèches `∈ ∉ ⊂ ⊃ ∪ ∩ ∀ ∃ ⇒ ⇔ → ← ↑ ↓ ↔ ∇ ∓ ∝ ⊥ ≡ ≪ ≫ ∧ ∨ ¬ ⌈⌉⌊⌋ ∖ ∅`, et les ensembles de nombres `ℝ ℕ ℤ ℚ ℂ` | Copyright 2022 Google LLC |

Elles ne sont **jamais** la police principale d'un style. Elles sont déclarées
dans `AppTypography.replis` et câblées sur chaque `TextStyle` via
`fontFamilyFallback`, y compris sur les étiquettes que les figures dessinent
elles-mêmes au `TextPainter`. Le moteur ne les consulte que pour un caractère
que la police principale ne sait pas dessiner : le reste du texte garde
exactement l'allure qu'il avait avant leur arrivée, ce que les captures de
référence ont confirmé — aucune n'a bougé le jour où elles ont été ajoutées.

`NotoSansGrec` est variable comme les deux premières, donc le grec suit la
graisse du texte qui l'entoure. `NotoSansMath` ne l'est pas : les opérateurs
s'affichent toujours à la graisse normale, y compris dans un titre en gras.
C'est visible si on le cherche, et sans conséquence sur la lisibilité.

## Comment les sous-ensembles ont été fabriqués

Les fichiers de repli sont des extraits : les polices complètes pèsent 2,0 Mo
et 1,0 Mo, ce qui serait absurde pour quelques dizaines de signes. Les
extraits pèsent 54 Ko et 23 Ko (54 040 et 23 120 octets).

```sh
pip install fonttools brotli

curl -o notosans.ttf \
  'https://raw.githubusercontent.com/google/fonts/main/ofl/notosans/NotoSans%5Bwdth,wght%5D.ttf'
curl -o notosansmath.ttf \
  'https://raw.githubusercontent.com/google/fonts/main/ofl/notosansmath/NotoSansMath-Regular.ttf'

pyftsubset notosans.ttf --output-file=NotoSansGrec.ttf \
  --layout-features='*' --name-IDs='*' --notdef-outline \
  --text='αβγδεζηθικλμνξοπρςστυφχψωΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩϑϕϖϱϵ⁺⁻ⁿ₊₋ₙ'

pyftsubset notosansmath.ttf --output-file=NotoSansMath.ttf \
  --layout-features='*' --name-IDs='*' --notdef-outline \
  --text='∇∓∈∉⊂⊃⊆⊇∪∩∀∃∄⇒⇔→←↑↓↔∝∴⊥≡≪≫⌈⌉⌊⌋∧∨¬ℝℕℤℚℂ∖∅'
```

`--name-IDs='*'` n'est pas un détail : c'est ce qui conserve les mentions de
copyright dans la table `name` du fichier produit, comme la licence l'exige.

Pour ajouter un signe, il faut l'ajouter à la chaîne `--text`, refaire le
sous-ensemble, et vérifier que `test/data/typographie_test.dart` passe encore.
Ce test lit les tables `cmap` des quatre fichiers et confronte chaque
caractère du contenu et des chaînes Dart à ce que l'ensemble sait dessiner.
C'est le seul garde-fou : un caractère absent ne provoque aucune erreur, il
s'affiche en rectangle vide chez l'élève et nulle part ailleurs.
