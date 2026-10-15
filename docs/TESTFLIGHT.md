# Mettre Eurêka sur TestFlight, sans Mac

> **Le point dur, sans détour :** TestFlight impose un compte **Apple Developer
> Program à 99 $/an**, et un IPA ne peut être construit que sur macOS. Aucune
> méthode ne contourne ces deux règles.
>
> En revanche, **tu n'as pas besoin de posséder un Mac** : le workflow
> `.github/workflows/testflight.yml` construit et envoie le build depuis un
> runner macOS fourni par GitHub. Tout le reste de cette page se fait depuis
> un navigateur et un terminal Linux ou Windows.

Compte le temps : environ **1 h de mise en place une fois**, puis **un clic**
pour chaque build suivant.

---

## Étape 0 — Compte Apple Developer

1. S'inscrire sur <https://developer.apple.com/programs/enroll/> (99 $/an).
2. La validation par Apple prend de quelques heures à deux jours.
3. Noter le **Team ID** : <https://developer.apple.com/account> → Membership.
   Dix caractères, par exemple `A1B2C3D4E5`.

Rien de ce qui suit ne fonctionne avant que le compte soit actif.

## Étape 1 — Déclarer l'application

**Identifiant.** <https://developer.apple.com/account/resources/identifiers> →
**+** → App IDs → App → description « Eureka », Bundle ID **explicite** :

```
com.eureka.eureka
```

C'est l'identifiant déjà configuré dans le projet. Pour en utiliser un autre,
le changer dans `ios/Runner.xcodeproj/project.pbxproj`
(`PRODUCT_BUNDLE_IDENTIFIER`, trois occurrences pour `Runner`) et dans
`android/app/build.gradle.kts`. Aucune capacité particulière à cocher :
l'application n'utilise ni notifications, ni iCloud, ni rien d'autre.

**Fiche App Store Connect.** <https://appstoreconnect.apple.com> → Mes apps →
**+** → Nouvelle app : plateforme iOS, nom `Eurêka`, langue Français,
Bundle ID celui ci-dessus, SKU `eureka-001`.

> Sans cette fiche, l'envoi échoue avec une erreur peu explicite. C'est l'oubli
> le plus fréquent.

## Étape 2 — Le certificat de distribution (depuis Linux)

Apple demande d'habitude de générer la demande de certificat depuis le
Trousseau macOS. `openssl` fait exactement la même chose.

```bash
# 1. Une clé privée et une demande de signature (CSR).
openssl genrsa -out dist.key 2048
openssl req -new -key dist.key -out dist.csr \
  -subj "/emailAddress=TON_EMAIL/CN=Eureka Distribution/C=FR"
```

2. <https://developer.apple.com/account/resources/certificates> → **+** →
   **Apple Distribution** → téléverser `dist.csr` → télécharger
   `distribution.cer`.

```bash
# 3. Assembler certificat + clé privée dans un .p12.
openssl x509 -in distribution.cer -inform DER -out dist.pem -outform PEM
openssl pkcs12 -export -legacy \
  -inkey dist.key -in dist.pem \
  -name "Apple Distribution" -out dist.p12
# → choisir un mot de passe, et le retenir : c'est IOS_DIST_CERT_PASSWORD.
```

> `-legacy` n'est pas décoratif. Sans lui, OpenSSL 3 chiffre le `.p12` avec un
> algorithme que le trousseau macOS refuse d'importer, et le build échoue à la
> signature avec un message trompeur.

```bash
# 4. Encoder pour GitHub.
base64 -w0 dist.p12 > dist.p12.b64        # Linux
# base64 -i dist.p12 | tr -d '\n' > dist.p12.b64   # macOS
```

**Garde `dist.key` et `dist.p12` en lieu sûr, hors du dépôt.** Les perdre
oblige à révoquer le certificat et à tout recommencer.

## Étape 3 — Le profil d'approvisionnement

<https://developer.apple.com/account/resources/profiles> → **+** →
**App Store Connect** (sous Distribution) → App ID `com.eureka.eureka` →
sélectionner le certificat créé à l'étape 2 → nommer le profil, par exemple
`Eureka App Store` → télécharger `Eureka_App_Store.mobileprovision`.

```bash
base64 -w0 Eureka_App_Store.mobileprovision > profile.b64
```

> À refaire si tu ajoutes un certificat ou changes de Bundle ID. Un profil
> expire au bout d'un an.

## Étape 4 — La clé d'API App Store Connect

Elle remplace le mot de passe Apple pour l'envoi automatisé.

<https://appstoreconnect.apple.com/access/integrations/api> → onglet
**Team Keys** → **+** → nom `GitHub Actions`, accès **App Manager** →
Generate.

Relever :

- **Key ID** — dix caractères, affiché dans le tableau.
- **Issuer ID** — l'UUID en haut de la page.
- Le fichier **`AuthKey_XXXXXXXXXX.p8`**, téléchargeable **une seule fois**.

```bash
base64 -w0 AuthKey_XXXXXXXXXX.p8 > asc_key.b64
```

## Étape 5 — Les sept secrets GitHub

Dépôt → **Settings** → **Secrets and variables** → **Actions** →
**New repository secret**, sept fois :

| Secret | Contenu |
|---|---|
| `IOS_DIST_CERT_P12_BASE64` | contenu de `dist.p12.b64` |
| `IOS_DIST_CERT_PASSWORD` | le mot de passe choisi à l'étape 2 |
| `IOS_PROVISIONING_PROFILE_BASE64` | contenu de `profile.b64` |
| `IOS_TEAM_ID` | le Team ID de l'étape 0 |
| `ASC_KEY_ID` | le Key ID de l'étape 4 |
| `ASC_ISSUER_ID` | l'Issuer ID de l'étape 4 |
| `ASC_PRIVATE_KEY_BASE64` | contenu de `asc_key.b64` |

Coller le **contenu** des fichiers, pas leur chemin. Une seule ligne, sans
retour à la ligne final.

## Étape 6 — Lancer le build

Dépôt → onglet **Actions** → workflow **TestFlight** → **Run workflow** →
choisir la branche → éventuellement écrire une note pour les testeurs → lancer.

Le workflow, dans l'ordre :

1. vérifie que les sept secrets existent, et s'arrête en les nommant sinon ;
2. installe Flutter 3.47.7 ;
3. lance `flutter analyze` puis `flutter test` — **un build rouge n'est jamais
   envoyé** ;
4. installe certificat et profil dans un trousseau temporaire ;
5. construit l'IPA signé, avec `CFBundleVersion` = numéro d'exécution GitHub ;
6. joint l'IPA aux artefacts du workflow (téléchargeable 14 jours) ;
7. valide puis téléverse sur App Store Connect ;
8. efface certificats et clés du runner, même en cas d'échec.

Compter **12 à 20 minutes**, dont une bonne partie en compilation iOS.

## Étape 7 — Installer sur ton téléphone

1. Apple traite le build : **5 à 20 minutes** après l'envoi. Il apparaît dans
   App Store Connect → ton app → **TestFlight**, d'abord « En cours de
   traitement ».
2. Onglet **Testeurs internes** → créer un groupe → ajouter ton propre compte
   Apple (jusqu'à 100 testeurs internes, sans revue Apple).
3. Installer **TestFlight** depuis l'App Store sur ton iPhone, s'y connecter
   avec le même compte : Eurêka y apparaît, installable.

La conformité à l'export ne sera pas demandée : `ITSAppUsesNonExemptEncryption`
est déjà déclaré à `false` dans `ios/Runner/Info.plist`, ce qui est exact —
l'application ne chiffre rien et n'émet aucune requête réseau.

**Pour les builds suivants** : Actions → Run workflow. C'est tout. Le numéro de
build s'incrémente seul ; pour changer le numéro de version affiché (`1.0.0`),
modifier `version:` dans `pubspec.yaml`.

---

## Quand ça coince

| Symptôme | Cause habituelle |
|---|---|
| `No signing certificate "iOS Distribution" found` | Le `.p12` ne contient pas la clé privée, ou a été créé sans `-legacy`. Refaire l'étape 2 depuis `dist.key`. |
| `Provisioning profile ... doesn't include signing certificate` | Le profil a été créé avant le certificat. Régénérer le profil (étape 3) en cochant le bon certificat. |
| `No suitable application records were found` | La fiche App Store Connect n'existe pas, ou son Bundle ID diffère. Étape 1. |
| `The bundle version must be higher than the previously uploaded version` | Un numéro de build a déjà été utilisé. Relancer : `github.run_number` aura augmenté. |
| `Invalid Pre-Release Train` | La version de `pubspec.yaml` est inférieure ou égale à une version déjà publiée. L'incrémenter. |
| Build rejeté pour cause de SDK trop ancien | Passer `runs-on: macos-15` à `macos-latest` dans le workflow. |

Les journaux complets sont dans l'onglet Actions ; l'étape « Versions de
l'environnement » donne les versions exactes de Flutter, Xcode et CocoaPods
utilisées.

## Si tu as accès à un Mac

Le workflow devient optionnel :

```bash
flutter build ipa --release
open build/ios/archive/Runner.xcarchive   # puis Distribute App dans Xcode
```

La première fois, ouvrir `ios/Runner.xcworkspace` dans Xcode et sélectionner
l'équipe de signature dans Signing & Capabilities.

## Autres services

**Codemagic** (<https://codemagic.io>) offre 500 minutes macOS gratuites par
mois et gère la signature automatiquement à partir de la seule clé d'API de
l'étape 4 — les étapes 2 et 3 deviennent inutiles. C'est plus simple à
démarrer, au prix d'une dépendance à un service tiers. **Xcode Cloud** (Apple,
25 h/mois incluses avec le compte développeur) est l'autre option.

Le workflow GitHub fourni ici ne dépend de rien d'autre que du dépôt et du
compte Apple.
