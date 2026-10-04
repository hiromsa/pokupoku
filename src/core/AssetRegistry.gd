extends Node
# 画像・音声アセットを「論理ID」で解決するレジストリ。
#
# 生成ツール (tools/asset_gen) が manifest.json を出力し、
# そこに 論理ID -> 実パス の対応が書かれる。シーン側は実パスを一切知らないため、
# 画像の差し替え・リネームが manifest.json 一箇所で完結する。

# 未生成カテゴリ (音声など) の manifest は警告を出さない任意扱いにする。
#  typo でファイルが見つからない事故は、必須側と AssetManifestTest が検出する。
const REQUIRED_MANIFEST_PATHS: Array[String] = [
	"res://assets/images/manifest.json",
]
const OPTIONAL_MANIFEST_PATHS: Array[String] = [
	"res://assets/audio/manifest.json",
]

var _path_table: Dictionary = {}
var _texture_cache: Dictionary = {}
var _audio_cache: Dictionary = {}
var _loaded: bool = false


func _ready() -> void:
	reload_manifest()


func reload_manifest() -> void:
	_loaded = true
	_path_table.clear()
	_texture_cache.clear()
	_audio_cache.clear()
	for manifest_path: String in REQUIRED_MANIFEST_PATHS:
		_merge_manifest(manifest_path, true)
	for manifest_path: String in OPTIONAL_MANIFEST_PATHS:
		_merge_manifest(manifest_path, false)


func has_asset(asset_id: String) -> bool:
	_ensure_loaded()
	return _path_table.has(asset_id)


func get_asset_path(asset_id: String) -> String:
	_ensure_loaded()
	return str(_path_table.get(asset_id, ""))


func get_texture(asset_id: String) -> Texture2D:
	if _texture_cache.has(asset_id):
		return _texture_cache[asset_id] as Texture2D

	var resource: Resource = _load_resource(asset_id)
	var texture: Texture2D = resource as Texture2D
	if texture != null:
		_texture_cache[asset_id] = texture
	return texture


func get_audio_stream(asset_id: String) -> AudioStream:
	if _audio_cache.has(asset_id):
		return _audio_cache[asset_id] as AudioStream

	var resource: Resource = _load_resource(asset_id)
	var stream: AudioStream = resource as AudioStream
	if stream != null:
		_audio_cache[asset_id] = stream
	return stream


func registered_ids() -> Array:
	_ensure_loaded()
	return _path_table.keys()


# autoload の _ready() は --script 起動 (テスト) では後から走る。
# 参照時に必ずロード済みへ寄せることで、初期化順序に依存しない。
func _ensure_loaded() -> void:
	if not _loaded:
		reload_manifest()


func _merge_manifest(manifest_path: String, required: bool) -> void:
	if not FileAccess.file_exists(manifest_path):
		if required:
			push_warning("Asset manifest not found: %s" % manifest_path)
		return

	var raw_text: String = FileAccess.get_file_as_string(manifest_path)
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Malformed asset manifest: %s" % manifest_path)
		return

	for asset_id: String in (parsed as Dictionary):
		_path_table[asset_id] = (parsed as Dictionary)[asset_id]


func _load_resource(asset_id: String) -> Resource:
	var resource_path: String = get_asset_path(asset_id)
	if resource_path.is_empty():
		push_warning("Unknown asset id: %s" % asset_id)
		return null
	if not ResourceLoader.exists(resource_path):
		push_warning("Asset file missing: %s (id=%s)" % [resource_path, asset_id])
		return null
	return ResourceLoader.load(resource_path)
