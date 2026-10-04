# 開発進捗 (PROGRESS)

> 新しいセッションを開始したら、まず本ファイルと `docs/specification/README.md`、
> `docs/specification/ui.md` を読んで作業を引き継ぐこと (`.clinerules` 規定)。

- **最終更新**: 2026-10-04 (Phase 1 完了 / Phase 2 着手直前)
- **バージョン**: `0.0.1-beta.5`

---

## 1. 現在の状態

| フェーズ | 内容 | 状態 |
|---|---|---|
| Phase 0 | 基盤スキャフォールド (Godot 導入 / テストランナー / ドキュメント) | **完了** |
| Phase 1 | ドット絵アセット生成パイプライン | **完了** |
| Phase 2 | マップ移動と UI のモック | 未着手 (**次・ユーザー合意済み**) |
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

## 3. Phase 1 で完了した内容 (コミット `d886b61`, `d64e94b`)

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

## 4. 検証結果

| 検証 | 結果 |
|---|---|
| `python tools/asset_gen/generate_all.py` | 26 PNG + 5 JSON を生成 (EXIT=0) |
| `python tools/asset_gen/verify.py` | **checks=500 failures=0** |
| `godot --headless --path . --import` | 成功 (EXIT=0)、ERROR なし |
| `godot --headless --path . --script res://tests/run_tests.gd` | **cases=25 assertions=453 failures=0 (RESULT: OK, EXIT=0)** |

テスト内訳: `ProjectConfigTest` / `UiPaletteTest` / `VersionTest` /
`AssetManifestTest` / `SpriteSheetLayoutTest`

Phase 0 で出ていた `WARNING: Asset manifest not found: res://assets/images/manifest.json` は
解消済み (audio 側は未配置のまま)。

## 5. 判明した注意点 (次回以降も必ず遵守)

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

## 6. 次の作業 (優先順)

**Phase 2 本実装に入る (ユーザー合意済み: タイルマップ + 移動 + HUD まで)**。
`FieldScene.gd` は現在も Phase 0 の暫定プレースホルダ (ColorRect + Label のみ) なので作り替える。

1. **`src/field/TileMapModel.gd`** — タイルグリッドのモデル (純ロジック, Node 非依存)
   - セル値はタイル ID 文字列 (`tile.grass` 等)。当たり可否は別テーブル
   - シード固定の決定論的生成 (テスト可能)。`tile_index.json` の ID だけを使う
2. **`src/field/FieldTileRenderer.gd`** — モデルを受けて `Sprite2D` + `AtlasTexture` で描画
   - 参照は `SpriteSheetLayout` 経由 (`tiles.field`)。`res://` 直指定禁止
3. **`src/field/MovementController.gd`** — 4 方向移動・当たり判定・方向保持 (純ロジック)
   - `InputRouter` の論理入力を購読する形にして UI 側と疎結合に保つ
4. **`src/field/FieldHero.gd`** — 主人公ビュー (方向 + 歩行アニメ)
   - フレーム: `hero.field.<dir>.{stand,step_l,step_r}`
   - アニメ方式未定: `AnimatedSprite2D` + `SpriteFrames` に積むか、手動で `texture` 差し替えか
5. **`src/ui/HudLayout.gd`** — ステータス窓 / メッセージ窓 (`ui.parts` の `panel_9slice` を NinePatch で)
6. **`src/scene/FieldScene.gd`** — 上記の組立て (View は状態を上位で管理する疎結合構成を維持)
7. **テスト追加**: `TileMapModelTest` (決定論生成・当たり判定) / `MovementControllerTest`
   / `FieldAssetLookupTest` (hero/tiles のフレーム解決スモーク)
8. `docs/specification/ui.md` に HUD・フィールドレイアウトの決定事項を追記 (**義務**)

## 7. 未確定事項 (ユーザー確認が必要)

- ステータス窓の `MP` の意味 (主人公は MP 魔法を使わない設計のため)
- 戦闘メッセージ窓にパネル枠を付けるか (サンプルでは素の文字描画)
- BGM/SE WAV が未入手。8bit 風 WAV を程序生成するか、提供を待つか
- Web 配布時のパッド / タッチ操作の要否
- **(新) フィールド歩行アニメの実装方式**: `AnimatedSprite2D` + `SpriteFrames` か手動フレーム切替か
- **(新) Phase 2 のテスト用マップ**: 1 エリア (例: 村 + 森) で十分か、初期エリア数を確定させるか
- **(新) 当たり判定の粒度**: タイル単位の 4 方向のみか、斜め移動も許すか (現状の論理入力は 4 方向想定)
