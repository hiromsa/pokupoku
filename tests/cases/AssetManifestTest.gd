class_name AssetManifestTest
extends TestCase
# tools/asset_gen が生成した manifest.json / sheets.json の整合性を検証する。
#
# 生成物は Python 側 (tools/asset_gen) と GDScript 側 (AssetRegistry /
# SpriteSheetLayout) の契約そのものなので、ズレはこのテストで検出する。

const MANIFEST_PATH: String = "res://assets/images/manifest.json"
const SHEETS_PATH: String = "res://assets/images/sheets.json"
const TILE_INDEX_PATH: String = "res://assets/images/tiles/tile_index.json"

# フェーズ進行上で必ず必要になるアセット ID。欠けるとシーンが黙って壊れる。
const REQUIRED_ASSET_IDS: Array[String] = [
	"hero.field", "hero.battle", "tiles.field", "items.icons", "ui.parts", "ui.icon",
]

const REQUIRED_ENEMY_IDS: Array[String] = [
	"poku", "karekusa", "dosun", "kachikochi", "hyun",
	"yukidama", "yamanushi", "chap", "kaze_no_yami", "haka_bake",
]


func test_manifest_file_parses_to_dictionary() -> void:
	assert_true(FileAccess.file_exists(MANIFEST_PATH), "manifest.json exists")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	assert_true(typeof(parsed) == TYPE_DICTIONARY, "manifest.json is a JSON object")
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	assert_true((parsed as Dictionary).size() >= REQUIRED_ASSET_IDS.size(), "manifest not empty")


func test_every_manifest_entry_resolves_to_existing_resource() -> void:
	var manifest: Dictionary = _read_json_object(MANIFEST_PATH)
	for asset_id: String in manifest:
		var resource_path: String = String(manifest[asset_id])
		assert_true(resource_path.begins_with("res://"), "path is res:// relative: %s" % asset_id)
		assert_true(ResourceLoader.exists(resource_path), "resource exists: %s" % resource_path)


func test_required_asset_ids_present() -> void:
	var manifest: Dictionary = _read_json_object(MANIFEST_PATH)
	for asset_id: String in REQUIRED_ASSET_IDS:
		assert_true(manifest.has(asset_id), "manifest has %s" % asset_id)


func test_all_ten_enemies_have_field_and_battle_sheets() -> void:
	var manifest: Dictionary = _read_json_object(MANIFEST_PATH)
	for enemy_id: String in REQUIRED_ENEMY_IDS:
		assert_true(manifest.has("enemy.%s" % enemy_id), "field sheet: %s" % enemy_id)
		assert_true(manifest.has("enemy.%s.battle" % enemy_id), "battle sheet: %s" % enemy_id)


func test_sheets_declare_consistent_grid_geometry() -> void:
	var sheets: Dictionary = _read_json_object(SHEETS_PATH)
	assert_true(sheets.size() > 0, "sheets.json not empty")

	for asset_id: String in sheets:
		var meta: Dictionary = sheets[asset_id] as Dictionary
		var cols: int = int(meta.get("cols", 0))
		var rows: int = int(meta.get("rows", 0))
		var cell: Array = meta.get("cell", []) as Array
		var frames: Array = meta.get("frames", []) as Array

		assert_true(cols > 0 and rows > 0, "grid size positive: %s" % asset_id)
		assert_eq(cell.size(), 2, "cell declared: %s" % asset_id)
		assert_eq(frames.size(), cols * rows, "frame count matches grid: %s" % asset_id)

		for frame_name: String in frames:
			assert_true(not String(frame_name).is_empty(), "frame named: %s" % asset_id)

		var texture: Texture2D = ResourceLoader.load(String(meta.get("path", ""))) as Texture2D
		if texture == null:
			continue
		assert_eq(texture.get_width(), cols * int(cell[0]), "sheet width matches grid: %s" % asset_id)
		assert_eq(texture.get_height(), rows * int(cell[1]), "sheet height matches grid: %s" % asset_id)


func test_tile_index_covers_every_registered_tile() -> void:
	assert_true(FileAccess.file_exists(TILE_INDEX_PATH), "tile_index.json exists")
	if not FileAccess.file_exists(TILE_INDEX_PATH):
		return
	var tile_index: Dictionary = _read_json_object(TILE_INDEX_PATH)
	assert_true(tile_index.size() >= 20, "at least 20 tiles registered (got %d)" % tile_index.size())

	var sheets: Dictionary = _read_json_object(SHEETS_PATH)
	var frames: Array = (sheets.get("tiles.field", {}) as Dictionary).get("frames", []) as Array
	for tile_name: String in tile_index:
		assert_true(frames.has("tile.%s" % tile_name), "tile frame registered: %s" % tile_name)


func _read_json_object(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary
