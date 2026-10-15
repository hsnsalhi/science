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

    args = parser.parse_args(argv)
    try:
        return int(args.func(args))
    except Failure as error:
        print(f"\nErreur : {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
