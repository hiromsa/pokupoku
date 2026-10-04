# 開発進捗 (PROGRESS)

> 新しいセッションを開始したら、まず本ファイルと `docs/specification/README.md`、
> `docs/specification/ui.md` を読んで作業を引き継ぐこと (`.clinerules` 規定)。

- **最終更新**: 2026-10-04 (Phase 2 のモック完了 / Phase 3 着手前)
- **バージョン**: `0.0.1-beta.14`

---

## 1. 現在の状態

| フェーズ | 内容 | 状態 |
|---|---|---|
| Phase 0 | 基盤スキャフォールド (Godot 導入 / テストランナー / ドキュメント) | **完了** |
| Phase 1 | ドット絵アセット生成パイプライン | **完了** |
| Phase 2 | マップ移動と UI のモック | **完了** (エンカウント・コマンド操作は未実装。次フェーズ) |
| Phase 3 | 戦闘システムの基礎 | 未着手 |
| Phase 4 | データ読み込みとフラグ管理 | 未着手 |
| Phase 5 | コンテンツ展開 (エリア1〜3 / 全10エネミー / 図鑑) | 未着手 |
| Phase 6 | Web エクスポート | 未着手 |

## 2. Phase 0 で完了した内容

### 環境

- Godot **4.7.2-stable** (win64) を `tools/godot/` に展開 (gitignore 済み)
  - 取得: `tools/fetch_godot.ps1` (GitHub Releases, 86 MB)
  - 実行: `tools/godot/Godot_v4.7.2-stable_win64_console.exe`
- 日本語ピクセルフォント **DotGothic16** (OFL) を `assets/fonts/` に同梱
- git 初期化。remote = `https://github.com/hiromsa/pokupoku`、branch = `main`
  - リポジトリ既存の `LICENSE` (MIT, Copyright (c) 2026 ほたて) を取り込み

### プロジェクト設定

- 内部解像度 **640×360**、タイル **32×32**、`Nearest` フィルタ、整数 2 倍表示
- autoload 7 種: `Version` / `EventBus` / `InputRouter` / `AssetRegistry` /
  `AudioManager` / `SaveManager` / `SceneRouter`
- 論理入力は `InputRouter` が実行時登録 (`project.godot` の `[input]` は使わない)

### 実装済みソース

```
src/Main.gd / Main.tscn              ブートストラップ
src/config/Version.gd                バージョン文字列生成
src/core/EventBus.gd                 シーン横断シグナル
src/core/InputRouter.gd              論理入力アクション登録
src/core/AssetRegistry.gd            論理アセットID -> 実パス (manifest.json 駆動)
src/core/AudioManager.gd             BGM/SE (アセット欠損時は無音で通過)
src/core/SaveManager.gd              user://saves/slot_N.json
src/core/SceneRouter.gd              シーン遷移 + フェード
src/ui/UiPalette.gd                  サンプル画像抽出パレット (単一定義元)
src/ui/UiFonts.gd                    DotGothic16 取得口
src/scene/TitleScene.gd/.tscn        タイトル (暫定)
src/scene/FieldScene.gd/.tscn        フィールド (暫定プレースホルダ)
```

### テスト

- 依存ゼロのテストランナー `tests/` を自作 (gdUnit 等のアドオンは不使用)
- 実行結果: **cases=13 assertions=50 failures=0 (RESULT: OK)**
  - `ProjectConfigTest` (7) / `UiPaletteTest` (3) / `VersionTest` (3)

### ドキュメント

- `docs/specification/README.md` (インデックス)
- `docs/specification/architecture.md` (レイヤ構成・依存ルール・テスト方針)
- `docs/specification/ui.md` (サンプル画像を実測したレイアウト・パレット)

## 3. Phase 1 で完了した内容 (コミット `2711509`, `13d8b21`)

### 生成パイプライン (`tools/asset_gen/`)

```
palette.py                11+ 色の単一定義元 (UiPalette.gd と色値一致をテストで担保)
pixel_canvas.py           Sprite (RGBA キャンバス) / SpriteSheet / 合成・縁取り・反転
draw.py                   fill_rect / fill_ellipse / fill_polygon / line 等の図形プリミティブ
sprite_defs/hero.py       主人公 (ASCII 部品合成)
sprite_defs/enemies.py    エネミー 10 種 (図形プリミティブ + 顔オーバーレイ)
sprite_defs/tiles_field.py タイル 24 種
sprite_defs/items.py      アイコン 10 種
sprite_defs/ui_parts.py   panel_9slice / cursor / face_poku / bgm_note / icon
generate_all.py           PNG + JSON インデックスを一括出力 (決定論的)
verify.py                 生成物の寸法・アルファ・シート整合を検証
preview.py                tmp_preview/ に拡大画像を書き出す (目視レビュー用, gitignore 済み)
```

### 生成アセット (26 PNG + 5 JSON)

| 論理アセットID | セル | 構成 | 実パス |
|---|---|---|---|
| `hero.field` | 24×32 | 4 方向 × {`stand`,`step_l`,`step_r`} = 12f (3 列 × 4 行) | `assets/images/hero/hero_field.png` |
| `hero.battle` | 48×64 | `idle`/`attack`/`damage`/`victory` | `assets/images/hero/hero_battle.png` |
| `enemy.<id>` | 32×32 | `idle_a`/`idle_b`/`attack`/`damage` | `assets/images/enemies/enemy_<id>.png` |
| `enemy.<id>.battle` | 64×64 | 同上 (フィールド版の 2 倍スケール) | `assets/images/enemies/enemy_<id>_battle.png` |
| `tiles.field` | 32×32 | 24 種 (6 列 × 4 行) | `assets/images/tiles/tiles_field.png` |
| `items.icons` | 16×16 | 10 種 | `assets/images/items/items.png` |
| `ui.parts` | 48×48 | `panel_9slice`/`cursor`/`face_poku`/`bgm_note` | `assets/images/ui/ui_parts.png` |

エネミー ID: `poku` / `karekusa` / `dosun` / `kachikochi` / `hyun` / `yukidama` /
`yamanushi` / `chap` / `kaze_no_yami` / `haka_bake`

タイル ID (`tile.` プレフィックス): `grass`, `grass_flower`, `dirt`, `dirt_path`,
`cracked_ground`, `water`, `water_shore_sand`, `tree`, `rock`, `big_rock`, `signboard`,
`house_wall`, `house_roof`, `wooden_door`, `stairs_up`, `stairs_down`, `town_road`,
`cave_floor`, `cave_wall`, `tower_floor`, `tower_wall`, `water_deep`, `fence`, `codex_stand`

### インデックス JSON

| ファイル | 用途 |
|---|---|
| `assets/images/manifest.json` | 論理アセットID → 実パス (`AssetRegistry` が読む) |
| `assets/images/sheets.json` | 各シートの cell / cols / rows / frames 順 (`SpriteSheetLayout` が読む) |
| `assets/images/tiles/tile_index.json` | タイル ID → フレーム名 |
| `assets/images/items/item_index.json` | アイテム ID → フレーム名 |
| `assets/data/enemy_catalog.json` | エネミーの図鑑カタログ (名前・属性・テーマ顔) |

### Godot 側 (`src/core/`)

- `SpriteSheetLayout.gd` (autoload, 8 番目): 論理アセットID + フレーム名 → `AtlasTexture`。
  シート幾何は `sheets.json` から導出し、`res://` 直指定はしない。
- `AssetRegistry.gd`: 必須/任意マニフェストを**遅延読み込み**。
  `--script` 実行時 (autoload 未起動) でも初期化順に依存せず動作する。
- `tests/diag_assets.gd`: 実行時アセット解決の診断スクリプト (手動実行用)。

### 目視レビューで実施した調整

- 主人公: 剣を胴体に接して保持させ、左向き時に剣が背面へ回らないようアンカー修正
- エネミー: 手足を塗るレイヤを追加。`damage` は色相反転ではなく白飛び気味の明部反転
- エネミー縁取り: 個別 stroke でなく **alpha dilation による中央適用** (破線化防止)
- アイテム: 16×16 で黒縁を足すと刃が潰えるため、**色階 (陰 1px) で立体化**。
  `boro_no_tsurugi` は錆びた茶色にして安物感を先出し
- UI: `cursor` を右向き三角 (`▶`) に修正 (当初は右下がり階段三角形だった)

## 4. Phase 2 で完了した内容 (コミット `285cdfb` `0f6b672` `46bc126`)

### domain 層 (すべて `RefCounted`。Node / autoload / 時間に非依存)

```
src/domain/data/TileCatalog.gd        tile_index.json → 表示名 / solid / base を解決
src/domain/data/MapDefinition.gd      assets/data/maps/*.json を読んだ結果
src/domain/map/TileMapModel.gd        グリッド + is_passable / base_tile_id_at / iter_tiles
src/domain/map/MapLayoutDecoder.gd    rows + glyphs → TileMapModel
src/domain/map/MovementController.gd  4 方向 1 タイル移動。step_progress / interpolated_tile
src/domain/anim/FrameAnimator.gd      フレーム名の循環進行 (looping / holding)
```

### view 層 (描画専用。ドメインを読むだけで状態を変えない)

```
src/ui/FieldTileLayer.gd    TileMapModel を _draw() で走査。下地 → 障害物の順
src/ui/FieldHeroSprite.gd   向き + 歩行位相で hero.field.<dir>.<phase> を差し替え
src/ui/PanelFrame.gd        ui.parts の panel_9slice を NinePatchRect で展開
src/ui/HudLayout.gd         ui.md §1 の座標で 4 窓 + ラベル。set_* で値を注入
src/scene/FieldScene.gd     読み込み・組立て・入力受付・HUD への値の流し込み
tools/debug/CaptureField.*  640×360 を tmp_preview/field_scene.png へ保存 (目視レビュー用)
```

### 下地 (base) タイル — 画面の穴をデータで塞いだ

- 木・岩・大岩・柵・看板・図鑑台は透過背景のため、そのまま描くと背景が透けて
  画面に穴として見えた (目視レビューで判明)。
- 対応: `tile_index.json` に **`base`** を追加し、`FieldTileLayer` が
  「下地の地面 → 障害物」の順で描画。通行判定は常に上層タイルのみ (`is_passable`)。
- 定義元は `tools/asset_gen/sprite_defs/tiles_field.py` の `BASE_TILES`
  (tree / rock / big_rock / fence / signboard → grass、codex_stand → cave_floor)。
- 検出は二重に張った: `verify.py` は PNG の透過ピクセルを実測して宣言漏れを、
  `PrototypeMapTest` はマップ上で下地が未登録 / 通行不可地面でないことを検出する。

### マップデータ (外部 JSON)

- `tools/asset_gen/prototype_map.py` → `assets/data/maps/prototype_village.json`
  (30×20、出現 (5,11)、`rows` 文字列アート + `glyphs` 対応表)。`generate_all.py` から常時実行。
- 地形の編集は GDScript を触らずにできる。行長不足が穴にならないよう生成時に全行の寸法を強制。

### テスト (新規・更新)

| ケース | 見ている内容 |
|---|---|
| `TileCatalogTest` | `solid` / `base` の解決。未知・自己参照・非文字列の base は無視 |
| `TileMapModelTest` | `is_passable`、`base_tile_id_at`、範囲外・空タイルは安全側 (通行不可) |
| `MapLayoutDecoderTest` | rows + glyphs の展開。未知 glyph は空タイル (通行不可) |
| `MovementControllerTest` | 1 タイル移動、壁では向きだけ、補間値、進行中は入力不可 |
| `FrameAnimatorTest` | `looping` / `holding`、秒数に応じた進行と循環 |
| `PrototypeMapTest` | 寸法・出現位置、外周封鎖、目印 3 地点への徒歩到達 (BFS)、水と家の遮蔽、下地の妥当性 |
| `FieldAssetLookupTest` | hero / tile / base / HUD のフレーム名が実行時に解決するか |

### 仕様ドキュメント

- `docs/specification/map-system.md` **新規** (タイル属性・下地規約・マップ JSON・移動・歩行アニメ)
- `docs/specification/ui.md` に §2 の実装方式と **§10 フィールドHUD 実装状況** を追記
  (旧 §10 未確定事項は §11 へ繰り下げ)
- `docs/specification/README.md` のインデックスを更新

### 主人公の待機アニメーション (足踏み) — 追加実装

静止中に「立っている」ことが分かるよう、**待機専用の位相循環**を domain 側へ追加した。

| ファイル | 内容 |
|---|---|
| `src/domain/anim/HeroFieldAnimation.gd` | **新規**。歩行 `[step_l, step_r]` (0.16s) と待機 `[stand, step_r, stand, step_l]` (0.5s) の位相選択を持つ。画像もノードも知らない純ロジック |
| `src/ui/FieldHeroSprite.gd` | 位相選択を `HeroFieldAnimation` へ委譲。view は位相名が変わったフレームだけテクスチャを差し替える |
| `tests/cases/HeroFieldAnimationTest.gd` | **新規**。位相の順序・待機と歩行の速さ差・停止時の stand 復帰・向き変更時の挙動 |
| `tests/cases/FieldAssetLookupTest.gd` | 全方向の **歩行 / 待機両方** の位相がシートに存在するかの検査へ拡張 |
| `tools/debug/CaptureField.gd` | 出力先と待機フレーム数を実行引数で上書き可能に (`-- res://tmp_preview/x.png 45`) |
| `tools/debug/crop_preview.py` | **新規**。スクショの指定領域を切り出して拡大する (目視レビュー用) |

- アセットは既存の `stand` / `step_l` / `step_r` をそのまま利用 (再生成不要)。
- 待機は 1 周期 2.0 秒。`stand` を間に挟むことで「フットタップの間」を作り、
  歩行と静止の中間に見える速度にした (テストで「2 倍以上遅い」ことを担保)。
- 実機検証のため、`FieldScene` のカメラ初期位置を主人公中心へ設定するよう修正
  (開始直後に画面が滑る症状を解消)。

## 5. 検証結果

| 検証 | Phase 1 | Phase 2 (現在) |
|---|---|---|
| `python tools/asset_gen/generate_all.py` | 26 PNG + 5 JSON | 26 PNG + 6 JSON (マップ JSON 増) |
| `python tools/asset_gen/verify.py` | checks=500 failures=0 | **checks=721 failures=0** (タイル属性・下地・マップ検査増) |
| `godot --headless --path . --import` | 成功、ERROR なし | 成功、ERROR なし |
| `godot --headless --path . --script res://tests/run_tests.gd` | cases=25 assertions=453 | **cases=77 assertions=1543 failures=0 (RESULT: OK)** |
| `godot --path . --rendering-driver opengl3 --quit-after 120 res://tools/debug/CaptureField.tscn` | 未実施 | 成功。`tmp_preview/field_scene.png` で目視確認済み |
| 待機アニメの連続キャプチャ (`CaptureField.tscn -- <out.png> <待機フレーム数>`) | 未実施 | 0.5 秒ごとに `stand → step_r → stand → step_l` へ切り替わることを脚元の切り出し差分で確認。背景領域の差分 0 = カメラ静止 |

Phase 2 のテスト内訳: `ProjectConfigTest` / `UiPaletteTest` / `VersionTest` /
`AssetManifestTest` / `SpriteSheetLayoutTest` / `TileCatalogTest` / `TileMapModelTest` /
`MapLayoutDecoderTest` / `MovementControllerTest` / `FrameAnimatorTest` /
`HeroFieldAnimationTest` / `PrototypeMapTest` / `FieldAssetLookupTest`

Phase 1 の目視レビュー結果 (主人公・エネミー・アイテム・UI の調整) は §3 を参照。

Phase 0 で出ていた `WARNING: Asset manifest not found: res://assets/images/manifest.json` は
解消済み (audio 側は未配置のまま)。

## 6. 判明した注意点 (次回以降も必ず遵守)

1. **PowerShell 5.1 で日本語入りソースを編集してはいけない**
   `Set-Content -Encoding utf8` は BOM を付け、`-replace` は Shift-JIS として読み誤変換する。
   実際に `TitleScene.gd` が文字化けした。**必ずエディタ機能で編集する**。
2. `project.godot` のセクション名は内部設定名で接頭辞になる
   (`[application]` → `application/run/main_scene`、`[autoload]` → `autoload/<Name>`)
3. `Tween.tween_property()` の第 1 引数は Object。プロパティは `"color:a"` のように文字列で渡す
4. autoload や `Main._ready` 中の `change_scene_to_file()` はツリー構築と衝突する。
   `call_deferred` 経由で遅延させる
5. `docs/` は Godot のインポート対象外にしている (`docs/.gdignore`)。忘れると
   サンプル画像がテクスチャとして取り込まれる
6. `--script` 実行前に一度 `--headless --editor --quit` が必要
   (`.godot/global_script_class_cache.cfg` が無いと `class_name` が解決できない)
7. **PowerShell で `python -c "..."` の複数行コードは壊れる** (`\n` が行継続扱い)。
   再利用するスクリプトは必ず `tools/asset_gen/preview.py` のようにファイル化する
8. ドット絵の目視レビューは 1 倍では不可能。`preview.py` で 3〜6 倍に拡大した
   `tmp_preview/*.png` を `read_files` で見て判定する (tmp_preview は gitignore 済み)
9. アトラスのフレーム名は `<asset_id>.<frame>` の連結で `sheets.json` に保存済み。
   行優先 (row-major) 順なので、並びを変えると `verify.py` と Godot 側の両方が壊れる
10. **GDScript の真偽値は `true` / `false` (小文字)**。Python 風の `True` / `False` は
    そのまま構文エラーになる (domain 実装時に実際に発生)
11. **`const` に `PackedStringArray` は書けない** (定数式に許される型に限る)。
    文字列配列の定数は `static func` で毎回組み立てる (`FieldHeroSprite.walk_phases()`)
12. **Godot 実行中 (import / capture) に `.tscn` を編集すると失われることがある**。
    実際に `FieldScene.tscn` へのノード追加が一度消えた。シーンファイルを編集したら
    `Get-Content` で実ファイルを確認し、可能ならランタイム生成 (`add_child`) も併せておく
13. **PowerShell では Godot の stderr 出力で `$LASTEXITCODE` が 1 になる偽陽性がある**。
    成否は終了コードでなく `RESULT: OK` / `failures=0` の行で判定する
14. 半透明タイルを足すときは `tile_index.json` の `base` も同時に足す。
    忘れると画面に背景色の穴として現れるが、実行時は無警告 (検査は `verify.py` と
    `PrototypeMapTest` が担う)
15. **キャプチャ画像は 1280×720 で書き出される** (内部 640×360 + `content_scale_factor = 2.0`)。
    `tools/debug/crop_preview.py` に渡す切り出し座標は **実画像ピクセル基準**
    (= 論理座標 × 2)。論理解像度で指定すると的を外れる。
16. **`Camera2D` は `make_current()` 時点の位置が補正の始点になる**。位置を設定せず current にすると
    (0,0) から滑り始める。位置を設定 → `make_current()` → `reset_smoothing()` の順で固定する。
17. **アニメの位相は「フレーム番号 ÷ 60」にはならない**。初フレームの `delta` が大きいため
    想定より進む。連続キャプチャでの検証は絶対時刻ではなく **差分の周期**
    (0.5 秒ごとにフレームが変わるか) で判定する。

## 7. 次の作業 (優先順)

**Phase 3 (戦闘システムの基礎) に入る**。ただし Phase 2 の残りを先に片付ける方が安全。

1. **ステータスシステム** — `domain/entity/Stats.gd` / `Character.gd` / `Hero.gd`
   - `FieldScene.PROTOTYPE_*` 定数を実データへ置換し、`HudLayout.set_status()` へ渡す
   - `docs/design.md` の能力値・レベル表を先に `docs/specification/battle-system.md` へ起こす
2. **コマンドメニューの操作化** — `InputRouter` の `action_confirm` / `action_cancel` で選択。
   `ui.parts` の `cursor` (▶) を選択行へ描画。`HudLayout` は表示専用のまま維持
3. **タイルインタラクション** — `しらべる` で前向きタイルの `label` をメッセージ窓へ。
   `codex_stand` で図鑑、`wooden_door` / 階段でエリア移動の足場を作る
4. **エンカウント** — `domain/map/EncounterTable.gd` (歩数 + タイル重みの乱数注入式)。
   草・森で発生し、水・道では発生しない。乱数は注入 (domain は乱数を知らない)
5. **Phase 3 本実装** — `domain/battle/` (ターン順 / ダメージ計算 / 属性弱点 / 敵AI / ログ)
   と戦闘シーン。`enemy.<id>.battle` (64×64) と `hero.battle` を使用
6. **タイトル → フィールドの開始フロー** — `TitleScene` の「はじめから」で
   `SceneRouter.goto()`。セーブスロット選択は Phase 4
7. **ドキュメントの整理** — `docs/specification/map-system.md` に旧構成の §1〜§7 が重複収録
   (現行は前半のみ)。削除するか「履歴」へまとめる。あわせて §3 / §4 のマップ例が
   実データ (`assets/data/maps/prototype_village.json` = 30×20) と食い違っている
   (`assets/maps/prototype_field.json` = 40×24 と記載)

## 8. 未確定事項 (ユーザー確認が必要)

- ステータス窓の `MP` の意味 (主人公は MP 魔法を使わない設計のため)
- 戦闘メッセージ窓にパネル枠を付けるか (サンプルでは素の文字描画)
- BGM/SE WAV が未入手。8bit 風 WAV を程序生成するか、提供を待つか
- Web 配布時のパッド / タッチ操作の要否
- パネル枠のドロップシャドウ (ui.md §2 に仕様あり / 未実装)。
  付けるなら 9 スライス画像側へ焼き込むのが安いが、枠の伸縮と相性が悪い

### Phase 2 で決定済み (相談済み・実装済み)

- **歩行アニメ**: `AnimatedSprite2D` + `SpriteFrames` でなく **手動フレーム切替**。
  アトラスをエディタへ焼き込まないため、アセット再生成がそのまま反映される
- **当たり判定の粒度**: **タイル単位の 4 方向のみ** (斜めなし)。
  `tile_index.json` の `solid` が単一の定義元
- **半透明タイルの下地**: `tile_index.json` の **`base`** で宣言。
  描画順は下地 → 障害物で、通行判定は常に上層タイルのみ
- **テスト用マップ**: **1 エリア (はじまりの草原 = 村 + 森 + 池)** で確定
  (`assets/data/maps/prototype_village.json`)
