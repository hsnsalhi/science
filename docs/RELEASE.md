# Publier Eurêka

> État actuel : l'application se compile et passe ses tests. Les étapes
> ci-dessous n'ont **pas** encore été réalisées — elles demandent des comptes
> développeur et des secrets qui n'ont pas leur place dans ce dépôt.

---

## Avant toute publication

- [ ] Choisir une licence (voir `docs/ROADMAP.md`).
- [x] Icône de l'application — générée par `python3 tool/generate_icons.py`
      (iOS et Android, y compris l'icône adaptative Android).
- [ ] Écran de lancement (celui de Flutter est encore en place).
- [ ] Vérifier l'identifiant d'application : `com.techlyb.eureka`
      (`android/app/build.gradle.kts` et la cible Xcode).
- [ ] Relire les textes des réglages : ils décrivent les promesses du produit
      et seront lus par les parents.

## Android

Tout est automatisé depuis le dépôt : voir [ANDROID.md](ANDROID.md). En
résumé, onglet Actions → *Android* → *Run workflow*. Sans aucun secret, le
workflow produit un APK installable à la main ; avec la clé de téléversement,
il produit aussi l'AAB ; avec le compte de service, il le dépose sur la piste
de test interne.

La signature est déjà branchée dans `android/app/build.gradle.kts`, et
`tool/android_signing.py` fabrique la clé et affiche les secrets à déposer.
Il n'y a plus d'étape manuelle de `keytool`.

Pour un build local, une fois `android/key.properties` en place :

```bash
flutter build appbundle --release
```

Déclarations attendues par Play :

- **Sécurité des données** : aucune donnée collectée, aucune donnée partagée.
  C'est exact et vérifiable — l'application n'effectue aucune requête réseau.
- **Public cible** : enfants et adolescents. L'absence de publicité, d'achats
  intégrés et de collecte simplifie considérablement le questionnaire
  « Familles ».
- **Publicités** : aucune.

## iOS

Pour un envoi **TestFlight sans Mac**, suivre
[TESTFLIGHT.md](TESTFLIGHT.md) : le workflow
`.github/workflows/testflight.yml` fait tout depuis un runner macOS GitHub.

La procédure manuelle ci-dessous nécessite macOS et Xcode.

```bash
flutter build ipa --release
```

1. Compte Apple Developer, certificat de distribution, profil
   d'approvisionnement.
2. Ouvrir `ios/Runner.xcworkspace`, régler l'équipe de signature.
3. Transmettre via Xcode ou `xcrun altool`.

Déclarations attendues par App Store Connect :

- **App Privacy** : « Data Not Collected ».
- **Export compliance** : déjà déclarée dans `Info.plist`
  (`ITSAppUsesNonExemptEncryption` = `false`), la question ne sera pas posée à
  chaque envoi.
- **Age Rating** : 4+ (aucun contenu sensible, aucune publicité, aucun accès
  réseau).
- **Kids Category** : éligible, l'application ne contenant ni publicité, ni
  achat, ni lien sortant.

## Listing des stores

Éléments à préparer, en français :

- Titre : `Eurêka — Sciences en s'amusant`
- Sous-titre : `Maths, physique, info, SVT — gratuit et hors-ligne`
- Description : reprendre les quatre promesses du `README.md`.
- Captures : téléphone (6,5″) et tablette (12,9″), en portrait et en paysage —
  l'application gère les deux.

## Versionnage

`pubspec.yaml`, champ `version: <nom>+<build>`. Le nom alimente
`versionName` (Android) et `CFBundleShortVersionString` (iOS) ; le build
alimente `versionCode` et `CFBundleVersion`. Le numéro de build doit croître à
chaque dépôt sur un store.
