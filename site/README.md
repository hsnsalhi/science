# Site public d'Eurêka

Quatre pages statiques, à déposer sous `https://techlyb.com/eureka/`.

```
site/
├── index.html              → /eureka/
├── support.html            → /eureka/support.html
├── confidentialite.html    → /eureka/confidentialite.html
├── privacy.html            → /eureka/privacy.html
└── assets/                 style, icônes, police
```

## Déployer

Copier le **contenu** de `site/` dans le dossier `eureka/` de l'hébergement.
Aucune compilation, aucune dépendance, aucun serveur applicatif : du HTML et
du CSS.

```bash
rsync -av --delete site/ utilisateur@techlyb.com:/var/www/techlyb.com/eureka/
```

## Les trois URL à donner à App Store Connect

| Champ App Store Connect | URL |
|---|---|
| **Privacy Policy URL** (obligatoire) | `https://techlyb.com/eureka/confidentialite.html` |
| **Support URL** (obligatoire) | `https://techlyb.com/eureka/support.html` |
| Marketing URL (facultatif) | `https://techlyb.com/eureka/` |

Apple vérifie que ces URL répondent. Elles doivent être en ligne **avant** de
soumettre la fiche.

## Captures d'écran

Les images de `assets/screens/` sont produites par l'application elle-même,
pas dessinées :

```bash
flutter test test/screenshots/capture_screenshots.dart --update-goldens
python3 tool/export_screenshots.py
```

Le premier ordre rend les écrans aux dimensions exactes exigées par App Store
Connect — 1320 × 2868 pour l'iPhone 6,9 pouces, 2064 × 2752 pour l'iPad
13 pouces — dans `test/screenshots/goldens/`. **Ces fichiers sont
téléversables tels quels dans la fiche App Store.** Le second les réduit pour
le site et compose l'image de partage.

Le fichier de capture ne se termine pas par `_test.dart` : un `flutter test`
ordinaire l'ignore. C'est voulu, une comparaison de pixels dépendant de la
plateforme de rendu, elle échouerait sur le runner macOS et bloquerait la
publication pour une différence d'anticrénelage.

## À compléter avant mise en ligne

Trois points sont signalés en jaune dans les pages, et doivent être renseignés :

1. **Identité de l'éditeur** — nom ou raison sociale, statut, adresse. Obligatoire
   pour un service en ligne destiné au public.
2. **Hébergeur du site** — nom, adresse, durée de conservation des journaux.
3. **Adresse de contact** — les pages utilisent `contact@techlyb.com`. Vérifier
   que cette boîte existe et est relevée : Apple écrit parfois à cette adresse,
   et c'est le seul canal d'assistance affiché.

## Ce que les pages affirment

Le texte de la politique de confidentialité décrit exactement ce que fait
l'application : aucune collecte, aucune requête réseau, stockage local
uniquement. **Ces affirmations sont vérifiables dans le code** — elles doivent
être revues si l'application venait à changer sur ce point, notamment si une
synchronisation serveur était ajoutée un jour.

La police Nunito est servie depuis ce domaine plutôt que depuis un CDN : un
site qui promet l'absence de traçage ne peut pas exposer l'adresse IP de ses
visiteurs à un service tiers au premier chargement.
