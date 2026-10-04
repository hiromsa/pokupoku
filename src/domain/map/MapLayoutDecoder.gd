class_name MapLayoutDecoder
extends RefCounted
# 文字列アートのマップレイアウトを TileMapModel に展開する。
#
# レイアウト本体は JSON (assets/data/maps/) に置くため、
# マップの地形編集は GDScript を触らずにできる。ここでは変換だけを受け持つ。

# どのタイルにも対応しない文字。通行不可の穴として扱う。
const VOID_GLYPH: String = ""


static func map_width(rows: PackedStringArray) -> int:
	var longest: int = 0
	for row: String in rows:
		longest = maxi(longest, row.length())
	return longest


static func decode(rows: PackedStringArray, glyph_table: Dictionary, catalog: TileCatalog) -> TileMapModel:
	var model: TileMapModel = TileMapModel.create(map_width(rows), rows.size(), catalog)
	for y: int in range(rows.size()):
		_decode_row(model, rows[y], y, glyph_table)
	return model


static func _decode_row(model: TileMapModel, row: String, y: int, glyph_table: Dictionary) -> void:
	for x: int in range(row.length()):
		var glyph: String = row[x]
		var tile_id: String = String(glyph_table.get(glyph, VOID_GLYPH))
		if tile_id == VOID_GLYPH:
			continue
		model.set_tile(Vector2i(x, y), tile_id)
