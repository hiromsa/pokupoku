# マップ・移動システム仕様

- **ステータス**: 暫定 (Phase 2 でモックフィールドまで実装済み。エリア追加時に拡張予定)
- **実装**: `src/domain/data/` `src/domain/map/` `src/domain/anim/` (純ロジック)
  / `src/ui/FieldTileLayer.gd` `src/ui/FieldHeroSprite.gd` (描画専用)

## 1. レイヤ分担

| レイヤ | 担当 | 役割 |
|---|---|---|
| domain | `MapDefinition` | マップメタ (ID / 名称 / 出現位置 / glyph テーブル / 行) |
| domain | `TileCatalog` | `tile_index.json` からタイル属性 (通行可否 / 下地) を解決 |
| domain | `TileMapModel` | 2 次元タイルグリッド。`tile_id_at` / `is_passable` / `base_tile_id_at` |
| domain | `MapLayoutDecoder` | 文字列アート + glyph テーブル → `TileMapModel` |
| domain | `MovementController` | 4 方向移動。1 タイル単位のステップ進行と補間値 |
| domain | `FrameAnimator` | フレーム名の循環進行 (秒 → 現在フレーム名) |
| view | `FieldTileLayer` | `TileMapModel` を `_draw()` で読むだけ。状態を変えない |
| view | `FieldHeroSprite` | 向きと歩行位相からテクスチャを差し替えるだけ |
| scene | `FieldScene` | 読み込み・組立て・入力受付・HUD への値の流し込み。ロジックを書かない |

`domain/` は `Node` / `CanvasItem` / `ProjectSettings` / autoload に依存しない (起動順に依存しない)。
経過時間・入力はすべて `advance()` 等の引数で注入する。

## 2. タイルデータ (`assets/images/tiles/tile_index.json`)

生成側 `tools/asset_gen/sprite_defs/tiles_field.py` が `TILE_BUILDERS` から出力する。

| フィールド | 型 | 意味 |
|---|---|---|
| `id` (キー) | string | タイル ID (`grass` 等)。アトラスフレーム名は `tile.<id>` |
| `frame_index` | int | アトラス上の位置 (6 列 row-major) |
| `solid` | bool | `true` で通行不可。**当たり判定の単一の定義元** |
| `base` | string | 透明部分を持つタイルの下に敷く地面タイル ID (省略可) |

### 下地 (base) の規約

- 透過ピクセルを持つタイルは、`solid` の可否に関係なく `base` を宣言する。
  宣言漏れは `verify.py` が PNG の透過ピクセル実測で検出し、
  `PrototypeMapTest` がマップ側 (下地が未登録 / 下地が通行不可地面でない) を検出する。
- 描画順は **下地 → 上層タイル** (`FieldTileLayer._draw_tile`)。
- 通行判定は常に上層タイルのみで決まる (`is_passable`)。
  `base` は見た目のためのデータで、当たり判定へ影響しない。
- `base` に未知 ID / 自分自身 / 非文字列を指定した場合は「下地なし」として扱う
  (`TileCatalog.base_tile_id`)。

| 上層タイル | 下地 | 通行 |
|---|---|---|
| `tree` / `rock` / `big_rock` / `fence` | `grass` | 不可 |
| `signboard` | `grass` | 可 |
| `codex_stand` | `cave_floor` | 可 |

## 3. マップデータ (`assets/data/maps/<map_id>.json`)

`tools/asset_gen/prototype_map.py` が生成する (地形編集は GDScript を触らずにできる方針)。

```json
{
  "id": "prototype_village",
  "name": "はじまりの草原",
  "spawn": { "x": 5, "y": 11 },
  "glyphs": { "T": "tree", "g": "grass", "p": "dirt_path", "K": "codex_stand" },
  "rows": ["TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT", "..."]
}
```

- `rows` は行優先の文字列アート。1 文字 = 1 タイルの glyph キー。
- glyph → タイル ID の対応は JSON 内の `glyphs` が定義元 (コード側にハードコードしない)。
- 未対応の glyph は **空タイル** (`MapLayoutDecoder.VOID_GLYPH`) となり通行不可になる。
  行の長さ不足が穴にならないよう、生成側 `_validated_rows()` が
  全行がちょうど `MAP_WIDTH` であることを生成時に強制する。
- 出現位置が塞がっていても固まらないよう、`MovementController._clamp_to_passable` が
  最も近い通行可能セルへ寄せる (マップデータの抜けに対する保険)。

## 4. モックマップ (`prototype_village`)

- 30 × 20 タイル。上 = 森、中央 = はじまりの村 (家・図鑑台)、下 = 草原と池。
  外周は木と柵で塞ぎ、画面外へ出られない。
- 出現位置 `(5, 11)` (村の通り)。
- 決定論的 (ランダム不使用)。同じ入力は同じマップを作る。
- 検証:
  - `verify.py` → 全 glyph が既知タイル ID を指すこと。
  - `PrototypeMapTest` → 寸法・出現位置、外周が塞がれていること、
    目印 3 地点 (森・村の通り・池のほとり) が徒歩で到達可能であること (BFS)、
    水 / 家の壁 / 屋根が実際に塞ぐこと、使用タイルの下地が登録済み通行可能地面であること。

## 5. 移動仕様 (`MovementController`)

- 4 方向のみ (斜めなし)。1 操作で 1 タイル。`STEP_DURATION_SECONDS = 0.16`。
- 論理位置は常に整数タイル座標。移動中は `_step_from` → `_step_to` を
  `step_progress()` (0.0〜1.0) で補間した `interpolated_tile()` を view が位置換算に使う。
- 進行中は `try_step()` が false を返し、次の入力を受け付けない
  (キー押しっぱなしでも 1 タイルずつ進む)。
- 移動先が範囲外・空タイル・`solid` の場合は **向きだけ更新** して移動しない (壁を向く)。
- 入力は `InputRouter` の論理アクション (`move_up` / `move_down` / `move_left` / `move_right`)。
  `action_cancel` (X / Esc) でタイトルへ戻る。

## 6. 歩行アニメ (`FrameAnimator` + `FieldHeroSprite`)

- `FrameAnimator.looping(["step_l", "step_r"], 0.16)`。静止時は `stop()` + `reset()` で
  `stand` フレームを表示する。
- 進行中は `step_l` ⇄ `step_r` を 0.16 秒ごとに循環。秒 → 進行は `advance(delta)` で注入する。
- フレーム名は `hero.field.<dir>.<phase>`。`SpriteSheetLayout.get_frame_texture("hero.field", ...)`
  でランタイム解決する (`SpriteFrames` に焼き込まないため、アセット再生成がそのまま反映される)。
- 主人公はタイル中央 `(x + 0.5) * 32, (y + 0.5) * 32` に置く。`z_index = 10` でタイル上。
- カメラは `Camera2D`。マップ範囲へ limit を張り、`position_smoothing_speed = 8.0`。

## 7. 未実装 (次フェーズ)

- ステータスシステム (現状 `FieldScene` が暫定値を `PROTOTYPE_*` 定数で HUD へ流す)
- コマンドメニューの操作 (現状は表示のみ)、`しらべる` などのタイルインタラクション
- エンカウント (`EncounterTable`)、NPC / 会話、エリア接続・ワープ、階段の遷移
- 図鑑 (`codex_stand`) とのインタラクション

## 1. レイヤ分担

| レイヤ | 担当 | 役割 |
|---|---|---|
| domain | `MapDefinition` | マップメタ (ID / 名称 / 出現位置 / レイアウト行) |
| domain | `TileCatalog` | `tile_index.json` からタイル属性 (表示名 / 通行 / 下地) を解決 |
| domain | `TileMapModel` | 2 次元タイルグリッド。`tile_id_at` / `is_passable_at` / `base_tile_id_at` |
| domain | `MapLayoutDecoder` | 文字列レイアウト → `TileMapModel` |
| domain | `MovementController` | 4 方向移動。グリッド単位で移動可否を判定 |
| domain | `FrameAnimator` | 進行方向ごとのフレーム進行 (秒 → フレーム番号) |
| view | `FieldTileLayer` | `TileMapModel` を読んで `Sprite2D` を並べるだけ |
| view | `FieldHeroSprite` | `MovementController` の状態からテクスチャを差し替えるだけ |
| scene | `FieldScene` | 読み込み・組立て・入力受付・進行のみ。ロジックを書かない |

`domain/` は `Node` / `CanvasItem` / `ProjectSettings` に依存しない (autoload 起動順に依存しない)。

## 2. タイルデータ (`assets/images/tiles/tile_index.json`)

生成側 `tools/asset_gen/sprite_defs/tiles_field.py` が `TILE_DEFS` から出力する。

| フィールド | 型 | 意味 |
|---|---|---|
| `id` | string | タイル ID (`grass` 等)。アトラスフレームは `tile.<id>` |
| `label` | string | デバッグ用の日本語名 |
| `solid` | bool | `true` で通行不可。当たり判定の単一の定義元 |
| `base` | string | 半透明タイルの下に敷く地面タイル ID (省略可) |

### 下地 (base) の規約

- 透過ピクセルを持つ装飾タイルは、必ず `base` を宣言する。
  宣言漏れは `verify.py` が透過ピクセルの実測で検出し、`PrototypeMapTest` がマップ側で検出する。
- 描画順は **下地 → 上層タイル**。通行判定は常に上層タイルのみを参照する
  (`base` は見た目のためのデータであり、当たり判定へ影響しない)。
- `base` に未知 ID / 自分自身を指定した場合は「下地なし」として扱う (`TileCatalog.base_tile_id`)。

| 上層タイル | 下地 |
|---|---|
| `tree` / `rock` / `big_rock` / `signboard` / `fence` | `grass` |
| `codex_stand` | `cave_floor` |

## 3. マップデータ (`assets/maps/<map_id>.json`)

```json
{
  "id": "prototype_field",
  "name": "はじまりの草原",
  "width": 40,
  "height": 24,
  "spawn": { "x": 4, "y": 6 },
  "layout": ["gggg...", "..."]
}
```

- `layout` は行優先の文字列配列。1 文字 = 1 タイルのキー。
- キー対応は `MapLayoutDecoder.LAYOUT_KEYS` (単一の定義元)。
  `.` = grass, `,` = tall_grass, `T` = tree, `W` = wall, `H` = house_floor, `h` = house_door など。
- 読み込み時に **全タイル ID がカタログに存在する**ことを検証し、不正なら `is_valid()` で false を返す。
- 出現位置は必須。範囲外または通行不可のセルを指定した場合は
  範囲内から到達可能なセルへ自動で補正する (`_resolve_spawn`)。

## 4. プロトタイプマップ (`assets/maps/prototype_field.json`)

- 生成: `python tools/asset_gen/prototype_map.py` (`generate_all.py` から常時実行)。
- 40 × 24。草原 + 森 + 岩場 + 土の道 + 壁で囲まれた小屋 + 洞窟入口 + 水辺。
- 決定論的 (ランダム不使用)。同じ入力は同じマップを作る。
- 検証:
  - `verify.py` → 全セルが既知キーであること。
  - `PrototypeMapTest` → 全通行可能セルが出現位置から到達可能 (閉じ込め防止)、
    使用タイルがカタログに存在し、半透明タイルに下地が定義されていること。

## 5. 移動仕様 (`MovementController`)

- 4 方向のみ (斜めなし)。1 操作で 1 タイル。
- 進行中は入力を受け付けない。目的地へ到着後、次の入力を受け付ける
  (キー押しっぱなしでも 1 タイルずつ進む)。
- 移動先が範囲外または `solid` の場合は方向だけ更新して移動しない (壁を向く)。
- 位置は整数タイル座標。滑らかな移動は view 側の補間でなく
  `progress` (0.0〜1.0) を domain が保持し、view が位置換算に使う。

## 6. 歩行アニメ (`FrameAnimator`)

- 静止 (`STAND`) は 0 帧で常に stand フレーム。
- 進行中は `WALK_FRAME_NAMES[0]` (step_l) → `WALK_FRAME_NAMES[1]` (step_r) を
  `WALK_FRAME_SECONDS` ごとに交互へ。
- 秒 → フレーム番号の純関数 (`frame_index`)。テストは時間を注入して検証する。
- `SpriteFrames` (baked アトラス) は使わない。実行時に `SpriteSheetLayout` 経由で
  `AtlasTexture` を解決するため、アセット再生成がそのまま反映される。

## 7. 未実装 (次フェーズ)

- ステータスシステム (現状 `FieldScene` は暫定値を表示)
- コマンドメニューの操作 (現状は表示のみ)、`しらべる` などのタイルインタラクション
- エンカウント (`EncounterTable`)、NPC / 会話、エリア接続・ワープ
- `InputRouter` の論理入力 (`move_up` 等) の利用 (現状は `_input` で直接キー判定)
