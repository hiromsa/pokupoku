"""エネミー 10 種の定義。

各エネミーは build() で「静止画 (idle_a)」を 1 枚生成する。
idle_b / attack / damage は共通の差分変換 (上下ゆれ・踏み込み・白フラッシュ) で
導出するため、10 種 x 4 パターン = 40 枚を手書きしない。
個別モーションが必要なエネミーは attack_transform で上書きする。

シート構成 (enemy_<id>.png): 4 列 x 1 行 = idle_a / idle_b / attack / damage
"""

from dataclasses import dataclass, field
from typing import Callable, Dict, List, Optional, Sequence, Tuple

from draw import (
    draw_eyes_wide,
    draw_face,
    fill_ellipse,
    fill_polygon,
    fill_rect,
    new_canvas,
    shade_bottom,
    set_pixel,
)
from palette import hex_of
from pixel_canvas import Sheet, Sprite

FIELD_CELL = (32, 32)
BATTLE_CELL = (64, 64)
ANIMATION_PATTERNS: Tuple[str, ...] = ("idle_a", "idle_b", "attack", "damage")

BLACK = hex_of("K")
WHITE = hex_of("W")
OFFWHITE = hex_of("w")
DIM = hex_of("s")
NAVY = hex_of("N")
NAVY_DEEP = hex_of("n")
GOLD = hex_of("Y")
GOLD_DARK = hex_of("y")
RED = hex_of("R")
RED_DARK = hex_of("r")
ORANGE = hex_of("O")
ORANGE_DARK = hex_of("o")
BLUE = hex_of("B")
BLUE_DEEP = hex_of("b")
CYAN = hex_of("C")
GREEN = hex_of("G")
GREEN_DARK = hex_of("g")
BROWN = hex_of("T")
BROWN_DARK = hex_of("t")
SAND = hex_of("D")
STONE = hex_of("M")
STONE_DARK = hex_of("m")
STONE_LIGHT = hex_of("L")
PURPLE = hex_of("P")
PURPLE_DARK = hex_of("p")
FLAME = hex_of("F")
FLAME_MID = hex_of("S")

Transform = Callable[[Sprite], Sprite]


@dataclass(frozen=True)
class EnemyDef:
    """1 エネミー分の定義。ビルド関数とアニメーション差分だけを持つ。"""

    enemy_id: str
    display_name: str
    element: str
    build: Callable[[], Sprite]
    idle_bob: Tuple[int, int] = (0, 1)
    attack_shift: Tuple[int, int] = (2, 0)
    attack_transform: Optional[Transform] = None
    anchor_y: float = 1.0     # 浮遊キャラは 0.5 にして地面に固定しない


# ---------------------------------------------------------------- 1. ポクポク

def build_poku() -> Sprite:
    """サンプル画像に最も近い、青い丸い体に大きな白目。"""
    canvas = new_canvas(22, 20)
    fill_ellipse(canvas, 11, 10, 9.5, 8.5, BLUE)
    # 左上の高光
    fill_ellipse(canvas, 7, 5, 2.5, 1.5, CYAN)
    draw_eyes_wide(canvas, 11, 7, WHITE, BLACK, size=5)
    fill_rect(canvas, 9, 14, 4, 1, BLACK)
    # 手足 (体の輪郭の外にはみ出さないと黒縁が見えなくなるため 1px 外へ出す)
    fill_rect(canvas, 0, 10, 2, 3, BLUE_DEEP)
    fill_rect(canvas, 20, 10, 2, 3, BLUE_DEEP)
    fill_rect(canvas, 6, 18, 4, 2, BLUE_DEEP)
    fill_rect(canvas, 12, 18, 4, 2, BLUE_DEEP)
    shade_bottom(canvas, BLUE_DEEP, band_height=2)
    return canvas


# ---------------------------------------------------------------- 2. カレクサ

def build_karekusa() -> Sprite:
    """枯れ草の塊。細い葉を多角形で重ねる。"""
    canvas = new_canvas(20, 24)
    blades = [
        [(9, 23), (4, 22), (2, 8), (5, 4), (8, 14)],
        [(11, 23), (8, 22), (9, 3), (12, 1), (13, 12)],
        [(13, 23), (16, 22), (18, 9), (15, 5), (12, 15)],
    ]
    for blade in blades:
        fill_polygon(canvas, blade, SAND)
    for blade in blades:
        fill_polygon(canvas, [(p[0], p[1]) for p in blade[:3]], BROWN)
    # 根本の株
    fill_ellipse(canvas, 10, 21, 7.0, 3.0, BROWN)
    fill_ellipse(canvas, 10, 20, 5.0, 2.0, BROWN_DARK)
    draw_face(canvas, 10, 17, BLACK, mouth=True, eye_size=2)
    return canvas


# ---------------------------------------------------------------- 3. ドスン

def build_dosun() -> Sprite:
    """転がる岩の塊。ずんぐりした胴体に短い腕。"""
    canvas = new_canvas(24, 20)
    fill_polygon(canvas, [(3, 19), (1, 12), (5, 4), (13, 2), (21, 6), (23, 15), (19, 19)], STONE)
    fill_polygon(canvas, [(4, 19), (3, 14), (7, 8), (12, 7), (11, 19)], STONE_DARK)
    fill_polygon(canvas, [(8, 5), (12, 3), (16, 5), (13, 8)], STONE_LIGHT)
    draw_face(canvas, 13, 10, BLACK, mouth=True, eye_size=2)
    fill_rect(canvas, 0, 12, 3, 4, STONE_DARK)
    fill_rect(canvas, 21, 12, 3, 4, STONE_DARK)
    fill_rect(canvas, 6, 18, 5, 2, STONE_DARK)
    fill_rect(canvas, 14, 18, 5, 2, STONE_DARK)
    return canvas


# ---------------------------------------------------------------- 4. カチコチ

def build_kachikochi() -> Sprite:
    """六角柱の氷の結晶。"""
    canvas = new_canvas(20, 26)
    fill_polygon(canvas, [(10, 0), (17, 7), (17, 19), (10, 25), (3, 19), (3, 7)], CYAN)
    fill_polygon(canvas, [(10, 2), (15, 8), (15, 18), (10, 23)], BLUE)
    fill_polygon(canvas, [(5, 8), (9, 4), (9, 20), (5, 17)], WHITE)
    draw_face(canvas, 10, 11, BLUE_DEEP, mouth=True, eye_size=2)
    set_pixel(canvas, 10, 1, WHITE)
    set_pixel(canvas, 10, 24, WHITE)
    return canvas


# ---------------------------------------------------------------- 5. ヒュン

def build_hyun() -> Sprite:
    """渦を巻く風の塊。三つの弧で流れを表す。"""
    canvas = new_canvas(24, 18)
    fill_ellipse(canvas, 12, 9, 10.0, 7.0, OFFWHITE)
    fill_ellipse(canvas, 8, 5, 5.0, 2.0, CYAN)
    fill_ellipse(canvas, 16, 12, 5.0, 2.0, CYAN)
    fill_ellipse(canvas, 12, 9, 4.0, 2.5, WHITE)
    draw_face(canvas, 12, 8, BLACK, mouth=True, eye_size=2)
    # 後方へ流れる尾
    fill_rect(canvas, 21, 8, 3, 1, OFFWHITE)
    fill_rect(canvas, 22, 10, 2, 1, DIM)
    return canvas


# ---------------------------------------------------------------- 6. ユキダマ

def build_yukidama() -> Sprite:
    """雪玉。白地に淡い青で陰影を付ける。"""
    canvas = new_canvas(20, 20)
    fill_ellipse(canvas, 10, 10, 9.0, 9.0, WHITE)
    fill_ellipse(canvas, 10, 15, 7.0, 4.0, OFFWHITE)
    fill_ellipse(canvas, 6, 5, 2.5, 2.0, WHITE)
    draw_face(canvas, 10, 8, BLUE_DEEP, mouth=True, eye_size=2)
    set_pixel(canvas, 15, 13, OFFWHITE)
    set_pixel(canvas, 5, 14, OFFWHITE)
    return canvas


# ---------------------------------------------------------------- 7. ヤマヌシ

def build_yamanushi() -> Sprite:
    """山の主。大きな岩体に角と赤い目。"""
    canvas = new_canvas(30, 28)
    fill_polygon(canvas, [(2, 27), (0, 16), (5, 6), (15, 1), (25, 6), (29, 17), (26, 27)], STONE)
    fill_polygon(canvas, [(4, 27), (3, 18), (8, 10), (14, 9), (13, 27)], STONE_DARK)
    fill_polygon(canvas, [(16, 9), (23, 11), (25, 22), (17, 27)], STONE)
    fill_polygon(canvas, [(10, 22), (20, 22), (18, 27), (12, 27)], STONE_LIGHT)
    fill_polygon(canvas, [(6, 8), (3, 1), (9, 6)], GOLD)
    fill_polygon(canvas, [(24, 8), (27, 1), (21, 6)], GOLD)
    fill_rect(canvas, 10, 12, 3, 3, RED)
    fill_rect(canvas, 18, 12, 3, 3, RED)
    fill_rect(canvas, 11, 13, 1, 1, FLAME)
    fill_rect(canvas, 19, 13, 1, 1, FLAME)
    fill_rect(canvas, 13, 18, 5, 2, BLACK)
    fill_rect(canvas, 14, 18, 1, 2, WHITE)
    fill_rect(canvas, 16, 18, 1, 2, WHITE)
    return canvas


# ---------------------------------------------------------------- 8. チャプ

def build_chap() -> Sprite:
    """小さな炎。しずく形の重ね塗り。"""
    canvas = new_canvas(18, 22)
    fill_polygon(canvas, [(9, 0), (15, 10), (14, 18), (9, 21), (4, 18), (3, 10)], ORANGE)
    fill_polygon(canvas, [(9, 4), (13, 12), (12, 18), (9, 20), (6, 18), (5, 12)], FLAME_MID)
    fill_polygon(canvas, [(9, 9), (11, 15), (9, 19), (7, 15)], FLAME)
    draw_face(canvas, 9, 13, RED_DARK, mouth=True, eye_size=2)
    fill_rect(canvas, 8, 0, 2, 2, FLAME)
    return canvas


# ---------------------------------------------------------------- 9. 風の闇

def build_kaze_no_yami() -> Sprite:
    """闇を孕んだ風の渦。濃紺の中心に紫の縁取り。"""
    canvas = new_canvas(24, 24)
    fill_ellipse(canvas, 12, 12, 11.0, 11.0, PURPLE_DARK)
    fill_ellipse(canvas, 12, 12, 7.5, 7.5, NAVY)
    fill_ellipse(canvas, 12, 12, 4.0, 4.0, NAVY_DEEP)
    fill_ellipse(canvas, 7, 6, 3.0, 1.5, PURPLE)
    fill_ellipse(canvas, 17, 18, 3.0, 1.5, PURPLE)
    draw_eyes_wide(canvas, 12, 10, GOLD, BLACK, size=4)
    fill_rect(canvas, 10, 16, 4, 1, GOLD)
    return canvas


# ---------------------------------------------------------------- 10. 墓場の化け

def build_haka_bake() -> Sprite:
    """墓場に立つ半透明の化け。裾をギザギザにする。"""
    canvas = new_canvas(22, 26)
    fill_ellipse(canvas, 11, 11, 9.0, 10.0, OFFWHITE)
    fill_rect(canvas, 2, 11, 18, 10, OFFWHITE)
    for tooth_x in (2, 6, 10, 14, 18):
        fill_polygon(canvas, [(tooth_x, 21), (tooth_x + 4, 21), (tooth_x + 2, 25)], OFFWHITE)
    fill_ellipse(canvas, 8, 6, 3.0, 2.0, WHITE)
    fill_rect(canvas, 6, 9, 3, 3, NAVY)
    fill_rect(canvas, 13, 9, 3, 3, NAVY)
    fill_rect(canvas, 7, 10, 1, 1, WHITE)
    fill_rect(canvas, 14, 10, 1, 1, WHITE)
    fill_ellipse(canvas, 11, 16, 2.0, 1.5, NAVY_DEEP)
    return canvas


# ---------------------------------------------------------------- レジストリ

def _hop(sprite: Sprite) -> Sprite:
    return sprite.translated(3, -2)


ENEMY_DEFS: Sequence[EnemyDef] = (
    EnemyDef("poku", "ポクポク", "null", build_poku,
             attack_transform=_hop),
    EnemyDef("karekusa", "カレクサ", "wind", build_karekusa, idle_bob=(1, 0),
             attack_transform=lambda s: s.flipped_h().translated(2, 0)),
    EnemyDef("dosun", "ドスン", "earth", build_dosun,
             attack_transform=lambda s: s.translated(4, -3)),
    EnemyDef("kachikochi", "カチコチ", "ice", build_kachikochi, idle_bob=(0, -1),
             attack_transform=lambda s: s.translated(2, 1)),
    EnemyDef("hyun", "ヒュン", "wind", build_hyun, idle_bob=(0, -1), anchor_y=0.5,
             attack_transform=lambda s: s.translated(6, 0)),
    EnemyDef("yukidama", "ユキダマ", "ice", build_yukidama,
             attack_transform=lambda s: s.translated(3, -1)),
    EnemyDef("yamanushi", "ヤマヌシ", "earth", build_yamanushi,
             attack_transform=lambda s: s.translated(2, -2)),
    EnemyDef("chap", "チャプ", "fire", build_chap, idle_bob=(0, -1),
             attack_transform=lambda s: s.tinted(FLAME, 0.5).translated(2, -1)),
    EnemyDef("kaze_no_yami", "風の闇", "wind", build_kaze_no_yami, idle_bob=(1, -1),
             anchor_y=0.5, attack_transform=lambda s: s.translated(4, 0)),
    EnemyDef("haka_bake", "墓場の化け", "dark", build_haka_bake, idle_bob=(0, -2),
             anchor_y=0.6,
             attack_transform=lambda s: s.tinted(PURPLE, 0.4).translated(3, -1)),
)


def find_enemy_def(enemy_id: str) -> EnemyDef:
    for enemy_def in ENEMY_DEFS:
        if enemy_def.enemy_id == enemy_id:
            return enemy_def
    raise KeyError(f"Unknown enemy id: {enemy_id}")


def build_enemy_frames(enemy_def: EnemyDef) -> Dict[str, Sprite]:
    """idle_a から 4 パターンを導出し、すべて FIELD_CELL 揃えに直す。

    縁取り (1px 黒) はここで一括適用する。図形プリミティブの輪郭関数は
    破線になりやすいため、アルファからのダイレーションで確実に閉じた輪郭を作る。
    """
    base = enemy_def.build().outlined(BLACK)

    def place(sprite: Sprite) -> Sprite:
        return sprite.on_canvas(*FIELD_CELL, anchor_x=0.5, anchor_y=enemy_def.anchor_y)

    idle_a = place(base)
    idle_b = place(base.translated(*enemy_def.idle_bob))

    attack_source = (enemy_def.attack_transform(base) if enemy_def.attack_transform
                     else base.translated(*enemy_def.attack_shift))
    attack = place(attack_source)
    damage = place(base.translated(-2, 0).tinted(WHITE, 0.55))
    return {"idle_a": idle_a, "idle_b": idle_b, "attack": attack, "damage": damage}


def build_enemy_sheet(enemy_def: EnemyDef) -> Sheet:
    frames = build_enemy_frames(enemy_def)
    sheet = Sheet(len(ANIMATION_PATTERNS), 1, *FIELD_CELL)
    sheet.add_row(0, [frames[name] for name in ANIMATION_PATTERNS],
                  [f"enemy.{enemy_def.enemy_id}.{name}" for name in ANIMATION_PATTERNS])
    return sheet


def build_enemy_battle_sheet(enemy_def: EnemyDef) -> Sheet:
    """戦闘用はフィールド絵の 2 倍拡大。ピクセル密度を主人公と揃える。"""
    frames = build_enemy_frames(enemy_def)
    sheet = Sheet(len(ANIMATION_PATTERNS), 1, *BATTLE_CELL)
    scaled = [frames[name].scaled_nearest(2).on_canvas(
                  *BATTLE_CELL, anchor_y=enemy_def.anchor_y)
              for name in ANIMATION_PATTERNS]
    sheet.add_row(0, scaled,
                  [f"enemy.{enemy_def.enemy_id}.battle.{name}" for name in ANIMATION_PATTERNS])
    return sheet


def enemy_catalog_payload() -> List[Dict[str, str]]:
    """Godot 側のデータテーブルにも使えるメタ情報。"""
    return [
        {"id": enemy_def.enemy_id, "name": enemy_def.display_name,
         "element": enemy_def.element}
        for enemy_def in ENEMY_DEFS
    ]
