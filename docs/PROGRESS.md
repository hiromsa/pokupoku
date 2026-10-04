# 開発進捗 (PROGRESS)

> 新しいセッションを開始したら、まず本ファイルと `docs/specification/README.md`、
> `docs/specification/ui.md` を読んで作業を引き継ぐこと (`.clinerules` 規定)。

- **最終更新**: 2026-10-04 (Phase 0 完了)
- **バージョン**: `0.0.1-beta.1`

---

## 1. 現在の状態

| フェーズ | 内容 | 状態 |
|---|---|---|
| Phase 0 | 基盤スキャフォールド (Godot 導入 / テストランナー / ドキュメント) | **完了** |
| Phase 1 | ドット絵アセット生成パイプライン | 未着手 (次) |
| Phase 2 | マップ移動と UI のモック | 未着手 |
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

## 3. 検証結果

| 検証 | 結果 |
|---|---|
| `godot --headless --editor --quit` (インポート) | 成功 (EXIT=0) |
| `godot --headless --script res://tests/run_tests.gd` | 全緑 (EXIT=0) |
| `godot --headless --quit-after 90` (ゲーム起動) | 成功。SCRIPT ERROR なし |

ゲーム起動時に出る警告は未配置アセットのみ (想定内):

```
WARNING: Asset manifest not found: res://assets/images/manifest.json
WARNING: Asset manifest not found: res://assets/audio/manifest.json
```
→ Phase 1 で `manifest.json` を生成すれば解消する。

## 4. 判明した注意点 (次回以降も必ず遵守)

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

## 5. 次の作業 (優先順)

1. **Phase 1: アセット生成パイプライン** (`tools/asset_gen/`)
   - `palette.py` — `UiPalette.gd` と同じ 11+ 色を単一定義元にする
   - `pixel_canvas.py` — ASCII ピクセルマップ → PNG、spritesheet 合成
   - `sprite_defs/hero.py` — 主人公: 4方向 × 歩行3フレーム (24×32) + 戦闘4ポーズ (48×64)
   - `sprite_defs/enemies.py` — 10 種 × 4パターン (`idle_a`/`idle_b`/`attack`/`damage`)
   - `sprite_defs/tiles_field.py` — 32×32 タイル 18 種 (`(・.・)` 付きの木・岩・大岩・看板含む)
   - `sprite_defs/items.py` — 16×16 アイコン 10 種
   - `sprite_defs/ui_parts.py` — `panel_9slice` / `cursor` / `face_poku` / `icon.png`
   - `generate_all.py` が `assets/images/manifest.json` を出力 (論理ID → 実パス)
   - `verify.py` で生成 PNG の寸法・アルファ・シート整合を検証
2. `UiPalette.gd` と `palette.py` の色値一致を検証するテストを追加する
   (Python 側と GDScript 側の二重定義を防ぐ)
3. Phase 2: `HudLayout` / `PanelFrame` / `StatusWindow` / `CommandMenu` / `MessageWindow`
   と `TileMapModel` / `MovementController` / `SpriteAnimator`

## 6. 未確定事項 (ユーザー確認が必要)

- ステータス窓の `MP` の意味 (主人公は MP 魔法を使わない設計のため)
- 戦闘メッセージ窓にパネル枠を付けるか (サンプルでは素の文字描画)
- BGM/SE WAV が未入手。8bit 風 WAV を程序生成するか、提供を待つか
- Web 配布時のパッド / タッチ操作の要否
