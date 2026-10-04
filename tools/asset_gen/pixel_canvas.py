"""ASCII ピクセルマップ -> RGBA スプライト の変換と合成プリミティブ。

スプライト定義 (sprite_defs/*) はこの Sprite / Sheet だけを組み合わせて
最終 PNG を組み立てる。画像編集ソフトに依存しない。
"""

from __future__ import annotations

from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

from PIL import Image

from palette import TRANSPARENT_CHAR, hex_to_rgba, resolve

Rgba = Tuple[int, int, int, int]


class Sprite:
    """透過付き RGBA ビットマップの薄いラッパ。PIL.Image をそのまま保持する。"""

    def __init__(self, image: Image.Image) -> None:
        if image.mode != "RGBA":
            image = image.convert("RGBA")
        self.image = image

    # --- 生成 ---

    @classmethod
    def from_ascii(cls, rows: Sequence[str]) -> "Sprite":
        """文字列配列を 1px=1 文字として RGBA 化します。行長は揃っている必要があります。"""
        width = len(rows[0])
        for index, row in enumerate(rows):
            if len(row) != width:
                raise ValueError(f"row {index} has {len(row)} chars, expected {width}")

        image = Image.new("RGBA", (width, len(rows)), (0, 0, 0, 0))
        pixels = image.load()
        for y, row in enumerate(rows):
            for x, char in enumerate(row):
                pixels[x, y] = _resolve_char(char)
        return cls(image)

    @classmethod
    def blank(cls, width: int, height: int) -> "Sprite":
        return cls(Image.new("RGBA", (width, height), (0, 0, 0, 0)))

    # --- 基本情報 ---

    @property
    def width(self) -> int:
        return self.image.width

    @property
    def height(self) -> int:
        return self.image.height

    def size(self) -> Tuple[int, int]:
        return (self.image.width, self.image.height)

    # --- 変換 ---

    def flipped_h(self) -> "Sprite":
        return Sprite(self.image.transpose(Image.Transpose.FLIP_LEFT_RIGHT))

    def flipped_v(self) -> "Sprite":
        return Sprite(self.image.transpose(Image.Transpose.FLIP_TOP_BOTTOM))

    def translated(self, dx: int, dy: int) -> "Sprite":
        """同じ大きさのキャンバス上で dx,dy だけずらす (はみ出しは切り捨て)。"""
        moved = Image.new("RGBA", self.size(), (0, 0, 0, 0))
        moved.paste(self.image, (dx, dy))
        return Sprite(moved)

    def tinted(self, color_hex: str, alpha: float) -> "Sprite":
        """不透明部分だけを color_hex に alpha 割合で塗り潰す (被弾フラッシュ用)。"""
        target = hex_to_rgba(color_hex)
        out = self.image.copy()
        src = self.image.load()
        dst = out.load()
        blend = max(0.0, min(1.0, alpha))
        for y in range(self.height):
            for x in range(self.width):
                r, g, b, a = src[x, y]
                if a == 0:
                    continue
                dst[x, y] = (
                    int(r * (1 - blend) + target[0] * blend),
                    int(g * (1 - blend) + target[1] * blend),
                    int(b * (1 - blend) + target[2] * blend),
                    a,
                )
        return Sprite(out)

    def outlined(self, color_hex: str) -> "Sprite":
        """不透明ピクセルの 4 隣に輪郭を 1px 足す (フィールドオブジェクトの視認性確保)。"""
        edge = hex_to_rgba(color_hex)
        out = Image.new("RGBA", (self.width + 2, self.height + 2), (0, 0, 0, 0))
        src = self.image.load()
        dst = out.load()
        for y in range(self.height):
            for x in range(self.width):
                if src[x, y][3] == 0:
                    continue
                for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
                    tx, ty = x + 1 + dx, y + 1 + dy
                    if dst[tx, ty][3] == 0:
                        dst[tx, ty] = edge
        out.paste(self.image, (1, 1))
        return Sprite(out)

    def scaled_nearest(self, factor: int) -> "Sprite":
        return Sprite(self.image.resize(
            (self.width * factor, self.height * factor), Image.Resampling.NEAREST))

    def recolored(self, char_map: Dict[str, str]) -> "Sprite":
        """既存ピクセルを色値で置換する (属性違いの派生スプライト用)。"""
        replacements = {hex_to_rgba(k)[:3]: hex_to_rgba(v) for k, v in char_map.items()}
        out = self.image.copy()
        src = self.image.load()
        dst = out.load()
        for y in range(self.height):
            for x in range(self.width):
                r, g, b, a = src[x, y]
                if a == 0:
                    continue
                replacement = replacements.get((r, g, b))
                if replacement is not None:
                    dst[x, y] = replacement
        return Sprite(out)

    # --- 合成 ---

    def on_canvas(self, width: int, height: int,
                  anchor_x: float = 0.5, anchor_y: float = 1.0) -> "Sprite":
        """指定キャンバスへ配置する。anchor は 0.0〜1.0 の比率 (既定は 下中央)。"""
        canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        offset_x = int(round((width - self.width) * anchor_x))
        offset_y = int(round((height - self.height) * anchor_y))
        canvas.paste(self.image, (offset_x, offset_y), self.image)
        return Sprite(canvas)

    def merged_over(self, other: "Sprite", x: int, y: int) -> "Sprite":
        """other を self 上の x,y に重ねたコピーを返す (self は変更しない)。"""
        out = self.image.copy()
        out.paste(other.image, (x, y), other.image)
        return Sprite(out)

    def cropped(self, box: Tuple[int, int, int, int]) -> "Sprite":
        return Sprite(self.image.crop(box))

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        self.image.save(path)


class Sheet:
    """等間隔グリッドのスプライトシート。frame_index = row * cols + col で決まる。"""

    def __init__(self, cols: int, rows: int, cell_width: int, cell_height: int) -> None:
        self.cols = cols
        self.rows = rows
        self.cell_width = cell_width
        self.cell_height = cell_height
        self.image = Image.new("RGBA", (cols * cell_width, rows * cell_height), (0, 0, 0, 0))
        self.frame_names: List[str] = []

    def add(self, col: int, row: int, sprite: Sprite, name: str) -> None:
        if not (0 <= col < self.cols and 0 <= row < self.rows):
            raise ValueError(f"cell ({col},{row}) out of range {self.cols}x{self.rows}")
        if sprite.width > self.cell_width or sprite.height > self.cell_height:
            raise ValueError(
                f"sprite {name!r} {sprite.size()} exceeds cell "
                f"{self.cell_width}x{self.cell_height}")
        self.image.paste(sprite.image, (col * self.cell_width, row * self.cell_height), sprite.image)
        self._register(name, row * self.cols + col)

    def add_row(self, row: int, sprites: Sequence[Sprite], names: Sequence[str]) -> None:
        if len(sprites) != len(names):
            raise ValueError("sprites and names length mismatch")
        for col, (sprite, name) in enumerate(zip(sprites, names)):
            self.add(col, row, sprite, name)

    def frame_count(self) -> int:
        return self.cols * self.rows

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        self.image.save(path)

    def _register(self, name: str, frame_index: int) -> None:
        while len(self.frame_names) <= frame_index:
            self.frame_names.append("")
        self.frame_names[frame_index] = name


def _resolve_char(char: str) -> Rgba:
    if char == TRANSPARENT_CHAR or char == " ":
        return (0, 0, 0, 0)
    return resolve(char)
