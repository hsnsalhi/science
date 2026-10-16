# Feuille de route

Le socle technique est posé, et cinquante-neuf chapitres sont jouables. Les
huit matières sont représentées aux quatre niveaux : le tableau n'a plus de
case vide.

La question n'est donc plus la couverture, mais la profondeur. Par niveau :
21 chapitres au collège, 15 au primaire, 15 au lycée, 8 à l'université. Par
matière : 14 en mathématiques, 8 en physique-chimie, 7 en SVT, en astronomie
et en logique, 6 en informatique, 5 en technologie et en histoire des
sciences.

La suite se joue surtout sur le **contenu**, et sur un petit nombre de
briques techniques qui ne sont utiles qu'une fois le contenu étoffé.

---

## Court terme — étoffer le contenu

L'ordre proposé suit l'utilité pour un élève, pas la facilité d'écriture.

1. **Des progressions suivies, plutôt qu'un chapitre par case.** Les
   mathématiques au primaire en ont une — multiplication, division,
   fractions, décimaux — et c'est le seul endroit où un élève
   peut enchaîner plusieurs chapitres sans sauter d'un sujet à l'autre.
   Reproduire cela ailleurs vaut mieux qu'ouvrir de nouvelles cases.
2. **Les matières les plus maigres** : la technologie et l'histoire des
   sciences en ont cinq chacune, contre quatorze aux mathématiques.
3. **L'université**, qui n'a que huit chapitres, un par matière. C'est une
   amorce, pas un cursus : chaque chapitre y demande une figure neuve et
   une écriture plus dense.

Chaque chapitre écrit doit passer `flutter test test/data/content_test.dart`.

## Moyen terme — briques techniques

| Brique | Pourquoi, et quand |
|---|---|
| **Révision espacée explicite** | Les données sont déjà là (`distinctDays`, justesse par leçon). Un écran « à réviser aujourd'hui » devient utile dès qu'il y a une dizaine de chapitres terminés, pas avant. |
| **Rendu LaTeX** | Les huit chapitres universitaires ont tenu en Unicode, mais de justesse, et en évitant les intégrales et les matrices écrites en ligne. `typographie_test.dart` dit précisément ce que les polices savent dessiner : la vraie contrainte est là, pas dans le goût. C'est le premier chantier technique quand le supérieur s'étoffera. |
| **Éditeur de code embarqué** | Pour l'informatique au lycée : exécuter un petit programme Python dans l'application. Techniquement le plus gros morceau restant. |
| **Sons** | Un retour sonore court sur bonne réponse, désactivable. Volontairement repoussé : mal fait, c'est pire que rien. |
| **Plus de figures interactives** | Quarante-trois existent, et plusieurs servent déjà trois ou quatre chapitres — la chaîne d'énergie, le code génétique, la machine de Turing. Restent la balance chimique, une figure de géométrie dans l'espace, et un spectre lumineux. Écrire un chapitre autour d'une figure existante coûte deux fois moins cher. |
| **Icône et écran de lancement** | À produire avant toute mise en ligne sur les stores. |

## Long terme — ce qui demande une décision

Ces points touchent aux promesses du produit. Aucun ne doit être traité comme
une évidence technique.

- **Mode classe / enseignant.** Un professeur veut voir où en sont ses élèves.
  Cela suppose un serveur, donc des comptes, donc la collecte de données de
  mineurs — à l'exact opposé de la promesse actuelle. Si c'est souhaité, la
  seule couture prévue est l'interface `KeyValueStore` (voir
  `docs/ARCHITECTURE.md`), et il faudra traiter le consentement parental, une
  politique de confidentialité et l'hébergement.
- **Classements entre élèves.** Mêmes conséquences, et un effet pédagogique
  discutable sur les plus jeunes.
- **Traduction.** L'arabe demanderait un support RTL complet ; l'architecture
  ne s'y oppose pas, mais le volume de contenu double.
- **Licence et publication.** À choisir avant la première mise en ligne, en
  particulier si des contributions extérieures sont attendues.

## Ce qui est volontairement exclu

- Publicités, achats intégrés, abonnement.
- Vies, énergie, ou tout mécanisme limitant l'accès au contenu.
- Télémétrie, y compris « anonyme ».
- Verrouillage de chapitres : les parcours suggèrent un ordre, ils
  n'interdisent rien.
