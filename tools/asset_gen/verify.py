"""生成済みアセットの整合検証。

実行:
    python tools/asset_gen/verify.py

終了コード 0 = 全項目合格。CI / pre-commit からそのまま呼べる。
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Dict, List

from PIL import Image

HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))

from palette import UI_PALETTE_CONTRACT  # noqa: E402
from sprite_defs import enemies, tiles_field  # noqa: E402
import prototype_map  # noqa: E402

IMAGES_DIR = PROJECT_ROOT / "assets" / "images"
DATA_DIR = PROJECT_ROOT / "assets" / "data"
EXPECTED_ENEMY_PATTERNS = ("idle_a", "idle_b", "attack", "damage")


class Verifier:
    def __init__(self) -> None:
        self.failures: List[str] = []
        self.checks: int = 0

    def check(self, condition: bool, label: str) -> None:
        self.checks += 1
        if not condition:
            self.failures.append(label)

    def report(self) -> int:
        for failure in self.failures:
            print(f"  FAIL  {failure}")
        print(f"checks={self.checks} failures={len(self.failures)}")
        return 0 if not self.failures else 1


def verify_manifest(verifier: Verifier) -> dict:
    manifest_path = IMAGES_DIR / "manifest.json"
    verifier.check(manifest_path.exists(), "manifest.json exists")
    if not manifest_path.exists():
        return {}
    return json.loads(manifest_path.read_text(encoding="utf-8"))


def verify_sheets(verifier: Verifier, sheets: dict) -> None:
    sheets_path = IMAGES_DIR / "sheets.json"
    verifier.check(sheets_path.exists(), "sheets.json exists")
    if not sheets_path.exists():
        return
    sheet_meta = json.loads(sheets_path.read_text(encoding="utf-8"))

    for asset_id, meta in sorted(sheet_meta.items()):
        absolute = PROJECT_ROOT / meta["path"].removeprefix("res://")
        verifier.check(absolute.exists(), f"{asset_id}: file exists ({absolute})")
        if not absolute.exists():
            continue

        with Image.open(absolute) as image:
            expected_size = (meta["cols"] * meta["cell"][0], meta["rows"] * meta["cell"][1])
            verifier.check(image.size == expected_size,
                           f"{asset_id}: size {image.size} == {expected_size}")
            verifier.check(image.mode == "RGBA", f"{asset_id}: mode RGBA (got {image.mode})")

            frames = meta["frames"]
            verifier.check(len(frames) == meta["cols"] * meta["rows"],
                           f"{asset_id}: frame count {len(frames)} == {meta['cols'] * meta['rows']}")

            rgba = image.convert("RGBA")
            for index, frame_name in enumerate(frames):
                verifier.check(bool(frame_name), f"{asset_id}: frame {index} has a name")
                cell_x = (index % meta["cols"]) * meta["cell"][0]
                cell_y = (index // meta["cols"]) * meta["cell"][1]
                cell = rgba.crop((cell_x, cell_y,
                                  cell_x + meta["cell"][0], cell_y + meta["cell"][1]))
                opaque_pixels = sum(1 for alpha in cell.getchannel("A").getdata() if alpha > 0)
                verifier.check(opaque_pixels > 0, f"{asset_id}: frame {frame_name} is not empty")


def verify_enemies(verifier: Verifier, sheets: dict) -> None:
    verifier.check(len(enemies.ENEMY_DEFS) == 10,
                   f"10 enemy defs registered (got {len(enemies.ENEMY_DEFS)})")
    for enemy_def in enemies.ENEMY_DEFS:
        for suffix in ("", ".battle"):
            asset_id = f"enemy.{enemy_def.enemy_id}{suffix}"
            verifier.check(asset_id in sheets, f"{asset_id} present in manifest")
        meta = sheets.get(f"enemy.{enemy_def.enemy_id}", {})
        frames = meta.get("frames", [])
        for pattern in EXPECTED_ENEMY_PATTERNS:
            verifier.check(f"enemy.{enemy_def.enemy_id}.{pattern}" in frames,
                           f"enemy {enemy_def.enemy_id} has {pattern} frame")


def verify_tiles(verifier: Verifier, sheet_meta: dict) -> dict:
    index_path = IMAGES_DIR / "tiles" / "tile_index.json"
    verifier.check(index_path.exists(), "tile_index.json exists")
    if not index_path.exists():
        return {}
    tile_index = json.loads(index_path.read_text(encoding="utf-8"))
    tile_frames = sheet_meta.get("tiles.field", {}).get("frames", [])
    for tile_name in tiles_field.tile_names():
        entry = tile_index.get(tile_name)
        verifier.check(isinstance(entry, dict), f"tile {tile_name} indexed")
        if not isinstance(entry, dict):
            continue
        frame = entry.get("frame")
        verifier.check(frame == tiles_field.tile_names().index(tile_name),
                       f"tile {tile_name} frame index matches atlas order")
        verifier.check(f"tile.{tile_name}" in tile_frames,
                       f"tile {tile_name} frame present in sheets.json")
        verifier.check(isinstance(entry.get("solid"), bool),
                       f"tile {tile_name} has a boolean solid flag")
    verifier.check(set(tile_index) == set(tiles_field.tile_names()),
                   "tile_index.json covers exactly the defined tiles")
    for tile_name in tiles_field.SOLID_TILES:
        verifier.check(bool(tile_index.get(tile_name, {}).get("solid")),
                       f"tile {tile_name} is solid")
    for tile_name in set(tiles_field.tile_names()) - tiles_field.SOLID_TILES:
        verifier.check(not bool(tile_index.get(tile_name, {}).get("solid")),
                       f"tile {tile_name} is passable")
    verify_tile_bases(verifier, tile_index, sheet_meta)
    return tile_index


def verify_tile_bases(verifier: Verifier, tile_index: dict, sheet_meta: dict) -> None:
    """下地タイルの宣言を検証する。

    樹木・岩・柵などは画像自体が透明背景のため、下に地面を敷かないと
    画面の背景色が見えてしまう。宣言の妥当性はもちろん、
    「透明ピクセルがあるのに下地が無い」も画像を実測して検出する。
    """
    for tile_name, base_name in sorted(tiles_field.BASE_TILES.items()):
        verifier.check(base_name in tile_index,
                       f"tile {tile_name} base {base_name!r} is a known tile")
        verifier.check(base_name != tile_name, f"tile {tile_name} base is not itself")
        verifier.check(not tile_index.get(base_name, {}).get("solid"),
                       f"tile {tile_name} base {base_name!r} is walkable ground")
    for tile_name, entry in sorted(tile_index.items()):
        declared = entry.get("base", "")
        verifier.check(declared == tiles_field.BASE_TILES.get(tile_name, ""),
                       f"tile {tile_name} base matches the generator")

    meta = sheet_meta.get("tiles.field", {})
    absolute = PROJECT_ROOT / str(meta.get("path", "")).removeprefix("res://")
    if not absolute.exists():
        verifier.check(False, "tiles.field png available for the base check")
        return
    cols, cell = meta["cols"], meta["cell"]
    with Image.open(absolute) as image:
        rgba = image.convert("RGBA")
        for tile_name, entry in sorted(tile_index.items()):
            frame = entry.get("frame")
            if not isinstance(frame, int):
                continue
            cell_x, cell_y = (frame % cols) * cell[0], (frame // cols) * cell[1]
            cell_image = rgba.crop((cell_x, cell_y, cell_x + cell[0], cell_y + cell[1]))
            transparent = sum(1 for alpha in cell_image.getchannel("A").getdata() if alpha == 0)
            if transparent > 0:
                verifier.check(bool(entry.get("base")),
                               f"tile {tile_name} declares a base for its {transparent} transparent px")


def verify_maps(verifier: Verifier, tile_index: dict) -> None:
    """モックマップがプレイ可能な形になっているかを検証する。

    地形は JSON データなので、Godot を起動せずにここで壊れを検出できる。
    """
    map_path = DATA_DIR / "maps" / f"{prototype_map.MAP_ID}.json"
    verifier.check(map_path.exists(), "prototype map json exists")
    if not map_path.exists():
        return
    payload = json.loads(map_path.read_text(encoding="utf-8"))

    rows: List[str] = payload.get("rows", [])
    glyphs: Dict[str, str] = payload.get("glyphs", {})
    verifier.check(len(rows) == prototype_map.MAP_HEIGHT,
                   f"map has {prototype_map.MAP_HEIGHT} rows")
    verifier.check(all(len(row) == prototype_map.MAP_WIDTH for row in rows),
                   "every map row is exactly the map width")
    for glyph, tile_id in glyphs.items():
        verifier.check(tile_id in tile_index, f"glyph {glyph!r} -> known tile {tile_id!r}")

    solid_ids = {name for name, entry in tile_index.items() if entry.get("solid")}

    def is_solid_cell(x: int, y: int) -> bool:
        glyph = rows[y][x]
        tile_id = glyphs.get(glyph, "")
        return tile_id == "" or tile_id in solid_ids

    spawn = payload.get("spawn", {})
    spawn_x, spawn_y = int(spawn.get("x", -1)), int(spawn.get("y", -1))
    verifier.check(0 <= spawn_x < prototype_map.MAP_WIDTH and 0 <= spawn_y < prototype_map.MAP_HEIGHT,
                   "spawn point inside map bounds")
    verifier.check(not is_solid_cell(spawn_x, spawn_y), "spawn point is walkable")

    for x in range(prototype_map.MAP_WIDTH):
        verifier.check(is_solid_cell(x, 0) and is_solid_cell(x, prototype_map.MAP_HEIGHT - 1),
                       f"map edge sealed at column {x}")
    for y in range(prototype_map.MAP_HEIGHT):
        verifier.check(is_solid_cell(0, y) and is_solid_cell(prototype_map.MAP_WIDTH - 1, y),
                       f"map edge sealed at row {y}")

    walkable = sum(1 for row in rows for glyph in row
                   if glyphs.get(glyph, "") and glyphs[glyph] not in solid_ids)
    verifier.check(walkable > 100, f"map offers enough walkable ground (got {walkable})")


def verify_palette_contract(verifier: Verifier) -> None:
    """src/ui/UiPalette.gd の色値が palette.py の契約と一致していることを確認する。

    Python 側と GDScript 側で色を二重定義しているため、ズレをテストで検出する。
    """
    gd_path = PROJECT_ROOT / "src" / "ui" / "UiPalette.gd"
    verifier.check(gd_path.exists(), "src/ui/UiPalette.gd exists")
    if not gd_path.exists():
        return
    source = gd_path.read_text(encoding="utf-8")
    gd_colors = dict(re.findall(
        r'const\s+(\w+)\s*:=\s*Color\(\s*"?#?([0-9A-Fa-f]{6})"?\s*\)', source))
    for name, expected_hex in UI_PALETTE_CONTRACT.items():
        actual = gd_colors.get(name, "")
        verifier.check(actual.lower() == expected_hex.lstrip("#").lower(),
                       f"UiPalette.{name} == {expected_hex} (got {actual or 'MISSING'})")


def main() -> int:
    verifier = Verifier()
    manifest = verify_manifest(verifier)
    sheets_file = IMAGES_DIR / "sheets.json"
    sheet_meta = json.loads(sheets_file.read_text(encoding="utf-8")) if sheets_file.exists() else {}

    for asset_id, path in sorted(manifest.items()):
        absolute = PROJECT_ROOT / path.removeprefix("res://")
        verifier.check(absolute.exists(), f"{asset_id}: manifest target exists")

    verify_sheets(verifier, sheet_meta)
    verify_enemies(verifier, sheet_meta)
    tile_index = verify_tiles(verifier, sheet_meta)
    verify_maps(verifier, tile_index)
    verify_palette_contract(verifier)

    print("=== asset verification ===")
    return verifier.report()


if __name__ == "__main__":
    raise SystemExit(main())
