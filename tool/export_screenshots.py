#!/usr/bin/env python3
"""Décline les captures d'écran de l'application pour le site et le partage.

Les captures elles-mêmes sont produites par l'application :

    flutter test test/screenshots --update-goldens

Elles sortent aux dimensions exactes exigées par App Store Connect et sont
donc téléversables telles quelles. Ce script n'en fabrique aucune : il les
réduit pour le web et compose l'image de partage.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
GOLDENS = ROOT / "test/screenshots/goldens"
SITE_SCREENS = ROOT / "site/assets/screens"
FONT = ROOT / "assets/fonts/Nunito.ttf"

#: Largeur des captures servies par le site. Deux fois la taille d'affichage,
#: pour rester nettes sur un écran à haute densité.
WEB_WIDTH = 560

#: Captures montrées sur la page d'accueil, dans l'ordre.
SHOWCASE = [
    ("iphone-1-accueil", "L'accueil et l'objectif du jour"),
    ("iphone-2-chapitre", "Un chapitre, étape par étape"),
    ("iphone-3-lecon", "Des figures qu'on manipule"),
    ("iphone-4-exercice", "Chaque réponse est expliquée"),
]


def load_font(size: int, weight: int = 400) -> ImageFont.FreeTypeFont:
    """Charge Nunito à la graisse demandée, si la police variable le permet."""
    font = ImageFont.truetype(str(FONT), size)
    try:
        font.set_variation_by_axes([weight])
    except (AttributeError, OSError):
        pass  # FreeType sans support des axes : graisse par défaut.
    return font


def export_web() -> int:
    SITE_SCREENS.mkdir(parents=True, exist_ok=True)
    count = 0
    for name, _ in SHOWCASE:
        source = GOLDENS / f"{name}.png"
        if not source.exists():
            raise SystemExit(
                f"{source} manquant — lancer d'abord :\n"
                "  flutter test test/screenshots --update-goldens"
            )
        image = Image.open(source)
        height = round(WEB_WIDTH * image.height / image.width)
        image.resize((WEB_WIDTH, height), Image.LANCZOS).save(
            SITE_SCREENS / f"{name}.png", "PNG", optimize=True
        )
        count += 1
    return count


def export_social() -> Path:
    """Compose l'image affichée quand le lien est partagé (1200 × 630)."""
    width, height = 1200, 630
    card = Image.new("RGB", (width, height))
    pixels = card.load()
    for y in range(height):
        for x in range(width):
            t = (x / width + y / height) / 2
            pixels[x, y] = (
                round(60 + 40 * t),
                round(66 + 30 * t),
                round(150 + 45 * t),
            )

    draw = ImageDraw.Draw(card)
    # Coins arrondis comme sur un écran d'accueil : collée carrée, l'icône
    # se détache en rectangle pâle sur le fond.
    icon = Image.open(ROOT / "docs/app-icon.png").resize((132, 132), Image.LANCZOS)
    icon_mask = Image.new("L", icon.size, 0)
    ImageDraw.Draw(icon_mask).rounded_rectangle(
        [0, 0, icon.size[0] - 1, icon.size[1] - 1], radius=30, fill=255
    )
    card.paste(icon, (72, 96), icon_mask)

    draw.text((72, 258), "Eurêka", font=load_font(76, 800), fill=(255, 255, 255))
    draw.text(
        (72, 350),
        "Apprendre les sciences en s'amusant,\ndu primaire à l'université.",
        font=load_font(30, 500),
        fill=(222, 228, 255),
        spacing=10,
    )
    draw.text(
        (72, 470),
        "Gratuit  ·  Sans publicité  ·  Sans compte  ·  Hors-ligne",
        font=load_font(24, 700),
        fill=(255, 196, 92),
    )

    # Deux captures en biais sur la droite, pour montrer l'application.
    x = 700
    for name in ("iphone-1-accueil", "iphone-4-exercice"):
        shot = Image.open(GOLDENS / f"{name}.png")
        shot = shot.resize((232, round(232 * shot.height / shot.width)), Image.LANCZOS)
        rounded = Image.new("RGBA", shot.size, (0, 0, 0, 0))
        mask = Image.new("L", shot.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, shot.size[0] - 1, shot.size[1] - 1], radius=22, fill=255
        )
        rounded.paste(shot, (0, 0), mask)
        card.paste(rounded, (x, 92), rounded)
        x += 250

    target = ROOT / "site/assets/social.png"
    card.save(target, "PNG", optimize=True)
    return target


def main() -> int:
    count = export_web()
    social = export_social()
    print(f"Site    : {count} captures dans {SITE_SCREENS.relative_to(ROOT)}")
    print(f"Partage : {social.relative_to(ROOT)}")
    print(
        "App Store : les fichiers de "
        f"{GOLDENS.relative_to(ROOT)} sont déjà aux dimensions exigées."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
