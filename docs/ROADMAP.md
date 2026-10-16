# Feuille de route

Le socle technique est posé, et quarante-neuf chapitres sont jouables — au
moins un par matière et par niveau. La répartition est désormais la vraie
question : 21 chapitres au collège contre 13 au primaire, 13 au lycée et 2 à
l'université. La suite se joue surtout sur le **contenu**, et sur un petit
nombre de briques techniques qui ne sont utiles qu'une fois le contenu
étoffé.

---

## Court terme — étoffer le contenu

L'ordre proposé suit l'utilité pour un élève, pas la facilité d'écriture.

1. **Le primaire**, remonté à treize chapitres. L'écart avec le collège
   se referme ; il reste à lui donner une progression suivie plutôt
   qu'un chapitre par matière. C'est le niveau où une suite tenue de dix chapitres change le plus
   l'usage, et celui où l'écriture est la plus exigeante : moins de texte,
   plus de manipulation.
2. **Les matières les plus maigres** : la technologie et l'histoire
   des sciences en ont quatre chacune, contre douze aux mathématiques.
3. **L'université**, qui n'a que deux chapitres, tous deux en logique
   et informatique. Les mathématiques, la physique et la biologie du
   supérieur restent entières.

Chaque chapitre écrit doit passer `flutter test test/data/content_test.dart`.

## Moyen terme — briques techniques

| Brique | Pourquoi, et quand |
|---|---|
| **Révision espacée explicite** | Les données sont déjà là (`distinctDays`, justesse par leçon). Un écran « à réviser aujourd'hui » devient utile dès qu'il y a une dizaine de chapitres terminés, pas avant. |
| **Rendu LaTeX** | Les formules Unicode suffisent jusqu'au lycée. Le supérieur (intégrales, matrices, sommes) en aura besoin : à faire en même temps que les premiers chapitres universitaires. |
| **Éditeur de code embarqué** | Pour l'informatique au lycée : exécuter un petit programme Python dans l'application. Techniquement le plus gros morceau restant. |
| **Sons** | Un retour sonore court sur bonne réponse, désactivable. Volontairement repoussé : mal fait, c'est pire que rien. |
| **Plus de figures interactives** | Trente-six existent ; le circuit, la cellule et la parabole sont faits. Restent la balance chimique, le repère orthonormé et une figure de géométrie dans l'espace. Chaque figure sert plusieurs chapitres. |
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
