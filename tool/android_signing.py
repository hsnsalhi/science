#!/usr/bin/env python3
"""Fabrique et vérifie la clé de signature Android, sans rien envoyer nulle part.

Google Play refuse tout paquet signé avec la clé de débogage. Il faut donc
une **clé de téléversement** : un fichier `.jks` protégé par mot de passe,
créé une fois, conservé précieusement, et jamais versionné. Perdre cette
clé sans avoir activé la signature par Google rend impossible toute mise à
jour de l'application publiée.

    python3 tool/android_signing.py creer
    #  → android/upload-keystore.jks et android/key.properties
    python3 tool/android_signing.py verifier
    python3 tool/android_signing.py secrets

La dernière commande affiche les valeurs à coller dans
Settings → Secrets and variables → Actions du dépôt GitHub. Elles ne
transitent par aucun service : le script les écrit sur le terminal, et
c'est tout.

Voir docs/ANDROID.md pour le contexte de chaque étape.
"""

from __future__ import annotations

import argparse
import base64
import getpass
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ANDROID = ROOT / "android"
KEYSTORE = ANDROID / "upload-keystore.jks"
PROPRIETES = ANDROID / "key.properties"

OK = "  ✓"
BAD = "  ✗"
WARN = "  !"


def erreur(message: str) -> None:
    print(f"\n{BAD} {message}", file=sys.stderr)
    raise SystemExit(1)


def keytool() -> str:
    """Le chemin de `keytool`, livré avec n'importe quel JDK.

    La recherche va au-delà du PATH parce qu'un JDK présent mais absent du
    PATH est le cas le plus courant : sous Windows, l'installateur
    d'Adoptium laisse la case « Add to PATH » décochée, et Android Studio
    embarque son propre JDK sans l'exposer du tout.
    """
    trouve = shutil.which("keytool")
    if trouve:
        return trouve

    exe = ".exe" if os.name == "nt" else ""

    # JAVA_HOME d'abord : c'est la réponse la plus fiable quand elle existe.
    java_home = os.environ.get("JAVA_HOME")
    if java_home:
        candidat = Path(java_home) / "bin" / f"keytool{exe}"
        if candidat.exists():
            return str(candidat)

    # Puis les emplacements habituels, par système.
    motifs: list[Path] = []
    if os.name == "nt":
        # Une variable absente vaut la chaîne vide, et Path("") désigne le
        # répertoire courant : sans ce filtre, on irait chercher un JDK
        # dans le dossier d'où le script est lancé.
        dossiers = [
            os.environ.get("ProgramFiles") or "C:\\Program Files",
            os.environ.get("ProgramFiles(x86)") or "C:\\Program Files (x86)",
        ]
        local = os.environ.get("LOCALAPPDATA")
        if local:
            dossiers.append(str(Path(local) / "Programs"))
        for chemin in dossiers:
            racine = Path(chemin)
            if not racine.exists():
                continue
            motifs += [
                # Le JDK embarqué d'Android Studio : déjà là chez beaucoup
                # de monde, et suffisant pour fabriquer une clé.
                racine / "Android" / "Android Studio" / "jbr" / "bin" / f"keytool{exe}",
                *sorted(racine.glob(f"Eclipse Adoptium/*/bin/keytool{exe}")),
                *sorted(racine.glob(f"Java/*/bin/keytool{exe}")),
                *sorted(racine.glob(f"Microsoft/jdk*/bin/keytool{exe}")),
                *sorted(racine.glob(f"Amazon Corretto/*/bin/keytool{exe}")),
            ]
    else:
        for base in (
            Path("/usr/lib/jvm"),
            Path("/Library/Java/JavaVirtualMachines"),
            Path("/opt/homebrew/opt"),
        ):
            if not base.exists():
                continue
            motifs += sorted(base.glob("*/bin/keytool"))
            motifs += sorted(base.glob("*/Contents/Home/bin/keytool"))
            motifs += sorted(base.glob("*/libexec/openjdk.jdk/Contents/Home/bin/keytool"))

    for candidat in motifs:
        if candidat.exists():
            return str(candidat)

    if os.name == "nt":
        erreur(
            "keytool est introuvable. Il est livré avec le JDK.\n\n"
            "  1. Installer « Temurin 17 (JDK) » depuis adoptium.net\n"
            "  2. Pendant l'installation, cocher « Set JAVA_HOME variable »\n"
            "     et « Add to PATH » — elles sont décochées par défaut.\n"
            "  3. Fermer et rouvrir ce terminal : une fenêtre déjà ouverte\n"
            "     garde l'ancien PATH.\n\n"
            "Si Android Studio est installé, son JDK suffit et ce script\n"
            "le trouve tout seul — vérifier qu'il est bien à l'emplacement\n"
            r"« C:\Program Files\Android\Android Studio\jbr »."
        )
    erreur(
        "keytool est introuvable. Il est livré avec le JDK : installer "
        "« Temurin 17 » (adoptium.net), le paquet default-jdk sous Linux, "
        "ou « brew install openjdk@17 » sous macOS."
    )
    raise AssertionError("inatteignable")


def creer(args: argparse.Namespace) -> None:
    if KEYSTORE.exists() and not args.remplacer:
        erreur(
            f"{KEYSTORE} existe déjà. La remplacer rendrait impossible toute "
            "mise à jour d'une application déjà publiée avec l'ancienne. "
            "Utiliser --remplacer seulement si rien n'a encore été publié."
        )

    # On vérifie l'outillage avant de demander quoi que ce soit : échouer
    # après deux saisies de mot de passe pousse à en choisir un court au
    # second essai, ce qui est exactement ce qu'il ne faut pas.
    outil = keytool()

    print("Création de la clé de téléversement.")
    print(
        "\nLe mot de passe protège le fichier. Il sera demandé à chaque\n"
        "publication, et devra être confié à l'intégration continue sous\n"
        "forme de secret. Choisir une phrase longue, et la ranger dans un\n"
        "gestionnaire de mots de passe : elle n'est récupérable nulle part."
    )
    motdepasse = getpass.getpass("\nMot de passe : ")
    if len(motdepasse) < 6:
        erreur("Un magasin de clés exige au moins six caractères.")
    if motdepasse != getpass.getpass("Confirmer    : "):
        erreur("Les deux saisies diffèrent.")

    sujet = (
        f"CN={args.nom}, OU={args.organisation}, O={args.organisation}, "
        f"L={args.ville}, C={args.pays}"
    )
    commande = [
        outil,
        "-genkeypair",
        "-v",
        "-keystore",
        str(KEYSTORE),
        "-storetype",
        "JKS",
        "-keyalg",
        "RSA",
        "-keysize",
        "2048",
        # Vingt-sept ans : Google exige une validité qui dépasse le 22
        # octobre 2033, et une clé expirée interdit toute mise à jour.
        "-validity",
        "10000",
        "-alias",
        args.alias,
        "-dname",
        sujet,
        "-storepass",
        motdepasse,
        "-keypass",
        motdepasse,
    ]
    resultat = subprocess.run(commande, capture_output=True, text=True)
    if resultat.returncode != 0:
        erreur(f"keytool a échoué :\n{resultat.stderr.strip()}")
    print(f"{OK} {KEYSTORE.relative_to(ROOT)} créé.")

    PROPRIETES.write_text(
        "# Écrit par tool/android_signing.py. Jamais versionné.\n"
        f"storeFile=upload-keystore.jks\n"
        f"storePassword={motdepasse}\n"
        f"keyAlias={args.alias}\n"
        f"keyPassword={motdepasse}\n",
        encoding="utf-8",
    )
    PROPRIETES.chmod(0o600)
    print(f"{OK} {PROPRIETES.relative_to(ROOT)} écrit.")
    print(
        f"\n{WARN} Ces deux fichiers sont ignorés par git, et doivent le "
        "rester.\n"
        f"{WARN} Les sauvegarder hors du dépôt : sans eux, aucune mise à "
        "jour n'est possible.\n"
    )
    print("Étape suivante : python3 tool/android_signing.py secrets")


def _lire_proprietes() -> dict[str, str]:
    if not PROPRIETES.exists():
        erreur(
            f"{PROPRIETES.relative_to(ROOT)} est absent. "
            "Lancer d'abord : python3 tool/android_signing.py creer"
        )
    valeurs: dict[str, str] = {}
    for ligne in PROPRIETES.read_text(encoding="utf-8").splitlines():
        ligne = ligne.strip()
        if not ligne or ligne.startswith("#") or "=" not in ligne:
            continue
        cle, _, valeur = ligne.partition("=")
        valeurs[cle.strip()] = valeur.strip()
    return valeurs


def verifier(args: argparse.Namespace) -> None:
    del args
    print("Vérification de la clé de téléversement.\n")
    proprietes = _lire_proprietes()

    manquants = [
        c
        for c in ("storeFile", "storePassword", "keyAlias", "keyPassword")
        if not proprietes.get(c)
    ]
    if manquants:
        erreur(f"Clés absentes de key.properties : {', '.join(manquants)}")
    print(f"{OK} key.properties contient les quatre champs attendus.")

    magasin = ANDROID / proprietes["storeFile"]
    if not magasin.exists():
        erreur(f"{magasin} est introuvable.")
    print(f"{OK} {magasin.name} présent ({magasin.stat().st_size} octets).")

    resultat = subprocess.run(
        [
            keytool(),
            "-list",
            "-v",
            "-keystore",
            str(magasin),
            "-alias",
            proprietes["keyAlias"],
            "-storepass",
            proprietes["storePassword"],
        ],
        capture_output=True,
        text=True,
    )
    if resultat.returncode != 0:
        erreur(
            "keytool refuse d'ouvrir le magasin : mot de passe ou alias "
            f"incorrect.\n{resultat.stderr.strip()}"
        )
    print(f"{OK} L'alias « {proprietes['keyAlias']} » s'ouvre avec ce mot de passe.")

    sortie = resultat.stdout
    empreinte = re.search(r"SHA256:\s*([0-9A-F:]+)", sortie)
    if empreinte:
        print(f"{OK} Empreinte SHA-256 : {empreinte.group(1)[:47]}…")
    expiration = re.search(r"jusqu'au|until:\s*(.+)", sortie)
    if expiration:
        print(f"{OK} Valide {expiration.group(0).strip()}")

    # Une clé de 2048 bits au moins, exigence de Google Play.
    taille = re.search(r"(\d+)[ -]bit", sortie)
    if taille and int(taille.group(1)) < 2048:
        erreur(f"Clé de {taille.group(1)} bits : Google Play en exige 2048.")

    print("\nTout est cohérent. La signature de publication fonctionnera.")


def secrets(args: argparse.Namespace) -> None:
    del args
    proprietes = _lire_proprietes()
    magasin = ANDROID / proprietes["storeFile"]
    if not magasin.exists():
        erreur(f"{magasin} est introuvable.")

    encode = base64.b64encode(magasin.read_bytes()).decode("ascii")

    print(
        "\nÀ déposer dans Settings → Secrets and variables → Actions,\n"
        "bouton « New repository secret ». Une fois enregistré, un secret\n"
        "n'est plus lisible, par personne — y compris par vous.\n"
    )
    print(f"{WARN} Ne jamais coller ces valeurs dans une conversation,")
    print(f"{WARN} un ticket, un message ou un fichier du dépôt.\n")

    lignes = [
        ("ANDROID_KEYSTORE_BASE64", encode),
        ("ANDROID_KEYSTORE_PASSWORD", proprietes["storePassword"]),
        ("ANDROID_KEY_ALIAS", proprietes["keyAlias"]),
        ("ANDROID_KEY_PASSWORD", proprietes["keyPassword"]),
    ]
    for nom, valeur in lignes:
        apercu = valeur if len(valeur) <= 60 else f"{valeur[:40]}… ({len(valeur)} caractères)"
        print(f"── {nom} " + "─" * max(0, 60 - len(nom)))
        print(apercu if nom != "ANDROID_KEYSTORE_BASE64" else valeur)
        print()

    print(
        "Le cinquième secret, GOOGLE_PLAY_SERVICE_ACCOUNT_JSON, ne se\n"
        "fabrique pas ici : il vient de la console Google Cloud. La\n"
        "procédure est dans docs/ANDROID.md. Sans lui, l'intégration\n"
        "continue produit quand même l'APK et l'AAB, mais ne les envoie pas\n"
        "sur Google Play."
    )


def main() -> None:
    analyseur = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sous = analyseur.add_subparsers(dest="commande", required=True)

    p_creer = sous.add_parser("creer", help="fabriquer la clé de téléversement")
    p_creer.add_argument("--alias", default="eureka")
    p_creer.add_argument("--nom", default="Eureka")
    p_creer.add_argument("--organisation", default="Techlyb")
    p_creer.add_argument("--ville", default="Paris")
    p_creer.add_argument("--pays", default="FR")
    p_creer.add_argument(
        "--remplacer",
        action="store_true",
        help="écraser une clé existante (danger : voir l'aide)",
    )
    p_creer.set_defaults(fonction=creer)

    p_verifier = sous.add_parser("verifier", help="contrôler la clé et le mot de passe")
    p_verifier.set_defaults(fonction=verifier)

    p_secrets = sous.add_parser("secrets", help="afficher les secrets à déposer sur GitHub")
    p_secrets.set_defaults(fonction=secrets)

    args = analyseur.parse_args()
    args.fonction(args)


if __name__ == "__main__":
    main()
