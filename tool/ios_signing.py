#!/usr/bin/env python3
"""Prépare et vérifie les secrets de signature iOS, depuis Linux ou Windows.

Apple documente ces étapes en supposant un Mac et son Trousseau. `openssl`
fait exactement le même travail. Ce script l'enchaîne, puis — et c'est le
point important — **vérifie la cohérence de l'ensemble avant** le premier
build, car les erreurs de signature ne se manifestent sinon qu'au bout de
quinze minutes d'intégration continue, avec des messages trompeurs.

    python3 tool/ios_signing.py csr --email moi@exemple.fr
    #  → déposer dist.csr sur developer.apple.com, récupérer distribution.cer
    python3 tool/ios_signing.py p12 --cer ~/Téléchargements/distribution.cer
    python3 tool/ios_signing.py check --profile ~/Téléchargements/Eureka.mobileprovision
    python3 tool/ios_signing.py secrets --profile ... --asc-key AuthKey_XXXXXXXXXX.p8

Voir docs/TESTFLIGHT.md pour le contexte de chaque étape.
"""

from __future__ import annotations

import argparse
import base64
import datetime as dt
import getpass
import os
import plistlib
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DIR = ROOT / "ios-signing"

OK = "  ✓"
BAD = "  ✗"
WARN = "  !"


class Failure(Exception):
    """Erreur attendue, affichée sans trace d'exécution."""


def run(args: list[str], *, stdin: bytes | None = None) -> bytes:
    """Lance une commande et renvoie sa sortie, ou lève une [Failure]."""
    try:
        done = subprocess.run(
            args, input=stdin, capture_output=True, check=True
        )
    except FileNotFoundError as error:
        raise Failure(f"Commande introuvable : {args[0]}") from error
    except subprocess.CalledProcessError as error:
        detail = error.stderr.decode(errors="replace").strip()
        raise Failure(f"Échec de « {' '.join(args[:2])} » :\n{detail}") from error
    return done.stdout


def password_from(prompt: str) -> str:
    """Mot de passe du .p12, lu dans l'environnement ou demandé."""
    value = os.environ.get("P12_PASSWORD")
    if value:
        return value
    return getpass.getpass(prompt)


# --------------------------------------------------------------------- csr


def cmd_csr(args: argparse.Namespace) -> int:
    """Crée la clé privée et la demande de signature à déposer chez Apple."""
    folder: Path = args.out
    folder.mkdir(parents=True, exist_ok=True)
    key = folder / "dist.key"
    csr = folder / "dist.csr"

    if key.exists() and not args.force:
        raise Failure(
            f"{key} existe déjà. Réutilise-la, ou relance avec --force "
            "(ce qui invalidera le certificat déjà émis)."
        )

    run(["openssl", "genrsa", "-out", str(key), "2048"])
    key.chmod(0o600)
    run([
        "openssl", "req", "-new",
        "-key", str(key), "-out", str(csr),
        "-subj", f"/emailAddress={args.email}/CN={args.name}/C={args.country}",
    ])

    print(f"Clé privée      : {key}  (à garder, et à ne jamais versionner)")
    print(f"Demande (CSR)   : {csr}")
    if getattr(args, "quiet", False):
        return 0
    print()
    print("Suite :")
    print("  1. https://developer.apple.com/account/resources/certificates → +")
    print("  2. Type « Apple Distribution », téléverser le fichier .csr")
    print("  3. Télécharger distribution.cer, puis :")
    print(f"     python3 tool/ios_signing.py p12 --cer distribution.cer")
    return 0


# --------------------------------------------------------------------- p12


def cmd_p12(args: argparse.Namespace) -> int:
    """Assemble certificat et clé privée dans un .p12 lisible par macOS."""
    folder: Path = args.out
    key = folder / "dist.key"
    if not key.exists():
        raise Failure(
            f"{key} est introuvable : lance d'abord « ios_signing.py csr »."
        )
    cer: Path = args.cer
    if not cer.exists():
        raise Failure(f"Certificat introuvable : {cer}")

    pem = folder / "dist.pem"
    p12 = folder / "dist.p12"
    # Apple livre un certificat au format DER, que pkcs12 n'accepte pas.
    run([
        "openssl", "x509", "-inform", "DER", "-in", str(cer),
        "-outform", "PEM", "-out", str(pem),
    ])

    password = password_from("Mot de passe à poser sur le .p12 : ")
    if not password:
        raise Failure("Un mot de passe vide est refusé par le trousseau macOS.")

    command = [
        "openssl", "pkcs12", "-export",
        "-inkey", str(key), "-in", str(pem),
        "-name", "Apple Distribution",
        "-out", str(p12),
        "-passout", "stdin",
    ]
    # Sans -legacy, OpenSSL 3 chiffre avec un algorithme que « security
    # import » refuse : le build échoue à la signature, très loin d'ici.
    if _openssl_supports_legacy():
        command.insert(2, "-legacy")
    else:
        print(f"{WARN} openssl sans option -legacy : si l'import échoue sur le")
        print("    runner macOS, régénère le .p12 avec OpenSSL 3.")
    run(command, stdin=password.encode())
    p12.chmod(0o600)

    print(f"{OK} {p12}")
    print()
    print("Vérifie maintenant l'ensemble :")
    print("  python3 tool/ios_signing.py check --profile <profil.mobileprovision>")
    return 0


def _openssl_supports_legacy() -> bool:
    helptext = subprocess.run(
        ["openssl", "pkcs12", "-help"], capture_output=True
    ).stderr.decode(errors="replace")
    return "-legacy" in helptext


def dump_p12(path: Path, password: str) -> str:
    """Déchiffre un .p12 et renvoie son contenu PEM.

    Les .p12 destinés au trousseau macOS sont chiffrés en RC2-40, que
    OpenSSL 3 ne lit qu'avec son fournisseur « legacy ». On essaie donc les
    deux formes avant de conclure à un mauvais mot de passe.
    """
    attempts = (
        ["openssl", "pkcs12", "-legacy", "-in", str(path), "-nodes",
         "-passin", "stdin"],
        ["openssl", "pkcs12", "-in", str(path), "-nodes", "-passin", "stdin"],
    )
    last: Failure | None = None
    for command in attempts:
        try:
            return run(command, stdin=password.encode()).decode(errors="replace")
        except Failure as error:
            last = error
    raise Failure(
        f"{path.name} ne s'ouvre pas : mot de passe incorrect, ou fichier "
        f"illisible.\n{last}"
    )


# ------------------------------------------------------------------- check


def read_profile(path: Path) -> dict:
    """Décode un .mobileprovision (plist signé en CMS)."""
    if not path.exists():
        raise Failure(f"Profil introuvable : {path}")
    for tool in (["openssl", "smime", "-inform", "DER", "-verify", "-noverify"],
                 ["openssl", "cms", "-inform", "DER", "-verify", "-noverify"]):
        try:
            raw = run([*tool, "-in", str(path)])
        except Failure:
            continue
        try:
            return plistlib.loads(raw)
        except Exception:  # noqa: BLE001 — sortie inattendue, on tente l'autre
            continue
    raise Failure(f"Impossible de décoder {path} : fichier corrompu ?")


def cert_fingerprint(der: bytes) -> str:
    out = run(
        ["openssl", "x509", "-inform", "DER", "-noout", "-fingerprint",
         "-sha256"],
        stdin=der,
    )
    return out.decode().strip().split("=", 1)[1]


def cert_subject(der: bytes) -> str:
    out = run(
        ["openssl", "x509", "-inform", "DER", "-noout", "-subject"], stdin=der
    )
    text = out.decode().strip()
    match = re.search(r"CN\s*=\s*([^,/]+)", text)
    return match.group(1).strip() if match else text


def cert_not_after(der: bytes) -> dt.datetime | None:
    out = run(
        ["openssl", "x509", "-inform", "DER", "-noout", "-enddate"], stdin=der
    ).decode()
    try:
        stamp = out.strip().split("=", 1)[1]
        return dt.datetime.strptime(stamp, "%b %d %H:%M:%S %Y %Z").replace(
            tzinfo=dt.timezone.utc
        )
    except (IndexError, ValueError):
        return None


def project_bundle_id() -> str | None:
    """Identifiant déclaré dans le projet Xcode, pour le comparer au profil."""
    pbxproj = ROOT / "ios/Runner.xcodeproj/project.pbxproj"
    if not pbxproj.exists():
        return None
    for line in pbxproj.read_text().splitlines():
        if "PRODUCT_BUNDLE_IDENTIFIER" in line and "RunnerTests" not in line:
            return line.split("=", 1)[1].strip().rstrip(";").strip('"')
    return None


def cmd_check(args: argparse.Namespace) -> int:
    """Vérifie que certificat, profil et clé d'API forment un tout cohérent."""
    folder: Path = args.out
    p12: Path = args.p12 or (folder / "dist.p12")
    problems: list[str] = []
    now = dt.datetime.now(dt.timezone.utc)

    print("Certificat de distribution")
    if not p12.exists():
        raise Failure(f"{p12} est introuvable : lance « ios_signing.py p12 ».")
    password = password_from(f"Mot de passe de {p12.name} : ")
    bundle = dump_p12(p12, password)

    has_key = "PRIVATE KEY" in bundle
    print(f"{OK if has_key else BAD} contient la clé privée")
    if not has_key:
        problems.append(
            "Le .p12 ne contient pas de clé privée : refaire l'étape p12 en "
            "repartant de dist.key."
        )

    p12_der = b""
    match = re.search(
        r"-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----",
        bundle,
        re.S,
    )
    if match:
        p12_der = run(
            ["openssl", "x509", "-outform", "DER"], stdin=match.group(0).encode()
        )
        subject = cert_subject(p12_der)
        is_distribution = "Distribution" in subject
        print(f"{OK if is_distribution else BAD} certificat : {subject}")
        if not is_distribution:
            problems.append(
                f"Le certificat « {subject} » n'est pas un certificat de "
                "distribution. TestFlight exige « Apple Distribution »."
            )
        expiry = cert_not_after(p12_der)
        if expiry:
            left = (expiry - now).days
            mark = OK if left > 30 else (WARN if left > 0 else BAD)
            print(f"{mark} expire le {expiry:%d/%m/%Y} ({left} jours)")
            if left <= 0:
                problems.append("Le certificat a expiré : en générer un neuf.")
    else:
        print(f"{BAD} aucun certificat dans le .p12")
        problems.append("Le .p12 ne contient aucun certificat.")

    if args.profile:
        print()
        print("Profil d'approvisionnement")
        profile = read_profile(args.profile)
        name = profile.get("Name", "?")
        print(f"{OK} nom : {name}")

        app_id = profile.get("Entitlements", {}).get("application-identifier", "")
        team = (profile.get("TeamIdentifier") or [None])[0]
        bundle_id = app_id.split(".", 1)[1] if "." in app_id else ""
        print(f"{OK} équipe : {team}")

        expected = project_bundle_id()
        matches_project = expected is None or bundle_id == expected
        print(f"{OK if matches_project else BAD} identifiant : {bundle_id}")
        if not matches_project:
            problems.append(
                f"Le profil vise « {bundle_id} » alors que le projet déclare "
                f"« {expected} ». Régénérer le profil, ou changer "
                "PRODUCT_BUNDLE_IDENTIFIER dans le projet Xcode."
            )

        # Un profil App Store ne liste aucun appareil ; un profil de
        # développement ou ad-hoc en liste, et sera refusé au téléversement.
        is_store = "ProvisionedDevices" not in profile
        print(f"{OK if is_store else BAD} type : "
              f"{'App Store' if is_store else 'développement ou ad-hoc'}")
        if not is_store:
            problems.append(
                "Ce profil n'est pas un profil App Store. En créer un de type "
                "« App Store Connect » sous Distribution."
            )

        expiry = profile.get("ExpirationDate")
        if isinstance(expiry, dt.datetime):
            if expiry.tzinfo is None:
                expiry = expiry.replace(tzinfo=dt.timezone.utc)
            left = (expiry - now).days
            mark = OK if left > 15 else (WARN if left > 0 else BAD)
            print(f"{mark} expire le {expiry:%d/%m/%Y} ({left} jours)")
            if left <= 0:
                problems.append("Le profil a expiré : en régénérer un.")

        # L'erreur la plus fréquente, et la plus coûteuse à diagnostiquer.
        certs = profile.get("DeveloperCertificates", [])
        fingerprints = {cert_fingerprint(bytes(c)) for c in certs}
        if p12_der:
            embedded = cert_fingerprint(p12_der) in fingerprints
            print(f"{OK if embedded else BAD} contient bien le certificat du .p12")
            if not embedded:
                problems.append(
                    "Le profil n'inclut pas le certificat du .p12. C'est "
                    "l'erreur classique : le profil a été créé avant le "
                    "certificat. Régénérer le profil en cochant le bon "
                    "certificat."
                )

    if args.asc_key:
        print()
        print("Clé d'API App Store Connect")
        key_path: Path = args.asc_key
        if not key_path.exists():
            raise Failure(f"Clé introuvable : {key_path}")
        text = key_path.read_text(errors="replace")
        valid = "BEGIN PRIVATE KEY" in text
        print(f"{OK if valid else BAD} format PKCS#8")
        if not valid:
            problems.append(
                "Le fichier .p8 ne ressemble pas à une clé privée App Store "
                "Connect."
            )
        name_match = re.fullmatch(r"AuthKey_([A-Z0-9]{10})\.p8", key_path.name)
        if name_match:
            print(f"{OK} identifiant de clé (ASC_KEY_ID) : {name_match.group(1)}")
        else:
            print(f"{WARN} nom de fichier inattendu : relever le Key ID à la main")

    print()
    if problems:
        print(f"{len(problems)} problème(s) à corriger avant de lancer un build :")
        for item in problems:
            print(f"  • {item}")
        return 1
    print("Tout est cohérent. Prochaine étape :")
    print("  python3 tool/ios_signing.py secrets --profile <profil> "
          "--asc-key <AuthKey_XXXXXXXXXX.p8>")
    return 0


# ----------------------------------------------------------------- secrets


def cmd_secrets(args: argparse.Namespace) -> int:
    """Affiche les valeurs à coller dans les secrets GitHub."""
    folder: Path = args.out
    p12: Path = args.p12 or (folder / "dist.p12")

    def encode(path: Path) -> str:
        if not path.exists():
            raise Failure(f"Fichier introuvable : {path}")
        return base64.b64encode(path.read_bytes()).decode()

    entries: list[tuple[str, str]] = [
        ("IOS_DIST_CERT_P12_BASE64", encode(p12)),
    ]
    if args.profile:
        entries.append(
            ("IOS_PROVISIONING_PROFILE_BASE64", encode(args.profile))
        )
        team = (read_profile(args.profile).get("TeamIdentifier") or [""])[0]
        entries.append(("IOS_TEAM_ID", team))
    if args.asc_key:
        entries.append(("ASC_PRIVATE_KEY_BASE64", encode(args.asc_key)))
        match = re.fullmatch(r"AuthKey_([A-Z0-9]{10})\.p8", args.asc_key.name)
        if match:
            entries.append(("ASC_KEY_ID", match.group(1)))

    out_dir: Path = args.write_to
    if out_dir:
        out_dir.mkdir(parents=True, exist_ok=True)

    print("À coller dans : dépôt → Settings → Secrets and variables → Actions")
    print()
    for name, value in entries:
        preview = value if len(value) <= 60 else f"{value[:40]}… ({len(value)} car.)"
        print(f"{name}\n  {preview}")
        if out_dir:
            target = out_dir / f"{name}.txt"
            target.write_text(value)
            target.chmod(0o600)
            print(f"  → écrit dans {target}")
        print()

    missing = [
        n for n in (
            "IOS_DIST_CERT_PASSWORD", "ASC_ISSUER_ID",
            *(["IOS_TEAM_ID"] if not args.profile else []),
            *(["ASC_KEY_ID", "ASC_PRIVATE_KEY_BASE64"] if not args.asc_key else []),
        )
    ]
    print("À saisir à la main :")
    for name in missing:
        hint = {
            "IOS_DIST_CERT_PASSWORD": "le mot de passe choisi pour le .p12",
            "ASC_ISSUER_ID": "l'UUID en haut de appstoreconnect.apple.com"
                             "/access/integrations/api",
            "IOS_TEAM_ID": "developer.apple.com/account → Membership",
            "ASC_KEY_ID": "le Key ID, dix caractères",
            "ASC_PRIVATE_KEY_BASE64": "le fichier AuthKey_*.p8 encodé en base64",
        }[name]
        print(f"  • {name} — {hint}")
    return 0



# --------------------------------------------------------------------- go


DOWNLOADS = Path.home() / "Downloads"
TELECHARGEMENTS = Path.home() / "Téléchargements"


def _watch_for(patterns: list[str], since: float) -> Path:
    """Attend qu'un fichier correspondant apparaisse dans les téléchargements.

    Plutôt que de demander un chemin — que personne n'a envie de taper —, on
    surveille les dossiers de téléchargement et on prend le fichier le plus
    récent. Entrée relance l'inspection, au cas où le fichier soit ailleurs.
    """
    folders = [d for d in (DOWNLOADS, TELECHARGEMENTS, Path.cwd()) if d.is_dir()]
    print(f"  (j'attends — surveillance de {', '.join(str(d) for d in folders)})")
    while True:
        found: list[Path] = []
        for folder in folders:
            for pattern in patterns:
                found += [
                    f for f in folder.glob(pattern)
                    if f.stat().st_mtime >= since
                ]
        if found:
            newest = max(found, key=lambda f: f.stat().st_mtime)
            print(f"{OK} trouvé : {newest}")
            return newest
        try:
            answer = input(
                "  Entrée quand c'est téléchargé, ou colle le chemin : "
            ).strip().strip("'\"")
        except EOFError:
            raise Failure("Interrompu.")
        if answer:
            candidate = Path(answer).expanduser()
            if candidate.exists():
                return candidate
            print(f"{BAD} introuvable : {candidate}")


def _step(number: int, title: str) -> None:
    print()
    print(f"\033[1m── {number}. {title}\033[0m")


def _gh_available(repo: str) -> bool:
    """`gh` installé et authentifié : on pourra poser les secrets nous-mêmes."""
    try:
        subprocess.run(["gh", "auth", "status"], capture_output=True, check=True)
    except (FileNotFoundError, subprocess.CalledProcessError):
        return False
    return True


def _gh_set_secret(repo: str, name: str, value: str) -> bool:
    """Écrit un secret via `gh`, la valeur passant par l'entrée standard.

    Jamais en argument de ligne de commande : les arguments sont visibles
    dans la liste des processus de la machine.
    """
    try:
        subprocess.run(
            ["gh", "secret", "set", name, "--repo", repo],
            input=value.encode(),
            capture_output=True,
            check=True,
        )
        return True
    except (FileNotFoundError, subprocess.CalledProcessError) as error:
        detail = getattr(error, "stderr", b"").decode(errors="replace").strip()
        print(f"{BAD} {name} : {detail or error}")
        return False


def cmd_go(args: argparse.Namespace) -> int:
    """Déroule toute la préparation, en attendant l'utilisateur à chaque porte."""
    folder: Path = args.out
    repo: str = args.repo

    print("\033[1mPréparation de la publication iOS d'Eurêka\033[0m")
    print("Trois passages sur le portail Apple, le reste est automatique.")
    print(f"Dépôt visé : {repo}")

    # ------------------------------------------------------------ 1. CSR
    _step(1, "Clé privée et demande de certificat")
    key = folder / "dist.key"
    if key.exists():
        print(f"{OK} déjà faite : {folder / 'dist.csr'}")
    else:
        cmd_csr(argparse.Namespace(
            out=folder, email=args.email, name="Eureka Distribution",
            country="FR", force=False, quiet=True,
        ))

    # ---------------------------------------------------- 2. Certificat
    _step(2, "Certificat de distribution")
    p12 = folder / "dist.p12"
    if p12.exists():
        print(f"{OK} déjà assemblé : {p12}")
    else:
        print("  Ouvre : https://developer.apple.com/account/resources/certificates/add")
        print("  • Type : « Apple Distribution »  (PAS « iOS Distribution »)")
        print(f"  • Téléverse : {folder / 'dist.csr'}")
        print("  • Puis Download.")
        cer = _watch_for(["*.cer"], time.time() - 300)
        cmd_p12(argparse.Namespace(out=folder, cer=cer))

    # ------------------------------------------------------- 3. Profil
    _step(3, "Profil d'approvisionnement")
    print("  Ouvre : https://developer.apple.com/account/resources/profiles/add")
    print("  • Type : « App Store Connect », sous Distribution")
    print(f"  • App ID : {project_bundle_id()}")
    print("  • Certificat : celui qui vient d'être créé")
    print("  • Nomme-le, puis Download.")
    profile = _watch_for(["*.mobileprovision"], time.time() - 300)

    # ------------------------------------------------------ 4. Clé d'API
    _step(4, "Clé d'API App Store Connect")
    print("  Ouvre : https://appstoreconnect.apple.com/access/integrations/api")
    print("  • Onglet « Team Keys » → + → rôle « App Manager »")
    print("  • Télécharge le .p8 — il n'est téléchargeable qu'une seule fois.")
    asc_key = _watch_for(["AuthKey_*.p8"], time.time() - 600)
    issuer = input("  Colle l'Issuer ID (l'UUID en haut de la page) : ").strip()
    if not issuer:
        raise Failure("L'Issuer ID est indispensable au téléversement.")

    # --------------------------------------------------- 5. Vérification
    _step(5, "Contrôle de cohérence")
    password = password_from(f"  Mot de passe de {p12.name} : ")
    os.environ["P12_PASSWORD"] = password
    status = cmd_check(argparse.Namespace(
        out=folder, p12=p12, profile=profile, asc_key=asc_key,
    ))
    if status != 0:
        print()
        print("Corrige les points ci-dessus, puis relance la même commande :")
        print("  python3 tool/ios_signing.py go")
        return status

    # -------------------------------------------------------- 6. Secrets
    _step(6, "Dépôt des secrets")
    key_id_match = re.fullmatch(r"AuthKey_([A-Z0-9]{10})\.p8", asc_key.name)
    values: dict[str, str] = {
        "IOS_DIST_CERT_P12_BASE64": base64.b64encode(p12.read_bytes()).decode(),
        "IOS_DIST_CERT_PASSWORD": password,
        "IOS_PROVISIONING_PROFILE_BASE64":
            base64.b64encode(profile.read_bytes()).decode(),
        "IOS_TEAM_ID": (read_profile(profile).get("TeamIdentifier") or [""])[0],
        "ASC_KEY_ID": key_id_match.group(1) if key_id_match else
            input("  Key ID (dix caractères) : ").strip(),
        "ASC_ISSUER_ID": issuer,
        "ASC_PRIVATE_KEY_BASE64":
            base64.b64encode(asc_key.read_bytes()).decode(),
    }

    if _gh_available(repo):
        print(f"  `gh` est authentifié : je dépose les secrets dans {repo}.")
        failures = [n for n, v in values.items() if not _gh_set_secret(repo, n, v)]
        if failures:
            raise Failure(f"Secrets non déposés : {', '.join(failures)}")
        for name in values:
            print(f"{OK} {name}")
        print()
        print("Tout est en place. Dernière étape, dans le navigateur :")
        print(f"  https://github.com/{repo}/actions/workflows/testflight.yml")
        print("  → Run workflow")
        return 0

    out_dir = folder / "secrets"
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, value in values.items():
        target = out_dir / f"{name}.txt"
        target.write_text(value)
        target.chmod(0o600)
    print(f"{WARN} `gh` n'est pas installé ou pas connecté.")
    print()
    print(f"  Les sept valeurs sont prêtes dans {out_dir},")
    print("  un fichier par secret, nommé exactement comme lui. À coller dans")
    print(f"  https://github.com/{repo}/settings/secrets/actions")
    print()
    print("  Pour éviter ces sept copier-coller, installe `gh` — sans")
    print("  Homebrew et sans administrateur — puis reprends ici même :")
    print("      python3 tool/ios_signing.py install-gh")
    print("      gh auth login")
    print("      python3 tool/ios_signing.py push-secrets")
    return 0


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def _der_to_raw(der: bytes) -> bytes:
    """Convertit une signature ECDSA du format DER au format brut R||S.

    `openssl dgst -sign` produit une SEQUENCE DER de deux entiers, alors
    qu'un JWT ES256 attend les deux coordonnées concaténées, sur 32 octets
    chacune. Sans cette conversion, Apple rejette le jeton.
    """
    if not der or der[0] != 0x30:
        raise Failure("Signature inattendue : séquence DER absente.")
    index = 2
    if der[1] & 0x80:  # longueur sur plusieurs octets
        index = 2 + (der[1] & 0x7F)

    numbers: list[int] = []
    for _ in range(2):
        if der[index] != 0x02:
            raise Failure("Signature inattendue : entier DER absent.")
        length = der[index + 1]
        start = index + 2
        numbers.append(int.from_bytes(der[start:start + length], "big"))
        index = start + length
    return b"".join(n.to_bytes(32, "big") for n in numbers)


def asc_token(key_path: Path, key_id: str, issuer_id: str) -> str:
    """Fabrique un jeton JWT ES256 pour l'API App Store Connect."""
    import json
    import time

    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    now = int(time.time())
    payload = {
        "iss": issuer_id,
        "iat": now,
        # Apple refuse toute validité supérieure à vingt minutes.
        "exp": now + 600,
        "aud": "appstoreconnect-v1",
    }
    signing_input = ".".join(
        _b64url(json.dumps(part, separators=(",", ":")).encode())
        for part in (header, payload)
    )
    der = run(
        ["openssl", "dgst", "-sha256", "-sign", str(key_path), "-binary"],
        stdin=signing_input.encode(),
    )
    return f"{signing_input}.{_b64url(_der_to_raw(der))}"


def cmd_check_asc(args: argparse.Namespace) -> int:
    """Interroge l'API App Store Connect pour valider les identifiants.

    `altool --list-providers` n'accepte pas l'authentification par clé
    d'API : le seul test fiable est d'appeler l'API directement. Aucune
    dépendance au-delà d'openssl et de la bibliothèque standard.
    """
    import json
    import urllib.error
    import urllib.request

    key_path: Path = args.asc_key
    if not key_path.exists():
        raise Failure(f"Clé introuvable : {key_path}")
    match = re.fullmatch(r"AuthKey_([A-Z0-9]{10})\.p8", key_path.name)
    key_id = args.key_id or (match.group(1) if match else None)
    if not key_id:
        raise Failure(
            "Impossible de déduire le Key ID du nom de fichier ; "
            "le passer avec --key-id."
        )

    print(f"Key ID    : {key_id}")
    print(f"Issuer ID : {args.issuer}")
    print()

    token = asc_token(key_path, key_id, args.issuer)
    request = urllib.request.Request(
        "https://api.appstoreconnect.apple.com/v1/apps?limit=10",
        headers={"Authorization": f"Bearer {token}"},
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = json.load(response)
    except urllib.error.HTTPError as error:
        body = error.read().decode(errors="replace")
        print(f"{BAD} Apple refuse ces identifiants (HTTP {error.code}).")
        try:
            for item in json.loads(body).get("errors", []):
                print(f"    {item.get('title')} — {item.get('detail')}")
        except ValueError:
            print(f"    {body[:400]}")
        print()
        print("  Causes, par ordre de fréquence :")
        print("   1. l'Issuer ID n'est pas celui de l'onglet « Team Keys »")
        print("      de appstoreconnect.apple.com/access/integrations/api ;")
        print("   2. la clé a été révoquée, ou appartient à une autre équipe ;")
        print("   3. le .p8 fourni n'est pas celui de ce Key ID.")
        return 1
    except urllib.error.URLError as error:
        raise Failure(f"Appel impossible : {error.reason}")

    apps = payload.get("data", [])
    print(f"{OK} Apple accepte ces identifiants.")
    print(f"{OK} {len(apps)} application(s) visible(s) :")
    for app in apps:
        attributes = app.get("attributes", {})
        print(f"    • {attributes.get('name')} — {attributes.get('bundleId')}")

    if getattr(args, "probe_upload", False):
        _probe_privileges(token, apps)
    if getattr(args, "builds", None):
        _list_builds(token, apps, args.builds)
    return 0


def _asc_get(token: str, path: str):
    """Appelle l'API en lecture et renvoie la charge utile, ou None."""
    import json
    import urllib.error
    import urllib.request

    request = urllib.request.Request(
        f"https://api.appstoreconnect.apple.com{path}",
        headers={"Authorization": f"Bearer {token}"},
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        print(f"{BAD} HTTP {error.code} sur {path}")
        return None
    except urllib.error.URLError as error:
        print(f"{BAD} Appel impossible : {error.reason}")
        return None


def _list_builds(token: str, apps: list, bundle_id: str) -> None:
    """Affiche l'état des derniers builds d'une application.

    Un build téléversé n'est pas un build installable : Apple le traite
    pendant quelques minutes, et tant que « processingState » vaut
    PROCESSING il n'apparaît chez aucun testeur. C'est la seule façon de
    distinguer « Apple travaille encore » de « Apple a rejeté ».
    """
    app = next(
        (a for a in apps if a.get("attributes", {}).get("bundleId") == bundle_id),
        None,
    )
    print()
    if app is None:
        print(f"{BAD} Aucune application pour {bundle_id}.")
        return
    name = app.get("attributes", {}).get("name")
    print(f"Builds de « {name} » ({bundle_id}) :")
    payload = _asc_get(
        token,
        f"/v1/builds?filter[app]={app['id']}&limit=5"
        "&sort=-uploadedDate&fields[builds]="
        "version,processingState,uploadedDate,expired",
    )
    if payload is None:
        return
    builds = payload.get("data", [])
    if not builds:
        print(f"  {BAD} Aucun build : rien n'est arrivé chez Apple.")
        return
    for build in builds:
        at = build.get("attributes", {})
        state = at.get("processingState")
        mark = OK if state == "VALID" else BAD
        expired = " (expiré)" if at.get("expired") else ""
        print(
            f"  {mark} build {at.get('version')} — {state}"
            f" — déposé le {at.get('uploadedDate')}{expired}"
        )
    print()
    print("  PROCESSING : Apple travaille encore, patienter.")
    print("  VALID      : installable ; s'il reste invisible, c'est côté")
    print("               TestFlight (groupe ou conformité export).")
    print("  INVALID    : Apple a rejeté le build, le courriel le détaille.")


def _asc_status(token: str, path: str) -> int:
    """Renvoie le code HTTP d'un appel en lecture sur l'API."""
    import urllib.error
    import urllib.request

    request = urllib.request.Request(
        f"https://api.appstoreconnect.apple.com{path}",
        headers={"Authorization": f"Bearer {token}"},
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.status
    except urllib.error.HTTPError as error:
        return error.code
    except urllib.error.URLError:
        return 0


def _probe_privileges(token: str, apps: list) -> None:
    """Situe le rôle de la clé quand le téléversement a été refusé.

    Lire la liste des applications ne demande aucun privilège particulier :
    une clé « Developer » y parvient aussi. Téléverser un build en demande.
    Trois appels en lecture, choisis pour leurs seuils d'accès différents,
    suffisent à encadrer le rôle sans rien écrire.
    """
    print()
    checks = [
        ("/v1/users?limit=1", "Comptes de l'équipe", "Admin"),
        ("/v1/builds?limit=1", "Builds existants", "App Manager ou Developer"),
    ]
    if apps:
        app_id = apps[0].get("id")
        checks.append(
            (f"/v1/apps/{app_id}/betaGroups?limit=1",
             "Groupes TestFlight", "App Manager"),
        )

    results = {}
    for path, label, needed in checks:
        status = _asc_status(token, path)
        results[label] = status
        mark = OK if status == 200 else BAD
        print(f"  {mark} {label:22} HTTP {status or '—'}  (demande : {needed})")

    print()
    if results.get("Comptes de l'équipe") == 200:
        print("  La clé a le rôle Admin : le rôle n'explique pas le refus.")
    elif results.get("Groupes TestFlight") == 200:
        print("  La clé atteint TestFlight : le rôle n'explique pas le refus.")
    else:
        print("  La clé ne voit ni les comptes ni les groupes TestFlight :")
        print("  elle a probablement le rôle « Developer », qui autorise la")
        print("  lecture mais pas le dépôt d'un build. Créer une clé « App")
        print("  Manager » ou « Admin » dans App Store Connect → Users and")
        print("  Access → Integrations, et remplacer les trois secrets.")


def _asc_post(token: str, path: str, body: dict) -> int:
    """Envoie une écriture à l'API et renvoie le code HTTP."""
    import json
    import urllib.error
    import urllib.request

    request = urllib.request.Request(
        f"https://api.appstoreconnect.apple.com{path}",
        data=json.dumps(body).encode(),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.status
    except urllib.error.HTTPError as error:
        detail = error.read().decode(errors="replace")
        print(f"{BAD} HTTP {error.code}")
        try:
            for item in json.loads(detail).get("errors", []):
                print(f"    {item.get('title')} — {item.get('detail')}")
        except ValueError:
            print(f"    {detail[:300]}")
        return error.code
    except urllib.error.URLError as error:
        print(f"{BAD} Appel impossible : {error.reason}")
        return 0


def _print_testers(token: str, internes: list, app_id: str = "",
                   resend: bool = False) -> None:
    """Affiche les testeurs de chaque groupe interne et leur état.

    Un testeur « invité » mais qui n'a pas accepté ne voit rien : c'est la
    cause la plus fréquente d'une application absente de TestFlight alors
    que tout est vert côté Apple.
    """
    for gid, nom, _ in internes:
        payload = _asc_get(
            token,
            f"/v1/betaGroups/{gid}/betaTesters?limit=20"
            "&fields[betaTesters]=email,firstName,lastName,inviteType,state",
        )
        if payload is None:
            print(f"  Testeurs de « {nom} » : lecture refusée.")
            continue
        testeurs = payload.get("data", [])
        print(f"\nTesteurs de « {nom} » ({len(testeurs)}) :")
        for tester in testeurs:
            at = tester.get("attributes", {})
            etat = at.get("state") or "état non communiqué"
            accepte = etat in ("INSTALLED", "ACCEPTED")
            mark = OK if accepte else BAD
            print(f"  {mark} {at.get('email')} — {etat}")
            if accepte or not resend or not app_id:
                continue
            # Invité mais jamais accepté : l'application reste invisible
            # dans TestFlight tant que le lien du courriel n'est pas suivi.
            # Renvoyer l'invitation coûte un courriel et refait un lien
            # valide, ce qui est plus sûr que de chercher l'ancien.
            status = _asc_post(
                token, "/v1/betaTesterInvitations",
                {"data": {
                    "type": "betaTesterInvitations",
                    "relationships": {
                        "app": {"data": {"type": "apps", "id": app_id}},
                        "betaTester": {"data": {
                            "type": "betaTesters", "id": tester["id"]}},
                    },
                }},
            )
            mark = OK if status in (200, 201, 204) else BAD
            print(f"    {mark} invitation renvoyée (HTTP {status or '—'})")


def cmd_testflight(args: argparse.Namespace) -> int:
    """Dit pourquoi un build valide n'apparaît pas chez un testeur.

    Un build « VALID » est traité par Apple, pas distribué pour autant :
    il faut encore qu'il soit rattaché à un groupe de test. Un groupe
    interne créé sans distribution automatique ne reçoit rien tant qu'on
    ne lui ajoute pas chaque build à la main.
    """
    key_path: Path = args.asc_key
    if not key_path.exists():
        raise Failure(f"Clé introuvable : {key_path}")
    match = re.fullmatch(r"AuthKey_([A-Z0-9]{10})\.p8", key_path.name)
    key_id = args.key_id or (match.group(1) if match else None)
    if not key_id:
        raise Failure("Key ID indéterminable ; le passer avec --key-id.")
    token = asc_token(key_path, key_id, args.issuer)

    apps = (_asc_get(token, "/v1/apps?limit=20") or {}).get("data", [])
    app = next(
        (a for a in apps
         if a.get("attributes", {}).get("bundleId") == args.bundle_id),
        None,
    )
    if app is None:
        raise Failure(f"Aucune application pour {args.bundle_id}.")
    app_id = app["id"]
    print(f"Application : {app['attributes'].get('name')} ({args.bundle_id})")

    builds = (_asc_get(
        token,
        f"/v1/builds?filter[app]={app_id}&limit=1&sort=-uploadedDate"
        "&fields[builds]=version,processingState",
    ) or {}).get("data", [])
    if not builds:
        raise Failure("Aucun build chez Apple.")
    build = builds[0]
    version = build["attributes"].get("version")
    state = build["attributes"].get("processingState")
    print(f"Dernier build : {version} — {state}")
    if state != "VALID":
        print(f"{BAD} Build non traité : rien à distribuer pour l'instant.")
        return 0

    groups = (_asc_get(
        token, f"/v1/apps/{app_id}/betaGroups?limit=20"
    ) or {}).get("data", [])
    print(f"\nGroupes de test ({len(groups)}) :")
    internes = []
    for group in groups:
        at = group.get("attributes", {})
        kind = "interne" if at.get("isInternalGroup") else "externe"
        auto = "distribution automatique" if at.get(
            "hasAccessToAllBuilds") else "ajout manuel des builds"
        print(f"  • {at.get('name')} — {kind}, {auto}")
        if at.get("isInternalGroup"):
            internes.append((group["id"], at.get("name"),
                             bool(at.get("hasAccessToAllBuilds"))))

    # Un refus de lecture n'est pas une absence : sans cette distinction,
    # une clé aux droits trop courts ferait conclure que le build n'est
    # rattaché à rien, et déclencherait un rattachement inutile.
    payload = _asc_get(
        token, f"/v1/builds/{build['id']}/betaGroups?limit=20"
    )
    if payload is None:
        print("\n  Rattachement du build : lecture refusée par Apple.")
        attached, lisible = [], False
    else:
        attached = payload.get("data", [])
        lisible = True
        noms = [g.get("attributes", {}).get("name") for g in attached]
        print(f"\nGroupes recevant le build {version} : "
              f"{', '.join(n for n in noms if n) or 'aucun'}")

    _print_testers(token, internes, app_id, args.resend_invite)

    manquants = [(gid, nom) for gid, nom, auto in internes
                 if not auto and gid not in {g['id'] for g in attached}]
    if not lisible:
        print(f"\n  Les groupes en distribution automatique reçoivent le "
              f"build sans intervention ; les autres, non — et le refus "
              f"ci-dessus empêche de savoir lesquels l'ont déjà.")
    if not manquants:
        if lisible:
            print(f"\n{OK} Tous les groupes internes reçoivent ce build.")
        print("  S'il reste invisible : actualiser TestFlight sur le "
              "téléphone (onglet « Apps », tirer vers le bas), et vérifier "
              "que l'identifiant Apple du téléphone est bien celui du "
              "testeur ci-dessus.")
        return 0

    print(f"\n{BAD} Groupes internes qui ne reçoivent pas ce build :")
    for _, nom in manquants:
        print(f"    • {nom}")
    if not args.assign:
        print("\n  Relancer avec --assign pour l'y ajouter.")
        return 0

    for gid, nom in manquants:
        status = _asc_post(
            token, f"/v1/betaGroups/{gid}/relationships/builds",
            {"data": [{"type": "builds", "id": build["id"]}]},
        )
        mark = OK if status in (201, 204) else BAD
        print(f"  {mark} « {nom} » : ajout du build {version} "
              f"(HTTP {status or '—'})")
    return 0


def cmd_push_secrets(args: argparse.Namespace) -> int:
    """Dépose dans GitHub les secrets déjà écrits par l'assistant.

    Sert à reprendre après coup, quand `gh` n'était pas installé au moment
    où l'assistant est arrivé au bout : tout est déjà calculé, il ne reste
    qu'à l'envoyer. Aucun fichier Apple n'est redemandé.
    """
    folder: Path = args.out / "secrets"
    repo: str = args.repo
    if not folder.is_dir():
        raise Failure(
            f"{folder} n'existe pas. Lance d'abord : "
            "python3 tool/ios_signing.py go"
        )

    files = sorted(folder.glob("*.txt"))
    if not files:
        raise Failure(f"Aucun secret trouvé dans {folder}.")

    if not _gh_available(repo):
        raise Failure(
            "`gh` n'est pas installé ou pas connecté :\n"
            "    python3 tool/ios_signing.py install-gh\n"
            "    gh auth login"
        )

    print(f"Dépôt des {len(files)} secrets dans {repo}…")
    failures: list[str] = []
    for path in files:
        name = path.stem
        if _gh_set_secret(repo, name, path.read_text()):
            print(f"{OK} {name}")
        else:
            failures.append(name)
    if failures:
        raise Failure(f"Non déposés : {', '.join(failures)}")

    if args.keep:
        print(f"\n{WARN} Les valeurs restent en clair dans {folder}.")
    else:
        for path in files:
            path.unlink()
        folder.rmdir()
        # Une fois chez GitHub, les garder en clair sur le disque n'apporte
        # rien et ne fait qu'élargir la surface d'exposition.
        print(f"\n{OK} copies locales effacées ({folder})")

    print()
    print("Tout est en place. Dernière étape, dans le navigateur :")
    print(f"  https://github.com/{repo}/actions/workflows/testflight.yml")
    print("  → Run workflow")
    return 0


def cmd_install_gh(args: argparse.Namespace) -> int:
    """Installe la ligne de commande GitHub dans ~/bin, sans administrateur.

    Homebrew n'est pas toujours là, et l'installer pour un seul binaire est
    disproportionné. On récupère l'archive officielle et on la dépose dans
    le répertoire personnel.
    """
    import json
    import platform
    import urllib.request
    import zipfile

    system = platform.system()
    if system != "Darwin":
        raise Failure(f"Prévu pour macOS ; système détecté : {system}.")
    arch = "arm64" if platform.machine() == "arm64" else "amd64"

    with urllib.request.urlopen(
        "https://api.github.com/repos/cli/cli/releases/latest"
    ) as response:
        version = json.load(response)["tag_name"].lstrip("v")

    name = f"gh_{version}_macOS_{arch}"
    url = f"https://github.com/cli/cli/releases/download/v{version}/{name}.zip"
    print(f"Téléchargement de gh {version} ({arch})…")

    archive = Path.home() / ".cache" / "gh.zip"
    archive.parent.mkdir(parents=True, exist_ok=True)
    urllib.request.urlretrieve(url, archive)

    target_dir = Path.home() / "bin"
    target_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as bundle:
        with bundle.open(f"{name}/bin/gh") as source:
            binary = target_dir / "gh"
            binary.write_bytes(source.read())
    binary.chmod(0o755)
    archive.unlink(missing_ok=True)

    print(f"{OK} {binary}")
    if str(target_dir) not in os.environ.get("PATH", ""):
        print()
        print("  Ajoute ~/bin au PATH, une fois pour toutes :")
        print('      echo \'export PATH="$HOME/bin:$PATH"\' >> ~/.zshrc')
        print("      source ~/.zshrc")
    print()
    print("  Puis : gh auth login")
    return 0

# -------------------------------------------------------------------- main


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--out", type=Path, default=DEFAULT_DIR,
        help="dossier de travail (défaut : ios-signing/, non versionné)",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    csr = sub.add_parser("csr", help="créer la clé privée et la demande Apple")
    csr.add_argument("--email", required=True)
    csr.add_argument("--name", default="Eureka Distribution")
    csr.add_argument("--country", default="FR")
    csr.add_argument("--force", action="store_true")
    csr.set_defaults(func=cmd_csr)

    p12 = sub.add_parser("p12", help="assembler le .p12 depuis le certificat")
    p12.add_argument("--cer", type=Path, required=True)
    p12.set_defaults(func=cmd_p12)

    check = sub.add_parser("check", help="vérifier la cohérence de l'ensemble")
    check.add_argument("--p12", type=Path)
    check.add_argument("--profile", type=Path)
    check.add_argument("--asc-key", type=Path)
    check.set_defaults(func=cmd_check)

    secrets = sub.add_parser("secrets", help="afficher les valeurs à coller")
    secrets.add_argument("--p12", type=Path)
    secrets.add_argument("--profile", type=Path)
    secrets.add_argument("--asc-key", type=Path)
    secrets.add_argument(
        "--write-to", type=Path,
        help="écrire chaque secret dans un fichier de ce dossier",
    )
    secrets.set_defaults(func=cmd_secrets)

    go = sub.add_parser(
        "go", help="tout préparer de bout en bout (commande conseillée)"
    )
    go.add_argument("--email", default="contact@techlyb.com")
    go.add_argument("--repo", default="hsnsalhi/science")
    go.set_defaults(func=cmd_go)

    asc = sub.add_parser(
        "check-asc",
        help="vérifier les identifiants App Store Connect auprès d'Apple",
    )
    asc.add_argument("--asc-key", type=Path, required=True)
    asc.add_argument("--issuer", required=True)
    asc.add_argument("--key-id")
    asc.add_argument(
        "--probe-upload", action="store_true",
        help="situer le rôle de la clé quand le téléversement est refusé",
    )
    asc.add_argument(
        "--builds", metavar="BUNDLE_ID",
        help="afficher l'état des derniers builds de cette application",
    )
    asc.set_defaults(func=cmd_check_asc)

    tf = sub.add_parser(
        "testflight",
        help="dire pourquoi un build valide n'apparaît pas chez un testeur",
    )
    tf.add_argument("--asc-key", type=Path, required=True)
    tf.add_argument("--issuer", required=True)
    tf.add_argument("--key-id")
    tf.add_argument("--bundle-id", default="com.techlyb.eureka")
    tf.add_argument(
        "--resend-invite", action="store_true",
        help="renvoyer son invitation à un testeur qui n'a jamais accepté",
    )
    tf.add_argument(
        "--assign", action="store_true",
        help="rattacher le build aux groupes internes qui ne l'ont pas",
    )
    tf.set_defaults(func=cmd_testflight)

    push = sub.add_parser(
        "push-secrets",
        help="déposer dans GitHub les secrets déjà préparés par « go »",
    )
    push.add_argument("--repo", default="hsnsalhi/science")
    push.add_argument(
        "--keep", action="store_true",
        help="conserver les copies locales après le dépôt",
    )
    push.set_defaults(func=cmd_push_secrets)

    install = sub.add_parser(
        "install-gh", help="installer la ligne de commande GitHub sans Homebrew"
    )
    install.set_defaults(func=cmd_install_gh)

    args = parser.parse_args(argv)
    try:
        return int(args.func(args))
    except Failure as error:
        print(f"\nErreur : {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
