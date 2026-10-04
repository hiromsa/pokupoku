"""スクリーンショットの一部を切り出して拡大するデバッグ用ツール。

実行中の画面は 640x360 と小さいため、主人公の足元など 24x32 の枠だけでは
目視確認が難しい。切り出して拡大した画像を別名で書き出す。

使い方:
    python tools/debug/crop_preview.py tmp_preview/field_scene.png \
        tmp_preview/hero_zoom.png 308 164 24 32 6
"""

import sys
from pathlib import Path

from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parents[2]


def resolve(path_text: str) -> Path:
    """カレント依存の相対パスを、プロジェクト直下からのパスとして扱う。"""
    path = Path(path_text)
    return path if path.is_absolute() else PROJECT_ROOT / path


def crop(source: Path, target: Path, box: tuple[int, int, int, int], scale: int) -> None:
    """指定領域を切り出して拡大し、元画像と同じ不透明度で保存する。"""
    with Image.open(source) as image:
        region = image.convert("RGBA").crop(box)
        if scale > 1:
            region = region.resize((region.width * scale, region.height * scale), Image.NEAREST)
        target.parent.mkdir(parents=True, exist_ok=True)
        region.save(target)
    print(f"cropped {box} x{scale} -> {target}")


def main(argv: list[str]) -> int:
    if len(argv) < 6:
        print(__doc__)
        return 1
    source = resolve(argv[1])
    target = resolve(argv[2])
    box = (int(argv[3]), int(argv[4]), int(argv[3]) + int(argv[5]), int(argv[4]) + int(argv[6]))
    scale = int(argv[7]) if len(argv) > 7 else 4
    if not source.exists():
        print(f"missing source: {source}")
        return 1
    crop(source, target, box, scale)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
