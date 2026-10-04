"""全アセット共通のパレット定義。

色値は docs/sample_image の 3 枚から抽出した実測値。
GDScript 側の src/ui/UiPalette.gd と必ず一致させること (verify.py が検証する)。

ASCII ピクセルマップでは 1 文字 = 1 色としてこの辞書のキーを使う。
`.` は常に透明を表す。
"""

from typing import Dict, Optional

# --- 基本 ---
TRANSPARENT_CHAR = "."

# 文字 -> HEX。短い英字で「素材の役割」が読めるように命名する。
#   大文字 = 明部 / 主色、小文字 = 陰部・補助色、という規則で揃えている。
CHAR_COLORS: Dict[str, Optional[str]] = {
    ".": None,        # 透明

    "K": "#000000",   # 輪郭 (黒)
    "k": "#262626",   # 柔らかい黒 (影の縁)

    "W": "#FFFFFF",   # 白 (枠・ハイライト)
    "w": "#D9D9E6",   # 明灰 (布の明部)
    "s": "#9AA6D8",   # 補足色 (UI の TEXT_DIM)

    "N": "#0D124A",   # パネル地 (PANEL_NAVY)
    "n": "#0B1048",   # パネル地 濃 (PANEL_NAVY_DEEP)

    "Y": "#F2C64C",   # 金 (TEXT_NAME)
    "y": "#C79A2E",   # 金 陰

    "R": "#D94C4C",   # 赤
    "r": "#9E2F2F",   # 赤 陰

    "O": "#E08A3C",   # 橙
    "o": "#A85F22",   # 橙 陰

    "B": "#2B7AC5",   # 水 (WATER)
    "b": "#1B4E82",   # 水 深
    "C": "#6FC2F4",   # 水 高光 (WATER_HIGHLIGHT)

    "G": "#75A947",   # 草 (GRASS)
    "g": "#3A5930",   # 草 陰 (GRASS_DARK)

    "T": "#956C40",   # 土 (DIRT)
    "t": "#6B4A2A",   # 土 陰
    "D": "#C8934F",   # 砂 (DIRT_LIGHT)

    "M": "#8A8A96",   # 岩 中 (STONE_MID)
    "m": "#5C5C68",   # 岩 陰 (STONE_DARK)
    "L": "#B8B8C4",   # 岩 明 (STONE_LIGHT)

    "P": "#B46BC0",   # 魔法 紫
    "p": "#7A3E86",   # 魔法 紫 陰

    "F": "#FFD966",   # 炎 明
    "S": "#F0A83C",   # 炎 中
}

# UiPalette.gd と照合する必須色 (名前 -> HEX)
UI_PALETTE_CONTRACT: Dict[str, str] = {
    "PANEL_NAVY": "#0D124A",
    "PANEL_NAVY_DEEP": "#0B1048",
    "PANEL_BORDER": "#FFFFFF",
    "PANEL_SHADOW": "#000000",
    "TEXT_PRIMARY": "#FFFFFF",
    "TEXT_DIM": "#9AA6D8",
    "TEXT_NAME": "#F2C64C",
    "SKY": "#89CDCE",
    "GRASS": "#75A947",
    "GRASS_DARK": "#3A5930",
    "DIRT": "#956C40",
    "DIRT_LIGHT": "#C8934F",
    "WATER": "#2B7AC5",
    "WATER_HIGHLIGHT": "#6FC2F4",
    "HP_GOOD": "#5CD65C",
    "HP_WARN": "#E8C34A",
    "HP_DANGER": "#E05454",
}

# フィールドの空 (SKY) など、スプライト以外で使う色
SKY = "#89CDCE"


def resolve(char: str) -> Optional[tuple]:
    """1 文字を RGBA タプルへ変換する。未知の文字は例外にする (早急に気づくため)。"""
    if char not in CHAR_COLORS:
        raise KeyError(f"Unknown palette char: {char!r}")
    hex_value = CHAR_COLORS[char]
    if hex_value is None:
        return (0, 0, 0, 0)
    return hex_to_rgba(hex_value)


def hex_of(char: str) -> str:
    """パレット文字 -> HEX。draw.py の図形描画で使う。"""
    value = CHAR_COLORS.get(char)
    if value is None:
        raise KeyError(f"Palette char {char!r} has no hex value")
    return value


def hex_to_rgba(hex_value: str, alpha: int = 255) -> tuple:
    body = hex_value.lstrip("#")
    return (int(body[0:2], 16), int(body[2:4], 16), int(body[4:6], 16), alpha)
