# アーキテクチャ仕様

- **ステータス**: 確定 (Phase 0)

## 1. エンジン選定

| 項目 | 決定 |
|---|---|
| エンジン | **Godot 4.7.2-stable** (GDScript) |
| 配置 | `tools/godot/` (gitignore 済み)。取得は `tools/fetch_godot.ps1` |
| 対象プラットフォーム | Web ブラウザ (HTML5)。デスクトップは開発中の動作確認用 |
| 選定理由 | デザイン指示書が許容する 2 案のうち、Godot を採用。ドメイン/UI 分離はレイヤ規約 (後述) で担保する |

Web エクスポートには `Godot_v4.7.2-stable_export_templates.tpz` (約 1.28 GB) が必要。
Phase 6 までダウンロードを遅延させ、それまでは headless 起動とユニットテストで検証する。

## 2. 画面解像度とグリッド

| 項目 | 値 | 根拠 |
|---|---|---|
| 内部解像度 | **640 × 360** | `docs/sample_image` の 3 枚 (1024×559 ≒ 16:9) と同じ比率 |
| 表示ウィンドウ | 1280 × 720 (整数 2 倍) | ドット絵を歪ませない |
| ストレッチ | `canvas_items` / `aspect=keep` | |
| タイルサイズ | **32 × 32** | 水平 20 タイル表示。サンプル画像と一致 |
| テクスチャフィルタ | `Nearest` (必須) | `default_texture_filter=0`。テストで固定 |

## 3. レヤ構成と依存ルール

上から下へ一方向にのみ依存する。下位レイヤが上位レイヤを知ってはいけない。

```
scene/          シーン合成・入力受付・演出のみ。ドメインを new するが、ロジックを書かない
  ├─ ui/        描画専用。ドメインの値を読み取って描く。状態変更をしない
  ├─ core/      Node 依存の基盤 (autoload)。シーン管理・入力・音声・保存
  └─ domain/    純粋ロジック。RefCounted のみ。Node / SceneTree / ProjectSettings へ依存しない
```

### 依存に関する規約 (テスト可能性の担保)

- `domain/` の全クラスは `RefCounted` を継承する。**Node・CanvasItem・autoload を参照しない**
- `domain/` は入力も時間も知らない。進行に必要な外部値 (乱数・経過時間) は引数で注入する
- `ui/` はドメインオブジェクトを**読むだけ**。状態を変える処理は `scene/` 経由
- シーン横断の通知は `EventBus` (autoload) のシグナルのみを使う。シーン間直接参照は禁止

### domain 内の分割

| パッケージ | 責務 |
|---|---|
| `domain/entity/` | `Stats` / `Character` / `Hero` / `Enemy` / `LevelTable` |
| `domain/item/` | `Item` / `MagicItem` / `ConsumableItem` / `Inventory` |
| `domain/battle/` | `Battle` / `BattleResolver` / `DamageCalculator` / `ElementAffinity` / `TurnOrder` / `FleeResolver` / `EnemyAi` / `BattleLog` |
| `domain/map/` | `TileMapModel` / `GameMap` / `MovementController` / `EncounterTable` / `Npc` |
| `domain/story/` | `FlagStore` / `DialogueRepository` / `EventRunner` |
| `domain/data/` | `DatabaseLoader` / `EnemyDatabase` / `ItemDatabase` / `MapDatabase` |

## 4. autoload (project.godot に登録済み)

登録順に初期化される。

| 名前 | 責務 |
|---|---|
| `Version` | バージョン情報生成 (`get_short_version` / `get_detailed_version`) |
| `EventBus` | シーン横断シグナルの中継点 |
| `InputRouter` | 論理入力アクションの実行時登録 |
| `AssetRegistry` | 論理アセット ID → 実パス の解決 (`manifest.json` 駆動) |
| `AudioManager` | BGM / SE 再生。アセット欠損時は無音で通過 |
| `SaveManager` | `user://saves/slot_N.json` の読み書き |
| `SceneRouter` | シーン遷移とフェード演出 |

### 入力アクション (InputRouter が実行時登録)

`project.godot` の `[input]` はシリアライズ形式が複雑で手編集に脆弱なため、
`src/core/InputRouter.gd` の `ACTION_BINDINGS` で一元管理している。

| 論理名 | キー |
|---|---|
| `action_confirm` | Z / Enter / Space |
| `action_cancel` | X / Esc |
| `action_menu` | C |
| `move_left` / `move_right` / `move_up` / `move_down` | 矢印キー |

## 5. アセット参照の疎結合

シーン側は画像パスを**一切ハードコードしない**。

```
tools/asset_gen  ->  assets/images/manifest.json  { "hero.walk": "res://assets/images/hero/hero_walk.png", ... }
                              |
                    AssetRegistry.get_texture("hero.walk")
```

画像の差し替え・リネームは `manifest.json` 一箇所で完結する。

## 6. テスト方針

外部依存ゼロの自作ランナー (`tests/`) を採用。gdUnit4 等のアドオンは
Godot 4.7 との相性リスクがあるため使わない。

```
tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd
```

- `tests/cases/*.gd` を自動収集。`test_` で始まるメソッドが実行される
- `TestCase` が `assert_eq / assert_true / assert_false / assert_between / assert_approx` を提供
- 終了コードが 0 なら全成功 (CI・pre-commit フックからそのまま使える)
- 初回実行前に `.godot/` (グローバルクラスキャッシュ) 生成のため
  `--headless --editor --quit` によるインポートが必要

## 7. セーブデータ

- 場所: `user://saves/slot_{0,1,2}.json`
- 中身: ドメインがシリアライズした Dictionary のみ。ノード参照は保存しない
- 形式: 人間可読な JSON (インデント付き)

## 8. バージョン番号運用 (Godot 版への写し方)

`.clinerules` の `package.json` / `src/config/version.ts` は、本プロジェクトでは次の対応で運用する。

| clinerules | 本プロジェクト |
|---|---|
| `package.json` の `"version"` | `project.godot` の `config/version` |
| `src/config/version.ts` | `src/config/Version.gd` (`app_build_number` / `app_commit_hash`) |

コミット直前に必ず次を実行して更新する。

1. `git rev-list --count HEAD` + 1 → `app_build_number` と `config/version`
2. `git rev-parse --short HEAD` → `app_commit_hash`

`tests/cases/ProjectConfigTest.gd` が `config/version` と `Version.gd` の一致を検証する。

## 9. 既知の注意点

- `docs/` 配下は Godot のインポート対象外にする (`docs/.gdignore`)。サンプル画像が
  テクスチャとして取り込まれるのを防ぐ
- autoload の `_ready` 中や `Main._ready` 中の `change_scene_to_file` はツリー構築と衝突する。
  必ず `call_deferred` 経由で遅延させる
- PowerShell 5.1 の `Set-Content -Encoding utf8` は BOM を付与し、日本語を含む GDScript を
  文字化けさせる。**日本語を含むソースの編集は必ずエディタ機能を使う**
