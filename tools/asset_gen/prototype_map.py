"""Phase 2 のモック用マップ (はじまりの草原)。

マップは外部 JSON (assets/data/maps/) として出力する。地形の編集は
GDScript を触らずにできるべきだという design.md の方針に沿う。

レイアウトは文字列アート。 glyph テーブルでタイル ID へ変換する。
"""

from __future__ import annotations

from typing import Dict, List

MAP_ID = "prototype_village"
MAP_NAME = "はじまりの草原"
MAP_WIDTH = 30
MAP_HEIGHT = 20
SPAWN_TILE = (5, 11)

# 文字 -> タイル ID。タイル ID は tiles_field.py の定義名と必ず一致させる。
TILE_GLYPHS: Dict[str, str] = {
    "T": "tree",
    "F": "fence",
    "g": "grass",
    "f": "grass_flower",
    "d": "dirt",
    "p": "dirt_path",
    "c": "cracked_ground",
    "s": "water_shore_sand",
    "w": "water",
    "W": "water_deep",
    "r": "rock",
    "R": "big_rock",
    "S": "signboard",
    "H": "house_wall",
    "O": "house_roof",
    "D": "wooden_door",
    "u": "stairs_up",
    "U": "stairs_down",
    "o": "town_road",
    "K": "codex_stand",
}

# 上: 森 / 中央: はじまりの村 / 下: 草原と池。外周は木と柵で塞ぐ。
LAYOUT_ROWS: List[str] = [
    "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
    "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
    "TTTggggggTTTTTTTTTTTTTTTTTTTTT",
    "TTgggggggggTTTrrrrTTTTTTTTTTTT",
    "TTggfggggggTTrrrrrrTTTTTTTTTTT",
    "TgggggggggggTrrrrrrTTTTTTTTTTT",
    "TgggTgggggggTrrrrTTTTTTTTTTTTT",
    "TgggTTggggggTTrrTTTTTTTTTTTTTT",
    "TgggTTTggggggTTTTTTTggggTTTTTT",
    "TggTTTggggggggTTTTgggggggTTTTT",
    "TggTTggggggggggggggggggggTTTTT",
    "TpppppppppppoooooooooooooTTTTT",
    "TggTTggggggggoHHHHHHHgggTTTTTT",
    "TggTTggggggggoHDDHHHggggTTTTTT",
    "TggTTggggggggoHHHHHHgKggTTTTTT",
    "TggTTggggggggooooooooogggTTTTT",
    "TTTTgggggggggggggwwwwggggTTTTT",
    "TTTTTTggggggggggwwwwwwggTTTTTT",
    "TFFFFFFFFFFFFFFFFFFFFFFFFFFFFT",
    "TFFFFFFFFFFFFFFFFFFFFFFFFFFFFT",
]


def _validated_rows() -> List[str]:
    """全行がちょうど MAP_WIDTH であることを強制する。

    短い行を暗黙に埋めると、意図しない通行不可の穴がマップに紛れ込む。
    レイアウトを書いた時点で気づけるよう、生成時に失敗させる。
    """
    rows: List[str] = []
    for index, row in enumerate(LAYOUT_ROWS):
        if len(row) != MAP_WIDTH:
            raise ValueError(
                f"map row {index} must be exactly {MAP_WIDTH} chars, got {len(row)}: {row!r}")
        rows.append(row)
    if len(rows) != MAP_HEIGHT:
        raise ValueError(f"map must be {MAP_HEIGHT} rows, got {len(rows)}")
    return rows


def prototype_map_payload() -> Dict[str, object]:
    """assets/data/maps/prototype_village.json の中身。"""
    return {
        "id": MAP_ID,
        "name": MAP_NAME,
        "spawn": {"x": SPAWN_TILE[0], "y": SPAWN_TILE[1]},
        "glyphs": dict(TILE_GLYPHS),
        "rows": _validated_rows(),
    }
