#!/usr/bin/env python3
"""Envoie un AAB sur Google Play, sans dépendance ni action tierce.

L'API Google Play Developer se pilote avec trois requêtes HTTP et un jeton
OAuth, que `openssl` sait signer. Passer par une action GitHub tierce
reviendrait à confier le compte de service — qui a le droit de publier — à
du code qu'on ne relit pas. Le fichier ci-dessous tient en deux cents
lignes et n'utilise que la bibliothèque standard.

    python3 tool/play_upload.py verifier --compte compte.json
    python3 tool/play_upload.py envoyer  --compte compte.json \
        --aab build/app/outputs/bundle/release/app-release.aab \
        --piste internal --notes "Corrections de la semaine."

Le fichier du compte de service ne doit jamais être versionné ni collé
ailleurs que dans un secret GitHub. Voir docs/ANDROID.md.
"""

from __future__ import annotations

import argparse
import base64
import json
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"
TELEVERSEMENT = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications"
JETON = "https://oauth2.googleapis.com/token"
PORTEE = "https://www.googleapis.com/auth/androidpublisher"

OK = "  ✓"
BAD = "  ✗"


class Echec(Exception):
    """Une erreur qu'il faut montrer à l'utilisateur, pas une trace Python."""


def _b64url(donnees: bytes) -> str:
    return base64.urlsafe_b64encode(donnees).rstrip(b"=").decode()


def _jeton_acces(compte: dict) -> str:
    """Échange la clé du compte de service contre un jeton d'accès.

    La signature RS256 est faite par `openssl` : ajouter une dépendance
    Python pour une seule signature ne se justifie pas, et `openssl` est
    présent partout où ce script peut tourner.
    """
    maintenant = int(time.time())
    entete = {"alg": "RS256", "typ": "JWT"}
    charge = {
        "iss": compte["client_email"],
        "scope": PORTEE,
        "aud": JETON,
        "iat": maintenant,
        # Google refuse toute validité supérieure à une heure.
        "exp": maintenant + 3600,
    }
    a_signer = ".".join(
        _b64url(json.dumps(p, separators=(",", ":")).encode()) for p in (entete, charge)
    )

    # openssl lit les données à signer sur son entrée standard : la clé doit
    # donc passer par un fichier. Il est créé avec les droits restreints de
    # `mkstemp` et effacé quoi qu'il arrive.
    with tempfile.NamedTemporaryFile("w", suffix=".pem", delete=False) as fichier:
        fichier.write(compte["private_key"])
        chemin_cle = fichier.name
    try:
        resultat = subprocess.run(
            ["openssl", "dgst", "-sha256", "-sign", chemin_cle],
            input=a_signer.encode(),
            capture_output=True,
        )
    finally:
        Path(chemin_cle).unlink(missing_ok=True)

    if resultat.returncode != 0:
        # Le message d'openssl cite le fichier temporaire, déjà effacé et
        # sans intérêt pour qui lit : on garde la cause, pas le chemin.
        detail = resultat.stderr.decode(errors="replace").strip()
        detail = re.sub(r"\s*from /tmp/\S+", "", detail)
        raise Echec(
            "openssl n'a pas pu signer le jeton : le champ private_key du "
            f"compte de service est inutilisable.\n{detail}"
        )

    assertion = f"{a_signer}.{_b64url(resultat.stdout)}"
    corps = urllib.parse.urlencode(
        {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": assertion,
        }
    ).encode()
    try:
        with urllib.request.urlopen(JETON, data=corps, timeout=30) as reponse:
            return json.load(reponse)["access_token"]
    except urllib.error.HTTPError as erreur:
        detail = erreur.read().decode(errors="replace")
        raise Echec(
            f"Google refuse la clé du compte de service (HTTP {erreur.code}).\n"
            f"{detail}\n"
            "Vérifier que l'API Google Play Android Developer est activée et "
            "que le compte a été invité dans la console Play."
        ) from erreur


def _appel(
    methode: str,
    url: str,
    jeton: str,
    *,
    corps: bytes | None = None,
    type_contenu: str = "application/json",
) -> dict:
    requete = urllib.request.Request(url, data=corps, method=methode)
    requete.add_header("Authorization", f"Bearer {jeton}")
    if corps is not None:
        requete.add_header("Content-Type", type_contenu)
        requete.add_header("Content-Length", str(len(corps)))
    try:
        with urllib.request.urlopen(requete, timeout=600) as reponse:
            brut = reponse.read()
            return json.loads(brut) if brut else {}
    except urllib.error.HTTPError as erreur:
        detail = erreur.read().decode(errors="replace")
        raise Echec(f"{methode} {url.split('?')[0]} → HTTP {erreur.code}\n{detail}") from erreur


def _compte(chemin: Path) -> dict:
    if not chemin.exists():
        raise Echec(f"{chemin} est introuvable.")
    try:
        compte = json.loads(chemin.read_text(encoding="utf-8"))
    except json.JSONDecodeError as erreur:
        raise Echec(f"{chemin} n'est pas un JSON valide : {erreur}") from erreur
    for champ in ("client_email", "private_key", "type"):
        if champ not in compte:
            raise Echec(f"Le champ « {champ} » manque dans {chemin}.")
    if compte["type"] != "service_account":
        raise Echec(f"{chemin} n'est pas une clé de compte de service.")
    return compte


def verifier(args: argparse.Namespace) -> None:
    """Contrôle les droits sans rien publier."""
    compte = _compte(Path(args.compte))
    print(f"Compte de service : {compte['client_email']}")
    jeton = _jeton_acces(compte)
    print(f"{OK} Jeton d'accès obtenu.")

    edition = _appel("POST", f"{API}/{args.paquet}/edits", jeton, corps=b"{}")
    print(f"{OK} Édition ouverte sur {args.paquet} : {edition['id']}")
    _appel("DELETE", f"{API}/{args.paquet}/edits/{edition['id']}", jeton)
    print(f"{OK} Édition refermée. Les droits de publication sont en place.")


def envoyer(args: argparse.Namespace) -> None:
    aab = Path(args.aab)
    if not aab.exists():
        raise Echec(f"{aab} est introuvable.")
    octets = aab.read_bytes()
    print(f"Paquet : {aab.name} ({len(octets) / 1e6:.1f} Mo)")

    compte = _compte(Path(args.compte))
    jeton = _jeton_acces(compte)

    edition = _appel("POST", f"{API}/{args.paquet}/edits", jeton, corps=b"{}")
    identifiant = edition["id"]
    print(f"{OK} Édition {identifiant} ouverte.")

    envoi = _appel(
        "POST",
        f"{TELEVERSEMENT}/{args.paquet}/edits/{identifiant}/bundles?uploadType=media",
        jeton,
        corps=octets,
        type_contenu="application/octet-stream",
    )
    code = envoi["versionCode"]
    print(f"{OK} Paquet déposé, code de version {code}.")

    notes = [{"language": args.langue, "text": args.notes}] if args.notes else []
    _appel(
        "PUT",
        f"{API}/{args.paquet}/edits/{identifiant}/tracks/{args.piste}",
        jeton,
        corps=json.dumps(
            {
                "track": args.piste,
                "releases": [
                    {
                        "versionCodes": [str(code)],
                        "status": "completed",
                        "releaseNotes": notes,
                    }
                ],
            }
        ).encode(),
    )
    print(f"{OK} Piste « {args.piste} » mise à jour.")

    _appel("POST", f"{API}/{args.paquet}/edits/{identifiant}:commit", jeton)
    print(f"{OK} Édition validée. Le build apparaît dans la console sous quelques minutes.")


def main() -> None:
    analyseur = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    analyseur.add_argument("--paquet", default="com.techlyb.eureka")
    sous = analyseur.add_subparsers(dest="commande", required=True)

    p_verifier = sous.add_parser("verifier", help="contrôler les droits, sans publier")
    p_verifier.add_argument("--compte", required=True)
    p_verifier.set_defaults(fonction=verifier)

    p_envoyer = sous.add_parser("envoyer", help="déposer un AAB sur une piste")
    p_envoyer.add_argument("--compte", required=True)
    p_envoyer.add_argument("--aab", required=True)
    p_envoyer.add_argument("--piste", default="internal")
    p_envoyer.add_argument("--notes", default="")
    p_envoyer.add_argument("--langue", default="fr-FR")
    p_envoyer.set_defaults(fonction=envoyer)

    args = analyseur.parse_args()
    try:
        args.fonction(args)
    except Echec as erreur:
        print(f"\n{BAD} {erreur}", file=sys.stderr)
        raise SystemExit(1) from erreur


if __name__ == "__main__":
    main()
