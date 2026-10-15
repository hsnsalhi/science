#!/usr/bin/env python3
"""Génère les icônes d'application d'Eurêka, iOS et Android.

L'icône est dessinée en code, comme la mascotte de l'application : un noyau
clair sur fond dégradé de marque, deux orbites inclinées et un électron doré.
Chaque taille est rendue indépendamment, avec des épaisseurs de trait
proportionnelles, puis réduite depuis un suréchantillonnage ×4 — un simple
redimensionnement du 1024 px donnerait des traits empâtés en 20 px.

Usage : python3 tool/generate_icons.py
"""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent

# Dégradé de marque (app_colors.dart : brand → un violet plus clair).
BRAND_TOP = (76, 111, 255)
BRAND_BOTTOM = (142, 123, 255)
NUCLEUS = (255, 255, 255)
ORBIT = (255, 255, 255)
ELECTRON = (255, 176, 32)

SUPERSAMPLE = 4


def _gradient(size: int) -> Image.Image:
    """Fond en dégradé diagonal, opaque (iOS refuse la transparence)."""
    base = Image.new("RGB", (size, size))
    pixels = base.load()
    for y in range(size):
        for x in range(size):
            # Diagonale haut-gauche → bas-droite.
            t = (x + y) / (2 * (size - 1)) if size > 1 else 0
            pixels[x, y] = (
                round(BRAND_TOP[0] + (BRAND_BOTTOM[0] - BRAND_TOP[0]) * t),
                round(BRAND_TOP[1] + (BRAND_BOTTOM[1] - BRAND_TOP[1]) * t),
                round(BRAND_TOP[2] + (BRAND_BOTTOM[2] - BRAND_TOP[2]) * t),
            )
    return base


def _draw_atom(image: Image.Image, size: int, scale: float) -> None:
    """Dessine le noyau, les deux orbites et l'électron sur `image`.

    `scale` est la part de l'icône occupée par le motif : plus petit pour
    Android adaptatif, dont le système rogne les bords.
    """
    draw = ImageDraw.Draw(image)
    cx = cy = size / 2
    unit = size * scale

    orbit_rx = unit * 0.46
    orbit_ry = unit * 0.185
    stroke = max(1, round(unit * 0.045))

    for tilt_deg in (32, -32):
        layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        layer_draw = ImageDraw.Draw(layer)
        layer_draw.ellipse(
            [cx - orbit_rx, cy - orbit_ry, cx + orbit_rx, cy + orbit_ry],
            outline=ORBIT + (235,),
            width=stroke,
        )
        # Rotation autour du centre : une ellipse ne se dessine pas inclinée.
        layer = layer.rotate(tilt_deg, resample=Image.BICUBIC, center=(cx, cy))
        image.alpha_composite(layer)

    nucleus_r = unit * 0.2
    draw.ellipse(
        [cx - nucleus_r, cy - nucleus_r, cx + nucleus_r, cy + nucleus_r],
        fill=NUCLEUS,
    )

    # Électron sur l'orbite inclinée à +32°, en haut à droite.
    angle = math.radians(-32)
    ex = cx + (orbit_rx * math.cos(angle) * 0.86)
    ey = cy + (orbit_rx * math.sin(angle) * 0.86)
    electron_r = unit * 0.075
    draw.ellipse(
        [ex - electron_r, ey - electron_r, ex + electron_r, ey + electron_r],
        fill=ELECTRON,
    )


def render(size: int, *, scale: float = 0.78, background: bool = True) -> Image.Image:
    """Rend une icône de `size` pixels de côté."""
    big = size * SUPERSAMPLE
    if background:
        image = _gradient(big).convert("RGBA")
    else:
        image = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    _draw_atom(image, big, scale)
    out = image.resize((size, size), Image.LANCZOS)
    return out


def write_ios() -> int:
    """Remplace les PNG de l'AppIcon.appiconset en gardant son Contents.json."""
    icon_set = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((icon_set / "Contents.json").read_text())
    written = 0
    for entry in contents["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        # "20x20" + "@3x" → 60 px.
        side = float(entry["size"].split("x")[0])
        pixels = round(side * float(entry["scale"].rstrip("x")))
        # iOS exige des icônes opaques et sans canal alpha.
        render(pixels).convert("RGB").save(icon_set / filename, "PNG")
        written += 1
    return written


# Android : densité → taille de l'icône héritée, puis du calque adaptatif.
ANDROID_DENSITIES = {
    "mdpi": (48, 108),
    "hdpi": (72, 162),
    "xhdpi": (96, 216),
    "xxhdpi": (144, 324),
    "xxxhdpi": (192, 432),
}


def write_android() -> int:
    """Écrit les icônes héritées et les calques de l'icône adaptative."""
    res = ROOT / "android/app/src/main/res"
    written = 0
    for density, (legacy, adaptive) in ANDROID_DENSITIES.items():
        folder = res / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        render(legacy).convert("RGB").save(folder / "ic_launcher.png", "PNG")
        # Calque avant de l'icône adaptative : le motif est réduit à 0,42 car
        # le système rogne jusqu'à 18 % de chaque bord selon le masque.
        render(adaptive, scale=0.42, background=False).save(
            folder / "ic_launcher_foreground.png", "PNG"
        )
        written += 2

    (res / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (res / "mipmap-anydpi-v26/ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        "</adaptive-icon>\n"
    )
    (res / "values").mkdir(parents=True, exist_ok=True)
    (res / "values/ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="ic_launcher_background">#4C6FFF</color>\n'
        "</resources>\n"
    )
    return written + 2


def main() -> None:
    ios_count = write_ios()
    android_count = write_android()
    preview = ROOT / "docs/app-icon.png"
    render(512).convert("RGB").save(preview, "PNG")
    print(f"iOS     : {ios_count} icônes")
    print(f"Android : {android_count} fichiers")
    print(f"Aperçu  : {preview.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
