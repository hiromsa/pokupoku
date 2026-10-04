class_name MapDefinition
extends RefCounted
# マップ 1 枚分の定義。assets/data/maps/*.json を読んだ結果を保持する。
#
# レイアウトは文字列アート (rows) + 文字 -> タイルID テーブル (glyphs) で持つ。
# 外部 JSON で管理するため、マップ編集は GDScript を触らずにできる。

var map_id: String = ""
var display_name: String = ""
var spawn_tile: Vector2i = Vector2i.ZERO
var rows: PackedStringArray = PackedStringArray()
var glyph_table: Dictionary = {}


static func from_dictionary(data: Dictionary) -> MapDefinition:
	var definition := MapDefinition.new()
	definition._read(data)
	return definition


func _read(data: Dictionary) -> void:
	map_id = str(data.get("id", ""))
	display_name = str(data.get("name", ""))
	spawn_tile = _read_tile(data.get("spawn", {}))
	rows = _read_rows(data.get("rows", []))
	glyph_table = _read_glyphs(data.get("glyphs", {}))


func width() -> int:
	var longest := 0
	for row: String in rows:
		longest = maxi(longest, row.length())
	return longest


func height() -> int:
	return rows.size()


func build_tile_map(catalog: TileCatalog) -> TileMapModel:
	return MapLayoutDecoder.decode(rows, glyph_table, catalog)


func _read_tile(raw: Variant) -> Vector2i:
	if typeof(raw) != TYPE_DICTIONARY:
		return Vector2i.ZERO
	var data: Dictionary = raw
	return Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))


func _read_rows(raw: Variant) -> PackedStringArray:
	var parsed := PackedStringArray()
	if typeof(raw) != TYPE_ARRAY:
		return parsed
	for row: Variant in (raw as Array):
		parsed.append(String(row))
	return parsed


func _read_glyphs(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var table := {}
	for glyph: String in (raw as Dictionary):
		table[glyph] = String((raw as Dictionary)[glyph])
	return table
