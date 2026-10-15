"""Petit moteur de rendu 3D, pour dessiner l'icône d'Eurêka.

Les icônes sont réellement calculées en trois dimensions — surfaces
implicites parcourues par lancer de rayon (*raymarching*), éclairage de
studio, ombres portées douces, occlusion ambiante — et non imitées par des
dégradés plats. C'est ce qui donne l'occlusion correcte entre les anneaux et
le noyau : un anneau passe devant, l'autre derrière, et la lumière en tient
compte.

Tout tient dans ce fichier, sans moteur 3D externe : le rendu est vectorisé
avec numpy, et une icône de 1024 px se calcule en quelques dizaines de
secondes.
"""

from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

Array = np.ndarray
EPS = np.float32(1e-4)


# --------------------------------------------------------------- géométrie


def normalize(v: Array) -> Array:
    return v / np.linalg.norm(v, axis=-1, keepdims=True)


def rotation(axis: str, degrees: float) -> Array:
    """Matrice de rotation autour d'un axe, en degrés."""
    a = np.radians(degrees, dtype=np.float32)
    c, s = np.cos(a), np.sin(a)
    if axis == "x":
        m = [[1, 0, 0], [0, c, -s], [0, s, c]]
    elif axis == "y":
        m = [[c, 0, s], [0, 1, 0], [-s, 0, c]]
    else:
        m = [[c, -s, 0], [s, c, 0], [0, 0, 1]]
    return np.array(m, dtype=np.float32)


def compose(*rotations: Array) -> Array:
    out = np.eye(3, dtype=np.float32)
    for r in rotations:
        out = r @ out
    return out


@dataclass
class Shape:
    """Une primitive, placée et orientée dans la scène.

    `kind` vaut « sphere » (rayon), « torus » (grand et petit rayon) ou
    « box » (demi-dimensions et arrondi). `material` indexe la table des
    matériaux de la scène.
    """

    kind: str
    params: tuple[float, ...]
    material: int = 0
    position: tuple[float, float, float] = (0.0, 0.0, 0.0)
    rotation: Array = field(default_factory=lambda: np.eye(3, dtype=np.float32))

    def distance(self, p: Array) -> Array:
        """Distance signée des points `p` (N, 3) à la surface."""
        local = (p - np.asarray(self.position, dtype=np.float32)) @ self.rotation
        if self.kind == "sphere":
            return np.linalg.norm(local, axis=-1) - self.params[0]
        if self.kind == "torus":
            big, small = self.params
            # Distance au tore d'axe Y : on replie d'abord sur le cercle guide.
            q = np.stack(
                [
                    np.linalg.norm(local[..., [0, 2]], axis=-1) - big,
                    local[..., 1],
                ],
                axis=-1,
            )
            return np.linalg.norm(q, axis=-1) - small
        if self.kind == "box":
            half = np.asarray(self.params[:3], dtype=np.float32)
            radius = np.float32(self.params[3])
            q = np.abs(local) - half + radius
            outside = np.linalg.norm(np.maximum(q, 0.0), axis=-1)
            inside = np.minimum(np.max(q, axis=-1), 0.0)
            return outside + inside - radius
        raise ValueError(f"primitive inconnue : {self.kind}")


@dataclass
class Material:
    """Apparence d'une surface."""

    color: tuple[float, float, float]
    roughness: float = 0.25
    specular: float = 0.9
    rim: float = 0.35


@dataclass
class Scene:
    shapes: list[Shape]
    materials: list[Material]
    background: tuple[tuple[float, float, float], tuple[float, float, float]]
    light: tuple[float, float, float] = (-0.55, 0.72, 0.42)
    fill: tuple[float, float, float] = (0.6, -0.2, 0.5)
    bound: float = 1.35

    #: Ouverture de la caméra. Plus petit = sujet plus grand dans le cadre.
    zoom: float = 0.335
    #: Lumière ambiante de base.
    ambient: float = 0.26
    #: Ombre portée : intensité, décalage et flou, en fraction de l'image.
    shadow_strength: float = 0.42
    shadow_offset: float = 0.035
    shadow_blur: float = 0.045

    def distance(self, p: Array) -> Array:
        """Distance au plus proche objet."""
        out = self.shapes[0].distance(p)
        for shape in self.shapes[1:]:
            np.minimum(out, shape.distance(p), out=out)
        return out

    def distance_and_material(self, p: Array) -> tuple[Array, Array]:
        """Distance et indice de matériau du plus proche objet."""
        stack = np.stack([s.distance(p) for s in self.shapes], axis=0)
        index = np.argmin(stack, axis=0)
        ids = np.asarray([s.material for s in self.shapes], dtype=np.int32)
        return np.take_along_axis(stack, index[None], axis=0)[0], ids[index]


# ------------------------------------------------------------------ rendu


MAX_STEPS = 96
MAX_DIST = np.float32(6.0)


def _march(scene: Scene, origin: Array, direction: Array) -> Array:
    """Avance le long des rayons et renvoie la distance parcourue.

    Les rayons qui ont convergé ou divergé sont retirés du calcul à chaque
    pas : sans cette compaction, les trois quarts du travail porteraient sur
    des rayons déjà terminés.
    """
    count = direction.shape[0]
    travelled = np.zeros(count, dtype=np.float32)
    active = np.arange(count)
    for _ in range(MAX_STEPS):
        if active.size == 0:
            break
        p = origin[active] + direction[active] * travelled[active, None]
        d = scene.distance(p).astype(np.float32)
        travelled[active] += d
        alive = (d > EPS) & (travelled[active] < MAX_DIST)
        active = active[alive]
    return travelled


def _normals(scene: Scene, p: Array) -> Array:
    """Normale par différences centrées."""
    h = np.float32(6e-4)
    out = np.empty_like(p)
    for axis in range(3):
        offset = np.zeros(3, dtype=np.float32)
        offset[axis] = h
        out[:, axis] = scene.distance(p + offset) - scene.distance(p - offset)
    return normalize(out)


def _soft_shadow(scene: Scene, p: Array, light: Array) -> Array:
    """Ombre portée douce : la pénombre s'élargit avec la distance."""
    shadow = np.ones(p.shape[0], dtype=np.float32)
    t = np.full(p.shape[0], 0.02, dtype=np.float32)
    for _ in range(28):
        d = scene.distance(p + light * t[:, None]).astype(np.float32)
        shadow = np.minimum(shadow, 10.0 * d / np.maximum(t, 1e-3))
        t += np.clip(d, 0.008, 0.2)
        if np.all((shadow < 0.001) | (t > 3.0)):
            break
    return np.clip(shadow, 0.0, 1.0)


def _ambient_occlusion(scene: Scene, p: Array, n: Array) -> Array:
    """Assombrit les creux, là où la lumière ambiante pénètre mal."""
    total = np.zeros(p.shape[0], dtype=np.float32)
    weight = np.float32(1.0)
    for i in range(1, 6):
        step = np.float32(0.035 * i)
        d = scene.distance(p + n * step).astype(np.float32)
        total += weight * (step - d)
        weight *= np.float32(0.72)
    return np.clip(1.0 - 2.4 * total, 0.0, 1.0)


def _background(scene: Scene, size: int) -> Array:
    """Dégradé diagonal, halo derrière le sujet, vignettage sur les bords.

    Le fond est volontairement soutenu : un sujet clair sur un fond pâle
    perd tout contraste une fois réduit à 20 px, ce qui est précisément la
    taille où l'icône doit encore se reconnaître.
    """
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    t = ((x + y) / (2.0 * (size - 1)))[..., None]
    top = np.asarray(scene.background[0], dtype=np.float32)
    bottom = np.asarray(scene.background[1], dtype=np.float32)
    grad = top * (1 - t) + bottom * t

    cx = cy = (size - 1) / 2.0
    r = np.sqrt((x - cx) ** 2 + (y - cy) ** 2) / (size * 0.5)
    halo = np.clip(1.0 - r * 0.85, 0.0, 1.0)[..., None] ** 2
    vignette = np.clip(1.0 - 0.22 * np.clip(r - 0.55, 0.0, None) ** 1.5, 0.0, 1.0)
    return (grad + halo * 0.22) * vignette[..., None]


def _blur(a: Array, radius: int) -> Array:
    """Flou séparable, trois passes de moyenne glissante.

    Trois boîtes successives approchent une gaussienne d'assez près pour une
    ombre portée, pour une fraction du coût.
    """
    if radius < 1:
        return a
    kernel = np.ones(2 * radius + 1, dtype=np.float32)
    kernel /= kernel.sum()
    out = a.astype(np.float32)
    for _ in range(3):
        for axis in (0, 1):
            padded = np.pad(out, [(radius, radius) if i == axis else (0, 0)
                                  for i in range(out.ndim)], mode="edge")
            out = np.apply_along_axis(
                lambda m: np.convolve(m, kernel, mode="valid"), axis, padded
            )
    return out


def _tonemap(color: Array) -> Array:
    """Compression des hautes lumières, puis passage en sRGB."""
    color = np.clip(color, 0.0, None)
    # Courbe de Reinhard étendue : garde du contraste dans les ombres.
    mapped = color * (1.0 + color / 9.0) / (1.0 + color)
    return np.clip(mapped, 0.0, 1.0) ** (1.0 / 2.2)


def render_background(scene: Scene, size: int) -> Array:
    """Rend le fond seul, sans sujet ni ombre."""
    return (_tonemap(_background(scene, size)) * 255.0 + 0.5).astype(np.uint8)


def render(
    scene: Scene,
    size: int,
    *,
    supersample: int = 2,
    with_background: bool = True,
) -> Array:
    """Calcule l'image de la scène, en RGB 8 bits.

    Le sujet est rendu séparément du fond, avec sa couverture : cela donne
    des bords nets après réduction, et permet de glisser une ombre portée
    entre les deux. Avec `with_background=False`, seul le sujet est renvoyé,
    en RGBA — ce qu'exige le calque avant d'une icône adaptative Android.
    """
    n = size * supersample
    object_color = np.zeros((n * n, 3), dtype=np.float32)
    coverage = np.zeros(n * n, dtype=np.float32)

    origin = np.array([0.0, 0.0, 3.4], dtype=np.float32)
    px, py = np.meshgrid(
        (np.arange(n, dtype=np.float32) + 0.5) / n * 2 - 1,
        (np.arange(n, dtype=np.float32) + 0.5) / n * 2 - 1,
    )
    direction = normalize(
        np.stack(
            [px * scene.zoom, -py * scene.zoom, -np.ones_like(px)], axis=-1
        )
    ).reshape(-1, 3)
    origins = np.broadcast_to(origin, direction.shape)

    # Les rayons qui manquent la sphère englobante n'ont rien à calculer.
    b = np.einsum("ij,ij->i", origins, direction)
    c = np.einsum("ij,ij->i", origins, origins) - scene.bound ** 2
    candidates = np.flatnonzero(b * b - c > 0)

    if candidates.size:
        travelled = _march(scene, origins[candidates], direction[candidates])
        hit = travelled < MAX_DIST
        idx = candidates[hit]
        if idx.size:
            p = origins[idx] + direction[idx] * travelled[hit][:, None]
            normal = _normals(scene, p)
            _, material_id = scene.distance_and_material(p)

            light = normalize(np.asarray(scene.light, dtype=np.float32))
            fill = normalize(np.asarray(scene.fill, dtype=np.float32))
            view = -direction[idx]

            ndl = np.clip(normal @ light, 0.0, 1.0)
            ndf = np.clip(normal @ fill, 0.0, 1.0)
            shadow = _soft_shadow(scene, p + normal * 0.012, light)
            ao = _ambient_occlusion(scene, p, normal)

            half = normalize(light + view)
            ndh = np.clip(np.einsum("ij,ij->i", normal, half), 0.0, 1.0)
            fresnel = 1.0 - np.clip(np.einsum("ij,ij->i", normal, view), 0, 1)

            def per_material(attribute: str) -> Array:
                table = np.asarray(
                    [getattr(m, attribute) for m in scene.materials],
                    dtype=np.float32,
                )
                return table[material_id]

            base = np.asarray(
                [m.color for m in scene.materials], dtype=np.float32
            )[material_id]
            shininess = 2.0 / np.maximum(per_material("roughness"), 0.02) ** 2
            specular = per_material("specular") * ndh ** shininess
            specular *= 0.3 + 0.7 * shadow

            ambient = scene.ambient + 0.14 * normal[:, 1]
            lit = base * (
                (1.05 * ndl * (0.22 + 0.78 * shadow) + 0.38 * ndf + ambient)
                * ao
            )[:, None]
            lit += specular[:, None] * np.float32(1.4)
            lit += (per_material("rim") * fresnel ** 3.5)[:, None] * np.float32(1.3)

            object_color[idx] = lit
            coverage[idx] = 1.0

    obj = object_color.reshape(n, n, 3)
    alpha = coverage.reshape(n, n)
    if supersample > 1:
        obj = obj.reshape(size, supersample, size, supersample, 3).mean(axis=(1, 3))
        alpha = alpha.reshape(size, supersample, size, supersample).mean(axis=(1, 3))

    image = _background(scene, size)

    # Ombre portée : la même silhouette, décalée, floutée, assombrissant le
    # fond. C'est elle qui pose le sujet au lieu de le laisser flotter.
    if scene.shadow_strength > 0:
        offset = max(1, int(round(size * scene.shadow_offset)))
        shifted = np.roll(alpha, (offset, offset // 3), axis=(0, 1))
        shifted[:offset] = 0.0
        blurred = _blur(shifted, max(1, int(round(size * scene.shadow_blur))))
        image *= (1.0 - scene.shadow_strength * blurred)[..., None]

    if not with_background:
        rgba = np.empty((size, size, 4), dtype=np.uint8)
        rgba[..., :3] = (_tonemap(obj) * 255.0 + 0.5).astype(np.uint8)
        rgba[..., 3] = (np.clip(alpha, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8)
        return rgba

    composited = image * (1.0 - alpha[..., None]) + obj * alpha[..., None]
    return (_tonemap(composited) * 255.0 + 0.5).astype(np.uint8)
