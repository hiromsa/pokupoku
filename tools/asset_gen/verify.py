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
from typing import List

from PIL import Image

HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))

from palette import UI_PALETTE_CONTRACT  # noqa: E402
from sprite_defs import enemies, tiles_field  # noqa: E402

IMAGES_DIR = PROJECT_ROOT / "assets" / "images"
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


def verify_tiles(verifier: Verifier) -> None:
    index_path = IMAGES_DIR / "tiles" / "tile_index.json"
    verifier.check(index_path.exists(), "tile_index.json exists")
    if not index_path.exists():
        return
    tile_index = json.loads(index_path.read_text(encoding="utf-8"))
    for tile_name in tiles_field.tile_names():
        verifier.check(tile_name in tile_index, f"tile {tile_name} indexed")


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
    verify_tiles(verifier)
    verify_palette_contract(verifier)

    print("=== asset verification ===")
    return verifier.report()


if __name__ == "__main__":
    raise SystemExit(main())
