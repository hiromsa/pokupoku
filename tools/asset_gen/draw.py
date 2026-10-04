"""スプライトへ直接描画する図形プリミティブ。

ASCII ピクセルマップは小さなキャラには適していますが、10 種のエネミーを
手書きで書き写すと行長ミスと修正波及のリスクが大きくなります。
そこでエネミーは「図形 + 顔オーバーレイ」のレシピで定義し、
生成物が決定的に決まることを保ちつつ再利用性を高めています。
"""

from __future__ import annotations

from typing import Optional, Sequence, Tuple

from palette import hex_to_rgba
from pixel_canvas import Sprite

Point = Tuple[int, int]


def fill_rect(sprite: Sprite, x: int, y: int, width: int, height: int, color_hex: str) -> None:
    color = hex_to_rgba(color_hex)
    pixels = sprite.image.load()
    for py in range(y, y + height):
        for px in range(x, x + width):
            if 0 <= px < sprite.width and 0 <= py < sprite.height:
                pixels[px, py] = color


def fill_ellipse(sprite: Sprite, cx: float, cy: float, radius_x: float,
                 radius_y: float, color_hex: str) -> None:
    """中心 (cx, cy) ・半径 (rx, ry) の塗り楕円。ピクセル中心で判定する。"""
    color = hex_to_rgba(color_hex)
    pixels = sprite.image.load()
    for py in range(int(cy - radius_y) - 1, int(cy + radius_y) + 2):
        for px in range(int(cx - radius_x) - 1, int(cx + radius_x) + 2):
            if not (0 <= px < sprite.width and 0 <= py < sprite.height):
                continue
            normalized = ((px - cx) / radius_x) ** 2 + ((py - cy) / radius_y) ** 2
            if normalized <= 1.0:
                pixels[px, py] = color


def stroke_ellipse(sprite: Sprite, cx: float, cy: float, radius_x: float,
                   radius_y: float, color_hex: str) -> None:
    """楕円の輪郭 (塗りつぶし境界の 1px 外側まで含める)。"""
    color = hex_to_rgba(color_hex)
    pixels = sprite.image.load()
    for py in range(int(cy - radius_y) - 2, int(cy + radius_y) + 3):
        for px in range(int(cx - radius_x) - 2, int(cx + radius_x) + 3):
            if not (0 <= px < sprite.width and 0 <= py < sprite.height):
                continue
            outer = (((px + 0.5 - cx) / (radius_x + 1)) ** 2
                     + ((py + 0.5 - cy) / (radius_y + 1)) ** 2)
            inner = (((px + 0.5 - cx) / radius_x) ** 2
                     + ((py + 0.5 - cy) / radius_y) ** 2)
            if inner > 1.0 and outer <= 1.0:
                pixels[px, py] = color


def fill_polygon(sprite: Sprite, points: Sequence[Point], color_hex: str) -> None:
    """単純な多角形を走査線で塗りつぶす (岩・結晶などのトゲ形状用)。"""
    color = hex_to_rgba(color_hex)
    pixels = sprite.image.load()
    min_y = max(0, min(p[1] for p in points))
    max_y = min(sprite.height - 1, max(p[1] for p in points))

    for py in range(min_y, max_y + 1):
        crossings = []
        count = len(points)
        for index in range(count):
            x1, y1 = points[index]
            x2, y2 = points[(index + 1) % count]
            if y1 == y2:
                continue
            if y1 <= py < y2 or y2 <= py < y1:
                t = (py - y1) / (y2 - y1)
                crossings.append(x1 + t * (x2 - x1))
        crossings.sort()
        for pair in range(0, len(crossings) - 1, 2):
            left = max(0, int(round(crossings[pair])))
            right = min(sprite.width - 1, int(round(crossings[pair + 1])))
            for px in range(left, right + 1):
                pixels[px, py] = color


def set_pixel(sprite: Sprite, x: int, y: int, color_hex: str) -> None:
    if 0 <= x < sprite.width and 0 <= y < sprite.height:
        sprite.image.load()[x, y] = hex_to_rgba(color_hex)


def draw_face(sprite: Sprite, cx: int, cy: int, eye_color_hex: str = "#000000",
              mouth: bool = True, eye_size: int = 2) -> None:
    """テーマ記号 `(・.・)` の顔を描く。全キャラ共通の目立ち方を持たせる。"""
    half_gap = 4 if eye_size >= 2 else 3
    for eye_x in (cx - half_gap, cx + half_gap - eye_size + 1):
        fill_rect(sprite, eye_x, cy, eye_size, eye_size, eye_color_hex)
    if mouth:
        fill_rect(sprite, cx - 1, cy + 3, 2, 1, eye_color_hex)


def draw_eyes_wide(sprite: Sprite, cx: int, cy: int, white_hex: str,
                   pupil_hex: str, size: int = 4) -> None:
    """白目 + 黒瞳の大きな目 (サンプル画像の主人公風エネミー用)。"""
    for offset_x in (-size - 1, 1):
        fill_rect(sprite, cx + offset_x, cy, size, size, white_hex)
        fill_rect(sprite, cx + offset_x + 1, cy + 1, size - 2, size - 2, pupil_hex)


def shade_bottom(sprite: Sprite, shadow_hex: str, band_height: int = 3) -> None:
    """下端 band_height 行の明るさを落として立体感を出す。"""
    shadow = hex_to_rgba(shadow_hex)
    pixels = sprite.image.load()
    for py in range(sprite.height - band_height, sprite.height):
        for px in range(sprite.width):
            r, g, b, a = pixels[px, py]
            if a == 0:
                continue
            pixels[px, py] = (
                int(r * 0.62) if shadow[0] < 40 else min(255, int(shadow[0] + (r - shadow[0]) * 0.5)),
                int(g * 0.62) if shadow[1] < 40 else min(255, int(shadow[1] + (g - shadow[1]) * 0.5)),
                int(b * 0.62) if shadow[2] < 40 else min(255, int(shadow[2] + (b - shadow[2]) * 0.5)),
                a,
            )


def new_canvas(width: int, height: int) -> Sprite:
    return Sprite.blank(width, height)
