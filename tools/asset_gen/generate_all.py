"""全アセットを生成し、Godot 側の manifest を書き出すエントリポイント。

実行:
    python tools/asset_gen/generate_all.py

出力:
    assets/images/**.png                    生成された画像
    assets/images/manifest.json             論理アセットID -> res:// パス
    assets/images/sheets.json               シートレイアウト (cols/rows/cell/frames)
    assets/data/enemy_catalog.json          エネミー一覧 (Phase 3/4 のデータテーブル種データ)
    assets/data/maps/prototype_village.json Phase 2 モック用マップ (文字列アート)
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Dict, List

HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))

from sprite_defs import enemies, hero, items, tiles_field, ui_parts  # noqa: E402
from pixel_canvas import Sheet  # noqa: E402
import prototype_map  # noqa: E402

ASSETS_DIR = PROJECT_ROOT / "assets"
IMAGES_DIR = ASSETS_DIR / "images"
DATA_DIR = ASSETS_DIR / "data"
MAPS_DIR = DATA_DIR / "maps"


def _res_path(absolute_path: Path) -> str:
    return "res://" + str(absolute_path.relative_to(PROJECT_ROOT)).replace("\\", "/")


class ManifestWriter:
    """manifest.json と sheets.json を同時に溜めて書き出す。"""

    def __init__(self) -> None:
        self.paths: Dict[str, str] = {}
        self.sheets: Dict[str, Dict[str, object]] = {}

    def add_sheet(self, asset_id: str, sheet: Sheet, save_path: Path) -> None:
        sheet.save(save_path)
        self.paths[asset_id] = _res_path(save_path)
        self.sheets[asset_id] = {
            "path": _res_path(save_path),
            "cols": sheet.cols,
            "rows": sheet.rows,
            "cell": [sheet.cell_width, sheet.cell_height],
            "frames": sheet.frame_names,
        }

    def add_image(self, asset_id: str, sprite, save_path: Path) -> None:
        sprite.save(save_path)
        self.paths[asset_id] = _res_path(save_path)

    def write(self) -> None:
        IMAGES_DIR.mkdir(parents=True, exist_ok=True)
        (IMAGES_DIR / "manifest.json").write_text(
            json.dumps(self.paths, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8")
        (IMAGES_DIR / "sheets.json").write_text(
            json.dumps(self.sheets, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8")


def generate_hero(manifest: ManifestWriter) -> None:
    hero_dir = IMAGES_DIR / "hero"
    manifest.add_sheet("hero.field", hero.build_hero_field_sheet(), hero_dir / "hero_field.png")
    manifest.add_sheet("hero.battle", hero.build_hero_battle_sheet(), hero_dir / "hero_battle.png")


def generate_enemies(manifest: ManifestWriter) -> None:
    enemy_dir = IMAGES_DIR / "enemies"
    for enemy_def in enemies.ENEMY_DEFS:
        manifest.add_sheet(f"enemy.{enemy_def.enemy_id}",
                           enemies.build_enemy_sheet(enemy_def),
                           enemy_dir / f"enemy_{enemy_def.enemy_id}.png")
        manifest.add_sheet(f"enemy.{enemy_def.enemy_id}.battle",
                           enemies.build_enemy_battle_sheet(enemy_def),
                           enemy_dir / f"enemy_{enemy_def.enemy_id}_battle.png")

    DATA_DIR.mkdir(parents=True, exist_ok=True)
    (DATA_DIR / "enemy_catalog.json").write_text(
        json.dumps(enemies.enemy_catalog_payload(), ensure_ascii=False, indent=2), encoding="utf-8")


def generate_tiles(manifest: ManifestWriter) -> None:
    atlas, names = tiles_field.build_tiles_field_atlas()
    manifest.add_sheet("tiles.field", atlas, IMAGES_DIR / "tiles" / "tiles_field.png")

    # タイル名 -> {frame, solid} を Godot 側が引けるように出す (当たり判定の正)
    (IMAGES_DIR / "tiles" / "tile_index.json").write_text(
        json.dumps(tiles_field.tile_catalog_payload(), ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8")


def generate_items(manifest: ManifestWriter) -> None:
    atlas, names = items.build_items_atlas()
    manifest.add_sheet("items.icons", atlas, IMAGES_DIR / "items" / "items.png")
    item_index_map = {name: index for index, name in enumerate(names)}
    (IMAGES_DIR / "items" / "item_index.json").write_text(
        json.dumps(item_index_map, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8")


def generate_ui(manifest: ManifestWriter) -> None:
    ui_dir = IMAGES_DIR / "ui"
    manifest.add_sheet("ui.parts", ui_parts.build_ui_atlas(), ui_dir / "ui_parts.png")
    manifest.add_image("ui.icon", ui_parts.build_app_icon(64), ui_dir / "icon.png")


def generate_maps() -> None:
    """モック用マップを JSON データとして出力する。地形編集は GDScript 外でできる。"""
    MAPS_DIR.mkdir(parents=True, exist_ok=True)
    (MAPS_DIR / f"{prototype_map.MAP_ID}.json").write_text(
        json.dumps(prototype_map.prototype_map_payload(), ensure_ascii=False, indent=2),
        encoding="utf-8")


def main() -> int:
    manifest = ManifestWriter()
    generate_hero(manifest)
    generate_enemies(manifest)
    generate_tiles(manifest)
    generate_items(manifest)
    generate_ui(manifest)
    generate_maps()
    manifest.write()

    print(f"generated {len(manifest.paths)} image assets -> {IMAGES_DIR}")
    for asset_id in sorted(manifest.paths):
        print(f"  {asset_id:36s} {manifest.paths[asset_id]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
