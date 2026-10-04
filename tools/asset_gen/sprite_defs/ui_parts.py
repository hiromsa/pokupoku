"""UI パーツ (パネル枠・カーソル・顔オーナメント・アプリアイコン) 定義。

panel_9slice.png は Godot 側で NinePatchRect に使う 48x48 の 9 スライス画像。
枠線 2px + 角丸 4px は docs/specification/ui.md のパネル描画スタイルと一致させる。
"""

from draw import draw_eyes_wide, fill_ellipse, fill_rect, new_canvas, set_pixel
from palette import hex_of
from pixel_canvas import Sheet, Sprite

PANEL_SIZE = 48
BORDER = 2
CORNER = 4

NAVY_HEX = hex_of("N")
NAVY_DEEP_HEX = hex_of("n")
WHITE_HEX = hex_of("W")
BLACK_HEX = hex_of("K")
GOLD_HEX = hex_of("Y")
BLUE_HEX = hex_of("B")
CYAN_HEX = hex_of("C")


def _rounded_mask(sprite: Sprite, x: int, y: int, width: int, height: int,
                  corner: int, color_hex: str) -> None:
    """角を落とした矩形を描く。"""
    fill_rect(sprite, x + corner, y, width - corner * 2, height, color_hex)
    fill_rect(sprite, x, y + corner, width, height - corner * 2, color_hex)
    for corner_x, corner_y in ((x, y), (x + width - corner, y),
                               (x, y + height - corner), (x + width - corner, y + height - corner)):
        fill_rect(sprite, corner_x + 1, corner_y + 1, corner - 1, corner - 1, color_hex)


def build_panel_9slice() -> Sprite:
    """NinePatchRect 用の 48x48 パネル。中央は引き伸ばされる前提の単色地。"""
    canvas = new_canvas(PANEL_SIZE, PANEL_SIZE)
    # 外側の黒シャドウ (右下 2px)
    _rounded_mask(canvas, 2, 2, PANEL_SIZE - 2, PANEL_SIZE - 2, CORNER, BLACK_HEX)
    # 白枠
    _rounded_mask(canvas, 0, 0, PANEL_SIZE - 2, PANEL_SIZE - 2, CORNER, WHITE_HEX)
    # 濃紺の地
    _rounded_mask(canvas, BORDER, BORDER, PANEL_SIZE - 2 - BORDER * 2,
                  PANEL_SIZE - 2 - BORDER * 2, max(1, CORNER - BORDER), NAVY_HEX)
    # 内側の深い影 (上辺に 1px の明るい縁)
    fill_rect(canvas, BORDER, BORDER, PANEL_SIZE - BORDER * 2, 1, NAVY_DEEP_HEX)
    return canvas


def build_cursor() -> Sprite:
    """コマンド選択の三角カーソル (8x8)。行中央で幅が最大になる右向き三角。"""
    canvas = new_canvas(8, 8)
    for row in range(8):
        distance_from_center = abs(row - 3) if row < 4 else abs(row - 4)
        fill_rect(canvas, 0, row, 4 - distance_from_center, 1, WHITE_HEX)
    return canvas


def build_face_poku() -> Sprite:
    """テーマ記号 `(・.・)` の顔オーナメント (16x16)。"""
    canvas = new_canvas(16, 16)
    fill_ellipse(canvas, 8, 8, 7.0, 7.0, BLUE_HEX)
    draw_eyes_wide(canvas, 8, 6, WHITE_HEX, BLACK_HEX, size=4)
    fill_rect(canvas, 6, 12, 4, 1, BLACK_HEX)
    return canvas


def build_bgm_note() -> Sprite:
    """BGM インジケータの音符 (12x12)。"""
    canvas = new_canvas(12, 12)
    fill_ellipse(canvas, 4, 9, 3.0, 2.5, WHITE_HEX)
    fill_rect(canvas, 6, 2, 2, 8, WHITE_HEX)
    fill_rect(canvas, 7, 2, 4, 2, WHITE_HEX)
    fill_rect(canvas, 10, 4, 1, 3, WHITE_HEX)
    return canvas


def build_app_icon(size: int = 64) -> Sprite:
    """Web / デスクトップ用のアプリアイコン。濃紺地にポクポクの顔。"""
    canvas = new_canvas(size, size)
    fill_rect(canvas, 0, 0, size, size, NAVY_HEX)
    fill_rect(canvas, 0, 0, size, 2, WHITE_HEX)
    fill_rect(canvas, 0, size - 2, size, 2, WHITE_HEX)
    fill_rect(canvas, 0, 0, 2, size, WHITE_HEX)
    fill_rect(canvas, size - 2, 0, 2, size, WHITE_HEX)
    scale = size // 64
    face = build_face_poku().scaled_nearest(max(1, scale * 4))
    return canvas.merged_over(face, (size - face.width) // 2, (size - face.height) // 2)


def build_ui_atlas() -> Sheet:
    """UI パーツを 1 列に並べたシート (panel / cursor / face / bgm)。"""
    parts = [build_panel_9slice(), build_cursor(), build_face_poku(), build_bgm_note()]
    cell = max(part.height for part in parts)
    cell_width = max(part.width for part in parts)
    sheet = Sheet(1, len(parts), cell_width, cell)
    for row, (part, name) in enumerate(zip(parts, ("panel_9slice", "cursor", "face_poku", "bgm_note"))):
        sheet.add(0, row, part.on_canvas(cell_width, cell), f"ui.{name}")
    return sheet
