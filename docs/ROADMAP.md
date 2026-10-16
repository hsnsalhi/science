# Feuille de route

Le socle technique est posé, et dix-sept chapitres sont jouables — au moins un
par matière et par niveau. La suite se joue surtout sur le **contenu**, et sur
un petit nombre de briques techniques qui ne sont utiles qu'une fois le contenu
étoffé.

---

## Court terme — étoffer le contenu

L'ordre proposé suit l'utilité pour un élève, pas la facilité d'écriture.

1. **Épaissir chaque niveau jusqu'à une progression suivie.** Un chapitre par
   matière suffit à montrer ce que l'application sait faire ; il n'enchaîne
   personne. Le collège en mathématiques et le primaire sont les deux endroits
   où une suite de cinq ou six chapitres changerait l'usage.
2. **Les matières les plus maigres** : technologie, logique et histoire des
   sciences n'ont qu'un chapitre chacune.
3. **Le lycée et l'université**, où chaque chapitre demande plus de travail
   d'écriture et souvent une figure neuve.

Chaque chapitre écrit doit passer `flutter test test/data/content_test.dart`.

## Moyen terme — briques techniques

| Brique | Pourquoi, et quand |
|---|---|
| **Révision espacée explicite** | Les données sont déjà là (`distinctDays`, justesse par leçon). Un écran « à réviser aujourd'hui » devient utile dès qu'il y a une dizaine de chapitres terminés, pas avant. |
| **Rendu LaTeX** | Les formules Unicode suffisent jusqu'au lycée. Le supérieur (intégrales, matrices, sommes) en aura besoin : à faire en même temps que les premiers chapitres universitaires. |
| **Éditeur de code embarqué** | Pour l'informatique au lycée : exécuter un petit programme Python dans l'application. Techniquement le plus gros morceau restant. |
| **Sons** | Un retour sonore court sur bonne réponse, désactivable. Volontairement repoussé : mal fait, c'est pire que rien. |
| **Plus de figures interactives** | Circuit électrique, balance chimique, cellule explorable, courbe de fonction, repère orthonormé. Chaque figure sert plusieurs chapitres. |
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
