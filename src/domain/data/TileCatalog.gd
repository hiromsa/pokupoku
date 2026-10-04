class_name TileCatalog
extends RefCounted
# タイルの属性カタログ。
#
# tools/asset_gen が出力する assets/images/tiles/tile_index.json をそのまま読む。
# 「どのタイルが通行を塞ぐか」の単一の定義元であり、
# フィールドも戦闘もここ以外で当たり判定を判断しない。

var _entries: Dictionary = {}


static func from_dictionary(data: Dictionary) -> TileCatalog:
	var catalog := TileCatalog.new()
	catalog._load_entries(data)
	return catalog


func _load_entries(data: Dictionary) -> void:
	_entries.clear()
	for tile_id: String in data:
		var entry: Variant = data[tile_id]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		_entries[tile_id] = entry


func is_registered(tile_id: String) -> bool:
	return _entries.has(tile_id)


func count() -> int:
	return _entries.size()


func tile_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for tile_id: String in _entries:
		ids.append(tile_id)
	ids.sort()
	return ids


# アトラス内の row-major 列番号。未知のタイルは -1。
func frame_index(tile_id: String) -> int:
	if not _entries.has(tile_id):
		return -1
	return int(_entries[tile_id].get("frame", -1))


# 未登録タイルは通行不可へ倒す。データ側の抜けでプレイヤーが壁を突き抜ける事故を防ぐ。
func is_solid(tile_id: String) -> bool:
	if not _entries.has(tile_id):
		return true
	return bool(_entries[tile_id].get("solid", true))
