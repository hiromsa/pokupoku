class_name TestFixtures
extends RefCounted
# テストケース間で共有する小さなフィクスチャ。
#
# 生成済みアセットに依存しない最小限のデータを用意することで、
# ロジック単体のテストがアセット生成の有無に左右されないようにする。

const SAMPLE_TILE_COUNT: int = 4
const SPRITE_SHEET_LAYOUT_PATH: String = "res://src/core/SpriteSheetLayout.gd"


# autoload のノードを複製せず、スクリプトから直接インスタンス化する。
# _ready はツリー追加時に走るため、同じ処理である reload_layouts() を明示的に呼ぶ。
static func create_sprite_sheet_layout() -> Node:
	var script: GDScript = load(SPRITE_SHEET_LAYOUT_PATH)
	var layout: Node = script.new() as Node
	layout.reload_layouts()
	return layout


static func free_node(node: Node) -> void:
	if node != null:
		node.free()


static func sample_catalog() -> TileCatalog:
	return TileCatalog.from_dictionary({
		"grass": {"frame": 0, "solid": false},
		"dirt_path": {"frame": 1, "solid": false},
		"tree": {"frame": 2, "solid": true, "base": "grass"},
		"water": {"frame": 3, "solid": true},
	})


# 外周が壁で囲まれた歩き回れる広場。移動系のテストで使う。
static func open_field(size: int = 5) -> TileMapModel:
	var catalog: TileCatalog = sample_catalog()
	var map: TileMapModel = TileMapModel.create(size, size, catalog)
	for y: int in range(size):
		for x: int in range(size):
			map.set_tile(Vector2i(x, y), "grass")
	return map
