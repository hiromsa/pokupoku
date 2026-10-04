"""RPG『ポクポク』ドット絵アセット生成ツール群。

手書き PNG を溜め込む代わりに、ASCII ピクセルマップを定義元として PNG を生成する。
生成物がコードから決定的に決まるため、差分レビュー・再生成・検証が可能になる。

使い方:
    python tools/asset_gen/generate_all.py      # 全アセット生成
    python tools/asset_gen/verify.py            # 生成物の整合検証

設計方針:
  - palette.py   : 色はここに単一定義元 (docs/specification/ui.md と一致させる)
  - pixel_canvas : ASCII -> RGBA 変換と合成・反転・彩色などのプリミティブ
  - sprite_defs/ : 各スプライトの定義。共通部品を再利用して差分で表現する
"""
