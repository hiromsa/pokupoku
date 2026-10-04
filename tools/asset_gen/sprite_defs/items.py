"""どうぐ・武器アイコン (16x16) 定義。

剣系は同一形状のブレード色だけ差し替える (recolored) ことで、
5 本の武器アイコンを 1 つの定義から生成している。
"""

from typing import Callable, Dict, List, Tuple

from draw import fill_ellipse, fill_polygon, fill_rect, new_canvas, set_pixel
from palette import hex_of
from pixel_canvas import Sheet, Sprite

ICON = 16

BLACK_HEX = hex_of("K")
WHITE_HEX = hex_of("W")
GREEN_HEX = hex_of("G")
GREEN_DARK_HEX = hex_of("g")
CYAN_HEX = hex_of("C")
BLUE_HEX = hex_of("B")
STEEL_HEX = hex_of("L")
STEEL_DARK_HEX = hex_of("M")
GOLD_HEX = hex_of("Y")
GOLD_DARK_HEX = hex_of("y")
ICE_HEX = hex_of("C")
WIND_HEX = hex_of("w")
DARK_HEX = hex_of("N")
DARK_DARK_HEX = hex_of("n")
WOOD_HEX = hex_of("O")
BROWN_HEX = hex_of("T")
BROWN_DARK_HEX = hex_of("t")
PAPER_HEX = hex_of("D")


def _sword(blade_hex: str, hilt_hex: str = GOLD_HEX, shade_hex: str = STEEL_DARK_HEX) -> Sprite:
    """16x16 の剣アイコン共通形状。柄を右下、刃を左上に向ける。

    刃は 2px 幅 + 下面 1px の陰で厚みを出す。16x16 では黒縁を足すと
    刃そのものが潰えて判別できなくなるため、縁取らず色階で立体化する。
    """
    canvas = new_canvas(ICON, ICON)
    blade_cells = [(3, 12), (4, 11), (5, 10), (6, 9), (7, 8), (8, 7), (9, 6), (10, 5), (11, 4)]
    for x, y in blade_cells:
        fill_rect(canvas, x, y, 2, 2, blade_hex)
    for x, y in blade_cells:
        set_pixel(canvas, x + 1, y + 1, shade_hex)
    # 切先
    set_pixel(canvas, 12, 3, WHITE_HEX)
    set_pixel(canvas, 12, 2, blade_hex)
    # 鍔
    fill_rect(canvas, 10, 11, 5, 2, hilt_hex)
    fill_rect(canvas, 12, 9, 2, 5, hilt_hex)
    # 柄
    fill_rect(canvas, 13, 13, 3, 3, GOLD_DARK_HEX)
    return canvas


def build_herba() -> Sprite:
    """薬草。緑の葉を 3 枚。"""
    canvas = new_canvas(ICON, ICON)
    fill_ellipse(canvas, 6, 9, 4.0, 5.0, GREEN_HEX)
    fill_ellipse(canvas, 11, 8, 3.5, 4.5, GREEN_HEX)
    fill_ellipse(canvas, 8, 12, 3.0, 3.0, GREEN_DARK_HEX)
    fill_rect(canvas, 7, 13, 2, 3, GREEN_DARK_HEX)
    set_pixel(canvas, 5, 6, WHITE_HEX)
    return canvas


def build_kodama_no_kagami() -> Sprite:
    """木霊の鏡。青い鏡面と金枠。"""
    canvas = new_canvas(ICON, ICON)
    fill_ellipse(canvas, 8, 7, 5.5, 6.0, GOLD_HEX)
    fill_ellipse(canvas, 8, 7, 4.0, 4.5, CYAN_HEX)
    fill_ellipse(canvas, 6, 5, 1.5, 1.5, WHITE_HEX)
    fill_rect(canvas, 7, 13, 3, 3, GOLD_DARK_HEX)
    return canvas


def build_boro_no_tsurugi() -> Sprite:
    """粗い剣。錆びた茶色で安物感を先出しする。"""
    return _sword(BROWN_HEX, WOOD_HEX, BROWN_DARK_HEX)


def build_harai_no_tsurugi() -> Sprite:
    return _sword(STEEL_HEX, GOLD_HEX, STEEL_DARK_HEX)


def build_yuki_no_tsurugi() -> Sprite:
    sword = _sword(ICE_HEX, WHITE_HEX, BLUE_HEX)
    set_pixel(sword, 2, 13, CYAN_HEX)
    set_pixel(sword, 13, 1, WHITE_HEX)
    return sword


def build_kaze_no_tsurugi() -> Sprite:
    sword = _sword(WIND_HEX, STEEL_HEX, CYAN_HEX)
    fill_rect(sword, 1, 10, 2, 1, WHITE_HEX)
    fill_rect(sword, 12, 1, 3, 1, WHITE_HEX)
    return sword


def build_yami_no_tsurugi() -> Sprite:
    purple_hex = hex_of("P")
    sword = _sword(DARK_HEX, purple_hex, DARK_DARK_HEX)
    set_pixel(sword, 12, 2, purple_hex)
    return sword


def build_key() -> Sprite:
    canvas = new_canvas(ICON, ICON)
    fill_ellipse(canvas, 5, 5, 3.5, 3.5, GOLD_HEX)
    fill_ellipse(canvas, 5, 5, 1.5, 1.5, BLACK_HEX)
    fill_rect(canvas, 7, 6, 8, 2, GOLD_HEX)
    fill_rect(canvas, 11, 8, 2, 3, GOLD_HEX)
    fill_rect(canvas, 14, 8, 2, 4, GOLD_HEX)
    return canvas


def build_map() -> Sprite:
    canvas = new_canvas(ICON, ICON)
    fill_polygon(canvas, [(2, 3), (7, 1), (9, 4), (14, 2), (14, 13), (9, 15), (7, 12), (2, 14)], PAPER_HEX)
    fill_rect(canvas, 7, 1, 1, 12, hex_of("T"))
    fill_rect(canvas, 9, 3, 1, 12, hex_of("T"))
    fill_rect(canvas, 4, 7, 9, 1, CYAN_HEX)
    return canvas


def build_item_box() -> Sprite:
    """汎用ボックス (未実装アイテムのプレースホルダ)。"""
    canvas = new_canvas(ICON, ICON)
    fill_rect(canvas, 2, 4, 12, 10, WOOD_HEX)
    fill_rect(canvas, 2, 4, 12, 2, GOLD_HEX)
    fill_rect(canvas, 2, 4, 12, 1, BLACK_HEX)
    fill_rect(canvas, 7, 6, 2, 4, GOLD_HEX)
    return canvas


ITEM_BUILDERS: Dict[str, Callable[[], Sprite]] = {
    "herba": build_herba,
    "kodama_no_kagami": build_kodama_no_kagami,
    "harai_no_tsurugi": build_harai_no_tsurugi,
    "boro_no_tsurugi": build_boro_no_tsurugi,
    "yuki_no_tsurugi": build_yuki_no_tsurugi,
    "kaze_no_tsurugi": build_kaze_no_tsurugi,
    "yami_no_tsurugi": build_yami_no_tsurugi,
    "key": build_key,
    "map": build_map,
    "item_box": build_item_box,
}


def item_names() -> List[str]:
    return list(ITEM_BUILDERS.keys())


def build_items_atlas() -> Tuple[Sheet, List[str]]:
    """1 行に並べたアイコンアトラス。frame_index = アイテムの添字。"""
    names: List[str] = list(ITEM_BUILDERS.keys())
    sheet = Sheet(len(names), 1, ICON, ICON)
    for index, name in enumerate(names):
        sheet.add(index, 0, ITEM_BUILDERS[name](), f"item.{name}")
    return sheet, names
