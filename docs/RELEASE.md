# Publier Eurêka

> État actuel : l'application se compile et passe ses tests. Les étapes
> ci-dessous n'ont **pas** encore été réalisées — elles demandent des comptes
> développeur et des secrets qui n'ont pas leur place dans ce dépôt.

---

## Avant toute publication

- [ ] Choisir une licence (voir `docs/ROADMAP.md`).
- [ ] Produire l'icône de l'application et l'écran de lancement.
- [ ] Vérifier l'identifiant d'application : `com.eureka.eureka`
      (`android/app/build.gradle.kts` et la cible Xcode).
- [ ] Relire les textes des réglages : ils décrivent les promesses du produit
      et seront lus par les parents.

## Android

```bash
flutter build appbundle --release
```

1. Créer un magasin de clés (`keytool -genkey -v -keystore eureka.jks …`).
2. Renseigner `android/key.properties` — **jamais versionné**, déjà exclu par
   `.gitignore`.
3. Référencer la signature dans `android/app/build.gradle.kts`.
4. Déposer le `.aab` sur la Google Play Console.

Déclarations attendues par Play :

- **Sécurité des données** : aucune donnée collectée, aucune donnée partagée.
  C'est exact et vérifiable — l'application n'effectue aucune requête réseau.
- **Public cible** : enfants et adolescents. L'absence de publicité, d'achats
  intégrés et de collecte simplifie considérablement le questionnaire
  « Familles ».
- **Publicités** : aucune.

## iOS

Nécessite macOS et Xcode.

```bash
flutter build ipa --release
```

1. Compte Apple Developer, certificat de distribution, profil
   d'approvisionnement.
2. Ouvrir `ios/Runner.xcworkspace`, régler l'équipe de signature.
3. Transmettre via Xcode ou `xcrun altool`.

Déclarations attendues par App Store Connect :

- **App Privacy** : « Data Not Collected ».
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
