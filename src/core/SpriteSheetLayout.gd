extends Node
# スプライトシートのレイアウト解決。
#
# tools/asset_gen が書き出す assets/images/sheets.json を正とし、
# 「アセットID + フレーム名」から AtlasTexture を切り出して返す。
# シートの列数やフレーム順を変えても、呼び出し側は名前で参照できるため
# 画像側の並び替えがシーン実装に波及しない。

const SHEETS_PATH: String = "res://assets/images/sheets.json"

var _layout_table: Dictionary = {}
var _atlas_cache: Dictionary = {}
var _loaded: bool = false


func _ready() -> void:
	reload_layouts()


func reload_layouts() -> void:
	_loaded = true
	_layout_table.clear()
	_atlas_cache.clear()
	if not FileAccess.file_exists(SHEETS_PATH):
		push_warning("Sheet layout file not found: %s" % SHEETS_PATH)
		return

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SHEETS_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Malformed sheet layout file: %s" % SHEETS_PATH)
		return

	for asset_id: String in (parsed as Dictionary):
		_layout_table[asset_id] = (parsed as Dictionary)[asset_id]


func has_sheet(asset_id: String) -> bool:
	_ensure_loaded()
	return _layout_table.has(asset_id)


func frame_names(asset_id: String) -> PackedStringArray:
	var names := PackedStringArray()
	for frame_name: String in _frames_or_empty(asset_id):
		names.append(str(frame_name))
	return names


func frame_count(asset_id: String) -> int:
	return _frames_or_empty(asset_id).size()


func frame_index(asset_id: String, frame_name: String) -> int:
	var frames: Array = _frames_or_empty(asset_id)
	return frames.find(frame_name)


func get_frame_texture(asset_id: String, frame_name: String) -> AtlasTexture:
	var cache_key: String = "%s/%s" % [asset_id, frame_name]
	if _atlas_cache.has(cache_key):
		return _atlas_cache[cache_key] as AtlasTexture

	var index: int = frame_index(asset_id, frame_name)
	if index < 0:
		push_warning("Unknown frame: %s / %s" % [asset_id, frame_name])
		return null

	var texture: AtlasTexture = _build_atlas(asset_id, index)
	if texture != null:
		_atlas_cache[cache_key] = texture
	return texture


func get_frame_texture_by_index(asset_id: String, index: int) -> AtlasTexture:
	var cache_key: String = "%s/#%d" % [asset_id, index]
	if _atlas_cache.has(cache_key):
		return _atlas_cache[cache_key] as AtlasTexture

	var texture: AtlasTexture = _build_atlas(asset_id, index)
	if texture != null:
		_atlas_cache[cache_key] = texture
	return texture


# autoload の _ready() は --script 起動 (テスト) では後から走る。
# 参照時に必ずロード済みへ寄せることで、初期化順序に依存しない。
func _ensure_loaded() -> void:
	if not _loaded:
		reload_layouts()


func _build_atlas(asset_id: String, index: int) -> AtlasTexture:
	_ensure_loaded()
	var layout: Dictionary = _layout_table.get(asset_id, {})
	if layout.is_empty():
		push_warning("Unknown sheet: %s" % asset_id)
		return null

	var source: Texture2D = AssetRegistry.get_texture(asset_id)
	if source == null:
		return null

	var cols: int = int(layout.get("cols", 1))
	var cell: Array = layout.get("cell", [0, 0])
	var cell_width: int = int(cell[0])
	var cell_height: int = int(cell[1])
	if cell_width <= 0 or cell_height <= 0:
		push_warning("Sheet %s has a zero-sized cell" % asset_id)
		return null

	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(
		(index % cols) * cell_width,
		(index / cols) * cell_height,
		cell_width,
		cell_height,
	)
	return atlas


func _frames_or_empty(asset_id: String) -> Array:
	_ensure_loaded()
	var layout: Dictionary = _layout_table.get(asset_id, {})
	return layout.get("frames", []) as Array
