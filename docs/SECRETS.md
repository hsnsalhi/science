# Organiser les secrets de publication entre plusieurs applications

> Contexte : ce compte Apple publie plusieurs applications (Eurêka, Chabaka…).
> La question « que peut-on partager ? » a une réponse nette, et elle évite de
> refaire une heure de paperasse à chaque nouvelle application.

---

## Le point de départ, qui surprend souvent

**La valeur d'un secret GitHub n'est jamais relisible.** Ni par un outil, ni
par l'API, ni par le propriétaire du dépôt dans l'interface. On ne peut que
l'écraser. L'API expose uniquement le **nom** d'un secret et sa date de
dernière modification.

Conséquence pratique : **on ne copie pas un secret d'un dépôt à l'autre.** On
recolle la valeur depuis le **fichier d'origine** (`dist.p12`,
`AuthKey_XXXXXXXXXX.p8`). Ces fichiers sont donc à conserver — dans un
gestionnaire de mots de passe, jamais dans un dépôt.

## Ce qui se partage, et ce qui ne se partage pas

Sur **sept** secrets, **six** sont communs à toutes les applications d'un même
compte Apple. Un seul est propre à l'application.

| Secret | Portée | Pourquoi |
|---|---|---|
| `IOS_TEAM_ID` | **commun** | Un seul identifiant d'équipe par compte Apple : `K69HUXQMGL`. |
| `ASC_KEY_ID` | **commun** | Une clé d'API App Store Connect au rôle *App Manager* vaut pour toutes les apps de l'équipe. |
| `ASC_ISSUER_ID` | **commun** | Identique pour tout le compte. |
| `ASC_PRIVATE_KEY_BASE64` | **commun** | Le fichier `.p8` de cette même clé. |
| `IOS_DIST_CERT_P12_BASE64` | **commun** | Un certificat de distribution signe **toutes** les apps de l'équipe. |
| `IOS_DIST_CERT_PASSWORD` | **commun** | Le mot de passe de ce `.p12`. |
| `IOS_PROVISIONING_PROFILE_BASE64` | **propre à l'app** | Un profil est lié à un Bundle ID. `com.techlyb.eureka` et `com.techlyb.chabaka` en exigent chacun un. |

### Partager le certificat n'est pas un raccourci, c'est la bonne pratique

Apple **limite le nombre de certificats de distribution** d'un compte (deux en
pratique). En créer un par application mène droit au mur : au troisième, le
portail refuse, et il faut révoquer — ce qui **casse immédiatement les builds
de toutes les applications** qui s'appuyaient sur le certificat révoqué.

Un seul certificat de distribution, réutilisé partout, est la configuration
attendue par Apple.

### Pourquoi le profil, lui, ne se partage pas

Un profil d'approvisionnement associe trois choses : une équipe, **un Bundle
ID précis**, et un ou plusieurs certificats. Changer d'application change le
Bundle ID, donc le profil. C'est le seul élément à refaire — cinq minutes sur
le portail.

### Et le workflow lui-même ?

`.github/workflows/testflight.yml` **ne contient aucun identifiant
d'application** : il lit le Bundle ID dans le profil d'approvisionnement au
moment du build. Le fichier est donc copiable tel quel dans un autre dépôt
Flutter, sans la moindre retouche.

## Si Chabaka est déjà configuré

Alors il ne reste, pour Eurêka, qu'**un seul élément à produire** : le profil
d'approvisionnement de `com.techlyb.eureka`. Les six autres secrets se
recollent depuis les fichiers d'origine de Chabaka.

```bash
# Depuis les fichiers conservés lors de la configuration de Chabaka :
python3 tool/ios_signing.py secrets \
  --p12 chemin/vers/dist.p12 \
  --profile ~/Téléchargements/Eureka_App_Store.mobileprovision \
  --asc-key chemin/vers/AuthKey_XXXXXXXXXX.p8 \
  --write-to ios-signing/secrets
```

Et avant tout, le contrôle de cohérence — il vérifie notamment que le profil
tout neuf contient bien **l'ancien** certificat :

```bash
python3 tool/ios_signing.py check \
  --p12 chemin/vers/dist.p12 \
  --profile ~/Téléchargements/Eureka_App_Store.mobileprovision
```

> En créant le profil d'Eurêka sur le portail, **coche le certificat existant**
> — celui qui signe déjà Chabaka. Ne crée pas un nouveau certificat.

## Si les fichiers d'origine ont été perdus

| Élément perdu | Récupérable ? | Que faire |
|---|---|---|
| `AuthKey_*.p8` | **Non**, téléchargeable une seule fois | En générer une nouvelle (le nombre de clés n'est pas contraint), mettre à jour `ASC_KEY_ID` et `ASC_PRIVATE_KEY_BASE64` dans **tous** les dépôts, puis révoquer l'ancienne. |
| `dist.p12` | **Non** si la clé privée est perdue | Révoquer le certificat et en créer un neuf — puis **régénérer les profils de toutes les applications**, qui référencent l'ancien. À faire en une fois. |
| `.mobileprovision` | **Oui** | Le retélécharger depuis le portail, il n'y a rien à recréer. |

## L'organisation à viser

### Aujourd'hui : des secrets par dépôt

Avec deux applications, chaque secret commun existe en double. Au moindre
renouvellement — un certificat expire au bout d'un an — il faut penser à le
mettre à jour partout. C'est exactement le genre d'oubli qui se découvre le
jour d'une publication urgente.

### La bonne structure : une organisation GitHub et des secrets partagés

Les **secrets d'organisation** sont définis une fois et s'exposent aux dépôts
choisis. Dans les workflows, `${{ secrets.IOS_TEAM_ID }}` s'écrit exactement
pareil : **aucune modification de `testflight.yml` n'est nécessaire.**

Une organisation GitHub est **gratuite** pour des dépôts publics comme privés.

1. <https://github.com/organizations/plan> → créer une organisation gratuite,
   par exemple `techlyb`.
2. Y transférer `science` et `chabaka` (Settings → General → Transfer
   ownership). Les URL existantes continuent de rediriger.
3. Organisation → Settings → Secrets and variables → Actions →
   **New organization secret**, pour les six secrets communs. Portée :
   *Selected repositories*, puis cocher les deux dépôts.
4. Dans chaque dépôt, ne garder que
   `IOS_PROVISIONING_PROFILE_BASE64`.

Un secret de dépôt masque le secret d'organisation de même nom : la migration
peut donc se faire dépôt par dépôt, sans interruption.

Le renouvellement annuel du certificat devient alors **une seule mise à jour**
au lieu d'une par application — et plus rien à oublier.

### Variables plutôt que secrets

`IOS_TEAM_ID`, `ASC_KEY_ID` et `ASC_ISSUER_ID` ne sont pas des informations
sensibles : un Team ID figure dans chaque application publiée. Les déclarer en
**variables d'organisation** (onglet *Variables*) plutôt qu'en secrets les
rend lisibles dans l'interface et dans les journaux — ce qui aide au
diagnostic, là où un secret masqué affiche `***` et complique la lecture.

Cela supposerait de remplacer `secrets.IOS_TEAM_ID` par `vars.IOS_TEAM_ID`
dans le workflow. **Changement volontairement non appliqué ici** : tant que la
première publication n'a pas réussi, mieux vaut ne pas déplacer une pièce.
À reconsidérer ensuite.

## Ce qui ne doit jamais arriver

- Un `.p12`, un `.p8` ou un mot de passe **dans un dépôt**. `.gitignore` les
  écarte déjà (`*.p12`, `*.mobileprovision`, `AuthKey_*.p8`, `ios-signing/`).
- Un secret **collé dans une conversation** — y compris avec un assistant.
  Les valeurs vont du gestionnaire de mots de passe à l'interface GitHub,
  directement.
- Un `echo` d'une valeur sensible dans un workflow. GitHub masque les secrets
  connus dans les journaux, mais pas ce qui en est dérivé.
