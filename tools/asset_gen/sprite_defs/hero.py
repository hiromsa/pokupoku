"""主人公「ゆうしゃ」のスプライト定義。

設計方針:
  - 頭部 / 胴体 / 脚 / 剣 の 4 部品に分け、向きと歩行は部品の差し替えで表現する。
    フレームごとに 24x32 の ASCII を書き写すと修正が 12 箇所に波及するため避けている。
  - 剣を持つ手が左右非対称なので、左右向きは flip_h せず別部品で構成する。

シート構成:
  hero_field.png  : 3 列 (stand / step_l / step_r) x 4 行 (down/up/left/right) = 12 フレーム
  hero_battle.png : 4 フレーム (idle / attack / damage / victory)
"""

from typing import Dict, List, Sequence, Tuple

from pixel_canvas import Sheet, Sprite

FIELD_CELL = (24, 32)
BATTLE_CELL = (48, 64)

# ---------------------------------------------------------------- 頭部 (12 x 10)

HEAD_DOWN: Sequence[str] = (
    "..KKKKKKKK..",
    ".KTTTTTTTTK.",
    "KTTTTTTTTTTK",
    "KTDDDDDDDDTK",
    "KTDKKDDKKDTK",
    "KTDKKDDKKDTK",
    "KTDDDDDDDDTK",
    "KTDDDKKDDDTK",
    ".KDDDDDDDDK.",
    "..KKKKKKKK..",
)

HEAD_UP: Sequence[str] = (
    "..KKKKKKKK..",
    ".KTTTTTTTTK.",
    "KTTTTTTTTTTK",
    "KTTTTTTTTTTK",
    "KTTTTTTTTTTK",
    "KTTTTTTTTTTK",
    "KTTTTTTTTTTK",
    "KTTTTTTTTTTK",
    ".KTTTTTTTTK.",
    "..KKKKKKKK..",
)

# 右向き: 前髪が左、目と口は右寄りに寄せる
HEAD_RIGHT: Sequence[str] = (
    "..KKKKKKKK..",
    ".KTTTTTTTTK.",
    "KTTTTTTTTTTK",
    "KTTTTDDDDDTK",
    "KTTTTDKKDDTK",
    "KTTTTDKKDDTK",
    "KTTTTDDDDDTK",
    "KTTTTTDDKDTK",
    ".KTTDDDDDDK.",
    "..KKKKKKKK..",
)

# ---------------------------------------------------------------- 胴体 (12 x 9)

TORSO: Sequence[str] = (
    "..KKKKKKKK..",
    ".KwwwwwwwwK.",
    "KwwWwwwwWwwK",
    "KwwwwwwwwwwK",
    "KwwwwwwwwwwK",
    "KwwRRRRRRwwK",
    "KTTTTTTTTTTK",
    "KwwwwwwwwwwK",
    ".KKKKKKKKKK.",
)

# 勝利ポーズ: 両腕を上げた胴体 (12 x 9)
TORSO_CHEER: Sequence[str] = (
    "KwwKKKKKKwwK",
    "KwwKKKKKKwwK",
    ".KwwwwwwwwK.",
    "KwwWwwwwWwwK",
    "KwwwwwwwwwwK",
    "KwwRRRRRRwwK",
    "KTTTTTTTTTTK",
    ".KwwwwwwwwK.",
    "..KKKKKKKK..",
)

# ---------------------------------------------------------------- 脚 (12 x 7)

LEGS_STAND: Sequence[str] = (
    ".KwwwwwwwwK.",
    ".KwwKKKKwwK.",
    ".KwwK..KwwK.",
    ".KwwK..KwwK.",
    ".KmmK..KmmK.",
    "KmmmK..KmmmK",
    "KKKKK..KKKKK",
)

# 左足を一歩上げた状態。右足は接地したまま。
LEGS_STEP_L: Sequence[str] = (
    ".KwwwwwwwwK.",
    ".KwwKKKKwwK.",
    ".KwwK..KwwK.",
    ".KmmK..KwwK.",
    "KmmmK..KwwK.",
    "KKKKK..KmmK.",
    "......KmmmK.",
)

# ---------------------------------------------------------------- 剣 (5 x 14)

SWORD_DOWN: Sequence[str] = (
    "..KK.",
    ".KLLK",
    ".KLLK",
    ".KLLK",
    ".KLLK",
    ".KLLK",
    ".KLLK",
    ".KLLK",
    ".KLLK",
    ".KLLK",
    "KYYYK",
    "..KyK",
    "..KyK",
    "..KK.",
)

# 振り下ろし: 刃を水平に構える (14 x 5)
SWORD_SWING: Sequence[str] = (
    "..KKKKKKKKKK..",
    ".KLLLLLLLLLLLK",
    "KYYyyyyyyyyyyK",
    ".KKKKKKKKKKKK.",
    "............K.",
)

# ---------------------------------------------------------------- 配置

BODY_X = 5
HEAD_Y = 5
TORSO_Y = 15
LEGS_Y = 24
# 剣は柄 (鍔) が胴体の腰線に接する位置に置く。浮いて見えないため x は胴体輪郭に付ける。
SWORD_Y = 11
SWORD_X_RIGHT = 16
SWORD_X_LEFT = 3

DIRECTIONS: Tuple[str, ...] = ("down", "up", "left", "right")
WALK_PHASES: Tuple[str, ...] = ("stand", "step_l", "step_r")


def _head(direction: str) -> Sprite:
    if direction == "down":
        return Sprite.from_ascii(HEAD_DOWN)
    if direction == "up":
        return Sprite.from_ascii(HEAD_UP)
    if direction == "right":
        return Sprite.from_ascii(HEAD_RIGHT)
    if direction == "left":
        return Sprite.from_ascii(HEAD_RIGHT).flipped_h()
    raise ValueError(f"unknown direction: {direction}")


def _legs(phase: str) -> Sprite:
    if phase == "stand":
        return Sprite.from_ascii(LEGS_STAND)
    if phase == "step_l":
        return Sprite.from_ascii(LEGS_STEP_L)
    if phase == "step_r":
        return Sprite.from_ascii(LEGS_STEP_L).flipped_h()
    raise ValueError(f"unknown walk phase: {phase}")


def _sword(facing_left: bool) -> Sprite:
    sword = Sprite.from_ascii(SWORD_DOWN)
    return sword.flipped_h() if facing_left else sword


def build_field_frame(direction: str, phase: str) -> Sprite:
    """フィールド用の 24x32 フレームを 4 部品から組み立てる。"""
    canvas = Sprite.blank(*FIELD_CELL)
    canvas = canvas.merged_over(_head(direction), BODY_X, HEAD_Y)
    canvas = canvas.merged_over(Sprite.from_ascii(TORSO), BODY_X, TORSO_Y)
    canvas = canvas.merged_over(_legs(phase), BODY_X, LEGS_Y)

    facing_left = direction == "left"
    sword_x = SWORD_X_LEFT if facing_left else SWORD_X_RIGHT
    canvas = canvas.merged_over(_sword(facing_left), sword_x, SWORD_Y)
    return canvas


def build_hero_field_sheet() -> Sheet:
    """3 列 (stand/step_l/step_r) x 4 行 (down/up/left/right) のシート。"""
    sheet = Sheet(len(WALK_PHASES), len(DIRECTIONS), *FIELD_CELL)
    for row, direction in enumerate(DIRECTIONS):
        sprites = [build_field_frame(direction, phase) for phase in WALK_PHASES]
        names = [f"hero.field.{direction}.{phase}" for phase in WALK_PHASES]
        sheet.add_row(row, sprites, names)
    return sheet


# ---------------------------------------------------------------- 戦闘用 (48 x 64)

BATTLE_BODY_X = 12
BATTLE_HEAD_Y = 8
BATTLE_TORSO_Y = 28
BATTLE_LEGS_Y = 46
BATTLE_SWORD_X = 36
BATTLE_SWORD_Y = 18


def _x2(sprite: Sprite) -> Sprite:
    """戦闘スプライトはフィールド絵の 2 倍拡大で統一し、ピクセル密度を揃える。"""
    return sprite.scaled_nearest(2)


def _battle_body(torso_rows: Sequence[str] = TORSO, lunge: int = 0) -> Sprite:
    canvas = Sprite.blank(*BATTLE_CELL)
    x = BATTLE_BODY_X + lunge
    canvas = canvas.merged_over(_x2(Sprite.from_ascii(HEAD_DOWN)), x, BATTLE_HEAD_Y)
    canvas = canvas.merged_over(_x2(Sprite.from_ascii(torso_rows)), x, BATTLE_TORSO_Y)
    canvas = canvas.merged_over(_x2(Sprite.from_ascii(LEGS_STAND)), x, BATTLE_LEGS_Y)
    return canvas


def build_battle_idle(bob: int = 0) -> Sprite:
    return _battle_body().translated(0, bob)


def build_battle_attack() -> Sprite:
    """踏み込み + 水平斬り。剣を差し替えて胴体を 2px 前に出す。"""
    body = _battle_body(lunge=4)
    swing = _x2(Sprite.from_ascii(SWORD_SWING))
    return body.merged_over(swing, BATTLE_SWORD_X - 2, BATTLE_TORSO_Y - 2)


def build_battle_damage() -> Sprite:
    """被弾: のけぞり + 白フラッシュ。"""
    return _battle_body().translated(-4, 0).tinted("#FFFFFF", 0.7)


def build_battle_victory() -> Sprite:
    """勝利: 両腕を上げ、剣を頭上へ。"""
    body = _battle_body(torso_rows=TORSO_CHEER)
    sword = _x2(Sprite.from_ascii(SWORD_DOWN)).flipped_v()
    return body.merged_over(sword, BATTLE_SWORD_X - 4, BATTLE_HEAD_Y - 12)


def build_hero_battle_sheet() -> Sheet:
    sheet = Sheet(4, 1, *BATTLE_CELL)
    sheet.add_row(0, [
        build_battle_idle(0),
        build_battle_attack(),
        build_battle_damage(),
        build_battle_victory(),
    ], [
        "hero.battle.idle",
        "hero.battle.attack",
        "hero.battle.damage",
        "hero.battle.victory",
    ])
    return sheet
