#!/usr/bin/env python3
"""Génère les icônes d'application d'Eurêka, iOS et Android.

L'icône est **calculée en 3D** par `render3d` : surfaces implicites
parcourues par lancer de rayon, éclairage de studio, ombres douces,
occlusion ambiante. Rien n'est peint à la main, donc changer de concept, de
couleur ou d'angle ne demande qu'une ligne — et toutes les tailles restent
cohérentes entre elles.

    python3 tool/generate_icons.py                  # concept par défaut
    python3 tool/generate_icons.py --concept orbite # un autre
    python3 tool/generate_icons.py --list           # les concepts existants

Les tailles dérivent toutes d'un même rendu de 1024 px réduit au filtre de
Lanczos : rendre chaque taille séparément donnerait des icônes légèrement
différentes les unes des autres, ce qui se voit quand le système les affiche
côte à côte.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))

import icon_concepts  # noqa: E402  (le chemin doit être posé avant)
import render3d  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent

#: Concept retenu pour l'application.
DEFAULT_CONCEPT = "atome-croise"

#: Taille du rendu de référence, dont toutes les autres sont réduites.
MASTER_SIZE = 1024

#: En dessous de ce seuil, un léger renforcement compense le flou de la
#: réduction : sans lui, l'icône de 20 px paraît laiteuse.
SHARPEN_BELOW = 72

# Densités Android : taille de l'icône héritée, puis du calque adaptatif.
ANDROID_DENSITIES = {
    "mdpi": (48, 108),
    "hdpi": (72, 162),
    "xhdpi": (96, 216),
    "xxhdpi": (144, 324),
    "xxxhdpi": (192, 432),
}

#: Taille logique du logo de l'écran de lancement, en points.
LAUNCH_POINTS = 160

#: Part du calque adaptatif réellement visible : le masque du système rogne
#: jusqu'aux 66 dp centraux d'un calque de 108 dp.
ADAPTIVE_SAFE = 66 / 108


def downscale(master: Image.Image, size: int) -> Image.Image:
    out = master.resize((size, size), Image.LANCZOS)
    if size < SHARPEN_BELOW:
        out = out.filter(ImageFilter.UnsharpMask(radius=0.6, percent=55, threshold=0))
    return out


def write_ios(master: Image.Image) -> int:
    """Remplace les PNG de l'AppIcon.appiconset, en gardant son Contents.json."""
    icon_set = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((icon_set / "Contents.json").read_text())
    written = 0
    for entry in contents["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        # « 20x20 » et « @3x » donnent 60 px.
        side = float(entry["size"].split("x")[0])
        pixels = round(side * float(entry["scale"].rstrip("x")))
        # iOS refuse la transparence et le canal alpha sur les icônes.
        downscale(master, pixels).convert("RGB").save(icon_set / filename, "PNG")
        written += 1
    return written


def write_android(master: Image.Image, scene: render3d.Scene) -> int:
    """Écrit les icônes héritées et les deux calques de l'icône adaptative."""
    res = ROOT / "android/app/src/main/res"
    written = 0

    # Le sujet seul, détouré, pour le calque avant.
    subject = Image.fromarray(
        render3d.render(scene, 512, supersample=3, with_background=False),
        mode="RGBA",
    )

    for density, (legacy, adaptive) in ANDROID_DENSITIES.items():
        folder = res / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)

        downscale(master, legacy).convert("RGB").save(
            folder / "ic_launcher.png", "PNG"
        )

        # Calque avant : sujet réduit à la zone sûre, centré sur fond
        # transparent.
        inner = round(adaptive * ADAPTIVE_SAFE)
        layer = Image.new("RGBA", (adaptive, adaptive), (0, 0, 0, 0))
        layer.paste(
            subject.resize((inner, inner), Image.LANCZOS),
            ((adaptive - inner) // 2, (adaptive - inner) // 2),
        )
        layer.save(folder / "ic_launcher_foreground.png", "PNG")

        # Calque arrière : le dégradé, et non un aplat.
        Image.fromarray(render3d.render_background(scene, adaptive)).save(
            folder / "ic_launcher_background.png", "PNG"
        )
        written += 3

    (res / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (res / "mipmap-anydpi-v26/ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        "</adaptive-icon>\n"
    )
    # L'ancienne couleur de fond n'a plus d'emploi : le dégradé la remplace.
    legacy_color = res / "values/ic_launcher_background.xml"
    if legacy_color.exists():
        legacy_color.unlink()
    return written + 1


def write_launch_screen(scene: render3d.Scene) -> int:
    """Écrit le logo de l'écran de lancement iOS, en 1x, 2x et 3x.

    Le sujet est détouré : c'est le storyboard qui pose le fond, avec la
    couleur échantillonnée dans l'icône pour que les deux soient raccord et
    qu'aucune bascule de couleur ne se voie au démarrage.
    """
    folder = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    subject = Image.fromarray(
        render3d.render(scene, LAUNCH_POINTS * 3, supersample=2,
                        with_background=False),
        mode="RGBA",
    )
    for scale in (1, 2, 3):
        size = LAUNCH_POINTS * scale
        suffix = "" if scale == 1 else f"@{scale}x"
        subject.resize((size, size), Image.LANCZOS).save(
            folder / f"LaunchImage{suffix}.png", "PNG"
        )

    # Le storyboard déclare la taille logique de l'image : si elle ne
    # correspond pas au fichier, iOS l'étire.
    storyboard = ROOT / "ios/Runner/Base.lproj/LaunchScreen.storyboard"
    text = storyboard.read_text()
    import re

    text = re.sub(
        r'<image name="LaunchImage" width="\d+" height="\d+"/>',
        f'<image name="LaunchImage" width="{LAUNCH_POINTS}" '
        f'height="{LAUNCH_POINTS}"/>',
        text,
    )
    storyboard.write_text(text)
    return 3


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--concept", default=DEFAULT_CONCEPT)
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args(argv)

    if args.list:
        for name in icon_concepts.CONCEPTS:
            print(name)
        return 0

    if args.concept not in icon_concepts.CONCEPTS:
        print(
            f"Concept inconnu : {args.concept}. "
            f"Disponibles : {', '.join(icon_concepts.CONCEPTS)}",
            file=sys.stderr,
        )
        return 2

    scene = icon_concepts.CONCEPTS[args.concept]()
    print(f"Rendu 3D du concept « {args.concept} » en {MASTER_SIZE} px…")
    master = Image.fromarray(render3d.render(scene, MASTER_SIZE, supersample=3))

    ios_count = write_ios(master)
    launch_count = write_launch_screen(scene)
    android_count = write_android(master, scene)

    preview = ROOT / "docs/app-icon.png"
    master.resize((512, 512), Image.LANCZOS).save(preview, "PNG")

    print(f"iOS     : {ios_count} icônes, {launch_count} images de lancement")
    print(f"Android : {android_count} fichiers")
    print(f"Aperçu  : {preview.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
