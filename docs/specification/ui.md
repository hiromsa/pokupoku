# UI 仕様

- **ステータス**: 暫定 (Phase 0 でサンプル画像から実測した値。Phase 2 のフィールドHUD を
  §10 の通り実装済み。戦闘・図鑑のレイアウトは未実装のため調整の可能性がある)
- **出典**: `docs/sample_image/battle.jpg` / `enemies.jpg` / `field.jpg`
  のパネル領域を flood-fill で実測し、1024×559 → 640×360 へ 0.625 倍して確定した。

## 1. 全体共通レイアウト (640 × 360)

全シーン共通で次の固定要素を持つ。

| 要素 | 実測値 (1024px 基準) | 採用値 (640×360 基準) |
|---|---|---|
| タイトルバナー | x 326–697, y 7–93 (371×54) | **x 204, y 4, w 232, h 54** (水平中央) |
| BGM インジケータ | x 819–1013, y 7–49 (195×43) | **x 512, y 4, w 122, h 27** (右寄せ) |
| 下部バンド上端 | y 385 / 559 | **y 240** |
| 外周マージン | 10 px | **6 px** |

### 下部バンド (3 窓分割)

`design.md` の「画面下部にステータス、コマンド、メッセージを分割表示」に対応させる。

| 窓 | 位置・サイズ (640×360) | 内容 |
|---|---|---|
| `StatusWindow` | x 6, y 240, w 180, h 114 | 名前 / LV / HP / MP / 武器 |
| `MessageWindow` | x 192, y 240, w 316, h 82 | メッセージ本文・バトルログ |
| `CommandTab` | x 198, y 326, w 90, h 28 | `コ マ ン ド` 見出しタブ |
| `CommandMenu` | x 514, y 240, w 120, h 114 | 選択肢リスト |

## 2. パネル描画スタイル

`docs/sample_image` 全パネルに共通するスタイル。`ui/PanelFrame` で 9 スライス化して実装する。

| 属性 | 値 |
|---|---|
| 地色 | `#0D124A` (`UiPalette.PANEL_NAVY`) |
| 枠線 | 白 2 px (`UiPalette.PANEL_BORDER`) |
| 角 | 角丸 4 px |
| 外側ドロップシャドウ | 黒 2 px 右下オフセット |
| 見出し | 白文字・文字間 1 px・中央寄せ |

### 実装 (`src/ui/PanelFrame.gd` + `ui.parts` の `panel_9slice`)

- 枠の地・白線・角丸は **生成済み 9 スライス画像** (`assets/images/ui/ui_parts.png` の
  `panel_9slice` = 48×48) に焼き込む。GDScript 側で枠を再描画しない。
- 画像は `res://` を直接参照せず、`SpriteSheetLayout.get_frame_texture("ui.parts", "ui.panel_9slice")`
  で解決する (アセット再生成がそのまま反映される)。
- `PanelFrame` は `NinePatchRect`。四隅 8 px を保持して引き伸ばす
  (`PATCH_MARGIN = 8`。枠 2 px + 角丸 4 px が潰れない余白)。
- `mouse_filter = MOUSE_FILTER_IGNORE` で入力を素通しにする (HUD は表示専用)。
- 見出しは窓本体に描かず、`Label` を中央寄せで窓上端へ重ねる
  (`コ マ ン ド` のように全角スペース区がけで表現する)。
- 9 スライスのメタ (セル寸法・frame 名) は `assets/images/ui/ui_parts.json` が定義元。
  数値を GDScript へハードコードしない。
- **未実装**: 外側ドロップシャドウ (黒 2 px 右下)。Phase 2 のモックでは省略した。

## 3. カラーパレット (`src/ui/UiPalette.gd` が単一の定義元)

色値は `UiPalette.gd` 以外にハードコードしない。`tests/cases/UiPaletteTest.gd` が
サンプル画像からの抽出値と一致を検証する。

| 名前 | HEX | 用途 |
|---|---|---|
| `PANEL_NAVY` | `#0D124A` | パネル地 |
| `PANEL_NAVY_DEEP` | `#0B1048` | パネル地 (濃) |
| `PANEL_BORDER` | `#FFFFFF` | 枠線・本文 |
| `PANEL_SHADOW` | `#000000` | 影・輪郭 |
| `TEXT_PRIMARY` | `#FFFFFF` | 本文 |
| `TEXT_DIM` | `#9AA6D8` | 補足・ラベル |
| `TEXT_NAME` | `#F2C64C` | 名前・見出し (図鑑) |
| `SKY` | `#89CDCE` | 空 |
| `GRASS` | `#75A947` | 草原 |
| `GRASS_DARK` | `#3A5930` | 草原の影 |
| `DIRT` | `#956C40` | 割れ大地 |
| `DIRT_LIGHT` | `#C8934F` | 砂道 |
| `WATER` | `#2B7AC5` | 水面 |
| `WATER_HIGHLIGHT` | `#6FC2F4` | 水面高光 |
| `HP_GOOD` | `#5CD65C` | HP 正常 |
| `HP_WARN` | `#E8C34A` | HP 注意 |
| `HP_DANGER` | `#E05454` | HP 危険 |

## 4. フォント

- **DotGothic16 Regular** (SIL Open Font License 1.1)
  - `assets/fonts/DotGothic16-Regular.ttf`、`OFL.txt` を同梱
  - 取得元: `https://github.com/google/fonts` (`ofl/dotgothic16`)
- 取得は `UiFonts.pixel_font()` 経由。アセット欠損時はフォールバックフォントで継続
- サイズ基準 (640×360 内部解像度での推奨値)

| 用途 | px |
|---|---|
| タイトル (タイトル画面) | 48 |
| タイトルバナー | 20 |
| パネル見出し | 12 |
| 本文・コマンド | 12 |
| ステータス数値 | 11 |
| 補足・バージョン表示 | 10 |

## 5. コマンドメニューの選択表示

`battle.jpg` / `field.jpg` の表記を踏襲する。**カーソル記号ではなく括弧で囲む**。

```
【たたかう】どうぐ
にげる
ステータス
```

- 選択中: `【` と `】` で囲む。文字色 `TEXT_PRIMARY`
- 非選択: 括弧なし。文字色 `TEXT_DIM`
- 1 行 1 項目。行ピッチ 18 px

### シーン別コマンド

| シーン | 項目 |
|---|---|
| フィールド | `はなす` / `しらべる` / `つかう` / `システム` |
| 戦闘 | `たたかう` / `どうぐ` / `にげる` / `ステータス` |

## 6. ステータス窓の表記

| シーン | 行構成 |
|---|---|
| フィールド | `ステータス` (見出し) / `名前：ゆうしゃ` / `HP：25/25` / `MP：5/5` |
| 戦闘 | `名前：ゆうしゃ` / `LV：1` / `HP：20/20` / `武器：ぼろのつるぎ` |

- 主人公は MP 魔法を使わない (`design.md`) ため、`MP` は「魔法アイテムの使用回数」等の
  リソース表示として扱うか、Phase 3 で表示可否を確定する (**未確定**)

## 7. モンスター図鑑 (`enemies.jpg`)

| 項目 | 実測 (1024) | 採用 (640) |
|---|---|---|
| 見出しバナー | x 326–697, y 7–61 | タイトルバナーと共通 |
| エントリ列数 | 2 列 | 2 列 |
| エントリ行数 | 4 行 | 4 行 |
| エントリ行ピッチ | 116 px | **72 px** |
| スプライト枠 | 111 × 101 | **70 × 63** |
| テキスト枠 | 329 × 101 | **205 × 63** |

- スプライト枠: 白枠 + 濃紺地。`idle_a` フレームを中央配置
- エントリ名: `TEXT_NAME` (#F2C64C)
- 解説文: `TEXT_PRIMARY`、1 行 20 字程度で折り返し

## 8. デザインテーマ「(・.・)」

`design.md` のテーマ規定に従い、次の要素すべてに `(・.・)` の顔を持たせる。

- 主人公・全エネミー・ボス
- フィールドの **木・岩・大岩・看板**
- タイトルバナーの飾り、BGM インジケータの表示部

## 9. キーバインド

`InputRouter` の論理アクションに紐づく。

| 操作 | キー |
|---|---|
| 決定 | Z / Enter / Space |
| 取消・戻る | X / Esc |
| メニュー | C |
| 移動 | 矢印キー |

**パッド / タッチ操作は未対応** (Web 配布を考えると Phase 5 以降で検討)。

## 10. フィールドHUD 実装状況 (Phase 2)

`src/ui/HudLayout.gd` が §1 の実測座標で 4 窓を構築する。
位置・サイズは同ファイルの定数 (`STATUS_RECT` / `MESSAGE_RECT` / `COMMAND_TAB_RECT` /
`COMMAND_MENU_RECT`) が定義元で、シーン側には書かない。

### ノード構成 (`src/scene/FieldScene.gd`)

```
FieldScene (Node2D)
├─ TileLayer   (FieldTileLayer)  タイルを描くだけ。TileMapModel を読む
├─ Hero        (FieldHeroSprite) z_index = 10
├─ Camera      (Camera2D)        マップ範囲で limit、平滑追従 speed 8.0
└─ HudLayer    (CanvasLayer, layer = 10)
   └─ Hud      (HudLayout)
      ├─ StatusWindow / MessageWindow / CommandTab / CommandMenu (PanelFrame)
      └─ Label (見出し 2 + 本文 3)
```

- HUD は `CanvasLayer` に載せるため、カメラが動いても画面へ固定される。
- `HudLayout` は表示専用。状態を持たず、値は `set_status()` / `set_message()` /
  `set_commands()` で上位 (シーン) から注入する。
- コマンドは選択中のみ `【】` で囲む (§5)。1 行 1 項目・行ピッチ 18 px は
  `line_spacing` オーバーライド (18 − 12) で作る。
- 見出しは中央寄せ・文字間 1 px・12 px。本文 12 px、ステータス数値 11 px (§4 基準)。
- 色は `UiPalette`、フォントは `UiFonts.pixel_font()` 経由のみ (ハードコード禁止)。

### 主人公スプライト (`src/ui/FieldHeroSprite.gd`)

- `Sprite2D`。フレーム名 `hero.field.<dir>.<phase>` を `SpriteSheetLayout` でランタイム解決。
- `AnimatedSprite2D` + `SpriteFrames` は使わない。アトラスをエディタへ焼き込むと
  アセット再生成が反映されなくなるため。
- 歩行位相の進行は `domain/anim/FrameAnimator` が持ち、view はフレーム名を受け取るだけ。
- 拡大は nearest 必須 (`project.godot` の `default_texture_filter=0`、シーン側でも `texture_filter = 0`)。

### 目視レビューの手順

`tools/debug/CaptureField.tscn` を実行すると 640×360 の画面を
`tmp_preview/field_scene.png` へ保存する (`tmp_preview/` は gitignore 済み)。

```
tools/godot/Godot_v4.7.2-stable_win64_console.exe --path . \
  --rendering-driver opengl3 --quit-after 120 res://tools/debug/CaptureField.tscn
```

### 現状の暫定値 (Phase 2 モック)

| 項目 | 値 | 置き換え時期 |
|---|---|---|
| 名前 / HP / MP | `ゆうしゃ` / 25 / 5 (`FieldScene.PROTOTYPE_*` 定数) | ステータスシステム実装時 |
| メッセージ | 操作説明の固定文 | イベント・コマンド結果の表示 |
| コマンド | `はなす / しらべる / つかう / システム` を表示のみ | 選択操作の実装時 |

### HUD で未実装

- 外周ドロップシャドウ、タイトルバナー、BGM インジケータ
- コマンド選択カーソル (`cursor` アセット) と決定 / 取消の操作系

## 11. 未確定事項

- ステータス窓の `MP` の意味 (上記 6)
- 戦闘中のメッセージ窓にパネル枠を付けるか (サンプルでは素の文字描画になっている)
- ウィンドウリサイズ時の最小スケール (現状は 2 倍固定)
