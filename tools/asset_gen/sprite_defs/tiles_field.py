"""フィールド / ダンジョンのタイル (32x32) 定義。

design.md の「木・岩・大岩・看板には (・.・) の顔を描き、世界全体にテーマを
染み込ませる」方針を、顔描画ヘルパーを使って全タイルで徹底する。

アトラス: tiles_field.png = 6 列 x N 行。frame_index = row * 6 + col。
"""

from typing import Callable, Dict, List, Sequence, Tuple

from draw import draw_face, fill_ellipse, fill_polygon, fill_rect, new_canvas, set_pixel
from palette import hex_of
from pixel_canvas import Sheet, Sprite

TILE = 32
ATLAS_COLS = 6

GRASS_HEX = hex_of("G")
GRASS_DARK_HEX = hex_of("g")
DIRT_HEX = hex_of("T")
DIRT_DARK_HEX = hex_of("t")
SAND_HEX = hex_of("D")
WATER_HEX = hex_of("B")
WATER_DEEP_HEX = hex_of("b")
WATER_LIGHT_HEX = hex_of("C")
STONE_HEX = hex_of("M")
STONE_DARK_HEX = hex_of("m")
STONE_LIGHT_HEX = hex_of("L")
BLACK_HEX = hex_of("K")
WHITE_HEX = hex_of("W")
WOOD_HEX = hex_of("O")
WOOD_DARK_HEX = hex_of("o")
ROOF_HEX = hex_of("R")
ROOF_DARK_HEX = hex_of("r")
NAVY_HEX = hex_of("N")
NAVY_DEEP_HEX = hex_of("n")
GOLD_HEX = hex_of("Y")


def _speckle(sprite: Sprite, color_hex: str, offsets: Sequence[Tuple[int, int]],
             size: int = 2) -> None:
    for offset_x, offset_y in offsets:
        fill_rect(sprite, offset_x, offset_y, size, size, color_hex)


# ---------------------------------------------------------------- 地面

def build_grass() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, GRASS_HEX)
    _speckle(canvas, GRASS_DARK_HEX, ((3, 6), (12, 2), (22, 9), (7, 19), (18, 24), (27, 15)))
    fill_rect(canvas, 5, 12, 1, 3, GRASS_DARK_HEX)
    fill_rect(canvas, 24, 4, 1, 3, GRASS_DARK_HEX)
    return canvas


def build_grass_flower() -> Sprite:
    canvas = build_grass()
    fill_rect(canvas, 9, 8, 2, 2, WHITE_HEX)
    set_pixel(canvas, 10, 9, GOLD_HEX)
    fill_rect(canvas, 20, 18, 2, 2, WHITE_HEX)
    set_pixel(canvas, 21, 19, GOLD_HEX)
    return canvas


def build_dirt() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, DIRT_HEX)
    _speckle(canvas, DIRT_DARK_HEX, ((4, 4), (16, 7), (26, 3), (9, 21), (21, 26)))
    _speckle(canvas, SAND_HEX, ((12, 13), (2, 27), (28, 12)), size=1)
    return canvas


def build_dirt_path() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, SAND_HEX)
    _speckle(canvas, DIRT_HEX, ((6, 5), (19, 11), (27, 22), (11, 25)))
    _speckle(canvas, DIRT_DARK_HEX, ((2, 15), (24, 3)), size=1)
    return canvas


def build_cracked_ground() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, DIRT_HEX)
    fill_polygon(canvas, [(0, 18), (10, 15), (16, 20), (26, 14), (31, 17),
                          (31, 19), (26, 17), (16, 23), (10, 18), (0, 21)], DIRT_DARK_HEX)
    fill_polygon(canvas, [(14, 0), (16, 0), (18, 12), (22, 20), (20, 21), (15, 11)], DIRT_DARK_HEX)
    fill_polygon(canvas, [(18, 12), (28, 8), (29, 10), (19, 15)], DIRT_DARK_HEX)
    _speckle(canvas, SAND_HEX, ((5, 6), (24, 26)), size=2)
    return canvas


def build_water() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, WATER_HEX)
    fill_rect(canvas, 0, 0, TILE, 4, WATER_DEEP_HEX)
    for wave_y in (9, 19):
        fill_rect(canvas, 4, wave_y, 9, 1, WATER_LIGHT_HEX)
        fill_rect(canvas, 18, wave_y + 4, 10, 1, WATER_LIGHT_HEX)
    return canvas


def build_water_shore_sand() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, 14, SAND_HEX)
    fill_rect(canvas, 0, 16, TILE, 16, WATER_HEX)
    fill_rect(canvas, 0, 14, TILE, 2, WHITE_HEX)
    _speckle(canvas, DIRT_HEX, ((6, 4), (20, 8)), size=2)
    fill_rect(canvas, 5, 22, 8, 1, WATER_LIGHT_HEX)
    return canvas


# ---------------------------------------------------------------- 障害物 (顔つき)

def build_tree() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 13, 20, 6, 12, WOOD_DARK_HEX)
    fill_rect(canvas, 14, 20, 3, 12, WOOD_HEX)
    fill_ellipse(canvas, 16, 12, 12.0, 11.0, GRASS_DARK_HEX)
    fill_ellipse(canvas, 15, 10, 9.5, 8.5, GRASS_HEX)
    draw_face(canvas, 16, 11, BLACK_HEX, mouth=True, eye_size=2)
    fill_rect(canvas, 8, 4, 4, 2, GRASS_HEX)
    return canvas


def build_rock() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_polygon(canvas, [(6, 30), (3, 20), (9, 11), (20, 9), (28, 17), (27, 30)], STONE_HEX)
    fill_polygon(canvas, [(7, 30), (5, 22), (10, 15), (14, 14), (13, 30)], STONE_DARK_HEX)
    fill_polygon(canvas, [(14, 11), (20, 10), (23, 13), (18, 15)], STONE_LIGHT_HEX)
    draw_face(canvas, 18, 20, BLACK_HEX, mouth=True, eye_size=2)
    return canvas


def build_big_rock() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_polygon(canvas, [(2, 31), (0, 18), (7, 6), (17, 2), (27, 8), (31, 22), (29, 31)], STONE_HEX)
    fill_polygon(canvas, [(4, 31), (3, 20), (9, 10), (15, 9), (14, 31)], STONE_DARK_HEX)
    fill_polygon(canvas, [(18, 9), (25, 12), (27, 24), (19, 31)], STONE_HEX)
    fill_polygon(canvas, [(11, 4), (17, 3), (21, 7), (14, 9)], STONE_LIGHT_HEX)
    draw_face(canvas, 17, 18, BLACK_HEX, mouth=True, eye_size=3)
    fill_rect(canvas, 13, 25, 8, 2, STONE_LIGHT_HEX)
    return canvas


def build_signboard() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 14, 18, 4, 14, WOOD_DARK_HEX)
    fill_rect(canvas, 4, 6, 24, 14, WOOD_HEX)
    for edge_y in (6, 18):
        fill_rect(canvas, 4, edge_y, 24, 2, WOOD_DARK_HEX)
    for edge_x in (4, 26):
        fill_rect(canvas, edge_x, 6, 2, 14, WOOD_DARK_HEX)
    draw_face(canvas, 16, 11, BLACK_HEX, mouth=True, eye_size=2)
    return canvas


# ---------------------------------------------------------------- 市街

def build_house_wall() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, WOOD_HEX)
    for plank_y in range(0, TILE, 8):
        fill_rect(canvas, 0, plank_y, TILE, 1, WOOD_DARK_HEX)
    fill_rect(canvas, 0, 0, 2, TILE, WOOD_DARK_HEX)
    fill_rect(canvas, 30, 0, 2, TILE, WOOD_DARK_HEX)
    return canvas


def build_house_roof() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, ROOF_HEX)
    for row_y in range(0, TILE, 8):
        fill_rect(canvas, 0, row_y, TILE, 2, ROOF_DARK_HEX)
        for col_x in range(0, TILE, 8):
            fill_rect(canvas, col_x, row_y + 2, 1, 6, ROOF_DARK_HEX)
    return canvas


def build_wooden_door() -> Sprite:
    canvas = build_house_wall()
    fill_rect(canvas, 8, 4, 16, 28, NAVY_DEEP_HEX)
    fill_rect(canvas, 9, 5, 14, 26, WOOD_HEX)
    fill_rect(canvas, 9, 5, 14, 1, WOOD_DARK_HEX)
    fill_rect(canvas, 9, 5, 1, 26, WOOD_DARK_HEX)
    fill_rect(canvas, 22, 5, 1, 26, WOOD_DARK_HEX)
    fill_rect(canvas, 19, 17, 2, 2, GOLD_HEX)
    return canvas


def build_stairs_up() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, STONE_HEX)
    for step in range(4):
        fill_rect(canvas, 0, 6 + step * 7, TILE, 2, STONE_DARK_HEX)
        fill_rect(canvas, 0, 8 + step * 7, TILE, 5, STONE_LIGHT_HEX)
    return canvas


def build_stairs_down() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, STONE_HEX)
    for step in range(4):
        fill_rect(canvas, 0, 27 - step * 7, TILE, 2, STONE_DARK_HEX)
        fill_rect(canvas, 0, 20 - step * 7, TILE, 7, STONE_LIGHT_HEX)
    return canvas


def build_town_road() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, STONE_LIGHT_HEX)
    fill_rect(canvas, 0, 15, TILE, 2, STONE_HEX)
    fill_rect(canvas, 15, 0, 2, 15, STONE_HEX)
    fill_rect(canvas, 7, 17, 2, 15, STONE_HEX)
    fill_rect(canvas, 24, 17, 2, 15, STONE_HEX)
    return canvas


# ---------------------------------------------------------------- ダンジョン

def build_cave_floor() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, STONE_DARK_HEX)
    _speckle(canvas, STONE_HEX, ((5, 7), (18, 4), (26, 19), (11, 24)), size=2)
    fill_rect(canvas, 0, 0, TILE, 2, NAVY_DEEP_HEX)
    return canvas


def build_cave_wall() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, NAVY_DEEP_HEX)
    fill_rect(canvas, 0, 0, TILE, 22, STONE_DARK_HEX)
    fill_rect(canvas, 0, 22, TILE, 3, STONE_HEX)
    _speckle(canvas, STONE_HEX, ((4, 5), (20, 12)), size=3)
    return canvas


def build_tower_floor() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, NAVY_HEX)
    fill_rect(canvas, 0, 0, TILE, 1, STONE_DARK_HEX)
    fill_rect(canvas, 0, 16, TILE, 1, STONE_DARK_HEX)
    fill_rect(canvas, 16, 0, 1, TILE, STONE_DARK_HEX)
    set_pixel(canvas, 8, 8, STONE_HEX)
    set_pixel(canvas, 24, 24, STONE_HEX)
    return canvas


def build_tower_wall() -> Sprite:
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, NAVY_DEEP_HEX)
    fill_rect(canvas, 2, 2, 28, 20, NAVY_HEX)
    fill_rect(canvas, 2, 2, 28, 2, STONE_DARK_HEX)
    fill_rect(canvas, 14, 4, 3, 16, STONE_DARK_HEX)
    return canvas


def build_water_deep() -> Sprite:
    """深い水。船着き場や海の中心に使う。"""
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 0, 0, TILE, TILE, WATER_DEEP_HEX)
    fill_rect(canvas, 0, 0, TILE, 3, WATER_HEX)
    for wave_y in (11, 23):
        fill_rect(canvas, 6, wave_y, 7, 1, WATER_HEX)
        fill_rect(canvas, 20, wave_y + 3, 6, 1, WATER_HEX)
    return canvas


def build_fence() -> Sprite:
    """木柵。通行止め境界の視認用。"""
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 2, 10, 28, 4, WOOD_HEX)
    fill_rect(canvas, 2, 18, 28, 4, WOOD_HEX)
    for post_x in (4, 15, 26):
        fill_rect(canvas, post_x, 6, 3, 24, WOOD_DARK_HEX)
        fill_rect(canvas, post_x + 1, 6, 1, 24, WOOD_HEX)
    return canvas


def build_codex_stand() -> Sprite:
    """図鑑台。本を載せた台座。"""
    canvas = new_canvas(TILE, TILE)
    fill_rect(canvas, 6, 20, 20, 12, STONE_HEX)
    fill_rect(canvas, 6, 20, 20, 2, STONE_LIGHT_HEX)
    fill_rect(canvas, 8, 10, 16, 10, GOLD_HEX)
    fill_rect(canvas, 8, 10, 16, 2, NAVY_HEX)
    fill_rect(canvas, 15, 10, 2, 10, NAVY_HEX)
    return canvas


# ---------------------------------------------------------------- アトラス

TILE_BUILDERS: Dict[str, Callable[[], Sprite]] = {
    "grass": build_grass,
    "grass_flower": build_grass_flower,
    "dirt": build_dirt,
    "dirt_path": build_dirt_path,
    "cracked_ground": build_cracked_ground,
    "water": build_water,
    "water_shore_sand": build_water_shore_sand,
    "tree": build_tree,
    "rock": build_rock,
    "big_rock": build_big_rock,
    "signboard": build_signboard,
    "house_wall": build_house_wall,
    "house_roof": build_house_roof,
    "wooden_door": build_wooden_door,
    "stairs_up": build_stairs_up,
    "stairs_down": build_stairs_down,
    "town_road": build_town_road,
    "cave_floor": build_cave_floor,
    "cave_wall": build_cave_wall,
    "tower_floor": build_tower_floor,
    "tower_wall": build_tower_wall,
    "water_deep": build_water_deep,
    "fence": build_fence,
    "codex_stand": build_codex_stand,
}


def tile_names() -> List[str]:
    return list(TILE_BUILDERS.keys())


# 通行を塞ぐタイル。フィールドの当たり判定はここから導出する (データ駆動)。
# 調べられるオブジェクト (看板・図鑑台) も、プレイヤーが重なって読めなくなるため塞ぐ。
# 扉は Phase 4 のイベントで開閉する想定のため、床として歩かせない。
SOLID_TILES: frozenset = frozenset({
    "tree", "rock", "big_rock", "signboard",
    "house_wall", "house_roof", "fence", "wooden_door",
    "water", "water_deep",
    "cave_wall", "tower_wall",
})


def tile_catalog_payload() -> Dict[str, Dict[str, object]]:
    """tile_index.json の中身。タイル名 -> {frame, solid}。

    frame はアトラス内の row-major 列番号。solid は当たり判定の真偽。
    Godot 側 (domain/data/TileCatalog.gd) がそのまま読む。
    """
    names: List[str] = list(TILE_BUILDERS.keys())
    return {
        name: {"frame": index, "solid": name in SOLID_TILES}
        for index, name in enumerate(names)
    }


def build_tiles_field_atlas() -> Tuple[Sheet, List[str]]:
    """6 列に詰めたタイルアトラス。frame_index = row * ATLAS_COLS + col。"""
    names: List[str] = list(TILE_BUILDERS.keys())
    rows = (len(names) + ATLAS_COLS - 1) // ATLAS_COLS
    sheet = Sheet(ATLAS_COLS, rows, TILE, TILE)
    for index, name in enumerate(names):
        built = TILE_BUILDERS[name]()
        if built.size() != (TILE, TILE):
            raise ValueError(f"tile {name!r} must be exactly {TILE}x{TILE}, got {built.size()}")
        sheet.add(index % ATLAS_COLS, index // ATLAS_COLS, built, f"tile.{name}")
    return sheet, names
