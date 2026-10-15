"""Les directions possibles pour l'icône d'Eurêka, décrites en 3D.

Chaque concept est une scène complète — géométrie, matériaux, fond — rendue
par `render3d`. Les regrouper ici permet de les comparer côte à côte, et de
n'en garder qu'une sans toucher au reste du projet.

Trois contraintes ont guidé chaque réglage :

* **Lisible à 20 px**, la taille utilisée par Réglages et Spotlight. Les
  traits fins et les petits détails y disparaissent, donc anneaux épais mais
  pas boursouflés, et jamais plus de trois masses distinctes.
* **Contraste fort** entre le sujet et le fond. Un sujet clair sur un fond
  pâle devient une tache grise une fois réduit.
* **Une marge généreuse.** Le système arrondit et rogne l'icône ; un sujet
  qui touche les bords est amputé.
"""

from __future__ import annotations

import math

import numpy as np

from render3d import Material, Scene, Shape, compose, rotation

#: Fond de marque : indigo profond vers violet. Volontairement soutenu.
BRAND_BG = ((0.05, 0.08, 0.48), (0.34, 0.17, 0.95))

PEARL = Material(color=(1.00, 1.00, 1.00), roughness=0.13, specular=1.45, rim=0.70)
GOLD = Material(color=(1.00, 0.67, 0.08), roughness=0.15, specular=1.35, rim=0.50)
AMBER = Material(color=(1.00, 0.78, 0.28), roughness=0.14, specular=1.35, rim=0.55)
SILVER = Material(color=(0.86, 0.90, 1.00), roughness=0.16, specular=1.25, rim=0.55)
TEAL = Material(color=(0.12, 0.80, 0.74), roughness=0.20, specular=1.10, rim=0.45)


def _ring(tilt: float, spin: float, big: float, small: float, material: int) -> Shape:
    """Anneau orienté : incliné autour de X, puis tourné autour de Z."""
    return Shape(
        "torus",
        (big, small),
        material=material,
        rotation=compose(rotation("x", tilt), rotation("z", spin)),
    )


def _point_on_ring(tilt: float, spin: float, big: float, angle: float):
    """Point du cercle guide d'un anneau, exprimé dans la scène."""
    local = np.array(
        [big * math.cos(math.radians(angle)), 0.0, big * math.sin(math.radians(angle))],
        dtype=np.float32,
    )
    world = compose(rotation("x", tilt), rotation("z", spin)) @ local
    return (float(world[0]), float(world[1]), float(world[2]))


def _bond(a, b, radius: float, material: int) -> Shape:
    """Liaison cylindrique entre deux centres, orientée correctement."""
    start = np.asarray(a, dtype=np.float32)
    end = np.asarray(b, dtype=np.float32)
    axis = end - start
    length = float(np.linalg.norm(axis))
    x = axis / length
    # Deux vecteurs quelconques orthogonaux à l'axe complètent la base.
    helper = np.array([0.0, 0.0, 1.0], dtype=np.float32)
    if abs(float(x @ helper)) > 0.9:
        helper = np.array([0.0, 1.0, 0.0], dtype=np.float32)
    y = np.cross(helper, x)
    y /= np.linalg.norm(y)
    z = np.cross(x, y)
    return Shape(
        "box",
        (length / 2, radius, radius, radius * 0.98),
        material=material,
        position=tuple(((start + end) / 2).tolist()),
        rotation=np.stack([x, y, z], axis=1).astype(np.float32),
    )


def atome_croise() -> Scene:
    """Noyau nacré, deux orbites dorées croisées en X large.

    Les anneaux sont presque vus par la tranche — ellipses longues et
    plates — et écartés de 70°, pour que la silhouette lise comme un atome
    et non comme un nœud. L'occlusion est réelle : une orbite passe devant
    le noyau, l'autre derrière, et chacune porte son ombre sur lui.
    """
    tilt, spin, big, small = 20.0, 35.0, 0.82, 0.062
    return Scene(
        shapes=[
            Shape("sphere", (0.38,), material=0),
            _ring(tilt, spin, big, small, 1),
            _ring(tilt, -spin, big, small, 1),
        ],
        materials=[PEARL, GOLD],
        background=BRAND_BG,
        zoom=0.40,
        shadow_strength=0.50,
    )


def atome_trois() -> Scene:
    """L'atome canonique : trois orbites à 60°, noyau ambré au centre.

    La forme que tout le monde reconnaît. Plus dense, donc plus fragile en
    tout petit : c'est ce que la planche de comparaison doit trancher.
    """
    tilt, big, small = 16.0, 0.82, 0.055
    return Scene(
        shapes=[
            Shape("sphere", (0.34,), material=0),
            _ring(tilt, 0.0, big, small, 1),
            _ring(tilt, 60.0, big, small, 1),
            _ring(tilt, -60.0, big, small, 1),
        ],
        materials=[AMBER, SILVER],
        background=BRAND_BG,
        zoom=0.40,
        shadow_strength=0.50,
    )


def orbite() -> Scene:
    """Une sphère et son anneau incliné. La silhouette la plus simple.

    L'électron est posé en haut à droite, nettement en avant de l'anneau.
    Calculé sur le cercle guide, il retombait sous la sphère et passait pour
    un défaut de modelé.
    """
    tilt, spin, big = 62.0, 20.0, 0.84
    return Scene(
        shapes=[
            Shape("sphere", (0.50,), material=0),
            _ring(tilt, spin, big, 0.060, 1),
            Shape("sphere", (0.125,), material=1, position=(0.60, 0.58, 0.36)),
        ],
        materials=[PEARL, GOLD],
        background=BRAND_BG,
        zoom=0.40,
        shadow_strength=0.50,
    )


def molecule() -> Scene:
    """Trois atomes liés : trois masses franches, donc robuste en tout petit."""
    liaison = Material(color=(0.80, 0.85, 1.00), roughness=0.3, specular=0.9, rim=0.3)
    top = (0.02, 0.54, 0.06)
    left = (-0.56, -0.34, -0.06)
    right = (0.58, -0.32, 0.04)
    return Scene(
        shapes=[
            _bond(top, left, 0.055, 3),
            _bond(top, right, 0.055, 3),
            Shape("sphere", (0.36,), material=0, position=top),
            Shape("sphere", (0.30,), material=1, position=left),
            Shape("sphere", (0.30,), material=2, position=right),
        ],
        materials=[PEARL, GOLD, TEAL, liaison],
        background=BRAND_BG,
        zoom=0.38,
        shadow_strength=0.50,
    )


CONCEPTS = {
    "atome-croise": atome_croise,
    "atome-trois": atome_trois,
    "orbite": orbite,
    "molecule": molecule,
}
