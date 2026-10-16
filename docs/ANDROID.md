# Mettre Eurêka sur Android

> **La bonne nouvelle, d'emblée :** côté Android, rien n'est obligatoire pour
> commencer. Pas de machine particulière, pas de compte, pas de clé. Le
> workflow `.github/workflows/android.yml` produit un **APK installable**
> qu'on télécharge depuis l'onglet Actions et qu'on ouvre sur le téléphone.
> Dix minutes, zéro euro.
>
> Un compte **Google Play Console** (25 $ une seule fois, pas par an) ne
> devient nécessaire que pour distribuer à des testeurs sans leur demander
> d'installer un fichier à la main.

Trois niveaux, à franchir dans l'ordre et seulement si le besoin se présente :

| Niveau | Ce que ça donne | Ce que ça demande | Temps |
|---|---|---|---|
| 1. APK brut | L'application sur ton téléphone et ceux de tes proches | rien | 10 min |
| 2. APK signé | Le même, avec une clé stable : les mises à jour s'installent par-dessus | une clé de téléversement | +15 min |
| 3. Google Play | Un lien d'invitation, installation et mises à jour automatiques | compte Play à 25 $ + compte de service | +1 h |

---

## Niveau 1 — Un APK, tout de suite

1. Onglet **Actions** du dépôt → **Android** → **Run workflow**.
2. Laisser `destination` sur `apk-seulement`, écrire une note si tu veux.
3. Attendre six à huit minutes — la première exécution réelle a pris
   6 min 30 s en tout, dont 4 min 20 s pour la compilation elle-même.
4. En bas de la page d'exécution, section **Artifacts**, télécharger
   `eureka-android-build-<n>` (une trentaine de mégaoctets ; conservé
   quatorze jours).
5. Dézipper, transférer `app-release.apk` sur le téléphone, l'ouvrir.

Android demandera d'autoriser l'installation depuis cette source : c'est
normal pour une application qui ne vient pas du Play Store, et le réglage se
révoque juste après.

**Ce que cet APK ne sait pas faire.** Il est signé avec la clé de débogage,
celle que Flutter fabrique tout seul. Deux conséquences : Google Play le
refuserait, et une version suivante signée avec une autre clé ne s'installera
pas par-dessus — il faudra désinstaller d'abord. Pour un essai, c'est sans
importance.

---

## Niveau 2 — Une clé de téléversement

Une clé stable permet aux mises à jour de remplacer la version précédente
sans désinstallation, et c'est le préalable à toute publication.

**Prérequis : un JDK.** La clé est fabriquée par `keytool`, qui est livré
avec le JDK et avec rien d'autre. Si Android Studio est installé, son JDK
embarqué suffit et le script le trouve tout seul. Sinon :

| Système | Quoi installer |
|---|---|
| Windows | « Temurin 17 (JDK) » sur [adoptium.net](https://adoptium.net), en cochant **Set JAVA_HOME variable** et **Add to PATH** — décochées par défaut |
| macOS | `brew install openjdk@17` |
| Linux | `sudo apt install default-jdk` |

Sous Windows, il faut **fermer et rouvrir le terminal** après l'installation :
une fenêtre déjà ouverte garde l'ancien PATH. C'est la cause la plus
fréquente d'un « keytool introuvable » juste après avoir installé le JDK.

```bash
python3 tool/android_signing.py creer
python3 tool/android_signing.py verifier
```

La première commande demande un mot de passe et écrit deux fichiers :

- `android/upload-keystore.jks` — la clé elle-même ;
- `android/key.properties` — le chemin, l'alias et le mot de passe.

Les deux sont ignorés par git et **doivent le rester**. Le `.gitignore` du
dépôt couvre déjà `*.jks`, `*.keystore` et `key.properties`.

> **Ne colle jamais ce fichier ni ce mot de passe dans une conversation, un
> ticket ou un message.** Une conversation est archivée ; une clé qui y passe
> est à considérer comme perdue.

**À sauvegarder.** Le `.jks` et son mot de passe, dans un gestionnaire de mots
de passe. Si tu les perds avant d'avoir publié quoi que ce soit, il suffit
d'en refaire une. Si tu les perds après, Google peut réinitialiser la clé de
téléversement sur demande — c'est l'un des avantages de la signature par
Google Play, qui garde la vraie clé de l'application et que la console active
par défaut depuis 2021.

Ensuite :

```bash
python3 tool/android_signing.py secrets
```

La commande affiche quatre valeurs à déposer dans **Settings → Secrets and
variables → Actions**, bouton *New repository secret* :

| Secret | Contenu |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | le `.jks` encodé en base64 |
| `ANDROID_KEYSTORE_PASSWORD` | le mot de passe du magasin |
| `ANDROID_KEY_ALIAS` | l'alias, `eureka` par défaut |
| `ANDROID_KEY_PASSWORD` | le mot de passe de la clé, identique au précédent |

Une fois enregistré, **un secret n'est plus relisible par personne**, toi
compris : on ne peut que l'écraser. C'est pourquoi les fichiers d'origine
sont à conserver.

Le workflow détecte ces secrets tout seul. La prochaine exécution produira un
APK **et** un AAB, tous deux signés avec cette clé.

---

## Niveau 3 — Google Play

### Étape 1 — Le compte

S'inscrire sur <https://play.google.com/console/signup> : 25 $ une seule
fois. Compter un à deux jours de vérification d'identité.

Créer l'application dans la console, avec le nom de paquet exact :

```
com.techlyb.eureka
```

Il ne pourra plus changer. La fiche du Store (description, captures,
politique de confidentialité) n'est obligatoire que pour une diffusion
publique — la piste de **test interne** n'en demande aucune.

### Étape 2 — Le compte de service

C'est le droit de publier, délégué à une machine. Il se crée en deux endroits.

Dans **Google Cloud** (<https://console.cloud.google.com>) :

1. Créer un projet, ou en réutiliser un.
2. **APIs & Services → Library** → activer **Google Play Android Developer API**.
3. **IAM & Admin → Service Accounts** → *Create service account*, nom libre,
   aucun rôle à cette étape.
4. Sur le compte créé : **Keys → Add key → Create new key → JSON**. Le
   fichier se télécharge une seule fois.

Dans la **Play Console** :

5. **Users and permissions → Invite new user**, coller l'adresse
   `…@….iam.gserviceaccount.com` du compte de service.
6. Lui donner, sur Eurêka uniquement, les droits **Release to testing tracks**
   et **View app information**. Rien de plus : ce compte n'a pas besoin de
   pouvoir publier en production.

### Étape 3 — Vérifier avant de publier

```bash
python3 tool/play_upload.py verifier --compte ~/Téléchargements/compte.json
```

La commande ouvre une édition vide sur l'application puis la referme, sans
rien publier. Si elle passe, les droits sont bons. Si elle échoue, le message
dit lequel des trois points manque : API désactivée, compte non invité, ou
droits insuffisants.

### Étape 4 — Le cinquième secret

Déposer le **contenu entier** du fichier JSON dans un secret nommé
`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`. Le fichier lui-même se range dans le
gestionnaire de mots de passe, comme le reste.

### Étape 5 — Envoyer

Onglet **Actions** → **Android** → **Run workflow**, `destination` sur
`play-interne`.

Le build apparaît dans la console sous **Test → Internal testing** en
quelques minutes. L'onglet *Testers* donne un lien d'inscription à partager :
ceux qui l'ouvrent reçoivent l'application et ses mises à jour comme
n'importe quelle autre.

---

## Comment c'est construit

`tool/play_upload.py` fait l'envoi avec la seule bibliothèque standard et
`openssl`. Aucune action du Marketplace n'est utilisée : une action tierce
recevrait le compte de service, qui a le droit de publier l'application, et
c'est beaucoup de confiance pour du code mis à jour sans qu'on le relise.

Le script signe un jeton RS256, ouvre une édition, téléverse le paquet,
positionne la piste et valide. Quatre requêtes HTTP, deux cents lignes.

Le `versionCode` vient du numéro d'exécution du workflow. Google Play refuse
deux fois le même, et ce compteur ne revient jamais en arrière. Il est propre
au workflow Android : il n'a rien à voir avec celui de TestFlight, et c'est
sans conséquence — les deux magasins comptent séparément.

**R8 n'est pas activé.** La part Java de l'application tient en quelques
classes — tout le reste est du Dart, déjà élagué par Flutter — et
l'obfuscation casse régulièrement des greffons sans que rien ne le signale
avant l'exécution sur un vrai appareil. Le gain de taille ne vaut pas ce
risque. C'est un réglage d'une ligne dans `android/app/build.gradle.kts` si
l'on change d'avis.

---

## Quand ça coince

| Symptôme | Cause habituelle |
|---|---|
| « Le magasin ne s'ouvre pas avec cet alias » | `ANDROID_KEY_ALIAS` ou le mot de passe ne correspond pas. Relancer `android_signing.py verifier` en local pour trancher. |
| « Le magasin décodé ne fait que N octets » | `ANDROID_KEYSTORE_BASE64` a été collé tronqué. La valeur fait plusieurs milliers de caractères sur une seule ligne. |
| HTTP 401 au téléversement | L'API Google Play Android Developer n'est pas activée sur le projet Cloud. |
| HTTP 403 au téléversement | Le compte de service n'a pas été invité dans la Play Console, ou n'a pas le droit *Release to testing tracks*. |
| « Version code N has already been used » | Une exécution précédente a déjà déposé ce numéro. Relancer : le compteur aura avancé. |
| L'APK ne s'installe pas par-dessus l'ancien | Les deux sont signés avec des clés différentes. Désinstaller d'abord, ou passer au niveau 2. |

---

## Le même travail, côté iOS

[docs/TESTFLIGHT.md](TESTFLIGHT.md). Les deux workflows sont indépendants et
se lancent en parallèle : leurs groupes de concurrence sont distincts, et
rien dans l'un n'attend l'autre.
