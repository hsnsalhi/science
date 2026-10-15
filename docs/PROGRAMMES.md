# Les programmes officiels suivis par le catalogue

Le catalogue (`assets/content/catalog.json`) n'est pas une liste de sujets
choisis au jugé : chaque chapitre renvoie, par son champ `source`, au texte
réglementaire qui le fixe. Les textes retenus sont ceux **en vigueur en
France à la rentrée 2026-2027**.

Cette page sert à deux choses : savoir sur quoi s'appuie un chapitre quand
on l'écrit, et savoir quand un texte change.

## Pourquoi c'est daté

Les programmes français sont en pleine refonte. Entre 2024 et 2026, les
mathématiques ont été réécrites du CP à la première, et les sciences et
technologie du CP à la sixième. Ces textes entrent en vigueur **par niveau,
sur plusieurs rentrées** : à un instant donné, deux classes d'un même
collège ne suivent pas le même programme.

Le catalogue vise l'état d'arrivée, pas l'état transitoire : il décrit le
programme tel qu'il s'appliquera une fois le calendrier déroulé. Le champ
`note` de chaque source dit où en est ce calendrier.

## Textes retenus

| Clé | Texte | Classes | État |
|---|---|---|---|
| `c2-maths` | Mathématiques, cycle 2 — BO n° 41 du 31 octobre 2024 | CP → CE2 | En vigueur depuis 2025 |
| `c3-maths` | Mathématiques, cycle 3 — BO n° 16 du 17 avril 2025 | CM1 → 6e | Tout le cycle depuis 2026 |
| `c4-maths` | Mathématiques, cycle 4 — BO n° 10 du 5 mars 2026 | 5e → 3e | 5e en 2026, 4e en 2027, 3e en 2028 |
| `c23-sciences` | Sciences et technologie, cycles 2 et 3 — BO n° 24 du 11 juin 2026 | CP → 6e | CP et CM1 en 2026, le reste en 2027 |
| `c4-2020` | Physique-chimie, SVT, technologie, cycle 4 — BO n° 31 du 30 juillet 2020 | 5e → 3e | Toujours en vigueur ; refonte en consultation |
| `2de-maths` | Mathématiques, seconde — BO n° 14 du 2 avril 2026 | 2de | En vigueur depuis 2026 |
| `1re-maths` | Spécialité mathématiques, première — BO n° 14 du 2 avril 2026 | 1re | En vigueur depuis 2026 |
| `tle-maths` | Spécialité mathématiques, terminale — BO spécial n° 8 du 25 juillet 2019 | Tle | Remplacé à la rentrée 2027 |
| `2de-pc` | Physique-chimie, seconde — BO spécial n° 1 du 22 janvier 2019 | 2de | En vigueur |
| `spe-pc` | Spécialité physique-chimie — BO spécial n° 1 (2019) et n° 8 (2019) | 1re, Tle | En vigueur |
| `2de-svt` | SVT, seconde — BO spécial n° 1 du 22 janvier 2019 | 2de | En vigueur |
| `spe-svt` | Spécialité SVT — BO spécial n° 1 (2019) et n° 8 (2019) | 1re, Tle | En vigueur |
| `snt` | Sciences numériques et technologie — BO spécial n° 1 du 22 janvier 2019 | 2de | En vigueur |
| `nsi` | Spécialité NSI — BO spécial n° 1 (2019) et n° 8 (2019) | 1re, Tle | En vigueur |
| `ens-sci` | Enseignement scientifique — BO du 22 juin 2023 et BO spécial n° 8 (2019) | 1re, Tle | En vigueur |
| `licence` | Licences scientifiques | L1 → L3 | Aucun programme national |

## Le cas de l'université

Il n'existe pas de programme national de licence. L'arrêté licence du
30 juillet 2018 fixe un cadre — crédits, compétences, organisation — et
chaque université écrit sa maquette. Les chapitres `universite` reprennent
donc le socle que l'on retrouve d'une maquette à l'autre dans une mention
donnée, et non un texte réglementaire. C'est une approximation assumée, et
le champ `source` le dit.

## Les quatre niveaux de l'application et les classes françaises

L'application range les chapitres en quatre niveaux ; les classes réelles
sont portées par le champ `grades` de chaque chapitre, et affichées sur sa
carte.

- `primaire` : CP, CE1, CE2, CM1, CM2
- `college` : 6e, 5e, 4e, 3e
- `lycee` : 2de, 1re, Tle
- `universite` : L1, L2, L3

La sixième appartient au cycle 3, qu'elle partage avec le CM1 et le CM2 :
quelques chapitres de `college` s'appuient donc sur un texte de cycle 3, et
c'est voulu.

## Quand un texte change

1. Mettre à jour l'entrée dans `sources` de `catalog.json` : référence du
   BO, classes, et note de calendrier.
2. Reprendre les chapitres concernés — titre, résumé, `grades`.
3. Mettre à jour le tableau ci-dessus.

Les textes se récupèrent sur `education.gouv.fr` (le PDF de l'annexe, pas
la page du BO) et sur Éduscol.
