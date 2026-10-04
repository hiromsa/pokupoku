class_name MapLayoutDecoderTest
extends TestCase
# 文字列アートからタイルグリッドへの展開を検証する。
#
# マップ本体は JSON データなので、この変換が唯一の GDScript 側経路になる。

const GLYPHS: Dictionary = {
	"g": "grass",
	"p": "dirt_path",
	"T": "tree",
	"w": "water",
}


func test_glyphs_expand_into_a_grid() -> void:
	var rows := PackedStringArray(["gpT", "gwg"])
	var map: TileMapModel = MapLayoutDecoder.decode(rows, GLYPHS, TestFixtures.sample_catalog())
	assert_eq(map.width(), 3, "width from the widest row")
	assert_eq(map.height(), 2, "height from the row count")
	assert_eq(map.tile_id_at(Vector2i(0, 0)), "grass", "first glyph decoded")
	assert_eq(map.tile_id_at(Vector2i(1, 0)), "dirt_path", "second glyph decoded")
	assert_true(map.is_solid(Vector2i(2, 0)), "tree glyph blocks")
	assert_true(map.is_solid(Vector2i(1, 1)), "water glyph blocks")
	assert_true(map.is_passable(Vector2i(2, 1)), "grass glyph walks")


func test_unknown_glyph_becomes_an_impassable_hole() -> void:
	var rows := PackedStringArray(["g?g"])
	var map: TileMapModel = MapLayoutDecoder.decode(rows, GLYPHS, TestFixtures.sample_catalog())
	assert_eq(map.tile_id_at(Vector2i(1, 0)), TileMapModel.EMPTY_TILE, "unknown glyph leaves no tile")
	assert_false(map.is_passable(Vector2i(1, 0)), "unknown glyph blocks movement")
	assert_true(map.is_passable(Vector2i(0, 0)), "known glyph beside it still works")


func test_ragged_rows_are_padded_to_the_widest_row() -> void:
	var rows := PackedStringArray(["ggg", "g"])
	var map: TileMapModel = MapLayoutDecoder.decode(rows, GLYPHS, TestFixtures.sample_catalog())
	assert_eq(map.width(), 3, "padded to the widest row")
	assert_eq(map.height(), 2, "row count preserved")
	assert_false(map.is_passable(Vector2i(2, 1)), "padded cells are holes")


func test_empty_layout_produces_an_empty_map() -> void:
	var map: TileMapModel = MapLayoutDecoder.decode(PackedStringArray(), GLYPHS, TestFixtures.sample_catalog())
	assert_eq(map.width(), 0, "empty layout has no width")
	assert_eq(map.height(), 0, "empty layout has no rows")
	assert_false(map.is_passable(Vector2i(0, 0)), "nothing is walkable")
