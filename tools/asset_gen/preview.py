"""生成済みアセットを拡大したプレビュー画像を tmp_preview/ に書き出す。

ドット絵は 1 倍だと判別できないため、目視レビュー用の拡大画像を作る。
一時ファイルなので git には載せない (.gitignore の tmp_preview/)。

実行:
    python tools/asset_gen/preview.py [名前...]
      名前省略時は全カテゴリ。例: python tools/asset_gen/preview.py hero enemies
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Dict, List, Sequence

from PIL import Image

HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))

from sprite_defs import enemies, hero, items, tiles_field, ui_parts  # noqa: E402

PREVIEW_DIR = PROJECT_ROOT / "tmp_preview"
BACKGROUND = (40, 44, 90, 255)
GAP = 8


def _contact_sheet(sprites: Sequence[Image.Image], scale: int) -> Image.Image:
    """透過スプライトを横一列に並べ、背景を敷いて拡大する。"""
    width = sum(sprite.width for sprite in sprites) + GAP * len(sprites)
    height = max(sprite.height for sprite in sprites) + GAP
    sheet = Image.new("RGBA", (width, height), BACKGROUND)
    x = GAP // 2
    for sprite in sprites:
        sheet.alpha_composite(sprite, (x, (height - sprite.height) // 2))
        x += sprite.width + GAP
    return sheet.resize((width * scale, height * scale), Image.Resampling.NEAREST)


def _save(name: str, image: Image.Image) -> None:
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    path = PREVIEW_DIR / f"{name}.png"
    image.save(path)
    print(f"  {path.relative_to(PROJECT_ROOT)}  {image.size[0]}x{image.size[1]}")


def _frames_of(sheet) -> List[Image.Image]:
    """シートからフレーム画像だけを切り出す。"""
    return [sheet.image.crop((index % sheet.cols * sheet.cell_width,
                              index // sheet.cols * sheet.cell_height,
                              (index % sheet.cols + 1) * sheet.cell_width,
                              (index // sheet.cols + 1) * sheet.cell_height))
            for index in range(sheet.frame_count())]


def preview_hero() -> None:
    # 12 フレーム (down/up/left/right x stand/step_l/step_r) を並べ順どおりに並べる
    _save("hero_field", _contact_sheet(_frames_of(hero.build_hero_field_sheet()), 5))
    _save("hero_battle", _contact_sheet(_frames_of(hero.build_hero_battle_sheet()), 3))


def preview_enemies() -> None:
    idles = [enemies.build_enemy_frames(enemy_def)["idle_a"].image for enemy_def in enemies.ENEMY_DEFS]
    _save("enemies_contact", _contact_sheet(idles, 3))

    _save("poku_anim", _contact_sheet(_frames_of(enemies.build_enemy_sheet(enemies.find_enemy_def("poku"))), 4))


def preview_tiles() -> None:
    atlas, _names = tiles_field.build_tiles_field_atlas()
    _save("tiles_field", _contact_sheet(_frames_of(atlas), 3))


def preview_items() -> None:
    atlas, _names = items.build_items_atlas()
    _save("items", _contact_sheet(_frames_of(atlas), 5))


def preview_ui() -> None:
    _save("ui_parts", _contact_sheet(_frames_of(ui_parts.build_ui_atlas()), 3))


PREVIEWERS: Dict[str, callable] = {
    "hero": preview_hero,
    "enemies": preview_enemies,
    "tiles": preview_tiles,
    "items": preview_items,
    "ui": preview_ui,
}


def main(argv: List[str]) -> int:
    targets: Sequence[str] = argv or list(PREVIEWERS.keys())
    unknown = [name for name in targets if name not in PREVIEWERS]
    if unknown:
        print(f"unknown target(s): {unknown}. available: {sorted(PREVIEWERS)}")
        return 1
    for target in targets:
        PREVIEWERS[target]()
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
